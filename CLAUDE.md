# CLAUDE.md — Kiến trúc & quy ước dự án

App học tiếng Trung HSK: **một file HTML** (`hoc-tieng-trung-hsk1-2_1.html`), vanilla JS,
**không framework / không backend / không bước build lúc chạy**. Ràng buộc BẮT BUỘC: **chạy được
trên `file://`** (double-click). Vì vậy KHÔNG dùng `fetch`/ES module để nạp dữ liệu.

## 1. Cơ chế nạp dữ liệu (chạy trên `file://`)

Thứ tự nạp (đặt trong HTML, ngay trước phần JS chính):

```
data/registry.js  →  data/manifest.js  →  (document.write các <level>.js)  →  JS chính
```

- **`data/registry.js`**: định nghĩa `registerLevel(level, {words, conversations})` và gom vào
  đối tượng toàn cục **`HSKData`** với `HSKData.words()`, `.conversations()`, `.levels()`, `.topics()`.
  - `words()` gắn `lv` cho từng từ; `topics()` **tự suy ra** danh sách chủ đề theo thứ tự xuất hiện.
- **`data/manifest.js`** (TỰ SINH): đặt `var LEVELS = ["HSK1","HSK2",...]` (ghi ra cả `window`+`self`).
- **Bộ nạp inline** (trong HTML): duyệt `LEVELS`, dùng `document.write` chèn `<script src="data/<LEVEL>/<level>.js">`
  **đồng bộ, đúng thứ tự** (KHÔNG `async`/`defer`).
- Mỗi **`data/<LEVEL>/<level>.js`** (TỰ SINH) chỉ gọi `registerLevel("HSKx", {...})`.

JS chính đọc dữ liệu qua `const WORDS = HSKData.words()`, `CONVS = HSKData.conversations()`,
`TOPICS = HSKData.topics()`. Nút chọn cấp và tiêu đề được **sinh động từ `HSKData.levels()`/`LEVELS`**.

## 2. Quy trình build (nguồn dữ liệu = CSV)

`tools/build.ps1` (PowerShell 7):
1. Quét `data/csv/` tìm thư mục cấp (bỏ `_TEMPLATE`), thứ tự theo số trong tên.
2. Đọc `words.csv` (+ `conversations.csv` nếu có), ánh xạ cột tiếng Việt → khoá nội bộ
   (`chuHan→w, pinyin→p, nghia→m, viDu→ex, viDuPinyin→exp, viDuNghia→exm, chuDe→topic`;
   hội thoại `cau→zh, pinyin→py, nghia→vi, nguoi→who`, gộp theo `hoiThoai`).
3. Sinh `data/<LEVEL>/<level>.js` + `data/manifest.js` (UTF-8 **không BOM**).
4. **Dọn rác** thư mục cấp không còn CSV. In tóm tắt.

> CSV lưu **UTF-8 có BOM** (để Excel đọc chữ Hán). File `.js` sinh ra **không BOM**. ĐỪNG sửa tay
> các file trong `data/<LEVEL>/` và `data/manifest.js` — build sẽ ghi đè.

## 3. Các tính năng (nhóm điều hướng)

- **Học** (thẻ ghi nhớ), **Tập viết** (hanzi-writer), **Trò chơi & Kiểm tra** (trắc nghiệm, ghép
  cặp, gõ pinyin, luyện nghe, luyện nói), **Hội thoại** — giữ nguyên như bản gốc.
- **Luyện tập** (mới): nền học chung có lưu tiến độ lâu dài. Xem mục 4.

## 4. Nền học chung ở tab “Luyện tập” (trong JS chính)

Các module (đều là `const` trong phạm vi `<script>` chính):

- **`Store`**: bọc `localStorage`, khoá có tiền tố `zh_` + hậu tố phiên bản `_v1`
  (đổi shape dữ liệu thì tăng hậu tố, đừng sửa ngầm).
- **`Progress`**: thống kê theo **“khóa cấu hình học”** (`configKey = kind::direction::levels::topics`):
  mỗi mục lưu `correct/wrong/timeout/totalTimeMs/timedCount`; **streak** hiện tại/tốt nhất;
  **lịch sử phiên**; **ghi chú** theo mục. Có `resetAll` / `clearConfig` / `clearHistory`.
  - Khoá localStorage: `zh_progress_v1`, `zh_streak_v1`, `zh_history_v1`, `zh_notes_v1`, `zh_settings_v1`, `zh_trainConfig_v1`.
- **`Settings`**: công tắc **gõ đáp án** (bật/tắt), **đồng hồ đếm ngược**, thuật toán mặc định,
  và **phím tắt bind được** (lưu theo `event.code`).
- **`selectNextItem(items, configKey, algorithm, lastItemId)`**: 4 thuật toán chọn mục —
  `uniform` / `unseen` / `least` / `weak` (trọng số theo tỉ lệ sai + thời gian trả lời TB);
  luôn tránh lặp lại ngay mục vừa hiện.
- **`normalizePinyin` / `meaningMatches`**: tự chấm — pinyin chấp nhận có/không dấu thanh, số
  thanh điệu (`hao3`), khoảng trắng tuỳ ý, `v`↔`ü`; nghĩa Việt bỏ dấu + so khớp theo phân đoạn.
- **`Trainer`**: hai chế độ trên cùng nền — **Học từ** (`word`) và **Dịch câu** (`sentence`,
  ngân hàng câu = ví dụ của từ + các dòng hội thoại). Có màn **chọn nguồn** (nhiều cấp + nhiều
  chủ đề + lọc + xem trước), **đổi chiều học**, **chỉ ôn lỗi sai**, **gõ đáp án tự chấm**, **ghi
  chú**, **đồng hồ**, và **tổng kết + biểu đồ** cuối phiên.
- **`StatsPage`**: bảng thống kê theo mục (sắp xếp được), streak, lịch sử phiên, nút xóa/đặt lại.
- **`SettingsPage`**: UI cho `Settings` + gán lại phím tắt; `installGlobalKeys()` gắn 1 handler
  `keydown` toàn cục (chỉ tác dụng khi đang ở tab Luyện tập; trong ô nhập chỉ `Enter`/`Esc`).

## 5. Bất biến — ĐỪNG phá

- Giữ chạy `file://`: không `fetch`/ES module cho việc nạp dữ liệu.
- Không đổi tên trường dữ liệu (`w/p/m/ex/exp/exm/lv/topic`, `title/icon/lines/who/zh/py/vi`),
  id DOM cũ, hay khoá localStorage đã có.
- Giữ đường lùi offline của `hanzi-writer`.
- Dữ liệu sau build phải **khớp 100%** với CSV nguồn.

## 6. Kiểm chứng nhanh (không cần trình duyệt)

- `node --check` các file `.js` sinh ra.
- Mô phỏng chuỗi nạp bằng Node (`global.window=global`, nạp registry→manifest→các cấp), so sánh
  `HSKData.*` với dữ liệu gốc.
- Thử vòng thêm/xoá cấp (`data/csv/HSK3/…` → build → kiểm `manifest.js` → xoá → build lại).
