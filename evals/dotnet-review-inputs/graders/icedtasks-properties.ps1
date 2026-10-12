param(
    [Parameter(Mandatory)][string]$Workspace,
    [Parameter(Mandatory)][string]$OutDir
)
$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $false
Import-Module (Join-Path $PSScriptRoot '../../lib/Grading.psm1') -Force

$evalDir = Split-Path $PSScriptRoot
$task = Get-TaskSpec -EvalDir $evalDir -TaskId 'icedtasks-properties'
$commit = $task.repository.commit
$reviewPath = Join-Path $Workspace 'review.md'

$checks = @()
$review = if (Test-Path $reviewPath -PathType Leaf) { Get-Content -Raw -Encoding utf8 $reviewPath } else { $null }
$hasReview = -not [string]::IsNullOrWhiteSpace($review)
$checks += New-Check 'review.md exists and is not empty' $hasReview ''

$state = Get-ChangedTrackedFiles -Workspace $Workspace
$clean = $state.Head -eq $commit -and $state.Files.Count -eq 0
$checks += New-Check 'The review changed no repository file: HEAD is the task commit and no tracked file changed' $clean "HEAD: $($state.Head); changed: $($state.Files -join ', ')"

# A citation is a .fs path or file name followed by :line or #Lline.
$citations = @()
if ($hasReview) {
    $citations = @([regex]::Matches($review, '(?<path>[A-Za-z0-9_./\\-]+\.fsx?)(?::|#L)(?<line>\d+)') | ForEach-Object {
            [pscustomobject]@{ Path = $_.Groups['path'].Value; Line = [int]$_.Groups['line'].Value }
        })
}
$checks += New-Check 'The review cites at least one source location as file:line' ($citations.Count -gt 0) "$($citations.Count) citations"

if ($citations.Count -eq 0) {
    $checks += New-Check 'Each file:line citation points to an existing line' $null 'skipped: the review has no file:line citation'
} else {
    $bad = @()
    foreach ($c in $citations) {
        $relative = $c.Path.Replace('\', '/').TrimStart('.', '/')
        $files = @(Get-ChildItem -Path $Workspace -Recurse -File -Filter (Split-Path $relative -Leaf) -ErrorAction SilentlyContinue |
                Where-Object { $_.FullName.Replace('\', '/').EndsWith($relative) -and $_.FullName -notmatch '[\\/](bin|obj|\.git)[\\/]' })
        $found = @($files | Where-Object { @(Get-Content $_.FullName).Count -ge $c.Line -and $c.Line -gt 0 }).Count -gt 0
        if (-not $found) { $bad += "$($c.Path):$($c.Line)" }
    }
    $checks += New-Check 'Each file:line citation points to an existing line' ($bad.Count -eq 0) $(if ($bad.Count) { 'not found: ' + (($bad | Select-Object -Unique) -join ', ') } else { '' })
}

if ($hasReview) {
    $checks += Invoke-Rubric -Workspace $Workspace -EvalDir $evalDir -TaskId 'icedtasks-properties'
} else {
    $checks += @($task.rubric | ForEach-Object { New-Check "Rubric $($_.id): $($_.question)" $false 'review.md does not exist' })
}

Write-Checks (Join-Path $OutDir 'grading.json') $checks
