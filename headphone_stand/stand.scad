// =============================================================
// ヘッドホンスタンド(割れにくさ優先のオリジナル設計)
//
// MakerWorld で見つけたスタンドは、はめ込み(あり継ぎ)の口の横の薄い壁が
// 積層の境目に沿って裂けた。この設計では次のようにして、同じ割れ方を起こさない。
//   1. 横から見た形を台の上に寝かせて刷る。曲げの力が積層の線に沿ってかかり、
//      層と層の間を引きはがす向きの力がかからない。サポートも要らない。
//   2. くさびになる継ぎ手を使わない。A1 mini(180mm角)に入れるため上下2つに分けるが、
//      継ぎ目は「相欠き」(厚みを半分ずつ重ねる)にして、接着剤で面どうしを貼る。
//      位置合わせのダボは刷り方向に沿って横向きに付くので、層の境目で折れない。
//   3. 内側の角はすべて丸める(力が集まる尖った角を作らない)。手が触れる縁は面取りする。
//
// 座標: x が前(ヘッドホンを掛ける腕が伸びる向き)、y が上、z が幅。
// 出力する STL は、そのまま台に置く向き(横から見た形が台の上、幅が高さ)になっている。
// =============================================================

part = "lower";        // "lower"(土台と柱の下) / "upper"(柱の上と腕) / "both"(確認用に組んだ姿)
                       // "one"(継ぎ目なしの一体。A1 mini に入るのは H が 175mm まで)
                       // "foot"(左右に倒れにくくする幅広の足の板。土台をはめて接着する)

H = 225;               // 全体の高さ。エレコム HS-HP06SUBK(高さ約200mm)が足の板に当たらない高さ
W = 50;                // 幅(刷るときの高さ)
T = 12;                // 柱と腕の厚み
base_len = 125;        // 土台の前後の長さ
base_t = 8;            // 土台の厚み
arm_len = 105;         // 腕の先までの長さ(柱の後ろの面から)
r_bend = 28;           // 柱から腕へ曲がる所の内側の半径
r_foot = 30;           // 柱と土台の間の内側の丸み
lip_h = 4;             // 腕の先の返し(ヘッドホンが滑り落ちないため)
edge = 1.2;            // 幅の面の縁の面取り
round_r = 2;           // 横から見た形の角の丸み

lap_y = 110;           // 継ぎ目の下の端の高さ
lap_len = 45;          // 継ぎ目の重なりの長さ
fit = 0.2;             // 継ぎ目のすき間
peg_d = 5;             // ダボの太さ
peg_len = 4;           // ダボの長さ(重ねた相手の厚み T/2 より短く)
peg_y = [lap_y + 12, lap_y + lap_len - 12];

// 足の板: スタンド本体の幅(W)だけだと左右に倒れやすいので、幅の広い板を別に刷って土台をはめ、接着する
foot_w = 110;          // 足の板の幅(左右)
foot_t = 6;            // 足の板の厚み
foot_pocket = 3;       // 土台がはまるくぼみの深さ
foot_margin = 6;       // 土台の前後に足す長さ

$fn = 96;

bend_c = [T + r_bend, H - T - r_bend];   // 曲がりの中心

module profile() {
    // 尖った角を作らないよう、凹んだ角も出た角も丸める
    offset(r = round_r) offset(delta = -round_r)
    offset(r = -round_r) offset(delta = round_r)
    union() {
        // 土台(前の縁は丸く)
        hull() {
            square([1, base_t]);
            translate([base_len - base_t / 2, base_t / 2]) circle(d = base_t);
            translate([0, 0]) square([base_len - base_t / 2, 0.01]);
        }
        // 柱
        square([T, bend_c[1]]);
        // 柱と土台の間の丸み
        difference() {
            translate([T, base_t]) square([r_foot, r_foot]);
            translate([T + r_foot, base_t + r_foot]) circle(r = r_foot);
        }
        // 柱から腕への曲がり
        intersection() {
            difference() {
                translate(bend_c) circle(r = r_bend + T);
                translate(bend_c) circle(r = r_bend);
            }
            translate([0, bend_c[1]]) square([bend_c[0], H - bend_c[1]]);
        }
        // 腕
        translate([bend_c[0], H - T]) square([arm_len - bend_c[0], T]);
        // 腕の先の返し
        translate([arm_len - T / 2, H - T / 2]) hull() {
            circle(d = T);
            translate([0, lip_h]) circle(d = T * 0.6);
        }
    }
}

// 横から見た形を幅の分だけ伸ばす。台に付く面と上の面の縁は、0.2mm ずつ段にして面取りする
module slab2d_extrude() {
    steps = round(edge / 0.2);
    for (i = [0 : steps - 1]) {
        inset = edge - i * 0.2;
        translate([0, 0, i * 0.2]) linear_extrude(0.2 + 0.001) offset(delta = -inset) children();
        translate([0, 0, W - (i + 1) * 0.2]) linear_extrude(0.2 + 0.001) offset(delta = -inset) children();
    }
    translate([0, 0, edge]) linear_extrude(W - 2 * edge) children();
}

// ダボと穴は横向き(x 方向)。刷るとき上になる側(+z)を尖らせた涙形にして、穴の天井が垂れないようにする
module teardrop2d(d) {
    union() {
        circle(d = d);
        rotate(45) square(d / 2);
    }
}
module peg(len, d) rotate([0, 90, 0]) rotate([0, 0, 90]) linear_extrude(len) teardrop2d(d);

module lower2d() {
    union() {
        intersection() { profile(); translate([-1, -1]) square([base_len + 10, lap_y + 1]); }
        // 重ねる所は後ろ半分の厚み
        translate([0, lap_y - 0.01]) square([T / 2, lap_len - fit]);
    }
}
module upper2d() {
    union() {
        intersection() { profile(); translate([-1, lap_y + lap_len]) square([base_len + 10, H]); }
        // 重ねる所は前半分の厚み
        translate([T / 2, lap_y + fit]) square([T / 2, lap_len - fit + 0.01]);
    }
}

module lower() {
    union() {
        slab2d_extrude() lower2d();
        for (y = peg_y) translate([T / 2 - 0.01, y, W / 2]) peg(peg_len, peg_d);
    }
}
module upper() {
    difference() {
        slab2d_extrude() upper2d();
        for (y = peg_y) translate([T / 2 - 0.01, y, W / 2]) peg(peg_len + 0.5, peg_d + 2 * fit);
    }
}

// 足の板。刷る向き(板を台に寝かせる)のまま出力する。くぼみは上の面
module foot() {
    L = base_len + 2 * foot_margin;
    difference() {
        translate([-foot_margin, -(foot_w - W) / 2, 0])
            linear_extrude(foot_t) offset(r = 10) offset(delta = -10) square([L, foot_w]);
        translate([-fit, -fit, foot_t - foot_pocket]) cube([base_len + 2 * fit, W + 2 * fit, foot_pocket + 1]);
    }
}

if (part == "foot") foot();
else if (part == "one") slab2d_extrude() profile();
else if (part == "lower") lower();
else if (part == "upper") upper();
else if (part == "both") { color("#444") lower(); color("#777") upper(); }
