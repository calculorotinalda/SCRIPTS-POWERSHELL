if(![System.IO.File]::Exists('ffmpeg/bin/ffmpeg.exe')){
	break
}

Write-Host "####################################`n##  Youtube-dl Powershell script  ##`n##          by bitxo.se           ##`n####################################"   -ForegroundColor Red

$yturl = Read-Host -Prompt 'Enter YouTube URL' 
Write-Host "URL: $yturl" -ForegroundColor Red -BackgroundColor Yellow

.\youtube-dl.exe --ffmpeg-location "ffmpeg/bin" -f bestaudio --extract-audio --audio-format mp3 $yturl

PAUSE