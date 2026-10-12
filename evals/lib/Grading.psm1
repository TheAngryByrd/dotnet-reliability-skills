Set-StrictMode -Version Latest

function New-Check {
    param(
        [Parameter(Mandatory)][string]$Text,
        [AllowNull()][Nullable[bool]]$Passed,
        [string]$Evidence = ''
    )
    [pscustomobject]@{ text = $Text; passed = $Passed; evidence = $Evidence }
}

function Write-Checks {
    param([Parameter(Mandatory)][string]$ResultPath, [object[]]$Checks)
    ConvertTo-Json -InputObject @($Checks) -Depth 5 | Set-Content -Path $ResultPath -Encoding utf8
}

function Read-JsonFile {
    param([Parameter(Mandatory)][string]$Path)
    if (-not (Test-Path $Path)) { return $null }
    try { Get-Content -Raw $Path | ConvertFrom-Json -Depth 20 } catch { $null }
}

function Get-JsonField($Object, [string]$Name) {
    if ($Object -is [psobject] -and $Object.PSObject.Properties[$Name]) { $Object.$Name } else { $null }
}

function New-TempDirectory {
    $dir = Join-Path ([IO.Path]::GetTempPath()) ('skill-eval-' + [guid]::NewGuid().ToString('n'))
    New-Item -ItemType Directory -Force -Path $dir | Out-Null
    $dir
}

function Invoke-Capture {
    param([Parameter(Mandatory)][string]$FilePath, [string[]]$Arguments = @(), [string]$WorkingDirectory = $PWD.Path)
    Push-Location $WorkingDirectory
    try {
        $output = & $FilePath @Arguments 2>&1 | ForEach-Object { "$_" }
        [pscustomobject]@{ ExitCode = $LASTEXITCODE; Lines = @($output); Text = ($output -join "`n") }
    } finally {
        Pop-Location
    }
}

function Get-LastLines {
    param([string]$Text, [int]$Count = 15)
    (($Text -split "`n") | Select-Object -Last $Count) -join "`n"
}

function Get-TaskSpec {
    param([Parameter(Mandatory)][string]$EvalDir, [Parameter(Mandatory)][string]$TaskId)
    $spec = Get-Content -Raw (Join-Path $EvalDir 'evals.json') | ConvertFrom-Json
    $task = $spec.tasks | Where-Object id -eq $TaskId | Select-Object -First 1
    if (-not $task) { throw "evals.json in $EvalDir has no task $TaskId." }
    $task
}

function Get-EvalCacheRoot {
    if ($env:SKILL_EVAL_CACHE) { return $env:SKILL_EVAL_CACHE }
    Join-Path ([IO.Path]::GetTempPath()) 'skill-evals/cache'
}

function Get-ChangedTrackedFiles {
    # Untracked files, such as the agent's report, do not count. A file that is deleted, modified, or staged does.
    param([Parameter(Mandatory)][string]$Workspace)
    $r = Invoke-Capture git @('-c', 'core.autocrlf=false', '-c', 'core.quotepath=false', 'status', '--porcelain', '--untracked-files=no') -WorkingDirectory $Workspace
    if ($r.ExitCode -ne 0) { throw "git status failed in ${Workspace}: $($r.Text)" }
    $head = Invoke-Capture git @('rev-parse', 'HEAD') -WorkingDirectory $Workspace
    [pscustomobject]@{ Files = @($r.Lines | Where-Object { $_.Trim() }); Head = "$($head.Text)".Trim() }
}

function Copy-RepositorySnapshot {
    # A shared clone at a fixed commit. It does not contain the agent's uncommitted changes.
    param([Parameter(Mandatory)][string]$Source, [Parameter(Mandatory)][string]$Commit, [Parameter(Mandatory)][string]$Destination)
    $r = Invoke-Capture git @('-c', 'core.autocrlf=false', 'clone', '--quiet', '--shared', '--no-checkout', $Source, $Destination)
    if ($r.ExitCode -ne 0) { throw "git clone failed: $($r.Text)" }
    $null = Invoke-Capture git @('config', 'core.autocrlf', 'false') -WorkingDirectory $Destination
    $r = Invoke-Capture git @('checkout', '--quiet', '--detach', $Commit) -WorkingDirectory $Destination
    if ($r.ExitCode -ne 0) { throw "git checkout $Commit failed: $($r.Text)" }
}

function Read-TrxResults {
    param([Parameter(Mandatory)][string]$Directory)
    $file = Get-ChildItem -Path $Directory -Filter '*.trx' -Recurse -File -ErrorAction SilentlyContinue | Sort-Object LastWriteTime | Select-Object -Last 1
    if (-not $file) { return $null }
    [xml]$xml = Get-Content -Raw $file.FullName
    $results = @($xml.GetElementsByTagName('UnitTestResult') | ForEach-Object { [pscustomobject]@{ Name = $_.testName; Outcome = $_.outcome } })
    [pscustomobject]@{
        Total  = $results.Count
        Passed = @($results | Where-Object Outcome -eq 'Passed').Count
        Failed = @($results | Where-Object Outcome -eq 'Failed' | ForEach-Object Name)
    }
}

function Invoke-DotnetTest {
    # dotnet selects its SDK from global.json above the working directory, so the command runs in the repository root.
    param([Parameter(Mandatory)][string]$Repository, [Parameter(Mandatory)][string]$Project, [Parameter(Mandatory)][string[]]$Arguments)
    $results = Join-Path $Repository '.eval-results'
    Remove-Item -Recurse -Force $results -ErrorAction SilentlyContinue
    $run = Invoke-Capture dotnet (@('test', $Project) + $Arguments + @('--logger', 'trx;LogFileName=result.trx', '--results-directory', $results)) -WorkingDirectory $Repository
    Get-TestRunOutcome -Text $run.Text -ExitCode $run.ExitCode -Trx (Read-TrxResults $results)
}

function Get-TestRunOutcome {
    # A compiler error in a source file is an outcome of the code. Restore, MSBuild, and runner failures are infrastructure failures.
    param([AllowEmptyString()][string]$Text, $ExitCode, $Trx)
    $compileError = $Text -match '(?m)\.(?:fs|fsi|fsx|cs)\(\d+,\d+\): error (?:FS|CS)\d+'
    $failed = @(if ($Trx) { @($Trx.Failed) | Where-Object { $_ } })
    $verdict = if ($compileError) { 'invalid' }
    elseif ($null -eq $Trx) { 'inconclusive' }
    elseif ($failed.Count -gt 0) { 'detected' }
    elseif ($Trx.Total -gt 0 -and $ExitCode -eq 0) { 'survived' }
    else { 'inconclusive' }
    [pscustomobject]@{
        Verdict  = $verdict
        ExitCode = $ExitCode
        Total    = if ($Trx) { $Trx.Total } else { 0 }
        Passed   = if ($Trx) { $Trx.Passed } else { 0 }
        Failed   = $failed
        Log      = $Text
    }
}

$RubricDocumentLimit = 60000
$RubricMinQuoteLength = 4

$RubricSchema = @{
    type = 'object'; required = @('items')
    properties = @{
        items = @{
            type = 'array'
            items = @{
                type = 'object'; required = @('id', 'answer', 'quote')
                properties = @{ id = @{ type = 'string' }; answer = @{ type = 'string'; enum = @('yes', 'no') }; quote = @{ type = 'string' } }
            }
        }
    }
} | ConvertTo-Json -Depth 10 -Compress

$RubricSystemPrompt = 'You review a technical document against a rubric. Answer each item with yes or no. Base each answer only on the document. Copy each quote exactly from one line of the document.'

function Get-JudgeCommand {
    $configured = $env:SKILL_EVAL_JUDGE
    if (-not $configured) {
        return @('claude', '-p', '--model', 'haiku', '--tools', '', '--disable-slash-commands', '--no-session-persistence', '--strict-mcp-config',
            '--setting-sources', '', '--system-prompt', $RubricSystemPrompt, '--output-format', 'json', '--json-schema', $RubricSchema)
    }
    if ($configured.Trim() -eq 'off') { return $null }
    $invalid = "SKILL_EVAL_JUDGE must be 'off' or a JSON array of the command and its arguments. Value: $configured"
    try { $parsed = ConvertFrom-Json -InputObject $configured -NoEnumerate } catch { throw $invalid }
    if ($parsed -isnot [array] -or $parsed.Count -eq 0 -or @($parsed | Where-Object { $_ -isnot [string] }).Count -or -not $parsed[0]) { throw $invalid }
    [string[]]$parsed
}

function Get-RubricPrompt {
    param([Parameter(Mandatory)][object[]]$Items, [Parameter(Mandatory)][AllowEmptyString()][string]$Document)
    $lines = @(
        'Review the document below against each rubric item.',
        'Answer "yes" or "no" for each item.',
        'For each item, give one quote: an exact substring of one line of the document that shows the answer.',
        'If no line of the document shows the answer, give an empty quote.',
        'Reply with JSON only, in this shape: {"items":[{"id":"<item id>","answer":"yes","quote":"<exact text from the document>"}]}',
        '',
        'Rubric items:'
    )
    $lines += $Items | ForEach-Object { "- $($_.id): $($_.question)" }
    $lines += @('', 'Document:', '<document>', $Document, '</document>')
    $lines -join "`n"
}

function ConvertTo-NormalizedText([string]$Line) {
    ($Line -replace '[‘’]', "'" -replace '[“”]', '"' -replace '\s+', ' ').Trim()
}

function Test-QuoteInDocument([string]$Quote, [string[]]$DocumentLines) {
    $quoteLines = @($Quote -split "\r?\n" | Where-Object { $_.Trim() })
    if ($quoteLines.Count -ne 1) { return $false }
    $text = ConvertTo-NormalizedText $quoteLines[0]
    if ($text.Length -lt $RubricMinQuoteLength) { return $false }
    @($DocumentLines | Where-Object { $_.Contains($text) }).Count -gt 0
}

function ConvertFrom-JudgeOutput([string]$Text) {
    $candidates = @($Text.Trim())
    $start = $Text.IndexOf('{'); $end = $Text.LastIndexOf('}')
    if ($start -ge 0 -and $end -gt $start) { $candidates += $Text.Substring($start, $end - $start + 1) }
    foreach ($candidate in $candidates) {
        try { $obj = ConvertFrom-Json -InputObject $candidate -Depth 20 } catch { continue }
        if ($obj -isnot [psobject]) { continue }
        $structured = Get-JsonField $obj 'structured_output'
        if ($structured) { $obj = $structured }
        $items = Get-JsonField $obj 'items'
        if ($items -is [array]) { return , $items }
        if ($items -is [psobject] -and $items -isnot [string]) { return , @($items) }
        $result = Get-JsonField $obj 'result'
        if ($result -is [string] -and $result -ne $Text) {
            $inner = ConvertFrom-JudgeOutput $result
            if ($null -ne $inner) { return , $inner }
        }
    }
    $null
}

function Invoke-Utf8Native([scriptblock]$Script) {
    # PowerShell decodes native stdout with the console code page, which is not UTF-8 by default on Windows.
    $previous = [Console]::OutputEncoding
    try {
        [Console]::OutputEncoding = [Text.UTF8Encoding]::new($false)
        & $Script
    } finally {
        [Console]::OutputEncoding = $previous
    }
}

# Variables that a parent Claude Code session sets. A child Claude process that inherits them can attach to the parent session.
$ParentSessionVariables = @('CLAUDECODE', 'CLAUDE_CODE_ENTRYPOINT', 'CLAUDE_CODE_SESSION_ID', 'CLAUDE_CODE_CHILD_SESSION', 'CLAUDE_CODE_SESSION_ATTENDED',
    'CLAUDE_CODE_MESSAGING_SOCKET', 'CLAUDE_CODE_MESSAGING_TOKEN', 'CLAUDE_PID', 'CLAUDE_EFFORT')

function Get-ParentSessionVariables { $ParentSessionVariables }

function Invoke-Judge {
    param([Parameter(Mandatory)][AllowEmptyString()][string[]]$Command, [Parameter(Mandatory)][string]$Prompt)
    $temp = New-TempDirectory
    $saved = @{}
    foreach ($name in $ParentSessionVariables) {
        $value = [Environment]::GetEnvironmentVariable($name)
        if ($null -ne $value) { $saved[$name] = $value; [Environment]::SetEnvironmentVariable($name, $null) }
    }
    try {
        $promptFile = Join-Path $temp 'prompt.txt'
        $errFile = Join-Path $temp 'stderr.txt'
        Set-Content -Path $promptFile -Value $Prompt -Encoding utf8NoBOM -NoNewline
        $exe, $arguments = $Command
        Push-Location $temp
        try {
            $output = Invoke-Utf8Native { Get-Content -Raw -Encoding utf8 $promptFile | & $exe @arguments 2>$errFile }
            $exit = $LASTEXITCODE
        } finally { Pop-Location }
        $stderr = if (Test-Path $errFile) { Get-Content -Raw $errFile } else { '' }
        [pscustomobject]@{ ExitCode = $exit; Output = (@($output) -join "`n"); Stderr = "$stderr" }
    } finally {
        foreach ($name in $saved.Keys) { [Environment]::SetEnvironmentVariable($name, $saved[$name]) }
        Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
    }
}

function New-RubricCheck([string]$Text, [AllowNull()][Nullable[bool]]$Passed, [string]$Evidence, [AllowNull()][string]$Answer) {
    # answer keeps the judge's yes or no when a quote check skips the result, so the agreement script can compare raw answers.
    $check = New-Check $Text $Passed $Evidence
    $check | Add-Member -NotePropertyName answer -NotePropertyValue $(if ($Answer) { $Answer } else { $null })
    $check
}

function Get-RubricChecks {
    param([object[]]$Items, [string]$Document, [object[]]$Answers)
    $documentLines = @($Document -split "\r?\n" | ForEach-Object { ConvertTo-NormalizedText $_ } | Where-Object { $_ })
    foreach ($item in $Items) {
        $text = "Rubric $($item.id): $($item.question)"
        $hit = @($Answers | Where-Object { "$(Get-JsonField $_ 'id')" -eq "$($item.id)" }) | Select-Object -First 1
        if (-not $hit) { New-RubricCheck $text $null 'skipped: the judge gave no answer for this item' $null; continue }
        $quote = "$(Get-JsonField $hit 'quote')"
        $verdict = "$(Get-JsonField $hit 'answer')".Trim().ToLowerInvariant()
        if ($verdict -notin 'yes', 'no') { New-RubricCheck $text $null "skipped: the judge answer '$verdict' is not yes or no" $null; continue }
        if ($verdict -eq 'yes' -and -not (Test-QuoteInDocument $quote $documentLines)) {
            New-RubricCheck $text $null "skipped: judge quote not found in one document line: '$quote'" $verdict; continue
        }
        New-RubricCheck $text ($verdict -eq 'yes') "${verdict}: $quote" $verdict
    }
}

function Invoke-Rubric {
    param(
        [Parameter(Mandatory)][string]$Workspace,
        [Parameter(Mandatory)][string]$EvalDir,
        [Parameter(Mandatory)][string]$TaskId
    )
    $spec = Get-Content -Raw (Join-Path $EvalDir 'evals.json') | ConvertFrom-Json
    $task = Get-TaskSpec -EvalDir $EvalDir -TaskId $TaskId
    $items = @(@(if ($task.PSObject.Properties['rubric']) { $task.rubric }) | ForEach-Object {
            [pscustomobject]@{ id = "$(Get-JsonField $_ 'id')"; question = "$(Get-JsonField $_ 'question')" }
        })
    if ($items.Count -eq 0) { return @() }
    $skipAll = { param($reason) $items | ForEach-Object { New-Check "Rubric $($_.id): $($_.question)" $null "skipped: $reason" } }
    if (@($items | Where-Object { -not $_.id -or -not $_.question }).Count) {
        return @(& $skipAll "each rubric item in $TaskId needs an id and a question")
    }
    $documentName = "$(Get-JsonField $task 'rubricDocument')"
    if (-not $documentName) { return @(& $skipAll "task $TaskId has a rubric but no rubricDocument") }

    try {
        $command = Get-JudgeCommand
        if (-not $command) { return @(& $skipAll 'the judge is off (SKILL_EVAL_JUDGE=off)') }
        $path = Join-Path $Workspace $documentName
        if (-not (Test-Path $path -PathType Leaf)) {
            return @($items | ForEach-Object { New-Check "Rubric $($_.id): $($_.question)" $false "$documentName does not exist" })
        }
        $document = Get-Content -Raw -Encoding utf8 $path
        if ($null -eq $document) { $document = '' }
        if ($spec.PSObject.Properties['skill'] -and $spec.skill) {
            $document = $document -replace ([regex]::Escape("$($spec.skill)-eval") + '(?![\w-])'), $spec.skill
        }
        if ($document.Length -gt $RubricDocumentLimit) { $document = $document.Substring(0, $RubricDocumentLimit) + "`n[document cut at $RubricDocumentLimit characters]" }

        $run = Invoke-Judge -Command $command -Prompt (Get-RubricPrompt -Items $items -Document $document)
        if ($run.ExitCode -ne 0) { return @(& $skipAll "the judge exited with code $($run.ExitCode): $(Get-LastLines ($run.Stderr + "`n" + $run.Output) 3)") }
        $answers = ConvertFrom-JudgeOutput $run.Output
        if ($null -eq $answers) { return @(& $skipAll "the judge output has no items array: $(Get-LastLines $run.Output 3)") }
        @(Get-RubricChecks -Items $items -Document $document -Answers $answers)
    } catch {
        @(& $skipAll "the rubric could not run: $_")
    }
}

Export-ModuleMember -Function Get-ParentSessionVariables, New-Check, Write-Checks, Read-JsonFile, Get-JsonField, New-TempDirectory, Invoke-Capture, Get-LastLines, Get-TaskSpec,
    Get-EvalCacheRoot, Get-ChangedTrackedFiles, Copy-RepositorySnapshot, Read-TrxResults, Invoke-DotnetTest, Get-TestRunOutcome, Get-RubricChecks, Invoke-Rubric
