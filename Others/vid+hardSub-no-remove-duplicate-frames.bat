@echo off
if "%~4"=="" (echo "input file(video), input file(subtitle such as .srt), bitrate, font size" & exit)
ffmpeg -hide_banner -hwaccel cuda -i %1 -vf "subtitles=%~n2%~x2:force_style='Fontsize=%4'"  -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %3 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high -c:a copy %~n1+hardSub-fontSize-%4-bitrate-%3%~x1