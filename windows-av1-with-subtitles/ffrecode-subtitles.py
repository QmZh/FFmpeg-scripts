import argparse
import subprocess
import pathlib
import sys
import json
import logging
import os
import shutil
from datetime import datetime
import re
import time
import threading
from concurrent.futures import ThreadPoolExecutor, as_completed
try:
    import msvcrt
    import winreg
except ImportError:
    msvcrt = None
    winreg = None


def interactive_sleep(seconds):
    """Sleeps for the given seconds, but returns immediately if a key is pressed."""
    if seconds <= 0:
        return

    start_time = time.time()
    print(f"Sleeping for {seconds/60:.1f} minutes... Press any key to start next loop immediately (Ctrl+C to exit).")

    while time.time() - start_time < seconds:
        if msvcrt:
            if msvcrt.kbhit():
                # Consume the key press
                msvcrt.getch()
                return
        time.sleep(0.1)


def refresh_windows_path():
    """Updates the process PATH from the Windows Registry to pick up environment changes."""
    if winreg is None:
        return

    try:
        # System PATH
        with winreg.OpenKey(winreg.HKEY_LOCAL_MACHINE, r"System\CurrentControlSet\Control\Session Manager\Environment") as key:
            sys_path, _ = winreg.QueryValueEx(key, "Path")

        # User PATH
        with winreg.OpenKey(winreg.HKEY_CURRENT_USER, r"Environment") as key:
            user_path, _ = winreg.QueryValueEx(key, "Path")

        # Merge paths
        new_path = f"{sys_path};{user_path}"
        os.environ['PATH'] = new_path
    except Exception:
        # If registry reading fails, we keep the current process PATH
        pass


def get_free_space_mb(path):
    """Returns the free disk space in MB for the drive containing the given path."""
    try:
        total, used, free = shutil.disk_usage(str(path))
        return free / (1024 * 1024)
    except Exception:
        return None


def check_disk_space(root_dir, logger, args):
    """Checks disk space and triggers cleanup if below 500 MB."""
    free_mb = get_free_space_mb(root_dir)
    if free_mb is None:
        return False

    if free_mb < 500:
        logger.warning(f"Low disk space detected: {free_mb:.0f} MB free. Triggering cleanup...")
        cleanup_recoded_files(root_dir, logger, args, args.preview)
        return True  # Low space mode
    return False  # Normal space


def setup_logging(working_dir):
    """Sets up logging to both console and a timestamped file."""
    timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")
    log_filename = f"RecodingLog_{timestamp}.txt"
    log_path = pathlib.Path(working_dir) / log_filename

    logger = logging.getLogger("ffrecode")
    logger.setLevel(logging.INFO)

    # Console handler
    c_handler = logging.StreamHandler()
    c_format = logging.Formatter('%(message)s')
    c_handler.setFormatter(c_format)
    logger.addHandler(c_handler)

    # File handler
    f_handler = logging.FileHandler(log_path, encoding='utf-8')
    f_format = logging.Formatter('%(asctime)s - %(levelname)s - %(message)s')
    f_handler.setFormatter(f_format)
    logger.addHandler(f_handler)

    return logger, log_path


def get_video_metadata(file_path):
    """
    Uses ffprobe to get video metadata in JSON format.
    Returns a dict with width, height, shorter_side, bitrate, duration, and fps.
    """
    cmd = [
        "ffprobe",
        "-v", "quiet",
        "-print_format", "json",
        "-show_streams",
        "-show_format",
        str(file_path)
    ]
    try:
        # Use encoding='utf-8' to avoid UnicodeDecodeError on Windows (GBK)
        result = subprocess.run(cmd, capture_output=True, text=True, check=True,
                                encoding='utf-8', timeout=30)
        if result.stdout:
            data = json.loads(result.stdout)
        else:
            return None

        streams = data.get("streams", [])
        has_separate_subs = any(s.get("codec_type") == "subtitle" for s in streams)
        video_stream = next((s for s in streams if s["codec_type"] == "video"), None)
        if not video_stream:
            return None


        width = int(video_stream.get("width", 0))
        height = int(video_stream.get("height", 0))

        format_data = data.get("format", {})
        bitrate = int(format_data.get("bit_rate", 0)) if format_data.get("bit_rate") != "N/A" else 0
        duration = float(format_data.get("duration", 0))

        has_embedded_cc = check_embedded_cc(file_path)

        return {
            "width": width,
            "height": height,
            "shorter_side": min(width, height),
            "bitrate": bitrate,
            "duration": duration,
            "fps": video_stream.get("avg_frame_rate", "0/0"),
            "has_separate_subs": has_separate_subs,
            "has_embedded_cc": has_embedded_cc
        }
    except subprocess.TimeoutExpired:
        return None
    except (subprocess.CalledProcessError, json.JSONDecodeError, StopIteration, KeyError, ValueError):
        return None


_lavfi_rename_lock = threading.Lock()

# Thread-safe sets tracking files currently being written by ffmpeg.
# Used for cleanup on Ctrl+C so partial outputs are removed.
_in_progress_lock = threading.Lock()
_in_progress_subs = set()       # .ssa files mid-extraction
_in_progress_recodes = set()    # output mp4 files mid-recoding


def _needs_lavfi_workaround(path):
    """Check if a path contains characters that break FFmpeg's lavfi movie demuxer.

    The movie demuxer embeds the path inside a filtergraph string
    (movie='path'[flags]) where [, ], ', and \\ have special meaning.
    Even when escaped, some combinations are unreliable across FFmpeg versions.
    """
    name = path.name
    if any(c in name for c in ("'", "[", "]", "\\")):
        return True
    return False


# Map each lavfi-problematic character to a unique replacement so that
# two files differing only in which special character they contain
# (e.g. file' vs file[) get distinct temporary names.
_LAVFI_CHAR_MAP = {
    "'": "SingleQuote",
    "[": "OpenBracket",
    "]": "CloseBracket",
    "\\": "Backslash",
}


def _make_safe_path(file_path):
    """Create a temporary safe path in the same directory.

    Each special character is replaced with a unique identifier so that
    files like file' and file[ produce distinct temporary names.
    """
    parent = file_path.parent
    stem = file_path.stem
    for ch, repl in _LAVFI_CHAR_MAP.items():
        stem = stem.replace(ch, repl)
    return parent / f"__tmp_{stem}_{file_path.suffix}"


def check_embedded_cc(file_path):
    """Checks for embedded Closed Captions using FFmpeg lavfi subcc filter.

    If the filename contains characters that break lavfi parsing, the file is
    temporarily renamed to a safe name, processed, then renamed back.
    """
    if not _needs_lavfi_workaround(file_path):
        escaped = file_path.as_posix().replace("'", r"\'").replace(":", r"\:")
        cmd = [
            "ffmpeg",
            "-f", "lavfi",
            "-i", f"movie='{escaped}'[out0+subcc]",
            "-f", "null",
            "-"
        ]
        try:
            result = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', timeout=15)
            return "Subtitle: eia_608 (cc_dec)" in result.stderr
        except subprocess.TimeoutExpired:
            return False
        except Exception:
            return False

    # Rename to safe path, process, rename back
    safe_path = _make_safe_path(file_path)
    try:
        with _lavfi_rename_lock:
            file_path.rename(safe_path)
        try:
            escaped = safe_path.as_posix().replace("'", r"\'").replace(":", r"\:")
            cmd = [
                "ffmpeg",
                "-f", "lavfi",
                "-i", f"movie='{escaped}'[out0+subcc]",
                "-f", "null",
                "-"
            ]
            result = subprocess.run(cmd, capture_output=True, text=True, encoding='utf-8', timeout=15)
            return "Subtitle: eia_608 (cc_dec)" in result.stderr
        except subprocess.TimeoutExpired:
            return False
        except Exception:
            return False
        finally:
            with _lavfi_rename_lock:
                safe_path.rename(file_path)
    except OSError:
        return False


def extract_subtitles(file_path, logger, duration=0):
    """
    Extracts subtitles from a video file using ffmpeg lavfi movie filter.

    Uses the +subcc flag to ensure both separate subtitle streams and
    embedded Closed Captions (CC) are extracted.

    If the filename contains characters that break lavfi parsing (', [, ]),
    the file is temporarily renamed to a safe name, processed, then renamed back.
    This avoids the extra disk space a copy would require.

    duration: approximate video duration in seconds (used to set a timeout ceiling).
    """
    output_path = file_path.with_suffix(".ssa")

    if output_path.exists():
        logger.info(f"Subtitle file already exists for {file_path.name}, skipping extraction.")
        return

    logger.info(f"Extracting subtitles: {file_path}")

    # Timeout: 0.5× duration + 300 s buffer, with a floor of 300 s.
    extract_timeout = max(int(duration * 0.5) + 300, 300)

    # Track this output so Ctrl+C cleanup can remove partial files
    with _in_progress_lock:
        _in_progress_subs.add(output_path)

    try:
        if not _needs_lavfi_workaround(file_path):
            escaped = file_path.as_posix().replace("'", r"\'").replace(":", r"\:")
            cmd = [
                "ffmpeg",
                "-n",
                "-v", "warning",
                "-f", "lavfi",
                "-i", f"movie='{escaped}'[out0+subcc]",
                "-map", "s",
                str(output_path)
            ]
            try:
                subprocess.run(cmd, capture_output=True, text=True, check=True,
                               encoding='utf-8', timeout=extract_timeout)
            except subprocess.TimeoutExpired:
                logger.error(f"Subtitle extraction timed out after {extract_timeout}s for {file_path} (corrupted?).")
            except subprocess.CalledProcessError as e:
                logger.error(f"Subtitle extraction failed for {file_path}: {e.stderr}")
            return

        # Rename to safe path, process, rename back
        safe_path = _make_safe_path(file_path)
        try:
            with _lavfi_rename_lock:
                file_path.rename(safe_path)
            try:
                escaped = safe_path.as_posix().replace("'", r"\'").replace(":", r"\:")
                cmd = [
                    "ffmpeg",
                    "-n",
                    "-v", "warning",
                    "-f", "lavfi",
                    "-i", f"movie='{escaped}'[out0+subcc]",
                    "-map", "s",
                    str(output_path)
                ]
                subprocess.run(cmd, capture_output=True, text=True, check=True,
                               encoding='utf-8', timeout=extract_timeout)
            except subprocess.TimeoutExpired:
                logger.error(f"Subtitle extraction timed out after {extract_timeout}s for {file_path} (corrupted?).")
            except subprocess.CalledProcessError as e:
                logger.error(f"Subtitle extraction failed for {file_path}: {e.stderr}")
            finally:
                with _lavfi_rename_lock:
                    try:
                        safe_path.rename(file_path)
                    except OSError as exc:
                        logger.error(f"Failed to rename back {safe_path} -> {file_path}: {exc}")
        except OSError as exc:
            logger.error(f"Failed to rename {file_path} for subtitle extraction: {exc}")
    finally:
        with _in_progress_lock:
            _in_progress_subs.discard(output_path)

    # Check if the extracted subtitle file is effectively empty
    if output_path.exists() and output_path.stat().st_size <= 584:
        logger.info(f"Extracted subtitle file is empty ({output_path.stat().st_size} bytes), removing.")
        try:
            output_path.unlink()
        except (FileNotFoundError, PermissionError):
            pass


def calculate_cq(shorter_side, gpu_type="amd"):
    """Auto-calculates CQ based on shorter side resolution and GPU type.
    0 is treated as a special default quality and passed through unchanged."""
    if gpu_type == "amd":
        # AMD: 0 (default) - 51 (best)
        if shorter_side < 480: return 15
        if shorter_side < 720: return 10
        if shorter_side < 1080: return 8
        if shorter_side < 1440: return 6
        if shorter_side < 2160: return 4
        return 2

    # NVIDIA: 0 (default) - 51 (worst)
    if shorter_side < 480: return 34
    if shorter_side < 720: return 36
    if shorter_side < 1080: return 38
    if shorter_side < 1440: return 42
    if shorter_side < 2160: return 46
    return 49


def is_suitable_for_recoding(full, meta):
    """Determines if a video is worth recoding based on resolution and bitrate."""
    if full == 'y':
        return True

    ss = meta["shorter_side"]
    br = meta["bitrate"]

    # if ss > 1439: return True
    # if ss > 1023 and br > 1600000: return True
    # if ss > 719 and br > 1200000: return True
    # if ss > 479 and br > 800000: return True
    if ss > 359 and br > 30000: return True
    return False


def recode_video(in_path, out_path, cq, fps, preview, logger, stop_event, gpu_type, duration=0):
    """Recodes video using AV1 hardware acceleration (AMD or NVIDIA).

    duration: approximate video duration in seconds (used to set a timeout ceiling).
    """
    if stop_event.is_set():
        return False, False

    cmd = [
        "ffmpeg",
        "-n",
        "-i", str(in_path),
    ]

    if fps:
        cmd.extend(["-r", str(fps)])

    if gpu_type == "nvidia":
        cmd.extend([
            "-c:v", "av1_nvenc",
            "-cq", str(cq),
            "-b:v", "0",
            "-c:a", "copy",
            "-preset", "p7",
            "-multipass", "fullres",
            str(out_path)
        ])
    else:
        cmd.extend([
            "-c:v", "av1_amf",
            "-rc", "qvbr",
            "-qvbr_quality_level", str(cq),
            "-latency", "lowest_latency",
            "-c:a", "copy",
            str(out_path)
        ])

    if preview:
        logger.info(f"PREVIEW: Would execute: {' '.join(cmd)}")
        return True, False

    try:
        logger.info(f"Recoding: {in_path} -> {out_path} (CQ: {cq})")

        # Track this output so Ctrl+C cleanup can remove partial files
        with _in_progress_lock:
            _in_progress_recodes.add(out_path)
        marker = out_path.with_suffix(out_path.suffix + ".recording")
        marker.touch()

        try:
            proc = subprocess.Popen(cmd, stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, encoding='utf-8')

            # Watchdog thread: watches stop_event and kills ffmpeg if triggered,
            # so the worker doesn't block forever on proc.communicate().
            def _stop_watchdog():
                stop_event.wait()
                logger.info(f"Stop signaled while recoding {in_path}. Terminating FFmpeg...")
                proc.terminate()
                try:
                    proc.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    logger.info(f"Force-killing FFmpeg for {in_path}...")
                    proc.kill()
                    proc.wait()

            wd = threading.Thread(target=_stop_watchdog, daemon=True)
            wd.start()

            # Timeout: 2× duration + 120 s buffer (encoders can be slower than realtime),
            # with a hard floor of 600 s so short files don't expire instantly.
            communicate_timeout = max(int(duration * 2) + 120, 600)

            try:
                stdout, stderr = proc.communicate(timeout=communicate_timeout)
            except subprocess.TimeoutExpired:
                logger.error(f"Recoding timed out after {communicate_timeout}s for {in_path} (corrupted input?). Killing FFmpeg.")
                proc.kill()
                proc.wait()
                return False, False
            except KeyboardInterrupt:
                logger.info(f"Interrupted while recoding {in_path}. Terminating FFmpeg...")
                proc.terminate()
                try:
                    proc.wait(timeout=3)
                except subprocess.TimeoutExpired:
                    logger.info(f"Force-killing FFmpeg for {in_path}...")
                    proc.kill()
                    proc.wait()
                raise
            if proc.returncode != 0:
                raise subprocess.CalledProcessError(proc.returncode, cmd, output=stdout, stderr=stderr)
            return True, False
        finally:
            # Clean up tracking regardless of outcome
            with _in_progress_lock:
                _in_progress_recodes.discard(out_path)
            try:
                marker.unlink()
            except FileNotFoundError:
                pass
    except subprocess.CalledProcessError as e:
        stderr = e.stderr or ""
        if "No space left on device" in stderr or "Disk full" in stderr:
            logger.error(f"CRITICAL: Disk full detected while recoding {in_path}!")
            stop_event.set()
            return False, True
        logger.error(f"Recoding failed for {in_path}: {stderr}")
        return False, False


def confirm_deletion(file_path, yes_flag):
    """Prompts the user for confirmation before deleting a file."""
    if yes_flag:
        return True
    try:
        response = input(f"Delete {file_path}? (y/n): ").lower().strip()
        return response in ['y', 'yes']
    except EOFError:
        return False


def cleanup_recoded_files(root_dir, logger, args, preview):
    """
    Safe cleanup of recoded files.
    Only deletes recoded files if their original source file still exists.
    """
    if preview:
        logger.info("Preview mode is active, but cleanup will still be performed.")

    logger.info("Cleaning up existing recoded files...")

    # Get possible original extensions
    exts = [e.strip().lower() for e in args.types.split(",")]
    count = 0

    # Iterate over original files first for efficiency
    for ext in exts:
        # Handle extensions that might start with a dot
        glob_pattern = f"*.{ext}" if not ext.startswith(".") else f"*{ext}"
        for original_file in root_dir.rglob(glob_pattern):
            basename = original_file.stem

            # Find matching recoded files in the same directory
            # Pattern: {basename}_(cq|q|fps)-*.mp4
            recoded_pattern = re.compile(rf"^{re.escape(basename)}_(cq|q|fps)-.*\.mp4$")

            for candidate in original_file.parent.iterdir():
                if candidate.suffix.lower() == ".mp4" and recoded_pattern.match(candidate.name):
                    if confirm_deletion(candidate, args.yes):
                        try:
                            candidate.unlink()
                            logger.info(f"CLEANUP: Deleted {candidate}")
                        except (FileNotFoundError, PermissionError) as e:
                            logger.error(f"CLEANUP: Could not delete {candidate}: {e}")
                    count += 1

    if count == 0:
        logger.info("No recoded files found for existing originals.")
    else:
        logger.info(f"Cleaned up {count} recoded files.")


def cleanup_interrupted_files(root_dir, logger):
    """Clean up artifacts left behind by interrupted ffmpeg processes.

    On Ctrl+C, ffmpeg workers may be killed mid-write.  This function:
    - renames __tmp_* files back to their original names (lavfi workaround),
    - deletes partial subtitle files (.ssa) that were mid-extraction,
    - deletes partial recoded video files and their .recording marker files.
    """
    cleaned = 0

    # 1) Rename __tmp_* files back to their original names
    for tmp_file in root_dir.rglob("__tmp_*"):
        if not tmp_file.is_file():
            continue
        # Reverse the naming: __tmp_{stem}_{suffix} -> {stem}{suffix}
        name = tmp_file.name
        if name.startswith("__tmp_") and "_" in name[6:]:
            restored = name[6:]  # strip "__tmp_"
            restored_path = tmp_file.parent / restored
            try:
                tmp_file.rename(restored_path)
                logger.info(f"CLEANUP: Restored {tmp_file.name} -> {restored_path.name}")
                cleaned += 1
            except OSError as e:
                logger.error(f"CLEANUP: Failed to restore {tmp_file}: {e}")

    # 2) Delete partial subtitle files tracked during extraction
    with _in_progress_lock:
        for sub_path in list(_in_progress_subs):
            if sub_path.exists():
                try:
                    sub_path.unlink()
                    logger.info(f"CLEANUP: Removed partial subtitle {sub_path.name}")
                    cleaned += 1
                except OSError as e:
                    logger.error(f"CLEANUP: Failed to remove {sub_path}: {e}")
            _in_progress_subs.discard(sub_path)

    # 3) Delete partial recoded files tracked during recoding
    with _in_progress_lock:
        for rec_path in list(_in_progress_recodes):
            marker = rec_path.with_suffix(rec_path.suffix + ".recording")
            removed = False
            if marker.exists():
                try:
                    marker.unlink()
                    removed = True
                except OSError:
                    pass
            if rec_path.exists() and removed:
                try:
                    rec_path.unlink()
                    logger.info(f"CLEANUP: Removed partial recoded file {rec_path.name}")
                    cleaned += 1
                except OSError as e:
                    logger.error(f"CLEANUP: Failed to remove {rec_path}: {e}")
            _in_progress_recodes.discard(rec_path)

    if cleaned:
        logger.info(f"CLEANUP: Removed {cleaned} interrupted artifact(s).")
    else:
        logger.info("CLEANUP: No interrupted artifacts found.")


def process_single_file(file_path, args, logger, stop_event):
    """Processes a single video file: extract subtitles, probe, and recode if suitable."""
    if stop_event.is_set():
        return False, False

    try:
        basename = file_path.stem
    except FileNotFoundError:
        logger.warning(f"File disappeared during processing: {file_path}")
        return False, False

    # Filter 1: Already processed
    if any(pat in basename for pat in ["_cq-", "_q", "_fps-"]):
        if args.verbose:
            logger.info(f"Skipping {file_path}: Already a recoded version.")
        return False, False

    # Filter 2: Include pattern
    if args.include and args.include.lower() not in basename.lower():
        if args.verbose:
            logger.info(f"Skipping {file_path}: Does not match include pattern.")
        return False, False

    # Filter 3: Size
    try:
        if args.all != 'y' and file_path.stat().st_size < 100000:
            if args.verbose:
                logger.info(f"Skipping {file_path}: File too small.")
            return False, False
    except FileNotFoundError:
        logger.warning(f"File disappeared while checking size: {file_path}")
        return False, False

    # Action 1: Probe Metadata (before subtitle extraction so we know the duration)
    try:
        meta = get_video_metadata(file_path)
    except FileNotFoundError:
        logger.warning(f"File disappeared during metadata probe: {file_path}")
        return False, False
    if not meta:
        logger.warning(f"Could not probe metadata for {file_path}. Skipping.")
        return False, False

    # Action 2: Extract Subtitles (after probe so we can use duration for timeout)
    if not args.preview:
        try:
            extract_subtitles(file_path, logger, meta["duration"])
        except FileNotFoundError:
            logger.warning(f"File disappeared during subtitle extraction: {file_path}")
            return False, False
    else:
        logger.info(f"PREVIEW: Skipping subtitle extraction for {file_path}")

    # Decision: Suitability
    if not is_suitable_for_recoding(args.all, meta):
        if args.verbose:
            logger.info(f"Skipping {file_path}: Not suitable for recoding based on heuristics.")
        return False, False

    # Action 3: Determine CQ
    cq = int(args.cq) if args.cq else calculate_cq(meta["shorter_side"], args.gpu)

    # Filter 4: Duplicate check
    existing_pattern = re.compile(rf"{re.escape(basename)}_(cq|q|fps)-.*\.mp4$")
    similar_files = [f for f in file_path.parent.iterdir() if existing_pattern.match(f.name)]

    if similar_files:
        if args.verbose:
            logger.info(f"Skipping {file_path}: Similar recoded file already exists.")
        return False, False

    # Setup Output Path
    suffix = f"_cq-{cq}"
    if args.fps:
        suffix += f"_fps-{args.fps}"
    out_path = file_path.with_name(f"{basename}{suffix}.mp4")

    # Action 4: Recode
    try:
        success, disk_full = recode_video(file_path, out_path, cq, args.fps, args.preview, logger, stop_event, args.gpu, meta["duration"])
    except FileNotFoundError:
        logger.warning(f"File disappeared during recoding: {file_path}")
        return False, False

    if disk_full:
        return False, True
    if not success or args.preview:
        return False, False

    # Action 5: Verify & Cleanup
    try:
        new_meta = get_video_metadata(out_path)
    except FileNotFoundError:
        logger.error(f"Recoded file disappeared before verification: {out_path}")
        return False, False
    if not new_meta:
        logger.error(f"Failed to probe recoded file {out_path}.")
        return False, False

    # Duration check
    if new_meta["duration"] < 0.99 * meta["duration"]:
        logger.error(f"Verification failed for {out_path}: Duration mismatch.")
        return False, False

    # Bitrate check
    old_br = meta["bitrate"]
    new_br = new_meta["bitrate"]

    if new_br < args.ratio * old_br:
        logger.info(f"Success: {out_path} compressed well.")
        if args.delete == 'y':
            logger.info(f"Deleting original: {file_path}")
            try:
                file_path.unlink()
            except FileNotFoundError:
                pass
            except PermissionError:
                logger.error(f"Permission denied: Original file {file_path} is being used by another process. Skipping deletion.")
        return True, False
    elif new_br > old_br:
        logger.error(f"Failure: Recoded file {out_path} is larger than original. Deleting recoded.")
        try:
            out_path.unlink()
        except FileNotFoundError:
            pass
        except PermissionError:
            logger.error(f"Permission denied: Recoded file {out_path} is being used by another process. Skipping deletion.")
        return False, False
    else:
        logger.warning(f"Warning: {out_path} compressed but not enough. Keeping both.")
        return True, False


def run_processing_cycle(args, root_dir, logger, low_space_mode=False):
    """A single pass of scanning and processing files. Returns (recoded_any, disk_full)."""
    exts = {("." + e.strip().lower() if not e.strip().startswith(".") else e.strip().lower())
            for e in args.types.split(",")}

    # Recursive scan
    files = []
    for file in root_dir.rglob("*"):
        if file.suffix.lower() in exts:
            files.append(file)

    if not files:
        logger.info("No matching files found.")
        return False, False

    # Sorting
    if low_space_mode:
        logger.info("Low-space mode: sorting by file size (smallest first) to minimize temporary disk usage.")
        sorted_pairs = []
        for f in files:
            try:
                sorted_pairs.append((f.stat().st_size, f))
            except FileNotFoundError:
                continue
        sorted_pairs.sort()
        files = [f for _, f in sorted_pairs]
    elif args.sort == "name":
        files.sort(key=lambda x: x.name.lower())
    elif args.sort == "time":
        sorted_pairs = []
        for f in files:
            try:
                sorted_pairs.append((f.stat().st_mtime, f))
            except FileNotFoundError:
                continue
        sorted_pairs.sort()
        files = [f for _, f in sorted_pairs]
    else:  # size
        sorted_pairs = []
        for f in files:
            try:
                sorted_pairs.append((f.stat().st_size, f))
            except FileNotFoundError:
                continue
        sorted_pairs.sort()
        files = [f for _, f in sorted_pairs]

    stop_event = threading.Event()
    recoded_any = False
    disk_full = False

    # Use ThreadPoolExecutor for batch processing
    executor = ThreadPoolExecutor(max_workers=args.batch_size)
    try:
        tasks = []
        for f in files:
            try:
                basename = f.stem
                if any(pat in basename for pat in ["_cq-", "_q", "_fps-"]): continue
                if args.include and args.include.lower() not in basename.lower(): continue
                if args.all != "y" and f.stat().st_size < 100000: continue
                tasks.append(executor.submit(process_single_file, f, args, logger, stop_event))
            except FileNotFoundError:
                continue

        try:
            for future in as_completed(tasks):
                if stop_event.is_set():
                    break
                success, df = future.result()
                if df:
                    disk_full = True
                    stop_event.set()
                    break
                if success:
                    recoded_any = True
        except Exception as e:
            logger.error(f"Unexpected error in processing pool: {e}")
    except KeyboardInterrupt:
        stop_event.set()
        executor.shutdown(wait=False, cancel_futures=True)
        raise

    executor.shutdown(wait=False, cancel_futures=True)

    return recoded_any, disk_full


def main():
    parser = argparse.ArgumentParser(description="Combine subtitle extraction and AV1 AMF recoding.")
    parser.add_argument("--preview", "-p", action="store_true", help="Preview mode")
    parser.add_argument("--cleanup-recoded", "-cl", action="store_true", help="Delete existing recoded files at the end of each loop")
    parser.add_argument("--include", "-i", default="", help="Include pattern")
    parser.add_argument("--dir", "-wd", default=".", help="Working directory")
    parser.add_argument("--types", "-t", default="flv,ts,mp4", help="Input file extensions (comma-separated)")
    parser.add_argument("--gpu", choices=["amd", "nvidia"], default="amd", help="GPU encoder to use (default: amd)")
    parser.add_argument("--cq", "-q", help="Fixed CQ value (AMD: 1-51 higher=better; NVIDIA inverts this scale)")
    parser.add_argument("--fps", "-f", help="Fixed FPS")
    parser.add_argument("--all", "-a", default="n", help="Process all files regardless of size (y/n)")
    parser.add_argument("--delete", "-de", default="y", help="Delete original on success (y/n)")
    parser.add_argument("--ratio", "-r", type=float, default=0.7, help="Compression ratio threshold")
    parser.add_argument("--sort", "-s", choices=["name", "time", "size"], default="size", help="Sort order")
    parser.add_argument("--batch-size", "-b", type=int, default=1, help="Number of files to process in parallel (default: 1)")
    parser.add_argument("--loop", "-l", action="store_true", help="Loop indefinitely")
    parser.add_argument("--verbose", "-v", action="store_true", help="Output logs for skipped files")
    parser.add_argument("--yes", "-y", action="store_true", help="Bypass confirmation prompts for deletions")

    args = parser.parse_args()
    root_dir = pathlib.Path(args.dir).resolve()

    if not root_dir.is_dir():
        print(f"Error: {root_dir} is not a directory.")
        sys.exit(1)

    logger, log_file = setup_logging(root_dir)
    logger.info(f"Starting process in {root_dir}")
    logger.info(f"Settings: types={args.types}, include={args.include}, all={args.all}, delete={args.delete}, ratio={args.ratio}")

    try:
        wait_minutes = 1
        low_space_mode = False
        while True:
            refresh_windows_path()

            if args.verbose:
                try:
                    ff_ver = subprocess.run(["ffmpeg", "-version"], capture_output=True, text=True, encoding='utf-8', timeout=10)
                    if ff_ver.returncode == 0:
                        ver_line = ff_ver.stdout.splitlines()[0]
                        logger.info(f"FFmpeg version: {ver_line}")
                except Exception as e:
                    logger.warning(f"Could not determine FFmpeg version: {e}")

            if args.cleanup_recoded:
                cleanup_recoded_files(root_dir, logger, args, args.preview)

            low_space_mode = check_disk_space(root_dir, logger, args)

            logger.info("--- Starting processing cycle ---")
            recoded_any, disk_full = run_processing_cycle(args, root_dir, logger, low_space_mode)

            if disk_full:
                logger.critical("Disk full! Stopping all processing and exiting.")
                sys.exit(1)

            if not args.loop:
                break

            if recoded_any:
                wait_minutes = 1
            else:
                wait_minutes = min(wait_minutes * 2, 1024)

            interactive_sleep(wait_minutes * 60)
    except KeyboardInterrupt:
        logger.info("Process interrupted by user. Cleaning up interrupted files...")
        cleanup_interrupted_files(root_dir, logger)
        logger.info("Exiting...")

    logger.info(f"Finished processing. Log saved to {log_file}")


if __name__ == "__main__":
    main()
