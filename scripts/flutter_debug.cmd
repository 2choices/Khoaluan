@echo off
setlocal EnableExtensions

set "APP=%~1"
set "TARGET=%~2"

if "%APP%"=="" goto usage
if "%TARGET%"=="" goto usage

shift /1
shift /1

set "EXTRA_ARGS="
:collect_args
if "%~1"=="" goto args_done
set "EXTRA_ARGS=%EXTRA_ARGS% %~1"
shift /1
goto collect_args
:args_done

set "DEVICE="
if /I "%TARGET%"=="web" set "DEVICE=chrome"
if /I "%TARGET%"=="chrome" set "DEVICE=chrome"
if /I "%TARGET%"=="windows" set "DEVICE=windows"

if not defined DEVICE (
  echo [ERROR] Unknown target "%TARGET%". Use web or windows.
  exit /b 1
)

set "ROOT=%~dp0.."
for %%I in ("%ROOT%") do set "ROOT=%%~fI"
set "APP_DIR=%ROOT%\apps\%APP%"

if not exist "%APP_DIR%\pubspec.yaml" (
  echo [ERROR] App "%APP%" not found at "%APP_DIR%".
  exit /b 1
)

where flutter >nul 2>nul
if errorlevel 1 (
  echo [ERROR] Flutter was not found in PATH.
  exit /b 1
)

if /I "%DEVICE%"=="chrome" (
  call flutter config --enable-web >nul
) else if /I "%DEVICE%"=="windows" (
  call flutter config --enable-windows-desktop >nul
)

pushd "%APP_DIR%"
if errorlevel 1 exit /b 1

if /I "%DEVICE%"=="windows" (
  if not exist "windows\CMakeLists.txt" (
    echo [INFO] Windows platform is missing for %APP%. Creating it now...
    call flutter create --platforms=windows .
    if errorlevel 1 goto fail
  )
)

echo.
echo [OMNIGO] Running %APP% on %TARGET% ^(%DEVICE%^) in debug mode...
echo [OMNIGO] App dir: %APP_DIR%
echo.

call flutter pub get
if errorlevel 1 goto fail

call flutter run -d %DEVICE% --debug %EXTRA_ARGS%
set "EXIT_CODE=%ERRORLEVEL%"
popd
exit /b %EXIT_CODE%

:fail
set "EXIT_CODE=%ERRORLEVEL%"
popd
echo.
echo [ERROR] Failed with exit code %EXIT_CODE%.
exit /b %EXIT_CODE%

:usage
echo Usage:
echo   scripts\flutter_debug.cmd admin web
echo   scripts\flutter_debug.cmd pos windows
echo.
echo Targets: web, windows
exit /b 1
