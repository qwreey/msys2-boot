@echo off
set "BOOTROOT=%~dp0.."
for /f %%i in ('%windir%\System32\whoami.exe /USER /FO csv /NH') do set USER=%%i
if EXIST %BOOTROOT%\boot\cached set /p CACHED=<%BOOTROOT%\boot\cached
if "%USER: =%" NEQ "%CACHED: =%" (
    %BOOTROOT%\boot\luajit.exe %BOOTROOT%\boot\inituser.lua
    echo %USER% > %BOOTROOT%\boot\cached
)
