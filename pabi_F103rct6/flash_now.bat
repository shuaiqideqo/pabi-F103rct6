@echo off
setlocal
set OCD=C:\Users\Administrator\AppData\Local\Microsoft\WinGet\Packages\xpack-dev-tools.openocd-xpack_Microsoft.Winget.Source_8wekyb3d8bbwe\xpack-openocd-0.12.0-7\bin\openocd.exe
set HEX=%~dp0build\pabi_F103rct6.hex
echo HEX=%HEX%
echo OCD=%OCD%
"%OCD%" -f interface/stlink.cfg -f target/stm32f1x.cfg -c "program \"%HEX%\" verify reset exit"
echo EXIT=%ERRORLEVEL%
endlocal
