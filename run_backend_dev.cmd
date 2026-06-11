@echo off
setlocal

pushd "%~dp0backend\core-api" || exit /b 1
npm run start:dev %*
set EXIT_CODE=%ERRORLEVEL%
popd

exit /b %EXIT_CODE%
