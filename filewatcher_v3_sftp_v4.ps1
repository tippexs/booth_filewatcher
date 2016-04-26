# Filewatcher V2.0 with SFTP Upload 
#    Timo Stark
#    This program is free software: you can redistribute it and/or modify
#    it under the terms of the GNU General Public License as published by
#    the Free Software Foundation, either version 3 of the License, or
#    (at your option) any later version.
#
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.
#
#    You should have received a copy of the GNU General Public License
#    along with this program.  If not, see <http://www.gnu.org/licenses/>.





# Sevice state remains RUNNING on ERROR!
$ErrorActionPreference = "Continue";

# Load watcher config --- beginn

if (Test-Path C:\bind\watcher\fwatch.conf.xml) {

[xml]$configuration = Get-Content C:\bind\watcher\fwatch.conf.xml

foreach($conf in $configuration.configuration) {

    $loggerPath  = $conf.loggerPath
    $imgMagick   = $conf.imageMagick
    $imgHeight   = $conf.ThumbHeight
    $imgWidth    = $conf.ThumbWidth
    $imgOrigPer  = $conf.OriginalPerc
    $WEBdirThumb = $conf.WEBImgPathThumb
    $WEBdirOrig  = $conf.WEBImgPathOrig

}


} else {

  Out-File -FilePath 'C:\bind\watcher\log\filewatcher_error.log' -Append -InputObject "Konfigurationsdatei nicht gefunden - Bitte prüfen Sie ob die Datei unter C:\bind\watcher\fwatch.conf.xml gespeichert wurde?!"
  Exit

}

# Load watcher config --- end

# Load SFTP config --- beginn
if (Test-Path C:\bind\watcher\upload.conf.xml) {

[xml]$sftpconf = Get-Content C:\bind\watcher\upload.conf.xml


foreach($sconf in $sftpconf.sftpupload) {
    
    $SFTPUpload      = $sconf.SFTPUpload
    $SFTPHost        = $sconf.Host
    $SFTPUser        = $sconf.User
    $SFTPPass        = $sconf.Password
    $SFTPFprint      = $sconf.Fingerprint
    $SFTPErrLog      = $sconf.ErrorLog
    $SFTPRemPath     = $sconf.RemotePath

    }

        
    try {
            # Load WinSCP .NET assembly
            Add-Type -Path "C:\bind\sftpconn\WinSCPnet.dll"
 
            # Setup session options
            $sessionOptions = New-Object WinSCP.SessionOptions -Property @{
                Protocol = [WinSCP.Protocol]::Sftp
                HostName = $SFTPHost
                UserName = $SFTPUser
                Password = $SFTPPass
                SshHostKeyFingerprint = $SFTPFprint
            } 
         }

     catch [Exception] {
         Out-File -FilePath $SFTPErrLog -Append -InputObject  $_.Exception.Message
        } 

} else {

  $SFTPUpload = "false"
  Out-File -FilePath 'C:\bind\watcher\log\filewatcher_error.log' -Append -InputObject "Konfigurationsdatei nicht gefunden - Bitte prüfen Sie ob die Datei unter C:\bind\watcher\upload.conf.xml gespeichert wurde?!"
  
}

# Load SFTP config --- end


# Load multi watcher config --- beginn

foreach($watcher in $configuration.configuration.watcher) {
    
    $watchPath   = $watcher.watchPath
    $Subdir      = $watcher.Subdir
    $watchFilter = $watcher.watchFile

    $fsw = New-Object IO.FileSystemWatcher $watchPath, $watchFilter -Property @{IncludeSubdirectories = $Subdir; NotifyFilter = [IO.NotifyFilters]'FileName, LastWrite'}

           Register-ObjectEvent $fsw Created -SourceIdentifier $watcher.id -Action {

            $name = $Event.SourceEventArgs.Name
            $path = $Event.SourceEventArgs.FullPath
            $changeType = $Event.SourceEventArgs.ChangeType
            $timeStamp = $Event.TimeGenerated
            
           # Out-File -FilePath $loggerPath -Append -InputObject "File '$name' $changeType at $timeStamp"
            $logmessage =  "File '$name' $changeType at $timeStamp"
            addLog $logmessage $loggerPath



           try{
            #send file
            Start-Sleep -s 2
            $fullPath = $path
            $thumbFormat = 'jpg '
            $AllArgs_thumbs = @('-format ' + $thumbFormat + '-path  ' + $WEBdirThumb + '  -thumbnail  ' + $imgHeight + 'x' + $imgWidth + '  "'+$path+'"' )
            $AllArgs_origs  = @('-format ' + $thumbFormat + '-path  ' + $WEBdirOrig + '  -thumbnail  ' + $imgOrigPer + '  "'+ $path +'"' )
            
           # Out-File -FilePath $loggerPath -Append -InputObject "Start processing file: '$name'"
            $logmessage =  "Start processing file: '$name'"
            addLog $logmessage $loggerPath

            Start-Process -FilePath "mogrify.exe" -ArgumentList $AllArgs_thumbs -NoNewWindow -Wait
            Start-Process -FilePath "mogrify.exe" -ArgumentList $AllArgs_origs -NoNewWindow -Wait
            
            $logmessage =  "Image Magick Parameter string '$AllArgs_thumbs'"
            addLog $logmessage $loggerPath

            $logmessage =  "Image Magick Parameter string '$AllArgs_origs'"
            addLog $logmessage $loggerPath
           # Out-File -FilePath $loggerPath -Append -InputObject "Image Magick Parameter string '$AllArgs_thumbs'"
           # Out-File -FilePath $loggerPath -Append -InputObject "Image Magick Parameter string '$AllArgs_origs'"

                   if ($SFTPUpload -eq  "true") {
                    Start-Sleep -s 2
                           try
                        { 
                           $session = New-Object WinSCP.Session
                            try
                            {
                                # Connect
                                $session.Open($sessionOptions)                
                                $localFile = $WEBdirOrig+"\"+$name
                                    #Out-File -FilePath $loggerPath -Append -InputObject "Uploading ... '$localFile'"
                                    $logmessage = "Uploading file to $SFTPHost ... '$localFile'"
                                    addLog $logmessage $loggerPath
                                    $session.PutFiles($localFile, $SFTPRemPath).Check()
                            }
                            finally
                            {
                                # Disconnect, clean up
                                $session.Dispose()
                            }

                        }
                        catch [Exception]
                        {
                            $logmessage = "Uploading file to $SFTPHost $SFTPRemPath ... '$localFile' failed! Exception message", $_.Exception.Message
                            addLog $logmessage $loggerPath
                            #Out-File -FilePath $SFTPErrLog -Append -InputObject  $_.Exception.Message
                        }

                    } #ENDIF SFTP Versand 
           }
        
               catch {
               $logmessage = "failed to copy img thumb '$name' to image webservers directory"
               addLog $logmessage $loggerPath
               #Out-File -FilePath $loggerPath -Append -InputObject "failed to copy img thumb '$name' to image webservers directory"
               }
    # Load multi watcher config --- end
          } 
            
}

# Load multi watcher config --- end

# Logger Function --- start

Function addLog {
param ($logmessage, $logpath)
$Date = Get-Date
$DateNow = $Date.ToShortDateString()
$TimeNow = $Date.ToShortTimeString()

Out-File -FilePath $logpath -Append -InputObject "$DateNow $TimeNow : $logmessage"

Write-Host $DateNow, $TimeNow $logmessage

}


# Logger Function --- end







