@echo off
if "%~2"=="" (echo "duration, bitrate, filename(optional defaults to silent-audio-bitrate-%%bitrate-aka-%%2.aac)" & exit)
if "%~3"=="" (set output_name="silent-audio-bitrate-%2.aac") else (set output_name=%3)
ffmpeg -hide_banner -hwaccel cuda -f lavfi -i anullsrc -t %1 -b:a %2 %output_name%