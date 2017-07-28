@echo off
setlocal
cd /D %~dp0..
set BAT=%~dp0

:make
if not exist ZRToCid\nul mkdir ZRToCid

perl %BAT%gen-ZRCharWidth.pl
perl %BAT%gen-ZRJLRClass.pl
perl %BAT%gen-ZRKanaCid.pl
perl %BAT%gen-ZRToCid.pl
rem perl %BAT%gen-ZRWidthCid.pl
rem ### this does not work
rem ### perl %BAT%gen-ZRGTCode.pl

exit /B

:exit
