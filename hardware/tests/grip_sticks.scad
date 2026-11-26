// 試し T1: 握る所の筒の太さを決める3本(真ん中の直径 35・39・43mm)。
// 人間工学の研究で、握って一番楽な直径は手の長さの約20%(多くは 30〜40mm)。その前後を握り比べる。
// 上下の太さの比率(形)は3本とも同じにして、全体の太さだけを変える(使った人の提案)。
// 形: 下の端は真ん中の 0.93 倍、上の端は 1.10 倍。上は天面へ広がる向き、下は少し細くして土台へ広がる前の
// くびれ。比率は仮の値で、太さが決まってから別に比べる。
// 長さ 90mm、上の端は天面と同じ 29° で切る。上の面に真ん中の直径を刻む。立てたまま刷る(サポート不要)
// T1 の結果(2026-11-26): 43 は握れるが大きい、39 がちょうどいい、35 は小さめだがゲームパッドに近く使えそう。
// → 握る所の太さ(左右)は 39mm に決めた。35 は手の小さい人向け(S)の候補
diams = [35, 39, 43];
// T2: 太さ(左右)は 39mm に固定して、前後の長さだけを変える(断面の楕円の比 1.0・1.15・1.3)。
// 1.3(前後 51mm)は、既製品の首の前後の奥行き(横の写真で約51mm)とほぼ同じ
ratios = [1.0, 1.15, 1.3];
test = "T2";
len_ = 90;
k_bottom = 0.93; k_top = 1.10;   // 真ん中に対する下の端・上の端の太さ
// 太さの変わり方: 下の端→真ん中→上の端をなめらかにつなぐ(高さ方向の2次式)
function dia(d, z) = let(t = z / len_) d * (k_bottom * (1 - t) * (1 - 2 * t) + 4 * t * (1 - t) + k_top * t * (2 * t - 1));
tilt = 29;
$fn = 96;
module stick(d, r = 1) difference() {
    union() {
        scale([r, 1, 1]) rotate_extrude($fn = 96) polygon(concat([[0, 0]], [for (i = [0 : 30]) let(z = (len_ + 20) * i / 30) [dia(d, min(z, len_ + 20)) / 2, z]], [[0, len_ + 20]]));
    }
    // 上の端を天面と同じ角度で切る
    translate([0, 0, len_]) rotate([0, -tilt, 0]) translate([-50, -50, 0]) cube([100, 100, 60]);
    // 底の縁を少し面取り(台に付く側の縁の盛り上がり防止)
    scale([r, 1, 1]) difference() { translate([0, 0, -0.01]) cylinder(d = d * 1.2, h = 0.6); translate([0, 0, -0.02]) cylinder(d1 = d * k_bottom - 1.2, d2 = d * k_bottom, h = 0.62); }
}
module label(t, d) translate([0, 0, len_]) rotate([0, -tilt, 0]) translate([0, 0, -0.6])
    linear_extrude(1.2) text(t, size = d * 0.26, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
if (test == "T1") for (i = [0 : 2]) translate([i * 56, 0, 0]) difference() { stick(diams[i]); label(str(diams[i]), diams[i]); }
else for (i = [0 : 2]) translate([0, i * 50, 0]) difference() { stick(39, ratios[i]); label(["1.0", "1.15", "1.3"][i], 39); }
