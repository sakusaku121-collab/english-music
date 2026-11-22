// =============================================================
// 外形の定義。concept.scad と case.scad が共用する。
//
// 座標系: +X がモニター側、-X が手前(手首側)、+Y が左、Z が上。
// 握り方: 左手の手のひらを本体の左面に当てて、指先を前へ伸ばす。
// 親指は天面、人差し指・中指は前面のボタン、薬指・小指は前面下のくぼみに入る。
// 大きさと比率は Mouserpad v2(幅90×奥行125×高さ120)の写真から取った。
// 形そのものはまねず、寸法の比率だけを合わせている。
// =============================================================

// ---- 土台 ----
base_t    = 16;    // 厚み
base_x0   = -60;   // 平らな部分の後端
base_x1   = 50;    // 前端(前面の真下。くぼみの床ボタンが乗る)
base_y0   = -26;   // 右端
base_y1   = 46;    // 左端(手のひら側に張り出す)
base_r    = 16;    // 角の丸み
base_tip  = -73;   // 手首側の先端(ここから後端まで斜めに上がる)

// ---- 胴体: [高さz, 後ろ端x, 前端x, 幅の半分] ----
// 前端が 30 まで下がっている高さ 18〜32 が、薬指・小指の入るくぼみ
body = [
    [14, -60, 34, 27],
    [18, -58, 30, 25],
    [32, -55, 30, 24],
    [38, -53, 46, 24],
    [43, -51, 52, 24],
    [60, -46, 52, 23.5],
    [80, -40, 52, 24],
    [96, -35, 50, 26],
];
body_rb = 16;   // 後ろ側の角の丸み(手のひらに当たる)
body_rf = 6;    // 前側の角の丸み

// ---- 天面(親指を置く平らな板) ----
// 板の上の座標 (u, v): u は前方向、v は左方向、原点はスティックの中心
stick_pos  = [12.4, -14.5, 114.3];   // 本体座標でのスティックの中心
head_tilt  = 9;                      // 前が高くなる傾き(度)
plate_u    = [-46.5, 40];            // 板の前後の範囲
plate_v    = [-27.5, 48];            // 板の左右の範囲
plate_r    = 14;                     // 板の角の丸み
plate_t    = 8;                      // 板の厚み

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
base_buttons = [[40, 14], [40, 0], [40, -14]];

body_step = 2;  // 輪切りの間隔。表の値の間は曲線(Catmull-Rom)でつなぐ

function cr(p0, p1, p2, p3, t) =
    0.5 * (2 * p1 + (p2 - p0) * t + (2 * p0 - 5 * p1 + 4 * p2 - p3) * t * t
           + (3 * p1 - p0 - 3 * p2 + p3) * t * t * t);

function body_at(z, col) =
    let (n = len(body),
         i = min(n - 2, max([for (k = [0 : n - 1]) if (body[k][0] <= z) k])),
         t = (z - body[i][0]) / (body[i + 1][0] - body[i][0]))
    cr(body[max(i - 1, 0)][col], body[i][col], body[i + 1][col], body[min(i + 2, n - 1)][col], t);

function front_x(z) = body_at(z, 2);

body_zs = concat([for (z = [body[0][0] : body_step : body[len(body) - 1][0] - 0.01]) z],
                 [body[len(body) - 1][0]]);

module rrect(x0, x1, y0, y1, r, h)
    hull()
        for (x = [x0 + r, x1 - r], y = [y0 + r, y1 - r])
            translate([x, y, 0]) cylinder(r = r, h = h);

module slice(b)
    translate([0, 0, b[0]])
        hull()
            for (s = [-1, 1]) {
                translate([b[1] + body_rb, s * (b[3] - body_rb), 0]) cylinder(r = body_rb, h = 0.5);
                translate([b[2] - body_rf, s * (b[3] - body_rf), 0]) cylinder(r = body_rf, h = 0.5);
            }

module head_frame()
    translate(stick_pos) rotate([0, -head_tilt, 0]) children();

module head()
    head_frame()
        translate([0, 0, -plate_t])
            rrect(plate_u[0], plate_u[1], plate_v[0], plate_v[1], plate_r, plate_t);

// 天面の (u, v) に子要素を置く。子要素の +Z が天面の外向き
module on_head(u, v) head_frame() translate([u, v, 0]) children();

// 前面の高さ z に子要素を置く。子要素の +Z が前向き、子要素の X が縦方向
module on_front(z, y = 0) translate([front_x(z), y, z]) rotate([0, 90, 0]) children();

module on_base(b) translate([b[0], b[1], base_t]) children();

module base()
    hull() {
        rrect(base_x0, base_x1, base_y0, base_y1, base_r, base_t);
        translate([base_tip + 12, (base_y0 + base_y1) / 2, 0])
            scale([12, 28, 1]) cylinder(r = 1, h = 3);
    }

module slice_at(z) slice([z, body_at(z, 1), body_at(z, 2), body_at(z, 3)]);

module grip() {
    for (i = [0 : len(body_zs) - 2]) hull() { slice_at(body_zs[i]); slice_at(body_zs[i + 1]); }
    hull() { slice(body[len(body) - 1]); head(); }
}

module body() { base(); grip(); }
