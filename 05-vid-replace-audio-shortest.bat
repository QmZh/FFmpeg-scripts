@echo off
if "%~2"=="" (echo "inputs: video, audio" & echo "it replaces video's audio, result video length is the same as the shortest one" & exit)
ffmpeg -hide_banner -hwaccel cuda -i %1 -i %2 -map 0:v:0 -map 1:a:0 -c copy -strict experimental -shortest "%~n1+%~n2+shortest%~x1"