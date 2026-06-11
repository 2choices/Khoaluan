@echo off
call "%~dp0scripts\flutter_debug.cmd" pos windows %*
exit /b %ERRORLEVEL%
