"""既製品と試作7号の土台を紙になぞった写真(IMG_1183)から、既製品の土台の外形を取り出す。

1. 紙の四隅で写真を真上から見た形に直す(A4 として 210x297mm)
2. なぞった線の上に点を打つ(下の PRODUCT / PROTO、紙の上の mm)
3. 試作7号の線は、外形が分かっているので物差しの確かめに使う(長さ 102mm、モデルの接地面 98.5mm)
4. 紙の座標を本体の座標に直す: 紙の上(前)→ +X、紙の左(手のひら側)→ +Y
   x = 104.2 - 紙のy、y = 144 - 紙のx(前後は既製品の土台の真ん中を横の写真の値に、左右は試作の線の幅の中心に合わせた)
出力: hardware/base_outline.scad(なめらかにした外形と、x ごとの左右の端の表)、
      reference/trace/IMG_1183_sole.jpg(点を打った図)
"""
import cv2, numpy as np, sys, os
ROOT = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__))))
src = cv2.imread(os.path.join(ROOT, 'reference/mouserpad/IMG_1183_sole_trace_product_and_v7.jpg'))
corners = np.float32([[219, 256], [1272, 268], [1485, 1993], [20, 1922]])   # 紙の四隅(写真の画素)
K = 4
M = cv2.getPerspectiveTransform(corners, np.float32([[0, 0], [210 * K, 0], [210 * K, 297 * K], [0, 297 * K]]))
warp = cv2.warpPerspective(src, M, (210 * K, 297 * K))

PRODUCT = [(141, 123), (130, 128), (120, 133), (110, 137), (100, 142), (90, 149), (80, 158), (72, 168), (66, 180),
           (64, 195), (65, 207), (69, 218), (76, 226), (85, 230), (100, 231), (115, 230), (128, 227), (140, 221),
           (148, 212), (152, 200), (153, 188), (152, 175), (149, 162), (146, 148), (143, 134)]
PROTO = [(128, 120), (118, 121), (108, 128), (103, 138), (98, 150), (93, 165), (88, 180), (86, 195), (87, 206),
         (92, 214), (100, 220), (108, 222), (125, 222), (138, 218), (146, 213), (150, 205), (152, 190), (150, 170),
         (147, 152), (143, 133), (135, 122)]

# 前後の位置は、なぞった既製品の土台の真ん中を、横の写真で測った土台の真ん中(-73.6)に合わせる
# (最初は試作7号の線の先で合わせていて、既製品より約 6mm 後ろにずれていた)
def to_model(p): return (104.2 - p[1], 144 - p[0])
def chaikin(pts, n=3):
    for _ in range(n):
        q = []
        for i in range(len(pts)):
            a, b = np.array(pts[i]), np.array(pts[(i + 1) % len(pts)])
            q += [0.75 * a + 0.25 * b, 0.25 * a + 0.75 * b]
        pts = q
    return np.array(pts)

prod = chaikin([to_model(p) for p in PRODUCT])
# x ごとの左右の端(指側 ymin, 手のひら側 ymax)
xs = np.linspace(prod[:, 0].min() + 0.2, prod[:, 0].max() - 0.2, 60)
ymin, ymax = [], []
for x in xs:
    ys = []
    for i in range(len(prod)):
        a, b = prod[i], prod[(i + 1) % len(prod)]
        if (a[0] - x) * (b[0] - x) <= 0 and a[0] != b[0]:
            ys.append(a[1] + (x - a[0]) / (b[0] - a[0]) * (b[1] - a[1]))
    ymin.append(min(ys)); ymax.append(max(ys))
with open(os.path.join(ROOT, 'hardware/base_outline.scad'), 'w') as f:
    f.write('// 自動生成: reference/tools/sole_trace.py(IMG_1183 の紙になぞった既製品の土台)\n')
    f.write('base_outline_pts = [%s];\n' % ', '.join('[%.1f, %.1f]' % tuple(p) for p in prod))
    f.write('base_x_range = [%.1f, %.1f];\n' % (xs[0], xs[-1]))
    f.write('base_ymin_tab = [%s];\n' % ', '.join('[%.1f, %.1f]' % (x, y) for x, y in zip(xs, ymin)))
    f.write('base_ymax_tab = [%s];\n' % ', '.join('[%.1f, %.1f]' % (x, y) for x, y in zip(xs, ymax)))
pm = np.array([to_model(p) for p in PROTO])
print('product: x %.1f..%.1f (%.1f mm), y %.1f..%.1f (%.1f mm)' % (prod[:, 0].min(), prod[:, 0].max(), np.ptp(prod[:, 0]),
      prod[:, 1].min(), prod[:, 1].max(), np.ptp(prod[:, 1])))
print('proto  : length %.1f mm (model contact 98.5), width %.1f mm (model contact 70)' % (np.ptp(pm[:, 0]), np.ptp(pm[:, 1])))
v = warp.copy()
for pts, col in [(PRODUCT, (0, 0, 255)), (PROTO, (255, 120, 0))]:
    for p in pts: cv2.circle(v, (int(p[0] * K), int(p[1] * K)), 6, col, -1)
    cv2.polylines(v, [np.int32([(p[0] * K, p[1] * K) for p in pts])], True, col, 2)
cv2.putText(v, 'red: product  blue: prototype 7', (20, 1150), 0, 1.0, (0, 0, 0), 2)
os.makedirs(os.path.join(ROOT, 'reference/trace'), exist_ok=True)
cv2.imwrite(os.path.join(ROOT, 'reference/trace/IMG_1183_sole.jpg'), v[100 * K:245 * K, 40 * K:175 * K])
