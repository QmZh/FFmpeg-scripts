@echo off
if "%~2"=="" (echo "����: �������Ƶ����Ƶ�ļ�, ��������, ��Ƶ�ı����ʣ�Ĭ��192k, �ɿ�ȱ��������96k, 128k, 256k, ����ļ������ɿ�ȱ, Ĭ��Ϊ *-������-��������.*)" & exit) 
if "%~3"=="" (SET audio_bitrate=192k) else (SET audio_bitrate=%3)
if "%~4"=="" (SET output_name="%~n1-������-%2%~x1") else (SET output_name="%~n4%~x1")
ffmpeg -hide_banner -hwaccel cuda -i %1 -c:v copy -filter:a "volume=%2" -b:a %audio_bitrate% %output_name%
