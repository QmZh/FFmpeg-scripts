@echo off
if "%~2"=="" (echo "输入: 视频, 音频" & echo "替换音频，生成的视频长度和较长的那个对齐" & exit)
ffmpeg -hide_banner -hwaccel cuda -i %1 -i %2 -map 0:v:0 -map 1:a:0 -c copy -strict experimental "%~n1+%~n2+长对齐%~x1"