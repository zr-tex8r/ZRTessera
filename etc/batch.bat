@echo off
setlocal
cd /D %~dp0..
set BAT=%~dp0

:make
if not exist ZRToCid\nul mkdir ZRToCid

rem perl %BAT%gen-ZRCharWidth.pl
rem perl %BAT%gen-ZRJLRClass.pl
rem perl %BAT%gen-ZRKanaCid.pl
perl %BAT%gen-ZRToCid.pl
rem perl %BAT%gen-ZRWidthCid.pl
rem ### this does not work
rem ### perl %BAT%gen-ZRGTCode.pl

exit /B

:exit
