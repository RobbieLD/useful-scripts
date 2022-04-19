
$messages = git log master..develop --grep='dataprep' --pretty=format:"%b" | ConvertFrom-Json

Write-Host "# Data Prep"
Write-Host
Write-Host  "| Class | Field | Data Type |"
Write-Host  "| ----- | ----- | ----------|"

foreach ($message in $messages) {
    Write-Host "|$($message.dataprep.class) | $($message.dataprep.field) | $($message.dataprep.type) |"
}
