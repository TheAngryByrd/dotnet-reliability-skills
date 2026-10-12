#!/usr/bin/env pwsh
#Requires -Version 7.4
param()
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../lib/Agents.psm1') -Force
$fixtures = Join-Path $PSScriptRoot 'fixtures'
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-Equal($Expected, $Actual, [string]$Name) {
    if ($Expected -ne $Actual) { $failures.Add("${Name}: expected '$Expected', got '$Actual'") }
}

$cases = @(
    @{ Agent = 'claude'; Turns = 6; FailedBuilds = 3; FailedTestRuns = 1; SkillUsed = $true; GlobalSkillUsed = $false; Tokens = 15 }
    @{ Agent = 'codex'; Turns = 14; FailedBuilds = 4; FailedTestRuns = 1; SkillUsed = $false; GlobalSkillUsed = $true; Tokens = 110 }
    @{ Agent = 'opencode'; Turns = 3; FailedBuilds = 2; FailedTestRuns = 1; SkillUsed = $false; GlobalSkillUsed = $false; Tokens = 33 }
    @{ Agent = 'claude'; File = 'claude-no-result'; Turns = 7; FailedBuilds = 3; FailedTestRuns = 0; SkillUsed = $false; GlobalSkillUsed = $false; Tokens = $null }
    @{ Agent = 'claude'; File = 'empty'; Turns = $null; FailedBuilds = $null; FailedTestRuns = $null; SkillUsed = $false; GlobalSkillUsed = $false; Tokens = $null }
    @{ Agent = 'codex'; File = 'empty'; Turns = $null; FailedBuilds = $null; FailedTestRuns = $null; SkillUsed = $false; GlobalSkillUsed = $false; Tokens = $null }
    @{ Agent = 'opencode'; File = 'empty'; Turns = $null; FailedBuilds = $null; FailedTestRuns = $null; SkillUsed = $false; GlobalSkillUsed = $false; Tokens = $null }
    @{ Agent = 'opencode'; File = 'opencode-error'; Turns = 0; FailedBuilds = 0; FailedTestRuns = 0; SkillUsed = $false; GlobalSkillUsed = $false; Tokens = $null }
)
foreach ($case in $cases) {
    $file = if ($case.File) { $case.File } else { $case.Agent }
    $m = Get-AgentMetrics -Agent $case.Agent -TranscriptPath (Join-Path $fixtures "$file.jsonl") -Skill 'demo'
    $name = "$($case.Agent) $file"
    Assert-Equal $case.Turns $m.Turns "$name turns"
    Assert-Equal $case.FailedBuilds $m.FailedBuilds "$name failed builds"
    Assert-Equal $case.FailedTestRuns $m.FailedTestRuns "$name failed test runs"
    Assert-Equal $case.SkillUsed $m.SkillUsed "$name skill used"
    Assert-Equal $case.GlobalSkillUsed $m.GlobalSkillUsed "$name global skill used"
    $tokens = if ($null -ne $m.InputTokens) { $m.InputTokens + $m.OutputTokens } else { $null }
    Assert-Equal $case.Tokens $tokens "$name tokens"
    $expectedError = $case.File -in 'empty', 'opencode-error'
    Assert-Equal $expectedError ([bool]$m.AgentError) "$name agent error"
}
Assert-Equal $null (Get-AgentMetrics -Agent 'codex' -TranscriptPath (Join-Path $fixtures 'codex-retry.jsonl') -Skill 'demo').AgentError 'codex retried stream error is not an agent error'
Assert-Equal 'stream disconnected before completion' (Get-AgentMetrics -Agent 'codex' -TranscriptPath (Join-Path $fixtures 'codex-failed.jsonl') -Skill 'demo').AgentError 'codex turn.failed is an agent error'
$clean = [pscustomobject]@{ AgentError = $null }
Assert-Equal 'The agent process exited with code 137.' (Get-RunError $clean 137 $false) 'non-zero exit is an agent error'
Assert-Equal $null (Get-RunError $clean 137 $true) 'a timed-out run is not an agent error'
Assert-Equal $null (Get-RunError $clean 0 $false) 'exit code 0 is not an agent error'
Assert-Equal 'You have exceeded your monthly quota' (Get-AgentMetrics -Agent 'opencode' -TranscriptPath (Join-Path $fixtures 'opencode-error.jsonl') -Skill 'demo').AgentError 'opencode error message'

$missing = Get-AgentMetrics -Agent 'claude' -TranscriptPath (Join-Path $fixtures 'none.jsonl') -Skill 'demo'
Assert-Equal $null $missing.Turns 'missing transcript turns'
Assert-Equal $null $missing.FailedBuilds 'missing transcript failed builds'

$commands = @(
    @{ Command = 'dotnet test -f net9.0'; Failed = $true; Output = 'Failed!  - Failed: 1'; Expected = 'test' }
    @{ Command = 'dotnet test -f net9.0'; Failed = $true; Output = 'Result.fs(405,33): error FS0064: less generic'; Expected = 'build' }
    @{ Command = 'dotnet build'; Failed = $false; Output = 'Program.cs(1,1): error CS1002: ; expected'; Expected = 'build' }
    @{ Command = 'dotnet test'; Failed = $false; Output = 'Passed!'; Expected = $null }
    @{ Command = "rg 'dotnet test' ."; Failed = $true; Output = ''; Expected = $null }
    @{ Command = 'dotnet build-server shutdown'; Failed = $true; Output = ''; Expected = $null }
    @{ Command = 'git apply mutants/M1.patch && dotnet test'; Failed = $true; Output = 'Failed!'; Expected = 'test' }
)
foreach ($c in $commands) { Assert-Equal $c.Expected (Get-CommandFailure $c.Command $c.Failed $c.Output) "command '$($c.Command)' with '$($c.Output)'" }

function New-Run([string]$Mode, $Turns, $FailedBuilds, [bool]$SkillUsed = $true, [bool]$GlobalSkillUsed = $false, [string]$AgentError = $null) {
    [pscustomobject][ordered]@{ target = 'claude'; task = 'fix'; mode = $Mode; skill = 'demo'; skillUsed = $SkillUsed; globalSkillUsed = $GlobalSkillUsed; agentError = $AgentError
        passed = 1; failed = 0; skipped = 0; seconds = 10; inputTokens = 1; outputTokens = 1; costUsd = 0.25; turns = $Turns; failedBuilds = $FailedBuilds
        failedTestRuns = 0; checks = @() }
}
$root = Join-Path ([IO.Path]::GetTempPath()) "metrics-tests-$PID"
New-Item -ItemType Directory -Force -Path $root | Out-Null
try {
    $summary = Write-Summary -Root $root -Results @(
        New-Run 'without' 12 5; New-Run 'with' 4 0; New-Run 'with' 7 3; New-Run 'without' $null $null
        New-Run 'with' 99 99 $false; New-Run 'without' 99 99 $false $true; New-Run 'without' 99 99 $true $false 'quota exceeded')
    $rows = @($summary -split "`n" | Where-Object { $_ -match '^\| claude \| fix \|' })
    Assert-Equal '| claude | fix | with | 2 | 100% | 0 | 10 | 2 | 0.25 | 5.5 | 1.5 | 0.0 | 1 | 0 | 0 |' $rows[0] 'summary with-skill row'
    Assert-Equal '| claude | fix | without | 2 | 100% | 0 | 10 | 2 | 0.25 | 12.0 | 5.0 | 0.0 | 0 | 1 | 1 |' $rows[1] 'summary without-skill row'
    $previousCulture = [Globalization.CultureInfo]::CurrentCulture
    try {
        [Globalization.CultureInfo]::CurrentCulture = [Globalization.CultureInfo]::new('de-DE')
        $german = @((Write-Summary -Root $root -Results @(New-Run 'with' 4 0)) -split "`n" | Where-Object { $_ -match '^\| claude \| fix \|' })
        Assert-Equal '| claude | fix | with | 1 | 100% | 0 | 10 | 2 | 0.25 | 4.0 | 0.0 | 0.0 | 0 | 0 | 0 |' $german[0] 'summary row does not depend on the culture'
    } finally { [Globalization.CultureInfo]::CurrentCulture = $previousCulture }
} finally { Remove-Item -Recurse -Force $root }

if ($failures.Count) { $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }; exit 1 }
Write-Host 'Metrics tests passed.'
