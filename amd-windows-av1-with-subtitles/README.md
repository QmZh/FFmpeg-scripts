### <div align="right">[English README](README2.md)</div>

结合字幕提取与 AMD AV1 硬件加速批量重新编码的 Python 脚本。

## 注意事项

- AMD 780M核显以及相同架构的核显、独显，在使用`av1_amf`编码AV1视频时，有分辨率问题，例如1920x1080的视频会编码为1920x1082，应该没有解决办法，只能等下一代显卡解决这个bug。另外我尝试编码twitch 160p视频时总是失败，只能编码360p及以上的视频

- `--preview`预览模式下`--cleanup-recoded`仍然会生效，会删除存在原文件的已转码文件

- 脚本中的CQ变量名以及已编码视频文件名匹配规则，是为了和之前脚本保持一致、通用。但是AMD `av1_amf`编码的`qvbr_quality_level`越大，对应的视频质量越好。脚本里对更大分辨率，设置了更差的视频质量，目的是只要画面上的文字能看清即可，同时压缩率也会比较好，请自行调整

## 用途

[ffrecode-subtitles.py](ffrecode-subtitles.py) 递归扫描指定文件夹中的视频文件（默认 flv、ts、mp4），对每个视频：
1. 提取字幕（包括嵌入的 Closed Captions），保存为 .ssa 文件
2. 使用 ffprobe 获取视频元数据（分辨率、比特率、时长等）
3. 根据分辨率自动计算 CQ 值（也可手动指定），使用 AV1 AMF 编码器进行硬件加速重编码
4. 验证重编码后的视频（时长检查、比特率检查），确认压缩成功后可选择删除原文件

## 主要功能

- **字幕提取**：使用 ffmpeg 的 lavfi movie filter 提取字幕和 CC，保存为 .ssa 格式
- **自动 CQ**：根据短边分辨率自动选择 qvbr_quality_level（范围 2-15，数值越大画质越低但文件越小）
- **磁盘空间监控**：低于 500MB 时触发清理，低空间模式下按文件大小排序处理以最小化临时磁盘占用
- **循环模式**：`--loop` 参数可无限循环扫描新文件，适合持续下载的场景
- **批量处理**：`--batch-size` 参数控制并行处理文件数量
- **预览模式**：`--preview` 参数只输出将要执行的命令，不实际执行
- **清理已编码文件**：`--cleanup-recoded` 参数可删除已有编码文件（仅在原文件仍存在时删除）

## 使用示例

```bash
# 基本用法：处理当前目录
python fffrecode-subtitles.py

# 指定目录和文件格式
python fffrecode-subtitles.py --dir d:\path\to\videos --types flv,mp4

# 预览模式（不实际执行）
python fffrecode-subtitles.py --preview

# 循环模式，每 60 秒扫描新文件
python fffrecode-subtitles.py --loop

# 固定 CQ 值和 FPS
python fffrecode-subtitles.py --cq 8 --fps 30

# 并行处理 4 个文件
python fffrecode-subtitles.py --batch-size 4
```

## 其它

需要 AMD 显卡及对应的显卡驱动以支持 av1_amf 编码器。需要安装 ffmpeg 和 ffprobe。

与 [批量重新编码](batch-recode-ps1-bat-批量转码压缩/README.md) 中的 PowerShell 脚本类似，但这个是纯 Python 实现，增加了字幕提取功能，且使用 AMD 编码器而非 Nvidia 编码器。
