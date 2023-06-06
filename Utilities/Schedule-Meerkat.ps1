# Run Meerkat with highest rights every hour
# This setup includes creating a secure .ps1 file, then running the below code to create the scheduled task and reference said script file.

Add-WindowsFeature RSAT-AD-PowerShell
Import-Module ActiveDiMeerkattory

# Creation of MSAs immediately.
Add-KdsRootKey -EffectiveTime ((Get-Date).AddHours(-10))

$MSAName = "svcMSA-Meerkat"
$Server = "SystemName"

$Identity = Get-ADComputer -identity $Server
New-ADServiceAccount -Name $MSAName -Enabled $true -RestrictToSingleComputer -KerberosEncryptionType AES256
Add-ADComputerServiceAccount -Identity $Identity -ServiceAccount $MSAName

Install-ADServiceAccount -Identity ($MSAName + "$")
Uninstall-WindowsFeature RSAT-AD-PowerShell

$Action = New-ScheduledTaskAction -Execute 'Powershell.exe' -Argument '-ExecutionPolicy Bypass -Windowstyle Hidden -File "C:\Program Files\WindowsPowerShell\Modules\Meerkat\Utilities\Meerkat-Task.ps1"'
$Trigger = New-ScheduledTaskTrigger -Once -At (Get-Date) -RepetitionDuration (New-TimeSpan -Days (365 * 20)) -RepetitionInterval  (New-TimeSpan -Minutes 60)
$Principal = New-ScheduledTaskPrincipal -UserId ($MSAName + "$") -RunLevel Highest -LogonType Password

Register-ScheduledTask -Action $Action -Trigger $Trigger -Principal $Principal -TaskName "Meerkat Collection" -Description "https://github.com/TonyPhipps/Meerkat"

# C:\Meerkat.ps1 would contain something like:
# Import-Module C:\Program Files\WindowsPowerShell\Modules\Meerkat\Meerkat.psm1 -Force
# Invoke-Meerkat -Output C:\Meerkat
