// =============================================================
// 印刷用の握り心地確認モデル(外形は body.scad、完成イメージは concept.scad)
//
// 中身は詰まったソリッド。軽量化はスライサーのインフィル設定に任せる。
// 基板・配線用の空洞と底蓋は、外形が確定してから設計する。
// 穴は「親指がそこに届くか」を確かめるための目印。
// =============================================================
include <body.scad>

$fn = 64;

btn_hole     = 6.2;   // タクトスイッチキャップ径+クリアランス
stick_hole_d = 30;    // スティック可動部の開口径
side_btn_w   = 13;
side_btn_h   = 7;

difference() {
    body();
    on_head(stick_pos[0], stick_pos[1])
        translate([0, 0, -30]) cylinder(d = stick_hole_d, h = 40);
    for (p = concat(button_layout, [esc_pos]))
        on_head(p[0], p[1]) translate([0, 0, -20]) cylinder(d = btn_hole, h = 30);
    for (z = side_button_z)
        on_front(z) cube([side_btn_h, side_btn_w, 10], center = true);
    for (b = base_buttons)
        on_base(b) translate([0, 0, -2.5]) cube([13, 13, 6], center = true);
}

// TODO(外形確定後):
// - 内部空洞 + 底蓋 + M3インサートボス
// - スティックモジュールの取付ボス、Kailh choc 用の角穴
// - パネルマウントUSB-C口(レビュー分析#9: 直付け面一コネクタは破損する)
// - ESC + 予備2ボタンの最終位置(レビュー分析#1, #4)
