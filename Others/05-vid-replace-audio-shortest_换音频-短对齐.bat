@echo off
if "%~2"=="" (echo "����: ��Ƶ, ��Ƶ" & echo "�滻��Ƶ�����ɵ���Ƶ���Ⱥͽ϶̵��Ǹ�����" & exit)
ffmpeg -hide_banner -hwaccel cuda -i %1 -i %2 -map 0:v:0 -map 1:a:0 -c copy -strict experimental -shortest "%~n1+%~n2+�̶���%~x1"