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
if "x%~1" == "x-isolate" shift& set BOOTARG_ISOLATE=y&        goto :checkparams
if "x%~1" == "x-home"    shift& set BOOTARG_HOME=y&           goto :checkparams
if "x%~1" == "x-?" goto :help
if "x%~1" == "x-h" goto :help
if "x%~1" == "x-help" goto :help
if "x%~1" == "x--help" goto :help
if "x%~1" == "xhelp" goto :help
if "x%~1" == "x?" goto :help

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
set "BOOTROOT=%~dp0.."
call :debug BOOTROOT was initialized to %BOOTROOT%
if DEFINED BOOTPATH (
    set "PATH=%BOOTPATH%"
    set BOOTNESTED=yes
    set BOOTAPATH=
    call :debug nesting detected, loading original BOOTPATH
) else (
    set "BOOTPATH=%PATH%"
    set BOOTNESTED=no
)
for /f %%i in ('%BOOTROOT%\boot\readconf.bat %BOOTROOT%\boot\user.conf additional_path') do set BOOTAPATH=%%i
if DEFINED BOOTAPATH call :debug BOOTPATH appended with %BOOTAPATH%
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
set HOME=
set USER=
set USETNAME=
set HOST=
set HOSTNAME=
set LOGNAME=
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

@rem help
:help
set BOOTHELP=%~dp0
echo Boot new msys instance to %BOOTHELP:~0,-6%
echo -mintty               : Open mintty window to login shell
echo -debug                : Show boot debug logs
echo -shell (/usr/bin/...) : Select login shell. default value
echo                         is defined at /boot/user.conf
echo -isolate              : Remove all of env values to isolate
echo                         completely (not recommended)
echo -home                 : Ignore cwd, instead cd to $HOME
echo -? [-][-]help         : Show this message
echo:
echo You can adjust path, homedir, username configuration in
echo %~dp0user.conf
echo:
echo Current values:
set BOOTHELP=
for /f %%i in ('C:\Windows\System32\whoami.exe') do set BOOTHELP=%%i
echo   %BOOTHELP%
set BOOTHELP=
for /f %%i in ('%~dp0\readconf.bat %~dp0\user.conf user') do set BOOTHELP=%%i
if DEFINED BOOTHELP echo     user: %BOOTHELP%
set BOOTHELP=
for /f %%i in ('%~dp0\readconf.bat %~dp0\user.conf password') do set BOOTHELP=%%i
if DEFINED BOOTHELP echo     password: %BOOTHELP%
set BOOTHELP=
for /f %%i in ('%~dp0\readconf.bat %~dp0\user.conf home') do set BOOTHELP=%%i
if DEFINED BOOTHELP echo     home: %BOOTHELP%
set BOOTHELP=
for /f %%i in ('%~dp0\readconf.bat %~dp0\user.conf shell') do set BOOTHELP=%%i
if DEFINED BOOTHELP echo     shell: %BOOTHELP%
set BOOTHELP=
for /f %%i in ('%~dp0\readconf.bat %~dp0\user.conf additional_path') do set BOOTHELP=%%i
if DEFINED BOOTHELP echo     additional_path: %BOOTHELP%
echo:
echo   Administrator (root)
set BOOTHELP=
for /f %%i in ('%~dp0\readconf.bat %~dp0\user.conf admin_user') do set BOOTHELP=%%i
if DEFINED BOOTHELP echo     admin_user: %BOOTHELP%
set BOOTHELP=
for /f %%i in ('%~dp0\readconf.bat %~dp0\user.conf admin_password') do set BOOTHELP=%%i
if DEFINED BOOTHELP echo     admin_password: %BOOTHELP%
set BOOTHELP=
for /f %%i in ('%~dp0\readconf.bat %~dp0\user.conf admin_home') do set BOOTHELP=%%i
if DEFINED BOOTHELP echo     admin_home: %BOOTHELP%
set BOOTHELP=
for /f %%i in ('%~dp0\readconf.bat %~dp0\user.conf admin_shell') do set BOOTHELP=%%i
if DEFINED BOOTHELP echo     admin_shell: %BOOTHELP%
exit 0
