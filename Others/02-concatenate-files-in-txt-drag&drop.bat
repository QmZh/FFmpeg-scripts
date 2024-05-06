@echo off

if "%~1"=="" (echo "using '-c copy', there will not be re-encoding. The format and codec of the audios or videos need to be the same, including width and height." & echo "Note that if input.txt contains Chinese as it's content, use UTF-8 character encoding, or ffmpeg cannot concatenate these files." & exit)

SET /p texte=< %1
SET "file_name=%texte:*'=%"
SET "file_name=%file_name:'=%"

FOR %%i IN ("%file_name%") DO (
SET file_name_extension=%%~xi
)

if "%~2"=="" (SET output_name="output%file_name_extension%") else (SET output_name="%~n2%file_name_extension%")

ffmpeg -hide_banner -hwaccel cuda -f concat -safe 0 -i %1 -c copy %output_name%