// 試し T1: 握る所の筒の太さを決める3本(直径 35・39・43mm)。
// 人間工学の研究で、握って一番楽な直径は手の長さの約20%(多くは 30〜40mm)。その前後を握り比べる。
// 長さ 90mm、上の端は天面と同じ 29° で切る。上の面に直径を浮き彫りにする。立てたまま刷る(サポート不要)
diams = [35, 39, 43];
len_ = 90;
tilt = 29;
$fn = 96;
module stick(d) difference() {
    union() {
        cylinder(d = d, h = len_);
        translate([0, 0, len_ - 0.01]) intersection() {
            translate([0, 0, -1]) rotate([0, -tilt, 0]) translate([-50, -50, 0]) cube([100, 100, 1.6]);   // 刻む文字の台
            cylinder(d = d, h = 30);
        }
    }
    // 上の端を天面と同じ角度で切る
    translate([0, 0, len_]) rotate([0, -tilt, 0]) translate([-50, -50, 0]) cube([100, 100, 60]);
    // 底の縁を少し面取り(台に付く側の縁の盛り上がり防止)
    difference() { translate([0, 0, -0.01]) cylinder(d = d + 2, h = 0.6); translate([0, 0, -0.02]) cylinder(d1 = d - 1.2, d2 = d, h = 0.62); }
}
module label(d) translate([0, 0, len_]) rotate([0, -tilt, 0]) translate([0, 0, -0.6])
    linear_extrude(1.2) text(str(d), size = d * 0.32, halign = "center", valign = "center", font = "Liberation Sans:style=Bold");
for (i = [0 : 2]) translate([i * 52, 0, 0]) difference() { stick(diams[i]); label(diams[i]); }
