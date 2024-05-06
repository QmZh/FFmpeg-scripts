@echo off
if "%~2"=="" (echo "inputs: video, subtitle such as *.srt" & exit)
ffmpeg -hide_banner -hwaccel cuda -i %1 -i %2 -c:v copy -c:a copy -c:s mov_text %~n1+softSub.mp4