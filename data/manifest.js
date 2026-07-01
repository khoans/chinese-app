/* TỰ ĐỘNG SINH — ĐỪNG SỬA TAY (chạy tools/build.ps1). Danh sách cấp cho app tự nạp. */
var LEVELS = ["HSK1", "HSK2", "BT1", "BT2", "BT3", "BT4"];
if (typeof window !== "undefined") window.LEVELS = LEVELS;
if (typeof self !== "undefined") self.LEVELS = LEVELS;
