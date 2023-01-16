[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $LogPath,
    [Parameter()]
    [string]
    $PodPrefix,
    [Parameter()]
    [string[]]
    $Contexts,
    [Parameter()]
    [string]
    $Namespace
)

Function Get-PodNames {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $name,
        [Parameter()]
        [string]
        $namespace
    )

    $pods = kubectl get pods -n $namespace --output jsonpath='{range .items[*]}{.metadata.name}{"\n"}{end}'

    foreach ($pod in $pods.Split([Environment]::NewLine)) {
        if ($pod -like "$name*") {
            Write-Output $pod
        }
    }
}

Function Get-PodLog {
    [CmdletBinding()]
    param (
        [Parameter()]
        [string]
        $name,
        [Parameter()]
        [string]
        $namespace
    )

    Write-Host "Getting logs for $name"
    kubectl logs $name -n $namespace > "$LogPath\$name.log"
}

Write-Host "Removing existing logs"
Remove-Item "$LogPath\*.log"

foreach ($context in $Contexts) {
    kubectl config use-context $context
    Get-PodNames -namespace $Namespace -name $PodPrefix | ForEach-Object { Get-PodLog -namespace $Namespace -name $_ }
}

Write-Host "Merging Logs"
Get-Content "$LogPath\*.log" | Sort-Object | Set-Content "$LogPath\merge.log"
