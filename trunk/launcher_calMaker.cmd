@echo off
break
REM 
REM Name: launcher_calMaker.cmd
REM 
REM SVN Information:
REM $Revision$
REM $Date$
REM 

REM mode con: cols=75 lines=75

REM VARIABLE
SET mypath=%~dp0
SET binDir=ordinoMaker\bin
SET tmpDir=ordinoMaker\tmp
SET graphviz=%binDir%\graphviz\dev\release\bin
REM SET perl=%binDir%\perl\perl\bin\perl5.18.0.exe
REM SET perl=D:\perl\bin\perl5.16.3.exe
SET perl=%binDir%\perl5.8.8\perl\bin\perl5.8.8.exe
cd %mypath:~0,-1%

REM ---------------------------------------
REM PERL
echo ----------------------------------------
echo Execution du script principal
SET main=%binDir%\main_calMaker.pl
echo %perl% -w %main%
%perl% -w %main%

IF NOT "%ERRORLEVEL%"=="0" (
	echo ----------------------------------------
	echo Probleme lors de l execution de %main%
	GOTO :END
)

EXPLORER "%mypath:~0,-1%"\_calendrier"

:END
echo ----------------------------------------
pause
exit /B 0
