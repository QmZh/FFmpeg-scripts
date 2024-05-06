@echo off
if "%~1"=="" (echo "����: ��Ƶ" & exit)
ffmpeg -hide_banner -hwaccel cuda -i %1 -an -c:v copy %~n1-ȥ����Ƶ%~x1