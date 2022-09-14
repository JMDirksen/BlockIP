@echo off
SetLocal EnableDelayedExpansion
set blocklistfile="%~dp0BlockIP.list"

call :joinList %blocklistfile%
if [%join%]==[] netsh advfirewall firewall delete rule name=BlockIP & exit /b
netsh advfirewall firewall set rule name=BlockIP new remoteip=%join%
if %errorlevel% equ 1 netsh advfirewall firewall add rule name=BlockIP dir=in action=block remoteip=%join%
exit /b

:joinList
:: Usage: call :joinList "<filename>"
:: Returns: %join% all the lines from the file joined to one comma separated string
set join=
for /f "tokens=*" %%a in ('type %1') do (set join=!join!%%a,)
exit /b
