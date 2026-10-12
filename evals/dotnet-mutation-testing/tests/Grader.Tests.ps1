#!/usr/bin/env pwsh
#Requires -Version 7.4
<#
.SYNOPSIS
Grades a known-good and a known-bad workspace for the require-guards task. Needs git, network access, the .NET SDK that FsToolkit.ErrorHandling selects, and the .NET 9 runtime.
#>
param()
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Import-Module (Join-Path $PSScriptRoot '../../lib/Agents.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../../lib/Grading.psm1') -Force
$evalDir = Split-Path $PSScriptRoot
$task = Get-TaskSpec -EvalDir $evalDir -TaskId 'require-guards'
$grader = Join-Path $evalDir $task.grader
$failures = [System.Collections.Generic.List[string]]::new()

function New-TaskWorkspace([string]$Path) {
    Initialize-Workspace -Workspace $Path -Repository $task.repository -CacheRoot (Get-EvalCacheRoot) -WorkingTreePatch (Join-Path $evalDir $task.workingTreePatch)
    Copy-Item (Join-Path $evalDir 'inputs/mutants') $Path -Recurse
}

function Invoke-Grader([string]$Workspace) {
    $out = Join-Path $Workspace '../grade'
    New-Item -ItemType Directory -Force -Path $out | Out-Null
    & $grader -Workspace $Workspace -OutDir $out | Out-Null
    @(Get-Content -Raw (Join-Path $out 'grading.json') | ConvertFrom-Json)
}

function Assert-Checks([object[]]$Checks, [hashtable]$Expected, [string]$Name) {
    foreach ($c in $Checks) {
        $want = if ($Expected.ContainsKey($c.text)) { $Expected[$c.text] } else { $Expected['*'] }
        if ($c.passed -ne $want -or ($null -eq $want) -ne ($null -eq $c.passed)) { $failures.Add("${Name}: '$($c.text)' expected $want, got $($c.passed). $($c.evidence)") }
    }
}

$root = New-TempDirectory
try {
    $good = Join-Path $root 'good/ws'
    New-TaskWorkspace $good
    Copy-Item (Join-Path $PSScriptRoot 'known-good/mutation-report.json') $good
    $checks = Invoke-Grader $good
    if ($checks.Count -ne 10) { $failures.Add("good: expected 10 checks, got $($checks.Count)") }
    Assert-Checks $checks @{ '*' = $true } 'good'

    $report = Get-Content -Raw (Join-Path $PSScriptRoot 'known-good/mutation-report.json') | ConvertFrom-Json
    ($report.mutants | Where-Object id -eq 'M1').failingTests = @('happy path')
    $report | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $good 'mutation-report.json') -Encoding utf8
    $checks = Invoke-Grader $good
    Assert-Checks $checks @{
        '*' = $true
        "failingTests lists only tests that failed in the grader's run, and at least one for each detected mutant" = $false
    } 'good report with a partial test name'

    $broken = Join-Path $root 'broken/ws'
    New-TaskWorkspace $broken
    Copy-Item (Join-Path $PSScriptRoot 'known-good/mutation-report.json') $broken
    Set-Content -Path (Join-Path $broken 'global.json') -Value '{ "sdk": { "version": "1.0.0", "rollForward": "disable" } }' -Encoding utf8
    $checks = Invoke-Grader $broken
    Assert-Checks $checks @{ '*' = $true; 'The final tree builds and all tests pass' = $false } 'good report with a broken global.json'

    $untracked = Join-Path $root 'untracked/ws'
    New-TaskWorkspace $untracked
    Copy-Item (Join-Path $PSScriptRoot 'known-good/mutation-report.json') $untracked
    Set-Content -Path (Join-Path $untracked 'tests/FsToolkit.ErrorHandling.Tests/FsToolkit.ErrorHandling.Tests.fsproj.user') -Value '<Project><Import Project="missing.targets" /></Project>' -Encoding utf8
    $checks = Invoke-Grader $untracked
    Assert-Checks $checks @{ '*' = $true; 'The final tree builds and all tests pass' = $false } 'good report with a broken ignored .user file'

    $bad = Join-Path $root 'bad/ws'
    New-TaskWorkspace $bad
    Copy-Item (Join-Path $PSScriptRoot 'known-bad/mutation-report.json') $bad
    $null = Invoke-Capture git @('apply', (Join-Path $evalDir 'inputs/mutants/M1.patch')) -WorkingDirectory $bad
    $null = Invoke-Capture git @('checkout', '--', 'tests') -WorkingDirectory $bad
    $checks = Invoke-Grader $bad
    Assert-Checks $checks @{
        '*'                                                                    = $false
        'mutation-report.json has a baseline and an entry for each mutant'    = $true
        "M1 detected value matches the grader's test run"                      = $true
        "M4 detected value matches the grader's test run"                      = $true
    } 'bad'
} finally {
    Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
}

if ($failures.Count) { $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }; exit 1 }
Write-Host 'require-guards grader tests passed.'
