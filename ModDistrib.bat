@echo off
:: GotAdmin
::-------------------------------------
REM  --> Check for permissions
>nul 2>&1 "%SYSTEMROOT%\system32\cacls.exe" "%SYSTEMROOT%\system32\config\system"

REM --> If error flag set, we do not have admin.
if '%errorlevel%' NEQ '0' (
    echo Requesting administrative privileges...
    goto UACPrompt
) else ( goto gotAdmin )

:UACPrompt
    echo Set UAC = CreateObject^("Shell.Application"^) > "%temp%\getadmin.vbs"
    set params = %*:"="
    echo UAC.ShellExecute "cmd.exe", "/c %~s0 %params%", "", "runas", 1 >> "%temp%\getadmin.vbs"

    "%temp%\getadmin.vbs"
    del "%temp%\getadmin.vbs"
    exit /B

:gotAdmin
    pushd "%CD%"
    CD /D "%~dp0"
::--------------------------------------

:: CODE ADMIN:
title  Core_distribution_modifier
@echo off
:code
powershell Write-Host "ModDistrib" -Foregroundcolor White -BackgroundColor Blue -NoNewline 
powershell Write-Host "-extract'('w/o import')'/replace kernel32.dll',' WimVers.reg in Win10/11 ISO',' unpack" -Foregroundcolor yellow -BackgroundColor darkBlue
powershell Write-Host "-Ё§ў«ҐзҐ­ЁҐ'('ЎҐ§ Ё¬Ї®ав ')'/Ї®¤¬Ґ­  kernel32.dll',' WimVers.reg ў Win10/11 ISO Ё«Ё а бЇ Є®ўЄҐ" -Foregroundcolor yellow -BackgroundColor darkBlue

for /F %%I in ('powershell -Command "(Get-WindowsImage -Mounted).MountPath"') do set mountDir=%%I
if defined mountDir (
    Powershell Get-WindowsImage -Mounted
    powershell write-host -fore cyan "Unmount ImagePath in Path" -NoNewline & echo  : %mountDir%
    pause
    dism /unmount-wim /mountdir:"%mountDir%" /discard
    If exist "%mountDir%" RMDIR /S /Q "%mountDir%"
    set mountDir=
    cls
goto code
)
dism /cleanup-wim > nul
powershell write-host -fore darkyellow "IF NOT select ISO', 'you can Enter path of unpacked distrib"
:start
set isoPath=
for /f "delims=" %%i in ('powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'ISO file (*.iso)|*.iso|All Files (*.*)|*.*'; if($f.ShowDialog() -eq 'OK') { $f.FileName }"
') do set isoPath=%%i

if "%isoPath%"=="" powershell write-host -fore darkyellow NOT Selected ISO & goto def
goto isp
:def
echo ---------------Path to distrib-----------------------
set Fullpath=
set /p Fullpath="Enter Full path distrib(bef.\sources) : "
if "%Fullpath%"=="" powershell write-host -fore darkyellow Path is Empty & pause & goto start
for /F %%I in ('powershell -Command "(Test-Path -Path '%Fullpath%')"') do set TPath=%%I
If %TPath%==False powershell write-host -fore darkyellow 'Path is Invalid"," Pls to correct "&" enter again.' & powershell write-host -fore darkgray 'Prefer Short Paths without Spaces or invalid characters.' & goto def
goto fold
:isp
echo ---------------ISO Init-----------------------

echo Choosed "%isoPath%"
set isoDrive=
for /f "tokens=1,2 delims=," %%A in ('powershell -NoProfile -Command "Get-DiskImage -ImagePath '%isoPath%' | Get-Volume | Select-Object -ExpandProperty DriveLetter"') do set "isoDrive=%%A"
if defined isoDrive (
powershell -Command "Dismount-DiskImage -ImagePath '%isoPath%'" > nul
powershell write-host -fore cyan Iso at drive %isoDrive%: was unmount.
)
powershell write-host -fore darkyellow 'Check/Unpack ' -NoNewline & pause

for %%A in ("%isoPath%") do set "drive=%%~dA\"
If not exist "%drive%ModDistrib" mkdir "%drive%ModDistrib"
set out=%drive%ModDistrib\
for %%i in ("%isoPath%") do set "isoName=%%~ni"
powershell write-host -fore yellow iso unpack Dir : %out%
set Fullpath=%out%%isoName%
If exist "%out%%isoName%" (
echo Folder '%isoName%' already exist.
goto fold
 )

for /f %%L in ('powershell -Command "$free = ([char[]](67..90) | ? { -not (Get-PSDrive $_ -ErrorAction SilentlyContinue) })[0]; echo $free"') do set newLetter=%%L:

reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" /v "DisableAutoplay" /t REG_DWORD /d 1 /f > nul
powershell -Command "$mount = Mount-DiskImage -ImagePath '%isoPath%' -NoDriveLetter -PassThru; $volId = ($mount | Get-Volume).UniqueId; mountvol %newLetter% $volId"
powershell write-host -fore darkgray Unpacking Iso to %out%%isoName%...
If not exist "%out%%isoName%" mkdir "%out%%isoName%"
robocopy %newLetter%\ "%out%%isoName%" /E /A-:SH > nul
reg add "HKCU\Software\Microsoft\Windows\CurrentVersion\Explorer\AutoplayHandlers" /v "DisableAutoplay" /t REG_DWORD /d 0 /f > nul
powershell Dismount-DiskImage -ImagePath '%isoPath%' > nul
:fold
echo.--------------------Folders init--------------------------
if not exist "%Fullpath%\sources\install.*" powershell write-host -fore darkyellow  Entered Dir not contain 'install.wim' Pls, choose again & goto def
powershell write-host -fore yellow InPath : %Fullpath%
attrib -r "%Fullpath%\*.*" /s /d
for %%I in ("%Fullpath%\.") do set "isoName=%%~nxI"
for %%i in ("%Fullpath%.") do set "out=%%~dpi"
powershell write-host -fore yellow OutDir : %out%
if exist "%Fullpath%\sources\install.wim" goto inf
:esd
if not exist "%Fullpath%\sources\install.esd" powershell write-host -fore yellow Dir %Fullpath%\sources not contain install.esd & goto sel
echo.--------------------ESD Info------------------------------
if exist "%Fullpath%\sources\install.esd" dism /get-wiminfo /wimfile:"%Fullpath%\sources\install.esd" & echo 'install.esd' will convert to 'install.wim'

:esdc
SET choice=
SET /p "choice=Enter(cont.)/M(Menu): "
IF /i '%choice%'=='M' goto sel
IF /i '%choice%'=='' goto esw
goto esdc

:esw
echo ----------Export ESD index to WIM image-------------
echo Enter indexes separated by spaces,like(5, 1, 2) : 
set /p rein=
if "%rein%"=="" powershell write-host -fore darkyellow NOT Enter Value & goto esw
powershell write-host -fore darkgray Sorting...
for /f "delims=" %%i in ('powershell -Command "('%rein%,' -split ' ' | Sort { [int]$_ }) -join ' '"') do set sein=%%i
powershell write-host -fore yellow Selected ESD to Wim Index: '%sein%'
powershell write-host -fore cyan Will open minimized PS window '''keep AWAKE''' to prevent Sleep.
pause
start /min powershell -WindowStyle Minimized -Command "$Host.UI.RawUI.WindowTitle = 'Keep AWAKE'; $w = New-Object -ComObject WScript.Shell; while($true) { $w.SendKeys('{SCROLLLOCK}'); Start-Sleep -Seconds 60 }"pause

set i=0
for %%a in (%sein%) do (
    set /a i+=1
DISM /Export-Image /SourceImageFile:"%Fullpath%\sources\install.esd" /SourceIndex:%%a /DestinationImageFile:"%Fullpath%\sources\install.wim" /Compress:fast
powershell write-host -fore darkyellow ESD Index:%%a was converted
 )
echo.
taskkill /IM powershell.exe /F > nul
powershell write-host -fore cyan PS window '''keep AWAKE''' was closed.
powershell write-host -fore yellow ESD to WIM of Index:%sein% was converted ! & goto inf
:con
echo ----------Convert Wim index to ESD image-------------
echo Enter indexes separated by spaces,like(5, 1, 2) : 
set /p rein=
if "%rein%"=="" powershell write-host -fore darkyellow NOT Enter Value & goto con
powershell write-host -fore darkgray Sorting...
for /f "delims=" %%i in ('powershell -Command "('%rein%,' -split ' ' | Sort { [int]$_ }) -join ' '"') do set sein=%%i
powershell write-host -fore yellow Selected WIM to ESD Index: '%sein%'
powershell write-host "Note:This process will require significant resources and time !" -Foregroundcolor Darkred -BackgroundColor yellow
powershell write-host -fore cyan Will open minimized PS window '''keep AWAKE''' to prevent Sleep.
powershell write-host -fore darkgray '(old install.esd will be install.esd.back)'
pause
start /min powershell -WindowStyle Minimized -Command "$Host.UI.RawUI.WindowTitle = 'Keep AWAKE'; $w = New-Object -ComObject WScript.Shell; while($true) { $w.SendKeys('{SCROLLLOCK}'); Start-Sleep -Seconds 60 }"pause
if exist "%Fullpath%\sources\install.esd" move "%Fullpath%\sources\install.esd" "%Fullpath%\sources\install.esd.back"
set i=0
for %%a in (%sein%) do (
    set /a i+=1
dism /Export-Image /SourceImageFile:"%Fullpath%\sources\install.wim" /SourceIndex:%%a /DestinationImageFile:"%Fullpath%\sources\install.esd" /compress:recovery
powershell write-host -fore darkyellow WIM Index:%%a was converted
 )
echo.
taskkill /IM powershell.exe /F > nul
powershell write-host -fore cyan PS window '''keep AWAKE''' was closed.
powershell write-host -fore yellow WIM to ESD  of Index:%sein% was converted ! & goto inf

:inf
if exist "%Fullpath%\sources\install.esd" echo --------------------ESD Info------------------------------ & dism /get-wiminfo /wimfile:"%Fullpath%\sources\install.esd"
echo.--------------------Wim Info------------------------------
dism /get-wiminfo /wimfile:"%Fullpath%\sources\install.wim"
:sel
echo.--------------------Menu------------------------------
powershell write-host -fore darkgray 'Mount Distr(M) for Extract "&" Replace components'
@echo Mount Distr(M),Exp/Imp/Boot Distr(E),Remove index Distr(R),Export ESD to WIM(S),Install Bypass(P)
@echo Convert Wim to ESD(C), Details info Distr(I), Make Boot Iso(N), Add-PackageUpdate(U), To Start(B)?
SET choice=
SET /p choice=Pls, enter M/E/R/S/P/C/I/N/U/B: 
IF NOT '%choice%'=='' SET choice=%choice:~0,1%
IF /i '%choice%'=='M' goto ext
IF /i '%choice%'=='E' goto por
IF /i '%choice%'=='R' goto del
IF /i '%choice%'=='S' goto esd
IF /i '%choice%'=='C' goto con
IF /i '%choice%'=='I' goto det
IF /i '%choice%'=='N' goto iso
IF /i '%choice%'=='U' goto adpk
IF /i '%choice%'=='P' goto bpres
IF /i '%choice%'=='B' goto start
goto sel

:iso
echo.--------------------Make Iso Distr------------------------------
if not exist "%~dp0Oscdimg.exe" (
powershell write-host -fore darkyellow Missed Oscdimg. To download & pause
powershell -command "Start-BitsTransfer -Source 'https://msdl.microsoft.com/download/symbols/oscdimg.exe/688CABB065000/oscdimg.exe' -Destination '%~dp0'"
if exist "%~dp0Oscdimg.exe" powershell write-host -fore darkyellow Now exist Oscdimg. To build Iso & pause
 )
set is=
if exist "%out%%isoName%.iso" set is=_New
powershell write-host -fore darkgray %isoName%%is%.iso is building...
Oscdimg -bootdata:2#p0,e,b"%Fullpath%"\boot\etfsboot.com#pEF,e,b"%Fullpath%"\efi\microsoft\boot\efisys.bin -o -h -m -u2 -udfver102 "%Fullpath%" %out%%isoName%%is%.iso
powershell write-host -fore yellow Succefully maked %out%%isoName%%is%.iso & pause
goto sel

:det
echo.--------------------Wim Details Info------------------------------
set ind=
set /p "ind=Enter index: "
if "%ind%"=="" echo Not Entered Value & pause & goto det
if %ind% equ +%ind% (
set ind=%ind%
) else (
echo %ind% is NOT a digit.
    goto det
)
dism /get-wiminfo /wimfile:"%Fullpath%\sources\install.wim" /Index:%ind%
goto sel
:del
echo ----------Remove image of index-------------
echo Enter indexes separated by spaces,like(5, 1, 2) : 
set /p rein=
if "%rein%"=="" powershell write-host -fore darkyellow NOT Enter Value & goto del
powershell write-host -fore darkgray Sorting...
for /f "delims=" %%i in ('powershell -Command "('%rein%,' -split ' ' | Sort { [int]$_ }) -join ' '"') do set sein=%%i
powershell write-host -fore yellow Selected WIM index to remove: '%sein%'
for /f "delims=" %%i in ('powershell -Command "('%rein%,' -split ' ' | Sort-Object -Descending { [int]$_ }) -join ' '"') do set ein=%%i
pause
set i=0
for %%a in (%ein%) do (
    set /a i+=1
dism /Delete-Image /ImageFile:"%Fullpath%\sources\install.wim" /Index:%%a
powershell write-host -fore darkyellow Index:%%a was removed
 )
echo.
powershell write-host -fore yellow WIM Index:%sein% of image was removed !
goto inf
:por
echo ----------Export/Import/Boot image of index-------------
powershell write-host -fore darkgray 'Details info: import Wim (I), import Boot (B), Delete Boot Distr(D)' 
@echo Export Wim of Distr(E), Import Wim to Distr(I), Import Boot to Distr(B),
@echo Delete Boot of Distr(D), Back to Menu(M)?
SET choice=
SET /p choice=Pls, enter E/I/B/D/M: 
IF NOT '%choice%'=='' SET choice=%choice:~0,1%
IF /i '%choice%'=='E' goto dex
IF /i '%choice%'=='I' goto imp
IF /i '%choice%'=='B' goto ibp
IF /i '%choice%'=='D' goto ibd
IF /i '%choice%'=='M' goto inf
goto por

:ibd
dism /get-wiminfo /wimfile:"%Fullpath%\sources\boot.wim"
:dlx
set ind=
set /p "ind=Enter index: "
if "%ind%"=="" echo Not Entered Value & pause & goto dlx
if %ind% equ +%ind% (
set ind=%ind%
) else (
echo %ind% is NOT a digit.
    goto dlx
)
dism /get-wiminfo /wimfile:"%Fullpath%\sources\boot.wim" /Index:%ind%
:bdch
SET choice=
SET /p "choice=Enter(cont.)/B(back): "
IF /i '%choice%'=='B' goto por
IF /i '%choice%'=='' goto bdi
goto bdch
:bdi
powershell write-host -fore yellow Choosed delete index: %ind%
pause
dism /Delete-Image /ImageFile:"%Fullpath%\sources\boot.wim" /Index:%ind%
dism /get-wiminfo /wimfile:"%Fullpath%\sources\boot.wim"
goto por

:dex
set ind=
set /p "ind=Enter index: "
if "%ind%"=="" echo Not Entered Value & pause & goto dex
if %ind% equ +%ind% (
set ind=%ind%
) else (
echo %ind% is NOT a digit.
    goto dex
)
powershell write-host -fore yellow Choosed export index: %ind%
dism /get-wiminfo /wimfile:"%Fullpath%\sources\install.wim" /Index:%ind%
for /f "delims=" %%i in ('powershell -command "(Get-WindowsImage -ImagePath '%Fullpath%\sources\install.wim' -Index %ind%).ImageName"') do set nameExp=%%i
set destExp=/DestinationName:"%nameExp%"
powershell write-host -fore yellow Cont. will: install_%nameExp%_%ind%.wim
:ewch
SET choice=
SET /p "choice=Enter(cont.)/R(replace): "
IF /i '%choice%'=='R' goto ewr
IF /i '%choice%'=='' goto ewn
goto ewch
:ewn
if exist "%out%install_%nameExp%_%ind%.wim" DEL /S /Q "%out%install_%nameExp%_%ind%.wim" > nul
Dism /Export-Image /SourceImageFile:"%Fullpath%\sources\install.wim" /SourceIndex:%ind% /DestinationImageFile:"%out%install_%nameExp%_%ind%.wim" %destExp%
dism /get-wiminfo /wimfile:"%out%install_%nameExp%_%ind%.wim"
goto por
:ewr
if exist "%out%install_%nameExp%_%ind%.wim" DEL /S /Q "%out%install_%nameExp%_%ind%.wim" > nul
Dism /Export-Image /SourceImageFile:"%Fullpath%\sources\install.wim" /SourceIndex:%ind% /DestinationImageFile:"%out%install_%nameExp%_%ind%.wim" %destExp%
move "%out%install_%nameExp%_%ind%.wim" "%Fullpath%\sources\install.wim"
dism /get-wiminfo /wimfile:"%Fullpath%\sources\install.wim"
goto por

:ibp
echo.
powershell write-host -fore darkyellow Boot Wim of Distr:
dism /get-wiminfo /wimfile:"%Fullpath%\sources\boot.wim"
set wnm=
for /f "delims=" %%i in ('powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'Boot Wim (*.wim)|*.wim|All Files (*.*)|*.*'; if($f.ShowDialog() -eq 'OK') { $f.FileName }"
') do set wnm=%%i
IF NOT DEFINED wnm (
    ECHO NOT Choiced Wim to import & goto por
) ELSE (
powershell write-host -fore yellow Choosed Wim: "%wnm%"
dism /get-wiminfo /wimfile:"%wnm%"
)
:ieb
set ind=
set /p "ind=Enter index: "
if "%ind%"=="" echo Not Entered Value & pause & goto ieb
if %ind% equ +%ind% (
set ind=%ind%
) else (
echo %ind% is NOT a digit.
    goto ieb
)
powershell write-host -fore yellow Choosed import index: %ind%
dism /get-wiminfo /wimfile:"%wnm%" /Index:%ind%
:iwch
SET choice=
SET /p "choice=Enter(cont.)/B(back): "
IF /i '%choice%'=='B' goto por
IF /i '%choice%'=='' goto iwd
goto iwch
:iwd
powershell write-host -fore yellow To import Details Boot image index %ind% into Wim Boot Distr:
pause
Dism /Export-Image /SourceImageFile:"%wnm%" /SourceIndex:%ind% /DestinationImageFile:"%Fullpath%\sources\boot.wim"
dism /get-wiminfo /wimfile:"%Fullpath%\sources\boot.wim"
pause
goto por

:imp
echo.
powershell write-host -fore darkyellow Install Wim of Distr:
dism /get-wiminfo /wimfile:"%Fullpath%\sources\install.wim"
set wnm=
for /f "delims=" %%i in ('powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'Install Wim (*.wim)|*.wim|All Files (*.*)|*.*'; if($f.ShowDialog() -eq 'OK') { $f.FileName }"
') do set wnm=%%i
IF NOT DEFINED wnm (
    ECHO NOT Choiced Wim to import & goto por
) ELSE (
powershell write-host -fore yellow Choosed Wim: %wnm%
dism /get-wiminfo /wimfile:"%wnm%"
)
:iex
set ind=
set /p "ind=Enter index: "
if "%ind%"=="" echo Not Entered Value & pause & goto iex
if %ind% equ +%ind% (
set ind=%ind%
) else (
echo %ind% is NOT a digit.
    goto iex
)
powershell write-host -fore yellow Choosed import index: %ind%
dism /get-wiminfo /wimfile:"%wnm%" /Index:%ind%
:imch
SET choice=
SET /p "choice=Enter(cont.)/B(back): "
IF /i '%choice%'=='B' goto por
IF /i '%choice%'=='' goto imd
goto imch
:imd
powershell write-host -fore yellow To import Details image index %ind% into Install Wim Distr:
pause
Dism /Export-Image /SourceImageFile:"%wnm%" /SourceIndex:%ind% /DestinationImageFile:"%Fullpath%\sources\install.wim"
dism /get-wiminfo /wimfile:"%Fullpath%\sources\install.wim"
pause
goto por


:ext
echo ----------Mount image of index-------------
:mdex
set ind=
set /p "ind=Enter index: "
if "%ind%"=="" echo Not Entered Value & pause & goto mdex
if %ind% equ +%ind% (
set ind=%ind%
) else (
echo %ind% is NOT a digit.
    goto mdex
)
If not exist "%out%AIKMount" mkdir "%out%AIKMount"
dism /mount-wim /wimfile:"%Fullpath%\sources\install.wim" /index:%ind% /mountdir:"%out%AIKMount"
powershell write-host -fore cyan Install.wim was mounted in %out%AIKMount '!'
xcopy /S /-I /Q /Y "%out%AIKMount\windows\system32\kernel32.dll" "%out%"
for /F %%I in ('powershell -Command "(Get-Item -LiteralPath '%out%kernel32.dll').VersionInfo.FileVersion"') do set kever=%%I
If not exist "%out%Build%kever%_ind_%ind%" mkdir "%out%Build%kever%_ind_%ind%"
if exist "%out%kernel32.dll" move "%out%kernel32.dll" "%out%Build%kever%_ind_%ind%\kernel32.dll"
powershell write-host -fore yellow 'kernel32.dll' was extracted !
set kern=
echo ----------Import Kernel32-------------
powershell write-host -fore darkyellow "IF NOT select File', 'will be only extract"
for /f "delims=" %%i in ('powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'kernel32 (*.dll)|*.dll|All Files (*.*)|*.*'; if($f.ShowDialog() -eq 'OK') { $f.FileName }"
') do set kern=%%i
IF NOT DEFINED kern (
    ECHO NOT Choiced Kernel32.dll to import
) ELSE (
echo Choiced Kernel32.dll will replace
takeown /f "%out%AIKMount\windows\system32\LogFiles\WMI\RtBackup" > nul & icacls "%out%AIKMount\windows\system32\LogFiles\WMI\RtBackup" /grant Administrators:rx > nul
if exist "%out%AIKMount\windows\system32\WebThreatDefSvc" takeown /f "%out%AIKMount\windows\system32\WebThreatDefSvc" > nul & icacls "%out%AIKMount\windows\system32\WebThreatDefSvc" /grant Administrators:rx > nul
takeown /f "%out%AIKMount\windows\system32\kernel32.dll" > nul & icacls "%out%AIKMount\windows\system32\kernel32.dll" /grant Administrators:F /t > nul
move "%out%AIKMount\windows\system32\kernel32.dll" "%out%AIKMount\windows\system32\kernel32.dll.ax"
xcopy /S /-I /Q /Y "%kern%" "%out%AIKMount\windows\system32"
powershell write-host -fore yellow Choiced Kernel32.dll was replaced Successfully
)
takeown /f "%out%AIKMount\windows\system32\config\software" > nul & icacls "%out%AIKMount\windows\system32\config\software" /grant Administrators:F /t > nul
reg load HKLM\WimRegistry "%out%AIKMount\windows\system32\config\software"
powershell write-host -fore darkgray .....................................
Echo Registry was loaded WimRegistry !
if exist "%out%WimVer.reg" DEL /S /Q "%out%WimVer.reg" > nul
echo Windows Registry Editor Version 5.00>> "%out%WimVer.reg"
echo.>> "%out%WimVer.reg"
echo [HKEY_LOCAL_MACHINE\WimRegistry\Microsoft\Windows NT\CurrentVersion]>> "%out%WimVer.reg"
setlocal ENABLEEXTENSIONS
set KEY_NAME=HKEY_LOCAL_MACHINE\WimRegistry\Microsoft\Windows NT\CurrentVersion
set VALUE_NAME=CurrentBuild
for /F "usebackq tokens=1,2,*" %%A IN (`reg query "%KEY_NAME%" /v "%VALUE_NAME%" 2^>nul ^| find "%VALUE_NAME%"`) do (
  echo "CurrentBuild"="%%C">> "%out%WimVer.reg"
  set Build="%%C"
)
set VALUE_NAME=ReleaseId
for /F "usebackq tokens=1,2,*" %%A IN (`reg query "%KEY_NAME%" /v "%VALUE_NAME%" 2^>nul ^| find "%VALUE_NAME%"`) do (
  echo "ReleaseId"="%%C">> "%out%WimVer.reg"
)
set VALUE_NAME=UBR
for /F "usebackq tokens=1,2,*" %%A IN (`reg query "%KEY_NAME%" /v "%VALUE_NAME%" 2^>nul ^| find "%VALUE_NAME%"`) do (
  echo "UBR"=dword:%%C>> "%out%WimVer.reg"
)
set VALUE_NAME=BuildLabEx
for /F "usebackq tokens=1,2,*" %%A IN (`reg query "%KEY_NAME%" /v "%VALUE_NAME%" 2^>nul ^| find "%VALUE_NAME%"`) do (
  echo "BuildLabEx"="%%C">> "%out%WimVer.reg"
)
set VALUE_NAME=BuildLab
for /F "usebackq tokens=1,2,*" %%A IN (`reg query "%KEY_NAME%" /v "%VALUE_NAME%" 2^>nul ^| find "%VALUE_NAME%"`) do (
  echo "BuildLab"="%%C">> "%out%WimVer.reg"
)

powershell -Command "(gc '%out%WimVer.reg') -replace 'WimRegistry', 'SOFTWARE' | Out-File -encoding Unicode '%out%Build%kever%_ind_%ind%\WimExp%Build%.reg'
DEL /S /Q "%out%WimVer.reg" > nul
powershell write-host -fore yellow 'WimExp%Build%.reg' was extracted !
set wrg=
echo ----------Import reg-------------
powershell write-host -fore darkyellow "IF NOT select File', 'will be only extract"
for /f "delims=" %%i in ('powershell -NoProfile -Command "Add-Type -AssemblyName System.Windows.Forms; $f = New-Object System.Windows.Forms.OpenFileDialog; $f.Filter = 'Wim (*.reg)|*.reg|All Files (*.*)|*.*'; if($f.ShowDialog() -eq 'OK') { $f.FileName }"
') do set wrg=%%i
IF NOT DEFINED wrg (
    ECHO NOT Choiced Reg to import.
reg unload HKLM\WimRegistry
dism /unmount-wim /mountdir:"%out%AIKMount" /discard
) ELSE (
echo Choiced Reg file will replace
powershell -Command "(gc '%wrg%') -replace 'SOFTWARE', 'WimRegistry' | Out-File -encoding Unicode '%out%Build%kever%_ind_%ind%\WimImp.reg'
reg import "%out%Build%kever%_ind_%ind%\WimImp.reg"
powershell write-host -fore yellow Choiced Reg file was replaced Successfully
DEL /S /Q "%out%Build%kever%_ind_%ind%\WimImp.reg" > nul
reg unload HKLM\WimRegistry
dism /unmount-wim /mountdir:"%out%AIKMount" /commit
)

If exist "%out%AIKMount" RMDIR /S /Q "%out%AIKMount"
powershell write-host -fore cyan Install.wim was unmounted '!'
powershell write-host -fore green Close or Edit *supported* WIM','after this',' it can be restored:  
echo (After restoring, recommended to export for reduce)
pause
goto inf
:adpk
echo ----------Add-Package to image-------------
:pdex
set ind=
set /p "ind=Enter index: "
if "%ind%"=="" echo Not Entered Value & pause & goto pdex
if %ind% equ +%ind% (
set ind=%ind%
) else (
echo %ind% is NOT a digit.
    goto pdex
)
If not exist "%out%AIKMount" mkdir "%out%AIKMount"
dism /mount-wim /wimfile:"%Fullpath%\sources\install.wim" /index:%ind% /mountdir:"%out%AIKMount"
powershell write-host -fore cyan Install.wim was mounted in %out%AIKMount '!'
:lmsu
SET choice=
SET /p "choice=Enter(cont.)/L(List Updates): "
IF /i '%choice%'=='L' goto list
IF /i '%choice%'=='' goto msu
goto lmsu
:list
powershell write-host -fore darkgray Pls, wait for listing...
Dism /Get-Packages /Image:"%out%AIKMount" /Format:Table
pause
:msu
powershell write-host -fore darkyellow "IF NOT select DirPackages'('msu','cab'),' image will Unmout."
set msu=
set "psCommand="(new-object -com shell.application).browseforfolder(0,'Select File',0,17).self.path""
for /f "usebackq delims=" %%I in (`powershell %psCommand%`) do set "msu=%%I"
IF NOT DEFINED msu (
echo NOT Choiced UpdatePackage to import
:dmsu
dism /unmount-wim /mountdir:"%out%AIKMount" /discard
goto ufin
)
echo You selected: %msu%
setlocal enabledelayedexpansion
echo Adding updates from "%msu%" to mounted image "%out%AIKMount"
powershell write-host -fore yellow Choiced Packages in %msu% to import',' Pls wait...

powershell -NoLogo -NoProfile ^
  "$acl = New-Object System.Security.AccessControl.DirectorySecurity;" ^
  "$acl.AddAccessRule((New-Object System.Security.AccessControl.FileSystemAccessRule('Administrators','FullControl','ContainerInherit,ObjectInherit','None','Allow')));" ^
  "Set-Acl '%out%AIKMount' $acl"

:: Loop through all .cab and .msu files
for %%U in ("%msu%\*.cab" "%msu%\*.msu") do (
    if exist "%%~U" (
        echo Adding update: %%~nxU
        echo [INFO] Adding %%~nxU

        dism /image:"%out%AIKMount" /add-package /packagepath:"%%~U"
        if errorlevel 1 (
            echo [ERROR] Failed to add %%~nxU
        ) else (
            echo [OK] Added %%~nxU
        )
        echo.
    )
)
powershell write-host -fore yellow All updates in %msu% processed.
endlocal
:cmsu
SET choice=
SET /p "choice=S(Save), L(List Updates), D(Discard Updates) : "
IF /i '%choice%'=='L' goto ulist
IF /i '%choice%'=='S' goto smsu
IF /i '%choice%'=='D' goto dmsu
goto cmsu
:ulist
powershell write-host -fore darkgray Pls, wait for listing...
Dism /Get-Packages /Image:"%out%AIKMount" /Format:Table
pause
goto cmsu
:smsu
    dism /unmount-wim /mountdir:"%out%AIKMount" /commit
:ufin
If exist "%out%AIKMount" RMDIR /S /Q "%out%AIKMount"
powershell write-host -fore cyan Install.wim was unmounted '!'
pause
goto inf

:bpres
echo ----------Bypass-install restrictions-------------
:bdex
set ind=
set /p "ind=Enter index: "
if "%ind%"=="" echo Not Entered Value & pause & goto bdex
if %ind% equ +%ind% (
set ind=%ind%
) else (
echo %ind% is NOT a digit.
    goto bdex
)
If not exist "%out%AIKMount" mkdir "%out%AIKMount"
dism /mount-wim /wimfile:"%Fullpath%\sources\install.wim" /index:%ind% /mountdir:"%out%AIKMount"
powershell write-host -fore cyan Install.wim was mounted in %out%AIKMount '!'

takeown /f "%out%AIKMount\windows\system32\LogFiles\WMI\RtBackup" > nul & icacls "%out%AIKMount\windows\system32\LogFiles\WMI\RtBackup" /grant Administrators:rx > nul
if exist "%out%AIKMount\windows\system32\WebThreatDefSvc" takeown /f "%out%AIKMount\windows\system32\WebThreatDefSvc" > nul & icacls "%out%AIKMount\windows\system32\WebThreatDefSvc" /grant Administrators:rx > nul
takeown /f "%out%AIKMount\windows\system32\config\SYSTEM" > nul & icacls "%out%AIKMount\windows\system32\config\SYSTEM" /grant Administrators:F /t > nul

reg load HKLM\WimRegistry "%out%AIKMount\windows\system32\config\system" && powershell write-host -fore darkgray Load WimRegistry
reg add "HKLM\WimRegistry\SYSTEM\Setup\LabConfig" /v BypassTPMCheck /t REG_DWORD /d 1 /f && powershell write-host -fore green BypassTPMCheck
reg add "HKLM\WimRegistry\SYSTEM\Setup\LabConfig" /v BypassSecureBootCheck /t REG_DWORD /d 1 /f && powershell write-host -fore green BypassSecureBootCheck
reg add "HKLM\WimRegistry\SYSTEM\Setup\LabConfig" /v BypassRAMCheck /t REG_DWORD /d 1 /f && powershell write-host -fore green BypassRAMCheck
reg add "HKLM\WimRegistry\SYSTEM\Setup\LabConfig" /v BypassCPUCheck /t REG_DWORD /d 1 /f && powershell write-host -fore green BypassCPUCheck
reg unload HKLM\WimRegistry && powershell write-host -fore darkgray Unload WimRegistry
powershell write-host -fore yellow Install restictions was bypassed.
dism /unmount-wim /mountdir:"%out%AIKMount" /commit
If exist "%out%AIKMount" RMDIR /S /Q "%out%AIKMount"
powershell write-host -fore cyan Install.wim was unmounted '!'
pause
goto inf
