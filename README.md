# filewatcher

this file watcher will watch multible folders and pushs the new created files to anywhere you want.

If you want to run this script as windows service you need to download and install

http://the.powershell.zone/software/sorlov-powershell/


# file watcher for photobooth systems

If you want to use the file watcher on your photobooth system, you should use Image Magicks to render the pictures for your offline / online web galeries.

to render the image (mogrify.exe) you need to download and install Image Magick

http://www.imagemagick.org/script/index.php


# file watcher for photobooth systems with SFTP Upload to remote host

the current version of the file watcher includes the option to Upload the files directly to an SFTP Host. To configure the connection data, see the upload.conf.xml

You can create an exe file from the ps1 file and install it as a native windows service.

Use New-SelfHostedPS powershell command. Remeber to import the sorlov-powershell add on to your current powershell session with the ImportModule command and your profile.ps1 file.

IMPORTANT: The SFTP upload component uses WINScp Libs to do that. You need to link the correct path to this libs insinde the file watchers binaries.






