# Runs dotnet test with coverage then uses reportgenerator to make
# html report of it. Requires reportgenerator global tool
# dotnet tool install --global dotnet-reportgenerator-globaltool

# $solutionFile is optional and will use first one it 
# finds in working directory if not specified
param ([string] $solutionFile)

if (-Not (Get-Command reportgenerator -ErrorAction SilentlyContinue)) {
    Write-Error "Requires reportgenerator. Install with dotnet tool install --global dotnet-reportgenerator-globaltool"
    Return
}

if (-Not $solutionFile) {
    $solutionFile = Get-ChildItem *.sln | Select-Object -First 1
}

$location = Get-Location

If (Test-Path OpenCover) {
    Remove-Item -Recurse OpenCover
}

dotnet test $solutionFile `
    --configuration Debug `
    /p:CollectCoverage=true `
    /p:CoverletOutputFormat=opencover `
    /maxcpucount:1 `
    "--collect:XPlat Code Coverage" `
    -- DataCollectionRunSettings.DataCollectors.DataCollector.Configuration.Format=opencover -v diag

$reports = Get-ChildItem -recurse -Filter *.opencover.xml | Join-String -Separator ";"

reportgenerator `
    "-reports:$reports" `
    "-targetdir:$location\OpenCover" `
    -reporttypes:html

& $location\OpenCover\index.htm

