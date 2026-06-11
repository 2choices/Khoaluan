@echo off
call "%~dp0scripts\flutter_debug.cmd" admin windows %*
exit /b %ERRORLEVEL%
