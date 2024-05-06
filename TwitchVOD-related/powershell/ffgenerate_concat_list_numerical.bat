@echo off
if "%~2"=="" (echo "Input: start number, end number, one file example or postfix without dot(ts by default), txt file name(Not needed and defaults to i.txt. if present, will be "basename_part".txt. For example, a.b will be a.txt)" & echo "Note that the txt file will be ANSI encoded. If the names of the audio/video files contain Chinese, change the txt file's encoding to UTF-8 or ffmpeg cannot concatenate them." & echo "The txt file will look like several lines of file 'silence.mp3' \ file 'song.mp3' \ file 'silence2.mp3'" & echo "The order of files is alphabetical, you can edit it after running this bat script" & exit)

if "%~3"=="" (SET "file_extension=.ts") else (SET "file_extension=%~x3")
if "%file_extension%" == "" (SET "file_extension=.%3")

if "%~4" == "" (SET "txt_filename=i.txt") else (SET "txt_filename=%~n4.txt")

echo "generating concatenate list txt file %txt_filename% of *%file_extension% files"


(FOR /L %%i IN (%1, 1, %2) DO @echo file '%%i%file_extension%') > "%txt_filename%"

:: (for %%i in (*%file_extension%) do @echo file '%%i') > "%txt_filename%"
