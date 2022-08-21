@echo off
if "%~4"=="" (echo "input video, new width, new height, bitrate" & exit)
ffmpeg -hide_banner -hwaccel cuda -i %1 -vf scale=%2:%3 -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %4 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high -c:a copy "%~n1-%2x%3-%4%~x1"