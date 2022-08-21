echo "input file 1 (trim 1), input file 2 (trim 2), cut from left, cut width, (average) crop bitrate, (average) output bitrate, output file, input file 3 (trim 3)"
echo "crop=w:h:x:y"
SET ffmpeg_path=C:\FFmpeg\ffmpeg-2021-12-12-git-996b13fac4-essentials_build\bin\
%ffmpeg_path%ffmpeg -hwaccel cuda -i %1 -vf "crop=%4:ih:%3:0, mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %5 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high .\crop1.mp4 -y
%ffmpeg_path%ffmpeg -hwaccel cuda -i %2 -vf "crop=%4:ih:%3:0, mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %5 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high .\crop2.mp4 -y
:: %ffmpeg_path%ffmpeg -hwaccel cuda -i %8 -vf "crop=%4*iw/1920:ih:%3*iw/1920:0, mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %5 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high .\crop3.mp4 -y

%ffmpeg_path%ffmpeg -hwaccel cuda -i .\crop1.mp4 -i .\crop2.mp4 -filter_complex: "xstack=inputs=2:layout=0_0|w0_0 , mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %6 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high %7 -y
:: %ffmpeg_path%ffmpeg -hwaccel cuda -i .\crop1.mp4 -i .\crop2.mp4 -i .\crop3.mp4 -filter_complex: "xstack=inputs=3:layout=0_0|w0_0|w0+w1_0 , mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %6 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high %7 -y

:: DEL .\crop1.mp4
:: DEL .\crop2.mp4
:: DEL .\crop3.mp4
