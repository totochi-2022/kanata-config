# yamy → kanata 移行メモ

窓使いの憂鬱(yamy)の設定を [kanata](https://github.com/jtroo/kanata) へ移植した記録。
ハマった問題・原因・対策と、最終的な構成をまとめる。

- 対象環境: Windows + 日本語(JIS 106/109)キーボード
- kanata: v1.11.0（GUI版 `kanata.exe`、IOバックエンドは LLHOOK+SendInput）
- 正本にした yamy 設定: `.mayu`（キーマップ本体）+ `104on109.mayu`（JIS→US記号変換）

---

## 1. 結論（最初に読む）

| やりたいこと | 正解 | やってはいけない |
|---|---|---|
| 英数(CapsLock)→Ctrl | **レジストリの Scancode Map**（ドライバ層）で置換 | kanataで `caps lctl` すると固着する |
| JISキーボードでUS記号配列 | OSは**JISのまま**、kanata内で記号変換 | OSを101(US)に偽装する |
| IME ON/OFF | 変換/無変換キーを**そのまま**OSへ流しIME任せ | `A-grv` 等の小細工 |
| 修飾固着の対策 | 原因(CapsLock)を断つ | `windows-sync-keystates` で誤魔化す |
| ログオン時自動起動 | タスクスケジューラ＋最上位特権＋**exe直叩き** | `run_*.bat`(runas)を噛ませる |

---

## 2. ハマった問題と原因・対策

### 2-1. 英数(CapsLock)→Ctrl が「しばらくすると固着」して入力不能
- **症状**: 英数→Ctrlは効くが、使っているうちにCtrlが押しっぱなしになり、全キーが「Ctrl+◯」になって入力不能。
- **原因（デバッグログで確定）**: CapsLockはWindowsの**トグル(ロック)キー**で、**「離した」イベント(key-up)が低レベルフック(LLHOOK)に届かない**。
  - ログ実測: CapsLock `Press=10 / Release=0`、`key press LCtrl=1 / key release LCtrl=0`。
  - kanataはLCtrlを押したまま離せない。`windows-sync-keystates` も無力（kanata自身のSendInputでWindows側もCtrl押下中と認識し、ズレが検出されない）。
  - **OSレイアウト(JIS/US)とは無関係**。変換/無変換/Space等の普通のキーは `Press=Release` で正常（＝CapsLock固有の問題）。
- **対策**: 英数→Ctrlは kanata で拾わず、**Scancode Map**（`kbdclass`ドライバ層、フック/トグルの上流、USBにも有効）で `0x3A → 0x1D` に置換。kanataの `defsrc` から `caps` を削除して素通しさせる。

### 2-2. 「OSを101(US)にする」案は誤りだった
- 当初OSを101に変更して記号をUS配列に揃えようとしたが、これは間違い。
- **yamyは一度もOSを偽っていない**。109のまま、記号キーをソフトで入れ替えていた（`104on109.mayu` の `def subst`）。
- OSを101にすると、JIS固有キー（変換/無変換/¥/カタカナ/半角全角）がUS配列で行き場を失い、`HANJA`/`YEN`/`K0xB1` 等のゴミに化けて不安定化した。
- **対策**: OSはJISのまま。記号のJIS→US変換は kanata内で `(fork)` + `(unicode)` で再現（レイアウト非依存）。

### 2-3. `[ERROR] Releasing in Windows: BACKSLASH`schtasks /run /tn kanata
- **原因**: `windows-sync-keystates yes` が、tap-hold/unicode出力キー（例: `\`キー）を決定待ちの隙に誤って強制リリースしていた。
- **対策**: `windows-sync-keystates` を撤去。英数固着はScancode Mapで解決済みなので、この保険はもう不要。

### 2-4. mod0+c で日本語になる
- **原因**: nav層の `c caps` がCapsLockキーを送出するが、JISの英数/CapsLockキーはIMEの入力モード切替を兼ねるため、日本語に切り替わる。
- **対策**: `mod0+c` を撤去。

### 2-5. `.reg` / タスクXML が反映されない
- **原因**: ファイルがUTF-8だと regedit / schtasks が受け付けない。
- **対策**: **UTF-16LE + BOM** で保存する。

### 2-6. 自動起動が「うまくいってない」（旧yamyタスク）
- **原因1**: タスクの中身が `run_yamy.bat`（中で `powershell -Verb runas`）。最上位特権タスクから更にUAC昇格を要求する**二重昇格**でログオン時に失敗。
- **原因2**: `DisallowStartIfOnBatteries=true` でバッテリー駆動時に起動しない。
- **対策**: タスクの実行内容は **`kanata.exe --cfg ...kanata.kbd` を直接**指定（runasラッパー禁止）。バッテリー条件を false に。`ExecutionTimeLimit=PT0S`（無制限）。

---

## 3. 最終的なキー割り当て

### ベースレイヤ
| 物理キー | 動作 |
|---|---|
| 英数(CapsLock) | **左Ctrl**（Scancode Mapで実現。kanata管轄外） |
| Space | **SandS**（タップ=空白 / 長押し=Shift） |
| 変換 | タップ=変換(IME) / 長押し=navレイヤ |
| 無変換 | タップ=無変換(IME) / 長押し=navレイヤ |
| `:`キー | タップ=`'`/`"` / 長押し=Ctrl |
| `]`キー | タップ=`\`/`\|` / 長押し=Alt |
| 右Alt | 左クリック |
| 右Win | 中クリック |
| アプリケーションキー | 右クリック |

### 記号 JIS→US（`104on109.mayu` 相当、`fork`+`unicode`）
| 物理キー | 通常 | Shift |
|---|---|---|
| 半角/全角 | `` ` `` | `~` |
| 2 / 6 / 7 / 8 / 9 / 0 | 数字 | `@` `^` `&` `*` `(` `)` |
| `-` | `-` | `_` |
| `^`キー | `=` | `+` |
| `@`キー | `[` | `{` |
| `[`キー | `]` | `}` |
| `;`キー | `;` | `:` |

### navレイヤ（変換/無変換を押している間）
| キー | 動作 |
|---|---|
| h / j / k / l | ← / ↓ / ↑ / → |
| o / i | ウィンドウ切替 / 逆方向 |
| r | 設定リロード |
| Shift + hjkl | 範囲選択（Shift物理併用で自動的にShift+矢印） |

### 同時押し(chord)
| 入力 | 動作 |
|---|---|
| f + j（50ms以内） | Esc（navレイヤでは無効） |

---

## 4. ファイル一覧

| ファイル | 役割 |
|---|---|
| `kanata.kbd` | kanata設定本体 |
| `kanata.exe` | kanata（GUI版、常駐用） |
| `kanata_windows_tty_winIOv2_x64.exe` | TTY版（`--check`/`--debug`でログ確認用） |
| `caps_to_lctrl.reg` | 英数→LeftCtrl の Scancode Map（要再起動） |
| `caps_undo.reg` | 上記の取り消し（要再起動） |
| `kanata_task.xml` | ログオン時自動起動タスク定義 |
| `kanata.bat` | `kanata.exe --cfg kanata.kbd` 直叩き |
| `run_kanata.bat` | 手動起動用（UAC昇格して `kanata.bat` 実行） |
| `run_kanata_debug.bat` | デバッグ起動（`kanata_log.txt` に記録） |

---

## 5. 運用

### 起動 / 停止
- 自動: ログオン時にタスク `kanata` が起動。
- 手動起動: `schtasks /run /tn kanata`、または `run_kanata.bat`。
- 停止: タスクトレイのkanataアイコン → Exit、または物理キー **左Ctrl + Space + Esc**（緊急終了）。

### 設定変更後の反映
- `kanata.kbd` を編集 → kanataを再起動（**再起動不要**、プロセス再起動だけ）。
- 反映前に検証: `kanata_windows_tty_winIOv2_x64.exe --cfg kanata.kbd --check`

### トラブル時のログ取得
1. 動いているkanataを停止
2. `run_kanata_debug.bat` を実行（`kanata_log.txt` に全イベント記録）
3. 症状を再現 → 左Ctrl+Space+Esc で終了
4. `kanata_log.txt` を確認（修飾キーの press/release 数の不一致＝固着の手がかり）

### 自動起動の管理
```
schtasks /create /tn kanata /xml "C:\bin\yamy\kanata\kanata_task.xml" /f   # 登録(管理者)
schtasks /change /tn yamy /disable                                          # 旧yamy自動起動を無効化
schtasks /run /tn kanata                                                    # 即起動テスト
```

---

## 6. 残課題

- **ろ(`_`)キー → 右Shift**（`104on109.mayu` の `*ReverseSolidus = *RightShift`）: kanataのキー名が未確定。`kanata --debug` で押して名前を確認し、`defsrc` に追加して `rsft` を割り当てる。
- **¥キー**: yamyでも未変更のため素通り。必要なら後で。

---

## 7. 補足: yamy と kanata の違い（なぜ症状が逆になるか）

- **yamy** = カーネルのデバイスドライバ。生のスキャンコード（CapsLockのkey-upも）を取得できるので固着しない。一方IME制御API(`SetImeStatus`)まわりがトラブりやすかった。
- **kanata（このビルド）** = ユーザーモードのLLHOOK。トグルキー処理の上にいるためCapsLockのkey-upを取りこぼす。今回はIME制御APIを使わず変換/無変換を素通しにしたのでIME側は安定。
- ドライバ層で捕まえたいなら `kanata_windows_tty_wintercept_x64.exe`（Interceptionドライバ版）に乗り換える選択肢もある（yamyと同じ層になり、CapsLockをkanataで扱っても固着しない見込み。ただしドライバ導入が必要）。
