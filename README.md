# left-hand-controller

マウスと併用する左手ゲーミングデバイスの自作プロジェクト。
アナログスティック(ホールセンサー)+ メカニカルボタンで、WASD移動をアナログスティックに置き換える。

市販品(Mouserpad v2 等)との差別化ポイント:

- **ダッシュ(Shift)は独立した物理ボタン** — スティックをどれだけ倒してもダッシュは発動しない。
  回復アイテム使用中のレレレ移動・前進でスプリントが暴発してキャンセルされる問題を設計レベルで排除
- **コンテキスト抑制** — 回復キーを押した直後の数秒間はオートダッシュを無効化(オートダッシュをオンにした場合のみ)
- **プロファイル切替** — ゲームごとのキーマップ+スティック挙動を本体フラッシュに保存。どのPCに挿しても同じ挙動
- **筐体はパラメトリック設計** — グリップ角度・ボタン位置を数値で調整して自分の手に合わせられる

## 構成

```
firmware/   Raspberry Pi Pico 用ファームウェア (CircuitPython)
  code.py     メインループ
  config.py   キーマップ・スティック挙動・プロファイル定義(編集するのは基本ここだけ)
hardware/   筐体・部品
  case.scad   パラメトリック筐体モデル (OpenSCAD)
  BOM.md      部品表
docs/
  design-notes.md   設計判断の記録(なぜこの仕様なのか)
```

## 必要なもの

| 部品 | 目安価格 | 備考 |
|---|---|---|
| Raspberry Pi Pico | ~800円 | 無印(有線)。売る前提なので無線モデルは使わない |
| ホールセンサー式スティックモジュール | 500〜1,000円 | PS4/Switch互換の補修部品。アンチドリフト |
| タクトスイッチ or メカニカルスイッチ ×14 | 500〜2,000円 | Kailh choc 推奨(薄型・打鍵感) |
| 配線・M3インサート・ネジ | ~500円 | |
| フィラメント | 試作PLA / 販売版PETG or ASA | 1台あたり100〜150g |

詳細は [hardware/BOM.md](hardware/BOM.md) を参照。

## ファームウェアのセットアップ

1. Pico に [CircuitPython](https://circuitpython.org/board/raspberry_pi_pico/) の UF2 を書き込む
   (BOOTSEL を押しながらUSB接続 → 現れたドライブに UF2 をドラッグ)
2. [Adafruit CircuitPython Bundle](https://circuitpython.org/libraries) から
   `adafruit_hid` フォルダを `CIRCUITPY/lib/` にコピー
3. `firmware/code.py` と `firmware/config.py` を `CIRCUITPY/` 直下にコピー
4. 挿し直すとUSBキーボードとして認識される

## 配線

| 信号 | Picoピン | 備考 |
|---|---|---|
| スティック X軸 | GP26 (ADC0) | |
| スティック Y軸 | GP27 (ADC1) | |
| スティック押し込み | GP11 | C キー |
| 天面ボタン 1/2/3/4 | GP2/GP3/GP4/GP5 | |
| 天面ボタン Q/E/X/F/Tab | GP6/GP7/GP8/GP9/GP10 | |
| 側面ボタン G/Space/Ctrl | GP12/GP13/GP14 | |
| **ダッシュボタン (Shift)** | GP15 | 本プロジェクトの目玉 |

ボタンは片側GND、反対側を各GPIOへ(内部プルアップ使用)。
スティックモジュールは VCC→3V3、GND→GND。

## プロファイル切替

`Tab + スティック押し込み` を1.5秒長押しで次のプロファイルへ切替(選択はフラッシュに保存)。
プロファイルの中身は `firmware/config.py` の `PROFILES` を編集。

## ライセンス

MIT(販売を見据えてクリーンに保つ。外部GPLコードは取り込まない方針)
