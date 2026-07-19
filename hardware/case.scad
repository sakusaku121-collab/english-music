// =============================================================
// left-hand-controller パラメトリック筐体 v0 (OpenSCAD)
//
// これはエルゴノミクス試作用の「たたき台」。
// 上部のパラメータを変えて印刷 → 握る → 調整、を繰り返す前提。
// 印刷時は $fn を上げる(プレビューは低くて可)。
// =============================================================

// ---- 全体 ----
$fn = 48;            // 曲面分割数(印刷時は 96 以上推奨)
wall = 2.4;          // 壁厚

// ---- ベース(手首を乗せる土台) ----
base_len   = 110;    // 前後長
base_width = 78;     // 左右幅
base_height = 14;    // 土台の厚み

// ---- グリップ(握り柱) ----
grip_angle  = 28;    // 前傾角度(度)。ここが握り心地の最重要パラメータ
grip_height = 78;    // 柱の高さ
grip_width  = 46;    // 柱の左右幅
grip_depth  = 58;    // 柱の前後厚
grip_offset_y = -8;  // ベース上での前後位置

// ---- 天面ボタンプレート ----
plate_tilt   = 32;   // 天面の傾き(度)。親指が自然に届く角度に合わせる
plate_width  = 52;
plate_length = 72;

// ---- スティック ----
stick_hole_d   = 30;  // スティック可動部の開口径
stick_mount_w  = 34;  // モジュール基板の取付間隔(実測して合わせる)

// ---- ボタン穴 ----
btn_hole = 6.2;       // タクトスイッチキャップ径+クリアランス
                      // Kailh choc なら 13.8x13.8 の角穴に変更する

// ---- 側面ボタン(G / Space / Ctrl) ----
side_btn_w = 12;
side_btn_h = 6;
side_btn_pitch = 16;

// =============================================================

// 天面のボタン配置(プレートローカル座標 [x, y])
// 実機写真を参考にした扇状配置。自分の親指の可動域に合わせて調整する
button_layout = [
    [-16,  26],  // 3
    [ -4,  30],  // 4
    [  8,  26],  // Tab
    [-20,  12],  // F
    [-22,  -2],  // Q
    [-18, -16],  // E
    [  2, -20],  // X
    [-12, -28],  // 1
    [  0, -32],  // 2
];
stick_pos = [4, 4];  // スティック中心(プレートローカル)

module rounded_slab(l, w, h, r) {
    hull()
        for (dx = [-1, 1], dy = [-1, 1])
            translate([dx * (l/2 - r), dy * (w/2 - r), 0])
                cylinder(h = h, r = r);
}

// 手首側の土台
module base() {
    rounded_slab(base_len, base_width, base_height, 18);
}

// 前傾した握り柱(下端と上端の断面を hull で繋ぐ)。
// 上端断面は plate_tilt で傾けてあり、hull の天面がそのままボタンプレートになる
module grip() {
    top_shift = grip_height * tan(grip_angle);
    hull() {
        translate([grip_offset_y, 0, base_height - 1])
            rounded_slab(grip_depth, grip_width, 2, 14);
        translate([grip_offset_y + top_shift, 0, base_height + grip_height])
            rotate([0, plate_tilt, 0])
                rounded_slab(grip_depth * 0.8, grip_width * 0.9, 2, 12);
    }
}

// 天面プレートの座標系へ移動(grip() の上端断面と同じ変換)
module on_plate() {
    top_shift = grip_height * tan(grip_angle);
    translate([grip_offset_y + top_shift, 0, base_height + grip_height])
        rotate([0, plate_tilt, 0])
            children();
}

// スティック開口+ボタン穴
module top_cutouts() {
    on_plate() {
        translate([stick_pos[0], stick_pos[1], -20])
            cylinder(h = 40, d = stick_hole_d);
        for (p = button_layout)
            translate([p[0], p[1], -20])
                cylinder(h = 40, d = btn_hole);
    }
}

// 側面ボタンの角穴(小指側の面)
module side_cutouts() {
    for (i = [0 : 2])
        translate([grip_offset_y + 10,
                   grip_width / 2 - wall - 2,
                   base_height + 24 + i * side_btn_pitch])
            cube([side_btn_w, wall + 6, side_btn_h]);
}

// ---- 本体 ----
// 現段階はソリッド(軽量化はスライサーのインフィル設定に任せる)。
// 基板・配線用の内部空間と底蓋は、グリップ形状確定後の v1 で設計する
difference() {
    union() {
        base();
        grip();
    }
    top_cutouts();
    side_cutouts();
}

// TODO(v1 以降):
// - 底蓋 + M3インサートボス
// - スティックモジュールの取付ボス(stick_mount_w で位置決め)
// - Kailh choc 用の角穴プレートへの差し替え
// - パネルマウントUSB-C口の開口(レビュー分析#9: 直付け面一コネクタは破損する)
//
// レビュー分析(docs/design-notes.md)からの形状要件:
// - グリップ太さを上下で変える: 親指側(側面ボタン付近)は細く、
//   薬指・小指側(下部)は太く → 握り込む力を減らして手首痛対策 (#5)
// - パームレスト部(base)を広めに取り、掌の小指側エッジに角を当てない (#6)
// - ボタンは親指可動域の実測範囲内のみに配置。届かない位置に置かない (#7)
// - ESC + 予備2ボタンの配置スペースを天面外周に確保 (#1, #4)
// - スティック開口部エッジは面取りし、モジュールはネジ止めで交換可能に (#10)
