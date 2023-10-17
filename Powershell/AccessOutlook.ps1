$Account = "user@company.com"
$Folder = Inbox"

# Check if DLL exists for microsoft office, is so then add it in
$SearchPath = 'C:\WINDOWS\assembly\GAC_MSIL\Microsoft.Office.Interop.Outlook'
$SearchFilter = 'Microsoft.Office.Interop.Outlook.dll'
$PathToAssembly = Get-ChildItem -LiteralPath $SearchPath -Filter $SearchFilter -Recurse |
Select-Object -ExpandProperty FullName -Last 1

if ($PathToAssembly) {
    Add-Type -LiteralPath $PathToAssembly
}
else {
    throw "Could not find '$SearchFilter'"
}

# Create new outlook object
$Outlook = New-Object -comobject Outlook.Application
$namespace = $Outlook.GetNameSpace("MAPI")

# Read SUMMIT Live Error folder that's already in outlook
$namespace.Folders.Item($Account).Folders.Item($Folder).Items | Where-Object {$_.Subject -match "Something"}
