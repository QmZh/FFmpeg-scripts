:: video file type is mp4
@echo off
if "%~6"=="" (echo "width, hight, rate(frames per second), color(black, for example), length, -cq quality(38, for example)" & exit)
ffmpeg -hide_banner -hwaccel cuda -f lavfi -i color=size=%1x%2:rate=%3:color=%4 -t %5 -c:v hevc_nvenc -preset p7 -tune hq -rc:v vbr -cq:v %6 -rc-lookahead 120 -bf:v 5 -profile:v rext -tier high "%4-%1x%2-fps-%3.mp4"