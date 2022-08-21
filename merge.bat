echo "input file 1, input file 2, (average) bitrate, output file, hstack(left and right) or vstack"
echo "-filter_complex hstack means horizontally merge"
SET ffmpeg_path=C:\FFmpeg\ffmpeg-2021-10-03-git-2761a7403b-essentials_build\bin\
:: %ffmpeg_path%ffmpeg -hwaccel cuda -i %1 -i %2 -filter_complex hstack -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %3 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high %4
%ffmpeg_path%ffmpeg -hwaccel cuda -i %1 -i %2 -filter_complex: "%5 , mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %3 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high %4