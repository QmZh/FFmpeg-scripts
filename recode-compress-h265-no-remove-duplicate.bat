echo "input file, bitrate"
ffmpeg  -hwaccel cuda -i %1 -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %2 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high -c:a copy "%~n1-recode-h265.mp4"