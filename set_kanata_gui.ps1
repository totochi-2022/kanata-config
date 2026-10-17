# 置き場所はこのスクリプトのあるフォルダ（C:\bin\yamy\kanata でも C:\bin\kanata でも可）
$here = $PSScriptRoot
$a = New-ScheduledTaskAction -Execute "$here\kanata_v112_gui_winIOv2.exe" -Argument "--cfg `"$here\kanata.kbd`""
Set-ScheduledTask -TaskName 'kanata' -Action $a
