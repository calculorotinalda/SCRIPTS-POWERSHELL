function removephone{
Get-AppxPackage Microsoft.YourPhone -AllUsers | Remove-AppxPackage
}