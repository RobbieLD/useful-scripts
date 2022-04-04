# Uploads an activity to strava with a given name and api key

param(
    [string] $apiKey,
    [string] $device
)

Write-Host " Searching for $device"

$drive = (Get-Volume -FileSystemLabel $device).DriveLetter

if (-Not $drive)
{
    Write-Error "No device found"
    return
}

Write-Host "Device found with driver letter: $drive"

$source = "$drive`:\GARMIN\ACTIVITY"

Write-Host "Uploading from $source"


$files = Get-ChildItem $source -Filter *.FIT | Resolve-Path -Relative

foreach ($file in $files) {
     Write-Host "Uplading $file"
}