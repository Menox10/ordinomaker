@echo off

REM 
REM Name: getEnvVPN.cmd
REM 
REM SVN Information:
REM $Revision$
REM $Date$
REM 

SET mypath=%~dp0
SET PATH=%mypath%;%PATH%

REM Server Ref
SET ruser=wasstdp
SET rpw=wasstdp
SET rserver=172.26.1.90

REM Server Master TWS
SET mKserver=spu0wa21
SET mPserver=spu0wa34

REM ############################################################################
:getEnv
REM VPN
ping -w 100 -n 1 172.26.1.90 > NUL
IF NOT "%ERRORLEVEL%"=="0" ( EXIT 0 )

REM Init
echo y | plink.exe -pw %rpw% %ruser%@%rserver% "echo a > /dev/null"
IF NOT "%ERRORLEVEL%"=="0" ( EXIT 0 )

REM Test Prod
plink.exe -pw %rpw% %ruser%@%rserver% "ping -c 1 %mPserver% > /dev/null 2>&1"
IF "%ERRORLEVEL%"=="0" ( EXIT 1 )

plink.exe -pw %rpw% %ruser%@%rserver% "ping -c 1 %mKserver% > /dev/null 2>&1"
IF "%ERRORLEVEL%"=="0" ( EXIT 2 )

:END
EXIT 0