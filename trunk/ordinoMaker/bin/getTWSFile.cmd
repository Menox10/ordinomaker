@echo off

REM 
REM Name: getTWSFile.cmd
REM 
REM SVN Information:
REM $Revision$
REM $Date$
REM 

SET mypath=%~dp0
SET PATH=%PATH%;%mypath%

REM Server Ref
SET ruser=wasstdp
SET rpw=wasstdp
SET rserver=172.26.1.90
SET rdir=/gw4/gw4adm/tmp

REM Server Master TWS
SET muser=tws_ga1
SET mKserver=spu0wa21
SET mPserver=spu0wa34
SET mdir=/home/tws_ga1/APPLICATIONS/CRR/Exploit/tmp

REM variable
SET CPU=%1
SET Server=
SET Env=

SET composer=/opt/IBM/TWA/TWS/bin/composer
SET desk="%HOMEPATH%\Bureau"

if "%CPU%"=="" (
	echo Usage :
	echo    %0 [ CPU ]
	GOTO :END
)

REM ############################################################################
echo --------------------
:getEnv
REM VPN
ping -w 100 -n 1 172.26.1.90 > NUL
IF NOT "%ERRORLEVEL%"=="0" (
	echo VPN : Aucune Connexion !
	GOTO :END
)

REM Test Prod
plink.exe -pw %rpw% %ruser%@%rserver% "ping -c 1 %mPserver% > /dev/null 2>&1"
IF "%ERRORLEVEL%"=="0" (
	SET Server=%mPserver%
	SET Env=Prod
)

plink.exe -pw %rpw% %ruser%@%rserver% "ping -c 1 %mKserver% > /dev/null 2>&1"
IF "%ERRORLEVEL%"=="0" (
	SET Server=%mKserver%
	SET Env=Qualif
)

if "%Server%"=="" (
	echo Impossible de definir le server TWS !
	GOTO :END
)

echo Environnement : %Env%
echo Server        : %Server%

SET Fsched=%CPU%_%Env%.txt
SET Fjobs=%CPU%_%Env%_jobs.txt

REM ############################################################################
REM Jobstream

echo Recuperation des fichiers en cours
echo    ^=^> Fichier Jobstream
SET rcmd1=ssh %muser%@%server% 'cd %mdir% ^&^& %composer% create %Fsched% from s=%CPU%#@ ^> /dev/null 2^>^&1'

plink.exe -pw %rpw% %ruser%@%rserver% "%rcmd1%"
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
pscp.exe -pw %rpw% %ruser%@%rserver%:%rdir%/%CPU%* %desk%

REM Purge
SET rcmd4=rm %rdir%/%Fsched% %rdir%/%Fjobs%
plink.exe -pw %rpw% %ruser%@%rserver% "%rcmd4%"

REM CovertFile unix -> dos
echo    ^=^> CovertFile unix -^> dos
bin\unix2dos.exe %desk%\%Fsched% 2> NUL
bin\unix2dos.exe %desk%\%Fjobs% 2> NUL

:END
echo --------------------
