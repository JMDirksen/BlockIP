@echo off
cd /d "%~dp0"
net session >nul 2>&1
if %errorLevel% neq 0 echo Please run as administrator & goto end
if "%1" == "reset" goto reset

set /p ip=Enter IP to block: 
set /p reason=Reason: 
set name=BlockIP %ip% %reason%
set command=netsh advfirewall firewall add rule name="%name%" dir=in action=block remoteip="%ip%"
%command% >nul
if %errorLevel% neq 0 echo Something went wrong, please check your input & goto end
echo %command% >> %0
echo IP block rule "%name%" added.
goto end

:end
echo.
pause
exit /b 0

:reset
