@echo off
if "%~2"=="" (echo "输入: 视频, 开始时刻(格式为hh:mm:ss.xxx, 必须有秒ss其它可以省略), 帧数量(默认5), 使用jpg格式?(填"y"表示确定, jpg较小但不是无损), 名字数字部分的长度，不足则用前导0补齐" & echo ----- & echo "注意，同名图片文件会被直接覆盖" & exit)
if "%~3"=="" (set frames=5) else (set frames=%3)
if "%~4"=="y" (set postfix=jpg) else (set postfix=png)
if "%~5"=="" (set length_filling_with_leading0s=5) else (set length_filling_with_leading0s=%5)

:: "-hwaccel cuda" 有时会失效
:: %%d.png: 数字格式字符串，会生成从1开始的数字

ffmpeg -hide_banner -hwaccel cuda -i %1 -vf mpdecimate -vsync vfr -ss %2 -frames:v %frames% %~n1-%%0%length_filling_with_leading0s%d.%postfix%