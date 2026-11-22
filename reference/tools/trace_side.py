"""テーブルの高さから真横に撮った写真から、黒い本体の横の輪郭を取り出す。

使い方: python3 trace_side.py <写真> <出力の接頭辞> <本体の高さ mm> [切り抜き x0,y0,x1,y1]
  暗い部分の一番大きな塊を本体とみなし、床(一番下)から一番上までの高さを <本体の高さ> として mm に直す。
  左右は写真のまま(左が写真の左)。奥行き方向の縮尺は高さと同じとみなす(遠近の補正はしていない)。
出力: <接頭辞>_overlay.jpg / <接頭辞>_profile.csv(mm、床が y=0、上が +y、左端が x=0)
"""
import sys
import numpy as np
import cv2

src, out, height_mm = sys.argv[1], sys.argv[2], float(sys.argv[3])
im = cv2.imread(src)
h, w = im.shape[:2]
x0, y0, x1, y1 = (0, 0, w, h)
if len(sys.argv) > 4:
    x0, y0, x1, y1 = [int(v) for v in sys.argv[4].split(",")]
hsv = cv2.cvtColor(im, cv2.COLOR_BGR2HSV).astype(int)
dark = (hsv[..., 2] < 75).astype(np.uint8) * 255
crop = np.zeros_like(dark); crop[y0:y1, x0:x1] = 255
dark = cv2.bitwise_and(dark, crop)
dark = cv2.morphologyEx(dark, cv2.MORPH_OPEN, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (25, 25)))
dark = cv2.morphologyEx(dark, cv2.MORPH_CLOSE, cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (25, 25)))
n, lab, st, _ = cv2.connectedComponentsWithStats(dark)
i = max(range(1, n), key=lambda j: st[j, cv2.CC_STAT_AREA])
mask = (lab == i).astype(np.uint8) * 255
cnts, _ = cv2.findContours(mask, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_NONE)
c = cv2.approxPolyDP(cnts[0], 2.0, True).reshape(-1, 2).astype(float)
bx0, by0 = c.min(0); bx1, by1 = c.max(0)
k = height_mm / (by1 - by0)
mm = np.column_stack([(c[:, 0] - bx0) * k, (by1 - c[:, 1]) * k])
np.savetxt(f"{out}_profile.csv", mm, fmt="%.1f", delimiter=",", header="x_mm,z_mm", comments="")
ov = im.copy()
cv2.polylines(ov, [c.astype(np.int32)], True, (0, 0, 255), 6)
cv2.rectangle(ov, (x0, y0), (x1, y1), (0, 200, 0), 3)
cv2.imwrite(f"{out}_overlay.jpg", cv2.resize(ov, (w // 2, h // 2)), [cv2.IMWRITE_JPEG_QUALITY, 85])
print(f"mm/px {k:.4f}  width {(bx1-bx0)*k:.1f}mm  height {(by1-by0)*k:.1f}mm  points {len(mm)}")
