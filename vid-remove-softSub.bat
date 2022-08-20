@echo off
if "%~1"=="" (echo "inputs: input-file.mp4 or input-file.mkv" & exit)
ffmpeg -hide_banner -hwaccel cuda -i %1 -c:v copy -c:a copy -sn %~n1-remove-soft-subtitle%~x1