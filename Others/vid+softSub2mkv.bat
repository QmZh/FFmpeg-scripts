@echo off
if "%~2"=="" (echo "input file(video), input file(subtitle such as .srt)" & exit)
ffmpeg -hide_banner -hwaccel cuda -i %1 -i %2 -c copy %~n1+softSub.mkv