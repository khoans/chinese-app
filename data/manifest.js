/* TỰ ĐỘNG SINH — ĐỪNG SỬA TAY (chạy tools/build.ps1). LEVELS = mã cấp; LEVEL_SRC = file .js để nạp. */
var LEVELS = ["HSK1", "HSK2", "BoThu", "KhangHy"];
var LEVEL_SRC = ["data/HSK1/hsk1.js", "data/HSK2/hsk2.js", "data/BoThu/bothu.js", "data/KhangHy/khanghy.js"];
if (typeof window !== "undefined") { window.LEVELS = LEVELS; window.LEVEL_SRC = LEVEL_SRC; }
if (typeof self !== "undefined") { self.LEVELS = LEVELS; self.LEVEL_SRC = LEVEL_SRC; }
