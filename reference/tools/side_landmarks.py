"""IMG_1096(左側面をテーブルの高さから撮ったもの)に、目で読み取った輪郭の点を打ち、mm に直す。

点は写真の画素座標(横 1512 × 縦 2016 の半分の大きさ、756 × 1008 で読んだ値)で書いている。
縮尺は、本体の高さ 120mm(商品ページ)を、床(y=708)から天面の一番高い角(y=92)までの長さに合わせて決めた。
奥行き方向も同じ縮尺とみなした(真横から撮っているので、遠近による誤差は小さい)。
出力: trace/IMG_1096_landmarks.jpg(写真に点と線を描いたもの)、trace/IMG_1096_landmarks.csv(mm)
座標: X は前面(3つのボタンがある面、写真の左)が 0、手首側が負。Z は床が 0。
"""
import cv2
import numpy as np

FLOOR, TOP, FRONT = 708, 92, 95
k = 120.0 / (FLOOR - TOP)   # mm / px(半分の大きさの写真で)

outline = [  # 名前, x, y(半分の大きさの写真の画素)
    ("天面の前の角", 100, 92), ("天面 1", 190, 105), ("天面 2", 300, 148), ("天面 3", 380, 195),
    ("天面 4", 450, 255), ("天面の後ろの端", 515, 325),
    ("胴体の後ろ 1", 560, 430), ("胴体の後ろ 2", 600, 520), ("胴体と土台の境(後ろ)", 615, 550),
    ("土台の上面 1", 650, 590), ("土台の上面 2", 690, 625), ("土台の後ろの先", 735, 665),
    ("土台の後ろの下", 738, 703), ("土台の前の下", 207, 700), ("土台の前の上", 212, 607),
    ("首の前と土台の境", 330, 600), ("首の前 1", 338, 540), ("首の前 2", 322, 480),
    ("頭の下 1", 290, 440), ("頭の下(一番高い所)", 240, 425), ("頭の下 2", 180, 435),
    ("頭の下 3", 130, 465), ("前面の下の角", 95, 500),
]
tabs = [("上のボタン", 225, 285), ("真ん中のボタン", 305, 365), ("下のボタン", 385, 445)]  # y の上端と下端

def mm(x, y):
    return (-(x - FRONT) * k, (FLOOR - y) * k)

im = cv2.imread("mouserpad/IMG_1096_side_left_tableheight.jpg")
im = cv2.resize(im, (756, 1008))
pts = np.array([(x, y) for _, x, y in outline], np.int32)
cv2.polylines(im, [pts], True, (0, 0, 255), 2)
for i, (name, x, y) in enumerate(outline):
    cv2.circle(im, (x, y), 4, (0, 255, 255), -1)
for name, ya, yb in tabs:
    cv2.rectangle(im, (60, ya), (95, yb), (255, 120, 0), 2)
cv2.line(im, (0, FLOOR), (756, FLOOR), (0, 200, 0), 1)
cv2.line(im, (0, TOP), (756, TOP), (0, 200, 0), 1)
cv2.imwrite("trace/IMG_1096_landmarks.jpg", im, [cv2.IMWRITE_JPEG_QUALITY, 88])

with open("trace/IMG_1096_landmarks.csv", "w") as f:
    f.write("name,x_mm,z_mm\n")
    for name, x, y in outline:
        X, Z = mm(x, y); f.write(f"{name},{X:.1f},{Z:.1f}\n")
    for name, ya, yb in tabs:
        f.write(f"{name}(上端),0,{mm(0, ya)[1]:.1f}\n{name}(下端),0,{mm(0, yb)[1]:.1f}\n")

def ang(a, b):
    (x1, y1), (x2, y2) = a, b
    return np.degrees(np.arctan2(abs(y2 - y1), abs(x2 - x1)))
print(f"縮尺 {k:.4f} mm/px")
print(f"天面の傾き(前の角→後ろの端): {ang((100,92),(515,325)):.1f}°、水平方向の長さ {(515-100)*k:.1f}mm、斜めの長さ {np.hypot(415,233)*k:.1f}mm")
print(f"胴体の後ろの傾き(垂直から): {90-ang((520,345),(610,550)):.1f}°")
print(f"奥行き(前面→土台の後ろの先): {(738-95)*k:.1f}mm")
print(f"土台: 前の端 X={mm(207,0)[0]:.1f}、厚み 前 {(700-607)*k:.1f}mm / 後ろの先 {(703-665)*k:.1f}mm")
print(f"頭の下の空間: 前面の下の角 Z={mm(95,500)[1]:.1f}、一番高い所 Z={mm(240,425)[1]:.1f} (X={mm(240,425)[0]:.1f})、首の前 X={mm(330,600)[0]:.1f}")
for name, ya, yb in tabs:
    print(f"{name}: Z {mm(0,yb)[1]:.1f}〜{mm(0,ya)[1]:.1f}mm")
