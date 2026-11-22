// =============================================================
// クリスマスオーナメント(娘さんの絵から)
//
// AMS なしで刷れるように色ごとにパーツを分けている。
//   part = "base"   : ベージュの顔の板 + 黒い顔のパーツ(途中で一時停止して黒に替える)
//   part = "red"    : リボン + 吊り下げ輪 + 赤い点
//   part = "white"  : ふわふわの帯(左右2個)
//   part = "pink"   : ほっぺ(2個)
//   part = "yellow" : ボタン
//   part = "assembled" : 組み上がりの見本(印刷用ではない)
//   part = "single"    : 白1色で刷って、あとから塗る版(いまの既定)
//   part = "painted"   : single に塗る色を付けた見本
// 板にはパーツの形のくぼみがあり、はめて瞬間接着剤で留める。
// =============================================================

part = "single";
$fn = 64;

R        = 40;    // 顔の板の半径
base_t   = 3;     // 板の厚み(ここで一時停止して黒に替える)
black_t  = 0.8;   // 黒い顔のパーツの盛り上がり
pocket_d = 1.0;   // はめ込むくぼみの深さ
fit_gap  = 0.15;  // くぼみ側のすき間
line_w   = 1.3;   // 黒い線の太さ

c_base = "#EAD9C2"; c_black = "#2A2A2A"; c_red = "#D7262E";
c_white = "#FAFAFA"; c_pink = "#F2A0A8"; c_yellow = "#E7B92E";

// ---------- 2D の部品 ----------

function arcpts(c, r, a0, a1, n = 24) = [for (i = [0 : n]) let (a = a0 + (a1 - a0) * i / n) c + r * [cos(a), sin(a)]];
function rev(l) = [for (i = [len(l) - 1 : -1 : 0]) l[i]];

module arc2d(c, r, a0, a1, w = line_w) {
    polygon(concat(arcpts(c, r + w / 2, a0, a1), rev(arcpts(c, r - w / 2, a0, a1))));
    for (a = [a0, a1]) translate(c + r * [cos(a), sin(a)]) circle(d = w);
}

eye_pos   = [[-12, 4], [12, 4]];
cheek_pos = [[-21, -7], [21, -7]];
button_pos = [0, -22];
red_dot   = [0, -31.5];
black_dot = [0, -36];

module eyes2d()
    for (p = eye_pos) translate(p) difference() {
        circle(r = 4.5);
        translate([1.6, 1.6]) circle(r = 1.4);   // 光(板のベージュが見える)
    }

module brows2d() {
    arc2d([-13, 0], 14, 95, 160);
    arc2d([ 13, 0], 14, 20, 85);
}

module mouth2d() {
    arc2d([-2, -4], 2, 200, 340);
    arc2d([ 2, -4], 2, 200, 340);
    arc2d([ 0, -6.2], 1.6, 215, 325);
}

module black2d() {
    eyes2d(); brows2d(); mouth2d();
    translate(black_dot) circle(r = 1.6);
}

module cheek2d(p) translate(p) scale([5.5, 3.8]) circle(r = 1);

module fur2d(side) {   // side = -1 左, 1 右
    intersection() {
        union() {   // 丸を3段に重ねて雲の形にする(四角い辺を作らない)
            for (x = [9 : 6.5 : 36]) translate([side * x, -16 + (x - 9) * 0.05]) circle(r = 4.4);
            for (x = [8 : 6.5 : 36]) translate([side * (x + 1.5), -20.5]) circle(r = 4.6);
            for (x = [8 : 6.5 : 32]) translate([side * (x + 3), -25]) circle(r = 4.0);
        }
        circle(r = R - 0.8);
        translate([side > 0 ? 4 : -R, -R]) square([R - 4, R]);
    }
}

module button2d() translate(button_pos) circle(r = 5);

module bow2d() {
    for (s = [-1, 1]) {
        hull() { translate([0, 37]) circle(r = 3); translate([s * 14, 40]) circle(r = 8.5); }
        difference() {
            hull() { translate([s * 3, 34]) circle(r = 2.8); translate([s * 12, 24]) circle(r = 2.8); }
            translate([s * 12.5, 21.5]) rotate(s * 40) square([4, 4], center = true);
        }
    }
}

module knot2d() translate([0, 37]) offset(r = 1.5) square([6, 5], center = true);

module hanger2d() translate([0, 55]) difference() {
    scale([8, 16]) circle(r = 1);
    scale([8 - 3.5, 16 - 3.5]) circle(r = 1);
}

// ---------- 3D ----------

// 上の縁を丸めた押し出し(ふっくらさせる)
module puffy(h, r) {
    linear_extrude(h - r) children();
    for (k = [0 : 5]) {
        z0 = h - r + r * sin(90 * k / 6);
        z1 = h - r + r * sin(90 * (k + 1) / 6);
        translate([0, 0, z0]) linear_extrude(z1 - z0 + 0.01) offset(delta = -r * (1 - cos(90 * (k + 1) / 6))) children();
    }
}

module pocket(h = pocket_d) translate([0, 0, base_t - h]) linear_extrude(h + 0.01) offset(delta = fit_gap) children();

module base_part() {
    color(c_base) difference() {
        cylinder(r = R, h = base_t, $fn = 160);
        for (p = cheek_pos) pocket() cheek2d(p);
        pocket() fur2d(-1);
        pocket() fur2d(1);
        pocket() button2d();
        pocket() translate(red_dot) circle(r = 1.4);
    }
    color(c_black) translate([0, 0, base_t]) linear_extrude(black_t) black2d();
}

module fur_part(side) color(c_white) puffy(pocket_d + 2.2, 1.8) offset(delta = -0.1) fur2d(side);

module cheek_part(p) color(c_pink) difference() {
    puffy(pocket_d + 0.8, 0.6) offset(delta = -0.1) cheek2d(p);
    for (i = [-1 : 1])
        translate([p[0] + i * 1.8, p[1], pocket_d + 0.4]) rotate(-20)
            linear_extrude(1) square([0.8, 3.4], center = true);
}

module button_part() color(c_yellow) difference() {
    puffy(pocket_d + 1.6, 0.8) offset(delta = -0.1) button2d();
    translate([button_pos[0], button_pos[1], pocket_d + 1.2])
        linear_extrude(1) difference() { circle(r = 3.6); circle(r = 3.0); }
}

module red_part() color(c_red) {
    puffy(3.2, 1.4) bow2d();
    puffy(4.2, 1.4) knot2d();
    linear_extrude(3) hanger2d();
    translate(red_dot) cylinder(r = 1.3, h = pocket_d + 0.5);
}

// 白1色で刷って、あとから塗る版。色ごとに高さを変えて、境目を段差にしている
module single_part() {
    top = base_t;
    cylinder(r = R, h = top, $fn = 160);
    linear_extrude(top + black_t) black2d();
    for (p = cheek_pos) difference() {
        puffy(top + 0.6, 0.5) cheek2d(p);
        for (i = [-1 : 1])
            translate([p[0] + i * 1.8, p[1], top + 0.3]) rotate(-20)
                linear_extrude(1) square([0.8, 3.4], center = true);
    }
    puffy(top + 2.2, 1.8) fur2d(-1);
    puffy(top + 2.2, 1.8) fur2d(1);
    difference() {
        puffy(top + 1.6, 0.8) button2d();
        translate([button_pos[0], button_pos[1], top + 1.2])
            linear_extrude(1) difference() { circle(r = 3.6); circle(r = 3.0); }
    }
    translate(red_dot) cylinder(r = 1.3, h = top + 0.6);
    puffy(top + 3.2, 1.4) bow2d();
    puffy(top + 4.2, 1.4) knot2d();
    linear_extrude(3) hanger2d();
}

// 塗る色の見本(single_part と同じ形に色を付けたもの)
module painted_preview() {
    top = base_t;
    color(c_base) cylinder(r = R, h = top, $fn = 160);
    color(c_black) linear_extrude(top + black_t) black2d();
    color(c_pink) for (p = cheek_pos) puffy(top + 0.6, 0.5) cheek2d(p);
    color(c_white) { puffy(top + 2.2, 1.8) fur2d(-1); puffy(top + 2.2, 1.8) fur2d(1); }
    color(c_yellow) puffy(top + 1.6, 0.8) button2d();
    color(c_red) {
        translate(red_dot) cylinder(r = 1.3, h = top + 0.6);
        puffy(top + 3.2, 1.4) bow2d();
        puffy(top + 4.2, 1.4) knot2d();
        linear_extrude(3) hanger2d();
    }
}

// ---------- 出力 ----------

if (part == "single") {
    single_part();
} else if (part == "painted") {
    painted_preview();
} else if (part == "assembled") {
    base_part();
    lift = base_t - pocket_d;
    translate([0, 0, lift]) { fur_part(-1); fur_part(1); button_part(); for (p = cheek_pos) cheek_part(p); }
    translate([0, 0, base_t]) red_part();
} else if (part == "base") {
    base_part();
} else if (part == "red") {
    red_part();
} else if (part == "white") {
    translate([0, 12, 0]) fur_part(-1);
    translate([0, -12, 0]) fur_part(1);
} else if (part == "pink") {
    for (p = cheek_pos) translate([-p[0] * 0.5, -p[1], 0]) cheek_part(p);
} else if (part == "yellow") {
    translate(-button_pos) button_part();
}
