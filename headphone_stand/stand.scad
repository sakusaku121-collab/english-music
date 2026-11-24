// =============================================================
// ヘッドホンスタンド(割れにくさ優先のオリジナル設計)
//
// MakerWorld で見つけたスタンド(Deltaprints「スイング」)は、はめ込み(あり継ぎ)の口の横の
// 薄い壁が積層の境目に沿って裂けた。この設計では次のようにして、同じ割れ方を起こさない。
//   1. 横から見た形を台の上に寝かせて刷る。曲げの力が積層の線に沿ってかかり、
//      層と層の間を引きはがす向きの力がかからない。サポートも要らない。
//   2. 継ぎ目の「あり」と溝は、横から見た面(刷るときの台の面)の中の形にする。溝のまわりを
//      樹脂の線がぐるっと囲むので、口が開こうとしても層の境目では裂けない。
//      接着剤もネジも使わず、差し込むだけで固定する。
//   3. 尖った角を作らない。
//
// 形: 同じ厚みの板1枚を、1本のなめらかな曲線に沿って曲げたもの。
//   土台は机に平らに置かれ、後ろで大きく曲がって立ち上がり、柱は少し前へ傾きながら
//   ゆるく弧を描き、上で前へ回り込んで腕になる。腕は真ん中が少しくぼみ(バンドが収まる)、
//   先がふわっと反り上がる(前に滑り落ちない)。
//
// 座標: x が前(腕が伸びる向き)、y が上、z が幅。
// 出力する STL は、そのまま台に置く向き(横から見た形が台の上、幅が高さ)になっている。
// =============================================================

part = "lower";        // "lower"(土台と柱の下) / "upper"(柱の上と腕) / "plate"(扇形の土台板) / "both"(確認用に組んだ姿)

W = 70;                // 幅(刷るときの高さ)
T = 8;                 // 板の厚み
base_t = T;
edge = 2;              // 幅の面の縁の面取り(角ばらないよう大きめ)
round_r = 1.5;         // 横から見た形の角の丸み

// 板の中心線は、直線と円弧をなめらかにつないだ1本の線(向きが途中で折れない)。
// 土台の先から後ろへ進み、下で曲がって立ち上がり、上で前へ回り込んで腕になる。
start = [114, T / 2];  // 土台の先(中心線)。元のモデルと同じ奥行き 122mm に収める
base_run = 88;         // 土台のまっすぐな長さ
r_low = 20;            // 下の曲がりの半径(中心線)。内側 16mm、外側 24mm
lean = 4;              // 柱の前への傾き(度)
up_len = 183;          // 柱の長さ(全体の高さが元のモデルと同じ約 244mm になる)
up_sweep = 4;          // 柱が上へ行くほど前へ反る量(度)。ゆるい弧になる
r_top = 32;            // 上の曲がりの半径(中心線)
arm_hd = -14;          // 上の曲がりを抜けたときの腕の向き(度)。下向きに入って、くぼみを作る
r_cradle = 90;         // 腕のくぼみの半径(中心線)
tip_hd = 22;           // 腕の先の向き(度)。ふわっと反り上がる
segs = [[0, base_run],
        [1, r_low, (90 - lean) - 180],
        [1, up_len / (up_sweep * PI / 180), -up_sweep],
        [1, r_top, arm_hd - (90 - lean - up_sweep)],
        [1, r_cradle, tip_hd - arm_hd]];
base_len = start[0] + T / 2;   // 土台の前の端(柱の後ろの面から)

// 上下の継ぎ目(柱の途中)。この高さの間で、板の厚みを半分ずつ重ねる
lap_y = 110;
lap_len = 45;
fit = 0.2;             // 継ぎ目の端のすき間
lap_gap = 0.05;        // 重ねる面のすき間

// 上下の継ぎ目: 重ねた面に、台形の「あり」を2本、幅の方向に通す。上の部品を横から滑り込ませる。
// 滑り込ませる先ほど少し細くしてあり、最後まで入れると締まって抜けにくい。
key_y = [lap_y + 12, lap_y + lap_len - 12];   // あり の位置(高さ)
key_d = 2.5;           // あり の出っ張り
key_w0 = 8;            // あり の根元の幅
key_w1 = 10;           // あり の先の幅(根元より広いので抜けない)
key_taper = 0.2;       // 滑り込む先の細り(片側)
key_floor = 2;         // 溝の行き止まり(上の部品の、刷るとき台に付く側)
slide_fit = 0.15;      // 滑り込ませる所のすき間

base_corner = 2;       // 板の土台の前の角の丸み(上から見て)。土台板のくぼみに隠れるので小さく

// 土台板: 元のモデルのように、柱の付け根から前へ向かって左右に広がる扇形。
// 横から見た形を寝かせて刷る本体は幅(70mm)より広くできないので、土台板を別に寝かせて刷る。
// 本体の土台を後ろから引き出しのように差し込む。くぼみの両側の縁が土台の面取りの上にかぶさるので、
// 上にも左右にも抜けない。前ほど少し狭くしてあり、奥まで入れると締まる。上の面は段差なしでそろう。
plate_floor = 1.6;     // くぼみの底の厚み
plate_x0 = 0;          // 土台板の後ろの端(柱の後ろの面にそろえる。後ろに倒れにくくする)
plate_x1 = 122;        // 土台板の前の端(元のモデルの奥行き 122mm)
plate_half_back = 42;  // 後ろの端の幅の半分
plate_half_front = 60; // 前の端の幅の半分(元のモデルの幅 120mm)
plate_front_r = 16;    // 前の角の丸み
pocket_taper = 0.15;   // くぼみの前ほど狭くする量(片側)
lip_x0 = 55;           // くぼみの縁がかぶさり始める所(これより後ろは、本体の曲がりが通るので上を開ける)

$fn = 64;

// ---- 中心線(線を少しずつ進めながら点を打つ)----
// 直線 [0, 長さ]、円弧 [1, 半径, 曲がる角度(左回りが正)]。点はおよそ 1mm おき。各点に進む向き(度)を持たせる
function seg_pts(sg, p, h) = sg[0] == 0
    ? let(n = max(1, round(sg[1]))) [for (k = [1 : n]) [p + sg[1] * k / n * [cos(h), sin(h)], h]]
    : let(R = sg[1], a = sg[2], sn = sign(a), c = p + R * [cos(h + 90 * sn), sin(h + 90 * sn)], a0 = h - 90 * sn,
          n = max(2, ceil(abs(a) * R * PI / 180)))
      [for (k = [1 : n]) [c + R * [cos(a0 + a * k / n), sin(a0 + a * k / n)], h + a * k / n]];
function turtle(list, p, h, i = 0) = i >= len(list) ? [] :
    let(pts = seg_pts(list[i], p, h), last = pts[len(pts) - 1]) concat(pts, turtle(list, last[0], last[1], i + 1));
PH = concat([[start, 180]], turtle(segs, start, 180));
P = [for (q = PH) q[0]];
HD = [for (q = PH) q[1]];
NP = len(P);
TG = [for (h = HD) [cos(h), sin(h)]];          // 接線(土台の先から腕の先へ)
NM = [for (t = TG) [t[1], -t[0]]];              // 法線(C の内側へ向く)

// 柱の範囲で、中心線が高さ y を越える所の番号
function idx_at_y(y) = [for (i = [0 : NP - 1]) if (P[i][0] < 40 && P[i][1] >= y) i][0];
i_lap0 = idx_at_y(lap_y);
i_lap1 = idx_at_y(lap_y + lap_len);

// 板の厚み: 腕は先へ向かって 8mm → 6mm に細くする(軽やかに見せる)。柱と土台は 8mm
arm_tip_t = 6;
i_arm0 = [for (i = [0 : NP - 1]) if (HD[i] <= 0) i][0];   // 上の曲がりの一番高い所から細くし始める
function th(i) = i <= i_arm0 ? T : T + (arm_tip_t - T) * (i - i_arm0) / (NP - 1 - i_arm0);
// 番号 i の所の、法線方向 a〜b の線分(接線方向に shift ずらせる)。a, b は厚みに対する割合(-0.5〜0.5)でも渡せる
function seg(i, a, b, shift = 0) = [P[i] + TG[i] * shift + NM[i] * a, P[i] + TG[i] * shift + NM[i] * b];
// 番号 i0〜i1 の帯。法線方向 a〜b。両端を接線方向に s0, s1 ずらせる
module strip(i0, i1, a, b, s0 = 0, s1 = 0) {
    for (i = [i0 : i1 - 1]) {
        k = th(i) / T; k2 = th(i + 1) / T;   // 厚みが変わる所では、a, b を厚みに合わせて縮める
        p = seg(i, a * k, b * k, i == i0 ? s0 : 0);
        q = seg(i + 1, a * k2, b * k2, i + 1 == i1 ? s1 : 0);
        polygon([p[0], p[1], q[1], q[0]]);
    }
}
module caps() {
    translate(P[0]) circle(d = T);            // 土台の前の縁
    translate(P[NP - 1]) circle(d = arm_tip_t);   // 腕の先
}
module smooth() offset(r = round_r) offset(delta = -round_r) offset(r = -round_r) offset(delta = round_r) children();

module profile() smooth() union() { strip(0, NP - 1, -T / 2, T / 2); caps(); }

module lower2d() smooth() union() {
    strip(0, i_lap0, -T / 2, T / 2);
    strip(i_lap0, i_lap1, -T / 2, -lap_gap, 0, -fit);     // 重ねる所は外側(後ろ)半分
    translate(P[0]) circle(d = T);
}
module upper2d() smooth() union() {
    strip(i_lap0, i_lap1, lap_gap, T / 2, fit, 0);        // 重ねる所は内側(前)半分
    strip(i_lap1, NP - 1, -T / 2, T / 2);
    translate(P[NP - 1]) circle(d = arm_tip_t);
}

// 横から見た形を幅の分だけ伸ばす。台に付く面と上の面の縁は、0.2mm ずつ段にして面取りする
module slab2d_extrude() {
    n = round(edge / 0.2);
    for (i = [0 : n - 1]) {
        inset = edge - i * 0.2;
        translate([0, 0, i * 0.2]) linear_extrude(0.2 + 0.001) offset(delta = -inset) children();
        translate([0, 0, W - (i + 1) * 0.2]) linear_extrude(0.2 + 0.001) offset(delta = -inset) children();
    }
    translate([0, 0, edge]) linear_extrude(W - 2 * edge) children();
}

// 涙形(下を尖らせて 45° より寝ないようにした丸)
module teardrop2d(d) union() { circle(d = d); rotate(45) square(d / 2); }

// 土台を上から見た形の前の角を丸める。刷るとき台に付く側(z=0)の角は涙形にする
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

// あり の断面(重ねた面から内側へ出る台形)。u は法線方向、v は接線方向。grow で全体を太らせる
module key2d(grow) polygon([[-0.4, -key_w0 / 2 - grow], [key_d + grow, -key_w1 / 2 - grow],
                            [key_d + grow, key_w1 / 2 + grow], [-0.4, key_w0 / 2 + grow]]);
module at_key(i) multmatrix([[NM[i][0], TG[i][0], 0, P[i][0]], [NM[i][1], TG[i][1], 0, P[i][1]], [0, 0, 1, 0], [0, 0, 0, 1]]) children();
// z0 から z1 まで。z0 の側を key_taper だけ細くする
module key3d(y, grow, z0, z1) let(i = idx_at_y(y)) at_key(i) hull() {
    translate([0, 0, z0]) linear_extrude(0.01) key2d(grow - key_taper);
    translate([0, 0, z1 - 0.01]) linear_extrude(0.01) key2d(grow);
}

module lower() {
    difference() {
        union() {
            slab2d_extrude() lower2d();
            for (y = key_y) key3d(y, 0, key_floor + slide_fit, W);
        }
        base_corner_cut();
    }
}
module upper() {
    difference() {
        slab2d_extrude() upper2d();
        for (y = key_y) key3d(y, slide_fit, key_floor, W + 1);
    }
}

// 土台板を上から見た形(x 前、y 幅。本体の幅の真ん中が y = W/2)
function plate_half(x) = plate_half_back + (plate_half_front - plate_half_back) * pow((x - plate_x0) / (plate_x1 - plate_x0), 2);
module plate2d() {
    n = 30;
    pts = concat(
        [for (i = [0 : n]) let(x = plate_x0 + i * (plate_x1 - plate_x0) / n) [x, W / 2 + plate_half(x)]],
        [for (i = [n : -1 : 0]) let(x = plate_x0 + i * (plate_x1 - plate_x0) / n) [x, W / 2 - plate_half(x)]]);
    offset(r = 3) offset(delta = -3)
    intersection() {
        polygon(pts);
        hull() {   // 前の角を大きく丸める
            translate([plate_x0 - 1, W / 2 - plate_half_front - 1]) square([1, 2 * plate_half_front + 2]);
            translate([plate_x1 - plate_front_r, W / 2 + plate_half_front - plate_front_r]) circle(r = plate_front_r);
            translate([plate_x1 - plate_front_r, W / 2 - plate_half_front + plate_front_r]) circle(r = plate_front_r);
        }
    }
}
// くぼみの断面(u = 本体の幅の方向、v = 底からの高さ)。hw は幅の半分
module pocket2d(hw) polygon([[W / 2 - hw, -1], [W / 2 + hw, -1], [W / 2 + hw, T - edge], [W / 2 + hw - edge, T],
                             [W / 2 + hw - edge, T + 5], [W / 2 - hw + edge, T + 5], [W / 2 - hw + edge, T], [W / 2 - hw, T - edge]]);
module at_x(x) multmatrix([[0, 0, 1, x], [1, 0, 0, 0], [0, 1, 0, plate_floor], [0, 0, 0, 1]]) linear_extrude(0.01) children();
module pocket() {
    hull() {
        at_x(lip_x0) pocket2d(W / 2 + fit);
        at_x(base_len + fit) pocket2d(W / 2 + fit - pocket_taper);
    }
    translate([plate_x0 - 5, -fit, plate_floor]) cube([lip_x0 - plate_x0 + 5.01, W + 2 * fit, T + 5]);
}
// 刷る向きのまま出力(上から見た形が台の上、くぼみは上の面)
module plate() {
    th = T + plate_floor;
    difference() {
        union() {
            linear_extrude(0.4) offset(delta = -0.4) plate2d();                   // 台に付く縁の面取り
            translate([0, 0, 0.4]) linear_extrude(th - 2) plate2d();
            for (i = [0 : 7]) translate([0, 0, th - 1.6 + i * 0.2])                // 上の縁の面取り
                linear_extrude(0.2 + 0.001) offset(delta = -(i + 1) * 0.2) plate2d();
        }
        pocket();
    }
}

if (part == "plate") plate();
else if (part == "lower") lower();
else if (part == "upper") upper();
else if (part == "both") { color("#444") lower(); color("#777") upper(); }
else if (part == "profile") profile();
