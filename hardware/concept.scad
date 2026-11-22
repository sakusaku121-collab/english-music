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

module keycap(w = 12, d = 12, h = 4, r = 2) {
    hull() {
        for (sx = [-1, 1], sy = [-1, 1]) {
            translate([sx * (w / 2 - r), sy * (d / 2 - r), -1]) cylinder(r = r, h = 0.01);
            translate([sx * (w / 2 - r - 0.6), sy * (d / 2 - r - 0.6), h - r]) sphere(r);
        }
    }
}

// 天面・床用(手前 -X から見て読める向き)
module legend(t, h, size = 3.4) {
    translate([0, 0, h - 0.25]) rotate([0, 0, -90])
        linear_extrude(0.5) text(t, size = size, font = font, halign = "center", valign = "center");
}

// 前面用(モニター側 +X から見て読める向き)
module side_legend(t, h) {
    translate([0, 0, h - 0.25]) rotate([0, 0, 90])
        linear_extrude(0.5) text(t, size = 2.6, font = font, halign = "center", valign = "center");
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

// 右側面の USB-C から出るケーブル
module usb_cable() {
    color(c_dark) {
        translate([10, base_y0 + 1, 8]) rotate([90, 0, 0]) scale([1.6, 1, 1]) cylinder(r = 3.2, h = 8);
        hull() {
            translate([10, base_y0 - 7, 8]) sphere(2.2);
            translate([14, base_y0 - 30, 3]) sphere(2.2);
        }
        hull() {
            translate([14, base_y0 - 30, 3]) sphere(2.2);
            translate([60, base_y0 - 70, 2.2]) sphere(2.2);
        }
    }
}

color(c_body) body();

// 天面(親指)
for (i = [0 : len(button_layout) - 1])
    on_head(button_layout[i][0], button_layout[i][1]) {
        color(c_key) keycap();
        color(c_ink) legend(top_labels[i], 4, len(top_labels[i]) > 1 ? 2.8 : 3.6);
    }
on_head(esc_pos[0], esc_pos[1]) {
    color(c_dark) keycap();
    color(c_body) legend("ESC", 4, 2.6);
}
on_head(0, 0) {
    color(c_well) difference() {
        cylinder(r = 14, h = 0.8);
        translate([0, 0, -1]) cylinder(r = 12, h = 3);
    }
    color(c_dark) stick_cap();
}

// 前面(人差し指・中指)
for (i = [0 : len(side_button_z) - 1])
    on_front(side_button_z[i]) {
        color(i == 2 ? c_dark : c_key) keycap(w = 9, d = 20, h = 3);
        color(i == 2 ? c_body : c_ink) side_legend(side_labels[i], 3);
    }

// くぼみの床(薬指・小指で押し下げる、沈めた低いボタン)
for (i = [0 : len(base_buttons) - 1])
    on_base(base_buttons[i]) {
        color(c_well) translate([0, 0, -0.6]) keycap(w = 13, d = 13, h = 1.2, r = 2.5);
        color(c_key) keycap(w = 10, d = 12, h = 2.2, r = 1.6);
        color(c_ink) legend(base_labels[i], 2.2, 2.2);
    }

usb_cable();
