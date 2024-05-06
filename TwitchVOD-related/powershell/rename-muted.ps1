param(
    [Parameter()]

    [Alias("d","wd")]
    [String]$WorkingDirectory = ".",

    [Alias("t","type")]
    [String]$InputFileType = "ts",
    [Alias("s1")]
    [String]$SubStringToBeReplacedFrom = "-muted",
    [Alias("s2")]
    [String]$SubStringToBeReplacedTo = ""
)

Get-ChildItem $WorkingDirectory\*.$InputFileType | Rename-Item -NewName { $_.Name -replace $SubStringToBeReplacedFrom, $SubStringToBeReplacedTo }