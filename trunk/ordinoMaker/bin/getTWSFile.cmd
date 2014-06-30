@echo off

REM 
REM Name: getTWSFile.cmd
REM 
REM SVN Information:
REM $Revision$
REM $Date$
REM 

SET mypath=%~dp0
SET PATH=%mypath%;%mypath%convertFile\bin\;%PATH%

CALL "ordinoMaker/etc/profile.cmd"

REM variable
SET CPU=%2
SET Env=%1

SET composer=/opt/IBM/TWA/TWS/bin/composer
SET hostname=/usr/bin/hostname
SET desk=%HOMEDRIVE%%HOMEPATH%\Bureau

IF "%CPU%"=="" ( GOTO :USAGE )

REM ############################################################################
:getEnv
if "%Env%"=="Qualif" (SET Server=%mKserver%)
if "%Env%"=="Prod"	 (SET Server=%mPserver%)

if "%Server%"=="" (	GOTO :USAGE )

echo --------------------
echo Bureau ^= %desk%
echo Env : %Env%
echo TWS : %Server%

SET Fsched=%CPU%_%Env%.txt
SET Fjobs=%CPU%_%Env%_jobs.txt

REM ############################################################################
REM Jobstream

echo Recuperation des fichiers en cours
echo    ^=^> Fichier Jobstream
SET rcmd1=ssh %muser%@%server% 'cd %mdir% ^&^& %composer% create %Fsched% from s=%CPU%#@ ^> /dev/null 2^>^&1'

echo y | plink.exe -pw %rpw% %ruser%@%rserver% "%rcmd1%"
IF NOT "%ERRORLEVEL%"=="0" (
	echo %CPU% : CPU non trouvee !
	GOTO :END
)

REM Jobs
echo    ^=^> Fichier Jobs
SET rcmd2=ssh %muser%@%server% 'cd %mdir% ^&^& %composer% create %Fjobs% from j=%CPU%#@ ^> /dev/null 2^>^&1'
plink.exe -pw %rpw% %ruser%@%rserver% "%rcmd2%"

REM scp TWS -> Ref
echo    ^=^> scp TWS -^> Ref
SET rcmd3=cd %rdir% ^&^& scp '%muser%@%server%:%mdir%/%Fsched% %mdir%/%Fjobs%' .
plink.exe -pw %rpw% %ruser%@%rserver% "%rcmd3%"

REM scp Ref -> Local
echo    ^=^> scp Ref -^> Local
pscp.exe -pw %rpw% %ruser%@%rserver%:%rdir%/%CPU%* "%desk%"

REM Purge
SET rcmd4=rm %rdir%/%Fsched% %rdir%/%Fjobs%
plink.exe -pw %rpw% %ruser%@%rserver% "%rcmd4%"

REM CovertFile unix -> dos
echo    ^=^> CovertFile unix -^> dos
CALL unix2dos.exe "%desk%\%Fsched%" 
CALL unix2dos.exe "%desk%\%Fjobs%"

GOTO :END

:USAGE
ECHO Usage :
ECHO    %0 [Env] [ CPU ]
ECHO       [Env] ^= [Qualif^|Prod]
GOTO :END

:END
echo --------------------
