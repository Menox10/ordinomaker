@echo off

REM
REM Name: buildSubLink.cmd
REM 
REM SVN Information:
REM $Revision$
REM $Date$
REM

REM VARIABLE
SET mypath=%~dp0
SET binDir=..\bin
SET graphviz=%binDir%\graphviz\dev\release\bin
SET perl=%binDir%\perl\perl\bin\perl5.18.0.exe

%perl% -w buildSubLink.pl

"%graphviz%"\dot.exe -Tsvg -o ..\doc\buildSubLink.svg ..\tmp\buildSubLink.gv
"%graphviz%"\dot.exe -Tpng -o ..\doc\buildSubLink.png ..\tmp\buildSubLink.gv
