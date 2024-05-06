echo "input file, (average) bitrate, output file, start time, duration, other options like -an, -c:a copy"
echo "crop=w:h:x:y"
SET ffmpeg_path=C:\FFmpeg\ffmpeg-2021-12-12-git-996b13fac4-essentials_build\bin\
:: %ffmpeg_path%ffmpeg -hwaccel cuda -i %1 -filter:v "crop=1184*iw/1920:ih:384*iw/1920:0" -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %2 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high %4 %5 %6 %7 %8 %9 %3
%ffmpeg_path%ffmpeg -hwaccel cuda -ss %4 -t %5 -accurate_seek -i %1 -vf "crop=1056:896:12:512, mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %2 -2pass true -rc-lookahead 120 -bf:v 5 -profile:v rext -level 6.2 -tier high -avoid_negative_ts 1 %6 %7 %8 %9 %3