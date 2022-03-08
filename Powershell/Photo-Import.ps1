# Copies photos from an external memory card to a internal drive
# This argument is the import directory. If not provided the current date is used
param ([string] $tag)

$targetDir = 'E:\Photos\2022'
$sourceDir = 'F:\DCIM\100MSDCF\*'

$importDir = ((Get-Date).ToString('yyyy-MM-dd'))

if ($tag) {
    $importDir = "$importDir-$tag"
}

New-Item -ItemType Directory -Path "$targetDir\$importDir"

Copy-Item -Path $sourceDir -Destination "$targetDir\$importDir" -PassThru
