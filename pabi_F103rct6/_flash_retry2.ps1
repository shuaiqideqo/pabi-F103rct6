$ErrorActionPreference = 'Continue'
$ocd = 'C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\xpack-dev-tools.openocd-xpack_Microsoft.Winget.Source_8wekyb3d8bbwe\xpack-openocd-0.12.0-7\bin\openocd.exe'
$hex = 'C:/Temp/pabi_flash/pabi_F103rct6.hex'

Write-Host '=== search CubeProgrammer / ST-LINK_CLI ==='
Get-ChildItem 'C:\Program Files','C:\Program Files (x86)','D:\' -Filter 'STM32_Programmer_CLI.exe' -Recurse -Depth 6 -ErrorAction SilentlyContinue | Select-Object -First 5 FullName
Get-ChildItem 'C:\Program Files','C:\Program Files (x86)','D:\' -Filter 'ST-LINK_CLI.exe' -Recurse -Depth 6 -ErrorAction SilentlyContinue | Select-Object -First 5 FullName

Write-Host '=== try transport select swd + assert srst ==='
& $ocd -d2 -f interface/stlink.cfg -c 'transport select swd' -f target/stm32f1x.cfg -c 'adapter speed 100; reset_config srst_only srst_nogate connect_assert_srst; init; reset halt; exit' 2>&1 | Select-Object -Last 40

Write-Host '=== try no srst, gdb_port disabled ==='
& $ocd -f interface/stlink.cfg -c 'transport select swd' -f target/stm32f1x.cfg -c 'adapter speed 100; reset_config none separate; gdb_port disabled; tcl_port disabled; telnet_port disabled; init; targets; exit' 2>&1 | Select-Object -Last 40
