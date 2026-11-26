// =============================================================
// 外形(試作6号〜)。Mouserpad v2 を写真から測った値に合わせて作る。試作7号で、試作6号を刷って比べたずれを直した。
// 測り方と根拠: reference/tools/side_landmarks.py, top_landmarks.py と
// まとめページの「既製品の分析」タブ。
//
// 座標系: +X が前(3つのボタンの面、モニター側)、-X が手首側、+Y が手のひら側(左)、Z が上。
// 前面の一番前が X=0。スティックの中心が Y=0。
//
// 作り方: 横から見た輪郭(side_profile)を左右に伸ばした立体と、真上から見た形(首・天面)を
// 上下に伸ばした立体と、前から見た形(front_env)を前後に伸ばした立体の、重なる部分を本体にする。
// 土台は別に作って足す。
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

// 角の丸み(試作7号〜)。外形を一度この分だけ内へ縮めてから、同じ半径の球でなでて元の大きさに戻すと、
// 角がすべてこの半径で丸くなる(OpenSCAD の minkowski)。0 にすると丸めない(書き出しが速い)
r3 = 2.5;
module side_solid() rotate([90, 0, 0]) translate([0, 0, -150]) linear_extrude(300) offset(delta = -r3) offset(r = 2) offset(delta = -2) polygon(side_profile);

// ---- 土台(試作8号〜) ----
// 既製品の土台は、外の縁が丸く少し盛り上がり、その内側が一段くぼんで(盆地)、そこから首へ向かって
// 裾が広がるようにへこんだ曲面で立ち上がる(IMG_1177・IMG_1179)。左手の小指側の手のひらのふくらみが
// この盆地に収まって、手の高さと位置が決まる。試作7号は、縁の板と首の周りの 10mm の坂を
// hull でつないだだけで、くぼみがなく、坂も角ばっていた(手が置けずにずり落ちた)。
// 寸法: 縁の厚さ・継ぎ目の高さ・盆地の深さは定規で測った値(2026-11-23)。広がり方の幅は写真から見積もり。
rim_front = 10;    // 1: 前の端の縁の厚さ
rim_back = 9;      // 2: 手首側の先の縁の厚さ
collar_top = 21;   // 3・4: 首の付け根の継ぎ目の高さ
basin_depth = 3;   // 盆地の深さ(縁の上から)
flare_w = 12;      // 首から裾が広がる幅
lip_r = 3;         // 外の縁の丸み

// 土台を上から見た形: 既製品を紙になぞって測った外形(IMG_1183、reference/tools/sole_trace.py)。
// 前後 106mm・左右 88mm で、手のひら側へ首から 44mm 張り出す。試作7号(見積もり)は 98×70mm しかなかった。
// x ごとの指側(ymin)と手のひら側(ymax)の端の表を使う
include <base_outline.scad>
base_xb = base_x_range[0]; base_xf = base_x_range[1];
function bt(x) = (x - base_xb) / (base_xf - base_xb);
function base_ymax(x) = lookup(x, base_ymax_tab);
function base_ymin(x) = lookup(x, base_ymin_tab);
// 首が土台に立つ所(角の丸い四角)と、そこからの距離
// 握る部分の作り方。1回に1か所だけ変えて握り比べるため、試作7号の作り方も残す。
//   "v7"   : 頭は前面のボタンの高さ(40mm)まで天面の形のまま下り、そこから首へ絞る(試作7号。握って確かめ済み)
//   "loft" : 首の足元から天面の縁の下まで、筒のようになめらかな面(試作9号の案。未確認)
//   "tube" : T1・T2 で決めた楕円の筒(左右 39mm × 前後 45mm)を土台から天面まで1本でつなぐ(試作10号〜)
grip_style = "tube";
// 筒の作り方("tube")では、首の足元は筒の下の端の楕円(tools_grip_tube.py が出す値)
include <grip_tube.scad>
tube_bottom = head_tilt == 35 ? tube_bottom_35 : tube_bottom_29;
neck_c = grip_style == "tube" ? [tube_bottom[0], tube_bottom[1]] : [-76.5, 14];
neck_h = grip_style == "tube" ? [tube_bottom[2], tube_bottom[3]] : [31.5, 22];
neck_r = grip_style == "tube" ? min(tube_bottom[2], tube_bottom[3]) - 0.5 : 12;
function d_neck(x, y) = let(qx = abs(x - neck_c[0]) - (neck_h[0] - neck_r), qy = abs(y - neck_c[1]) - (neck_h[1] - neck_r))
    norm([max(qx, 0), max(qy, 0)]) + min(max(qx, qy), 0) - neck_r;
function rim_top(x) = rim_front + (rim_back - rim_front) * (base_xf - x) / (base_xf - base_xb);
// 土台の上面の高さ。de は外の縁からの距離
function base_z(x, y, de) = let(
    dn = d_neck(x, y),
    gap = max(de + max(dn, 0), 0.01),
    w = min(flare_w, gap * 0.55),
    flare = dn <= 0 ? collar_top - rim_top(x) : (collar_top - rim_top(x)) * pow(max(0, 1 - dn / w), 2),
    // 盆地は外の縁と首の間で、縁寄り(縁から 4 割)が一番深い。縁と首が近い所(前・指側)では浅くする
    trough = dn <= 0 ? 0 : basin_depth * pow(sin(180 * min(1, de / (gap * 0.85))), 2) * min(1, max(0, (gap - 8) / 8)),
    lip = lip_r - sqrt(max(0, lip_r * lip_r - pow(lip_r - min(de, lip_r), 2))))
    rim_top(x) + flare - trough - lip;

nbx = 80; nby = 40;
base_pts_top = [for (i = [0 : nbx]) for (j = [0 : nby])
    let(t = i / nbx, x = base_xb + t * (base_xf - base_xb), y0 = base_ymin(x), y1 = base_ymax(x), v = j / nby,
        y = y0 + v * (y1 - y0), de = min(min(v, 1 - v) * (y1 - y0), min(t, 1 - t) * (base_xf - base_xb)))
    [x, y, base_z(x, y, de)]];
base_pts = concat(base_pts_top, [for (p = base_pts_top) [p[0], p[1], 0]]);
function bi(i, j) = i * (nby + 1) + j;
NB = (nbx + 1) * (nby + 1);
base_faces = concat(
    [for (i = [0 : nbx - 1]) for (j = [0 : nby - 1]) each [[bi(i, j), bi(i, j + 1), bi(i + 1, j + 1)], [bi(i, j), bi(i + 1, j + 1), bi(i + 1, j)]]],
    [for (i = [0 : nbx - 1]) for (j = [0 : nby - 1]) each [[NB + bi(i, j), NB + bi(i + 1, j + 1), NB + bi(i, j + 1)], [NB + bi(i, j), NB + bi(i + 1, j), NB + bi(i + 1, j + 1)]]],
    [for (i = [0 : nbx - 1]) each [[bi(i, 0), bi(i + 1, 0), NB + bi(i + 1, 0)], [bi(i, 0), NB + bi(i + 1, 0), NB + bi(i, 0)]]],
    [for (i = [0 : nbx - 1]) each [[bi(i, nby), NB + bi(i, nby), NB + bi(i + 1, nby)], [bi(i, nby), NB + bi(i + 1, nby), bi(i + 1, nby)]]],
    [for (j = [0 : nby - 1]) each [[bi(0, j), NB + bi(0, j), NB + bi(0, j + 1)], [bi(0, j), NB + bi(0, j + 1), bi(0, j + 1)]]],
    [for (j = [0 : nby - 1]) each [[bi(nbx, j), bi(nbx, j + 1), NB + bi(nbx, j + 1)], [bi(nbx, j), NB + bi(nbx, j + 1), NB + bi(nbx, j)]]]
);
module base() polyhedron(points = base_pts, faces = base_faces, convexity = 6);

// 天面の外形の点をなめらかにつなぐ(Chaikin の角切り。試作6号は直線でつないでカクカクしていた: ずれ C)
function chaikin(p) = [for (i = [0 : len(p) - 1]) let(a = p[i], b = p[(i + 1) % len(p)]) each [0.75 * a + 0.25 * b, 0.25 * a + 0.75 * b]];
plate_xy_pts = [for (p = plate_outline_uv) plate_xy(p)];
plate_smooth = chaikin(chaikin(chaikin(plate_xy_pts)));
module plate2d() offset(delta = -r3) offset(r = 1) polygon(plate_smooth);

// 真上から見た形(首と天面)。頭(天面の下のかたまり)は前面のボタンがある高さ(head_bottom)まで
// 天面の外形のまま下り、そこから首へ向かって絞る。試作6号は 62mm から絞っていた。
// 頭の左右の絞り(とくに手のひら側の、親指の付け根の逃げ)は front_env で付ける(ずれ B・E)
head_bottom = 40;      // 前面の下の角の高さ(IMG_1096 で 40.5mm)
// 天面の面(傾いた面)に沿って置く。z = plate_z(x) + dz
module on_plate_plane(dz) multmatrix([[1, 0, 0, 0], [0, 1, 0, 0], [-tan(head_tilt), 0, 1, plate_z(0) + dz], [0, 0, 0, 1]]) children();
// 頭と首(試作9号〜): 天面の縁のすぐ下から、首の足元(継ぎ目の高さ)まで、まっすぐな面で下りる。
// 既製品は手のひら側の、親指の腹が当たる面がほぼ直線の斜面(IMG_1187・1188)。
// 試作7・8号は前面のボタンの高さまで天面の形のまま真下へ落としてから絞っていて、段と折れ目ができた
// (使った人の感想: 気持ち悪い。試作6号の方がしっくりくる)
rim = 4;               // 天面の縁の厚み。ここから下が斜面
module neck2d() offset(delta = -r3) rounded_box2d(neck_c[0] - neck_h[0], neck_c[0] + neck_h[0], neck_c[1] - neck_h[1], neck_c[1] + neck_h[1], neck_r);
// 握る部分: 首の足元から天面の縁の下まで、筒のようになめらかな面(tools_grip_loft.py が作る)。
// その上に、天面の縁(厚み rim)を天面と同じ傾きで載せる
include <grip_loft.scad>
module grip_loft() if (head_tilt == 35) polyhedron(grip_pts_35, grip_faces_35, convexity = 4);
                   else polyhedron(grip_pts_29, grip_faces_29, convexity = 4);

module top_env() if (grip_style == "loft") union() {
    grip_loft();
    on_plate_plane(-rim - 0.5) linear_extrude(rim + 30) plate2d();
} else union() {
    translate([0, 0, head_bottom]) linear_extrude(150) plate2d();
    // 首は土台の継ぎ目の高さから上だけ(試作7号は高さ 12mm からの大きな四角で、土台の上に台形がかぶさっていた。
    // ここは土台の一部なので、土台を替える試し A に含める)
    hull() {
        translate([0, 0, collar_top - 1]) linear_extrude(1) neck2d();
        translate([0, 0, head_bottom]) linear_extrude(0.5) plate2d();
    }
}
// 天面の縁のくぼみ(3・F・Q の側)は hull で埋まる。真下へ切ると縦の折れ目ができたので、
// 天面と同じ傾きの面の上だけで切る
module plate_notch_cut() on_plate_plane(-rim) translate([0, 0, 0.01]) linear_extrude(40)
    difference() { offset(delta = 40) plate2d(); plate2d(); }

// 前から見た形 [Y, Z]。既製品は天面の下で左右から絞られて首になり、とくに手のひら側(キーの側)は
// 天面の縁から斜めに大きく落としてあって、そこに親指の付け根が入る(ずれ B・E、IMG_1114・IMG_1115)。
// 指側は天面の縁からほぼまっすぐ下りて、頭の下で少し内へ入る。値は正面の写真から見積もった
front_env_pts = [
    [-27.5, 170], [50, 170],                 // 天面の高さでは天面の幅いっぱい
    [50, 98], [42, 78], [36, 58], [34, 44],  // 手のひら側: 天面の縁から斜めに落とす(試作7号の値)
    [38, 30], [40, 0],
    [-12, 0], [-12, 30],
    [-20, 42], [-24, 56], [-27.5, 80]        // 指側: 頭の下で少し内へ
];
module front_env() multmatrix([[0, 0, 1, -150], [1, 0, 0, 0], [0, 1, 0, 0], [0, 0, 0, 1]])
    linear_extrude(300) offset(delta = -r3) offset(r = 6) offset(delta = -6) polygon(front_env_pts);

// 前面の上の縁: 既製品は正面から見ると真ん中が凹んだ鞍の形(ずれ D、IMG_1114・IMG_1095)。
// 前後方向に寝かせた大きな円柱で、天面の前の端の真ん中を削る。天面は前が高いので、削れるのは前の端だけ
saddle_depth = 8;      // 前の端の真ん中での深さ(写真から見積もり)
saddle_r = 60;
saddle_y = 10;         // 凹みの真ん中の左右位置
module saddle_cut() translate([-80, saddle_y, plate_front[1] + saddle_r - saddle_depth - r3]) rotate([0, 90, 0]) cylinder(r = saddle_r, h = 100, $fn = 120);

module tube_core() difference() {
    if (head_tilt == 35) polyhedron(tube_pts_35, tube_faces_35, convexity = 4);   // 天面の縁まで含む
    else polyhedron(tube_pts_29, tube_faces_29, convexity = 4);
    saddle_cut();
}
module body_core() if (grip_style == "tube") tube_core(); else difference() {
    if (grip_style == "loft") intersection() { side_solid(); top_env(); }
    else intersection() { side_solid(); top_env(); front_env(); }
    saddle_cut();
}

// 台に付く底は平らのまま残す(底の縁まで丸めると、浮いた所ができてサポートが付いた)。
// 土台は上の面を関数で丸めてあるので、球でなでるのは土台より上だけ
module body() union() {
    base();
    if (grip_style == "tube") body_core();   // 筒は面がなめらかで、天面の縁は tools_grip_tube.py で丸めてある
    else if (r3 > 0) intersection() {
        minkowski() { body_core(); sphere(r = r3, $fn = 12); }
        translate([-200, -100, 0]) cube([400, 200, 300]);
    } else body_core();
}

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
side_button_y = 5;   // 試作7号で 8 → 5。既製品の正面写真ではボタンがもう少し指側にある(見積もり)
// 筒の作り方では、前面のボタンは筒の前の面に、面の傾きに合わせて置く(筒を握った人差し指・中指の先)
tube_front_x = head_tilt == 35 ? tube_front_x_35 : tube_front_x_29;
function front_x(z) = grip_style == "tube" ? lookup(z, tube_front_x) : 0;
function front_slope(z) = grip_style == "tube" ? atan((front_x(z + 2) - front_x(z - 2)) / 4) : 0;
module on_front(z) translate([front_x(z), side_button_y, z]) rotate([0, 90 + front_slope(z), 0]) children();
