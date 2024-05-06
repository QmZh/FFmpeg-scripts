:: ffmpeg -i m14a.mp4 -i pity.mp4 -filter_complex "[1:v]setpts=PTS-STARTPTS+37/TB[delayedGif]; [0:v][delayedGif]overlay=enable='between(t,37,52)'[out]"  -map [out] complete.mp4

echo "main.mp4, overlay.mp4, timestart/s, timeend/s, overlay_new_width/pixel, bitrate, output.mp4"

ffmpeg -hwaccel cuda -i %1 -i %2  -filter_complex "[1:v]setpts=PTS-STARTPTS+%3/TB, scale=%5:-1 [delayedGif]; [0:v][delayedGif]overlay=enable='between(t,%3,%4)'[out]" -c:v hevc_nvenc -preset p7 -rc:v vbr -b:v %6 -2pass true -rc-lookahead 60 -bf:v 5 -profile:v rext -level 6.2 -tier high -map [out] %7
