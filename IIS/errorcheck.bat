@echo off

set weburl=%1

for /f %%i in ('curl.exe -s -L -w %%{http_code} %weburl% -o nul') do set code=%%i
echo [%date%, %time%] %weburl% Status: %code% 

if not %code%==200 ( 
	echo [%date%, %time%] %weburl% appears to be down. >>errorcheck.log
	goto FAILSAFE 
	:FAILSAFE
		echo [%date%, %time%] Retrying... >>errorcheck.log	
		for /f %%i in ('curl.exe -s -L -w %%{http_code} %weburl% -o nul') do set code=%%i

		if %code%==200 (
			echo [%date%, %time%] %weburl% up. >>errorcheck.log
			exit
		)

		if not %code%==200 (
			echo [%date%, %time%] %weburl% still down. >>errorcheck.log
			C:\Windows\System32\inetsrv\appcmd recycle apppool "%weburl%" 
			echo [%date%, %time%] AppPool recycled. >>errorcheck.log
		)

		timeout /t 15 /nobreak

		echo [%date%, %time%] Verifying... >>errorcheck.log	
		for /f %%i in ('curl.exe -s -L -w %%{http_code} %weburl% -o nul') do set code=%%i

		if %code%==200 (
			echo [%date%, %time%] %weburl% up. >>errorcheck.log
			exit
		)

		if not %code%==200 (
			echo [%date%, %time%] Still not working... >>errorcheck.log	
			C:\Windows\System32\inetsrv\appcmd recycle apppool "%weburl%" 
			echo [%date%, %time%] AppPool recycled. >>errorcheck.log
		)		
		
		timeout /t 15 /nobreak

		echo [%date%, %time%] Last try... >>errorcheck.log	
		for /f %%i in ('curl.exe -s -L -w %%{http_code} %weburl% -o nul') do set code=%%i
		
		if %code%==200 (
			echo [%date%, %time%] %weburl% up. >>errorcheck.log
			exit
		)

		if not %code%==200 (
			echo [%date%, %time%] Still down. Resetting IIS... >>errorcheck.log	
			iisreset
			echo [%date%, %time%] IIS has been reset. >>errorcheck.log
		)
	)
exit