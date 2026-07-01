/* TỰ ĐỘNG SINH — ĐỪNG SỬA TAY (chạy tools/build.ps1). LEVELS = mã cấp; LEVEL_SRC = file .js để nạp. */
var LEVELS = ["HSK1", "HSK2", "BT1", "BT2", "BT3", "BT4", "BT5", "BT6", "BT7", "BT8", "BT9", "BT10", "KX1", "KX2", "KX3", "KX4", "KX5", "KX6"];
var LEVEL_SRC = ["data/HSK1/hsk1.js", "data/HSK2/hsk2.js", "data/BoThu/bt1.js", "data/BoThu/bt2.js", "data/BoThu/bt3.js", "data/BoThu/bt4.js", "data/BoThu/bt5.js", "data/BoThu/bt6.js", "data/BoThu/bt7.js", "data/BoThu/bt8.js", "data/BoThu/bt9.js", "data/BoThu/bt10.js", "data/KhangHy/kx1.js", "data/KhangHy/kx2.js", "data/KhangHy/kx3.js", "data/KhangHy/kx4.js", "data/KhangHy/kx5.js", "data/KhangHy/kx6.js"];
if (typeof window !== "undefined") { window.LEVELS = LEVELS; window.LEVEL_SRC = LEVEL_SRC; }
if (typeof self !== "undefined") { self.LEVELS = LEVELS; self.LEVEL_SRC = LEVEL_SRC; }
