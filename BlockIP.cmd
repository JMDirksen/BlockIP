@echo off
SetLocal EnableDelayedExpansion

:: Get last bad login ip (in last 5 min (300000) )
wevtutil qe Security /c:1 /rd:true /f:text /q:"*[System[EventID=4625 and TimeCreated[timediff(@SystemTime) <= 300000]]]" | find "Source Network Address:" > BlockIP.tmp
for /f "tokens=4" %%a in (BlockIP.tmp) do (set ip=%%a)
del BlockIP.tmp
echo IP: [%ip%]

:: Ignore local ip addresses
set iptest=b%ip%e
if not [%iptest%]==[%iptest:b192.168.=%] exit
if not [%iptest%]==[%iptest:b10.=%] exit

:: Get amount of bad logins from this ip (in last 30 min (1800000) )
wevtutil qe Security /c:3 /rd:true /f:text /q:"*[System[EventID=4625 and TimeCreated[timediff(@SystemTime) <= 1800000]]] and *[EventData[Data[@Name='IpAddress'] and (Data='%ip%')]]" | find /c "%ip%" > BlockIP.tmp
for /f "tokens=1" %%a in (BlockIP.tmp) do (set count=%%a)
del BlockIP.tmp
echo Count: [%count%]

:: Block ip if more than 3 bad attempts
if /i "%count%" lss "3" exit

:: Get current ip block list
netsh advfirewall firewall show rule name=BlockIP | find "RemoteIP:" > BlockIP.tmp
for /f "tokens=2" %%a in (BlockIP.tmp) do (set ipblocklist=%%a)
del BlockIP.tmp
echo Current ipblocklist: [%ipblocklist%]

:: Add ip to ipblocklist
set ipblocklist=%ipblocklist%,%ip%
echo New ipblocklist: [%ipblocklist%]

:: Update firewall rule with new ipblocklist
echo %date% %time% Blocking ip %ip% >> BlockIP.log
echo  New ipblocklist: %ipblocklist% >> BlockIP.log
netsh advfirewall firewall set rule name=BlockIP new remoteip=%ipblocklist%
if %errorlevel%==1 netsh advfirewall firewall add rule name=BlockIP dir=in action=block remoteip=%ipblocklist%
