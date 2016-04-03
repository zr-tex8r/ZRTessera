@echo off
if "%ZR_PUBLIC_SCRIPT%"=="" exit /b
if "%1"=="make" goto make
if "%1"=="install" goto install

:usage
perl -e "print q/Usage: %~n0 { make | install }/,qq/\n/"
exit /b

:make
cd %~dp0
if not exist ZRToCid\nul mkdir ZRToCid
if not exist ZRToCid\nul exit /b
perl gen-ZRCharWidth.pl
perl gen-ZRJLRClass.pl
perl gen-ZRKanaCid.pl
perl gen-ZRToCid.pl
perl gen-ZRWidthCid.pl
perl gen-ZRGTCode.pl
exit /b

:install
cd %~dp0
:__ins0
if not exist ZRCharWidth.pm goto __ins1
move /Y ZRCharWidth.pm %ZR_PUBLIC_SCRIPT%
:__ins1
if not exist ZRJLRClass.pm goto __ins2
move /Y ZRJLRClass.pm %ZR_PUBLIC_SCRIPT%
:__ins2
if not exist ZRKanaCid.pm goto __ins3
move /Y ZRKanaCid.pm %ZR_PUBLIC_SCRIPT%
:__ins3
if not exist ZRWidthCid.pm goto __ins4
move /Y ZRWidthCid.pm %ZR_PUBLIC_SCRIPT%
:__ins4
if not exist ZRCMapOut.pm goto __ins5
copy /Y ZRCMapOut.pm %ZR_PUBLIC_SCRIPT%
:__ins5
if not exist ZRJCode.pm goto __ins6
copy /Y ZRJCode.pm %ZR_PUBLIC_SCRIPT%
:__ins6
if not exist ZRShadowMap.pm goto __ins7
copy /Y ZRShadowMap.pm %ZR_PUBLIC_SCRIPT%
:__ins7
if not exist ZRWidthUcs.pm goto __ins8
copy /Y ZRWidthUcs.pm %ZR_PUBLIC_SCRIPT%
:__ins8
if not exist %ZR_PUBLIC_SCRIPT%\ZRToCid\nul mkdir %ZR_PUBLIC_SCRIPT%\ZRToCid
if not exist %ZR_PUBLIC_SCRIPT%\ZRToCid\nul goto __ins9
if not exist ZRToCid\nul goto __ins9
if not exist ZRToCid.pm goto __ins9
move /Y ZRToCid\* %ZR_PUBLIC_SCRIPT%\ZRToCid
move /Y ZRToCid.pm %ZR_PUBLIC_SCRIPT%
rmdir ZRToCid
:__ins9
if not exist ZRGTCode.pm goto __ins10
copy /Y ZRGTCode.pm %ZR_PUBLIC_SCRIPT%
:__ins10
exit /b

:exit
