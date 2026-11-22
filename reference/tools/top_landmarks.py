"""IMG_1092(真上から撮ったもの)に、目で読み取った天面の外形・キー・スティックの点を打ち、mm に直す。

点は 756 × 1008(写真の半分の大きさ)で読んだ画素座標。写真の上が 3つのボタンがある面(前)、左が手のひら側。
縮尺: 横からの写真(IMG_1096)で測った天面の前後の長さ(水平方向 80.8mm)を、この写真の天面の上端〜下端(y 165〜585)に合わせた。
スティックの頭の直径がこの縮尺で約19mm になり、市販のスティックの頭(約20mm)と合う。
天面は約29°傾いているので、前後方向の距離は写真では短く写る。天面に沿った距離は前後方向を 1/cos29° 倍して求めた。
出力: trace/IMG_1092_landmarks.jpg、trace/IMG_1092_landmarks.csv(mm、スティックの中心が原点、u は前、v は手のひら側)
"""
import cv2
import numpy as np

TOP_Y, BOTTOM_Y = 165, 585
k = 80.8 / (BOTTOM_Y - TOP_Y)
tilt = 29.3
stick = (410, 410)
outline = [(150, 345), (175, 290), (205, 230), (262, 165), (350, 168), (430, 180), (500, 212), (535, 260),
           (550, 320), (553, 400), (543, 480), (527, 535), (505, 558), (450, 570), (385, 585), (330, 545),
           (275, 490), (240, 440), (205, 395)]
keys = {"4": (265, 265), "3": (212, 330), "Tab": (345, 330), "F": (295, 395), "Q": (312, 470),
        "E": (385, 510), "X": (465, 495), "1": (408, 567), "2": (480, 553)}

def uv(x, y):
    return ((stick[1] - y) * k / np.cos(np.radians(tilt)), (stick[0] - x) * k)

im = cv2.resize(cv2.imread("mouserpad/IMG_1092_top_on_a4.jpg"), (756, 1008))
cv2.polylines(im, [np.array(outline, np.int32)], True, (0, 0, 255), 2)
cv2.circle(im, stick, 5, (0, 255, 0), -1)
for name, (x, y) in keys.items():
    cv2.circle(im, (x, y), 5, (0, 255, 255), -1)
    cv2.line(im, stick, (x, y), (0, 200, 255), 1)
cv2.line(im, (0, TOP_Y), (756, TOP_Y), (0, 200, 0), 1)
cv2.line(im, (0, BOTTOM_Y), (756, BOTTOM_Y), (0, 200, 0), 1)
cv2.imwrite("trace/IMG_1092_landmarks.jpg", im, [cv2.IMWRITE_JPEG_QUALITY, 88])

with open("trace/IMG_1092_landmarks.csv", "w") as f:
    f.write("name,u_mm,v_mm\n")
    for i, (x, y) in enumerate(outline):
        u, v = uv(x, y); f.write(f"outline{i},{u:.1f},{v:.1f}\n")
    for name, (x, y) in keys.items():
        u, v = uv(x, y); f.write(f"{name},{u:.1f},{v:.1f}\n")
print(f"縮尺 {k:.4f} mm/px、天面の幅(左右) {(553-150)*k:.1f}mm、スティックの頭の直径 約{100*k:.0f}mm")
for name, (x, y) in keys.items():
    u, v = uv(x, y)
    print(f"{name:>4}: 前 {u:6.1f} 手のひら側 {v:6.1f}  距離 {np.hypot(u,v):5.1f}mm  向き {np.degrees(np.arctan2(v,u)):6.1f}°")
