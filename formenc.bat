@ECHO OFF

REM AUTHOR: Zayne Jeffries
REM DATE: 09/01/2020
REM DESCRIPT: Scrip to format USBs to NTFS and encrypt with given password
SETLOCAL ENABLEDELAYEDEXPANSION
ECHO.
ECHO --CU USB FORMATTING AND ENCRYPTION PROGRAM--
ECHO.
ECHO WARNING! The following script will format every removable drive currently inserted.
ECHO If you do not wish to format some of the drives please remove them before running this script.
ECHO.
SET /P "confirm=Format inserted drives and set password? [y/n]: "
IF /I "%confirm%"=="y" (
	GOTO format
)

IF /I "%confirm%"=="n" (
	ECHO.
	ECHO Exiting program...
	PAUSE
	EXIT /B 0
)

:format
	for /F "tokens=1*" %%a in ('fsutil fsinfo drives') do (
		for %%c in (%%b) do (
			for /F "tokens=3" %%d in ('fsutil fsinfo drivetype %%c') do (
				if %%d equ Removable (
					CALL :subroutine1 "%%c"
					ECHO.
				) 
			)
		)
	)

:subroutine1
	SET string=%1
	SET string=%string:~1,1%
	IF "%string%"=="" (
		GOTO :pass
	)
	IF "%string%"=="~1,1" (
		GOTO :pass
	)
	IF "%string%"==":" (
		GOTO :pass
	)
	FORMAT %string%: /q /fs:ntfs /a:4096 /v: /y
	SET string=""
	GOTO :eof

:pass
	SET /P "passtest=Enter password: "
	for /F "tokens=1*" %%a in ('fsutil fsinfo drives') do (
	   for %%c in (%%b) do (
		  for /F "tokens=3" %%d in ('fsutil fsinfo drivetype %%c') do (
			 if %%d equ Removable (
			CALL :subroutine2 "%%c" "%passtest%"
			ECHO.
			 ) 
		  )
	   )
	)
	for /F "tokens=1*" %%a in ('fsutil fsinfo drives') do (
	   for %%c in (%%b) do (
		  for /F "tokens=3" %%d in ('fsutil fsinfo drivetype %%c') do (
			 if %%d equ Removable (
			CALL :checkcomplete "%%c"
			 ) 
		  )
	   )
	)

:subroutine2
	SET string=%1
	SET string=%string:~1,1%
	IF "%string%"=="" (
		GOTO :eof
	)
	IF "%string%"=="~1,1" (
		GOTO :eof
	)
	ECHO.
	powershell -Command "& {Add-BitLockerKeyProtector -MountPoint "%string%:" -Password ('%2' | ConvertTo-SecureString -AsPlainText -Force) -PasswordProtector}"
	manage-bde -on %string%:
	SET string=""
	GOTO :eof

:checkcomplete
	cls
	SET string=%1
	SET string=%string:~1,1%
	IF "%string%"=="" (
		GOTO :eof
	)
	IF "%string%"=="~1,1" (
		GOTO :eof
	)
	set done=
	set done=Conversion Status:    Fully Encrypted
	for /f "tokens=*" %%i in ('manage-bde -status %string%: ^| findstr /C:"Conversion"') do ^set status1=%%i
	echo %status1%
	ping 127.0.0.1>nul
	if "%status1%" == "%done%" ( 
		goto :eof 
    	) else (
		goto checkcomplete
	)