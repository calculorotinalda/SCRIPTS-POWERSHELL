function win32_
{
Get-CimClass -Namespace "root\cimv2" | Select-Object -Property CimClassName | Format-Wide | more
Get-CimClass -Namespace "root\cimv2" | Select-Object -Property CimClassName | Format-Wide | Out-File c:\win32_.txt
}
win32_