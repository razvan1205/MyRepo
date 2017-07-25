@rem ---------------------------------------------------------------------------------
@rem Copyright 2008 Microsoft Corporation. All rights reserved.
@rem This is provided as sample to deploy the package using msdeploy.exe
@rem For information about IIS Web Deploy technology,
@rem please visit http://go.microsoft.com/?linkid=9278654
@rem Note: This batch file assumes the package and setparametsrs.xml are in the same folder with this file
@rem ---------------------------------------------------------------------------------
@rem Note: This file has been edited to remove some of the complexity and make it easier for others to understand.
@rem ---------------------------------------------------------------------------------
@if %_echo%!==! echo off
setlocal
@rem ---------------------------------------------------------------------------------
@rem Please Make sure you have Web Deploy install in your machine. 
@rem Alternatively, you can explicit set the MsDeployPath to the location it is on your machine
@rem set MSDeployPath="C:\Program Files (x86)\IIS\Microsoft Web Deploy V3\"
@rem ---------------------------------------------------------------------------------
                      
@rem ---------------------------------------------------------------------------------
@rem if user does not set MsDeployPath environment variable, we will try to retrieve it from registry.
@rem ---------------------------------------------------------------------------------
if "%MSDeployPath%" == "" (
for /F "usebackq tokens=1,2,*" %%h  in (`reg query "HKLM\SOFTWARE\Microsoft\IIS Extensions\MSDeploy" /s  ^| findstr -i "InstallPath"`) do (
if /I "%%h" == "InstallPath" ( 
if /I "%%i" == "REG_SZ" ( 
if not "%%j" == "" ( 
if "%%~dpj" == "%%j" ( 
set MSDeployPath=%%j
))))))

if not exist "%MSDeployPath%\msdeploy.exe" (
echo. msdeploy.exe is not found on this machine. Please install Web Deploy before execute the script. 
echo. Please visit http://go.microsoft.com/?linkid=9278654
goto :usage
)

set RootPath=%~dp0

set _ArgTestDeploy=
set _ArgDestinationType=auto
set _ArgComputerName=
set _ArgUserName=
set _ArgPassword=
set _ArgEncryptPassword=
set _ArgIncludeAcls=False
set _ArgAuthType=
set _ArgtempAgent=
set _ArgLocalIIS=
set _ArgLocalIISVersion=
set _MsDeployAdditionalFlags=
set _ArgMsDeployAdditionalFlags=
                      
@rem ---------------------------------------------------------------------------------
@rem Simple Parse the arguments
@rem ---------------------------------------------------------------------------------
:NextArgument
set _ArgCurrentOriginal=%1
set _ArgCurrent=%~1

if /I "%_ArgCurrent%" == "" goto :GetStarted
if /I "%_ArgCurrent%" == "/T" set _ArgTestDeploy=true&goto :ArgumentOK
if /I "%_ArgCurrent%" == "/Y" set _ArgTestDeploy=false&goto :ArgumentOK
if /I "%_ArgCurrent%" == "/L" set _ArgLocalIIS=true&goto :ArgumentOK

set _ArgFlag=%_ArgCurrent:~0,3%
set _ArgValue=%_ArgCurrent:~3%

if /I "%_ArgFlag%" == "/M:" set _ArgComputerName=%_ArgValue%&goto :ArgumentOK
if /I "%_ArgFlag%" == "/U:" set _ArgUserName=%_ArgValue%&goto :ArgumentOK
if /I "%_ArgFlag%" == "/P:" set _ArgPassword=%_ArgValue%&goto :ArgumentOK
if /I "%_ArgFlag%" == "/E:" set _ArgEncryptPassword=%_ArgValue%&goto :ArgumentOK
if /I "%_ArgFlag%" == "/I:" set _ArgIncludeAcls=%_ArgValue%&goto :ArgumentOK
if /I "%_ArgFlag%" == "/A:" set _ArgAuthType=%_ArgValue%&goto :ArgumentOK
if /I "%_ArgFlag%" == "/G:" set _ArgtempAgent=%_ArgValue%&goto :ArgumentOK

@rem Any addition flags, pass through to the msdeploy
set _ArgMsDeployAdditionalFlags=%_ArgMsDeployAdditionalFlags% %_ArgCurrentOriginal%

:ArgumentOK
shift
goto :NextArgument
set _ArgMsDeployAdditionalFlags=%_ArgMsDeployAdditionalFlags% -preSync:runCommand="preSync.changed.bat",waitInterval=1000 -postSync:runCommand="postSync.changed.bat",waitInterval=1000

:GetStarted
if /I "%_ArgTestDeploy%" == "" goto :usage
if /I "%_ArgDestinationType%" == ""  goto :usage

set _Destination=%_ArgDestinationType%
if not "%_ArgComputerName%" == "" set _Destination=%_Destination%,computerName='%_ArgComputerName%'
if not "%_ArgUserName%" == "" set _Destination=%_Destination%,userName='%_ArgUserName%'
if not "%_ArgPassword%" == "" set _Destination=%_Destination%,password='%_ArgPassword%'
if not "%_ArgAuthType%" == "" set _Destination=%_Destination%,authtype='%_ArgAuthType%'
if not "%_ArgEncryptPassword%" == "" set _Destination=%_Destination%,encryptPassword='%_ArgEncryptPassword%'
if not "%_ArgIncludeAcls%" == "" set _Destination=%_Destination%,includeAcls='%_ArgIncludeAcls%'
if not "%_ArgtempAgent%" == "" set _Destination=%_Destination%,tempAgent='%_ArgtempAgent%'

@rem ---------------------------------------------------------------------------------
@rem add -whatif when -T is specified                      
@rem ---------------------------------------------------------------------------------
if /I "%_ArgTestDeploy%" NEQ "false" (
set _MsDeployAdditionalFlags=%_MsDeployAdditionalFlags% -whatif
)

@rem ---------------------------------------------------------------------------------
@rem pass through the addition msdeploy.exe Flags
@rem ---------------------------------------------------------------------------------
set _MsDeployAdditionalFlags=%_MsDeployAdditionalFlags% %_ArgMsDeployAdditionalFlags%

@rem ---------------------------------------------------------------------------------
@rem check the existence of the package file
@rem ---------------------------------------------------------------------------------
if not exist "%RootPath%[WEBSITE_NAME].zip" (
echo "%RootPath%[WEBSITE_NAME].zip" does not exist. 
echo This batch file relies on this deploy source file^(s^) in the same folder.
goto :usage
)
                      
@rem ---------------------------------------------------------------------------------
@rem Execute msdeploy.exe command line
@rem ---------------------------------------------------------------------------------
call :CheckParameterFile
echo. Start executing msdeploy.exe
echo -------------------------------------------------------

echo. "%MSDeployPath%\msdeploy.exe" -source:package='%RootPath%[WEBSITE_NAME].zip' -dest:%_Destination% -verb:sync -disableLink:AppPoolExtension -disableLink:ContentExtension -disableLink:CertificateExtension %_MsDeployAdditionalFlags%
"%MSDeployPath%\msdeploy.exe" -source:package='%RootPath%[WEBSITE_NAME].zip' -dest:%_Destination% -verb:sync -disableLink:AppPoolExtension -disableLink:ContentExtension -disableLink:CertificateExtension %_MsDeployAdditionalFlags%

goto :eof

@rem ---------------------------------------------------------------------------------
@rem Usage
@rem ---------------------------------------------------------------------------------
:usage
echo =========================================================
if not exist "%RootPath%[WEBSITE_NAME].deploy-readme.txt" (
echo Usage:%~nx0 [/T^|/Y] [/M:ComputerName] [/U:userName] [/P:password] [/G:tempAgent] [additional msdeploy flags ...]
echo Required flags:
echo /T  Calls msdeploy.exe with the "-whatif" flag, which simulates deployment. 
echo /Y  Calls msdeploy.exe without the "-whatif" flag, which deploys the package to the current machine or destination server 
echo Optional flags:  
echo. By Default, this script deploy to the current machine where this script is invoked which will use current user credential without tempAgent. 
echo.   Only pass these arguments when in advance scenario.
echo /M:  Msdeploy destination name of remote computer or proxy-URL. Default is local.
echo /U:  Msdeploy destination user name. 
echo /P:  Msdeploy destination password.
echo /G:  Msdeploy destination tempAgent. True or False. Default is false.
echo /A:  specifies the type of authentication to be used. The possible values are NTLM and Basic. If the wmsvc provider setting is specified, the default authentication type is Basic
otherwise, the default authentication type is NTLM.

echo.[additional msdeploy flags]: note: " is required for passing = through command line.
echo  "-skip:objectName=setAcl" "-skip:objectName=dbFullSql"
echo.Alternative environment variable _MsDeployAdditionalFlags is also honored.
echo.
echo. Please make sure MSDeploy is installed in the box http://go.microsoft.com/?linkid=9278654
echo.
echo In addition, you can change IIS Application Name, Physical path, 
echo connectionString and other deploy parameters in the following file:
echo "%_DeploySetParametersFile%"
echo.
echo For more information about this batch file, visit http://go.microsoft.com/fwlink/?LinkID=183544 
) else (
start notepad "%RootPath%[WEBSITE_NAME].deploy-readme.txt"
)
echo =========================================================
goto :eof
