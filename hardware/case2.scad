// 印刷用(試作6号〜、今は試作8号の形)。外形は body2.scad。中は詰まったまま(軽くするのはスライサーのインフィルで)。
// 穴は、キーとスティックの位置を確かめるための目印。
include <body2.scad>
$fn = 48;
difference() {
    body();
    on_head(0, 0) translate([0, 0, -20]) cylinder(d = 30, h = 30);
    for (p = concat(button_layout, [esc_pos])) on_head(p[0], p[1]) translate([0, 0, -3]) cylinder(d = 6.2, h = 13);   // 目印の穴。縁が 4mm と薄いので 3mm だけ
    for (z = side_button_z) on_front(z) cube([9.5, 20.5, 10], center = true);
}
