$ErrorActionPreference = 'Continue'
$work = 'C:\Temp\pabi_flash'
New-Item -ItemType Directory -Force -Path $work | Out-Null
$infDir = Join-Path $work 'winusb_stlink'
New-Item -ItemType Directory -Force -Path $infDir | Out-Null

$inf = @'
; Temporary WinUSB binding for ST-Link/V2 so OpenOCD can open the device.
[Version]
Signature="$WINDOWS NT$"
Class=USBDevice
ClassGuid={88BAE032-5A81-49f0-BC3D-A4FF138216D6}
Provider=%MFG%
DriverVer=09/15/2026,1.0.0.0
PnpLockdown=1

[DestinationDirs]
DefaultDestDir=12

[Manufacturer]
%MFG%=DeviceList,NTamd64

[DeviceList.NTamd64]
%DESC%=USB_Install, USB\VID_0483&PID_3748

[USB_Install]
Include=winusb.inf
Needs=WINUSB.NT

[USB_Install.Services]
Include=winusb.inf
Needs=WINUSB.NT.Services

[USB_Install.HW]
AddReg=Dev_AddReg

[Dev_AddReg]
HKR,,DeviceInterfaceGUIDs,0x10000,"{a5dcbf10-6530-11d2-901f-00c04fb951ed}"

[Strings]
MFG="STMicroelectronics"
DESC="STM32 STLink (WinUSB)"
'@

Set-Content -Path (Join-Path $infDir 'stlink_winusb.inf') -Value $inf -Encoding ASCII

Write-Host 'Installing WinUSB INF (may require signed driver policy)...'
pnputil /add-driver (Join-Path $infDir 'stlink_winusb.inf') /install | Out-Host

Start-Sleep 2
Get-PnpDevice | Where-Object { $_.InstanceId -like 'USB\VID_0483&PID_3748*' } | Format-List FriendlyName, Status, Problem, Service, Class

# Also try downloading official zip mirrors / github
$urls = @(
  'https://github.com/stlink-org/stlink/releases/download/v1.8.0/stlink-1.8.0-win64.zip'
)
foreach ($u in $urls) {
  try {
    $out = Join-Path $work 'stlink-tools.zip'
    Write-Host "Downloading $u"
    Invoke-WebRequest -Uri $u -OutFile $out -UseBasicParsing -TimeoutSec 60
    Write-Host "saved $out size=$((Get-Item $out).Length)"
  } catch {
    Write-Host ("download fail: " + $_.Exception.Message)
  }
}

# Try chocolatey
where.exe choco 2>$null
where.exe scoop 2>$null

$ocd = 'C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\xpack-dev-tools.openocd-xpack_Microsoft.Winget.Source_8wekyb3d8bbwe\xpack-openocd-0.12.0-7\bin\openocd.exe'
Write-Host '--- probe ---'
& $ocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c 'adapter speed 1000; transport select hla_swd; init; reset halt; exit'
Write-Host ("exit=" + $LASTEXITCODE)
if ($LASTEXITCODE -ne 0) {
  Write-Host '--- probe dapdirect ---'
  & $ocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c 'adapter speed 1000; init; reset halt; exit'
  Write-Host ("exit=" + $LASTEXITCODE)
}

if ($LASTEXITCODE -eq 0 -and (Test-Path 'C:\Temp\pabi_flash\pabi_F103rct6.hex')) {
  Write-Host '--- flash ---'
  & $ocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c 'adapter speed 1000; program C:/Temp/pabi_flash/pabi_F103rct6.hex verify reset exit'
  Write-Host ("flash exit=" + $LASTEXITCODE)
}
