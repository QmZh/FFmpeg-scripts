echo "input file, bitrate, output file, (audio? remove: -an, recode to opus: -c:a libopus, copy: -c:a copy)"
::SET ffmpeg_path=C:\FFmpeg\ffmpeg-2021-09-11-git-3e127b595a-essentials_build\bin\
::%ffmpeg_path%
ffmpeg -hwaccel cuda -i %1 -vf mpdecimate -vsync vfr -c:v h264_nvenc -preset p7 -rc:v vbr -b:v %2 -2pass true -rc-lookahead 60 -bf:v 4 -profile:v high -level 6.2 %4 %5 %3
