@echo off
setlocal

set "PowerShellPath=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "ScriptPath=%~dp0fix-ntp-vivo.ps1"

title Correcao de Horario Vivo

if not exist "%PowerShellPath%" (
    echo Nao foi possivel encontrar o Windows PowerShell.
    echo Este instalador requer o Windows 10 ou Windows 11.
    echo.
    pause
    exit /b 1
)

if not exist "%ScriptPath%" (
    echo Nao foi possivel encontrar o arquivo fix-ntp-vivo.ps1.
    echo Extraia todos os arquivos do ZIP para a mesma pasta e tente novamente.
    echo.
    pause
    exit /b 1
)

"%PowerShellPath%" -NoProfile -ExecutionPolicy Bypass -File "%ScriptPath%" %*
exit /b %ERRORLEVEL%
