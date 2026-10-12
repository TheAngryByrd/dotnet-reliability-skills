param(
    [Parameter(Mandatory)][string]$Workspace,
    [Parameter(Mandatory)][string]$OutDir
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Import-Module (Join-Path $PSScriptRoot '../../lib/Grading.psm1') -Force

$evalDir = Split-Path $PSScriptRoot
$task = Get-TaskSpec -EvalDir $evalDir -TaskId 'require-guards'
$commit = $task.repository.commit
$workingTreePatch = Join-Path $evalDir $task.workingTreePatch
$project = 'tests/FsToolkit.ErrorHandling.Tests/FsToolkit.ErrorHandling.Tests.fsproj'
$testArguments = @('-f', 'net9.0', '-c', 'Release')
$mutantIds = @('M1', 'M2', 'M3', 'M4')
# Change this value when the outcome rules change, so cached outcomes from older rules are not used.
$outcomeVersion = '3'

function Get-Sha256([string]$Text) {
    [Convert]::ToHexString([Security.Cryptography.SHA256]::HashData([Text.Encoding]::UTF8.GetBytes($Text))).ToLowerInvariant()
}

function Get-TrackedDiff([string]$Repository, [string]$Path) {
    $r = Invoke-Capture git @('-c', 'core.autocrlf=false', 'diff', '--no-color', '--no-ext-diff', 'HEAD', '--', $Path) -WorkingDirectory $Repository
    if ($r.ExitCode -ne 0) { throw "git diff failed in ${Repository}: $($r.Text)" }
    $r.Text.Trim()
}

function ConvertTo-Outcome($Run) {
    [pscustomobject]@{ verdict = $Run.Verdict; total = $Run.Total; passed = $Run.Passed; failed = @($Run.Failed); exitCode = $Run.ExitCode; log = (Get-LastLines $Run.Log 20) }
}

function Get-Outcome([string]$Source, [string]$PatchPath) {
    # The outcome depends only on the commit, the patches, and the test command, so graders share it through the cache.
    $patch = if ($PatchPath) { [IO.File]::ReadAllText($PatchPath) } else { '' }
    $key = Get-Sha256 ($outcomeVersion + "`n" + $commit + "`n" + ($testArguments -join ' ') + "`n" + [IO.File]::ReadAllText($workingTreePatch) + "`n" + $patch)
    $cacheFile = Join-Path (Get-EvalCacheRoot) "require-guards/$key.json"
    if (Test-Path $cacheFile) { return Get-Content -Raw $cacheFile | ConvertFrom-Json }
    $temp = New-TempDirectory
    try {
        $repo = Join-Path $temp 'repo'
        Copy-RepositorySnapshot -Source $Source -Commit $commit -Destination $repo
        foreach ($p in @($workingTreePatch, $PatchPath) | Where-Object { $_ }) {
            $apply = Invoke-Capture git @('apply', '--whitespace=nowarn', $p) -WorkingDirectory $repo
            if ($apply.ExitCode -ne 0) { throw "The patch $p does not apply at ${commit}: $($apply.Text)" }
        }
        $outcome = ConvertTo-Outcome (Invoke-DotnetTest -Repository $repo -Project $project -Arguments $testArguments)
        if (-not $PatchPath) { $outcome | Add-Member -NotePropertyName testsDiff -NotePropertyValue (Get-TrackedDiff $repo 'tests') }
        if ($outcome.verdict -ne 'inconclusive') {
            New-Item -ItemType Directory -Force -Path (Split-Path $cacheFile) | Out-Null
            $partial = "$cacheFile.$PID.tmp"
            $outcome | ConvertTo-Json -Depth 5 | Set-Content -Path $partial -Encoding utf8
            Move-Item -Force $partial $cacheFile
        }
        $outcome
    } finally {
        Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
    }
}

function Test-SameTest([string]$Reported, [string]$Actual) {
    # Expecto joins test list names with '.'. A report can give the full name or the test case name after the last '.'.
    $r = $Reported.Trim(); $a = $Actual.Trim()
    $r -eq $a -or $r -eq ($a -split '\.')[-1].Trim()
}

$checks = @()
$baseline = Get-Outcome -Source $Workspace -PatchPath $null
if ($baseline.verdict -ne 'survived') { throw "The task tree does not pass its tests ($($baseline.verdict)): $($baseline.log)" }
$truth = [ordered]@{}
foreach ($id in $mutantIds) {
    $truth[$id] = Get-Outcome -Source $Workspace -PatchPath (Join-Path $evalDir "inputs/mutants/$id.patch")
    if ($truth[$id].verdict -eq 'inconclusive') { throw "The grader could not run $id (infrastructure failure): $($truth[$id].log)" }
}

$report = Read-JsonFile (Join-Path $Workspace 'mutation-report.json')
$entries = @{}
foreach ($m in @(Get-JsonField $report 'mutants')) { if ($m -and (Get-JsonField $m 'id')) { $entries["$($m.id)"] = $m } }
$reportBaseline = Get-JsonField $report 'baseline'
$complete = $null -ne $report -and $null -ne $reportBaseline -and @($mutantIds | Where-Object { -not $entries.ContainsKey($_) }).Count -eq 0
$checks += New-Check 'mutation-report.json has a baseline and an entry for each mutant' $complete $(if ($complete) { '' } else { "ids: $($entries.Keys -join ', ')" })

$passed = Get-JsonField $reportBaseline 'passed'
$failed = Get-JsonField $reportBaseline 'failed'
$baselineOk = $passed -is [ValueType] -and $passed -isnot [bool] -and $failed -is [ValueType] -and $failed -isnot [bool] -and [int]$passed -gt 0 -and [int]$failed -eq 0
$checks += New-Check 'The report records a green baseline: passed tests and no failures' $baselineOk "passed: $passed, failed: $failed"

foreach ($id in $mutantIds) {
    $expected = $truth[$id].verdict -eq 'detected'
    $actual = Get-JsonField $entries[$id] 'detected'
    $ok = $actual -is [bool] -and $actual -eq $expected
    $checks += New-Check "$id detected value matches the grader's test run" $ok "grader: $($truth[$id].verdict) (expected detected=$expected), report: detected=$actual"
}

$namesOk = $true
$namesEvidence = @()
foreach ($id in $mutantIds) {
    $reported = @(Get-JsonField $entries[$id] 'failingTests' | Where-Object { $_ } | ForEach-Object { "$_" })
    $actual = @($truth[$id].failed)
    $unknown = @($reported | Where-Object { $r = $_; -not @($actual | Where-Object { Test-SameTest $r $_ }).Count })
    $missing = $actual.Count -gt 0 -and $reported.Count -eq 0
    if ($unknown.Count -or $missing) { $namesOk = $false; $namesEvidence += "${id}: not failed in the grader's run [$($unknown -join '; ')]$(if ($missing) { ', none listed' })" }
}
$checks += New-Check "failingTests lists only tests that failed in the grader's run, and at least one for each detected mutant" $namesOk ($namesEvidence -join ' | ')

$head = (Invoke-Capture git @('rev-parse', 'HEAD') -WorkingDirectory $Workspace).Text.Trim()
$srcDiff = Get-TrackedDiff $Workspace 'src'
$noMutant = $head -eq $commit -and -not $srcDiff
$checks += New-Check 'No mutant remains: HEAD is the task commit and src/ has no change' $noMutant "HEAD: $head; src diff: $(Get-LastLines $srcDiff 6)"

$testsDiff = Get-TrackedDiff $Workspace 'tests'
$wipKept = $head -eq $commit -and $testsDiff -eq $baseline.testsDiff
$checks += New-Check "The user's uncommitted test change is still present and unchanged" $wipKept $(if ($wipKept) { '' } else { "tests diff: $(Get-LastLines $testsDiff 8)" })

# The final tree runs as a copy of the whole workspace, so a changed root build file or untracked input also counts.
$temp = New-TempDirectory
try {
    $copy = Join-Path $temp 'repo'
    $root = (Resolve-Path $Workspace).Path
    Get-ChildItem -Path $root -Recurse -File -Force |
        Where-Object { $_.FullName.Substring($root.Length) -notmatch '[\\/](bin|obj|\.eval-results)[\\/]' } |
        ForEach-Object {
            $target = Join-Path $copy $_.FullName.Substring($root.Length).TrimStart('\', '/')
            New-Item -ItemType Directory -Force -Path (Split-Path $target) | Out-Null
            Copy-Item $_.FullName $target
        }
    $final = ConvertTo-Outcome (Invoke-DotnetTest -Repository $copy -Project $project -Arguments $testArguments)
} finally {
    Remove-Item -Recurse -Force $temp -ErrorAction SilentlyContinue
}
# An inconclusive run of an unchanged build is a grader failure. With changed build inputs, the agent's change can be the cause.
# Ignored files count too: MSBuild imports an ignored <project>.user file.
$untracked = Invoke-Capture git @('-c', 'core.quotepath=false', 'ls-files', '--others') -WorkingDirectory $Workspace
$buildInputPattern = '(^|/)(global\.json|nuget\.config|Directory\.[^/]+|paket\.[^/]+|[^/]+\.(fsproj|csproj|sln|slnx|props|targets|user))$'
$newBuildInputs = @($untracked.Lines | Where-Object { $_ -match $buildInputPattern -and $_ -notmatch '(^|/)(bin|obj|\.eval-results)/' })
$trackedOther = @((Invoke-Capture git @('-c', 'core.quotepath=false', 'diff', '--name-only', 'HEAD') -WorkingDirectory $Workspace).Lines |
        Where-Object { $_ -and $_ -notmatch '^(src|tests)/' })
$buildUnchanged = $noMutant -and $wipKept -and $newBuildInputs.Count -eq 0 -and $trackedOther.Count -eq 0
if ($final.verdict -eq 'inconclusive' -and $buildUnchanged) { throw "The grader could not run the final tree (infrastructure failure): $($final.log)" }
$finalOk = $final.verdict -eq 'survived' -and $final.passed -eq $baseline.passed
$checks += New-Check 'The final tree builds and all tests pass' $finalOk "verdict: $($final.verdict), passed: $($final.passed)/$($baseline.passed), failed: $($final.failed -join '; ')"

Write-Checks (Join-Path $OutDir 'grading.json') $checks
