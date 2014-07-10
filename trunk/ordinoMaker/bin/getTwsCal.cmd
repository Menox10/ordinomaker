@echo off

REM 
REM Name: getTwsCal.cmd
REM 
REM SVN Information:
REM $Revision$
REM $Date$
REM 

SET mypath=%~dp0
SET PATH=%mypath%;%mypath%convertFile\bin\;%PATH%

CALL "ordinoMaker/etc/profile.cmd"

REM variable
SET Env=%1
SET Dest=%2

SET composer=/opt/IBM/TWA/TWS/bin/composer
SET desk=%cd%\%Dest%
SET Fcal=calendar_%Env%.txt

mkdir %Dest%

REM ############################################################################
:getEnv
if "%Env%"=="Qualif" (SET Server=%mKserver%)
if "%Env%"=="Prod"	 (SET Server=%mPserver%)

if "%Server%"=="" (	GOTO :USAGE )

echo Env  : %Env%
echo TWS  : %Server%
echo Dest : %desk%

REM ############################################################################
REM Calendrier

echo Recuperation des fichiers en cours
echo    ^=^> Fichier calendrier
SET rcmd1=ssh %muser%@%server% 'cd %mdir% ^&^& %composer% create %Fcal% from cal ^> /dev/null 2^>^&1'

echo y | plink.exe -pw %rpw% %ruser%@%rserver% "%rcmd1%"
IF NOT "%ERRORLEVEL%"=="0" (
	echo Probleme dans la creation du fichier calendrier !
	GOTO :END
)

REM scp TWS -> Ref
echo    ^=^> scp TWS -^> Ref
SET rcmd3=cd %rdir% ^&^& scp '%muser%@%server%:%mdir%/%Fcal%' .
plink.exe -pw %rpw% %ruser%@%rserver% "%rcmd3%"

REM scp Ref -> Local
echo    ^=^> scp Ref -^> Local
pscp.exe -pw %rpw% %ruser%@%rserver%:%rdir%/%Fcal% "%desk%"

REM Purge
SET rcmd4=rm %rdir%/%Fcal%
plink.exe -pw %rpw% %ruser%@%rserver% "%rcmd4%"

REM CovertFile unix -> dos
echo    ^=^> CovertFile unix -^> dos
CALL unix2dos.exe "%desk%\%Fcal%" 

GOTO :END

:USAGE
ECHO Usage :
ECHO    %0 [Env] [Dest]
ECHO       [Env] ^= [Qualif^|Prod]
GOTO :END

:END
