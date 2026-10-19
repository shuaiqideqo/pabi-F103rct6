$ErrorActionPreference = 'Continue'
$ocd = 'C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\xpack-dev-tools.openocd-xpack_Microsoft.Winget.Source_8wekyb3d8bbwe\xpack-openocd-0.12.0-7\bin\openocd.exe'
$hex = 'C:/Temp/pabi_flash/pabi_F103rct6.hex'

# Refresh hex from latest build
$desktop = 'C:\Users\Administrator\Desktop'
foreach ($d in (Get-ChildItem -LiteralPath $desktop -Directory -ErrorAction SilentlyContinue)) {
  $hit = Get-ChildItem -LiteralPath $d.FullName -Recurse -Filter 'pabi_F103rct6.hex' -ErrorAction SilentlyContinue |
    Where-Object { $_.DirectoryName -like '*build*' } |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
  if ($hit) {
    New-Item -ItemType Directory -Force -Path 'C:\Temp\pabi_flash' | Out-Null
    Copy-Item -LiteralPath $hit.FullName -Destination 'C:\Temp\pabi_flash\pabi_F103rct6.hex' -Force
    Write-Host ("HEX: " + $hit.FullName + " @ " + $hit.LastWriteTime)
    break
  }
}

Write-Host '=== device ==='
Get-PnpDevice | Where-Object { $_.InstanceId -like 'USB\VID_0483*' } | Format-Table Status, FriendlyName -AutoSize

$modes = @(
  @{ n = 'swd default'; c = 'transport select swd; adapter speed 1000; init; reset halt; exit' },
  @{ n = 'swd assert srst'; c = 'transport select swd; adapter speed 1000; reset_config srst_only connect_assert_srst; init; reset halt; exit' },
  @{ n = 'swd slow none'; c = 'transport select swd; adapter speed 100; reset_config none; init; reset halt; exit' }
)

$connected = $false
foreach ($m in $modes) {
  Write-Host ("=== probe: " + $m.n + " ===")
  & $ocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c $m.c 2>&1 | ForEach-Object { "$_" }
  if ($LASTEXITCODE -eq 0) {
    $connected = $true
    $script:modeCmd = $m.c.Replace('; init; reset halt; exit', '')
    Write-Host 'CONNECTED'
    break
  }
}

if (-not $connected) {
  Write-Host 'Still cannot connect to target.'
  exit 1
}

Write-Host '=== FLASH ==='
& $ocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c "$modeCmd; program $hex verify reset exit" 2>&1 | ForEach-Object { "$_" }
Write-Host ("flash exit=" + $LASTEXITCODE)
exit $LASTEXITCODE
