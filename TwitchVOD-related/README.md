### <div align="right">[English README](README2.md)</div>

如果你在用[Xtra](https://github.com/crackededed/Xtra)和[TwitchDownloader](https://github.com/lay295/TwitchDownloader)下载Twitch VOD, 你可能需要这个。如果你在root的安卓手机的Termux里的tsu模式下使用，那就可以直接用

## 用途

Termux tsu:

[ls-in-a-line](Termux-tsu/ls-in-a-line) 纯粹是为了在一行里列出下载文件夹里各个文件夹，方便复制到Ubuntu on Termux里面，然后用TwitchDownloader相关脚本下载chats(弹幕). ls-in-a-line /path/to/download/folder

[vid-duration](Termux-tsu/vid-duration) 检查下载的ts文件长度是否足够，并把不够长的文件移动到输入的文件夹下的sus文件夹。Xtra下载的文件常常有这个问题，可能是我网络问题。下载的0.ts, 1.ts, 2-muted.ts等等,一般长度都是10s，也有12s，12.5s的。Xtra可以点击暂停再点下载，会自动下载少了的文件。

[mv-small-files](Termux-tsu/mv-small-files) 把不够大的下载的ts文件移动到输入的文件夹下的sus文件夹

Ubuntu,以下3个需要TwitchDownloader:

[twitch_comments_downloader](Termux-tsu/Ubuntu/twitch_comments_downloader) 对工作目录（文件夹）下的符合格式的twitch VOD的下载文件夹（把Xtra下载的文件夹，列成一行然后复制，创建文件夹即可），在每个文件夹里下载twitch chat

[twitch_chat_info](Termux-tsu/Ubuntu/twitch_chat_info) 在[twitch_comments_downloader](Termux-tsu/Ubuntu/twitch_comments_downloader)下载好或正在下载的文件夹里，解压缩下载的文件并把一些文字信息输入到info.txt里，方便查看和按照顺序下载（

[twitch_vod_downloader](Termux-tsu/Ubuntu/twitch_vod_downloader) 有些VOD的某些清晰度, Xtra无法下载，需要使用 TwitchDownloader（其实相反情况也有，所以我这两种方式都要保留，另外TwitchDownloader似乎还没有只下载ts文件、合并ts文件但是不合成mp4文件的选项，空间紧张时还是要用Xtra）, 这个需要在一个工作目录下创建文件夹，例如2xxxx720p，然后 “twitch_vod_downloader 工作文件夹 起始时刻 结束时刻”

powershell:
[ffgenerate_concat_list_numerical.bat](powershell/ffgenerate_concat_list_numerical.bat) 目的是把ts文件拼接起来。需要先把xxx-muted.ts[重命名](powershell/rename-muted.ps1)为xxx.ts. TODO：其实只要解决遍历文件的时候按照numerical顺序而不是字典序就行，但是我没有仔细找。


## 其它
TODO: 之后会尝试一下和ps1脚本一样设置-tag形式的命令行参数（tag parameter instead of positional parameter）