@echo off
setlocal EnableExtensions
rem Desktop-window launcher: starts the local WebUI server, then opens a standalone Edge app window.
rem Install layout: {app}\runtime\python, {app}\app\hermes-agent, {app}\app\hermes-webui, {app}\tools\bin, {app}\node
set "ROOT=%~dp0.."
set "PATH=%ROOT%\runtime\python;%ROOT%\tools\bin;%ROOT%\node;%PATH%"
set "HERMES_WEBUI_NATIVE_FOLDER_PICKER=1"
set "HERMES_WEBUI_AGENT_DIR=%ROOT%\app\hermes-agent"
set "HERMES_WEBUI_PYTHON=%ROOT%\runtime\python\python.exe"
set "HERMES_BASE_HOME=%ROOT%\data\.hermes"
set "HERMES_HOME=%ROOT%\data\.hermes"
set "HERMES_WEBUI_STATE_DIR=%ROOT%\data\webui"
set "PYTHONUTF8=1"
set "PYTHONIOENCODING=utf-8"
if "%HERMES_API_TIMEOUT%"=="" set "HERMES_API_TIMEOUT=180"
if "%HERMES_API_CALL_STALE_TIMEOUT%"=="" set "HERMES_API_CALL_STALE_TIMEOUT=180"
if "%HERMES_CODEX_TTFB_TIMEOUT_SECONDS%"=="" set "HERMES_CODEX_TTFB_TIMEOUT_SECONDS=60"
if "%HERMES_CODEX_TTFB_MAX_SECONDS%"=="" set "HERMES_CODEX_TTFB_MAX_SECONDS=60"
if "%HERMES_CODEX_EVENT_STALE_TIMEOUT_SECONDS%"=="" set "HERMES_CODEX_EVENT_STALE_TIMEOUT_SECONDS=180"
if "%HERMES_DISABLE_LAZY_INSTALLS%"=="" set "HERMES_DISABLE_LAZY_INSTALLS=1"
set "HERMES_WEBUI_PORT=%HERMES_WEBUI_PORT%"
if "%HERMES_WEBUI_PORT%"=="" set "HERMES_WEBUI_PORT=8787"

if not exist "%HERMES_WEBUI_PYTHON%" (
  rem Compatibility fallback for older staging builds.
  set "HERMES_WEBUI_PYTHON=%ROOT%\runtime\venv\Scripts\python.exe"
)

if not exist "%HERMES_WEBUI_PYTHON%" (
  rem Development/staging fallback when Build-Staging.ps1 was run with -SkipVenv.
  set "HERMES_WEBUI_PYTHON=%ROOT%\..\..\hermes-agent\.venv\Scripts\python.exe"
)

if not exist "%HERMES_WEBUI_PYTHON%" (
  echo Missing Python runtime: "%ROOT%\runtime\python\python.exe"
  echo Complete the staging/build pipeline so runtime\python exists.
  exit /b 1
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:%HERMES_WEBUI_PORT%/api/settings' -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 } } catch { exit 1 }"
if errorlevel 1 (
  cd /d "%ROOT%\app\hermes-webui"
  start "Cosmius Hermes Server" /min "%HERMES_WEBUI_PYTHON%" server.py
)

for /l %%I in (1,1,40) do (
  powershell -NoProfile -ExecutionPolicy Bypass -Command "try { $r = Invoke-WebRequest -UseBasicParsing 'http://127.0.0.1:%HERMES_WEBUI_PORT%/api/settings' -TimeoutSec 2; if ($r.StatusCode -eq 200) { exit 0 } } catch { exit 1 }"
  if not errorlevel 1 goto :open_window
  timeout /t 1 /nobreak >nul
)

echo Cosmius Hermes did not become ready on http://127.0.0.1:%HERMES_WEBUI_PORT%
exit /b 1

:open_window
start "" "http://127.0.0.1:%HERMES_WEBUI_PORT%/"
