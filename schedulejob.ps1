
#$service = Get-Service | findstr "Running"
$date = Get-Date
$action = New-ScheduledTaskAction -Execute "powershell.exe" -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$scriptPath`""
$trigger = $date.Hour -eq 00 -and $date.Minute -ge 10
if($service){
$servicenome = Get-Service | findstr "Running"
$service = Get-Service $servicenome
Stop-Service $service 
}
else
{
Write-Host "nao ha servicos no estado Running"
}

Register-ScheduleTask -Name Agenda -Trigger $trigger -action $action -User "System" -RunLevel Highest

#$date = Get-Date
#if ($date.Hour -gt 23 -or ($date.Hour -eq 23 -and $date.Minute -ge 25)) {
 #   Write-Host "A hora atual é após 23:25."
#} else {
 #   Write-Host "A hora atual não é após 23:25."
#}
Get-ScheduledTask
Unregister-ScheduledTask -TaskName Uninstaller_SkipUac_PC -Confirm:$false

