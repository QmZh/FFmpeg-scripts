### <div align="right">[中文说明](README.md)</div>

credits: ChatGPT translated this, thanks very much.

If you're using [Xtra](https://github.com/crackededed/Xtra) and [TwitchDownloader](https://github.com/lay295/TwitchDownloader) to download Twitch VODs, you might need this. If you're using Termux on a rooted Android phone in tsu mode, then you can directly use:

## Purpose

Termux tsu:

[ls-in-a-line](Termux-tsu/ls-in-a-line) is purely for listing out folders within a download directory in a single line, making it easy to copy into Ubuntu on Termux, and then use TwitchDownloader-related scripts to download chats (comments). Usage: ls-in-a-line /path/to/download/folder

[vid-duration](Termux-tsu/vid-duration) checks if the length of downloaded ts files is sufficient and moves insufficient files to a "sus" folder within the specified input folder. Xtra downloads often encounter this issue, possibly due to network problems. Downloaded files like 0.ts, 1.ts, 2-muted.ts, etc., generally have lengths of 10s, 12s, or 12.5s. Xtra can pause and resume downloads, automatically downloading the missing files.

[mv-small-files](Termux-tsu/mv-small-files) moves small downloaded ts files to the "sus" folder within the specified input folder.

Ubuntu, the following 3 scripts require TwitchDownloader:

[twitch_comments_downloader](Termux-tsu/Ubuntu/twitch_comments_downloader) downloads Twitch chat within each folder of the working directory (folder) containing Twitch VOD download folders (simply list Xtra downloaded folders in a single line, then create folders).

[twitch_chat_info](Termux-tsu/Ubuntu/twitch_chat_info) extracts downloaded files within the folder downloaded by [twitch_comments_downloader](Termux-tsu/Ubuntu/twitch_comments_downloader) or currently being downloaded, and inputs some textual information into info.txt for easy viewing and sequential downloading.

[twitch_vod_downloader](Termux-tsu/Ubuntu/twitch_vod_downloader) for certain VODs with specific resolutions that Xtra cannot download, TwitchDownloader is needed (the reverse situation also occurs, so both methods are retained). Additionally, TwitchDownloader seems not to have an option to only download ts files or merge ts files without converting to mp4 files. This script requires creating a folder within a working directory, such as "2xxxx720p," and then using the command "twitch_vod_downloader working_folder start_time end_time."

powershell:

[ffgenerate_concat_list_numerical.bat](powershell/ffgenerate_concat_list_numerical.bat) is designed to concatenate ts files. First, [rename](powershell/rename-muted.ps1) xxx-muted.ts to xxx.ts. TODO: Actually, just solving the issue of traversing files in numerical order rather than lexicographical order is sufficient, but I haven't looked into it carefully.

## Other
TODO: Later, I will attempt to set up command-line parameters using the -tag format like in ps1 scripts (tag parameter instead of positional parameter).