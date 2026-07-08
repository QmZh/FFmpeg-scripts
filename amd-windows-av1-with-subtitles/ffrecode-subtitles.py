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
        result = subprocess.run(cmd, capture_output=True, text=True, check=True, encoding='utf-8')
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

        return {
            "width": width,
            "height": height,
            "shorter_side": min(width, height),
            "bitrate": bitrate,
            "duration": duration,
            "fps": video_stream.get("avg_frame_rate", "0/0"),
            "has_separate_subs": has_separate_subs
        }
    except (subprocess.CalledProcessError, json.JSONDecodeError, StopIteration, KeyError, ValueError):
        return None


def extract_subtitles(file_path, logger):
    """
    Extracts subtitles from a video file using ffmpeg movie filter.
    Mirrors the logic from extract_subtitles.py.

    Uses the +subcc flag to ensure both separate subtitle streams and
    embedded Closed Captions (CC) are extracted.
    """
    output_path = file_path.with_suffix(".ssa")

    if output_path.exists():
        logger.info(f"Subtitle file already exists for {file_path.name}, skipping extraction.")
        return

    # POSIX path and escaping for lavfi movie filter on Windows
    escaped_path = file_path.as_posix().replace("'", r"\'").replace(":", r"\:")

    cmd = [
        "ffmpeg",
        "-n",
        "-v", "warning",
        "-f", "lavfi",
        "-i", f"movie='{escaped_path}'[out0+subcc]",
        "-map", "s",
        str(output_path)
    ]

    try:
        logger.info(f"Extracting subtitles: {file_path}")
        subprocess.run(cmd, capture_output=True, text=True, check=True, encoding='utf-8')
    except subprocess.CalledProcessError as e:
        logger.error(f"Subtitle extraction failed for {file_path}: {e.stderr}")


def calculate_cq(shorter_side):
    """Auto-calculates CQ based on shorter side resolution."""
    if shorter_side < 480: return 15
    if shorter_side < 720: return 10
    if shorter_side < 1080: return 8
    if shorter_side < 1440: return 6
    if shorter_side < 2160: return 4
    return 2


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


def recode_video(in_path, out_path, cq, fps, preview, logger, stop_event):
    """Recodes video using AV1 AMF hardware acceleration."""
    if stop_event.is_set():
        return False, False

    cmd = [
        "ffmpeg",
        "-n",
        "-i", str(in_path),
    ]

    if fps:
        cmd.extend(["-r", str(fps)])

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
        subprocess.run(cmd, capture_output=True, text=True, check=True, encoding='utf-8')
        return True, False
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

    # Action 1: Extract Subtitles
    if not args.preview:
        try:
            extract_subtitles(file_path, logger)
        except FileNotFoundError:
            logger.warning(f"File disappeared during subtitle extraction: {file_path}")
            return False, False
    else:
        logger.info(f"PREVIEW: Skipping subtitle extraction for {file_path}")

    # Action 2: Probe Metadata
    try:
        meta = get_video_metadata(file_path)
    except FileNotFoundError:
        logger.warning(f"File disappeared during metadata probe: {file_path}")
        return False, False
    if not meta:
        logger.warning(f"Could not probe metadata for {file_path}. Skipping.")
        return False, False

    # Decision: Suitability
    if not is_suitable_for_recoding(args.all, meta):
        if args.verbose:
            logger.info(f"Skipping {file_path}: Not suitable for recoding based on heuristics.")
        return False, False

    # Action 3: Determine CQ
    cq = int(args.cq) if args.cq else calculate_cq(meta["shorter_side"])

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
        success, disk_full = recode_video(file_path, out_path, cq, args.fps, args.preview, logger, stop_event)
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
    with ThreadPoolExecutor(max_workers=args.batch_size) as executor:
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

    return recoded_any, disk_full


def main():
    parser = argparse.ArgumentParser(description="Combine subtitle extraction and AV1 AMF recoding.")
    parser.add_argument("--preview", "-p", action="store_true", help="Preview mode")
    parser.add_argument("--cleanup-recoded", "-cl", action="store_true", help="Delete existing recoded files at the end of each loop")
    parser.add_argument("--include", "-i", default="", help="Include pattern")
    parser.add_argument("--dir", "-wd", default=".", help="Working directory")
    parser.add_argument("--types", "-t", default="flv,ts,mp4", help="Input file extensions (comma-separated)")
    parser.add_argument("--cq", "-q", help="Fixed qvbr_quality_level value (1-51, larger for better video quality but larger file size)")
    parser.add_argument("--fps", "-f", help="Fixed FPS")
    parser.add_argument("--all", "-a", default="n", help="Process all files regardless of size (y/n)")
    parser.add_argument("--delete", "-de", default="y", help="Delete original on success (y/n)")
    parser.add_argument("--ratio", "-r", type=float, default=0.7, help="Compression ratio threshold")
    parser.add_argument("--sort", "-s", choices=["name", "time", "size"], default="size", help="Sort order")
    parser.add_argument("--batch-size", "-b", type=int, default=1, help="Number of files to process in parallel (default: 1)")
    parser.add_argument("--loop", "-l", action="store_true", help="Loop indefinitely, scanning for new files every 60 seconds")
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
        logger.info("Process interrupted by user. Exiting...")

    logger.info(f"Finished processing. Log saved to {log_file}")


if __name__ == "__main__":
    main()
