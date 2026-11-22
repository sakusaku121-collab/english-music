// =============================================================
// 外形の定義。concept.scad と case.scad が共用する。
//
// 座標系: +X がモニター側、-X が手前(手首側)、+Y が左、Z が上。
// 握り方: 左手の手のひらを本体の左面に当てて、指先を前へ伸ばす。
// 親指は天面、人差し指・中指は前面のボタン、薬指・小指は前面下のくぼみに入る。
// 大きさと比率は Mouserpad v2(幅90×奥行125×高さ120)の写真から取った。
// 形そのものはまねず、寸法の比率だけを合わせている。
//
// 胴体は、角の丸い四角(超楕円)の断面を下から上へなめらかにつないだ1枚の曲面。
// 天面は胴体の上端を傾けて平らにし、縁を丸めている。
// =============================================================

ring_n = 72;   // 断面1周の点の数

// ---- 土台: 角の丸い楕円の板。手首側は薄くなる ----
base_x  = [-73, 53];   // 前後の範囲
base_y  = [-32, 46];   // 左右の範囲(左の手のひら側に張り出す)
base_h  = 12;          // 厚み
base_rf = 5;           // 上の縁の丸み
base_se = 2.5;         // 断面の角の丸さ(2 で楕円、大きいほど四角に近い)
function base_thin(x) = lookup(x, [[-73, 0.35], [-40, 1]]);

// ---- 胴体: [高さz, 後ろ端x, 前端x, 右端y, 左端y] ----
// 高さ 20〜30 の前端が下がっているところが、薬指・小指の入るくぼみ。
// 高さ 60 あたりが一番細いくびれで、そこから天面へ向かって広がる。
body = [
    [  8, -62, 36, -32, 38  ],
    [ 14, -57, 31, -27, 32  ],
    [ 20, -54, 29, -25, 28  ],
    [ 30, -52, 30, -24, 26  ],
    [ 38, -50, 46, -24, 26  ],
    [ 46, -48, 52, -24, 26  ],
    [ 60, -45, 52, -24, 25  ],
    [ 75, -41, 52, -26, 27  ],
    [ 88, -38, 52, -31, 30  ],
    [ 98, -35, 52, -38, 33  ],
    [106, -34, 52, -42, 33.5],
    [108.7, -34, 52, -42, 33.5],
];
function body_se(z) = lookup(z, [[60, 3], [100, 4.2]]);   // 断面の角の丸さ(天面に近いほど四角寄り)
body_step = 2;      // 輪切りの間隔
top_r     = 5;      // 天面の縁の丸み

// ---- 天面(親指を置く平らな面) ----
head_tilt = 9;                                   // 前が高くなる傾き(度)
stick_xy  = [12.4, -14.5];                       // スティックの中心
top_z     = body[len(body) - 1][0] + top_r;      // スティック位置での天面の高さ
tilt_from = 92;                                  // ここから上を天面の傾きに合わせて傾ける
stick_pos = [stick_xy[0], stick_xy[1], top_z];

// 天面の上の座標 (u, v): u は前方向、v は左方向、原点はスティックの中心
// 親指を中心にした2重の扇形(内側の半径 約22mm、外側 約37mm)
button_layout = [
    [ 21.0,  31.5],   // 3
    [ 32.5,  20.5],   // 4
    [ 21.0,  10.0],   // Tab
    [  7.0,  21.0],   // F
    [ -8.5,  20.5],   // Q
    [-21.0,   7.5],   // E
    [-20.5,  -9.0],   // X
    [-36.5,   4.0],   // 1
    [-36.0, -11.5],   // 2
];
esc_pos = [24, -15];   // ボタンのない右前。誤爆対策にファームウェアで長押しにしている

// 前面のボタンの高さ(下から): G, CTRL, SHIFT, SPACE
side_button_z = [49, 63, 77, 91];

// 床ボタン: 前面の下のくぼみの床。薬指・小指の先で押し下げる
base_buttons = [[42, 14], [42, 0], [42, -14]];

// ---------------- 曲面をつくる道具 ----------------

function cr(p0, p1, p2, p3, t) =
    0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
           + (3 * p1 - p0 - 3 * p2 + p3) * t * t * t);

// 表の値の間を曲線(Catmull-Rom)でつないで、高さ z の [後ろ, 前, 右, 左] を返す
function body_at(z) =
    let (n = len(body),
         i = min(n - 2, max([for (k = [0 : n - 1]) if (body[k][0] <= z) k])),
         t = (z - body[i][0]) / (body[i + 1][0] - body[i][0]),
         a = body[max(i - 1, 0)], b = body[i], c = body[i + 1], d = body[min(i + 2, n - 1)])
    [for (col = [1 : 4]) cr(a[col], b[col], c[col], d[col], t)];

function front_x(z) = body_at(z)[1];
function center_y(z) = let (r = body_at(z)) (r[2] + r[3]) / 2;

// 超楕円の1点
function se(x0, x1, y0, y1, e, t) =
    [(x0 + x1) / 2 + (x1 - x0) / 2 * sign(cos(t)) * pow(abs(cos(t)), 2 / e),
     (y0 + y1) / 2 + (y1 - y0) / 2 * sign(sin(t)) * pow(abs(sin(t)), 2 / e)];

function ring(x0, x1, y0, y1, e, z) =
    [for (k = [0 : ring_n - 1]) let (p = se(x0, x1, y0, y1, e, 360 * k / ring_n)) [p[0], p[1], z]];

function smooth01(t) = let (c = max(0, min(1, t))) c * c * (3 - 2 * c);

// 天面の傾き: 高さ tilt_from から上を、スティック位置を軸に前が上がるようにずらす
function tilt_pt(p) =
    let (s = smooth01((p[2] - tilt_from) / (top_z - top_r - tilt_from)))
    [p[0], p[1], p[2] + tan(head_tilt) * (p[0] - stick_xy[0]) * s];

// 輪のリストを1つの閉じた立体にする(上下のふたは中心から扇形に張る)
module loft(rings) {
    m = len(rings);
    n = len(rings[0]);
    pts = [for (r = rings) for (p = r) p];
    bc =[sum_x(rings[0]) / n, sum_y(rings[0]) / n, avg_z(rings[0])];
    tc = [sum_x(rings[m - 1]) / n, sum_y(rings[m - 1]) / n, avg_z(rings[m - 1])];
    B = m * n;
    T = m * n + 1;
    sides = [for (i = [0 : m - 2], j = [0 : n - 1])
                let (a = i * n + j, b = (i + 1) * n + j,
                     c = (i + 1) * n + (j + 1) % n, d = i * n + (j + 1) % n)
                each [[a, b, c], [a, c, d]]];
    caps = concat([for (j = [0 : n - 1]) [B, j, (j + 1) % n]],
                  [for (j = [0 : n - 1]) [T, (m - 1) * n + (j + 1) % n, (m - 1) * n + j]]);
    polyhedron(points = concat(pts, [bc, tc]), faces = concat(sides, caps), convexity = 6);
}

function sum_x(r) = [for (p = r) 1] * [for (p = r) p[0]];
function sum_y(r) = [for (p = r) 1] * [for (p = r) p[1]];
function avg_z(r) = ([for (p = r) 1] * [for (p = r) p[2]]) / len(r);

// ---------------- 形 ----------------

function base_rings() =
    let (zs = concat([0, 1.2, base_h - base_rf],
                     [for (k = [1 : 6]) let (a = 90 * k / 6) base_h - base_rf + base_rf * sin(a)]),
         ins = concat([1.2, 0, 0],
                      [for (k = [1 : 6]) let (a = 90 * k / 6) base_rf * (1 - cos(a))]))
    [for (i = [0 : len(zs) - 1])
        [for (p = ring(base_x[0] + ins[i], base_x[1] - ins[i], base_y[0] + ins[i], base_y[1] - ins[i],
                       base_se, zs[i]))
            [p[0], p[1], p[2] * base_thin(p[0])]]];

function body_rings() =
    let (z0 = body[0][0],
         z1 = body[len(body) - 1][0],
         zs = concat([for (z = [z0 : body_step : z1 - 0.01]) z], [z1]),
         straight = [for (z = zs) let (r = body_at(z)) ring(r[0], r[1], r[2], r[3], body_se(z), z)],
         r1 = body_at(z1),
         crown = [for (k = [1 : 6])
                    let (a = 90 * k / 6, ins = top_r * (1 - cos(a)))
                    ring(r1[0] + ins, r1[1] - ins, r1[2] + ins, r1[3] - ins, body_se(z1), z1 + top_r * sin(a))])
    [for (r = concat(straight, crown)) [for (p = r) tilt_pt(p)]];

module head_frame() translate(stick_pos) rotate([0, -head_tilt, 0]) children();

// 天面の (u, v) に子要素を置く。子要素の +Z が天面の外向き
module on_head(u, v) head_frame() translate([u, v, 0]) children();

// 前面の高さ z に子要素を置く。子要素の +Z が前向き、子要素の X が縦方向
module on_front(z) translate([front_x(z), center_y(z), z]) rotate([0, 90, 0]) children();

module on_base(b) translate([b[0], b[1], base_h]) children();

module base() loft(base_rings());
module grip() loft(body_rings());
module body() { base(); grip(); }

base_y0 = base_y[0];
