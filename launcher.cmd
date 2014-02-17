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
REM SET perl=%binDir%\perl\perl\bin\perl5.18.0.exe
SET perl=%binDir%\perl5.8.8\perl\bin\perl5.8.8.exe
SET selectFile=%username%.cmd

REM ---------------------------------------
REM choix du fichier - launcher.pl
cd %mypath:~0,-1%

:LAUNCHER
%perl% -w %binDir%\launcher.pl %selectFile% %SERVICE%
SET CR=%ERRORLEVEL%

IF "%CR%"=="1" (GOTO :END1)
IF NOT "%CR%"=="0" (GOTO :END)

CALL "%mypath:~0,-1%"\%tmpDir%\%selectFile%

REM ---------------------------------------
REM Fichier params.conf
echo ----------------------------------------
SET ordinoDir=_ordinogramme\%SERVICE%\%FILE%
echo Service           : %SERVICE%
echo Fichier           : %FILE%
echo Rep. ordinogramme : %ordinoDir%
echo Rep. de travail   : %mypath:~0,-1%


REM ---------------------------------------
REM PERL
echo ----------------------------------------
echo Execution du script principal
SET main=%binDir%\main.pl
echo %perl% -w %main% %SERVICE% %FILE%.txt
%perl% -w %main% %SERVICE% %FILE%.txt

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
echo   PNG : %FILE%.png
"%graphviz%"\dot.exe -Tpng -o %ordinoDir%\%FILE%.png %tmpDir%\%FILE%.gv

echo   SVG : %FILE%.svg
"%graphviz%"\dot.exe -Tsvg -o %ordinoDir%\%FILE%.svg %tmpDir%\%FILE%.gv
REM Simple
echo         %FILE%_simple.svg
"%graphviz%"\dot.exe -Tsvg -o %ordinoDir%\%FILE%_simple.svg %tmpDir%\%FILE%_simple.gv
REM Full
echo         %FILE%_complet.svg
"%graphviz%"\dot.exe -Tsvg -o %ordinoDir%\%FILE%_complet.svg %tmpDir%\%FILE%_complet.gv

EXPLORER "%mypath:~0,-1%"\"%ordinoDir%"

echo.
echo ----------------------------------------
echo Fin Normale du traitement 
GOTO :LAUNCHER
REM GOTO :END

:END
echo ----------------------------------------
pause
exit /B 0

:END1
exit /B 0