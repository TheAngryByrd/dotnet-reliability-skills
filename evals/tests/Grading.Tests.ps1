#!/usr/bin/env pwsh
#Requires -Version 7.4
param()
$ErrorActionPreference = 'Stop'
Import-Module (Join-Path $PSScriptRoot '../lib/Grading.psm1') -Force
$failures = [System.Collections.Generic.List[string]]::new()

function Assert-Equal($Expected, $Actual, [string]$Name) {
    if ($Expected -ne $Actual) { $failures.Add("${Name}: expected '$Expected', got '$Actual'") }
}

function New-Trx([int]$Total, [string[]]$Failed = @()) {
    [pscustomobject]@{ Total = $Total; Passed = $Total - $Failed.Count; Failed = $Failed }
}

$cases = @(
    @{ Name = 'all tests pass'; Text = 'Passed!  - Failed: 0, Passed: 33'; Exit = 0; Trx = (New-Trx 33); Verdict = 'survived' }
    @{ Name = 'a test fails'; Text = 'Failed!  - Failed: 1, Passed: 32'; Exit = 1; Trx = (New-Trx 33 @('A.b')); Verdict = 'detected' }
    @{ Name = 'F# compiler error'; Text = 'C:\r\src\Result.fs(405,33): error FS0064: less generic [C:\r\src\A.fsproj]'; Exit = 1; Trx = $null; Verdict = 'invalid' }
    @{ Name = 'C# compiler error'; Text = 'src/A.cs(3,1): error CS1002: ; expected'; Exit = 1; Trx = $null; Verdict = 'invalid' }
    @{ Name = 'restore failure'; Text = 'C:\r\tests\A.fsproj : error NU1301: Unable to load the service index'; Exit = 1; Trx = $null; Verdict = 'inconclusive' }
    @{ Name = 'locked file'; Text = 'error MSB3027: Could not copy "obj\A.dll" to "bin\A.dll".'; Exit = 1; Trx = $null; Verdict = 'inconclusive' }
    @{ Name = 'aborted run without a failed test'; Text = 'Test Run Aborted.'; Exit = 1; Trx = (New-Trx 3); Verdict = 'inconclusive' }
    @{ Name = 'no tests ran'; Text = 'No test matches the given testcase filter'; Exit = 0; Trx = (New-Trx 0); Verdict = 'inconclusive' }
    @{ Name = 'compiler error text in test output'; Text = 'Expected error FS0064 in output'; Exit = 0; Trx = (New-Trx 2); Verdict = 'survived' }
)
foreach ($c in $cases) {
    $outcome = Get-TestRunOutcome -Text $c.Text -ExitCode $c.Exit -Trx $c.Trx
    Assert-Equal $c.Verdict $outcome.Verdict $c.Name
}

if ($failures.Count) { $failures | ForEach-Object { Write-Error $_ -ErrorAction Continue }; exit 1 }
Write-Host 'Grading tests passed.'
