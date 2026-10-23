// =============================================================
// 滑らかな外形(楕円体の hull 連鎖)。concept.scad と case.scad が共用する。
//
// 座標系: -X が手首側(ユーザー側)、+X がモニター側、Z が上。
// 掌の腹は傾斜した土台に乗り、親指は天面(ユーザー側を向く)、
// 人差し指・中指は柱の前面(+X)の側面ボタンにかかる。
// =============================================================

grip_lean = 10;   // 柱の前傾(度)
head_tilt = 30;   // 天面がユーザー側へ向く角度(度)

// 土台: 手首側(低い)とグリップ側(高い)の半楕円体を hull したスロープ
base_rear    = [-60, 0, 0];
base_rear_r  = [26, 34, 9];
base_front   = [  4, 0, 0];
base_front_r = [44, 40, 18];

// 柱の断面半径プロファイル [高さz, 半径]。細かい輪切りを hull で繋いで滑らかに見せる。
// 下は太く(薬指・小指で握り込まずに済む)、上は細く(人差し指・中指でボタン操作)
grip_rx = [[4, 36], [14, 31], [30, 25], [46, 21], [60, 19.5], [74, 20], [86, 23]];
grip_ry = [[4, 33], [14, 29], [30, 24], [46, 21], [60, 19.5], [74, 20], [86, 23]];
grip_z0 = 4;
grip_z1 = 86;
grip_step = 3;
grip_x0 = 8;

head_z = 99;
head_r = [40, 36, 11];
head_back = 7;   // 天面中心を柱軸からユーザー側へずらす量
flare_z = 93;    // 首から天面へのラッパ状の広がり
flare_r = [31, 29, 6];

function spine_x(z) = grip_x0 + z * tan(grip_lean);
function rx_at(z) = lookup(z, grip_rx);
function ry_at(z) = lookup(z, grip_ry);
function head_surface_z(u, v) =
    head_r[2] * sqrt(max(0, 1 - pow(u / head_r[0], 2) - pow(v / head_r[1], 2)));

module ell(p, r) translate(p) scale(r) sphere(1);

module ring(z) ell([spine_x(z), 0, z], [rx_at(z), ry_at(z), 2]);

module flare() ell([spine_x(flare_z) - head_back / 2, 0, flare_z], flare_r);

module head_frame()
    translate([spine_x(head_z) - head_back, 0, head_z])
        rotate([0, -head_tilt, 0])
            children();

module head() head_frame() scale(head_r) sphere(1);

// 天面の局所座標 (u, v) の表面上に子要素を置く(u+ がモニター側の縁)
module on_head(u, v) head_frame() translate([u, v, head_surface_z(u, v)]) children();

// 柱前面の高さ z の表面上に子要素を置く(+X 向き)
module on_front(z, y = 0)
    translate([spine_x(z) + rx_at(z), y, z]) rotate([0, 90 + grip_lean, 0]) children();

module base() hull() { ell(base_rear, base_rear_r); ell(base_front, base_front_r); }

module grip() {
    for (z = [grip_z0 : grip_step : grip_z1 - grip_step])
        hull() { ring(z); ring(min(z + grip_step, grip_z1)); }
    hull() { ring(grip_z1); flare(); }
    hull() { flare(); head(); }
}

module body() {
    intersection() {
        union() { base(); grip(); }
        translate([-200, -200, 0]) cube([400, 400, 300]);
    }
}

// 天面のボタン配置(天面局所座標 [u, v])。親指の可動域に合わせて扇状
button_layout = [
    [ 20,  20], [ 26,   6], [ 22,  -9],   // 3, 4, Tab(奥の列)
    [  6,  27], [-10,  26],               // F, Q(左の弧)
    [-24,  15], [-28,   0],               // E, X
    [-24, -15], [-12, -26],               // 1, 2(手前)
];
esc_pos   = [ 10, -24];
stick_pos = [  0,   2];

side_button_z = [46, 58, 70];
