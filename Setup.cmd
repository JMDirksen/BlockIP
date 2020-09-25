@echo off
schtasks /create /tn "BlockIP Trigger" /tr "%~dp0BlockIP.cmd" /ru system /sc onevent /ec Security /mo "*[System[Provider[@Name='Microsoft-Windows-Security-Auditing'] and EventID=4625]]"
echo.
echo.
if %ERRORLEVEL%==1 echo Make sure to run this setup with elevated permissions (Run as administrator).
pause
