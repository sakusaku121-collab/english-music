"""真上から描いたイラストから、色ごとの形と線画を切り抜いて OpenSCAD の多角形に書き出す。

使い方: python3 trace_top.py <入力画像> <出力ディレクトリ>
出力: masks.png(確認用)と shapes.scad
  shape_disc   顔の円(当てはめた真円)
  shape_red    リボンと吊り下げ輪(線画のすき間は埋めてある)
  shape_white  白いふわふわ(大きい2つ)
  shape_pink   ほっぺ
  shape_yellow ボタン
  shape_black  顔の線と黒い点(太い線だけ。輪郭の細い線は含まない)
  shape_lines  リボン・ふわふわ・ほっぺなどの中にある細い線(彫る溝にする)
  shape_dark   リボンの濃い赤の部分(一段低くする)
"""
import sys
import numpy as np
import cv2

src, out = sys.argv[1], sys.argv[2]
im = cv2.imread(src)
h, w = im.shape[:2]
hsv = cv2.cvtColor(im, cv2.COLOR_BGR2HSV).astype(np.int32)
H, S, V = hsv[..., 0], hsv[..., 1], hsv[..., 2]

def k(n):
    return cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (n, n))

def u8(m):
    return (m > 0).astype(np.uint8) * 255

def fill_holes(m, max_area=None):
    cnts, hier = cv2.findContours(m, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
    o = m.copy()
    if hier is None:
        return o
    for i, c in enumerate(cnts):
        if hier[0][i][3] != -1 and (max_area is None or cv2.contourArea(c) < max_area):
            cv2.drawContours(o, [c], -1, 255, -1)
    return o

dark = u8(V < 90)                                   # 黒い線(太い線も細い輪郭線も)
redish = (H <= 8) | (H >= 170)
red = u8(redish & (S > 140) & (V > 90))
red_dark = u8(redish & (S > 140) & (V > 90) & (V < 195))
pink = u8(redish & (S > 30) & (S <= 140) & (V > 150))
yellow = u8((H >= 15) & (H <= 32) & (S > 120))
beige = u8((H >= 10) & (H <= 30) & (S > 25) & (S <= 120) & (V > 200))
light = u8((S < 22) & (V > 225))

# 太い黒(顔の線・目・点): 細い輪郭線を開閉処理で消す
black = cv2.morphologyEx(dark, cv2.MORPH_OPEN, k(9))
black = fill_holes(black, 300)   # 目の中の光(大きめの穴)は残す

# 顔の円
face = cv2.morphologyEx(u8(beige | pink | yellow | black), cv2.MORPH_CLOSE, k(15))
cnts, _ = cv2.findContours(face, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
hull = cv2.convexHull(max(cnts, key=cv2.contourArea))
(cx, cy), r_px = cv2.minEnclosingCircle(hull)
(ex, ey), (a1, a2), _ = cv2.fitEllipse(hull)
cx, cy, r_px = ex, ey, (a1 + a2) / 4
R_out = 40.0
mm = R_out / r_px

# 白いふわふわ: 背景とつながっていない白(輪郭線に囲まれた白)のうち大きい2つ
bgfill = light.copy()
ff = np.zeros((h + 2, w + 2), np.uint8)
cv2.floodFill(bgfill, ff, (2, 2), 128)
enclosed = u8(bgfill == 255)
n, lab, st, _ = cv2.connectedComponentsWithStats(enclosed)
keep = sorted(range(1, n), key=lambda i: -st[i, cv2.CC_STAT_AREA])[:2]
white = u8(np.isin(lab, keep))
white = cv2.morphologyEx(white, cv2.MORPH_CLOSE, k(9))
white = cv2.dilate(white, k(5))   # 輪郭線の分だけ広げる

# 色の塊は輪郭線のすき間を埋めて1つにする
red_solid = fill_holes(cv2.morphologyEx(red, cv2.MORPH_CLOSE, k(11)), 20000)
pink_solid = fill_holes(cv2.dilate(cv2.morphologyEx(pink, cv2.MORPH_CLOSE, k(11)), k(5)))
yellow_solid = fill_holes(cv2.dilate(cv2.morphologyEx(yellow, cv2.MORPH_CLOSE, k(7)), k(5)))

# 色の塊の中にある細い線(彫る溝): 暗い線のうち太い黒以外
inside = cv2.erode(u8(red_solid | pink_solid | white | yellow_solid), k(7))
lines = cv2.bitwise_and(cv2.dilate(cv2.subtract(dark, cv2.dilate(black, k(5))), k(3)), inside)
lines = u8(lines | cv2.bitwise_and(cv2.dilate(u8((S > 60) & (V < 200) & (H >= 170) | (S > 60) & (V < 200) & (H <= 8) & (pink_solid > 0)), k(3)), pink_solid))

red_dark = cv2.morphologyEx(cv2.bitwise_and(red_dark, cv2.erode(red_solid, k(9))), cv2.MORPH_OPEN, k(7))

masks = {"red": red_solid, "white": white, "pink": pink_solid, "yellow": yellow_solid,
         "black": black, "lines": lines, "dark": red_dark}

def to_mm(pts):
    p = pts.reshape(-1, 2).astype(float) - [cx, cy]
    return [[round(float(x * mm), 2), round(float(-y * mm), 2)] for x, y in p]

min_area = {"black": 40, "red": 80, "pink": 200, "yellow": 200, "white": 2000, "lines": 15, "dark": 150}
out_lines = [f"// 自動生成: {src.split('/')[-1]} から切り抜いた形(mm、顔の中心が原点、顔の半径 {R_out})\n",
             f"module shape_disc() circle(r = {R_out}, $fn = 180);\n"]
for name, m in masks.items():
    cnts, hier = cv2.findContours(m, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
    pts_all, paths = [], []
    if hier is not None:
        for i, c in enumerate(cnts):
            if hier[0][i][3] != -1 or cv2.contourArea(c) < min_area[name]:
                continue
            group = [c]
            j = hier[0][i][2]
            while j != -1:
                if cv2.contourArea(cnts[j]) > 20:
                    group.append(cnts[j])
                j = hier[0][j][0]
            for g in group:
                g = cv2.approxPolyDP(g, 1.0, True)
                if len(g) < 3:
                    continue
                start = len(pts_all)
                pts_all += to_mm(g)
                paths.append(list(range(start, len(pts_all))))
    out_lines.append(f"module shape_{name}() polygon(points = {pts_all}, paths = {paths});\n")
open(f"{out}/shapes.scad", "w").write("".join(out_lines))

vis = np.full_like(im, 40)
cols = {"red": (40, 40, 220), "white": (255, 255, 255), "pink": (180, 150, 250), "yellow": (40, 200, 240),
        "black": (0, 0, 0), "dark": (20, 20, 120), "lines": (255, 0, 255)}
for name in ["red", "white", "pink", "yellow", "dark", "black", "lines"]:
    vis[masks[name] > 0] = cols[name]
cv2.circle(vis, (int(cx), int(cy)), int(r_px), (0, 255, 0), 3)
cv2.imwrite(f"{out}/masks.png", cv2.resize(vis, (w // 2, h // 2)))
print("circle", round(cx), round(cy), round(r_px), "mm/px", round(mm, 4))
