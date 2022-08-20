@echo off
if "%~2"=="" (echo "parameter list: input file, audio multiplies by, audio bitrate, output file(optional, defaults to *-audio_times-*.*)" & echo "it could be used on videos too" & exit) 
if "%~3"=="" (SET audio_bitrate=192k) else (SET audio_bitrate=%3)
if "%~4"=="" (SET output_name="%~n1-audio_times-%2%~x1") else (SET output_name="%~n4%~x1")
ffmpeg -hide_banner -hwaccel cuda -i %1 -c:v copy -filter:a "volume=%2" -b:a %audio_bitrate% %output_name%
