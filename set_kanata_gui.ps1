$a = New-ScheduledTaskAction -Execute 'C:\bin\yamy\kanata\kanata_v112_gui_winIOv2.exe' -Argument '--cfg C:\bin\yamy\kanata\kanata.kbd'
Set-ScheduledTask -TaskName 'kanata' -Action $a
