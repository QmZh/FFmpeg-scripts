@echo off
if "%~2"=="" (echo "输入: 视频, 开始时刻(格式为hh:mm:ss.xxx, 必须有秒ss其它可以省略), 持续时间 (默认0.1), 使用jpg格式?(y/*, jpg较小但不是无损), the equal length of the number part of the name that will be filled with leading 0's (there is a file name length limit)" & echo ----- & echo "Warning, if there are picture files with the same names, they will be overwritten directly" & exit)
if "%~3"=="" (set time_interval=0.1) else (set time_interval=%3) 
if "%~4"=="y" (set postfix=jpg) else (set postfix=png)
if "%~5"=="" (set length_filling_with_leading0s=5) else (set length_filling_with_leading0s=%5)

:: "-hwaccel cuda" sometimes may not work
:: %%d.png: number format string that will generate numbers counting from 1

ffmpeg -hide_banner -hwaccel cuda -i %1 -vf mpdecimate -vsync vfr -ss %2 -t %time_interval% %~n1-%%0%length_filling_with_leading0s%d.%postfix%
