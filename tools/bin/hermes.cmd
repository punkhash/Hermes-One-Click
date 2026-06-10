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
set "HERMES_INSTALL_ENV_FILE=%ROOT%\.env"
set "HERMES_HOME=%ROOT%\data\.hermes"
set "HERMES_WEBUI_STATE_DIR=%ROOT%\data\webui"
"%PYTHON_EXE%" -m hermes_cli.main %*
exit /b %ERRORLEVEL%
