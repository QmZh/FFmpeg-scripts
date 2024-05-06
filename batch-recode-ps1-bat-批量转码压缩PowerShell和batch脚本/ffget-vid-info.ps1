param(
    [Parameter()]

    [Alias("d","wd")]
    [String]$WorkingDirectory = ".",

    [Alias("t")]
    [String]$type = "flv",

    [Alias("a","all")]
    [String]$full = ""
)

Write-Output "arguments are -d/-wd/-WorkingDirectory $WorkingDirectory (defaults to current directory), -t/-type $type (defaults to flv), -a/-all/-full $full (y to include poor quality video files)`n"

if ($type -ne "*") {
    $output_file = "$WorkingDirectory\video-info-$type.txt"
}
else {
    $output_file = "$WorkingDirectory\video-info.txt"
}


Get-ChildItem $WorkingDirectory -Recurse -Filter *.$type | ForEach-Object {
    $width = [int]$(ffprobe -v error -select_streams v:0 -show_entries stream=width -of csv=nk=1:p=0 $_.FullName)
    $height = [int]$(ffprobe -v error -select_streams v:0 -show_entries stream=height -of csv=nk=1:p=0 $_.FullName)
    $bitrate = [int]$(ffprobe -v error -select_streams v:0 -show_entries format=bit_rate -of default=noprint_wrappers=1:nokey=1 -i $_.FullName)
    $shorter_side = $height
    if ($width -lt $height) {
        $shorter_side = $width
    }
    if ( ($full -eq "y") -or ($shorter_side -GT 1439) -or (($shorter_side -GT 1023) -and ($bitrate -GT 1600000)) -or (($shorter_side -GT 719) -and ($bitrate -GT 1400000)) -or (($shorter_side -GT 479) -and ($bitrate -GT 1200000)) ) {
        Write-Output $_.FullName
    
        $fps = $(ffprobe -v error -select_streams v:0 -show_entries stream=avg_frame_rate -of default=noprint_wrappers=1:nokey=1 -i $_.FullName)
        Write-Output "fps:"
        Write-Output $fps
        # don't format from this line changing "width,height" to "width, height" or ffmpeg won't work
        $resolution = [string]$(ffprobe -v error -select_streams v:0 -show_entries stream=width,height -of csv=s=x:p=0 -i $_.FullName)
        # don't format above this line changing "width,height" to "width, height" or ffmpeg won't work
    
        Write-Output "resolution:"
        Write-Output $resolution
            
        $duration = [double]$(ffprobe -v error -show_entries format=duration -hide_banner -of default=noprint_wrappers=1:nokey=1 -i $_.FullName)
        Write-Output "duration:"
        Write-Output $duration
            
            
        Write-Output "bitrate:"
        Write-Output $bitrate
            
        Write-Output ""
        Write-Output ""
    }
    
} | Tee-Object -FilePath $output_file