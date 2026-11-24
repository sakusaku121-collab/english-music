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

H = 225;               // 全体の高さ。エレコム HS-HP06SUBK(高さ約200mm)が土台に当たらない高さ
W = 70;                // 幅(刷るときの高さ)。左右に倒れにくいよう広め
// 元のモデル(Deltaprints)と同じく、同じ厚みの板1枚を曲げたような形にする。
// 曲がる所は内側と外側が同じ中心の円(板を曲げたときの形)。元のモデルの板は約5mmで、PLA だと割れたので厚くした
T = 8;                 // 板の厚み(柱・腕・土台・曲がりすべて同じ)
base_t = T;
base_len = 130;        // 土台の前後の長さ(柱の後ろの面から)
arm_len = 105;         // 腕の先までの長さ(柱の後ろの面から)
r_bend = 40;           // 柱から腕へ曲がる所の内側の半径
r_foot = 16;           // 柱から土台へ曲がる所の内側の半径。外側は 24mm。
                       // 大きくすると、机に付く所が前へ下がって、スタンドだけのときに後ろへ倒れる
arm_sag = 3;           // 腕の真ん中のくぼみの深さ(バンドが収まる)
arm_curl = 7;          // 腕の先の反り上がり(前に滑り落ちない)
base_corner = 12;      // 土台の前の角の丸み(上から見て)
edge = 2;              // 幅の面の縁の面取り(角ばらないよう大きめ)
round_r = 2;           // 横から見た形の角の丸み

lap_y = 110;           // 継ぎ目の下の端の高さ
lap_len = 45;          // 継ぎ目の重なりの長さ
fit = 0.2;             // 継ぎ目のすき間
peg_d = 5;             // ダボの太さ
peg_len = 2.5;         // ダボの長さ(重ねた相手の厚み T/2 より短く)
peg_hole = 3;          // ダボ穴の深さ(表に 1mm 残る)
peg_y = [lap_y + 12, lap_y + lap_len - 12];

$fn = 96;

bend_c = [T + r_bend, H - T - r_bend];   // 曲がりの中心

foot_c = [T + r_foot, T + r_foot];        // 下の曲がりの中心

module profile() {
    // 尖った角を作らないよう、凹んだ角も出た角も丸める
    offset(r = round_r) offset(delta = -round_r)
    offset(r = -round_r) offset(delta = round_r)
    union() {
        // 土台(前の縁は丸く。上から見た前の角は lower() で丸める)
        hull() {
            translate([foot_c[0], 0]) square([1, base_t]);
            translate([base_len - base_t / 2, base_t / 2]) circle(d = base_t);
        }
        // 柱から土台への曲がり(板を曲げた形)
        intersection() {
            difference() {
                translate(foot_c) circle(r = r_foot + T);
                translate(foot_c) circle(r = r_foot);
            }
            square([foot_c[0] + 0.01, foot_c[1] + 0.01]);
        }
        // 柱
        translate([0, foot_c[1]]) square([T, bend_c[1] - foot_c[1]]);
        // 柱から腕への曲がり
        intersection() {
            difference() {
                translate(bend_c) circle(r = r_bend + T);
                translate(bend_c) circle(r = r_bend);
            }
            translate([0, bend_c[1]]) square([bend_c[0], H - bend_c[1]]);
        }
        // 腕: 板そのものをしならせた形。真ん中がくぼみ(バンドが収まる所)、先が反り上がる
        arm_path = [for (i = [0 : 40]) let(t = i / 40) arm_center(t)];
        for (i = [0 : len(arm_path) - 2]) hull() {
            translate(arm_path[i]) circle(d = T);
            translate(arm_path[i + 1]) circle(d = T);
        }
    }
}

// 腕の板の中心線。t=0 が曲がりの終わり(水平につながる)、t=1 が先
// 高さ = 元の高さ - arm_sag·sin²(πt) + arm_curl·t³  → 根元は水平、真ん中で下がり、先で反り上がる
function arm_center(t) = [bend_c[0] + t * (arm_len - T / 2 - bend_c[0]),
                          H - T / 2 - arm_sag * pow(sin(180 * t), 2) + arm_curl * pow(t, 3)];

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

// 土台を上から見た形の前の角を丸める。刷るとき台に付く側(z=0)の角は、45° より寝ないよう涙形にする
module base_top2d() {
    r = base_corner;
    intersection() {
        hull() {
            square([base_len - r, W]);
            translate([base_len - r, W - r]) circle(r = r);
            translate([base_len - r, r]) rotate(180) teardrop2d(2 * r);
        }
        translate([-1, 0]) square([base_len + 2, W]);
    }
}
module base_corner_cut() {
    difference() {
        translate([base_len - base_corner - 1, -1, -1]) cube([base_corner + 10, base_t + 3, W + 2]);
        rotate([90, 0, 0]) translate([0, 0, -(base_t + 3)]) linear_extrude(base_t + 5) base_top2d();
    }
}

module lower() {
    difference() {
        union() {
            slab2d_extrude() lower2d();
            for (y = peg_y) translate([T / 2 - 0.01, y, W / 2]) peg(peg_len, peg_d);
        }
        base_corner_cut();
    }
}
module upper() {
    difference() {
        slab2d_extrude() upper2d();
        for (y = peg_y) translate([T / 2 - 0.01, y, W / 2]) peg(peg_hole, peg_d + 2 * fit);
    }
}

if (part == "one") slab2d_extrude() profile();
else if (part == "lower") lower();
else if (part == "upper") upper();
else if (part == "both") { color("#444") lower(); color("#777") upper(); }
