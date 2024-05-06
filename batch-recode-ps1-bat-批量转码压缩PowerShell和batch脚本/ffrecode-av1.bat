@echo off

:: echo "from %1 to %~dp1%~n1_cq-%2_fps-%3.mp4"

if "%~1"=="" (echo "input file, cq value(has default), fps{'no' for no change, empty for 15}, bitrate{another vid just for comparison, I suggest using cq, as constant bitrate cannot express variable vid quality effectively}, {recodes to av1, copies audio}" & exit)

set file_drive_and_path=%~dp1
set file_raw_name=%~n1

@REM mkdir %file_drive_and_path%\recoded\

if "%~2"=="" (set cq_value=37) else (set cq_value=%2)

echo new cq value is %cq_value%

if "%~3"=="" (ffmpeg -hide_banner -loglevel warning -hwaccel cuda -hwaccel_output_format cuda -i "%~1" -c:a copy -c:v av1_nvenc -cq %cq_value% -preset p7 -multipass fullres "%file_drive_and_path%%file_raw_name%_cq-%cq_value%_fps-.mp4" & goto NO_FPS_VALUE) else (set fps_value=%3)

echo new fps value is %fps_value%

ffmpeg -hide_banner -loglevel warning -hwaccel cuda -hwaccel_output_format cuda -i "%~1" -c:a copy -c:v av1_nvenc -filter:v fps=%fps_value% -cq %cq_value% -preset p7 -multipass fullres "%file_drive_and_path%%file_raw_name%_cq-%cq_value%_fps-%fps_value%.mp4"

if "%~4"=="" (exit) else (set bitrate_value=%4)
ffmpeg -hide_banner -loglevel warning -hwaccel cuda -hwaccel_output_format cuda -i "%~1" -c:a copy -c:v av1_nvenc -filter:v fps=%fps_value% -b:v %bitrate_value% -preset p7 -multipass fullres "%file_drive_and_path%%file_raw_name%_bitrate-%bitrate_value%_fps-%fps_value%.mp4"

:NO_FPS_VALUE

if "%~4"=="" (exit) else (set bitrate_value=%4)
ffmpeg -hide_banner -loglevel warning -hwaccel cuda -hwaccel_output_format cuda -i "%~1" -c:a copy -c:v av1_nvenc -b:v %bitrate_value% -preset p7 -multipass fullres "%file_drive_and_path%%file_raw_name%_bitrate-%bitrate_value%.mp4"


