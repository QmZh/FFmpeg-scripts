@echo off
if "%~2"=="" (echo "����: ��Ƶ, ��ʼʱ��(��ʽΪhh:mm:ss.xxx, ��������ss��������ʡ��), ֡����(Ĭ��5), ʹ��jpg��ʽ?(��"y"��ʾȷ��, jpg��С����������), �������ֲ��ֵĳ��ȣ���������ǰ��0����" & echo ----- & echo "ע�⣬ͬ��ͼƬ�ļ��ᱻֱ�Ӹ���" & exit)
if "%~3"=="" (set frames=5) else (set frames=%3)
if "%~4"=="y" (set postfix=jpg) else (set postfix=png)
if "%~5"=="" (set length_filling_with_leading0s=5) else (set length_filling_with_leading0s=%5)

:: "-hwaccel cuda" ��ʱ��ʧЧ
:: %%d.png: ���ָ�ʽ�ַ����������ɴ�1��ʼ������

ffmpeg -hide_banner -hwaccel cuda -i %1 -vf mpdecimate -vsync vfr -ss %2 -frames:v %frames% %~n1-%%0%length_filling_with_leading0s%d.%postfix%