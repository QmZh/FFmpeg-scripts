batch recode videos under a folder

## Usage
[ffget-vid-info.ps1](ffget-vid-info.ps1), get video info

[ffrecode-av1-batch.ps1](ffrecode-av1-batch.ps1), does recoding, currently needs to use [ffrecode-av1.bat](ffrecode-av1.bat). TODO: will rewrite to a function in ps1 script file


## Others

use directly if you have a 40xx Nvidia GPU

-type * for all files. TODO: will try to accept a list of file type.

My observation is that large resolution videos are clear even with big cq value in av1 encoding (same for crf in h264 and corresponding video quality option in hevc)

-fps need to be selected

you can choose to delete origin file on compressing, but a better checking is needed. Sometimes the space is short and the resulting video will be garbage. Currently it checks that duration is enough and bitrate is smaller than threshold. Note that when recording live (such as bilibili), short of space or internet problem or streamer side problem will cause the actual playing time shorter than displayed time on a player