@echo off
setlocal EnableExtensions
set "ROOT=%~dp0.."
set "PATH=%ROOT%\tools\bin;%ROOT%\node;%PATH%"
if "%APPDATA%"=="" (
  set "COSMIUS_HERMES_APPDATA=%USERPROFILE%\AppData\Roaming\CosmiusHermes"
) else (
  set "COSMIUS_HERMES_APPDATA=%APPDATA%\CosmiusHermes"
)
set "COSMIUS_HERMES_DATA=%COSMIUS_HERMES_APPDATA%\data"
set "COSMIUS_HERMES_CONFIG=%COSMIUS_HERMES_APPDATA%\config"
if not exist "%COSMIUS_HERMES_DATA%" mkdir "%COSMIUS_HERMES_DATA%"
if not exist "%COSMIUS_HERMES_CONFIG%" mkdir "%COSMIUS_HERMES_CONFIG%"
if not exist "%COSMIUS_HERMES_DATA%\webui" mkdir "%COSMIUS_HERMES_DATA%\webui"
set "HERMES_INSTALL_ENV_FILE=%COSMIUS_HERMES_CONFIG%\.env"
set "HERMES_ENV_PATH=%COSMIUS_HERMES_CONFIG%\.env"
set "HERMES_BASE_HOME=%COSMIUS_HERMES_DATA%"
set "HERMES_HOME=%COSMIUS_HERMES_DATA%"
set "HERMES_WEBUI_STATE_DIR=%COSMIUS_HERMES_DATA%\webui"
set "HERMES_EXE=%ROOT%\runtime\venv\Scripts\hermes.exe"
if not exist "%HERMES_EXE%" (
  echo Missing Cosmius Hermes CLI: "%HERMES_EXE%"
  exit /b 1
)
cd /d "%ROOT%\app\hermes-agent"
"%HERMES_EXE%" dashboard --host 127.0.0.1 --port 9119 %*
