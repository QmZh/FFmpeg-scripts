@echo off
if "%~2"=="" (echo "����: ������Ƶ, �����Ƶ" & exit)
ffmpeg -hide_banner -hwaccel cuda -i %1 -vn -c:a copy %2
