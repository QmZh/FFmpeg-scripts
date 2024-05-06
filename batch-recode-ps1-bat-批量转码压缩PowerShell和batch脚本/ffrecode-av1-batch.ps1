param(
    [Parameter()]

    [Alias("wd")]
    [String]$WorkingDirectory = ".",

    [Alias("t","type")]
    [String]$InputFileType = "flv",

    [Alias("q")]
    [String]$cq = "",

    [Alias("f")]
    [String]$fps = "",

    [Alias("a","all")]
    [String]$full = "",

    [Alias("de")]
    [String]$delete_origin_on_recoding = "",

    [Alias("r","cr","crt")]
    [double]$compress_ratio_threshold = 0.7
)

Write-Output "arguments are -wd/-WorkingDirectory $($WorkingDirectory) (defaults to current directory .), -t/-type/-InputFileType $($InputFileType) (defaults to flv, use * for matching any files), -q/-cq $($cq) (empty for auto deciding, provide a number between 0 and 51 for fixed cq value), -f/-fps $($fps) (empty for keeping original fps), -a/-all/-full $($full) (y to include poor quality video files that are often not worth it to recode them), -de/-delete_origin_on_recoding $($delete_origin_on_recoding) (y for deletion, will not delete if duration is shorter than 0.99 of origin, will not delete if recoded file bitrate is larger in which case the recoded file will be deleted), -r/-cr/-crt/-compress_ratio_threshold $($compress_ratio_threshold) (accepted compress ratio, under would pass)`n"


if ($cq -eq "") {
    $cq_provided = [bool]0
}
else {
    $cq_provided = [bool]1
}

Get-ChildItem $WorkingDirectory -Recurse -Filter *.$InputFileType | ForEach-Object {
    $InputFileFullPath = $_.FullName
    Write-Output "Input:"
    Write-Output $InputFileFullPath
    Write-Output "Input file size is $($_.Length)"
    if ($_.Length -lt 30000) {
        Write-Error "file too small, skipping"
        return # bruh, this means continue in ForEach-Object
    }
    # $InputFileName = Split-Path -Path $InputFileFullPath -Leaf
    # $InputFileNameWithoutExtension = $InputFileName.Split(".")[0]

    $width = [int]$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=nk=1:p=0 $InputFileFullPath)
    $height = [int]$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=nk=1:p=0 $InputFileFullPath)
    $bitrate = [int]$(ffprobe -v error -select_streams v:0 -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 -i $InputFileFullPath)
    $shorter_side = $height
    if ($width -lt $height) {
        $shorter_side = $width
    }
    if ( ($full -eq "y") -or ($shorter_side -GT 1439) -or (($shorter_side -GT 1023) -and ($bitrate -GT 1600000)) -or (($shorter_side -GT 719) -and ($bitrate -GT 1400000)) -or (($shorter_side -GT 479) -and ($bitrate -GT 1200000)) ) {
        if (!$cq_provided) {
            if ($shorter_side -lt 720) {
                # (, 720p)
                $cq = 36
            }
            elseif ($shorter_side -lt 1080) {
                # [720p, 1080p)
                $cq = 38
            }
            elseif ($shorter_side -lt 1440) {
                # [1080p, 1440p)
                $cq = 42
            }
            elseif ($shorter_side -lt 2160) {
                # [1440p, 2160p)
                $cq = 46
            }
            else {
                # [2160p, )
                $cq = 49
            }
        }

        Write-Output "Please keep an eye on fps, video duration, video quality, file size"
        Write-Output ""


        $InputFileFPS = $(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=noprint_wrappers=1:nokey=1 -i $InputFileFullPath)
        Write-Output "input file fps:"
        Write-Output $InputFileFPS

        # For VSCode: There are user settings, work space settings, (language/file type) settings, but seems no specific file settings or a block or even a line of code settings.
        # For example, I would like to disable the "powershell.codeFormatting.whitespaceAfterSeparator" VSCode powershell extension setting just for the line of code below.
        # don't format from this line changing "width,height" to "width, height" or ffmpeg won't work
        $resolution = [string]$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 -i $InputFileFullPath)
        # don't format above this line changing "width,height" to "width, height" or ffmpeg won't work

        Write-Output "resolution:"
        Write-Output $resolution
        
        $duration = [double]$(ffprobe -v error -show_entries format=duration -hide_banner -of default=noprint_wrappers=1:nokey=1 -i $InputFileFullPath)
        Write-Output "duration:"
        Write-Output $duration
        
        
        Write-Output "bitrate:"
        Write-Output $bitrate
        
        Write-Output ""
        Write-Output "Output:"
        $OutputFileFullPath = $InputFileFullPath.Split(".")[0]+"_cq-$($cq)_fps-$($fps).mp4"
        ffrecode-av1.bat $InputFileFullPath $cq $fps # ffrecode-av1.bat 应该换成一个压缩的函数？

        $new_duration = [double]$(ffprobe -v error -show_entries format=duration -hide_banner -of default=noprint_wrappers=1:nokey=1 -i $OutputFileFullPath)
        $new_bitrate = [int]$(ffprobe -v error -select_streams v:0 -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 -i $OutputFileFullPath)
        Write-Output "new duration:"
        Write-Output $new_duration
        Write-Output "new bitrate:"
        Write-Output $new_bitrate
        if (  ($new_duration -gt 0.99 * $duration) ) {
            Write-Output "new duration is above 0.99 of the original one"
            if ($new_bitrate -lt $compress_ratio_threshold * $bitrate){
                Write-Output "new bitrate is under $($compress_ratio_threshold) of the original one. Seems good"
                if ($delete_origin_on_recoding -eq "y"){
                    Write-Output "Deleting original file!"
                    Remove-Item $InputFileFullPath
                }
            }elseif ($new_bitrate -gt $bitrate){
                Write-Output "new bitrate is above the original one!"
                if ($delete_origin_on_recoding -eq "y"){
                    Write-Error "Not deleting original file!"
                }
                Write-Error "Deleting compressed file?!"
                Remove-Item $OutputFileFullPath
                
            }else {
                Write-Output "new bitrate is above $($compress_ratio_threshold) of the original one. But still a compress. Might recheck?"
                if ($delete_origin_on_recoding -eq "y"){
                    Write-Error "Not deleting original file!"
                }
            }
        }
        else {
            Write-Error "New duration not matching!"
            if ($delete_origin_on_recoding -eq "y"){
                Write-Error "Not deleting original file!"
            }
        }
        Write-Output ""
        Write-Output ""
    }else{
        Write-Error "poor quality, skipping"
        return # bruh, this means continue in ForEach-Object
    }
}
