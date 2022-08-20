@echo off
if "%~2"=="" (echo "输入: 输入视频, 输出音频" & exit)
ffmpeg -hide_banner -hwaccel cuda -i %1 -vn -c:a copy %2
