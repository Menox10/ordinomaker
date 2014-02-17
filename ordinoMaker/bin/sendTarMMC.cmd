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

REM
SET tarFile=%1

IF "%tarFile%"=="" ( GOTO :USAGE )

REM Server Ref
SET ruser=wasv32c
SET rpw=wasv32c
SET rserver=172.26.1.90
SET rdir=/data2/v32/v32c/pp/smid/tmp/ordinogramme

REM ############################################################################
:sendTar
echo y | plink.exe -pw %rpw% %ruser%@%rserver% "echo a > /dev/null"
IF NOT "%ERRORLEVEL%"=="0" ( 
	echo Impossible de conatcter le serveur Ref %rserver% !
	GOTO :END1
)

echo    ^=^> scp %tarFile% -^> Server Ref
pscp.exe -pw %rpw% %temp%\%tarFile% %ruser%@%rserver%:%rdir%/%tarFile%
GOTO :END

:USAGE
ECHO Usage :
ECHO    %0 [tarFile]
GOTO :END

:END1
EXIT 1

:END
EXIT 0