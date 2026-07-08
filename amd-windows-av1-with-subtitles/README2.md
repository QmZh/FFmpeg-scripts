### <div align="right">[中文说明](README.md)</div>

A Python script that combines subtitle extraction with AMD AV1 hardware-accelerated batch recoding.

## Notes

- AMD 780M integrated graphics (and GPUs on the same architecture) have a resolution issue when using `av1_amf` to encode AV1 videos — for example, a 1920×1080 video will be encoded as 1920×1082. There is likely no workaround other than waiting for the next generation of GPUs to fix this bug. Additionally, encoding Twitch 160p videos always fails; only 360p and above can be encoded successfully.

- In `--preview` mode, `--cleanup-recoded` still takes effect and will delete existing recoded files whose originals still exist.

- The CQ variable names and recoded filename matching rules in the script are kept consistent with previous scripts for compatibility. However, for AMD's `av1_amf` encoder, a **higher** `qvbr_quality_level` means **better** video quality. The script sets lower quality for higher resolutions with the goal of keeping on-screen text readable while achieving good compression — adjust as needed.

## Purpose

[ffrecode-subtitles.py](ffrecode-subtitles.py) recursively scans a specified folder for video files (default: flv, ts, mp4), and for each video:
1. Extracts subtitles (including embedded Closed Captions) and saves them as .ssa files
2. Uses ffprobe to gather video metadata (resolution, bitrate, duration, etc.)
3. Auto-calculates CQ value based on resolution (or use a manual value), then recodes using the AV1 AMF encoder with hardware acceleration
4. Verifies the recoded video (duration check, bitrate check), and optionally deletes the original file on success

## Features

- **Subtitle extraction**: Uses ffmpeg's lavfi movie filter with the +subcc flag to extract both separate subtitle streams and embedded Closed Captions, saved as .ssa
- **Auto CQ**: Automatically selects qvbr_quality_level based on the shorter side of the resolution (range 2–15, higher value = lower quality but smaller file)
- **Disk space monitoring**: Triggers cleanup when free space drops below 500MB; in low-space mode, files are sorted by size (smallest first) to minimize temporary disk usage
- **Loop mode**: `--loop` scans for new files every 60 seconds indefinitely, suitable for continuous download scenarios
- **Batch processing**: `--batch-size` controls the number of files processed in parallel
- **Preview mode**: `--preview` prints the commands that would be run without executing them
- **Cleanup recoded files**: `--cleanup-recoded` deletes existing recoded files (only if the original file still exists)

## Usage Examples

```bash
# Basic usage: process current directory
python fffrecode-subtitles.py

# Specify directory and file types
python fffrecode-subtitles.py --dir d:\path\to\videos --types flv,mp4

# Preview mode (dry run)
python fffrecode-subtitles.py --preview

# Loop mode, scan for new files every 60 seconds
python fffrecode-subtitles.py --loop

# Fixed CQ and FPS
python fffrecode-subtitles.py --cq 8 --fps 30

# Process 4 files in parallel
python fffrecode-subtitles.py --batch-size 4
```

## Others

Requires an AMD GPU with up-to-date drivers to support the av1_amf encoder. ffmpeg and ffprobe must be installed and available in PATH.

Similar to the PowerShell scripts in [batch recode](batch-recode-ps1-bat-批量转码压缩/README2.md), but this is a pure Python implementation with added subtitle extraction and uses the AMD encoder instead of Nvidia's.
