# LAB ONLY. Registers a daily 02:00 Windows scheduled task (current user, no admin). Remove: -Remove
param([switch]$Remove)
$name = 'DBALab-DailyBackup'
if ($Remove) { Unregister-ScheduledTask -TaskName $name -Confirm:$false; return }
$script = Join-Path $PSScriptRoot 'backup.ps1'
$act = New-ScheduledTaskAction -Execute 'powershell.exe' -Argument "-NoProfile -ExecutionPolicy Bypass -File `"$script`""
$trg = New-ScheduledTaskTrigger -Daily -At 2am
Register-ScheduledTask -TaskName $name -Action $act -Trigger $trg -Description 'DBA lab daily pg_dump' -Force | Out-Null
Get-ScheduledTask -TaskName $name | Select-Object TaskName, State
