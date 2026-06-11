@echo off
call "%~dp0scripts\flutter_debug.cmd" admin web %*
exit /b %ERRORLEVEL%
