#!/usr/bin/env pwsh
#Requires -Version 7.4
<#
.SYNOPSIS
Runs skill eval tasks with Claude Code, Codex, or opencode, with and without the skill, and grades the results.

.EXAMPLE
pwsh ./evals/run-evals.ps1 -Skill dotnet-mutation-testing -Target claude:sonnet,codex,opencode:github-copilot/gpt-5.5 -Runs 2

.EXAMPLE
pwsh ./evals/run-evals.ps1 -Skill dotnet-review-inputs -Target codex -Mode without -DryRun
#>
param(
    [Parameter(Mandatory)][string]$Skill,
    [string[]]$Target = @('claude'),
    [string[]]$Task = @(),
    [ValidateSet('both', 'with', 'without')][string]$Mode = 'both',
    [ValidateSet('explicit', 'implicit')][string]$Invocation = 'explicit',
    [ValidateRange(1, 20)][int]$Runs = 1,
    [ValidateRange(1, 240)][int]$TimeoutMinutes = 30,
    [string]$OutputRoot = (Join-Path ([IO.Path]::GetTempPath()) 'skill-evals'),
    [ValidatePattern('^[A-Za-z0-9._-]+$')][string]$RunId = (Get-Date -Format 'yyyyMMdd-HHmmss'),
    [switch]$Isolate,
    [switch]$DryRun
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Import-Module (Join-Path $PSScriptRoot 'lib/Agents.psm1') -Force

$repo = Split-Path $PSScriptRoot
$skillDir = Join-Path $repo $Skill
$evalDir = Join-Path $PSScriptRoot $Skill
$evalFile = Join-Path $evalDir 'evals.json'
if (-not (Test-Path (Join-Path $skillDir 'SKILL.md'))) { throw "Skill not found: $skillDir" }
if (-not (Test-Path $evalFile)) { throw "Eval definition not found: $evalFile" }

$spec = Get-Content -Raw $evalFile | ConvertFrom-Json
$Task = @($Task | ForEach-Object { $_ -split ',' } | Where-Object { $_ })
$tasks = @($spec.tasks | Where-Object { $Task.Count -eq 0 -or $_.id -in $Task })
if ($tasks.Count -eq 0) { throw "No task matches: $($Task -join ', '). Known: $($spec.tasks.id -join ', ')" }
$targets = @($Target | ForEach-Object { $_ -split ',' } | Where-Object { $_ } | ForEach-Object { ConvertTo-AgentTarget $_ })
$modes = if ($Mode -eq 'both') { @('with', 'without') } else { @($Mode) }

foreach ($t in $targets) {
    if (-not $DryRun) { $null = Resolve-AgentCommand $t.Agent }
}

$root = Join-Path $OutputRoot $RunId
$cacheRoot = Join-Path $OutputRoot 'cache'
New-Item -ItemType Directory -Force -Path $root, $cacheRoot | Out-Null
$env:SKILL_EVAL_CACHE = $cacheRoot
$skillRevision = (& git -C $repo rev-parse HEAD 2>$null | Select-Object -First 1)
$skillDirty = [bool](& git -C $repo status --porcelain -- $Skill 2>$null)

[object[]]$contamination = @()
if (-not $Isolate) { $contamination = @(Find-ConflictingSkills -Skill $Skill -Keywords @($spec.contaminationKeywords)) }
if ($contamination.Count -gt 0) {
    Write-Warning ("Agents can find these global skills: " + (($contamination | ForEach-Object { "$($_.Name) ($($_.Path))" }) -join ', '))
    Write-Warning 'Codex and opencode runs hide these skills. Claude baselines disable all skills. Claude runs with the skill can still load them.'
}

$dryRuns = [System.Collections.Generic.List[object]]::new()
foreach ($t in $targets) {
    foreach ($taskSpec in $tasks) {
        foreach ($m in $modes) {
            for ($i = 1; $i -le $Runs; $i++) {
                $runName = '{0}-{1}-{2}-r{3:d2}' -f (ConvertTo-PathSegment $t.Label), $taskSpec.id, $m, $i
                $runDir = Join-Path $root $runName
                if (Test-Path (Join-Path $runDir 'run.json')) { Write-Host "[$runName] already has run.json. Skipped."; continue }
                Remove-Item -Recurse -Force $runDir -ErrorAction SilentlyContinue
                New-Item -ItemType Directory -Force -Path $runDir | Out-Null
                $ws = Join-Path $runDir 'ws'
                $repository = if ($taskSpec.PSObject.Properties['repository']) { $taskSpec.repository } else { $null }
                if (-not $DryRun) {
                    $patch = if ($taskSpec.PSObject.Properties['workingTreePatch']) { Join-Path $evalDir $taskSpec.workingTreePatch } else { $null }
                    Initialize-Workspace -Workspace $ws -Repository $repository -CacheRoot $cacheRoot -WorkingTreePatch $patch
                    $added = @('TASK.md')
                    foreach ($f in @($taskSpec.files)) { Copy-Item (Join-Path $evalDir $f) $ws -Recurse; $added += (Split-Path $f -Leaf) }
                    Set-Content -Path (Join-Path $ws 'TASK.md') -Value $taskSpec.prompt -Encoding utf8
                    if ($m -eq 'with') { Install-Skill -SkillDir $skillDir -Workspace $ws; $added += "$('.claude/skills')/$(Get-InstallName $Skill)", ".agents/skills/$(Get-InstallName $Skill)" }
                    Add-WorkspaceExclusions -Workspace $ws -Paths $added
                }

                Write-Host "[$runName] $($t.Label) | $($taskSpec.id) | $m skill | run $i"
                $info = [ordered]@{
                    id = $runName; skill = $Skill; skillRevision = $skillRevision; skillDirty = $skillDirty
                    target = $t.Label; agent = $t.Agent; model = $t.Model; task = $taskSpec.id
                    mode = $m; run = $i; invocation = $Invocation; workspace = $ws; isolated = [bool]$Isolate
                    repository = $repository
                }

                $message = Get-AgentMessage -Skill $Skill -WithSkill:($m -eq 'with') -Invocation $Invocation
                $agentRun = Invoke-Agent -Target $t -Workspace $ws -RunDir $runDir -Message $message -WithSkill:($m -eq 'with') -HiddenSkills $contamination `
                    -Isolate:$Isolate -TimeoutMinutes $TimeoutMinutes -DryRun:$DryRun
                $info.command = $agentRun.Command
                if ($DryRun) { Remove-Item -Recurse -Force $runDir; $dryRuns.Add([pscustomobject]$info); continue }

                $metrics = Get-AgentMetrics -Agent $t.Agent -TranscriptPath $agentRun.Stdout -Skill $Skill
                $info.dotnetSdk = Get-DotnetSdk $ws
                $info.exitCode = $agentRun.ExitCode
                $info.timedOut = $agentRun.TimedOut
                $info.seconds = [math]::Round($agentRun.Seconds, 1)
                $info.inputTokens = $metrics.InputTokens
                $info.outputTokens = $metrics.OutputTokens
                $info.costUsd = $metrics.CostUsd
                $info.turns = $metrics.Turns
                $info.failedBuilds = $metrics.FailedBuilds
                $info.failedTestRuns = $metrics.FailedTestRuns
                $info.skillUsed = $metrics.SkillUsed
                $info.globalSkillUsed = $metrics.GlobalSkillUsed
                $info.agentError = Get-RunError $metrics $agentRun.ExitCode $agentRun.TimedOut
                $info.environment = $agentRun.Environment

                $gradeDir = Join-Path $runDir 'grade'
                New-Item -ItemType Directory -Force -Path $gradeDir | Out-Null
                $grader = Join-Path $evalDir $taskSpec.grader
                try {
                    & $grader -Workspace $ws -OutDir $gradeDir | Out-Null
                    $checks = @(Get-Content -Raw (Join-Path $gradeDir 'grading.json') | ConvertFrom-Json)
                } catch {
                    # A grader failure is not a result of the agent, so the check is skipped and the run has no pass rate.
                    $checks = @([pscustomobject]@{ text = 'Grader completed'; passed = $null; evidence = "skipped: the grader failed: $_" })
                }
                $info.checks = $checks
                $info.passed = @($checks | Where-Object { $_.passed -eq $true }).Count
                $info.failed = @($checks | Where-Object { $_.passed -eq $false }).Count
                $info.skipped = @($checks | Where-Object { $null -eq $_.passed }).Count
                $info | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $runDir 'run.json') -Encoding utf8
                if ($m -eq 'with' -and -not $info.skillUsed) { Write-Warning "    The agent did not load $(Get-InstallName $Skill) in this run." }
                if ($info.agentError) { Write-Warning "    The agent failed: $($info.agentError). The summary does not count this run." }
                if ($info.globalSkillUsed) { Write-Warning "    The agent loaded a global copy of $Skill in this run. The summary does not count it." }
                Write-Host ("    {0}/{1} checks passed, {2} skipped, {3}s, {4} turns, {5} failed builds, {6} failed test runs, skill used: {7}" -f $info.passed,
                    ($info.passed + $info.failed), $info.skipped, $info.seconds, $info.turns, $info.failedBuilds, $info.failedTestRuns, $info.skillUsed)
            }
        }
    }
}

if ($DryRun) {
    $dryRuns | ForEach-Object { "[$($_.id)]`n    $($_.command)" }
    Remove-Item $root -Force -ErrorAction SilentlyContinue
    return
}

# Other processes can write runs to the same RunId, so the summary reads every run.json under the root.
$results = @(Read-RunResults -Root $root)
$summary = Write-Summary -Results $results -Root $root -Contamination $contamination
$results | ConvertTo-Json -Depth 6 | Set-Content (Join-Path $root 'results.json') -Encoding utf8
Write-Host ''
Write-Host $summary
Write-Host ''
Write-Host "Results: $root"
