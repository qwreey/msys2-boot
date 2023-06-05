@echo off

@rem get arguments
set BOOTARG_TERM=
set BOOTARG_DEBUG=
set BOOTARG_SHELL=
set BOOTARG_UNNEST=
set BOOTARG_ISOLATE=
set BOOTARG_HOME=
:checkparams
if "x%~1" == "x-mintty"  shift& set BOOTARG_TERM=mintty&      goto :checkparams
if "x%~1" == "x-debug"   shift& set BOOTARG_DEBUG=y&          goto :checkparams
if "x%~1" == "x-shell"   shift& set BOOTARG_SHELL=%~2& shift& goto :checkparams
if "x%~1" == "x-unnest"  shift& set BOOTARG_UNNEST=y&         goto :checkparams
if "x%~1" == "x-isolate" shift& set BOOTARG_ISOLATE=y&        goto :checkparams
if "x%~1" == "x-home"    shift& set BOOTARG_HOME=y&           goto :checkparams

call :debug BOOTING ...

call :TASK_SETENV
call :TASK_CREATEPATH
call :TASK_GETSHELL
call :TASK_GETTERM
call :TASK_SETUPUSER
call :TASK_BOOT
call :TASK_CLEANUP

exit /b 0

@rem debug print
:debug
if NOT DEFINED BOOTARG_DEBUG exit /b 0
echo %*
exit /b 0

@rem GET ROOT AND PATH, (FOR NESTED LOGIN)
:TASK_CREATEPATH
if DEFINED BOOTARG_ISOLATE set BOOTARG_UNNEST=y
if DEFINED BOOTARG_UNNEST (
    set BOOTPATH=
    set BOOTROOT=
    call :debug forcing unnested
)
if NOT DEFINED BOOTROOT (
    set "BOOTROOT=%~dp0.."
    call :debug BOOTROOT was initialized to %BOOTROOT%
) else ( call :debug use inherited BOOTROOT )
if DEFINED BOOTPATH (
    set "PATH=%BOOTPATH%"
    set BOOTNESTED=yes
    set BOOTAPATH=
) else (
    set "BOOTPATH=%PATH%"
    set BOOTNESTED=no
    for /f %%i in ('%BOOTROOT%\boot\readconf.bat %BOOTROOT%\boot\user.conf additional_path') do set BOOTAPATH=%%i
)
exit /b 0

@rem GET USER SHELL
:TASK_GETSHELL
if NOT DEFINED BOOTARG_SHELL (
    call :debug READING %BOOTROOT%\boot\user.conf
    for /f %%i in ('%BOOTROOT%\boot\readconf.bat %BOOTROOT%\boot\user.conf shell') do set BOOTSHELL=%%i
) else set "BOOTSHELL=%BOOTARG_SHELL%"
if NOT DEFINED BOOTSHELL ( set BOOTSHELL=/usr/bin/bash )
call :debug use %BOOTSHELL% as SHELL
exit /b 0

@rem GET TERMINAL
:TASK_GETTERM
set BOOTTERM=
if "x%BOOTARG_TERM%x" == "xminttyx" set BOOTTERM=%BOOTROOT%\usr\bin\mintty.exe
if DEFINED BOOTTERM call :debug use %BOOTTERM% as TERM
exit /b 0

@rem CREATE ENV
:TASK_SETENV
call :debug setting env values
set FPATH=
set PROMPT=
set PS1=
set MSYSTEM=MSYS
if NOT DEFINED BOOTARG_HOME (
    set CHERE_INVOKING=enabled_from_arguments
    set SHLVL=
) else (
    set CHERE_INVOKING=
    set SHLVL=0
)
exit /b 0

@rem CREATE USER
:TASK_SETUPUSER
SETLOCAL
for /f %%i in ('C:\Windows\System32\whoami.exe /USER /FO csv /NH') do set USER=%%i
if EXIST %BOOTROOT%\boot\cached set /p CACHED=<%BOOTROOT%\boot\cached
if "%USER: =%" NEQ "%CACHED: =%" (
    %BOOTROOT%\boot\luajit.exe %BOOTROOT%\boot\inituser.lua
    echo %USER% > %BOOTROOT%\boot\cached
    call :debug userlist was updated
) else call :debug use cached userlist
ENDLOCAL
exit /b 0

@rem CLEANUP
:TASK_CLEANUP
set BOOTROOT=
set BOOTSHELL=
set BOOTINIT=
set BOOTDEBUG=
set BOOTPATH=
set BOOTTERM=
set BOOTAPATH=
exit /b 0

@rem BOOT
:TASK_BOOT
set "BOOTINIT=%BOOTTERM% %BOOTROOT%%BOOTSHELL:/=\%.exe -l"
if DEFINED BOOTARG_ISOLATE set "BOOTINIT=%BOOTROOT%\usr\bin\env -i %BOOTINIT%" & call :debug env values was isolated
call :debug execute %BOOTINIT%
(%BOOTINIT%)
exit /b 0
