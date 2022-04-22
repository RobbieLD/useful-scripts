[CmdletBinding()]
param(
    [Parameter()]
    [string]
    $FileName,
    [Parameter()]
    [string]
    $TemplateName,
    [Parameter()]
    [string]
    $TestType
)

$template = "C:\Code\templates\tests\$TemplateName.cs"
$chunks = $FileName -csplit  "([A-Z]|\d+)"
$test_class_name_parts = New-Object System.Collections.Generic.List[System.Object]

for($i = 3; $i -le $chunks.length - 1; $i += 2) {
    $test_class_name_parts.Add("$($chunks[$i].ToLower())$($chunks[$i + 1])")
}

$test_class_name = ($test_class_name_parts -join "_")

Write-Host "$test_class_name will be used as the test class name"

$destination_file = "C:\Code\Stratos.Youi.Calc.Service\src\Stratos.Youi.Calc.Assemblies.Perils.Test\UserFunctions\$TestType\$FileName\$test_class_name.cs"

$newvars = @{
    '__name__'  = $FileName
    '__class__' = $test_class_name
    '__type__'  = $TestType
}

$data = @()
foreach ($line in Get-Content $template) {
    foreach ($key in $newvars.Keys) {
        if ($line -match $key) {
            $line = $line -replace $key, $newvars[$key]
        }
    }
    $data += $line
}

$data | Out-File (New-Item -Path $destination_file -Force)

Write-Host "Finished writing $destination_file"
