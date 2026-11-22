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
base_y  = [-46, 56];   // 左右の範囲(左は手の側面を置く受け、右は床ボタンの分だけ張り出す)
base_h  = 12;          // 厚み
base_rf = 5;           // 上の縁の丸み
base_se = 2.5;         // 断面の角の丸さ(2 で楕円、大きいほど四角に近い)
function base_thin(x) = lookup(x, [[-73, 0.35], [-40, 1]]);

// ---- 胴体: [高さz, 後ろ端x, 前端x, 右端y, 左端y] ----
// 高さ 20〜30 の前端が下がっているところが、薬指・小指の入るくぼみ。
// 手の側面を土台に置いたとき、下から小指・薬指・中指・人差し指が並び、親指が天面に届く高さにしている。
// 握る部分は奥行き 約67・幅 約41 の細い首にして、手の小さい人でも握れるようにする。
// 天面(親指の扇形)は大きさを変えず、首から天面へ向かって広げる。
body = [
    [  8, -50, 36, -30, 36  ],
    [ 14, -38, 30, -25, 29  ],
    [ 20, -30, 27, -22, 25  ],
    [ 27, -26, 28, -21, 22  ],
    [ 33, -23, 42, -21, 21  ],
    [ 40, -21, 46, -21, 20.5],
    [ 46, -20, 47, -21, 20  ],
    [ 56, -19, 47, -21, 20  ],
];
function body_se(z) = lookup(z, [[60, 3], [100, 4.2]]);   // 断面の角の丸さ(天面に近いほど四角寄り)
body_step = 2;      // 輪切りの間隔
top_r     = 5;      // 天面の縁の丸み

// ---- 天面(親指を置く平らな面) ----
head_tilt = 45;                                  // 天面の傾き(度)。前が高く、手前を向く
stick_xy  = [12.4, -14.5];                       // スティックの中心
neck_top  = 46;                                  // 首の上端。ここから上は傾いた天面の板へつなぐ
plate_t   = 7;                                   // 天面の板の厚み(縁の丸みを含む)
plate_from = 30;                                 // ここから上で、首の断面を天面の外形(真上から見た形)へ変えていく
bridge_n  = 14;                                  // 首の上端から天面の板の下面までをつなぐ輪の数
// 天面の板の一番後ろの下面が、首の上端より 6mm 上にくるように天面の高さを決める
top_z     = neck_top + 6 + plate_t * cos(head_tilt) + 46 * sin(head_tilt);
stick_pos = [stick_xy[0], stick_xy[1], top_z];

// 天面の上の座標 (u, v): u は前方向、v は左方向、原点はスティックの中心。
// 角度はスティックから見た向き(0° が前、90° が左、180° が手前)。
//
// 扇形の考え方:
//   親指はスティックに置いたまま、付け根の方へ曲げてボタンを押し、スティックに戻る。
//   付け根の方へ曲げるのは楽で、反対側(右前)へ伸ばすのはつらい。
//   そこで、スティックを中心に、親指の付け根の向き thumb_dir を真ん中にして
//   ±90° の範囲にだけボタンを並べる。
//   - 内側の列(半径 ring_in): 5個を 45° おきに。親指を少し曲げるだけで届く
//   - 外側の列(半径 ring_out): 扇の両端に2個ずつ。真ん中は親指の付け根の真上で届かないので空ける
//   - ESC は扇の外(右前、指を伸ばす側)に置き、長押しでだけ送る
thumb_dir = 115;   // 親指の付け根の向き(左やや手前)
ring_in   = 22.3;
ring_out  = 37.5;

function polar(r, a) = [r * cos(a), r * sin(a)];

button_layout = [
    polar(ring_out, thumb_dir - 59),   // 3
    polar(ring_out, thumb_dir - 83),   // 4
    polar(ring_in,  thumb_dir - 90),   // Tab
    polar(ring_in,  thumb_dir - 45),   // F
    polar(ring_in,  thumb_dir),        // Q
    polar(ring_in,  thumb_dir + 45),   // E
    polar(ring_in,  thumb_dir + 90),   // X
    polar(ring_out, thumb_dir + 59),   // 1
    polar(ring_out, thumb_dir + 83),   // 2
];
esc_pos = polar(28.5, -32);

// 天面の外形: スティックから見た向きごとの半径。扇の範囲は外側の列まで広げ、
// 親指の付け根の真上(thumb_dir)は少しへこませ、指を伸ばす右側はスティックの周りに詰める
plate_knots = [
    [-180, 46], [-150, 44], [-120, 31], [-80, 25], [-40, 35],
    [ 0, 38], [ 30, 46], [ 60, 47], [ 90, 38], [115, 34], [140, 37], [165, 45],
];

// 前面のボタンの高さ(下から): G, CTRL, SHIFT, SPACE
// 上の3つ(CTRL・SHIFT・SPACE)は人差し指と中指で押す。G は少し離して下に置き、薬指で押す。
// 小指はその下のくぼみに巻き付けて、握りを安定させる(ボタンは置かない)
side_button_z = [36, 50, 62, 74];

// 床ボタン: 土台の右後ろ(手前側)。握っている指や手のひらが触れない場所で、
// 撃ち合いの合間に手を少しずらして押す。くぼみの床に置くと、薬指の背が当たってこすれるため移した
base_buttons = [[-36, -38], [-21, -38], [-6, -38]];

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

function front_x(z) =
    z <= neck_top ? body_at(z)[1]
    : let (t = smooth01((z - neck_top) / (plate_pt(40, 0, -plate_t)[2] - neck_top)))
      body_at(neck_top)[1] * (1 - t) + plate_pt(40, 0, -plate_t)[0] * t;

// 天面の外形の半径(角度 a、度)。plate_knots の間を曲線でつなぎ、一周でつながるようにする
function kang(i) = let (n = len(plate_knots)) plate_knots[(i % n + n) % n][0] + 360 * floor(i / n);
function kval(i) = let (n = len(plate_knots)) plate_knots[(i % n + n) % n][1];
function plate_R(a) =
    let (n = len(plate_knots), a0 = plate_knots[0][0],
         aa = a0 + ((a - a0) % 360 + 360) % 360,
         i = max([for (j = [0 : n - 1]) if (plate_knots[j][0] <= aa) j]),
         t = (aa - kang(i)) / (kang(i + 1) - kang(i)))
    cr(kval(i - 1), kval(i), kval(i + 1), kval(i + 2), t);

// 天面の板の上の点 (u, v, w) を本体の座標へ。w は天面からの高さ(下向きが負)
function plate_pt(u, v, w) =
    [stick_xy[0] + u * cos(head_tilt) - w * sin(head_tilt), stick_xy[1] + v, top_z + u * sin(head_tilt) + w * cos(head_tilt)];

// 天面の板の輪(傾いた面の上、天面から w の深さ、外形から ins だけ内側)
function plate_ring(ins, w) =
    [for (k = [0 : ring_n - 1]) let (a = 360 * k / ring_n, r = plate_R(a) - ins)
        plate_pt(r * cos(a), r * sin(a), w)];

// 真上から見た天面の外形を、高さ z の水平な輪にしたもの(首を天面の形へ寄せる目標)
function plate_shadow(z) =
    [for (k = [0 : ring_n - 1]) let (a = 360 * k / ring_n, r = plate_R(a))
        [stick_xy[0] + r * cos(a) * cos(head_tilt), stick_xy[1] + r * sin(a), z]];

function mix(p, q, w) = p * (1 - w) + q * w;
function center_y(z) = let (r = body_at(z)) (r[2] + r[3]) / 2;

// 超楕円の1点
function se(x0, x1, y0, y1, e, t) =
    [(x0 + x1) / 2 + (x1 - x0) / 2 * sign(cos(t)) * pow(abs(cos(t)), 2 / e),
     (y0 + y1) / 2 + (y1 - y0) / 2 * sign(sin(t)) * pow(abs(sin(t)), 2 / e)];

function ring(x0, x1, y0, y1, e, z) =
    [for (k = [0 : ring_n - 1]) let (p = se(x0, x1, y0, y1, e, 360 * k / ring_n)) [p[0], p[1], z]];

function smooth01(t) = let (c = max(0, min(1, t))) c * c * (3 - 2 * c);

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
         zs = concat([for (z = [z0 : body_step : neck_top - 0.01]) z], [neck_top]),
         // 首の断面(角の丸い四角)を、上へ行くほど天面の外形へ変えていく
         neck = [for (z = zs) let (r = body_at(z), w = 0.85 * smooth01((z - plate_from) / (neck_top - plate_from)),
                                   a = ring(r[0], r[1], r[2], r[3], body_se(z), z), b = plate_shadow(z))
                    [for (k = [0 : ring_n - 1]) mix(a[k], b[k], w)]],
         last = neck[len(neck) - 1],
         under = plate_ring(0, -plate_t),
         // 首の上端から、傾いた天面の板の下面までをなめらかにつなぐ
         bridge = [for (j = [1 : bridge_n - 1]) let (t = smooth01(j / bridge_n))
                    [for (k = [0 : ring_n - 1]) mix(last[k], under[k], t)]],
         side = [under, plate_ring(0, -top_r)],
         crown = [for (k = [1 : 6])
                    let (a = 90 * k / 6, ins = top_r * (1 - cos(a)))
                    plate_ring(ins, -top_r + top_r * sin(a))])
    concat(neck, bridge, side, crown);

module head_frame() translate(stick_pos) rotate([0, -head_tilt, 0]) children();

// 天面の (u, v) に子要素を置く。子要素の +Z が天面の外向き
module on_head(u, v) head_frame() translate([u, v, 0]) children();

// 前面の高さ z に子要素を置く。子要素の +Z が前向き、子要素の X が縦方向
module on_front(z) translate([front_x(z), center_y(z), z]) rotate([0, 90, 0]) children();

module on_base(b) translate([b[0], b[1], base_h]) children();

// 手の側面(小指側の手のひらの縁)を置く受け。土台の左に前後に長いくぼみを作り、
// 外側の縁を少し盛り上げる。手を置くだけで握る形が決まり、手が浮かない
cradle_y   = 39;     // くぼみの中心(左右)
cradle_x   = [-58, 30];
cradle_d   = 3.5;    // くぼみの深さ
lip_y      = 51;     // 外側の縁の位置
lip_h      = 4;      // 縁の盛り上がり

module cradle_cut()
    hull() for (x = cradle_x) translate([x, cradle_y, base_h + 9 - cradle_d]) scale([16, 11, 9]) sphere(1, $fn = 48);

module cradle_lip()
    hull() for (x = [cradle_x[0] + 6, cradle_x[1] - 4]) translate([x, lip_y, 0]) scale([10, 4.5, base_h + lip_h]) sphere(1, $fn = 48);

module base() difference() {
    union() { loft(base_rings()); intersection() { cradle_lip(); translate([-200, -200, 0]) cube([400, 400, 100]); } }
    cradle_cut();
}
module grip() loft(body_rings());
module body() { base(); grip(); }

base_y0 = base_y[0];
