@echo off
call "%~dp0scripts\flutter_debug.cmd" pos web %*
exit /b %ERRORLEVEL%
