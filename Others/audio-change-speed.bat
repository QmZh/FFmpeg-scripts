@echo off
if "%~2"=="" (echo "inputs: input video or audio, speed multiplies by, audio bitrate(optional, default to 192k), output file(optional, defaults to *-audio_speed_times-*.*)" & exit)
if "%~3"=="" (set audio_bitrate=192k) else (set audio_bitrate=%3)
if "%~4"=="" (set output_name="%~n1-audio_speed_times-%2%~x1") else (set output_name="%~n4%~x1")
ffmpeg -hide_banner -hwaccel cuda -i %1 -c:v copy -af atempo=%2 -b:a %audio_bitrate% %output_name%