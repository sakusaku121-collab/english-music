// 完成イメージ(試作6号〜、body2.scad)
include <body2.scad>
$fn = 64;
c_body = "#F4F3EF"; c_key = "#DEDCD6"; c_dark = "#2E2F33"; c_ink = "#3A3B40";
font = "Liberation Sans:style=Bold";


module keycap(w = 12, d = 12, h = 4, r = 2)
    hull() for (sx = [-1, 1], sy = [-1, 1]) {
        translate([sx * (w / 2 - r), sy * (d / 2 - r), -1]) cylinder(r = r, h = 0.01);
        translate([sx * (w / 2 - r - 0.6), sy * (d / 2 - r - 0.6), h - r]) sphere(r);
    }
module legend(t, h, size = 3.4)
    translate([0, 0, h - 0.25]) rotate([0, 0, -90]) linear_extrude(0.5) text(t, size = size, font = font, halign = "center", valign = "center");

color(c_body) body();
for (i = [0 : len(button_layout) - 1]) on_head(button_layout[i][0], button_layout[i][1]) {
    color(c_key) keycap(); color(c_ink) legend(key_names[i], 4, len(key_names[i]) > 1 ? 2.8 : 3.6);
}
on_head(esc_pos[0], esc_pos[1]) { color(c_dark) keycap(); color(c_body) legend("ESC", 4, 2.6); }
on_head(0, 0) {
    color(c_dark) { cylinder(r = 3.5, h = 7); translate([0, 0, 6]) cylinder(r = 10, h = 4); }
}
for (i = [0 : len(side_button_z) - 1]) on_front(side_button_z[i])
    color(i == 1 ? c_dark : c_key) keycap(w = 11, d = 20, h = 3);
