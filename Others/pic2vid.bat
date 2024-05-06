:: pic2vid
echo "framerate, output file, input image file prefix"
ffmpeg -hwaccel cuda -framerate %1 -i %3%%d.jpg -c:v hevc_nvenc -preset p7 -rc:v vbr -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high %2