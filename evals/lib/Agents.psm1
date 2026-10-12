Set-StrictMode -Version Latest

$AgentMessage = 'Read TASK.md in the current directory and complete the task it describes. Work only inside the current directory.'

# Variables that a parent Claude Code session sets. A child agent that inherits them can attach to the parent session.
$ParentSessionVariables = @('CLAUDECODE', 'CLAUDE_CODE_ENTRYPOINT', 'CLAUDE_CODE_SESSION_ID', 'CLAUDE_CODE_CHILD_SESSION', 'CLAUDE_CODE_SESSION_ATTENDED',
    'CLAUDE_CODE_MESSAGING_SOCKET', 'CLAUDE_CODE_MESSAGING_TOKEN', 'CLAUDE_PID', 'CLAUDE_EFFORT')

function ConvertTo-AgentTarget {
    param([Parameter(Mandatory)][string]$Spec)
    $agent, $model = $Spec -split ':', 2
    $agent = $agent.Trim().ToLowerInvariant()
    if ($agent -notin 'claude', 'codex', 'opencode') { throw "Unknown agent '$agent'. Use claude, codex, or opencode." }
    [pscustomobject]@{ Agent = $agent; Model = $(if ($model) { $model.Trim() } else { '' }); Label = $Spec.Trim() }
}

function ConvertTo-PathSegment {
    param([Parameter(Mandatory)][string]$Text)
    ($Text -replace '[^A-Za-z0-9._-]+', '_').Trim('_')
}

function Resolve-AgentCommand {
    param([Parameter(Mandatory)][string]$Agent)
    $cmd = Get-Command $Agent -CommandType Application -ErrorAction SilentlyContinue | Select-Object -First 1
    if (-not $cmd) { throw "Command '$Agent' was not found on PATH." }
    $cmd.Source
}

function Get-UserHome { [Environment]::GetFolderPath('UserProfile') }

function Find-ConflictingSkills {
    param([Parameter(Mandatory)][string]$Skill, [string[]]$Keywords = @())
    $userHome = Get-UserHome
    $dirs = @('.claude/skills', '.agents/skills', '.codex/skills', '.config/opencode/skills') | ForEach-Object { Join-Path $userHome $_ }
    foreach ($dir in $dirs | Where-Object { Test-Path $_ }) {
        foreach ($file in Get-ChildItem -Path $dir -Filter 'SKILL.md' -Recurse -Depth 2 -File -ErrorAction SilentlyContinue) {
            $description = (Get-Content $file.FullName -TotalCount 40 -ErrorAction SilentlyContinue | Where-Object { $_ -match '^description\s*:' } | Select-Object -First 1) -as [string]
            $name = $file.Directory.Name
            $hit = $name -eq $Skill -or @($Keywords | Where-Object { $description -match [regex]::Escape($_) }).Count -gt 0
            if ($hit) { [pscustomobject]@{ Name = $name; Path = $file.Directory.FullName; SkillFile = $file.FullName } }
        }
    }
}

function Get-InstallName {
    # A distinct name keeps global copies of the same skill, which can be older, from standing in for the version under test.
    param([Parameter(Mandatory)][string]$Skill)
    "$Skill-eval"
}

function Install-Skill {
    param([Parameter(Mandatory)][string]$SkillDir, [Parameter(Mandatory)][string]$Workspace)
    $name = Get-InstallName (Split-Path $SkillDir -Leaf)
    foreach ($base in '.claude/skills', '.agents/skills') {
        $dest = Join-Path $Workspace "$base/$name"
        New-Item -ItemType Directory -Force -Path $dest | Out-Null
        $root = (Resolve-Path $SkillDir).Path
        Get-ChildItem -Path $root -Recurse -File -Force |
            Where-Object { $_.FullName.Substring($root.Length) -notmatch '[\\/](bin|obj)[\\/]' } |
            ForEach-Object {
                $target = Join-Path $dest $_.FullName.Substring($root.Length).TrimStart('\', '/')
                New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
                Copy-Item $_.FullName $target
            }
        $entry = Join-Path $dest 'SKILL.md'
        $text = [IO.File]::ReadAllText($entry)
        [IO.File]::WriteAllText($entry, ([regex]'(?m)^name:\s*\S+').Replace($text, "name: $name", 1))
    }
}

function Invoke-Git {
    param([Parameter(Mandatory)][string[]]$Arguments)
    $output = & git -c core.autocrlf=false @Arguments 2>&1 | ForEach-Object { "$_" }
    if ($LASTEXITCODE -ne 0) { throw "git $($Arguments -join ' ') failed: $($output -join "`n")" }
    $output
}

function Get-RepositoryCache {
    # A blobless cache would make each workspace fetch blobs lazily from the remote.
    param([Parameter(Mandatory)]$Repository, [Parameter(Mandatory)][string]$CacheRoot)
    $name = ConvertTo-PathSegment (($Repository.url -replace '\.git$', '') -replace '^.*[/:]([^/:]+/[^/:]+)$', '$1')
    $dir = Join-Path $CacheRoot "repos/$name-$($Repository.commit.Substring(0, 12))"
    if (-not (Test-Path (Join-Path $dir '.git'))) {
        $partial = "$dir.partial-$PID"
        Remove-Item -Recurse -Force $partial -ErrorAction SilentlyContinue
        $null = Invoke-Git @('clone', '--quiet', '--no-checkout', $Repository.url, $partial)
        $null = Invoke-Git @('-C', $partial, 'cat-file', '-e', "$($Repository.commit)^{commit}")
        try { Move-Item $partial $dir -ErrorAction Stop } catch { Remove-Item -Recurse -Force $partial -ErrorAction SilentlyContinue }
    }
    $dir
}

function Initialize-Workspace {
    param([Parameter(Mandatory)][string]$Workspace, $Repository, [Parameter(Mandatory)][string]$CacheRoot, [string]$WorkingTreePatch)
    if ($Repository) {
        $cache = Get-RepositoryCache -Repository $Repository -CacheRoot $CacheRoot
        $null = Invoke-Git @('clone', '--quiet', '--no-checkout', $cache, $Workspace)
        $null = Invoke-Git @('-C', $Workspace, 'config', 'core.autocrlf', 'false')
        $null = Invoke-Git @('-C', $Workspace, 'checkout', '--quiet', '--detach', $Repository.commit)
        if ($WorkingTreePatch) { $null = Invoke-Git @('-C', $Workspace, 'apply', '--whitespace=nowarn', $WorkingTreePatch) }
    } else {
        New-Item -ItemType Directory -Force -Path $Workspace | Out-Null
        # Codex and opencode search for project skills up to the repository root. A repository here stops that search.
        $null = Invoke-Git @('init', '--quiet', $Workspace)
    }
}

function Add-WorkspaceExclusions {
    param([Parameter(Mandatory)][string]$Workspace, [string[]]$Paths)
    $exclude = Join-Path $Workspace '.git/info/exclude'
    New-Item -ItemType Directory -Force -Path (Split-Path $exclude) | Out-Null
    Add-Content -Path $exclude -Value ($Paths | ForEach-Object { '/' + $_.TrimStart('/') }) -Encoding utf8
}

function Get-DotnetSdk {
    param([Parameter(Mandatory)][string]$Workspace)
    if (-not (Get-Command dotnet -CommandType Application -ErrorAction SilentlyContinue)) { return $null }
    Push-Location $Workspace
    try { $v = & dotnet --version 2>&1 | Select-Object -Last 1; if ($LASTEXITCODE -eq 0) { "$v".Trim() } else { $null } } finally { Pop-Location }
}

function Get-IsolatedEnvironment {
    param([Parameter(Mandatory)][string]$RunDir)
    $isoHome = Join-Path $RunDir 'home'
    foreach ($d in '.claude', '.codex', '.config', '.local/share') { New-Item -ItemType Directory -Force -Path (Join-Path $isoHome $d) | Out-Null }
    $nuget = if ($env:NUGET_PACKAGES) { $env:NUGET_PACKAGES } else { Join-Path (Get-UserHome) '.nuget/packages' }
    @{
        HOME                              = $isoHome
        USERPROFILE                       = $isoHome
        XDG_CONFIG_HOME                   = Join-Path $isoHome '.config'
        XDG_DATA_HOME                     = Join-Path $isoHome '.local/share'
        CLAUDE_CONFIG_DIR                 = Join-Path $isoHome '.claude'
        CODEX_HOME                        = Join-Path $isoHome '.codex'
        NUGET_PACKAGES                    = $nuget
        DOTNET_NOLOGO                     = '1'
        DOTNET_SKIP_FIRST_TIME_EXPERIENCE = '1'
        DOTNET_CLI_TELEMETRY_OPTOUT       = '1'
    }
}

function Get-AgentMessage {
    param([string]$Skill, [switch]$WithSkill, [ValidateSet('explicit', 'implicit')][string]$Invocation = 'explicit')
    if ($WithSkill -and $Invocation -eq 'explicit') { "Use the $(Get-InstallName $Skill) skill for this task. $AgentMessage" } else { $AgentMessage }
}

function Get-AgentArguments {
    param([Parameter(Mandatory)]$Target, [Parameter(Mandatory)][string]$Workspace, [Parameter(Mandatory)][string]$Message,
        [switch]$WithSkill, [object[]]$HiddenSkills = @())
    switch ($Target.Agent) {
        'claude' {
            $a = @('-p', '--output-format', 'stream-json', '--verbose', '--dangerously-skip-permissions', '--no-session-persistence')
            if ($Target.Model) { $a += @('--model', $Target.Model) }
            if (-not $WithSkill) { $a += '--disable-slash-commands' }
            @{ Args = $a; Stdin = $Message }
        }
        'codex' {
            $a = @('exec', '--json', '--skip-git-repo-check', '--sandbox', 'danger-full-access', '--ephemeral')
            if ($Target.Model) { $a += @('-m', $Target.Model) }
            $files = @($HiddenSkills | Where-Object { $_.SkillFile -notmatch '[\\/]\.claude[\\/]' } | ForEach-Object { $_.SkillFile.Replace('\', '/') })
            if ($files.Count) { $a += @('-c', ('skills.config=[' + (($files | ForEach-Object { "{path='$_',enabled=false}" }) -join ',') + ']')) }
            @{ Args = $a + '-'; Stdin = $Message }
        }
        'opencode' {
            $a = @('run', '--format', 'json', '--auto', '--pure', '--dir', $Workspace)
            if ($Target.Model) { $a += @('-m', $Target.Model) }
            @{ Args = $a + $Message; Stdin = '' }
        }
    }
}

function Join-Arguments {
    param([string[]]$Arguments)
    ($Arguments | ForEach-Object {
        if ($_ -match '[\s",;=&|<>^()]' -or $_ -eq '') { '"' + ($_ -replace '"', '\"') + '"' } else { $_ }
    }) -join ' '
}

function Invoke-Agent {
    param(
        [Parameter(Mandatory)]$Target,
        [Parameter(Mandatory)][string]$Workspace,
        [Parameter(Mandatory)][string]$RunDir,
        [Parameter(Mandatory)][string]$Message,
        [switch]$WithSkill,
        [object[]]$HiddenSkills = @(),
        [switch]$Isolate,
        [int]$TimeoutMinutes = 30,
        [switch]$DryRun
    )
    $spec = Get-AgentArguments -Target $Target -Workspace $Workspace -Message $Message -WithSkill:$WithSkill -HiddenSkills $HiddenSkills
    $argLine = Join-Arguments $spec.Args
    $result = [ordered]@{
        Command = "$($Target.Agent) $argLine"; ExitCode = $null; TimedOut = $false; Seconds = 0
        Stdout = Join-Path $RunDir 'transcript.jsonl'; Stderr = Join-Path $RunDir 'stderr.txt'
    }
    if ($DryRun) { return [pscustomobject]$result }

    $stdin = Join-Path $RunDir 'stdin.txt'
    Set-Content -Path $stdin -Value $spec.Stdin -Encoding utf8NoBOM
    $startArgs = @{
        FilePath               = Resolve-AgentCommand $Target.Agent
        ArgumentList           = $argLine
        WorkingDirectory       = $Workspace
        RedirectStandardInput  = $stdin
        RedirectStandardOutput = $result.Stdout
        RedirectStandardError  = $result.Stderr
        NoNewWindow            = $true
        PassThru               = $true
    }
    $environment = if ($Isolate) { Get-IsolatedEnvironment -RunDir $RunDir } else { @{} }
    # Start-Process removes a variable whose value is $null.
    foreach ($name in $ParentSessionVariables) { if (Test-Path "env:$name") { $environment[$name] = $null } }
    $names = @($HiddenSkills | ForEach-Object Name | Select-Object -Unique)
    if ($Target.Agent -eq 'opencode' -and $names.Count) {
        $deny = [ordered]@{}
        foreach ($n in $names) { $deny[$n] = 'deny' }
        $environment.OPENCODE_CONFIG_CONTENT = @{ permission = @{ skill = $deny } } | ConvertTo-Json -Depth 5 -Compress
    }
    if ($environment.Count) { $startArgs.Environment = $environment }
    $result.Environment = @($environment.Keys | Where-Object { $null -ne $environment[$_] })

    $clock = [Diagnostics.Stopwatch]::StartNew()
    # Start-Process without -Wait: -Wait also waits for every descendant, and agent plugins can outlive the agent.
    $p = Start-Process @startArgs
    $null = $p.Handle
    if (-not $p.WaitForExit($TimeoutMinutes * 60000)) {
        $result.TimedOut = $true
        try { $p.Kill($true) } catch { }
        $null = $p.WaitForExit(10000)
    }
    $clock.Stop()
    $result.Seconds = $clock.Elapsed.TotalSeconds
    $result.ExitCode = if ($p.HasExited) { $p.ExitCode } else { $null }
    [pscustomobject]$result
}

function ConvertFrom-JsonLines {
    param([string]$Path)
    if (-not (Test-Path $Path)) { return }
    foreach ($line in Get-Content $Path) {
        if ($line.TrimStart().StartsWith('{')) {
            try { $line | ConvertFrom-Json -Depth 64 } catch { }
        }
    }
}

function Get-Number($Object, [string]$Name) {
    if ($null -ne $Object -and $Object.PSObject.Properties[$Name] -and $null -ne $Object.$Name) { [double]$Object.$Name } else { 0 }
}

function Find-TokenObjects($Node) {
    if ($null -eq $Node -or $Node -is [string] -or $Node -is [ValueType]) { return }
    if ($Node -is [System.Collections.IEnumerable]) { foreach ($item in $Node) { Find-TokenObjects $item }; return }
    foreach ($prop in $Node.PSObject.Properties) {
        if ($prop.Name -eq 'tokens' -and $prop.Value -and $prop.Value.PSObject.Properties['input']) { $prop.Value }
        else { Find-TokenObjects $prop.Value }
    }
}

$ShellWrapperPattern = '(?s)^\s*(?:"[^"]*|[^\s"]*)(?<![\w-])(?:pwsh|powershell|bash|sh|zsh)(?:\.exe)?"?(?:\s+-\w+)*?\s+-(?:Command|c|lc)\s+(?<script>.+)$'
$DotnetCommandPattern = '(?:^|[;&|({\r\n])\s*(?:[^\s;&|]*[\\/])?dotnet(?:\.exe)?\s+(?<verb>build|test|run|fsi|publish|pack|msbuild)(?![\w-])'
$CompilerErrorPattern = '(?m)\berror (?:FS|CS|MSB|NU)\d+|\bBuild FAILED\b'

function Get-DotnetVerbs {
    param([string]$Command)
    $script = $Command
    if ($script -match $ShellWrapperPattern) {
        $script = [regex]::Replace($Matches.script.Trim(), '"((?:\\.|[^"\\])*)"|''([^'']*)''', {
                param($q) if ($q.Groups[1].Success) { $q.Groups[1].Value -replace '\\(["\\$`])', '$1' } else { $q.Groups[2].Value } })
    }
    $script = $script -replace '["'']([^"'']*[\\/])?dotnet(\.exe)?["'']', 'dotnet'
    $script = $script -replace "'[^']*'", "''" -replace '"[^"]*"', '""'
    @([regex]::Matches($script, $DotnetCommandPattern) | ForEach-Object { $_.Groups['verb'].Value })
}

function Get-JsonText($Object, [string]$Name) {
    if ($null -eq $Object -or -not $Object.PSObject.Properties[$Name] -or $null -eq $Object.$Name) { return '' }
    $value = $Object.$Name
    if ($value -is [string]) { return $value }
    $message = @($value.PSObject.Properties | Where-Object Name -eq 'message' | ForEach-Object Value) + @($value.PSObject.Properties | Where-Object Name -eq 'data' | ForEach-Object { Get-JsonText $_.Value 'message' })
    $text = @($message | Where-Object { $_ }) | Select-Object -First 1
    if ($text) { "$text" } else { $value | ConvertTo-Json -Depth 5 -Compress }
}

function Get-UnrecoveredError([object[]]$Events, [string[]]$FatalTypes, [string[]]$ErrorTypes, [string]$ProgressType) {
    $typed = @($Events | Where-Object { $_.PSObject.Properties['type'] })
    $fatal = $typed | Where-Object { $_.type -in $FatalTypes } | Select-Object -First 1
    if ($fatal) { return $fatal }
    for ($i = 0; $i -lt $typed.Count; $i++) {
        if ($typed[$i].type -notin $ErrorTypes) { continue }
        $later = @($typed | Select-Object -Skip ($i + 1) | Where-Object { $_.type -eq $ProgressType })
        if ($later.Count -eq 0) { return $typed[$i] }
    }
    $null
}

function Get-RunError {
    # A process can exit with an error before it writes an error event. A timed-out run is a failed attempt, not an agent error.
    param($Metrics, $ExitCode, [bool]$TimedOut)
    if ($Metrics.AgentError) { return $Metrics.AgentError }
    if (-not $TimedOut -and $null -ne $ExitCode -and $ExitCode -ne 0) { return "The agent process exited with code $ExitCode." }
    $null
}

function Get-ContentText($Content) {
    if ($null -eq $Content) { return '' }
    if ($Content -is [string]) { return $Content }
    (@($Content) | ForEach-Object { if ($_ -is [string]) { $_ } elseif ($_.PSObject.Properties['text']) { "$($_.text)" } }) -join "`n"
}

function Get-CommandFailure {
    # A test command that does not compile is a failed build. A test command that compiles and fails is a failed test run.
    param([string]$Command, [bool]$Failed, [string]$Output)
    $verbs = @(Get-DotnetVerbs $Command)
    if ($verbs.Count -eq 0) { return $null }
    $compileError = $Output -match $CompilerErrorPattern
    if ($compileError) { return 'build' }
    if (-not $Failed) { return $null }
    if ($verbs -contains 'test') { 'test' } else { 'build' }
}

function Add-CommandFailure($Metrics, [string]$Command, [bool]$Failed, [string]$Output) {
    switch (Get-CommandFailure $Command $Failed $Output) {
        'build' { $Metrics.FailedBuilds++ }
        'test' { $Metrics.FailedTestRuns++ }
    }
}

function Get-AgentMetrics {
    param([Parameter(Mandatory)][string]$Agent, [Parameter(Mandatory)][string]$TranscriptPath, [Parameter(Mandatory)][string]$Skill, [switch]$NoGlobalCheck)
    $m = [ordered]@{ InputTokens = $null; OutputTokens = $null; CostUsd = $null; Turns = $null; FailedBuilds = $null; FailedTestRuns = $null
        SkillUsed = $false; GlobalSkillUsed = $false; AgentError = $null }
    if (-not $NoGlobalCheck -and (Test-Path $TranscriptPath)) {
        $installed = Get-InstallName $Skill
        if ($Skill -ne $installed) {
            $global = Get-AgentMetrics -Agent $Agent -TranscriptPath $TranscriptPath -Skill $Skill -NoGlobalCheck
            $m.GlobalSkillUsed = $global.SkillUsed
        }
    }
    if (-not (Test-Path $TranscriptPath)) { return [pscustomobject]$m }
    $events = @(ConvertFrom-JsonLines $TranscriptPath)
    if ($events.Count -eq 0) { $m.AgentError = 'The transcript has no JSON events.'; return [pscustomobject]$m }
    # Only tool output with the skill's frontmatter name line, or a completed skill tool call, proves a load.
    $lookFor = if ($NoGlobalCheck) { $Skill } else { Get-InstallName $Skill }
    $frontmatter = 'name:\s*' + [regex]::Escape($lookFor) + '(?![\w-])'
    $m.FailedBuilds = 0
    $m.FailedTestRuns = 0

    switch ($Agent) {
        'claude' {
            $final = $events | Where-Object { $_.PSObject.Properties['type'] -and $_.type -eq 'result' } | Select-Object -Last 1
            if ($final) {
                $u = $final.usage
                $m.InputTokens = (Get-Number $u 'input_tokens') + (Get-Number $u 'cache_creation_input_tokens') + (Get-Number $u 'cache_read_input_tokens')
                $m.OutputTokens = Get-Number $u 'output_tokens'
                $m.CostUsd = Get-Number $final 'total_cost_usd'
                if ($final.PSObject.Properties['num_turns']) { $m.Turns = [int]$final.num_turns }
                if ($final.PSObject.Properties['is_error'] -and $final.is_error) { $m.AgentError = "$($final.subtype): $(Get-JsonText $final 'result')" }
            }
            $skillCalls = @{}
            $commands = @{}
            $toolCalls = 0
            foreach ($e in $events | Where-Object { $_.PSObject.Properties['type'] -and $_.type -eq 'assistant' }) {
                foreach ($c in @($e.message.content)) {
                    if ($c.type -ne 'tool_use') { continue }
                    if ($c.name -eq 'Skill' -and $c.input.PSObject.Properties['skill'] -and "$($c.input.skill)" -eq $lookFor) { $skillCalls[$c.id] = $true }
                    $toolCalls++
                    if ($c.input.PSObject.Properties['command']) { $commands[$c.id] = "$($c.input.command)" }
                }
            }
            foreach ($e in $events | Where-Object { $_.PSObject.Properties['type'] -and $_.type -eq 'user' }) {
                foreach ($c in @($e.message.content)) {
                    if ($c -isnot [psobject] -or -not $c.PSObject.Properties['type'] -or $c.type -ne 'tool_result') { continue }
                    $failed = [bool]($c.PSObject.Properties['is_error'] -and $c.is_error)
                    $text = if ($c.PSObject.Properties['content']) { $c.content | ConvertTo-Json -Depth 10 } else { '' }
                    if (-not $failed -and ($skillCalls.ContainsKey($c.tool_use_id) -or $text -match $frontmatter)) { $m.SkillUsed = $true }
                    if ($commands.ContainsKey($c.tool_use_id)) { Add-CommandFailure $m $commands[$c.tool_use_id] $failed (Get-ContentText $c.content) }
                }
            }
            # A stopped Claude run has no result event.
            if ($null -eq $m.Turns) { $m.Turns = $toolCalls + 1 }
        }
        'codex' {
            $turns = @($events | Where-Object { $_.PSObject.Properties['type'] -and $_.type -eq 'turn.completed' })
            if ($turns.Count) {
                $m.InputTokens = ($turns | ForEach-Object { Get-Number $_.usage 'input_tokens' } | Measure-Object -Sum).Sum
                $m.OutputTokens = ($turns | ForEach-Object { Get-Number $_.usage 'output_tokens' } | Measure-Object -Sum).Sum
            }
            # Codex also emits an error event for a stream error that it retries. Such a run can still complete a turn.
            $errorEvent = Get-UnrecoveredError $events @('turn.failed') @('error') 'turn.completed'
            if ($errorEvent) { $m.AgentError = "$(Get-JsonText $errorEvent 'message')$(Get-JsonText $errorEvent 'error')" }
            $completed = @($events | Where-Object { $_.PSObject.Properties['type'] -and $_.type -eq 'item.completed' })
            # Codex exec emits no event for each model request.
            $m.Turns = @($completed | Where-Object { $_.item.type -notin 'agent_message', 'reasoning', 'error' }).Count + 1
            foreach ($e in $completed) {
                $item = $e.item
                $output = if ($item.PSObject.Properties['aggregated_output']) { "$($item.aggregated_output)" } else { '' }
                if ($output -match $frontmatter) { $m.SkillUsed = $true }
                if ($item.type -eq 'command_execution') {
                    $failed = ($item.PSObject.Properties['exit_code'] -and $null -ne $item.exit_code -and $item.exit_code -ne 0) -or
                        ($item.PSObject.Properties['status'] -and $item.status -eq 'failed')
                    Add-CommandFailure $m "$($item.command)" $failed $output
                }
            }
        }
        'opencode' {
            $errorEvent = Get-UnrecoveredError $events @() @('error') 'step_finish'
            if ($errorEvent) { $m.AgentError = Get-JsonText $errorEvent 'error' }
            $steps = @($events | Where-Object { $_.PSObject.Properties['type'] -and $_.type -eq 'step_finish' })
            $tokens = @($steps | ForEach-Object { Find-TokenObjects $_ })
            if ($tokens.Count) {
                $m.InputTokens = ($tokens | ForEach-Object { $cache = if ($_.PSObject.Properties['cache']) { $_.cache } else { $null }; (Get-Number $_ 'input') + (Get-Number $cache 'read') + (Get-Number $cache 'write') } | Measure-Object -Sum).Sum
                $m.OutputTokens = ($tokens | ForEach-Object { (Get-Number $_ 'output') + (Get-Number $_ 'reasoning') } | Measure-Object -Sum).Sum
            }
            $costs = @($steps | ForEach-Object { if ($_.PSObject.Properties['part'] -and $_.part.PSObject.Properties['cost']) { [double]$_.part.cost } })
            if ($costs.Count) { $m.CostUsd = ($costs | Measure-Object -Sum).Sum }
            $m.Turns = $steps.Count
            foreach ($e in $events | Where-Object { $_.PSObject.Properties['type'] -and $_.type -eq 'tool_use' }) {
                $state = $e.part.state
                $output = if ($state.PSObject.Properties['output']) { "$($state.output)" } else { '' }
                if ($state.PSObject.Properties['input'] -and $state.input.PSObject.Properties['command']) {
                    $meta = if ($state.PSObject.Properties['metadata']) { $state.metadata } else { $null }
                    $exit = if ($meta -and $meta.PSObject.Properties['exit']) { $meta.exit } else { $null }
                    $failed = $state.status -eq 'error' -or ($null -ne $exit -and $exit -ne 0)
                    Add-CommandFailure $m "$($state.input.command)" $failed $output
                }
                if ($state.status -ne 'completed') { continue }
                $isSkillTool = $e.part.tool -eq 'skill' -and $state.input.PSObject.Properties['name'] -and "$($state.input.name)" -eq $lookFor
                if ($isSkillTool -or $output -match $frontmatter) { $m.SkillUsed = $true }
            }
        }
    }
    [pscustomobject]$m
}

function Get-Mean([object[]]$Values) {
    $v = @($Values | Where-Object { $null -ne $_ })
    if ($v.Count -eq 0) { return $null }
    ($v | Measure-Object -Average).Average
}

function Get-RunValue($Run, [string]$Name) {
    if ($Run.PSObject.Properties[$Name]) { $Run.$Name } else { $null }
}

function Format-Mean([object[]]$Values) {
    $mean = Get-Mean $Values
    if ($null -ne $mean) { '{0:n1}' -f $mean } else { '-' }
}

function Test-CountedRun($Run) {
    # A with-skill run counts only when it loaded the installed copy. No run counts when it loaded a global copy or the agent failed to run.
    if (Get-RunValue $Run 'globalSkillUsed') { return $false }
    if (Get-RunValue $Run 'agentError') { return $false }
    $Run.mode -ne 'with' -or [bool](Get-RunValue $Run 'skillUsed')
}

function Read-RunResults {
    param([Parameter(Mandatory)][string]$Root)
    Get-ChildItem -Path $Root -Filter 'run.json' -Recurse -Depth 1 -File | Sort-Object FullName | ForEach-Object { Get-Content -Raw $_.FullName | ConvertFrom-Json }
}

function Write-Summary {
    param([Parameter(Mandatory)][object[]]$Results, [Parameter(Mandatory)][string]$Root, [string]$Skill, [AllowNull()][object[]]$Contamination = @())
    $Contamination = @($Contamination | Where-Object { $_ })
    $skills = @($Results | ForEach-Object { Get-RunValue $_ 'skill' } | Where-Object { $_ } | Select-Object -Unique)
    if (-not $skills.Count -and $Skill) { $skills = @($Skill) }
    $lines = @("# Eval results: $($skills -join ', ')", '')
    $lines += 'A with-skill run counts only when its transcript shows that the agent loaded the installed skill. A run that loaded a global copy of the skill does not count in either mode.'
    $lines += ''
    if ($Contamination.Count) {
        $lines += 'Global skills that Codex and opencode runs hide (Claude baselines disable all skills):'
        $lines += ($Contamination | ForEach-Object { "- $($_.Name): $($_.Path)" })
        $lines += ''
    }
    $sdks = @($Results | ForEach-Object { Get-RunValue $_ 'dotnetSdk' } | Where-Object { $_ } | Select-Object -Unique)
    if ($sdks.Count) { $lines += ".NET SDK in the workspaces: $($sdks -join ', ')"; $lines += '' }
    $lines += '| Target | Task | Skill | Counted runs | Pass rate | Skipped | Seconds | Tokens | Cost (USD) | Turns | Failed builds | Failed test runs | Not loaded | Global copy | Agent error |'
    $lines += '|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|'
    foreach ($g in $Results | Sort-Object target, task, @{ Expression = { $_.mode -ne 'with' } } | Group-Object target, task, mode) {
        $all = @($g.Group)
        $r = @($all | Where-Object { Test-CountedRun $_ })
        $errored = @($all | Where-Object { Get-RunValue $_ 'agentError' }).Count
        $global = @($all | Where-Object { -not (Get-RunValue $_ 'agentError') -and (Get-RunValue $_ 'globalSkillUsed') }).Count
        $notLoaded = @($all | Where-Object { -not (Get-RunValue $_ 'agentError') -and $_.mode -eq 'with' -and -not (Get-RunValue $_ 'skillUsed') -and -not (Get-RunValue $_ 'globalSkillUsed') }).Count
        if ($r.Count -eq 0) {
            $lines += '| {0} | {1} | {2} | 0 | - | - | - | - | - | - | - | - | {3} | {4} | {5} |' -f $all[0].target, $all[0].task, $all[0].mode, $notLoaded, $global, $errored
            continue
        }
        $rate = Get-Mean ($r | ForEach-Object { if (($_.passed + $_.failed) -gt 0) { $_.passed / ($_.passed + $_.failed) } })
        $tok = Get-Mean ($r | ForEach-Object { if ($null -ne (Get-RunValue $_ 'inputTokens')) { $_.inputTokens + $_.outputTokens } })
        $cost = Get-Mean ($r | ForEach-Object { Get-RunValue $_ 'costUsd' })
        $lines += '| {0} | {1} | {2} | {3} | {4} | {5} | {6} | {7} | {8} | {9} | {10} | {11} | {12} | {13} | {14} |' -f $r[0].target, $r[0].task, $r[0].mode, $r.Count,
            $(if ($null -ne $rate) { '{0:p0}' -f $rate } else { '-' }),
            (($r | Measure-Object skipped -Sum).Sum),
            ('{0:n0}' -f (Get-Mean $r.seconds)),
            $(if ($null -ne $tok) { '{0:n0}' -f $tok } else { '-' }),
            $(if ($null -ne $cost -and $cost -gt 0) { '{0:n2}' -f $cost } else { '-' }),
            (Format-Mean ($r | ForEach-Object { Get-RunValue $_ 'turns' })),
            (Format-Mean ($r | ForEach-Object { Get-RunValue $_ 'failedBuilds' })),
            (Format-Mean ($r | ForEach-Object { Get-RunValue $_ 'failedTestRuns' })),
            $notLoaded, $global, $errored
    }
    $lines += ''
    $lines += '## Checks'
    foreach ($g in $Results | Sort-Object target, task | Group-Object target, task) {
        $lines += ''
        $lines += "### $($g.Group[0].target) | $($g.Group[0].task)"
        $lines += ''
        $lines += '| Check | With skill | Without skill |'
        $lines += '|---|---|---|'
        $counted = @($g.Group | Where-Object { Test-CountedRun $_ })
        $texts = @($g.Group | ForEach-Object { $_.checks } | ForEach-Object { $_.text } | Select-Object -Unique)
        foreach ($text in $texts) {
            $cells = foreach ($mode in 'with', 'without') {
                $hits = @($counted | Where-Object mode -eq $mode | ForEach-Object { $_.checks } | Where-Object text -eq $text)
                if ($hits.Count -eq 0) { '-' }
                else { '{0}/{1}' -f @($hits | Where-Object { $_.passed -eq $true }).Count, @($hits | Where-Object { $null -ne $_.passed }).Count }
            }
            $lines += "| $($text -replace '\|', '\|') | $($cells[0]) | $($cells[1]) |"
        }
    }
    $text = $lines -join "`n"
    Set-Content -Path (Join-Path $Root 'summary.md') -Value $text -Encoding utf8
    $text
}

Export-ModuleMember -Function ConvertTo-AgentTarget, ConvertTo-PathSegment, Get-AgentMessage, Get-InstallName, Resolve-AgentCommand, Find-ConflictingSkills,
    Install-Skill, Initialize-Workspace, Add-WorkspaceExclusions, Get-DotnetSdk, Invoke-Agent, Get-AgentMetrics, Get-CommandFailure, Read-RunResults,
    Test-CountedRun, Get-RunError, Write-Summary
