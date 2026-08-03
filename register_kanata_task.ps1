# kanata の自動起動タスクを登録する（管理者 PowerShell で実行）。
#
#   powershell -ExecutionPolicy Bypass -File C:\bin\yamy\kanata\register_kanata_task.ps1
#
# kanata_task.xml は UserId を %%USERSID%% にしたテンプレート。実行中ユーザーの SID を
# 埋めた一時ファイルを作って schtasks に食わせ、後で消す。
# SID をリポジトリに置かないため（public repo に勤務先ドメインの識別子を出さない）と、
# 別PCでそのまま使えるようにするための仕組み。

$ErrorActionPreference = 'Stop'

$here = Split-Path -Parent $MyInvocation.MyCommand.Path
$tpl  = Join-Path $here 'kanata_task.xml'
$sid  = [System.Security.Principal.WindowsIdentity]::GetCurrent().User.Value

# schtasks は UTF-16LE+BOM の XML しか受け付けない（UTF-8 だと弾かれる）ので
# 読みも書きも Unicode(=UTF-16LE) で通す。
$tmp = Join-Path $env:TEMP 'kanata_task.generated.xml'
$xml = (Get-Content $tpl -Raw -Encoding Unicode).Replace('%%USERSID%%', $sid)
Set-Content -Path $tmp -Value $xml -Encoding Unicode -NoNewline

try {
    Write-Host "UserId = $sid で登録します"
    schtasks /create /tn kanata /xml $tmp /f
} finally {
    Remove-Item $tmp -ErrorAction SilentlyContinue
}
