@echo off
call "%~dp0scripts\flutter_debug.cmd" customer windows %*
exit /b %ERRORLEVEL%
