@echo off
if "%~2"=="" (echo "输入: 输入的音频或视频文件, 音量倍数, 音频的比特率（默认192k, 可空缺），例如96k, 128k, 256k, 输出文件名（可空缺, 默认为 *-音量乘-音量倍数.*)" & exit) 
if "%~3"=="" (SET audio_bitrate=192k) else (SET audio_bitrate=%3)
if "%~4"=="" (SET output_name="%~n1-音量乘-%2%~x1") else (SET output_name="%~n4%~x1")
ffmpeg -hide_banner -hwaccel cuda -i %1 -c:v copy -filter:a "volume=%2" -b:a %audio_bitrate% %output_name%
