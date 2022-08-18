@echo off
if "%~2"=="" (echo "输入参数: 拼接列表.txt, 输出文件名" & echo "使用’-c copy‘，拼接过程将没有重新编码。拼接列表里的音频或视频的格式、编码需要相同，包括长度宽度都要一致。" & echo "请注意，如果拼接列表.txt里的内容文字含有中文，需要把它转化为UTF-8编码，否则ffmpeg不能正常拼接这些文件！" & exit)
ffmpeg -hide_banner -hwaccel cuda -f concat -safe 0 -i %1 -c copy %2