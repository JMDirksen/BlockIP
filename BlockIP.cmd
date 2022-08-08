@echo off
SetLocal EnableDelayedExpansion
set blocklistfile="%~dp0BlockIP.list"
set logfile="%~dp0BlockIP.log"
set tmpfile="%~dp0BlockIP.tmp"
echo Start...

:: Get last bad login ip (in last 5 min (300000) )
wevtutil qe Security /c:1 /rd:true /f:text /q:"*[System[EventID=4625 and TimeCreated[timediff(@SystemTime) <= 300000]]]" | find "Source Network Address:" > "%tmpfile%"
for /f "tokens=4" %%a in ('type %tmpfile%') do (set ip=%%a)
echo IP address: %ip%
if [%ip%]==[] goto end
if [%ip%]==[-] goto end

:: Get amount of bad logins from this ip (in last 30 min (1800000) )
wevtutil qe Security /c:3 /rd:true /f:text /q:"*[System[EventID=4625 and TimeCreated[timediff(@SystemTime) <= 1800000]]] and *[EventData[Data[@Name='IpAddress'] and (Data='%ip%')]]" | find /c "%ip%" > "%tmpfile%"
for /f "tokens=1" %%a in ('type %tmpfile%') do (set count=%%a)
echo Attempts: %count%

:: Block ip if 3 or more bad attempts
if %count% lss 3 goto end

:: Ignore local ip addresses
set iptest=b%ip%e
if not [%iptest%]==[%iptest:b192.168.=%] goto localip
if not [%iptest%]==[%iptest:b10.=%] goto localip

:: Create firewall rule for new ip blocklist
echo Blocking IP address!
echo %date% %time% Blocking IP address %ip% >> %logfile%
call :addToUniqueLimitedList %blocklistfile% 1000 %ip%
call :joinList %blocklistfile%
netsh advfirewall firewall set rule name=BlockIP new remoteip=%join%
if %errorlevel% equ 1 netsh advfirewall firewall add rule name=BlockIP dir=in action=block remoteip=%join%
goto end


:addToUniqueLimitedList
:: Usage: call :addToUniqueLimitedList "<filename>" <maxlines> "<line to add>"
findstr /c:"%~3" %1>nul
if %errorlevel% equ 0 exit /b
(echo %~3)>>%1
:removelines
call :countlines %1
if %count% leq %2 exit /b
call :removefirstline %1
goto removelines


:countlines
:: Usage: call :countlines "<filename>"
:: Returns: the variable %count% will be set with the number of lines in the file
for /f "tokens=3" %%a in ('find /v /c "#$#" %1') do (set count=%%a)
exit /b


:removefirstline
:: Usage: call :removefirstline "<filename>"
findstr /v /n "#$#" %1 > "temp1.tmp"
findstr /v /b "1:" "temp1.tmp" > "temp2.tmp"
copy nul %1>nul
for /f "tokens=2 delims=:" %%a in ('type "temp2.tmp"') do ((echo %%a)>>%1)
del "temp1.tmp" "temp2.tmp"
exit /b


:joinList
:: Usage: call :joinList "<filename>"
:: Returns: %join% all the lines from the file joined to one comma separated string
set join=
for /f "tokens=*" %%a in ('type %1') do (set join=!join!%%a,)
exit /b


:localip
echo IP address is local
echo %date% %time% Ignoring local ip %ip% >> %logfile%

:end
if exist %tmpfile% del %tmpfile%
echo Done.
