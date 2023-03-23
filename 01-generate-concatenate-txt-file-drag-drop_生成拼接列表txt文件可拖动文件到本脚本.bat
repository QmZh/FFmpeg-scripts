@echo off
if "%~1"=="" (echo "输入: 拖动一个想拼接的类型的文件到本脚本，或者输入文件扩展名；txt 文件名(不需要，默认是 拼接列表.txt。如果有输入，将使用 “基础名(basename)部分”.txt。例如，a.b会生成a.txt)" & echo "注意，这里生成的txt文件将是ANSI编码的，如果音视频文件名含有中文，请把生成的txt文件改成UTF-8编码，否则ffmpeg不能正常拼接这些文件！" & echo "这个txt文件看起来会像几行的file 'silence.mp3' \ file 'song.mp3' \ file 'silence2.mp3'" & echo "排序按照音视频文件名字的字典序, 你可以编辑生成的txt文件" & exit)

SET "file_extension=%~x1"
if "%file_extension%" == "" (SET "file_extension=.%1")
if "%~2" == "" (SET "txt_filename=拼接列表.txt") else (SET "txt_filename=%~n2.txt")

echo "即将生成 *%file_extension% 文件的拼接列表txt文件 %txt_filename%"

(for %%i in (*%file_extension%) do @echo file '%%i') > "%txt_filename%"