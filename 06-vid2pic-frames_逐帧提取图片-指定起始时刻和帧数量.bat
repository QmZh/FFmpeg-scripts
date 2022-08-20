@echo off
if "%~2"=="" (echo "inputs: input video file, start time(hh:mm:ss.xxx, must have ss, can omit others), frames(defaults to 5), use jpg?(y/*, jpg is smaller but not lossless), the equal length of the number part of the name that will be filled with leading 0's (there is a file name length limit)" & echo ----- & echo "Warning, if there are picture files with the same names, they will be overwritten directly" & exit)
if "%~3"=="" (set frames=5) else (set frames=%3)
if "%~4"=="y" (set postfix=jpg) else (set postfix=png)
if "%~5"=="" (set length_filling_with_leading0s=5) else (set length_filling_with_leading0s=%5)

:: "-hwaccel cuda" sometimes may not work
:: %%d.png: number format string that will generate numbers counting from 1
ffmpeg -hide_banner -hwaccel cuda -i %1 -vf mpdecimate -vsync vfr -ss %2 -frames:v %frames% %~n1-%%0%length_filling_with_leading0s%d.%postfix%