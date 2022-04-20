
$messages = "{`"root`":[$(git log master..develop --grep='dataprep' --pretty=format:"%b,")]}" | ConvertFrom-Json

Write-Output -InputObject "# Data Prep"
Write-Output -InputObject ""
Write-Output -InputObject "| Class | Field | Data Type |"
Write-Output -InputObject  "| ----- | ----- | ----------|"

foreach ($message in $messages.root) {
    Write-Output -InputObject "|$($message.dataprep.class) | $($message.dataprep.field) | $($message.dataprep.type) |"
}
