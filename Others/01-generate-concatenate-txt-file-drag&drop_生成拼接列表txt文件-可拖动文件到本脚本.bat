@echo off
if "%~1"=="" (echo "����: �϶�һ����ƴ�ӵ����͵��ļ������ű������������ļ���չ����txt �ļ���(����Ҫ��Ĭ���� ƴ���б�.txt����������룬��ʹ�� ��������(basename)���֡�.txt�����磬a.b������a.txt)" & echo "ע�⣬�������ɵ�txt�ļ�����ANSI����ģ��������Ƶ�ļ����������ģ�������ɵ�txt�ļ��ĳ�UTF-8���룬����ffmpeg��������ƴ����Щ�ļ���" & echo "���txt�ļ������������е�file 'silence.mp3' \ file 'song.mp3' \ file 'silence2.mp3'" & echo "����������Ƶ�ļ����ֵ��ֵ���, ����Ա༭���ɵ�txt�ļ�" & exit)

SET "file_extension=%~x1"
if "%file_extension%" == "" (SET "file_extension=.%1")
if "%~2" == "" (SET "txt_filename=ƴ���б�.txt") else (SET "txt_filename=%~n2.txt")

echo "�������� *%file_extension% �ļ���ƴ���б�txt�ļ� %txt_filename%"

(for %%i in (*%file_extension%) do @echo file '%%i') > "%txt_filename%"