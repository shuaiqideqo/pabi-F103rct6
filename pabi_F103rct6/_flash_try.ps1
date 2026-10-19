$ErrorActionPreference = 'Continue'
$dev = Get-PnpDevice | Where-Object { $_.InstanceId -like 'USB\VID_0483&PID_3748*' }
$dev | Format-List FriendlyName, Status, InstanceId, Problem
if ($dev) {
  try {
    Disable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction Stop
    Start-Sleep 1
    Enable-PnpDevice -InstanceId $dev.InstanceId -Confirm:$false -ErrorAction Stop
    Write-Host 're-enabled OK'
  } catch {
    Write-Host ('re-enable failed: ' + $_.Exception.Message)
  }
}
pnputil /scan-devices | Out-Host
Start-Sleep 2
Get-PnpDevice | Where-Object { $_.InstanceId -like 'USB\VID_0483*' } | Format-Table Status, FriendlyName, InstanceId -AutoSize

$ocd = 'C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\xpack-dev-tools.openocd-xpack_Microsoft.Winget.Source_8wekyb3d8bbwe\xpack-openocd-0.12.0-7\bin\openocd.exe'
$hex = 'C:\Users\Administrator\Desktop\小车\双准直-修改\双准直\pabi_F103rct6\build\pabi_F103rct6.hex'
Write-Host "OCD exists: $(Test-Path $ocd)"
Write-Host "HEX exists: $(Test-Path $hex)"

# Try common CubeProgrammer locations
$cliCandidates = @(
  'C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe',
  'C:\Program Files (x86)\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe',
  'D:\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe'
)
foreach ($c in $cliCandidates) {
  if (Test-Path $c) { Write-Host "FOUND CLI: $c" }
}

Write-Host '--- openocd probe ---'
& $ocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c 'init; reset halt; exit'
Write-Host ("openocd exit: " + $LASTEXITCODE)
