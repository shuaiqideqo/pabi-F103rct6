$ErrorActionPreference = 'Continue'
$ocd = 'C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\xpack-dev-tools.openocd-xpack_Microsoft.Winget.Source_8wekyb3d8bbwe\xpack-openocd-0.12.0-7\bin\openocd.exe'
$hex = 'C:\Temp\pabi_flash\pabi_F103rct6.hex'

$attempts = @(
  @{ Name = 'hla_swd + connect_assert_srst'; Args = @('-f','interface/stlink.cfg','-c','transport select hla_swd','-f','target/stm32f1x.cfg','-c','adapter speed 1000; reset_config srst_only connect_assert_srst; init; reset halt; exit') },
  @{ Name = 'hla_swd + none'; Args = @('-f','interface/stlink.cfg','-c','transport select hla_swd','-f','target/stm32f1x.cfg','-c','adapter speed 100; reset_config none; init; reset halt; exit') },
  @{ Name = 'dapdirect + connect_assert_srst'; Args = @('-f','interface/stlink.cfg','-f','target/stm32f1x.cfg','-c','adapter speed 100; reset_config srst_only connect_assert_srst; init; reset halt; exit') },
  @{ Name = 'hla_swd slow'; Args = @('-f','interface/stlink.cfg','-c','transport select hla_swd','-f','target/stm32f1x.cfg','-c','adapter speed 50; init; halt; exit') }
)

$ok = $false
foreach ($a in $attempts) {
  Write-Host ("=== TRY: " + $a.Name + " ===")
  & $ocd @($a.Args) 2>&1 | ForEach-Object { "$_" }
  Write-Host ("exit=" + $LASTEXITCODE)
  if ($LASTEXITCODE -eq 0) { $ok = $true; $script:best = $a; break }
}

if (-not $ok) {
  Write-Host 'All OpenOCD connect modes failed.'
  # Try CubeProgrammer if present
  $cli = @(
    'C:\Program Files\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe',
    'C:\Program Files (x86)\STMicroelectronics\STM32Cube\STM32CubeProgrammer\bin\STM32_Programmer_CLI.exe'
  ) | Where-Object { Test-Path $_ } | Select-Object -First 1
  if ($cli) {
    Write-Host "Trying CubeProgrammer: $cli"
    & $cli -c port=SWD freq=1000 mode=UR -l
    & $cli -c port=SWD freq=1000 mode=UR -w $hex -v -rst
    exit $LASTEXITCODE
  }
  exit 1
}

Write-Host ("=== FLASH with: " + $best.Name + " ===")
# Rebuild flash command from successful style
if ($best.Name -like '*hla*') {
  & $ocd -f interface/stlink.cfg -c 'transport select hla_swd' -f target/stm32f1x.cfg -c "adapter speed 1000; reset_config srst_only connect_assert_srst; program $hex verify reset exit"
} else {
  & $ocd -f interface/stlink.cfg -f target/stm32f1x.cfg -c "adapter speed 1000; reset_config srst_only connect_assert_srst; program $hex verify reset exit"
}
Write-Host ("flash exit=" + $LASTEXITCODE)
exit $LASTEXITCODE
