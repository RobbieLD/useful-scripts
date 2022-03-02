Param(
    [string]$Name
)

dotnet new sln -n $Name

$projects `
    = Get-ChildItem `
        -Recurse `
        -Filter *.csproj `
    | Resolve-Path `
        -Relative
    
foreach ($project in $projects) {
    $folder = Split-Path -Path $project | Split-Path

    if ($folder.Length -le 2) {
        dotnet sln "$Name.sln" add $project
    }
    else {
        dotnet sln "$Name.sln" add -s $folder.Substring(2) $project
    }
}
