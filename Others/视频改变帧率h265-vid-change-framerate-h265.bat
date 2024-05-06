@echo off
if "%~2"=="" (echo "参数：输入文件，新帧率，是否删除中间文件(y/*)，输出文件(optional, defaults to *-fps-新帧率.*" & exit)
set raw_file_name="%~n1-raw.h265"
if "%~4"=="" (set output_name="%~n1-fps-%2%~x1") else (set output_name="%~n4%~x1")
ffmpeg -hide_banner -hwaccel cuda -i %1 -map 0:v -c:v copy -bsf:v hevc_mp4toannexb %raw_file_name%
ffmpeg -hide_banner -hwaccel cuda -fflags +genpts -r %2 -i %raw_file_name% -c:v copy %output_name%
if "%~3"=="y" (DEL %raw_file_name%)