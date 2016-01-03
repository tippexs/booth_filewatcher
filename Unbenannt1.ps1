
$ErrorActionPreference = "Continue";

[xml]$configuration = Get-Content C:\bind\watcher\fwatch.conf.xml
foreach($conf in $configuration.configuration) {
    $watchPath = $conf.watchPath
    $watchFilter = $conf.watchFile
    $loggerPath  = $conf.loggerPath
    $imgMagick   = $conf.imageMagick
    $imgHeight   = $conf.ThumbHeight
    $imgWidth    = $conf.ThumbWidth
    $WEBdirThumb = $conf.WEBImgPathThumb
    $WEBdirOrig  = $conf.WEBImgPathOrig
    $Subdir      = $conf.Subdir
    
}

# In the following line, you can change 'IncludeSubdirectories to $true if required.                          
$fsw = New-Object IO.FileSystemWatcher $watchPath, $watchFilter -Property @{IncludeSubdirectories = $Subdir; NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'}
Register-ObjectEvent $fsw Created -SourceIdentifier FilewatchCreated -Action {

$name = $Event.SourceEventArgs.Name
$changeType = $Event.SourceEventArgs.ChangeType
$timeStamp = $Event.TimeGenerated
Out-File -FilePath $loggerPath -Append -InputObject "File '$name' $changeType at $timeStamp"

try{
#send file
Start-Sleep -s 2
$fullPath = '"'+$watchPath +'\' + $name + '"'
$thumbFormat = 'jpg '
$AllArgs_thumbs = @('-format ' + $thumbFormat + '-path  ' + $WEBdirThumb + '  -thumbnail  ' + $imgHeight + 'x' + $imgWidth + '  "'+$watchPath + '\' +  $name +'"' )
$AllArgs_origs  = @('-format ' + $thumbFormat + '-path  ' + $WEBdirOrig + '  -thumbnail  ' + '1600x16000  ' + '  "'+$watchPath + '\' +  $name +'"' )
Out-File -FilePath $loggerPath -Append -InputObject "Start processing file: '$name'"
Start-Process -FilePath "mogrify.exe" -ArgumentList $AllArgs_thumbs -NoNewWindow -Wait
Start-Process -FilePath "mogrify.exe" -ArgumentList $AllArgs_origs -NoNewWindow -Wait
Out-File -FilePath $loggerPath -Append -InputObject "Image Magick Parameter string '$AllArgs_thumbs'"
Out-File -FilePath $loggerPath -Append -InputObject "Image Magick Parameter string '$AllArgs_origs'"

}
catch {Out-File -FilePath $loggerPath -Append -InputObject "failed to copy img thumb '$name' to image webservers directory"}

}

