// =============================================================
// 完成イメージ(色付きレンダー用)。印刷には case.scad を使う。
// =============================================================
include <body.scad>

$fn = 96;

c_body = "#F4F3EF";
c_key  = "#DEDCD6";
c_dark = "#2E2F33";

module keycap(w = 10, d = 10, h = 4, r = 2) {
    hull() {
        for (sx = [-1, 1], sy = [-1, 1]) {
            translate([sx * (w / 2 - r), sy * (d / 2 - r), -1]) cylinder(r = r, h = 0.01);
            translate([sx * (w / 2 - r - 0.6), sy * (d / 2 - r - 0.6), h - r]) sphere(r);
        }
    }
}

module stick_cap() {
    cylinder(r = 3.5, h = 7);
    translate([0, 0, 6])
        difference() {
            hull() {
                cylinder(r = 10, h = 1);
                translate([0, 0, 3]) cylinder(r = 9.4, h = 1.4);
            }
            translate([0, 0, 4.4 + 20 - 1.2]) sphere(20);
        }
}

color(c_body) body();

for (p = button_layout) on_head(p[0], p[1]) color(c_key) keycap();
on_head(esc_pos[0], esc_pos[1]) color(c_dark) keycap();

on_head(stick_pos[0], stick_pos[1]) {
    color(c_key) difference() {
        cylinder(r = 14, h = 0.8);
        translate([0, 0, -1]) cylinder(r = 12, h = 3);
    }
    color(c_dark) stick_cap();
}

for (z = side_button_z) on_front(z) color(c_key) keycap(w = 8, d = 15, h = 3);
