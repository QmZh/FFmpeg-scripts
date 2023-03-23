@echo off
if "%~1"=="" (echo "Input: drag and drop a file or postfix without dot, txt file name(Not needed and defaults to i.txt. if present, will be "basename_part".txt. For example, a.b will be a.txt)" & echo "Note that the txt file will be ANSI encoded. If the names of the audio/video files contain Chinese, change the txt file's encoding to UTF-8 or ffmpeg cannot concatenate them." & echo "The txt file will look like several lines of file 'silence.mp3' \ file 'song.mp3' \ file 'silence2.mp3'" & echo "The order of files is alphabetical, you can edit it after running this bat script" & exit)

SET "file_extension=%~x1"
if "%file_extension%" == "" (SET "file_extension=.%1")
if "%~2" == "" (SET "txt_filename=i.txt") else (SET "txt_filename=%~n2.txt")

echo "generating concatenate list txt file %txt_filename% of *%file_extension% files"

(for %%i in (*%file_extension%) do @echo file '%%i') > "%txt_filename%"