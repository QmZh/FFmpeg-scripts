:: Note that if using "cut-剪切.bat", change the character encoding to ANSI first! This could solve only part of the problem. In PowerShell the output of ffmpeg still has the wrong charactor encoding for Chinese. This is the encoding problem for Windows PowerShell and Notepad. I hope there are powers to push the normal use of Chinese in these softwares.

@echo off
:: To cut a video or audio from time s, lasting time d, without re-encoding. This script could decide the output name automatically.
:: Note that without re-encoding, the start time begins at a keyframe, so not an accurate cut, the starting time could be off by several seconds.

:: if no argument #1, print parameter list and exit
if "%~1"=="" (echo "parameter list: input file, start time(hh:mm:ss.xxx, must have ss, can omit others), duration(same format as start time), output file(not needed, defaults to *-cut.*)" & exit)
:: set start_time to argument #2 if not empty
if "%~2"=="" (SET start_time=2 ) else (SET start_time=%2 )
:: set duration to argument #3 if not empty
:: if you would like, you can change duration to end_time, this needs some modifications of the script.
if "%~3"=="" (SET duration=3 ) else (SET duration=%3 )
:: set output_file (name) to argument #4 if not empty or add some description to the basename of input file name
if "%~4"=="" (SET output_file="%~n1-cut%~x1" ) else (SET output_file=%4 )
:: TODO: if using nvidia GPUs, use "-hwaccel cuda"
:: TODO: with "-codec copy", is it faster to use "-hwaccel cuda"?
ffmpeg -hide_banner -hwaccel cuda -ss %start_time% -t %duration% -accurate_seek -i %1 -codec copy -avoid_negative_ts 1 %output_file%
:: if not using nvidia GPUs, comment last line and uncomment next line
:: ffmpeg -hide_banner -ss %start_time% -t %duration% -accurate_seek -i %1 -codec copy -avoid_negative_ts 1 %output_file%