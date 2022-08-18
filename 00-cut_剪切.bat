:: 注意，请把本文件"cut-剪切.bat"的编码转换成ANSI再使用！这只能解决一部分问题。命令行(PowerShell)中ffmpeg输出的中文仍然会有编码错误。这是Windows PowerShell以及Notepad的编码问题。希望有力量能推动中文在这些地方的正常使用。

@echo off
:: 剪切音视频，从某个时刻开始，持续一段时间，无需重新编码。本脚本可以自动决定输出文件名字
:: 注意在不编码的情况下，开始时刻在某个关键帧，所以不是准确切割，开始时间可能和指定的参数相差数秒

:: 如果没有第一个参数，输出形参列表并退出脚本
if "%~1"=="" (echo "参数列表: 输入文件, 开始时刻(格式hh:mm:ss.xxx, 必须有秒数ss, 其它可以省略), 持续时间(和开始时刻一样格式), 输出文件名(不需要， 默认为*-剪切.*)" & exit)
:: 设置开始时刻为参数2，如果参数2非空
if "%~2"=="" (SET start_time=2 ) else (SET start_time=%2 )
:: 设置持续时间为参数3，如果参数3非空
:: 你也可以尝试把持续时间改成结束时间，这需要对脚本做出一些修改
if "%~3"=="" (SET duration=3 ) else (SET duration=%3 )
:: 设置输出文件名字默认为*-剪切.*，如果参数4非空，设置为参数4
if "%~4"=="" (SET output_file="%~n1-剪切%~x1" ) else (SET output_file=%4 )
:: TODO: 有待实现的功能，判断是N卡就使用"-hwaccel cuda"
:: TODO: 有待确认的事情：使用"-codec copy"时，用"-hwaccel cuda"更快吗？
ffmpeg -hide_banner -hwaccel cuda -ss %start_time% -t %duration% -accurate_seek -i %1 -codec copy -avoid_negative_ts 1 %output_file%
:: 如果不是N卡，把上一行改成评论（开头增加两个英文冒号），下一行解除评论（删掉开头两个英文冒号）
:: ffmpeg -hide_banner -ss %start_time% -t %duration% -accurate_seek -i %1 -codec copy -avoid_negative_ts 1 %output_file%