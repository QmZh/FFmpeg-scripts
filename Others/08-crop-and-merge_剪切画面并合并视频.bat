@echo off
if "%~6"=="" (echo "����: ��Ƶ1, ��Ƶ2, ���к���(pixels), ���к�߶�(pixels), ���к����߿��(pixels), ���к�ඥ���߶�(pixels), ���к���Ƶ������(Ĭ��3M,�ɿ�ȱ), �ϲ�����Ƶ������(Ĭ��5M,�ɿ�ȱ), ��Ƶ3 (�ɿ�ȱ)" & exit)
if "%~7"=="" (SET crop_bitrate="3M") else (SET crop_bitrate="%7")
if "%~8"=="" (SET output_bitrate="5M") else (SET output_bitrate="%8")
SET crop1="%~n1-����-whxy-%3-%4-%5-%6-������-%crop_bitrate%.mp4"
SET crop2="%~n2-����-whxy-%3-%4-%5-%6-������-%crop_bitrate%.mp4"
SET crop3="%~n9-����-whxy-%3-%4-%5-%6-������-%crop_bitrate%.mp4"
ffmpeg -hide_banner -hwaccel cuda -i %1 -vf "crop=%3:%4:%5:%6, mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %crop_bitrate% -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high -c:a copy %crop1%
ffmpeg -hide_banner -hwaccel cuda -i %2 -vf "crop=%3:%4:%5:%6, mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %crop_bitrate% -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high -c:a copy %crop2%
if "%~9"=="" (echo "") else (ffmpeg -hide_banner -hwaccel cuda -i %9 -vf "crop=%3:%4:%5:%6, mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %crop_bitrate% -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high -c:a copy %crop3%)
:: echo "crop=w:h:x:y"
:: ffmpeg -hide_banner -hwaccel cuda -i %1 -vf "crop=%4:ih:%3:0, mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %5 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high .\crop1.mp4 -y
:: ffmpeg -hide_banner -hwaccel cuda -i %2 -vf "crop=%4:ih:%3:0, mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %5 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high .\crop2.mp4 -y
:: ffmpeg -hide_banner -hwaccel cuda -i %8 -vf "crop=%4*iw/1920:ih:%3*iw/1920:0, mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %5 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high .\crop3.mp4 -y

if "%~9"=="" (ffmpeg -hide_banner -hwaccel cuda -i %crop1% -i %crop2% -filter_complex: "xstack=inputs=2:layout=0_0|w0_0 , mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %output_bitrate% -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high -c:a copy .\%~n1-vs-%~n2.mp4) else (ffmpeg -hide_banner -hwaccel cuda -i %crop1% -i %crop2% -i %crop3% -filter_complex: "xstack=inputs=3:layout=0_0|w0_0|w0+w1_0 , mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %output_bitrate% -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high -c:a copy .\%~n1-vs-%~n2-vs-%~n9.mp4)
:: ffmpeg -hide_banner -hwaccel cuda -i .\crop1.mp4 -i .\crop2.mp4 -i .\crop3.mp4 -filter_complex: "xstack=inputs=3:layout=0_0|w0_0|w0+w1_0 , mpdecimate" -vsync vfr -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %6 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high %7 -y

:: DEL .\crop1.mp4
:: DEL .\crop2.mp4
:: DEL .\crop3.mp4
