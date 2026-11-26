"""握る部分(首から天面まで)を、筒のようになめらかな面で作る(試作9号〜)。

首の足元(継ぎ目の高さ)の角の丸い楕円と、天面の縁のすぐ下の天面の外形を、同じ向きの点どうしで
まっすぐ結ぶ。周りはなめらか(角なし)で、上下はまっすぐな線になる。
既製品は手のひら側の、親指の腹が当たる面がほぼ直線の斜面(IMG_1187・1188)。
ゲームパッドの握りのように、断面は丸い筒(使った人の希望)。
出力: hardware/grip_loft.scad(head_tilt 29° と 35° の polyhedron の点と面)
"""
import math, re, os
HERE = os.path.dirname(os.path.abspath(__file__))
txt = open(os.path.join(HERE, 'body2_measured.scad')).read()
uv = [tuple(map(float, p)) for p in re.findall(r'\[(-?[\d.]+), (-?[\d.]+)\]', txt.split('plate_outline_uv =')[1].split(';')[0])]
STICK_X = -48.1; RIM = 4; COLLAR = 21; R3 = 2.5
NECK_C = (-76.5, 14); NECK_H = (31.5 - R3, 22 - R3); NECK_N = 3.0   # 角の丸い楕円(超楕円)
CEN = (-62.0, 10.0); NA = 120; NL = 30

def chaikin(p, n=3):
    for _ in range(n):
        q = []
        for i in range(len(p)):
            a, b = p[i], p[(i + 1) % len(p)]
            q += [(0.75 * a[0] + 0.25 * b[0], 0.75 * a[1] + 0.25 * b[1]), (0.25 * a[0] + 0.75 * b[0], 0.25 * a[1] + 0.75 * b[1])]
        p = q
    return p

def offset_in(poly, d):
    # 外形を d だけ内へ(点ごとに、隣の辺の法線の平均方向へ)
    n = len(poly); out = []
    area = sum(poly[i][0] * poly[(i + 1) % n][1] - poly[(i + 1) % n][0] * poly[i][1] for i in range(n))
    s = 1 if area > 0 else -1
    for i in range(n):
        a, b, c = poly[i - 1], poly[i], poly[(i + 1) % n]
        def nrm(p, q):
            dx, dy = q[0] - p[0], q[1] - p[1]; L = math.hypot(dx, dy) or 1
            return (s * dy / L, -s * dx / L)   # 外向き
        n1, n2 = nrm(a, b), nrm(b, c); nx, ny = n1[0] + n2[0], n1[1] + n2[1]; L = math.hypot(nx, ny) or 1
        out.append((b[0] - d * nx / L, b[1] - d * ny / L))
    return out

def ray_hit(poly, ang):
    dx, dy = math.cos(ang), math.sin(ang); best = None
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        ex, ey = b[0] - a[0], b[1] - a[1]; den = dx * ey - dy * ex
        if abs(den) < 1e-12: continue
        t = ((a[0] - CEN[0]) * ey - (a[1] - CEN[1]) * ex) / den
        u = ((a[0] - CEN[0]) * dy - (a[1] - CEN[1]) * dx) / den
        if t > 0 and -1e-9 <= u <= 1 + 1e-9 and (best is None or t > best): best = t
    return (CEN[0] + best * dx, CEN[1] + best * dy)

def neck_pt(ang):
    c, s = math.cos(ang), math.sin(ang)
    r = (abs(c / NECK_H[0]) ** NECK_N + abs(s / NECK_H[1]) ** NECK_N) ** (-1 / NECK_N)
    # 楕円の中心から CEN 方向のずれは小さいので、角度は中心から測る
    return (NECK_C[0] + r * c, NECK_C[1] + r * s)

out = ['// 自動生成: hardware/tools_grip_loft.py(握る部分の筒。首の足元と天面の縁の下を結ぶ)']
for tilt in (29, 35):
    tn = math.tan(math.radians(tilt))
    plate = chaikin([(STICK_X + u * math.cos(math.radians(tilt)), v) for u, v in uv])
    plate = offset_in(plate, R3)
    def pz(x): return 120 - (-1 - x) * tn - RIM
    pts = []
    for l in range(NL + 1):
        t = l / NL
        for k in range(NA):
            ang = 2 * math.pi * k / NA
            a = neck_pt(ang); b = ray_hit(plate, ang)
            x = a[0] + (b[0] - a[0]) * t; y = a[1] + (b[1] - a[1]) * t
            z = COLLAR - 0.5 + (pz(b[0]) - (COLLAR - 0.5)) * t
            pts.append((x, y, z))
    pts.append((NECK_C[0], NECK_C[1], COLLAR - 0.5))
    pc = (sum(p[0] for p in pts[-NA - 1:-1]) / NA, sum(p[1] for p in pts[-NA - 1:-1]) / NA)
    pts.append((pc[0], pc[1], pz(pc[0])))
    B, T = len(pts) - 2, len(pts) - 1
    def i(l, k): return l * NA + (k % NA)
    faces = []
    for l in range(NL):
        for k in range(NA):
            faces.append([i(l, k), i(l + 1, k), i(l + 1, k + 1), i(l, k + 1)])
    for k in range(NA):
        faces.append([B, i(0, k), i(0, k + 1)])
        faces.append([T, i(NL, k + 1), i(NL, k)])
    out.append('grip_pts_%d = [%s];' % (tilt, ', '.join('[%.2f, %.2f, %.2f]' % p for p in pts)))
    out.append('grip_faces_%d = [%s];' % (tilt, ', '.join('[%s]' % ', '.join(map(str, f)) for f in faces)))
open(os.path.join(HERE, 'grip_loft.scad'), 'w').write('\n'.join(out) + '\n')
print('ok')
