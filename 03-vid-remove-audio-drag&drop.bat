@echo off
if "%~1"=="" (echo "inputs: video" & exit)
ffmpeg -hide_banner -hwaccel cuda -i %1 -an -c:v copy %~n1-no-audio%~x1