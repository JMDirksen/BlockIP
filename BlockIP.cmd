@echo off
SetLocal EnableDelayedExpansion
set logfile="%~dp0BlockIP.log"
set tmpfile=%~dp0BlockIP.tmp
echo Start...

:: Check parameter for reset
if "%1"=="reset" goto reset

:: Get last bad login ip (in last 5 min (300000) )
wevtutil qe Security /c:1 /rd:true /f:text /q:"*[System[EventID=4625 and TimeCreated[timediff(@SystemTime) <= 300000]]]" | find "Source Network Address:" > "%tmpfile%"
echo "%tmpfile%"
type "%tmpfile%"
for /f "tokens=4" %%a in (%tmpfile%) do (set ip=%%a)
echo IP address: %ip%
if [%ip%]==[] goto end
if [%ip%]==[-] goto end

:: Get amount of bad logins from this ip (in last 30 min (1800000) )
wevtutil qe Security /c:3 /rd:true /f:text /q:"*[System[EventID=4625 and TimeCreated[timediff(@SystemTime) <= 1800000]]] and *[EventData[Data[@Name='IpAddress'] and (Data='%ip%')]]" | find /c "%ip%" > "%tmpfile%"
for /f "tokens=1" %%a in (%tmpfile%) do (set count=%%a)
echo Attempts: %count%

:: Block ip if more than 3 bad attempts
if /i "%count%" lss "3" goto end

:: Ignore local ip addresses
set iptest=b%ip%e
if not [%iptest%]==[%iptest:b192.168.=%] goto localip
if not [%iptest%]==[%iptest:b10.=%] goto localip

:: Create firewall rule for ip
echo Blocking IP address!
echo %date% %time% Blocking IP address %ip% >> %logfile%
netsh advfirewall firewall add rule name=BlockIP dir=in action=block remoteip=%ip%

goto end

:reset
echo Resetting...
echo %date% %time% Resetting blocked IP addresses >> BlockIP.log
netsh advfirewall firewall delete rule name=BlockIP
goto end

:localip
echo IP address is local
echo %date% %time% Ignoring local ip %ip% >> %logfile%

:end
if exist "%tmpfile%" del "%tmpfile%"
echo Done.
