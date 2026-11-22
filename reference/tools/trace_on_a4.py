"""A4 の紙の上で撮った写真から、黒い本体の輪郭を取り出して mm に直す。

使い方: python3 trace_on_a4.py <写真> <出力の接頭辞> [四隅 x1,y1,x2,y2,x3,y3,x4,y4] [この x より左は無視]
  四隅は、自動で見つからないときに写真の画素座標で指定する(左上・右上・右下・左下の順)
  紙の四隅を見つけて、紙の面を 210×297mm に引き伸ばす(射影変換)。
  紙の面の上にある黒い部分(本体)の輪郭を取り出し、mm の座標で書き出す。
出力:
  <接頭辞>_overlay.jpg  元の写真に、見つけた紙の四隅(緑)と本体の輪郭(赤)を重ねたもの
  <接頭辞>_mm.png       紙の面を真上から見た図(1px = 0.5mm)に、輪郭と 10mm 方眼を描いたもの
  <接頭辞>_contour.csv  輪郭の点(mm、紙の左上が原点、右が x、下が y)
注意: 紙より高い位置にある部分は、カメラに近いぶん大きく写る。紙に接している部分ほど正確。
"""
import sys
import numpy as np
import cv2

src, out = sys.argv[1], sys.argv[2]
im = cv2.imread(src)
h, w = im.shape[:2]
hsv = cv2.cvtColor(im, cv2.COLOR_BGR2HSV).astype(int)
H, S, V = hsv[..., 0], hsv[..., 1], hsv[..., 2]

# 紙: 白っぽく、彩度が低い大きな塊。本体や手で欠けた部分は凸包で埋める
paper = ((S < 45) & (V > 128)).astype(np.uint8) * 255
paper = cv2.morphologyEx(paper, cv2.MORPH_OPEN, np.ones((15, 15), np.uint8))
cnts, _ = cv2.findContours(paper, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
big = max(cnts, key=cv2.contourArea)
hull = cv2.convexHull(big)
quad = cv2.approxPolyDP(hull, 0.02 * cv2.arcLength(hull, True), True).reshape(-1, 2)
if len(quad) != 4:
    rect = cv2.minAreaRect(hull)
    quad = cv2.boxPoints(rect)
quad = quad.astype(np.float32)
if len(sys.argv) > 3 and sys.argv[3]:
    quad = np.array([float(v) for v in sys.argv[3].split(",")], np.float32).reshape(4, 2)
ignore_x = int(sys.argv[4]) if len(sys.argv) > 4 else 0
# 並び: 左上, 右上, 右下, 左下
s = quad.sum(1); d = np.diff(quad, axis=1).ravel()
tl, br = quad[np.argmin(s)], quad[np.argmax(s)]
tr, bl = quad[np.argmin(d)], quad[np.argmax(d)]
quad = np.array([tl, tr, br, bl], np.float32)
wpx = (np.linalg.norm(tr - tl) + np.linalg.norm(br - bl)) / 2
hpx = (np.linalg.norm(bl - tl) + np.linalg.norm(br - tr)) / 2
pw, ph = (210.0, 297.0) if hpx >= wpx else (297.0, 210.0)
M = cv2.getPerspectiveTransform(quad, np.array([[0, 0], [pw, 0], [pw, ph], [0, ph]], np.float32))

# 本体: 暗い部分。紙の内側だけを見る。細いケーブルは開閉処理で消す
inside = np.zeros((h, w), np.uint8)
cv2.fillConvexPoly(inside, quad.astype(np.int32), 255)
inside = cv2.erode(inside, np.ones((15, 15), np.uint8))
inside[:, :ignore_x] = 0
skin = ((H <= 25) & (S > 40) & (V > 80)).astype(np.uint8) * 255
skin = cv2.dilate(cv2.morphologyEx(skin, cv2.MORPH_OPEN, np.ones((9, 9), np.uint8)), np.ones((25, 25), np.uint8))
dark = (V < 105).astype(np.uint8) * 255
dark = cv2.subtract(cv2.bitwise_and(dark, inside), skin)
dark = cv2.morphologyEx(dark, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (35, 35)))
dark = cv2.morphologyEx(dark, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (15, 15)))
cnts, _ = cv2.findContours(dark, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
body = max(cnts, key=cv2.contourArea)
body = cv2.approxPolyDP(body, 2.0, True)

pts_mm = cv2.perspectiveTransform(body.astype(np.float32), M).reshape(-1, 2)
np.savetxt(f"{out}_contour.csv", pts_mm, fmt="%.1f", delimiter=",", header="x_mm,y_mm", comments="")

ov = im.copy()
cv2.polylines(ov, [quad.astype(np.int32)], True, (0, 220, 0), 6)
cv2.polylines(ov, [body], True, (0, 0, 255), 6)
cv2.imwrite(f"{out}_overlay.jpg", cv2.resize(ov, (w // 2, h // 2)), [cv2.IMWRITE_JPEG_QUALITY, 85])

k = 2  # px / mm
top = cv2.warpPerspective(im, np.array([[k, 0, 0], [0, k, 0], [0, 0, 1]]) @ M, (int(pw * k), int(ph * k)))
for g in range(0, int(max(pw, ph)) + 1, 10):
    col = (200, 200, 200) if g % 50 else (150, 150, 150)
    cv2.line(top, (g * k, 0), (g * k, int(ph * k)), col, 1)
    cv2.line(top, (0, g * k), (int(pw * k), g * k), col, 1)
cv2.polylines(top, [(pts_mm * k).astype(np.int32)], True, (0, 0, 255), 2)
cv2.imwrite(f"{out}_mm.png", top)

x0, y0 = pts_mm.min(0); x1, y1 = pts_mm.max(0)
print(f"paper {pw:.0f}x{ph:.0f}mm  body bbox x {x0:.1f}..{x1:.1f} ({x1-x0:.1f}mm)  y {y0:.1f}..{y1:.1f} ({y1-y0:.1f}mm)  points {len(pts_mm)}")
