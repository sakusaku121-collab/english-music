// =============================================================
// クリスマスオーナメント(真上から描いたイラストを切り抜いて立体にした版)
//
// 形は shapes_top.scad(tools/trace_top.py が source_top.png から自動生成)。
// 白1色で刷って、あとから塗る。色ごとに高さを変えて、境目を段差にしている。
// イラストの細い線(リボンの結び目や折り目、ほっぺの斜線)は浅い溝にしている。
//   part = "single"  : 印刷用(白1色)
//   part = "painted" : 塗る色の見本
// =============================================================
include <shapes_top.scad>

part = "single";

base_t  = 3;     // 顔の板の厚み
groove  = 0.6;   // 線の溝の深さ
groove_w = 0.35; // 溝を太らせる量(細すぎると刷れないため)

c_base = "#F4E3C8"; c_black = "#2A2A2A"; c_red = "#D7262E";
c_white = "#FAFAFA"; c_pink = "#F2A0A8"; c_yellow = "#F2C34B";

// 上の縁を半径 r で丸めた押し出し。r を盛り上がりの高さと同じにすると、
// 太いところほど高く、細いところほど低い、ふっくらしたドームになる
module puffy(h, r, steps = 12) {
    linear_extrude(h - r) children();
    for (k = [0 : steps - 1]) {
        z0 = h - r + r * sin(90 * k / steps);
        z1 = h - r + r * sin(90 * (k + 1) / steps);
        translate([0, 0, z0]) linear_extrude(z1 - z0 + 0.01) offset(delta = -r * (1 - cos(90 * (k + 1) / steps))) children();
    }
}

module grooves(top) translate([0, 0, top - groove]) linear_extrude(groove + 1) offset(delta = groove_w) shape_lines();

module upper() intersection() { children(); translate([-200, 0]) square([400, 400]); }   // 顔の中心より上
module lower() intersection() { children(); translate([-200, -400]) square([400, 400]); }

// 盛り上がり(顔の板の上からの高さ)。ドームの丸みは高さと同じ半径
bow_rise  = 5;     // リボン
fur_rise  = 4.5;   // 白いひげ
bell_rise = 3.5;   // ボタン
loop_y    = 47;    // これより上は吊り下げ輪(平たく、丈夫に)
loop_t    = 3.5;   // 吊り下げ輪の厚み

module bow_shape() intersection() { upper() shape_red(); translate([-200, 0]) square([400, loop_y]); }
module loop_shape() intersection() { shape_red(); translate([-200, loop_y]) square([400, 400]); }

module bow() difference() {
    union() {
        puffy(base_t + bow_rise, bow_rise) bow_shape();
        puffy(loop_t, 1) loop_shape();
    }
    grooves(base_t + bow_rise);
    translate([0, 0, base_t + bow_rise - 1.2]) linear_extrude(4) offset(delta = -0.2) shape_dark();   // 濃い赤の折り目は一段低く
}

module fur() difference() { puffy(base_t + fur_rise, fur_rise) shape_white(); grooves(base_t + fur_rise); }
module cheeks() difference() { puffy(base_t + 0.8, 0.6) shape_pink(); grooves(base_t + 0.8); }
module bell() difference() { puffy(base_t + bell_rise, bell_rise) shape_yellow(); grooves(base_t + bell_rise); }
module face_lines() linear_extrude(base_t + 0.8) shape_black();
module red_dot() linear_extrude(base_t + 0.6) lower() shape_red();
module disc() linear_extrude(base_t) shape_disc();

if (part == "single") {
    union() { disc(); bow(); fur(); cheeks(); bell(); face_lines(); red_dot(); }
} else {
    color(c_base) disc();
    color(c_red) { bow(); red_dot(); }
    color(c_white) fur();
    color(c_pink) cheeks();
    color(c_yellow) bell();
    color(c_black) face_lines();
}
