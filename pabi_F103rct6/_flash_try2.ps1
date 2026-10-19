$ErrorActionPreference = 'Continue'

New-Item -ItemType Directory -Force -Path 'C:\Temp\pabi_flash' | Out-Null

# Resolve hex via short/known relative walk from Desktop
$hexSrc = $null
$root = 'C:\Users\Administrator\Desktop'
$candidates = Get-ChildItem -LiteralPath $root -Directory -ErrorAction SilentlyContinue
foreach ($d1 in $candidates) {
  $p = Join-Path $d1.FullName '双准直\pabi_F103rct6\build\pabi_F103rct6.hex'
  if (Test-Path -LiteralPath $p) { $hexSrc = $p; break }
  # fallback: any build hex under this folder
  $hit = Get-ChildItem -LiteralPath $d1.FullName -Recurse -Filter 'pabi_F103rct6.hex' -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -like '*build*' } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if ($hit) { $hexSrc = $hit.FullName; break }
}

if (-not $hexSrc) {
  Write-Host 'ERROR: cannot find build hex'
  exit 2
}

Write-Host "HEX SRC: $hexSrc"
Copy-Item -LiteralPath $hexSrc -Destination 'C:\Temp\pabi_flash\pabi_F103rct6.hex' -Force
Get-Item 'C:\Temp\pabi_flash\pabi_F103rct6.hex' | Format-List FullName, Length, LastWriteTime

# Try install ST-Link USB driver from Windows Update / generic
$devId = 'USB\VID_0483&PID_3748\5&D784AEA&0&3'
Write-Host 'Attempting driver update via pnputil...'
pnputil /enum-devices /instanceid $devId

# Search local driver store for stlink inf
$infs = @()
$infs += Get-ChildItem 'C:\Windows\System32\DriverStore\FileRepository' -Recurse -Filter '*.inf' -ErrorAction SilentlyContinue |
  Select-String -Pattern 'VID_0483.*PID_3748|STLink|ST-Link' -List -ErrorAction SilentlyContinue |
  Select-Object -ExpandProperty Path -Unique
$infs | Select-Object -First 20 | ForEach-Object { Write-Host "INF: $_" }

$ocd = 'C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\xpack-dev-tools.openocd-xpack_Microsoft.Winget.Source_8wekyb3d8bbwe\xpack-openocd-0.12.0-7\bin\openocd.exe'
Write-Host '--- openocd ---'
& $ocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c 'adapter speed 1000; init; reset halt; exit'
Write-Host ("probe exit=" + $LASTEXITCODE)

if ($LASTEXITCODE -eq 0) {
  Write-Host '--- flashing ---'
  & $ocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c 'adapter speed 1000; program C:/Temp/pabi_flash/pabi_F103rct6.hex verify reset exit'
  Write-Host ("flash exit=" + $LASTEXITCODE)
  exit $LASTEXITCODE
}

Write-Host 'ST-Link still not usable. Need driver install.'
Get-PnpDevice | Where-Object { $_.InstanceId -like 'USB\VID_0483*' } | Format-List *
exit 1
