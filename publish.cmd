@ECHO OFF
SETLOCAL

REM
REM Enable windows installer logging
REM    msiexec /i "C:\temp\installer.msi" /L*V "C:\temp\file.log"

REM  ***
ECHO *** ENVIRONMENT CHECK ***
REM  ***
wmic product get name | findstr /c:"WiX Toolset v3.11" > NUL
IF %ERRORLEVEL% NEQ 0 (
  ECHO Wix Toolset build tools not installed - download from https://wixtoolset.org/
  GOTO :error
)

SET arch=x64
SET configuration=Release
SET verbosity=Minimal & :: Minimal,Normal,Diagnostic,Detailed
SET wixheat="%ProgramFiles(x86)%\WiX Toolset v3.11\bin\heat.exe"
SET wixlight="%ProgramFiles(x86)%\WiX Toolset v3.11\bin\light.exe"
SET wixcandle="%ProgramFiles(x86)%\WiX Toolset v3.11\bin\candle.exe"
SET msbuild="%WINDIR%\Microsoft.NET\Framework\v4.0.30319\MSBuild.exe"

REM  ***
ECHO *** BRAVO BUILD ***
REM  ***
SET runtime=win-%arch%
SET framework=net5-windows10.0.17763.0
SET publishfolder=%~dp0src\bin\%configuration%\%framework%\%runtime%\publish
CD /d "%~dp0src"
IF EXIST %publishfolder% RMDIR /s /q %publishfolder%
dotnet publish Bravo.csproj --configuration %configuration% --output %publishfolder% --self-contained true --verbosity %verbosity% --force --nologo || GOTO :error

REM  ***
ECHO *** BRAVO INSTALLER ***
REM  ***
CD /d "%~dp0installer\wix\src\Bravo"
IF EXIST *.msi    DEL *.msi
IF EXIST *.wixobj DEL *.wixobj
IF EXIST *.wixpdb DEL *.wixpdb
%wixheat% dir "%publishfolder%" -gg -scom -srd -sreg -sfrag -templatefragment -cg ComponentsAutogenerated -dr INSTALLFOLDER -var var.PublishFolder -t Bravo.xslt -out Components.wxs -nologo || GOTO :error
%wixcandle% Components.wxs -dPublishFolder="%publishfolder%" -arch "%arch%" -nologo || GOTO :error
%wixcandle% Bravo.wxs -arch "%arch%" -dPublishFolder="%publishfolder%" -nologo || GOTO :error
REM light -sice:ICE60 is used to ignore -> warning LGHT1076 : ICE60: The file filE8E88FBC49DC5621FF3FC1B65ADCCB39 is not a Font, and its version is not a companion file reference. It should have a language specified in the Language column.
REM light -sice:ICE61 is used to ignore -> warning LGHT1076 : ICE61: This product should remove only older versions of itself. The Maximum version is not less than the current product.
REM light -sice:ICE80 is used to ignore -> error LGHT0204 : ICE80: This 64BitComponent pbitool.json uses 32BitDirectory POWERBIEXTERNALTOOLSFOLDER
%wixlight% Bravo.wixobj Components.wixobj -ext WixUIExtension.dll -ext WixUtilExtension.dll -cultures:en-us -loc Bravo-en-us.wxl -out "Bravo-%arch%-en-us.msi" -sice:ICE60 -sice:ICE61 -sice:ICE80 -nologo || GOTO :error

REM  ***
ECHO *** STORELAUNCHER BUILD ***
REM  ***
SET publishfolder=%~dp0installer\msix\Bravo.Installer.Msix.StoreLauncher\bin\%configuration%
CD /d "%~dp0installer\msix\Bravo.Installer.Msix.StoreLauncher"
%msbuild% /target:Clean;Rebuild /property:Configuration=%configuration% /verbosity:%verbosity% /toolsversion:4.0 /nologo Bravo.Installer.Msix.StoreLauncher.csproj || GOTO :error

REM  ***
ECHO *** STORELAUNCHER INSTALLER ***
REM  ***
CD /d "%~dp0installer\wix\src\BravoStoreLauncher"
IF EXIST *.msi    DEL *.msi
IF EXIST *.wixobj DEL *.wixobj
IF EXIST *.wixpdb DEL *.wixpdb
%wixcandle% BravoStoreLauncher.wxs -arch "%arch%" -dPublishFolder="%publishfolder%" -nologo || GOTO :error
REM light -sice:ICE61 is used to ignore -> warning LGHT1076 : ICE61: This product should remove only older versions of itself. The Maximum version is not less than the current product.
REM light -sice:ICE80 is used to ignore -> error LGHT0204 : ICE80: This 64BitComponent pbitool.json uses 32BitDirectory POWERBIEXTERNALTOOLSFOLDER
%wixlight% BravoStoreLauncher.wixobj -ext WixUIExtension.dll -cultures:en-us -loc BravoStoreLauncher-en-us.wxl -out "BravoStoreLauncher-%arch%-en-us.msi" -sice:ICE61 -sice:ICE80 -nologo || GOTO :error

REM ***
REM *** EXIT
REM ***
ECHO *** COMPLETED ***
GOTO :EOF
:error
%WINDIR%\System32\WindowsPowerShell\v1.0\Powershell.exe Write-Host -ForegroundColor Red ERROR
EXIT /b %ERRORLEVEL%
