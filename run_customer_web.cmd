@echo off
call "%~dp0scripts\flutter_debug.cmd" customer web %*
exit /b %ERRORLEVEL%
