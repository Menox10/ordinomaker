@echo off
break
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
SET binDir=ordinoMaker\bin
SET tmpDir=ordinoMaker\tmp
SET graphviz=%binDir%\graphviz\dev\release\bin
SET perl=%binDir%\perl\perl\bin\perl5.18.0.exe

REM ---------------------------------------
REM choix du fichier - launcher.pl
cd %mypath:~0,-1%
del  %tmpDir%\choixcpu.cmd 2> NUL
:LAUNCHER
%perl% -w %binDir%\launcher.pl
SET CR=%ERRORLEVEL%

IF "%CR%"=="1" (GOTO :END1)
IF "%CR%"=="2" (GOTO :LAUNCHER)
IF NOT "%CR%"=="0" (GOTO :END)

CALL "%mypath:~0,-1%"\%tmpDir%\choixcpu.cmd

REM ---------------------------------------
REM Fichier params.conf
echo ----------------------------------------
SET ordinoDir=_ordinogramme\%CPU%
echo Choix CPU : %CPU%.txt
echo Repertoire de travail : %mypath:~0,-1%
echo Repertoire ordinogramme : %ordinoDir%

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
echo Creation des graphs (dot.exe):

REM standard
echo   PNG : %CPU%.gv
"%graphviz%"\dot.exe -Tpng -o %ordinoDir%\%CPU%.png %tmpDir%\%CPU%.gv

echo   SVG : %CPU%.gv
"%graphviz%"\dot.exe -Tsvg -o %ordinoDir%\%CPU%.svg %tmpDir%\%CPU%.gv

REM Simple
echo         %CPU%_simple.gv
"%graphviz%"\dot.exe -Tsvg -o %ordinoDir%\%CPU%_simple.svg %tmpDir%\%CPU%_simple.gv

REM Full
echo         %CPU%_complet.gv
"%graphviz%"\dot.exe -Tsvg -o %ordinoDir%\%CPU%_complet.svg %tmpDir%\%CPU%_complet.gv

EXPLORER "%mypath:~0,-1%"\"%ordinoDir%"

echo ----------------------------------------
echo Fin Normale du traitement 

GOTO :END

:END
echo ----------------------------------------
pause
exit /B 0

:END1
exit /B 0