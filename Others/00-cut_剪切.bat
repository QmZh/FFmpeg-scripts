:: ע�⣬��ѱ��ļ�"cut-����.bat"�ı���ת����ANSI��ʹ�ã���ֻ�ܽ��һ�������⡣������(PowerShell)��ffmpeg�����������Ȼ���б����������Windows PowerShell�Լ�Notepad�ı������⡣ϣ�����������ƶ���������Щ�ط�������ʹ�á�

@echo off
:: ��������Ƶ����ĳ��ʱ�̿�ʼ������һ��ʱ�䣬�������±��롣���ű������Զ���������ļ�����
:: ע���ڲ����������£���ʼʱ����ĳ���ؼ�֡�����Բ���׼ȷ�и��ʼʱ����ܺ�ָ���Ĳ����������

:: ���û�е�һ������������β��б��˳��ű�
if "%~1"=="" (echo "�����б�: �����ļ�, ��ʼʱ��(��ʽhh:mm:ss.xxx, ����������ss, ��������ʡ��), ����ʱ��(�Ϳ�ʼʱ��һ����ʽ), ����ļ���(����Ҫ�� Ĭ��Ϊ*-����.*)" & exit)
:: ���ÿ�ʼʱ��Ϊ����2���������2�ǿ�
if "%~2"=="" (SET start_time=2 ) else (SET start_time=%2 )
:: ���ó���ʱ��Ϊ����3���������3�ǿ�
:: ��Ҳ���Գ��԰ѳ���ʱ��ĳɽ���ʱ�䣬����Ҫ�Խű�����һЩ�޸�
if "%~3"=="" (SET duration=3 ) else (SET duration=%3 )
:: ��������ļ�����Ĭ��Ϊ*-����.*���������4�ǿգ�����Ϊ����4
if "%~4"=="" (SET output_file="%~n1-����%~x1" ) else (SET output_file=%4 )
:: TODO: �д�ʵ�ֵĹ��ܣ��ж���N����ʹ��"-hwaccel cuda"
:: TODO: �д�ȷ�ϵ����飺ʹ��"-codec copy"ʱ����"-hwaccel cuda"������
ffmpeg -hide_banner -hwaccel cuda -ss %start_time% -t %duration% -accurate_seek -i %1 -codec copy -avoid_negative_ts 1 %output_file%
:: �������N��������һ�иĳ����ۣ���ͷ��������Ӣ��ð�ţ�����һ�н�����ۣ�ɾ����ͷ����Ӣ��ð�ţ�
:: ffmpeg -hide_banner -ss %start_time% -t %duration% -accurate_seek -i %1 -codec copy -avoid_negative_ts 1 %output_file%