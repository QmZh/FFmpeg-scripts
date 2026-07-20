### <div align="right">[English README](README2.md)</div>

结合字幕提取与 AV1 硬件加速批量重新编码的 Python 脚本。支持 AMD 和 NVIDIA 两种 GPU 编码器。

## 注意事项

- README可能和脚本有出入或本身有错误。

- AMD 780M核显以及相同架构的核显、独显，在使用`av1_amf`编码AV1视频时，有分辨率问题，例如1920x1080的视频会编码为1920x1082，应该没有解决办法，只能等下一代显卡解决这个bug。另外编码 twitch 160p 视频时可能失败，建议编码 360p 及以上的视频。

- `--preview` 预览模式下 `--cleanup-recoded` 仍然会生效，会删除存在原文件的已转码文件。

- 脚本中的 CQ 变量名以及已编码视频文件名匹配规则，是为了和之前脚本保持一致、通用。但是 AMD `av1_amf` 编码的 `qvbr_quality_level` 越大，对应的视频质量越好。脚本里对更大分辨率设置了更低的视频质量，目的是只要画面上的文字能看清即可，同时压缩率也会比较好，请自行调整。

## 用途

[ffrecode-subtitles.py](ffrecode-subtitles.py) 递归扫描指定文件夹中的视频文件（默认 flv、ts、mp4），对每个视频：
1. 提取字幕（包括嵌入的 Closed Captions），保存为 .ssa 文件
2. 使用 ffprobe 获取视频元数据（分辨率、比特率、时长等）
3. 根据分辨率自动计算 CQ 值（也可手动指定），使用 AV1 硬件编码器进行重编码
4. 验证重编码后的视频（时长检查、比特率检查），确认压缩成功后可选择删除原文件

## 主要功能

- **字幕提取**：使用 ffmpeg 的 lavfi movie filter 提取字幕和 CC，保存为 .ssa 格式；空字幕文件会自动删除
- **自动 CQ**：根据短边分辨率自动选择质量等级（AMD 数值越大画质越好，NVIDIA 则相反）
- **A卡和N卡支持**：通过 `--gpu amd`（默认）或 `--gpu nvidia` 选择编码器，分别使用 `av1_amf` 或 `av1_nvenc`
- **磁盘空间监控**：低于 500MB 时触发清理；低空间模式下按文件大小排序处理以最小化临时磁盘占用
- **循环模式**：`--loop` 参数可无限循环扫描新文件；无新文件时等待时间指数增长（最多 1024 分钟），按任意键可立即开始下一轮
- **批量处理**：`--batch-size` 参数控制并行处理文件数量
- **预览模式**：`--preview` 参数只输出将要执行的命令，不实际执行
- **清理已编码文件**：`--cleanup-recoded` 参数可删除已有编码文件（仅在原文件仍存在时删除）
- **排序方式**：`--sort` 参数支持按名称（name）、修改时间（time）或文件大小（size）排序，默认按大小
- **Windows PATH 自动刷新**：每次循环自动从注册表读取最新 PATH，无需重启即可识别新安装的 ffmpeg

## 命令行参数

| 参数 | 简写 | 默认值 | 说明 |
|------|------|--------|------|
| `--preview` | `-p` | false | 预览模式，只打印命令不执行 |
| `--cleanup-recoded` | `-cl` | false | 每轮循环结束时删除已有编码文件 |
| `--include` | `-i` | "" | 仅处理文件名包含该模式的文件 |
| `--dir` | `-wd` | "." | 工作目录 |
| `--types` | `-t` | "flv,ts,mp4" | 输入文件扩展名（逗号分隔） |
| `--gpu` | | "amd" | GPU 编码器：amd 或 nvidia |
| `--cq` | `-q` | 自动 | 固定 CQ 值（AMD: 1-51 越高越好；NVIDIA 相反） |
| `--fps` | `-f` | 自动 | 固定帧率 |
| `--all` | `-a` | "n" | 处理所有文件，忽略文件大小限制 |
| `--delete` | `-de` | "y" | 压缩成功后删除原文件 |
| `--ratio` | `-r` | 0.7 | 压缩率阈值，新文件比特率低于此比例视为成功 |
| `--sort` | `-s` | "size" | 排序方式：name / time / size |
| `--batch-size` | `-b` | 1 | 并行处理的文件数量 |
| `--loop` | `-l` | false | 无限循环模式 |
| `--verbose` | `-v` | false | 输出被跳过文件的日志 |
| `--yes` | `-y` | false | 跳过删除确认提示 |

## 使用示例

```powershell
# 基本用法：处理当前目录
python ffrecode-subtitles.py

# 指定目录和文件格式
python ffrecode-subtitles.py --dir d:\path\to\videos --types flv,mp4

# 预览模式（不实际执行）
python ffrecode-subtitles.py --preview

# 循环模式（无新文件时等待时间自动增长）
python ffrecode-subtitles.py --loop

# 固定 CQ 值和 FPS
python ffrecode-subtitles.py --cq 8 --fps 30

# 并行处理 4 个文件
python ffrecode-subtitles.py --batch-size 4

# 使用 NVIDIA GPU 编码器
python ffrecode-subtitles.py --gpu nvidia --cq 30

# 按修改时间排序，仅处理文件名包含 "lecture" 的文件
python ffrecode-subtitles.py --sort time --include lecture

# 循环模式 + 自动清理旧编码文件
python ffrecode-subtitles.py --loop --cleanup-recoded --yes
```

## 其它

需要支持 AV1 硬件编码的 GPU 及对应的显卡驱动。需要安装 ffmpeg 和 ffprobe。
