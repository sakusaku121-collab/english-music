# =============================================================
# left-hand-controller 設定ファイル
# 挙動を変えたいときは基本このファイルだけを編集する。
# =============================================================
import board
from adafruit_hid.keycode import Keycode

# --- ピン割り当て -------------------------------------------------
# スティック(アナログ)
PIN_STICK_X = board.GP26  # ADC0
PIN_STICK_Y = board.GP27  # ADC1

# スティックの向き調整(組み付け方向に合わせて反転)
STICK_INVERT_X = False
STICK_INVERT_Y = True  # 多くのモジュールは上に倒すとADC値が下がる

# ボタン: 論理名 → GPIO
# 論理名はプロファイルのキーマップから参照される
BUTTON_PINS = {
    "top_1": board.GP2,
    "top_2": board.GP3,
    "top_3": board.GP4,
    "top_4": board.GP5,
    "top_q": board.GP6,
    "top_e": board.GP7,
    "top_x": board.GP8,
    "top_f": board.GP9,
    "top_tab": board.GP10,
    "stick_click": board.GP11,
    "side_g": board.GP12,
    "side_space": board.GP13,
    "side_ctrl": board.GP14,
    "dash": board.GP15,  # 独立ダッシュボタン
    # --- 市販品レビュー分析(design-notes #1, #4)対応 ---
    "top_esc": board.GP16,  # ESC物理ボタン。市販品最大の不満点
    "spare_1": board.GP17,  # 増設用。位置・キーは試作しながら決める
    "spare_2": board.GP18,  # 増設用
}

# --- プロファイル切替 ---------------------------------------------
# この2ボタンを同時に長押しすると次のプロファイルへ
PROFILE_SWITCH_COMBO = ("top_tab", "stick_click")
PROFILE_SWITCH_HOLD_SEC = 1.5

# --- プロファイル定義 ---------------------------------------------
# stick:
#   deadzone        : 中心の不感帯 (0.0-1.0)。これ未満の倒しは無視
#   release_margin  : チャタリング防止のヒステリシス幅
# auto_dash:
#   enabled          : True にするとスティックの倒し込みで Shift が乗る(市販品互換モード)
#   threshold        : オートダッシュが発動する倒し量 (0.0-1.0)。高いほど暴発しにくい
#   forward_only     : True なら前方向(上)を含むときだけ発動
#   suppress_after   : ここに挙げたボタンを押した直後はオートダッシュを無効化
#   suppress_seconds : 無効化の持続秒数(バッテ=5秒, 医療キット=8秒 に合わせて調整)
PROFILES = [
    {
        # Apex(ホライゾン運用)想定:
        # オートダッシュは切り、ダッシュは物理ボタンのみ。
        # 回復中にスティックをどう倒してもキャンセルされない。
        "name": "apex",
        "keymap": {
            "move_up": Keycode.W,
            "move_down": Keycode.S,
            "move_left": Keycode.A,
            "move_right": Keycode.D,
            "top_1": Keycode.ONE,
            "top_2": Keycode.TWO,
            "top_3": Keycode.THREE,
            "top_4": Keycode.FOUR,
            "top_q": Keycode.Q,
            "top_e": Keycode.E,
            "top_x": Keycode.X,
            "top_f": Keycode.F,
            "top_tab": Keycode.TAB,
            "stick_click": Keycode.C,
            "side_g": Keycode.G,
            "side_space": Keycode.SPACE,
            "side_ctrl": Keycode.LEFT_CONTROL,
            "dash": Keycode.LEFT_SHIFT,
            "top_esc": Keycode.ESCAPE,
            # spare_1 / spare_2 は未割当(押しても何も起きない)。
            # 使うことになったらここに追記する。
        },
        "stick": {
            "deadzone": 0.30,
            "release_margin": 0.05,
        },
        "auto_dash": {
            "enabled": False,
            "threshold": 0.95,
            "forward_only": True,
            "suppress_after": ["top_4"],  # 回復キー
            "suppress_seconds": 7.0,
        },
    },
    {
        # 市販品互換モード: オートダッシュあり(比較・検証用)。
        # ただし threshold を高めにして、回復キー後は抑制する。
        "name": "auto-dash",
        "keymap": {
            "move_up": Keycode.W,
            "move_down": Keycode.S,
            "move_left": Keycode.A,
            "move_right": Keycode.D,
            "top_1": Keycode.ONE,
            "top_2": Keycode.TWO,
            "top_3": Keycode.THREE,
            "top_4": Keycode.FOUR,
            "top_q": Keycode.Q,
            "top_e": Keycode.E,
            "top_x": Keycode.X,
            "top_f": Keycode.F,
            "top_tab": Keycode.TAB,
            "stick_click": Keycode.C,
            "side_g": Keycode.G,
            "side_space": Keycode.SPACE,
            "side_ctrl": Keycode.LEFT_CONTROL,
            "dash": Keycode.LEFT_SHIFT,
            "top_esc": Keycode.ESCAPE,
        },
        "stick": {
            "deadzone": 0.30,
            "release_margin": 0.05,
        },
        "auto_dash": {
            "enabled": True,
            "threshold": 0.92,
            "forward_only": True,
            "suppress_after": ["top_4"],
            "suppress_seconds": 7.0,
        },
    },
]
