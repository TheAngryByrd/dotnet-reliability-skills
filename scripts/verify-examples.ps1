$ErrorActionPreference = 'Stop'
$exampleRoot = Join-Path $PSScriptRoot '../dotnet-feature-workload/assets/examples'
$projects = @('CSharp/CSharp.csproj', 'FSharp/FSharp.fsproj')

foreach ($project in $projects) {
    $projectPath = Join-Path $exampleRoot $project
    & dotnet build $projectPath --configuration Release --nologo
    if ($LASTEXITCODE -ne 0) { throw "Build failed: $project" }

    $baseline = & dotnet run --project $projectPath --configuration Release --no-build 2>&1
    $baselineExit = $LASTEXITCODE
    $baseline | Write-Output
    if ($baselineExit -ne 0) { throw "Baseline failed: $project (exit $baselineExit)" }

    $mutant = & dotnet run --project $projectPath --configuration Release --no-build -- --mutant 2>&1
    $mutantExit = $LASTEXITCODE
    $mutant | Write-Output
    $mutantLines = @($mutant | ForEach-Object { $_.ToString() })
    if ($mutantExit -ne 1 -or $mutantLines -notcontains 'PROPERTY_VIOLATION: exact capacity was rejected') {
        throw "Expected boundary violation was not observed: $project (exit $mutantExit)"
    }
}
