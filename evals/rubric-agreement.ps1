#!/usr/bin/env pwsh
#Requires -Version 7.4
<#
.SYNOPSIS
Judges the rubric items of saved runs several times and reports how often the judge gives the same result for an item.

.EXAMPLE
pwsh ./evals/rubric-agreement.ps1 -ResultDir $env:TEMP/skill-evals/20261011-154304 -Repeat 3
#>
param(
    [Parameter(Mandatory)][string]$ResultDir,
    [ValidateRange(2, 10)][int]$Repeat = 3
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Import-Module (Join-Path $PSScriptRoot 'lib/Grading.psm1') -Force
Import-Module (Join-Path $PSScriptRoot 'lib/Agents.psm1') -Force

$specs = @(Get-ChildItem -Path $PSScriptRoot -Filter 'evals.json' -Recurse -Depth 1 | ForEach-Object {
        [pscustomobject]@{ Dir = $_.DirectoryName; Spec = (Get-Content -Raw $_.FullName | ConvertFrom-Json) }
    })

$rows = [System.Collections.Generic.List[object]]::new()
foreach ($file in Get-ChildItem -Path $ResultDir -Filter 'run.json' -Recurse -Depth 1 | Sort-Object FullName) {
    $run = Get-Content -Raw $file.FullName | ConvertFrom-Json
    $owner = $specs | Where-Object { $_.Spec.skill -eq $run.skill -and $_.Spec.tasks.id -contains $run.task } | Select-Object -First 1
    if (-not $owner) { continue }
    $taskSpec = $owner.Spec.tasks | Where-Object id -eq $run.task
    if (-not $taskSpec.PSObject.Properties['rubric']) { continue }
    $ws = Join-Path $file.DirectoryName 'ws'
    # A run that the summary does not count, or that wrote no document, gives results that do not depend on the judge.
    if (-not (Test-CountedRun $run)) { continue }
    if (-not (Test-Path (Join-Path $ws $taskSpec.rubricDocument) -PathType Leaf)) { continue }
    $grades = @(1..$Repeat | ForEach-Object { , @(Invoke-Rubric -Workspace $ws -EvalDir $owner.Dir -TaskId $run.task) })
    foreach ($item in $taskSpec.rubric) {
        $text = "Rubric $($item.id): $($item.question)"
        # The raw yes or no answer counts, also when a quote check skipped the result. Only a missing answer leaves an item out.
        $values = @($grades | ForEach-Object {
                $hit = @($_ | Where-Object text -eq $text) | Select-Object -First 1
                $answer = if ($hit -and $hit.PSObject.Properties['answer']) { $hit.answer } else { $null }
                if ($answer) { "$answer" } else { 'skipped' }
            })
        $judged = $values -notcontains 'skipped'
        $rows.Add([pscustomobject]@{ run = $run.id; task = $run.task; item = $item.id; results = $values; judged = $judged; agree = $judged -and @($values | Select-Object -Unique).Count -eq 1 })
    }
    Write-Host ("{0}: {1}" -f $run.id, (($rows | Where-Object run -eq $run.id | ForEach-Object { "$($_.item)=$($_.results -join '/')" }) -join ', '))
}

$judged = @($rows | Where-Object judged)
$agreed = @($judged | Where-Object agree).Count
$skipped = $rows.Count - $judged.Count
$summary = [pscustomobject]@{ repeat = $Repeat; items = $rows.Count; judgedItems = $judged.Count; agreed = $agreed; itemsWithSkips = $skipped; rows = $rows }
$summary | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $ResultDir 'rubric-agreement.json') -Encoding utf8
Write-Host ''
Write-Host ("Agreement: {0}/{1} judged items gave the same result in all {2} grades. Items without a judge answer in a grade, not in the rate: {3}." -f $agreed, $judged.Count, $Repeat, $skipped)
