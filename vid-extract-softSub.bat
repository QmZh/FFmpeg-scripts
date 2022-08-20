@echo off
if "%~1"=="" (echo "inputs: input-file.mp4 or input-file.mkv" & exit)
ffmpeg -hide_banner -hwaccel cuda -i %1 %~n1-subtitle.srt