// =============================================================
// 完成イメージ(色付きレンダー用)。印刷には case.scad を使う。
// =============================================================
include <body.scad>

$fn = 96;

c_body = "#F4F3EF";
c_key  = "#DEDCD6";
c_well = "#BDBAB3";
c_dark = "#2E2F33";
c_ink  = "#3A3B40";

font = "Liberation Sans:style=Bold";

top_labels  = ["3", "4", "Tab", "F", "Q", "E", "X", "1", "2"];
side_labels = ["G", "CTRL", "SHIFT", "SPACE"];
base_labels = ["REV", "F1", "VIEW"];

module keycap(w = 10, d = 10, h = 4, r = 2) {
    hull() {
        for (sx = [-1, 1], sy = [-1, 1]) {
            translate([sx * (w / 2 - r), sy * (d / 2 - r), -1]) cylinder(r = r, h = 0.01);
            translate([sx * (w / 2 - r - 0.6), sy * (d / 2 - r - 0.6), h - r]) sphere(r);
        }
    }
}

// 天面・土台用(閲覧者はユーザー側 -X から見る)
module legend(t, h, size = 3.2) {
    translate([0, 0, h - 0.25]) rotate([0, 0, -90])
        linear_extrude(0.5) text(t, size = size, font = font, halign = "center", valign = "center");
}

// 柱前面用(閲覧者はモニター側 +X から見る)
module side_legend(t, h) {
    translate([0, 0, h - 0.25]) rotate([0, 0, 90])
        linear_extrude(0.5) text(t, size = 2.0, font = font, halign = "center", valign = "center");
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

module usb_cable() {
    color(c_dark) {
        hull() {
            translate([44, 0, 5]) rotate([0, 90, 0]) scale([1, 1.6, 1]) cylinder(r = 3.2, h = 8);
        }
        hull() {
            translate([52, 0, 5]) sphere(2.2);
            translate([80, 0, 3]) sphere(2.2);
        }
        hull() {
            translate([80, 0, 3]) sphere(2.2);
            translate([130, -12, 2.2]) sphere(2.2);
        }
    }
}

color(c_body) body();

// 天面
for (i = [0 : len(button_layout) - 1])
    on_head(button_layout[i][0], button_layout[i][1]) {
        color(c_key) keycap();
        color(c_ink) legend(top_labels[i], 4, len(top_labels[i]) > 1 ? 2.6 : 3.4);
    }
on_head(esc_pos[0], esc_pos[1]) {
    color(c_dark) keycap();
    color(c_body) legend("ESC", 4, 2.4);
}
on_head(stick_pos[0], stick_pos[1]) {
    color(c_well) difference() {
        cylinder(r = 14, h = 0.8);
        translate([0, 0, -1]) cylinder(r = 12, h = 3);
    }
    color(c_dark) stick_cap();
}

// 柱前面(人差し指・中指)
for (i = [0 : len(side_button_z) - 1])
    on_front(side_button_z[i]) {
        color(i == 2 ? c_dark : c_key) keycap(w = 8, d = 15, h = 3);
        color(i == 2 ? c_body : c_ink) side_legend(side_labels[i], 3);
    }

// 土台の床(手をずらして押す、沈めた低いボタン)
for (i = [0 : len(base_buttons) - 1])
    on_base(base_buttons[i]) {
        color(c_well) translate([0, 0, -0.6]) keycap(w = 13, d = 13, h = 1.2, r = 2.5);
        color(c_key) keycap(w = 10, d = 12, h = 2.2, r = 1.6);
        color(c_ink) legend(base_labels[i], 2.2, 2.2);
    }

usb_cable();
