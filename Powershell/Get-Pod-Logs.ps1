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
    $Contexts
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

foreach ($context in $Contexts) {
    kubectl config use-context $context
    Get-PodNames -namespace prod -name $PodPrefix | ForEach-Object { Get-PodLog -namespace prod -name $_ }
}
