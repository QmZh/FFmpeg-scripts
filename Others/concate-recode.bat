@echo off
if "%~1"=="" (echo "input.txt file, bitrate(1M by default), output file (input-conc-recode-h265-bit_rate.mp4 by default). (recodes to hevc(h265), copies audio, removes duplicate frames)" & echo "input.txt should look like several lines of file 'silence.mp3' \ file 'song.mp3' \ file 'silence2.mp3'" & exit)
if "%~2"=="" (SET bit_rate="1M") else (SET bit_rate="%2")
if "%~3"=="" (SET output_base_name="%~n1") else (SET output_base_name="%~n3")

ffmpeg -hide_banner -hwaccel cuda -f concat -safe 0  -i %1 -vf mpdecimate -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %bit_rate% -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high -c:a copy "%output_base_name%-conc-recode-h265-%bit_rate%.mp4"