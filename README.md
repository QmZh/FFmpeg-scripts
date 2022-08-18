[中文说明](读我.md)

# FFmpeg BAT scripts
FFmpeg BAT scripts to do some simple video/audio edits

# How to use
Download [ffmpeg](https://www.gyan.dev/ffmpeg/builds/), extract it to a folder, add that bin subfolder to path, which contains ffmpeg.exe. For example, [direct link(release essentials)](https://www.gyan.dev/ffmpeg/builds/ffmpeg-release-essentials.7z) (this should be the smallest build on that site).

Download the bat scripts, put them to a folder, add that folder to path.

### Note that to use bat scripts with Chinese characters, you need to change the character encoding to ANSI. Edit with notepad, choose "save as", pick ANSI as the encoding type.

Use explorer to navigate to the folder containing your video/audio files, open a terminal there (Press Shift and right click, select open PowerShell here) and use the scripts by typing the name of the script file and arguments into the terminal, separated by space(s). Check that you might need to type extra arguments when ffmpeg is running, for example "y" to agree to replace existing file with the same name.

### I don't recommend using Chinese in names of the audio/video files. The txt files generated by the scripts are in ANSI encoding. If there's Chinese character, ffmpeg will not recognize these files or concatenate them. You need to change the encoding of the txt file to UTF-8, only then could you use the scripts to concatenate the files.