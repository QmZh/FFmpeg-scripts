@echo off

if "%~1"=="" (echo "ʹ�á�-c copy����ƴ�ӹ��̽�û�����±��롣ƴ���б������Ƶ����Ƶ�ĸ�ʽ��������Ҫ��ͬ���������ȿ�ȶ�Ҫһ�¡�" & echo "��ע�⣬���ƴ���б�.txt����������ֺ������ģ���Ҫ����ת��ΪUTF-8���룬����ffmpeg��������ƴ����Щ�ļ���" & exit)

SET /p texte=< %1
SET "file_name=%texte:*'=%"
SET "file_name=%file_name:'=%"

FOR %%i IN ("%file_name%") DO (
SET file_name_extension=%%~xi
)

if "%~2"=="" (SET output_name="���%file_name_extension%") else (SET output_name="%~n2%file_name_extension%")

ffmpeg -hide_banner -hwaccel cuda -f concat -safe 0 -i %1 -c copy %output_name%