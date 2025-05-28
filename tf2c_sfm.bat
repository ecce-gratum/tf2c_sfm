REM tf2c_sfm.bat
REM Install/Update SFM files for TF2/Classic
REM
REM USE AT YOUR OWN RISK! NO WARRANTY!
REM
@ECHO OFF
SETLOCAL EnableDelayedExpansion
CLS
TITLE TF2C_SFM
GOTO MAIN

:GETDIR
	FOR /L %%I IN (0,1,%STEAM_DIRS_COUNT%) DO (
		IF EXIST "!STEAM_DIRS[%%I]!\steamapps\common\%~1" (
			SET "RETURN=!STEAM_DIRS[%%I]!\steamapps\common\%~1"
			GOTO :EOF
		)
		IF EXIST "!STEAM_DIRS[%%I]!\steamapps\sourcemods\%~1" (
			SET "RETURN=!STEAM_DIRS[%%I]!\steamapps\sourcemods\%~1"
			GOTO :EOF
		)
	)
	TITLE TF2C_SFM - ERROR
	ECHO:Could not find a %~1 installation.
	PAUSE
EXIT 1

:VPK_EXTRACT
	TITLE TF2C_SFM - Extracting Files...
	%VPK% -e "root\maps" -e "root\materials" -e "root\models" -e "root\particles" -e "root\sound" -p %1 -d %2
GOTO :EOF

:VPK_SIZE
	REM 32 bit integer limitations disallows easy conversion to GB
	FOR /F "tokens=2,3" %%I IN ('DIR "%~1\*.vpk"') DO IF "x%%I" == "xFile(s)" SET RETURN=%%J
	REM FOR /F "tokens=1" %I IN ('WHERE /T "E:\Steam\steamapps\common\Team Fortress 2\tf:tf2_*.vpk"') DO ECHO:%I
GOTO :EOF

:VPK_CONFIRM
	CALL :VPK_SIZE "%~dp1"
	ECHO:This requires %RETURN% bytes of free space.
	ECHO/
	ECHO Do you want to continue^? [y/n]
	SET /P "QUERY=> "
	IF /I "x%QUERY:~0,1%" == "xy" (
		ECHO Sit back^, this can take a few minutes...
		REM Wait 3 seconds
		PING -n 4 127.0.0.1>NUL
		GOTO :EOF
	)
	TITLE TF2C_SFM - ERROR
	ECHO Aborting...
	PAUSE
EXIT 1

:FIXMAT
	REM TF2C uses vmt shaders with the format SDK_xyz
	REM SFM only understands xyz
	TITLE TF2C_SFM - Fixing Materials...
	ECHO Sit back^, this can take a few minutes...
	FOR /F "delims=" %%I IN ('WHERE /R "%~1\materials" *.vmt') DO (
		(FOR /F "delims=" %%J IN ('type "%%~I"') DO (
			SET LINE=%%J
			SET LINE=!LINE:"SDK_="!
			SET LINE=!LINE:SDK_=!
			ECHO:!LINE!
	))>"%%I.FIX.TMP"
		MOVE /Y "%%I.FIX.TMP" "%%I" >NUL
		ECHO:Fixed %%I
	)
GOTO :EOF


:MAIN

SET STEAM="C:\Program Files (x86)\Steam"
:FIND_STEAM
IF NOT EXIST %STEAM%\config\libraryfolders.vdf (
	ECHO/
	ECHO Could not find Steam installation.
	ECHO Where is Steam installed on your system^?
	SET /P "STEAM=> "
	GOTO FIND_STEAM
)

REM steam game folders
SET STEAM_DIRS_COUNT=0
FOR /F delims^=^"^ tokens^=4 %%I IN ('FINDSTR path %STEAM%\config\libraryfolders.vdf') DO (
	SET STEAM_DIRS[!STEAM_DIRS_COUNT!]=%%~fI
	SET /A STEAM_DIRS_COUNT+=1
)

REM Valve's vpk.exe does not work currently
SET VPK=HLExtract.exe
:FIND_VPK
IF NOT EXIST %VPK% (
	ECHO/
	ECHO Could not find HLExtract ^(HLLib^) installation.
	ECHO Where is HLExtract.exe installed on your system^?
	SET /P "VPK=> "
	GOTO FIND_VPK
)
IF EXIST %VPK%\* (
	SET VPK=%VPK%\HLExtract.exe
	GOTO FIND_VPK
)

CALL :GETDIR SourceFilmmaker
SET DIR_SFM=%RETURN%
CALL :GETDIR tf2classic
SET DIR_TF2C=%RETURN%
SET DIR_SFM_TF2C=%DIR_SFM%\game\tf2classic

ECHO ------------------------
ECHO SFM: %DIR_SFM%
ECHO TF2C: %DIR_TF2C%
ECHO VPK: %VPK%
ECHO ------------------------
ECHO/
ECHO/
ECHO What would you like to do^?
ECHO 1 - Install/Update TF2Classic SFM content
ECHO 2 - Update TF2 SFM content
ECHO 3 - Fix TF2Classic SFM installation
SET /P "QUERY=> "
IF "x!QUERY!" == "x1" (
	IF NOT EXIST "!DIR_SFM_TF2C!\*" (
		MKDIR "!DIR_SFM_TF2C!"
		IF %ERRORLEVEL% == 1 (
			TITLE TF2C_SFM - ERROR
			ECHO:Could not create !DIR_SFM_TF2C!.
			PAUSE
			EXIT 1
		)
	) ELSE ECHO:Updating !DIR_SFM_TF2C! will override files.
	CALL :VPK_CONFIRM "%DIR_TF2C%\vpks\tf2c_assets_dir.vpk"
	CALL :VPK_EXTRACT "%DIR_TF2C%\vpks\tf2c_assets_dir.vpk" "%DIR_SFM_TF2C%"
	CALL :FIXMAT "%DIR_SFM_TF2C%"
) ELSE (IF "x%QUERY%" == "x2" (
	CALL :GETDIR "Team Fortress 2"
	SET DIR_TF=!RETURN!
	ECHO:TF2: !DIR_TF!
	ECHO:Updating !DIR_SFM!\game\tf will override files.
	CALL :VPK_CONFIRM "!DIR_TF!\tf\tf2_*_dir.vpk"
	FOR %%I IN (sound_misc misc textures) DO CALL :VPK_EXTRACT "!DIR_TF!\tf\tf2_%%I_dir.vpk" "%DIR_SFM%\game\tf"
	ECHO/
	ECHO All done!
	GOTO ALLDONE
) ELSE (IF "x%QUERY%" == "x3" (
	CALL :FIXMAT "%DIR_SFM_TF2C%"
) ELSE (
	TITLE TF2C_SFM - ERROR
	ECHO Aborting...
	PAUSE
	EXIT 1
)))

ECHO/
TITLE TF2C_SFM - Finished
ECHO All done!
ECHO Launch the SFM SDK and make sure the tf2classic searth path is enabled.
:ALLDONE
PAUSE
TITLE C:\Windows\System32\cmd.exe
