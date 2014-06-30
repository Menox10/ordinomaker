@echo off

REM 
REM Name: sendTarMMC.cmd
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

CALL "ordinoMaker/etc/profileMMC.cmd"

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