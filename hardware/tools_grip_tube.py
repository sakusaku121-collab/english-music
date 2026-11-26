"""握る所(試作10号〜): T1・T2 で決めた楕円の筒を、土台から天面まで1本でつなぐ。

- 断面: 左右 39mm × 前後 45mm の楕円(T1 で太さ 39mm、T2 で比 1.15 に決めた)
- 上下の太さの比率: 下の端 0.93 倍、真ん中 1.0、上の端 1.10(T1・T2 の筒と同じ形)
- 筒の傾き: 上へ行くほど前へ 24°(既製品の胴体の後ろの傾き、IMG_1096)
- 上の端は天面の外形へなめらかに広がって止めになる(筒の高さの上 4 割で広がる)
- 下の端は土台の継ぎ目の高さ(21mm)。土台の裾の広がりは body2.scad の土台が受け持つ
- 前面のボタンは、筒を握ったときに人差し指・中指が来る筒の前の面に置く
出力: hardware/grip_tube.scad(head_tilt 29°・35° の polyhedron と、前面の面の位置の表)
"""
import math, re, os
HERE = os.path.dirname(os.path.abspath(__file__))
txt = open(os.path.join(HERE, 'body2_measured.scad')).read()
uv = [tuple(map(float, p)) for p in re.findall(r'\[(-?[\d.]+), (-?[\d.]+)\]', txt.split('plate_outline_uv =')[1].split(';')[0])]
STICK_X = -48.1; RIM = 4; Z0 = 20.5; R3 = 0.0   # 角は球でなでずに、天面の縁をここで丸める
EDGE_R = 2.5                           # 天面の縁の上の角の丸み
W, D = 39.0, 45.0                      # 左右・前後の太さ
KB, KT = 0.93, 1.10                    # 下の端・上の端の太さの比率
LEAN = 24.0                            # 前への傾き(度)
YB = 12.0                              # 筒の下の端の左右の中心
FLARE_FROM = 0.8                       # 筒の高さのこの割合から上で天面へ広がる(試作10号の最初は 0.6。指のかかる所まで広がっていた)
NA, NL = 120, 48
BTN_Y = 5.0                            # 前面のボタンの左右の位置

def k(t): return KB * (1 - t) * (1 - 2 * t) + 4 * t * (1 - t) + KT * t * (2 * t - 1)
def smooth(t): t = min(1, max(0, t)); return t * t * (3 - 2 * t)
def chaikin(p, n=3):
    for _ in range(n):
        q = []
        for i in range(len(p)):
            a, b = p[i], p[(i + 1) % len(p)]
            q += [(0.75 * a[0] + 0.25 * b[0], 0.75 * a[1] + 0.25 * b[1]), (0.25 * a[0] + 0.75 * b[0], 0.25 * a[1] + 0.75 * b[1])]
        p = q
    return p
def offset_in(poly, d):
    n = len(poly)
    area = sum(poly[i][0] * poly[(i + 1) % n][1] - poly[(i + 1) % n][0] * poly[i][1] for i in range(n))
    s = 1 if area > 0 else -1; out = []
    for i in range(n):
        a, b, c = poly[i - 1], poly[i], poly[(i + 1) % n]
        def nrm(p, q):
            dx, dy = q[0] - p[0], q[1] - p[1]; L = math.hypot(dx, dy) or 1
            return (s * dy / L, -s * dx / L)
        n1, n2 = nrm(a, b), nrm(b, c); nx, ny = n1[0] + n2[0], n1[1] + n2[1]; L = math.hypot(nx, ny) or 1
        out.append((b[0] - d * nx / L, b[1] - d * ny / L))
    return out
def ray_hit(poly, c, ang):
    dx, dy = math.cos(ang), math.sin(ang); best = None
    for i in range(len(poly)):
        a, b = poly[i], poly[(i + 1) % len(poly)]
        ex, ey = b[0] - a[0], b[1] - a[1]; den = dx * ey - dy * ex
        if abs(den) < 1e-12: continue
        t = ((a[0] - c[0]) * ey - (a[1] - c[1]) * ex) / den
        u = ((a[0] - c[0]) * dy - (a[1] - c[1]) * dx) / den
        if t > 0 and -1e-9 <= u <= 1 + 1e-9 and (best is None or t > best): best = t
    return (c[0] + best * dx, c[1] + best * dy)

out = ['// 自動生成: hardware/tools_grip_tube.py(握る所の楕円の筒。土台の継ぎ目から天面まで)']
for tilt in (29, 35):
    tn = math.tan(math.radians(tilt)); tl = math.tan(math.radians(LEAN))
    def pz(x): return 120 - (-1 - x) * tn - RIM
    plate = offset_in(chaikin([(STICK_X + u * math.cos(math.radians(tilt)), v) for u, v in uv]), R3)
    pc = (sum(p[0] for p in plate) / len(plate), sum(p[1] for p in plate) / len(plate))
    zt = pz(pc[0]); H = zt - Z0
    xb = pc[0] - H * tl
    rings = []
    for l in range(NL + 1):
        t = l / NL; z = Z0 + t * H
        c = (xb + t * H * tl, YB + t * (pc[1] - YB))
        a = (D / 2 - R3) * k(t); b = (W / 2 - R3) * k(t)
        s = smooth((t - FLARE_FROM) / (1 - FLARE_FROM))
        ring = []
        for kk in range(NA):
            ang = 2 * math.pi * kk / NA
            r = a * b / math.sqrt((b * math.cos(ang)) ** 2 + (a * math.sin(ang)) ** 2)
            ex, ey = c[0] + r * math.cos(ang), c[1] + r * math.sin(ang)
            # 高さは点ごとに天面まで割り振る(筒の上の端が天面と同じ傾きになり、後ろで天面を突き抜けない)
            e = (ex, ey, Z0 + t * (pz(ex) - Z0))
            p = ray_hit(plate, pc, ang); p = (p[0], p[1], pz(p[0]))
            ring.append(tuple((1 - s) * e[i] + s * p[i] for i in range(3)))
        rings.append(ring)
    # 天面の縁: 外形のまま立ち上げ、上の角を 1/4 円で丸めて天面(傾いた平らな面)で閉じる
    last = rings[-1]
    def inset(p, d):
        dx, dy = p[0] - pc[0], p[1] - pc[1]; L = math.hypot(dx, dy)
        return (pc[0] + dx * (L - d) / L, pc[1] + dy * (L - d) / L)
    for j in range(1, 7):
        a_ = math.pi / 2 * j / 6
        d = EDGE_R * (1 - math.cos(a_)); h = RIM - EDGE_R + EDGE_R * math.sin(a_)
        rings.append([(q[0], q[1], pz(q[0]) + h) for q in (inset(p, d) for p in last)])   # 天面と同じ傾きの面の上に乗せる
    NLL = len(rings) - 1
    pts = [p for r in rings for p in r]
    pts.append((xb, YB, Z0)); pts.append((pc[0], pc[1], zt + RIM))
    B, T = len(pts) - 2, len(pts) - 1
    def i(l, kk): return l * NA + (kk % NA)
    faces = [f for l in range(NLL) for kk in range(NA) for f in ([i(l, kk), i(l + 1, kk), i(l + 1, kk + 1)], [i(l, kk), i(l + 1, kk + 1), i(l, kk + 1)])]
    faces += [[B, i(0, kk), i(0, kk + 1)] for kk in range(NA)] + [[T, i(NLL, kk + 1), i(NLL, kk)] for kk in range(NA)]
    # 前面の面の位置: 各高さの断面で y = BTN_Y の線と交わる一番前の x(球でなでる分 R3 を足す)
    tab = []
    for r in rings[:NL + 1]:
        xs = []
        for kk in range(NA):
            p, q = r[kk], r[(kk + 1) % NA]
            if (p[1] - BTN_Y) * (q[1] - BTN_Y) <= 0 and p[1] != q[1]:
                f = (BTN_Y - p[1]) / (q[1] - p[1])
                xs.append((p[0] + f * (q[0] - p[0]), p[2] + f * (q[2] - p[2])))
        if xs: x_, z_ = max(xs); tab.append((z_, x_ + R3))
    out.append('tube_pts_%d = [%s];' % (tilt, ', '.join('[%.2f, %.2f, %.2f]' % p for p in pts)))
    out.append('tube_faces_%d = [%s];' % (tilt, ', '.join('[%s]' % ', '.join(map(str, f)) for f in faces)))
    out.append('tube_front_x_%d = [%s];' % (tilt, ', '.join('[%.2f, %.2f]' % p for p in tab)))
    out.append('tube_bottom_%d = [%.2f, %.2f, %.2f, %.2f];' % (tilt, xb, YB, D / 2 * KB, W / 2 * KB))
    # 前面のボタンの高さの基準: 広がる前の筒の前の面の真上での天面の高さ(試しの筒の切り口の前側にあたる)
    x_tf = pc[0] + (D / 2) * KT
    out.append('tube_front_top_z_%d = %.2f;' % (tilt, pz(x_tf) + RIM))
    print(tilt, 'bottom center x %.1f, top center (%.1f, %.1f) z %.1f' % (xb, pc[0], pc[1], zt))
open(os.path.join(HERE, 'grip_tube.scad'), 'w').write('\n'.join(out) + '\n')
