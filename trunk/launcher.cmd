@echo off

REM 
REM Name: launcher.cmd
REM 
REM SVN Information:
REM $Revision$
REM $Date$
REM 

REM mode con: cols=75 lines=75

REM VARIABLE
SET mypath=%~dp0
SET paramFile=params.conf
SET binDir=ordinoMaker\bin
SET binTmp=ordinoMaker\tmp
SET graphviz=%binDir%\graphviz\dev\release\bin
SET perl=%binDir%\perl\perl\bin\perl5.18.0.exe
SET tmpDir=ordinoMaker\tmp

REM ---------------------------------------
REM choix du fichier - launcher.pl
cd %mypath:~0,-1%
del  %binTmp%\choixcpu.cmd 2> NUL
%perl% -w %binDir%\launcher.pl
REM echo %ERRORLEVEL%
if not "%ERRORLEVEL%"=="0" (GOTO :END)
CALL "%mypath:~0,-1%"\%binTmp%\choixcpu.cmd

REM ---------------------------------------
REM Fichier params.conf
echo ----------------------------------------
echo Choix CPU : %CPU%.txt
echo Prise en compte du fichier : %paramFile%
echo Repertoire de travail : %mypath:~0,-1%

REM ---------------------------------------
REM PERL
echo ----------------------------------------
echo Execution du script principal
SET main=%binDir%\main.pl
echo %perl% -w %main% %CPU%.txt
%perl% -w %main% %CPU%.txt

IF NOT "%ERRORLEVEL%"=="0" (
	echo ----------------------------------------
	echo Probleme lors de l execution de %main%
	GOTO :END
)

REM ---------------------------------------
REM GRAPHVIZ
echo ----------------------------------------
echo Creation des graphs :

REM standard
echo   PNG : dot.exe -Tpng -o %CPU%\%CPU%.png %tmpDir%\%CPU%.gv
"%graphviz%"\dot.exe -Tpng -o %CPU%\%CPU%.png %tmpDir%\%CPU%.gv

echo   SVG : dot.exe -Tsvg -o %CPU%\%CPU%.svg %tmpDir%\%CPU%.gv
"%graphviz%"\dot.exe -Tsvg -o %CPU%\%CPU%.svg %tmpDir%\%CPU%.gv

REM Simple
echo   SVG : dot.exe -Tsvg -o %CPU%\%CPU%_simple.svg %tmpDir%\%CPU%_simple.gv
"%graphviz%"\dot.exe -Tsvg -o %CPU%\%CPU%_simple.svg %tmpDir%\%CPU%_simple.gv

REM Full
echo   SVG : dot.exe -Tsvg -o %CPU%\%CPU%_complet.svg %tmpDir%\%CPU%_complet.gv
"%graphviz%"\dot.exe -Tsvg -o %CPU%\%CPU%_complet.svg %tmpDir%\%CPU%_complet.gv

EXPLORER "%mypath:~0,-1%"\"%CPU%"

echo ----------------------------------------
echo Fin Normale du traitement 

GOTO :END

:END
echo ----------------------------------------
pause
exit /B 0
