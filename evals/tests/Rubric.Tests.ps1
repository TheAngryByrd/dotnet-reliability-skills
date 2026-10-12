#!/usr/bin/env pwsh
#Requires -Version 7.4
param()
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../lib/Grading.psm1') -Force
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-Equal($Expected, $Actual, [string]$Name) {
    if ($Expected -ne $Actual) { $failures.Add("${Name}: expected '$Expected', got '$Actual'") }
}

$root = Join-Path ([IO.Path]::GetTempPath()) "rubric-tests-$PID"
$evalDir = Join-Path $root 'eval'
$ws = Join-Path $root 'ws'
New-Item -ItemType Directory -Force -Path $evalDir, $ws | Out-Null
$judge = Join-Path $root 'judge.ps1'
$promptCopy = Join-Path $root 'prompt.txt'
Set-Content -Path $judge -Encoding utf8 -Value @'
$prompt = [Console]::In.ReadToEnd()
Set-Content -Path $env:FAKE_JUDGE_PROMPT -Value $prompt -Encoding utf8NoBOM
Set-Content -Path "$env:FAKE_JUDGE_PROMPT.env" -Value "CLAUDECODE=$env:CLAUDECODE" -Encoding utf8NoBOM
[Console]::Out.Write($env:FAKE_JUDGE_OUTPUT)
exit [int]$env:FAKE_JUDGE_EXIT
'@
@{
    skill = 'demo'
    tasks = @(@{
            id = 'review'; rubricDocument = 'review.md'
            rubric = @(@{ id = 'a'; question = 'Does the review name the unit property?' }, @{ id = 'b'; question = 'Does the review cite maxTest?' })
        })
} | ConvertTo-Json -Depth 5 | Set-Content (Join-Path $evalDir 'evals.json') -Encoding utf8
Set-Content -Path (Join-Path $ws 'review.md') -Encoding utf8 -Value @"
# Review

The ``parallelism``   property takes unit, so each case repeats one scenario.
The demo-eval skill guided this review.
Under CI, fsCheckConfig sets maxTest = 10.
"@

$previousJudge = $env:SKILL_EVAL_JUDGE
$env:SKILL_EVAL_JUDGE = ConvertTo-Json -Compress -InputObject @('pwsh', '-NoProfile', '-File', $judge)
$env:FAKE_JUDGE_PROMPT = $promptCopy

function Invoke-Case([string]$Output, [int]$Exit = 0, [string]$Workspace = $ws) {
    $env:FAKE_JUDGE_OUTPUT = $Output
    $env:FAKE_JUDGE_EXIT = "$Exit"
    @(Invoke-Rubric -Workspace $Workspace -EvalDir $evalDir -TaskId 'review')
}
function Get-Answer([string]$A, [string]$AQuote, [string]$B, [string]$BQuote) {
    @{ items = @(@{ id = 'a'; answer = $A; quote = $AQuote }, @{ id = 'b'; answer = $B; quote = $BQuote }) } | ConvertTo-Json -Depth 5 -Compress
}

try {
    $c = Invoke-Case (Get-Answer 'yes' 'property takes unit, so each case' 'no' '')
    Assert-Equal 2 $c.Count 'one check per item'
    Assert-Equal 'Rubric a: Does the review name the unit property?' $c[0].text 'check text'
    Assert-Equal $true $c[0].passed 'yes with a quote from one line passes'
    Assert-Equal $false $c[1].passed 'no without a quote fails'
    Assert-Equal 'no' $c[1].answer 'a failed check keeps the raw judge answer'
    $prompt = Get-Content -Raw $promptCopy
    Assert-Equal $false ($prompt -match 'demo-eval') 'install name is replaced in the document'
    Assert-Equal $true ($prompt -match 'The demo skill guided') 'skill name stays in the document'

    $previousSession = $env:CLAUDECODE
    $env:CLAUDECODE = '1'
    try { $null = Invoke-Case (Get-Answer 'yes' 'property takes unit' 'no' '') } finally { $env:CLAUDECODE = $previousSession }
    Assert-Equal 'CLAUDECODE=' (Get-Content -Raw "$promptCopy.env").Trim() 'the judge does not inherit parent session variables'

    $c = Invoke-Case (Get-Answer 'yes' '`parallelism` property takes unit' 'yes' 'fsCheckConfig sets maxTest = 10')
    Assert-Equal $true $c[0].passed 'whitespace in the document line is collapsed'
    Assert-Equal $true $c[1].passed 'second item passes'

    $c = Invoke-Case (Get-Answer 'yes' 'property takes a generated list' 'yes' "Under CI,`nfsCheckConfig")
    Assert-Equal $null $c[0].passed 'a quote not in the document is skipped'
    Assert-Equal 'yes' $c[0].answer 'a skipped check keeps the raw judge answer'
    Assert-Equal $null $c[1].passed 'a quote on two lines is skipped'

    $c = Invoke-Case (Get-Answer 'yes' 'CI' 'maybe' 'maxTest')
    Assert-Equal $null $c[0].passed 'a quote shorter than 4 characters is skipped'
    Assert-Equal $null $c[1].passed 'an answer other than yes or no is skipped'

    $c = Invoke-Case (@{ items = @(@{ id = 'a'; answer = 'yes'; quote = 'property takes unit' }) } | ConvertTo-Json -Depth 5 -Compress)
    Assert-Equal $true $c[0].passed 'answered item passes'
    Assert-Equal $null $c[1].passed 'an item with no answer is skipped'

    $wrapped = @{ type = 'result'; structured_output = @{ items = @(@{ id = 'a'; answer = 'yes'; quote = 'property takes unit' }, @{ id = 'b'; answer = 'no'; quote = '' }) } } | ConvertTo-Json -Depth 6 -Compress
    $c = Invoke-Case $wrapped
    Assert-Equal $true $c[0].passed 'Claude structured_output is read'
    $inner = @{ type = 'result'; result = ('Here is the answer: ' + (Get-Answer 'yes' 'property takes unit' 'no' '')) } | ConvertTo-Json -Depth 6 -Compress
    $c = Invoke-Case $inner
    Assert-Equal $true $c[0].passed 'JSON inside the Claude result text is read'

    $c = Invoke-Case (Get-Answer 'yes' 'property takes unit' 'yes' 'maxTest = 10') 3
    Assert-Equal 2 @($c | Where-Object { $null -eq $_.passed }).Count 'a failed judge skips all items'
    $c = Invoke-Case 'not json'
    Assert-Equal 2 @($c | Where-Object { $null -eq $_.passed }).Count 'judge output without items skips all items'

    $empty = Join-Path $root 'empty-ws'
    New-Item -ItemType Directory -Force -Path $empty | Out-Null
    $c = Invoke-Case (Get-Answer 'yes' 'property takes unit' 'yes' 'maxTest = 10') 0 $empty
    Assert-Equal 2 @($c | Where-Object { $_.passed -eq $false }).Count 'a missing document fails all items'

    $env:SKILL_EVAL_JUDGE = 'off'
    $c = Invoke-Case (Get-Answer 'yes' 'property takes unit' 'yes' 'maxTest = 10')
    Assert-Equal 2 @($c | Where-Object { $null -eq $_.passed }).Count 'judge off skips all items'
    $env:SKILL_EVAL_JUDGE = '["claude", 3]'
    $c = Invoke-Case ''
    Assert-Equal 2 @($c | Where-Object { $null -eq $_.passed }).Count 'an invalid judge setting skips all items'
} finally {
    $env:SKILL_EVAL_JUDGE = $previousJudge
    Remove-Item Env:FAKE_JUDGE_OUTPUT, Env:FAKE_JUDGE_EXIT, Env:FAKE_JUDGE_PROMPT -ErrorAction SilentlyContinue
    Remove-Item -Recurse -Force $root -ErrorAction SilentlyContinue
}

if ($failures.Count) { $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }; exit 1 }
Write-Host 'Rubric tests passed.'
