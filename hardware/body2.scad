// =============================================================
// 外形(試作6号〜)。Mouserpad v2 を写真から測った値に合わせて作る。
// 測り方と根拠: reference/tools/side_landmarks.py, top_landmarks.py と
// まとめページの「既製品の分析」タブ。
//
// 座標系: +X が前(3つのボタンの面、モニター側)、-X が手首側、+Y が手のひら側(左)、Z が上。
// 前面の一番前が X=0。スティックの中心が Y=0。
//
// 作り方: 横から見た輪郭(side_profile)を左右に伸ばした立体と、
// 真上から見た形(土台・首・天面)を上下に伸ばした立体の、重なる部分を本体にする。
// =============================================================

head_tilt = 29;    // 天面の傾き(度)。既製品は約29°

// ---- 横から見た輪郭 [X, Z](IMG_1096 で測った点) ----
plate_front = [-1.0, 120.0];   // 天面の前の角
plate_back_x = -81.8;          // 天面の後ろの端の X
function plate_z(x) = plate_front[1] - (plate_front[0] - x) * tan(head_tilt);

side_profile = [
    plate_front,
    [plate_back_x, plate_z(plate_back_x)],      // 天面の後ろの端(傾きで高さが変わる)
    [-90.6, min(54.2, plate_z(plate_back_x) - 6)],
    [-98.4, 36.6], [-101.3, 30.8],               // 胴体の後ろ(手首側へ約24°倒れる)
    [-108.1, 23.0], [-115.9, 16.2], [-124.7, 8.4], [-125.3, 1.0],   // 土台の上面(手首側へ薄くなる)
    [-125.3, 0], [-21.8, 0], [-21.8, 10], [-36, 10.5], [-43, 14],   // 土台の底と前の端、首の前へ盛り上がる所
    [-45.8, 21.0], [-47.3, 32.7], [-44.2, 44.4],                    // 首の前
    [-38.0, 52.2], [-28.2, 55.1], [-16.6, 53.2], [-6.8, 47.3],      // 頭の下(指が入る空き)
    [0.0, 40.5],                                                    // 前面の下の角
];

// ---- 真上から見た形 [X, Y] ----
// 天面: IMG_1092 で測った外形(スティック中心からの前後 u・手のひら側 v)を X, Y に直したもの
stick_x = -48.1;
include <body2_measured.scad>   // plate_outline_uv, key_names, button_layout
function plate_xy(p) = [stick_x + p[0] * cos(head_tilt), p[1]];
// 首: 高さ約40mm での幅 約44mm(IMG_1092 で遠近を補正して測った値)。手のひら側へ寄っている
neck_y = [-8, 36];
// 土台: 前後は横の輪郭で決まる。左右は手のひら側へ大きく張り出し、手の側面を置く所になる
base_y = [-13, 62];   // 手のひら側の端は、全体の幅が商品ページの 90mm になるように決めた
base_r = 22;

module rounded_box2d(x0, x1, y0, y1, r) offset(r = r) offset(delta = -r) translate([x0, y0]) square([x1 - x0, y1 - y0]);

module side_solid() rotate([90, 0, 0]) translate([0, 0, -150]) linear_extrude(300) offset(r = 2) offset(delta = -2) polygon(side_profile);

// 土台は、薄い縁の板と、首の付け根の周りの盛り上がりでできている。
// 寸法は既製品を定規で測った値(2026-11-23)。測った場所はまとめページの「既製品の分析」タブ。
// IMG_1096 で「土台の上面」として測った約20mm は、この盛り上がりの上の継ぎ目の高さだった。
rim_front = 10;    // 1: 前の端の縁の厚さ
rim_back = 9;      // 2: 手首側の先の縁の厚さ
collar_top = 21;   // 3・4: 継ぎ目の高さ。手のひら側も指側も 21mm
collar_flare = 10; // 盛り上がりの裾が首から広がる幅。IMG_1097 から見積もった値で、測ってはいない

base_profile = [[-21.8, 0], [-21.8, rim_front], [-125.3, rim_back], [-125.3, 0]];

module neck_foot2d() rounded_box2d(-125, -46, neck_y[0], neck_y[1], 12);

// 手のひら側の盆地: 左手を置いたとき小指の腹の側面が収まる所。手のひら側の土台の上面が、
// 前後方向に山と山の間 80mm、真ん中(山から 40mm)で最大 3mm 下がる(定規を渡して測った値、IMG_1122)。
// 山の前後の位置は土台の前後の真ん中とした(測っていない)。首の側では、盛り上がりの裾の外から深くなる。
basin_len = 80;
basin_depth = 3;
basin_center_x = (-21.8 + -125.3) / 2;
basin_y = [neck_y[1] + collar_flare, neck_y[1] + collar_flare + 8];   // ここから外側で深さいっぱい
function rim_top(x) = rim_front + (rim_back - rim_front) * (-21.8 - x) / (125.3 - 21.8);
function basin_dip(x) = abs(x - basin_center_x) >= basin_len / 2 ? 0
    : basin_depth * (1 + cos(180 * (x - basin_center_x) / (basin_len / 2))) / 2;

module basin_cut() {
    n = 40;
    step = basin_len / n;
    for (i = [0 : n - 1]) {
        x0 = basin_center_x - basin_len / 2 + i * step;
        xm = x0 + step / 2;
        hull() {
            translate([x0, basin_y[0], rim_top(xm)]) cube([step + 0.01, 0.01, 30]);
            translate([x0, basin_y[1], rim_top(xm) - basin_dip(xm)]) cube([step + 0.01, 40, 30]);
        }
    }
}

module base() difference() { base_solid(); basin_cut(); }

module base_solid() union() {
    // 縁の板
    intersection() {
        linear_extrude(40) rounded_box2d(-130, -18, base_y[0], base_y[1], base_r);
        rotate([90, 0, 0]) translate([0, 0, -150]) linear_extrude(300) offset(r = 2) offset(delta = -2) polygon(base_profile);
    }
    // 首の付け根の盛り上がり。裾は縁の上面から、継ぎ目の高さで首の太さになる
    intersection() {
        hull() {
            translate([0, 0, rim_back - 0.5]) linear_extrude(0.5) offset(r = collar_flare) neck_foot2d();
            translate([0, 0, collar_top]) linear_extrude(0.5) neck_foot2d();
        }
        side_solid();
        linear_extrude(40) rounded_box2d(-130, -18, base_y[0], base_y[1], base_r);
    }
}

module footprints() {
    hull() {
        translate([0, 0, 12]) linear_extrude(1) rounded_box2d(-130, -40, neck_y[0], neck_y[1], 12);   // 首
        translate([0, 0, 62]) linear_extrude(80) offset(r = 1) polygon([for (p = plate_outline_uv) plate_xy(p)]);   // 天面
    }
}

module body() union() { base(); intersection() { side_solid(); footprints(); } }

// ---- 部品の位置 ----
// 天面の上の点 (u, v) を本体の座標へ。u は天面に沿った前方向、v は手のひら側
function head_pt(u, v) = [stick_x + u * cos(head_tilt), v, plate_z(stick_x + u * cos(head_tilt))];
module on_head(u, v) translate(head_pt(u, v)) rotate([0, -head_tilt, 0]) children();

// 天面のキー: body2_measured.scad(IMG_1092 で測った位置、天面に沿った距離)
// ESC は既製品にない(レビューで一番多い不満)。最初は [24, -15] に置いたが、試作6号で親指が届かなかった。
// 使う人の希望で Tab の右へ移した: 内側の列(スティックから約22mm、45°前後おき)の、Tab(35°)の次の -10.5° の位置。
// 親指がかすって送らないよう、ファームウェアで長押し(0.3秒)のときだけ送る
esc_pos = [21.6, -4.0];

// 前面の3つのボタン(IMG_1096 で測った高さ)。薬指用のボタンは、形が決まってから置き場所を決める
side_button_z = [57, 72.6, 88.2];
side_button_y = 8;
module on_front(z) translate([0, side_button_y, z]) rotate([0, 90, 0]) children();
