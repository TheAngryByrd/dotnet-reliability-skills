#!/usr/bin/env pwsh
#Requires -Version 7.4
<#
.SYNOPSIS
Grades the runs in an existing eval result folder again with the current graders and rebuilds the summary. The agents do not run again.

.EXAMPLE
pwsh ./evals/grade-evals.ps1 -ResultDir $env:TEMP/skill-evals/20261011-154304
#>
param(
    [Parameter(Mandatory)][string]$ResultDir,
    [string[]]$Task = @()
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
$Task = @($Task | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
Import-Module (Join-Path $PSScriptRoot 'lib/Agents.psm1') -Force
if (-not $env:SKILL_EVAL_CACHE) { $env:SKILL_EVAL_CACHE = Join-Path (Split-Path (Resolve-Path $ResultDir).Path) 'cache' }

$specs = @(Get-ChildItem -Path $PSScriptRoot -Filter 'evals.json' -Recurse -Depth 1 | ForEach-Object {
        [pscustomobject]@{ Dir = $_.DirectoryName; Spec = (Get-Content -Raw $_.FullName | ConvertFrom-Json) }
    })

foreach ($file in Get-ChildItem -Path $ResultDir -Filter 'run.json' -Recurse -Depth 1 | Sort-Object FullName) {
    $run = Get-Content -Raw $file.FullName | ConvertFrom-Json
    $owner = $specs | Where-Object { $_.Spec.skill -eq $run.skill -and $_.Spec.tasks.id -contains $run.task } | Select-Object -First 1
    if (-not $owner) { throw "No evals.json defines task $($run.task) for skill $($run.skill)." }
    $transcript = Join-Path $file.DirectoryName 'transcript.jsonl'
    if (Test-Path $transcript) {
        $metrics = Get-AgentMetrics -Agent $run.agent -TranscriptPath $transcript -Skill $run.skill
        foreach ($name in 'turns', 'failedBuilds', 'failedTestRuns', 'skillUsed', 'globalSkillUsed') {
            $value = $metrics.($name.Substring(0, 1).ToUpperInvariant() + $name.Substring(1))
            $run | Add-Member -NotePropertyName $name -NotePropertyValue $value -Force
        }
        $run | Add-Member -NotePropertyName agentError -NotePropertyValue (Get-RunError $metrics $run.exitCode ([bool]$run.timedOut)) -Force
    }
    if ($Task.Count -eq 0 -or $run.task -in $Task) {
        $taskSpec = $owner.Spec.tasks | Where-Object id -eq $run.task
        $gradeDir = Join-Path $file.DirectoryName 'grade'
        Remove-Item -Recurse -Force $gradeDir -ErrorAction SilentlyContinue
        New-Item -ItemType Directory -Force -Path $gradeDir | Out-Null
        $ws = Join-Path $file.DirectoryName 'ws'
        try {
            & (Join-Path $owner.Dir $taskSpec.grader) -Workspace $ws -OutDir $gradeDir | Out-Null
            $checks = @(Get-Content -Raw (Join-Path $gradeDir 'grading.json') | ConvertFrom-Json)
        } catch {
            # A grader failure is not a result of the agent, so the check is skipped and the run has no pass rate.
            $checks = @([pscustomobject]@{ text = 'Grader completed'; passed = $null; evidence = "skipped: the grader failed: $_" })
        }
        $run.checks = $checks
        $run.passed = @($checks | Where-Object { $_.passed -eq $true }).Count
        $run.failed = @($checks | Where-Object { $_.passed -eq $false }).Count
        $run.skipped = @($checks | Where-Object { $null -eq $_.passed }).Count
        Write-Host ("{0} | {1} | {2} | r{3}: {4}/{5} checks passed, {6} skipped" -f $run.target, $run.task, $run.mode, $run.run, $run.passed, ($run.passed + $run.failed), $run.skipped)
    }
    $run | ConvertTo-Json -Depth 6 | Set-Content $file.FullName -Encoding utf8
}

$results = @(Read-RunResults -Root $ResultDir)
$results | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $ResultDir 'results.json') -Encoding utf8
$summary = Write-Summary -Results $results -Root $ResultDir
Write-Host ''
Write-Host $summary
