# =============================================================
# left-hand-controller ファームウェア (CircuitPython / Raspberry Pi Pico)
#
# アナログスティック → WASD 8方向キー入力
# ボタン → 任意キー(config.py のプロファイルで定義)
# ダッシュは独立ボタン。オートダッシュはオプション+コンテキスト抑制付き。
# =============================================================
import math
import time

import analogio
import keypad
import microcontroller
import usb_hid
from adafruit_hid.keyboard import Keyboard

import config

# --- 初期化 -------------------------------------------------------
keyboard = Keyboard(usb_hid.devices)

stick_x = analogio.AnalogIn(config.PIN_STICK_X)
stick_y = analogio.AnalogIn(config.PIN_STICK_Y)

button_names = list(config.BUTTON_PINS.keys())
keys = keypad.Keys(
    [config.BUTTON_PINS[n] for n in button_names],
    value_when_pressed=False,  # 内部プルアップ、GNDに落として押下
    pull=True,
)

# 起動時にスティックが中立である前提でセンターを実測
# (組み立て後の個体差・ホールセンサーのオフセットを吸収する)
def read_raw():
    x = stick_x.value
    y = stick_y.value
    return x, y


def calibrate_center(samples=64):
    sx = sy = 0
    for _ in range(samples):
        x, y = read_raw()
        sx += x
        sy += y
        time.sleep(0.002)
    return sx // samples, sy // samples


CENTER_X, CENTER_Y = calibrate_center()
HALF_RANGE = 32768  # 16bit ADC の中心からの振れ幅の目安


def read_stick():
    """スティックの倒し量を (-1.0〜1.0, -1.0〜1.0) で返す。上が +y。"""
    rx, ry = read_raw()
    x = (rx - CENTER_X) / HALF_RANGE
    y = (ry - CENTER_Y) / HALF_RANGE
    if config.STICK_INVERT_X:
        x = -x
    if config.STICK_INVERT_Y:
        y = -y
    # 端で1.0を超えることがあるのでクランプ
    return max(-1.0, min(1.0, x)), max(-1.0, min(1.0, y))


# --- プロファイル管理 ---------------------------------------------
def load_profile_index():
    idx = microcontroller.nvm[0]
    if idx >= len(config.PROFILES):
        idx = 0
    return idx


def save_profile_index(idx):
    microcontroller.nvm[0] = idx


profile_index = load_profile_index()
profile = config.PROFILES[profile_index]


def blink_profile(idx):
    """プロファイル番号を LED の点滅回数で通知(Pico 内蔵LED)。"""
    try:
        import board
        import digitalio

        led = digitalio.DigitalInOut(board.LED)
        led.direction = digitalio.Direction.OUTPUT
        for _ in range(idx + 1):
            led.value = True
            time.sleep(0.12)
            led.value = False
            time.sleep(0.12)
        led.deinit()
    except Exception:
        pass  # LEDが使えない環境でも動作は継続


# --- 8方向セクター定義 --------------------------------------------
# 角度0° = 右、反時計回り。45°ごとの8セクター(境界は22.5°)
SECTOR_KEYS = [
    ("move_right",),
    ("move_right", "move_up"),
    ("move_up",),
    ("move_up", "move_left"),
    ("move_left",),
    ("move_left", "move_down"),
    ("move_down",),
    ("move_down", "move_right"),
]


def stick_direction_keys(x, y, active, cfg):
    """現在押すべき移動キーの論理名 set と、新しい active 状態を返す。

    ヒステリシス: 一度倒したと判定したら、deadzone - release_margin を
    下回るまで解除しない(境界でのチャタリング防止)。
    """
    magnitude = math.sqrt(x * x + y * y)
    press_th = cfg["deadzone"]
    release_th = cfg["deadzone"] - cfg["release_margin"]

    if active:
        if magnitude < release_th:
            return set(), False
    else:
        if magnitude < press_th:
            return set(), False

    angle = math.degrees(math.atan2(y, x))  # -180〜180
    sector = int(((angle + 22.5) % 360) // 45)
    return set(SECTOR_KEYS[sector]), True


# --- メインループ -------------------------------------------------
pressed_buttons = set()      # 押下中の物理ボタン(論理名)
pressed_move_keys = set()    # 押下中の移動キー(論理名)
stick_active = False
auto_dash_on = False
suppress_until = 0.0         # この時刻までオートダッシュ禁止
combo_since = None           # プロファイル切替コンボの押下開始時刻

blink_profile(profile_index)


def set_key(logical_name, pressed):
    """論理名 → 現プロファイルのキーコードで押下/解放。"""
    keycode = profile["keymap"].get(logical_name)
    if keycode is None:
        return
    if pressed:
        keyboard.press(keycode)
    else:
        keyboard.release(keycode)


while True:
    now = time.monotonic()

    # ---- ボタンイベント処理 ----
    event = keys.events.get()
    while event is not None:
        name = button_names[event.key_number]
        if event.pressed:
            pressed_buttons.add(name)
            set_key(name, True)
            # 回復キー等が押されたらオートダッシュを一定時間抑制
            ad = profile["auto_dash"]
            if name in ad["suppress_after"]:
                suppress_until = now + ad["suppress_seconds"]
        else:
            pressed_buttons.discard(name)
            set_key(name, False)
        event = keys.events.get()

    # ---- プロファイル切替コンボ ----
    if all(n in pressed_buttons for n in config.PROFILE_SWITCH_COMBO):
        if combo_since is None:
            combo_since = now
        elif now - combo_since >= config.PROFILE_SWITCH_HOLD_SEC:
            # 全キー解放してからプロファイルを進める
            keyboard.release_all()
            pressed_move_keys = set()
            stick_active = False
            auto_dash_on = False
            profile_index = (profile_index + 1) % len(config.PROFILES)
            profile = config.PROFILES[profile_index]
            save_profile_index(profile_index)
            blink_profile(profile_index)
            combo_since = None
    else:
        combo_since = None

    # ---- スティック → 移動キー ----
    x, y = read_stick()
    want_keys, stick_active = stick_direction_keys(
        x, y, stick_active, profile["stick"]
    )

    for name in want_keys - pressed_move_keys:
        set_key(name, True)
    for name in pressed_move_keys - want_keys:
        set_key(name, False)
    pressed_move_keys = want_keys

    # ---- オートダッシュ(オプション) ----
    ad = profile["auto_dash"]
    if ad["enabled"]:
        magnitude = math.sqrt(x * x + y * y)
        want_dash = (
            magnitude >= ad["threshold"]
            and now >= suppress_until
            and (not ad["forward_only"] or "move_up" in pressed_move_keys)
        )
        if want_dash and not auto_dash_on:
            set_key("dash", True)
            auto_dash_on = True
        elif not want_dash and auto_dash_on:
            # 物理ダッシュボタンを握っている間は離さない
            if "dash" not in pressed_buttons:
                set_key("dash", False)
            auto_dash_on = False

    time.sleep(0.001)  # ~1kHz ポーリング
