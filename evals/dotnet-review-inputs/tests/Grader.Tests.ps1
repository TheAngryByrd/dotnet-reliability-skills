#!/usr/bin/env pwsh
#Requires -Version 7.4
<#
.SYNOPSIS
Grades a known-good and a known-bad workspace for the icedtasks-properties task. Needs git, network access, and the rubric judge (SKILL_EVAL_JUDGE).
#>
param()
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Import-Module (Join-Path $PSScriptRoot '../../lib/Agents.psm1') -Force
Import-Module (Join-Path $PSScriptRoot '../../lib/Grading.psm1') -Force
$evalDir = Split-Path $PSScriptRoot
$task = Get-TaskSpec -EvalDir $evalDir -TaskId 'icedtasks-properties'
$grader = Join-Path $evalDir $task.grader
$failures = [System.Collections.Generic.List[string]]::new()

function Invoke-Grader([string]$Workspace) {
    $out = Join-Path $Workspace '../grade'
    New-Item -ItemType Directory -Force -Path $out | Out-Null
    & $grader -Workspace $Workspace -OutDir $out | Out-Null
    @(Get-Content -Raw (Join-Path $out 'grading.json') | ConvertFrom-Json)
}

$root = New-TempDirectory
try {
    $good = Join-Path $root 'good/ws'
    Initialize-Workspace -Workspace $good -Repository $task.repository -CacheRoot (Get-EvalCacheRoot)
    Copy-Item (Join-Path $PSScriptRoot 'known-good/review.md') $good
    $checks = Invoke-Grader $good
    $expectedCount = 4 + @($task.rubric).Count
    if ($checks.Count -ne $expectedCount) { $failures.Add("good: expected $expectedCount checks, got $($checks.Count)") }
    foreach ($c in $checks | Where-Object { $_.passed -ne $true }) { $failures.Add("good: '$($c.text)' expected True, got '$($c.passed)'. $($c.evidence)") }

    $bad = Join-Path $root 'bad/ws'
    Initialize-Workspace -Workspace $bad -Repository $task.repository -CacheRoot (Get-EvalCacheRoot)
    Copy-Item (Join-Path $PSScriptRoot 'known-bad/review.md') $bad
    Add-Content -Path (Join-Path $bad 'tests/IcedTasks.Tests/Expect.fs') -Value '// changed'
    $checks = Invoke-Grader $bad
    $expectTrue = @('review.md exists and is not empty', 'The review cites at least one source location as file:line')
    foreach ($c in $checks) {
        $want = $c.text -in $expectTrue
        if ($c.passed -ne $want -or $null -eq $c.passed) { $failures.Add("bad: '$($c.text)' expected $want, got '$($c.passed)'. $($c.evidence)") }
    }
} finally {
    Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
}

if ($failures.Count) { $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }; exit 1 }
Write-Host 'icedtasks-properties grader tests passed.'
