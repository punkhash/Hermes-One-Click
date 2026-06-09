@echo off
setlocal
set "ROOT=%~dp0..\.."
if /I "%~1"=="model" (
  if exist "%ROOT%\CosmiusHermes.exe" (
    start "" "%ROOT%\CosmiusHermes.exe" --model-config
    exit /b 0
  )
)
set "PYTHON_EXE=%ROOT%\runtime\python\python.exe"
if not exist "%PYTHON_EXE%" set "PYTHON_EXE=%ROOT%\runtime\venv\Scripts\python.exe"
if not exist "%PYTHON_EXE%" (
  echo Error: bundled Python runtime not found. 1>&2
  exit /b 1
)
set "PATH=%ROOT%\runtime\python;%ROOT%\tools\bin;%ROOT%\node;%PATH%"
set "HERMES_INSTALL_ROOT=%ROOT%"
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
"%PYTHON_EXE%" -m hermes_cli.main %*
exit /b %ERRORLEVEL%
