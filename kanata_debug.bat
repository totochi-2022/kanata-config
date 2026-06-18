@echo off
cd /d C:\bin\yamy\kanata

echo ===== 1 VERSION ===== > kanata_log.txt
kanata_windows_tty_winIOv2_x64.exe --version >> kanata_log.txt 2>&1
echo [version exitcode=%ERRORLEVEL%] >> kanata_log.txt

echo. >> kanata_log.txt
echo ===== 2 CHECK ===== >> kanata_log.txt
kanata_windows_tty_winIOv2_x64.exe --check --cfg C:\bin\yamy\kanata\kanata.kbd >> kanata_log.txt 2>&1
echo [check exitcode=%ERRORLEVEL%] >> kanata_log.txt

echo. >> kanata_log.txt
echo ===== 3 RUN press caps+a then close window ===== >> kanata_log.txt
kanata_windows_tty_winIOv2_x64.exe --debug --cfg C:\bin\yamy\kanata\kanata.kbd >> kanata_log.txt 2>&1
echo [run exitcode=%ERRORLEVEL%] >> kanata_log.txt
