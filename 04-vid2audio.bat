@echo off
if "%~2"=="" (echo "inputs: input video, output audio" & exit)
ffmpeg -hide_banner -hwaccel cuda -i %1 -vn -c:a copy %2
