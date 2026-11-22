"""真上から描いたオーナメントのイラストから、色ごとの形と線画を切り抜いて OpenSCAD の多角形に書き出す。

使い方: python3 trace_top.py <入力画像> <出力 .scad> [確認用 .png]
出力する形(すべて mm、顔の中心が原点、顔の半径 40):
  shape_disc      顔の円(当てはめた真円)
  shape_red       リボンと吊り下げ輪、赤い点(線画のすき間は埋めてある)
  shape_dark      リボンの濃い赤の部分(一段低くする)
  shape_white     白いふわふわ・髪のシュシュなど(線に囲まれた白で、ある程度大きいもの)
  shape_pink      ほっぺ・耳の内側
  shape_yellow    ボタン・星
  shape_black     顔の太い黒(目・眉・口・黒い点)
  shape_brown     塗りつぶされた髪(太いところ。ふっくら盛る)
  shape_brownline 細い髪の毛の線(低く盛る)
  shape_lines     色の塊の中にある細い線(溝にする)
  shape_facelines 顔の板の上にある細い線(髪の毛の線・耳の輪郭など。板に彫る溝にする)
"""
import sys
import numpy as np
import cv2

src, out_scad = sys.argv[1], sys.argv[2]
out_png = sys.argv[3] if len(sys.argv) > 3 else None
im = cv2.imread(src)
h, w = im.shape[:2]
hsv = cv2.cvtColor(im, cv2.COLOR_BGR2HSV).astype(np.int32)
H, S, V = hsv[..., 0], hsv[..., 1], hsv[..., 2]
sc = w / 2048   # 2048px の画像を基準にした太さの倍率


def k(n):
    n = max(3, int(round(n * sc)) | 1)
    return cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (n, n))


def u8(m):
    return (np.asarray(m) > 0).astype(np.uint8) * 255


def fill_holes(m, max_area=None):
    cnts, hier = cv2.findContours(m, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
    o = m.copy()
    if hier is None:
        return o
    for i, c in enumerate(cnts):
        if hier[0][i][3] != -1 and (max_area is None or cv2.contourArea(c) < max_area * sc * sc):
            cv2.drawContours(o, [c], -1, 255, -1)
    return o


redish = (H <= 8) | (H >= 170)
dark = u8(V < 60)                                             # 黒い線(太い線も細い線も)
brown = u8((V >= 50) & (V < 120) & (S > 35) & (S < 140) & ((H <= 25) | (H >= 165)))
red = u8(redish & (S > 140) & (V > 90))
red_dark = u8(redish & (S > 140) & (V > 90) & (V < 195))
pink = u8(redish & (S > 30) & (S <= 140) & (V > 150))
yellow = u8((H >= 15) & (H <= 32) & (S > 120) & (V > 150))
beige = u8((H >= 10) & (H <= 30) & (S > 25) & (S <= 120) & (V > 200))
light = u8((S < 22) & (V > 225))

black = fill_holes(cv2.morphologyEx(dark, cv2.MORPH_OPEN, k(9)), 300)          # 目の光(大きめの穴)は残す
brown_solid = fill_holes(cv2.morphologyEx(cv2.morphologyEx(brown, cv2.MORPH_OPEN, k(9)), cv2.MORPH_CLOSE, k(9)), 2000)
brown_solid = cv2.dilate(brown_solid, k(5))
# 太い髪(幅がだいたい 2mm 以上)と、細い髪の毛の線に分ける
brown_thick = cv2.morphologyEx(brown_solid, cv2.MORPH_OPEN, k(31))
brown_thick = cv2.bitwise_and(cv2.dilate(brown_thick, k(9)), brown_solid)
brown_line = cv2.subtract(brown_solid, brown_thick)

# 顔の円
face = cv2.morphologyEx(u8(beige | pink | yellow | black | brown_solid), cv2.MORPH_CLOSE, k(15))
cnts, _ = cv2.findContours(face, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
hull = cv2.convexHull(max(cnts, key=cv2.contourArea))
(cx, cy), (a1, a2), _ = cv2.fitEllipse(hull)
r_px = (a1 + a2) / 4
R_out = 40.0
mm = R_out / r_px

# 白: 背景とつながっていない白のうち、大きくて中心が顔の円の中にあるもの
bgfill = light.copy()
ff = np.zeros((h + 2, w + 2), np.uint8)
cv2.floodFill(bgfill, ff, (2, 2), 128)
enclosed = u8(bgfill == 255)
n, lab, st, cen = cv2.connectedComponentsWithStats(enclosed)
keep = [i for i in range(1, n)
        if st[i, cv2.CC_STAT_AREA] > 4000 * sc * sc and np.hypot(*(cen[i] - [cx, cy])) < r_px * 0.95]
white = u8(np.isin(lab, keep))
white = cv2.dilate(cv2.morphologyEx(white, cv2.MORPH_CLOSE, k(9)), k(5))   # 輪郭線の分だけ広げる

# 色の塊は輪郭線のすき間を埋めて1つにする
red_solid = fill_holes(cv2.morphologyEx(red, cv2.MORPH_CLOSE, k(11)), 20000)
pink_solid = fill_holes(cv2.dilate(cv2.morphologyEx(pink, cv2.MORPH_CLOSE, k(11)), k(5)))
yellow_solid = fill_holes(cv2.dilate(cv2.morphologyEx(yellow, cv2.MORPH_CLOSE, k(7)), k(5)))
solids = u8(red_solid | pink_solid | white | yellow_solid | brown_solid)

thin = cv2.subtract(dark, cv2.dilate(black, k(5)))   # 太い黒以外の暗い線

# 色の塊の中の線(リボンの結び目・ほっぺの斜線・お団子の線など)
inside = cv2.erode(solids, k(7))
pink_lines = u8(redish & (S > 60) & (V < 215) & (pink_solid > 0))
lines = u8(cv2.bitwise_and(cv2.dilate(thin, k(3)), inside) | cv2.bitwise_and(cv2.dilate(pink_lines, k(3)), cv2.erode(pink_solid, k(7))))

# 顔の板の上の線(髪の毛の線・耳の輪郭・あごの線など): 板の縁と、色の塊の縁の線は除く
disc_in = np.zeros((h, w), np.uint8)
cv2.circle(disc_in, (int(cx), int(cy)), int(r_px * 0.96), 255, -1)
edges = cv2.dilate(cv2.morphologyEx(solids, cv2.MORPH_GRADIENT, k(3)), k(5))
facelines = cv2.bitwise_and(thin, disc_in)
facelines = cv2.subtract(cv2.subtract(facelines, edges), cv2.dilate(solids, k(3)))

red_dark = cv2.morphologyEx(cv2.bitwise_and(red_dark, cv2.erode(red_solid, k(9))), cv2.MORPH_OPEN, k(7))

masks = {"red": red_solid, "dark": red_dark, "white": white, "pink": pink_solid, "yellow": yellow_solid,
         "black": black, "brown": brown_thick, "brownline": brown_line, "lines": lines, "facelines": facelines}
min_area = {"black": 40, "red": 80, "dark": 150, "white": 2000, "pink": 200, "yellow": 200,
            "brown": 300, "brownline": 60, "lines": 15, "facelines": 25}


def to_mm(pts):
    p = pts.reshape(-1, 2).astype(float) - [cx, cy]
    return [[round(float(x * mm), 2), round(float(-y * mm), 2)] for x, y in p]


out = [f"// 自動生成: {src.split('/')[-1]} から切り抜いた形(mm、顔の中心が原点、顔の半径 {R_out})\n",
       f"module shape_disc() circle(r = {R_out}, $fn = 180);\n"]
for name, m in masks.items():
    cnts, hier = cv2.findContours(m, cv2.RETR_CCOMP, cv2.CHAIN_APPROX_NONE)
    pts_all, paths = [], []
    if hier is not None:
        for i, c in enumerate(cnts):
            if hier[0][i][3] != -1 or cv2.contourArea(c) < min_area[name] * sc * sc:
                continue
            group = [c]
            j = hier[0][i][2]
            while j != -1:
                if cv2.contourArea(cnts[j]) > 20 * sc * sc:
                    group.append(cnts[j])
                j = hier[0][j][0]
            for g in group:
                g = cv2.approxPolyDP(g, 1.0 * sc, True)
                if len(g) < 3:
                    continue
                start = len(pts_all)
                pts_all += to_mm(g)
                paths.append(list(range(start, len(pts_all))))
    if pts_all:
        out.append(f"module shape_{name}() polygon(points = {pts_all}, paths = {paths});\n")
    else:
        out.append(f"module shape_{name}() {{}}\n")
open(out_scad, "w").write("".join(out))

if out_png:
    vis = np.full_like(im, 40)
    cols = {"red": (40, 40, 220), "white": (255, 255, 255), "pink": (180, 150, 250), "yellow": (40, 200, 240),
            "brown": (40, 70, 120), "brownline": (80, 140, 200), "dark": (20, 20, 120), "black": (0, 0, 0), "lines": (255, 0, 255),
            "facelines": (0, 255, 255)}
    for name in ["red", "white", "pink", "yellow", "brown", "brownline", "dark", "black", "lines", "facelines"]:
        vis[masks[name] > 0] = cols[name]
    cv2.circle(vis, (int(cx), int(cy)), int(r_px), (0, 255, 0), 3)
    cv2.imwrite(out_png, cv2.resize(vis, (w // 2, h // 2)))
print("circle", round(cx), round(cy), round(r_px), "mm/px", round(mm, 4))
