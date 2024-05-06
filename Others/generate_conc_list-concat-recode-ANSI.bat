@echo off
echo "parameter list: postfix without dot, bitrate (default to 1M), output_name (output-*.mp4 by default, will remove extension(use basename) and use mp4 extension)"
:: defaults bitrate to 1M bps
if "%~2"=="" (SET bit_rate=1M ) else (SET bit_rate=%2 )

if "%~3"=="" (SET output_name="output") else (SET output_name="%~n3")
:: concat list txt file
(for %%i in (*.%1) do @echo file '%%i') > "%output_name%-拼接列表.txt"
:: concat and recode to h265, using nVidia hevc(h265) encoder and remving duplicate frames
ffmpeg -hide_banner -hwaccel cuda -f concat -safe 0  -i "%output_name%-拼接列表.txt" -vf mpdecimate -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %bit_rate% -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high -c:a copy "%output_name%-拼接-转码-h265-码率_%bit_rate%.mp4"