### <div align="right">[中文说明](README.md)</div>

A Python script that combines subtitle extraction with AV1 hardware-accelerated batch recoding. Supports both AMD and NVIDIA GPU encoders.

## Notes

- README might differ from the actual script or have error.

- AMD 780M integrated graphics (and GPUs on the same architecture) have a resolution issue when using `av1_amf` to encode AV1 videos — for example, a 1920×1080 video will be encoded as 1920×1082. There is likely no workaround other than waiting for the next generation of GPUs to fix this bug. Additionally, encoding Twitch 160p videos may fail; it's recommended to encode 360p and above.

- In `--preview` mode, `--cleanup-recoded` still takes effect and will delete existing recoded files whose originals still exist.

- The CQ variable names and recoded filename matching rules in the script are kept consistent with previous scripts for compatibility. However, for AMD's `av1_amf` encoder, a **higher** `qvbr_quality_level` means **better** video quality. The script sets lower video quality for higher resolutions with the goal of keeping on-screen text readable while achieving good compression — adjust as needed.

## Purpose

[ffrecode-subtitles.py](ffrecode-subtitles.py) recursively scans a specified folder for video files (default: flv, ts, mp4), and for each video:
1. Extracts subtitles (including embedded Closed Captions) and saves them as .ssa files
2. Uses ffprobe to gather video metadata (resolution, bitrate, duration, etc.)
3. Auto-calculates CQ value based on resolution (or use a manual value), then recodes using the AV1 hardware encoder
4. Verifies the recoded video (duration check, bitrate check), and optionally deletes the original file on success

## Features

- **Subtitle extraction**: Uses ffmpeg's lavfi movie filter to extract subtitles and CC, saved as .ssa; empty subtitle files are automatically removed
- **Auto CQ**: Automatically selects quality level based on the shorter side of the resolution (AMD: higher = better; NVIDIA: lower = better)
- **A&N GPU support**: Choose encoder with `--gpu amd` (default) or `--gpu nvidia`, using `av1_amf` or `av1_nvenc` respectively
- **Disk space monitoring**: Triggers cleanup when free space drops below 500MB; in low-space mode, files are sorted by size (smallest first) to minimize temporary disk usage
- **Loop mode**: `--loop` scans for new files indefinitely; wait time doubles when no new files are found (up to 1024 minutes), press any key to start the next loop immediately
- **Batch processing**: `--batch-size` controls the number of files processed in parallel
- **Preview mode**: `--preview` prints the commands that would be run without executing them
- **Cleanup recoded files**: `--cleanup-recoded` deletes existing recoded files (only if the original file still exists)
- **Sort order**: `--sort` supports sorting by name, modification time, or file size (default: size)
- **Windows PATH auto-refresh**: Automatically reads the latest PATH from the Windows registry each loop, so newly installed ffmpeg is picked up without restart

## Command-Line Arguments

| Argument | Short | Default | Description |
|----------|-------|---------|-------------|
| `--preview` | `-p` | false | Preview mode, print commands without executing |
| `--cleanup-recoded` | `-cl` | false | Delete existing recoded files at the end of each loop |
| `--include` | `-i` | "" | Only process files whose name contains this pattern |
| `--dir` | `-wd` | "." | Working directory |
| `--types` | `-t` | "flv,ts,mp4" | Input file extensions (comma-separated) |
| `--gpu` | | "amd" | GPU encoder: amd or nvidia |
| `--cq` | `-q` | auto | Fixed CQ value (AMD: 1-51 higher=better; NVIDIA: inverse) |
| `--fps` | `-f` | auto | Fixed frame rate |
| `--all` | `-a` | "n" | Process all files regardless of size |
| `--delete` | `-de` | "y" | Delete original on successful compression |
| `--ratio` | `-r` | 0.7 | Compression ratio threshold for success |
| `--sort` | `-s` | "size" | Sort order: name / time / size |
| `--batch-size` | `-b` | 1 | Number of files to process in parallel |
| `--loop` | `-l` | false | Indefinite loop mode |
| `--verbose` | `-v` | false | Output logs for skipped files |
| `--yes` | `-y` | false | Skip deletion confirmation prompts |

## Usage Examples

```powershell
# Basic usage: process current directory
python ffrecode-subtitles.py

# Specify directory and file types
python ffrecode-subtitles.py --dir d:\path\to\videos --types flv,mp4

# Preview mode (dry run)
python ffrecode-subtitles.py --preview

# Loop mode (wait time auto-increases when no new files)
python ffrecode-subtitles.py --loop

# Fixed CQ and FPS
python ffrecode-subtitles.py --cq 8 --fps 30

# Process 4 files in parallel
python ffrecode-subtitles.py --batch-size 4

# Use NVIDIA GPU encoder
python ffrecode-subtitles.py --gpu nvidia --cq 30

# Sort by modification time, only process files containing "lecture"
python ffrecode-subtitles.py --sort time --include lecture

# Loop mode with automatic cleanup of old recoded files
python ffrecode-subtitles.py --loop --cleanup-recoded --yes
```

## Others

Requires a GPU with AV1 hardware encoding support and up-to-date drivers. ffmpeg and ffprobe must be installed and available in PATH.
