$ErrorActionPreference = 'Continue'
Write-Host '=== ST-Link device ==='
Get-PnpDevice | Where-Object { $_.InstanceId -like 'USB\VID_0483*' -or $_.FriendlyName -match 'STLink|ST-Link|STM32 STLink' } |
  Format-Table Status, Class, FriendlyName, InstanceId -AutoSize

$ocd = 'C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\xpack-dev-tools.openocd-xpack_Microsoft.Winget.Source_8wekyb3d8bbwe\xpack-openocd-0.12.0-7\bin\openocd.exe'
$hexCandidates = @(
  'C:\Temp\pabi_flash\pabi_F103rct6.hex'
)
# refresh hex from project build if needed
$desktop = 'C:\Users\Administrator\Desktop'
foreach ($d in (Get-ChildItem -LiteralPath $desktop -Directory -ErrorAction SilentlyContinue)) {
  $hit = Get-ChildItem -LiteralPath $d.FullName -Recurse -Filter 'pabi_F103rct6.hex' -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -like '*build*' } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if ($hit) {
    New-Item -ItemType Directory -Force -Path 'C:\Temp\pabi_flash' | Out-Null
    Copy-Item -LiteralPath $hit.FullName -Destination 'C:\Temp\pabi_flash\pabi_F103rct6.hex' -Force
    Write-Host ("HEX from: " + $hit.FullName + "  time=" + $hit.LastWriteTime)
    break
  }
}

$hex = 'C:\Temp\pabi_flash\pabi_F103rct6.hex'
Write-Host ("HEX exists: " + (Test-Path $hex))
if (Test-Path $hex) { Get-Item $hex | Format-List FullName, Length, LastWriteTime }

Write-Host '=== OpenOCD probe ==='
& $ocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c 'adapter speed 1000; init; reset halt; exit'
$probe = $LASTEXITCODE
Write-Host ("probe exit=" + $probe)

if ($probe -ne 0) {
  Write-Host 'Probe failed, not flashing.'
  exit 1
}

Write-Host '=== Flashing ==='
& $ocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c 'adapter speed 1000; program C:/Temp/pabi_flash/pabi_F103rct6.hex verify reset exit'
$flash = $LASTEXITCODE
Write-Host ("flash exit=" + $flash)
exit $flash
