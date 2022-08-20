@echo off
if "%~2"=="" (echo "inputs: input video or audio file, audio multiplies by, audio bitrate(optional, defaults to 192k), output file(optional, defaults to *-audio_times-*.*)" & exit) 
if "%~3"=="" (set audio_bitrate=192k) else (set audio_bitrate=%3)
if "%~4"=="" (set output_name="%~n1-audio_volume_times-%2%~x1") else (set output_name="%~n4%~x1")
ffmpeg -hide_banner -hwaccel cuda -i %1 -c:v copy -filter:a "volume=%2" -b:a %audio_bitrate% %output_name%
