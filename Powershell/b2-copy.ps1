[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $FromBucketName,
    [Parameter()]
    [string]
    $ToBucketName,
    [Parameter()]
    [string]
    $Destination
)

Write-Host "Copying $($FromBucketName) into $($ToBucketName) in $($Destination)"

$files = b2 ls --recursive --json $FromBucketName | ConvertFrom-Json

foreach ($file in $files) {
    if ($file.fileName -Like "*.bzEmpty" ) {
        continue
    }   
    
    Write-Host "Processing file: $($file.fileName)"

    b2 copy-file-by-id $file.fileId $ToBucketName "$($Destination)/$($file.fileName)"
}
