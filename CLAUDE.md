# CLAUDE.md — Kiến trúc & quy ước dự án

App học tiếng Trung HSK: **một file HTML** (`index.html`), vanilla JS,
**không framework / không backend / không bước build lúc chạy**. Ràng buộc BẮT BUỘC: **chạy được
trên `file://`** (double-click). Vì vậy KHÔNG dùng `fetch`/ES module để nạp dữ liệu.

> 👤 **Người biên soạn nội dung (không cần lập trình): đừng đọc file này** — hãy dùng
> [`README.md`](README.md), có hướng dẫn từng bước bằng Excel + ảnh mô tả. File `CLAUDE.md` là tài
> liệu kỹ thuật cho lập trình viên / AI trợ lý.

## 0. Chạy & kiểm nhanh (lệnh cụ thể)

```bash
# Mở app: nhấp đúp index.html (không cần server). Hoặc phục vụ tĩnh:
#   npx serve .        (rồi mở http://localhost:3000)

# Build lại dữ liệu sau khi sửa CSV (PowerShell 7 ưu tiên; Windows PowerShell 5.1 cũng chạy được):
pwsh ./tools/build.ps1
#   Windows, nếu bị chặn chính sách chạy script:
#   powershell -ExecutionPolicy Bypass -File .\tools\build.ps1

# Kiểm cú pháp các file .js sinh ra:
node --check data/registry.js && node --check data/manifest.js
for f in data/HSK*/*.js; do node --check "$f"; done

# Mô phỏng nạp bằng Node + so khớp dữ liệu (không cần trình duyệt):
node -e "global.window=global;global.self=global;const fs=require('fs'),vm=require('vm');
['data/registry.js','data/manifest.js'].forEach(f=>vm.runInThisContext(fs.readFileSync(f,'utf8')));
LEVELS.forEach(l=>vm.runInThisContext(fs.readFileSync('data/'+l+'/'+l.toLowerCase()+'.js','utf8')));
console.log('words',HSKData.words().length,'sentences',HSKData.sentences().length,'topics',HSKData.topics().length);"
```

## 0b. Cấp độ & nhãn hiển thị

- Mỗi thư mục con trong `data/csv/` (trừ `_TEMPLATE`) là một **cấp**. Mã cấp = tên thư mục
  (vd `HSK1`, `BT1`, `KX1`). `build.ps1` sắp theo band: **HSK** (số 1..6) → **BT** (1000+n) →
  **KX** (2000+n) → khác (3000+n) → không số (cuối) — xem `Get-LevelSortKey`.
- App hiển thị nhãn thân thiện qua `levelLabel(lv)` + bảng `LEVEL_LABELS`:
  `HSK1→"HSK 1"`, `BT1→"Bộ thủ 1"`, `KX1→"214 bộ · 1–2 nét"`. Thêm cấp kiểu khác = thêm 1 dòng.
- **Bộ thủ có hai phần độc lập:**
  - `BT1..BT10` — ~100 bộ **thông dụng**, chia theo **nghĩa** (cột `chuDe` = tên nhóm), có ví dụ.
  - `KX1..KX6` — đủ **214 bộ Khang Hy**, chia theo **số nét** (cột `chuDe` = "N nét"), dạng chữ
    Khang Hy chuẩn (một số phồn thể), **không có ví dụ** (`ex` rỗng → app tự ẩn khung ví dụ).
  - Cả hai là từ vựng bình thường (có `lv`) nên mọi chế độ dùng được ngay.

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
2. Đọc `words.csv` (+ `conversations.csv`, `sentences.csv` nếu có), ánh xạ cột tiếng Việt → khoá nội bộ
   (`chuHan→w, pinyin→p, nghia→m, viDu→ex, viDuPinyin→exp, viDuNghia→exm, chuDe→topic`;
   hội thoại `cau→zh, pinyin→py, nghia→vi, nguoi→who`, gộp theo `hoiThoai`;
   câu độc lập `cau→zh, pinyin→py, nghia→vi, chuDe→topic`).
   `registerLevel` nhận thêm mảng `sentences`; `HSKData.sentences()` trả về (đã gắn `lv`).
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
  **lịch sử phiên**; **ghi chú** theo mục. Có `resetAll` / `clearConfig` / `clearHistory`;
  `adjust(cfg,id,old,new)` + `setStreakCurrent` để **chấm lại thẻ trước** (đồng bộ thống kê).
  - Khoá localStorage: `zh_progress_v1`, `zh_streak_v1`, `zh_notes_v1`, `zh_settings_v1`, `zh_trainConfig_v1`, `zh_mastered_v1`, `zh_sessions_v1`, `zh_autoAudio_v1`, `zh_appWidth_v1`.
  - `Progress` giờ là **“bộ nhớ học” lâu dài** dùng cho thuật toán chọn (weak/unseen/mistakes),
    không phải số liệu người dùng xem — số liệu người dùng xem nằm ở `Sessions` (theo phiên).
- **`Mastered`**: tập mục “đã thuộc” (`zh_mastered_v1`, theo `itemId` toàn cục). `buildPool` loại
  các mục đã thuộc nên chúng không xuất hiện khi luyện; quản lý được ở danh sách đã/chưa thuộc.
- **`Sessions`** (`zh_sessions_v1`, tối đa 60): mỗi lần luyện = 1 **phiên**; lưu tổng
  (đúng/sai/hết giờ, độ chính xác, TB thời gian, chuỗi tốt nhất), **thống kê theo từng mục**, và
  chuỗi kết quả (cho biểu đồ). Trang **Thống kê** hiển thị theo phiên (chọn phiên để xem chi tiết).
- **`Settings`**: công tắc **gõ đáp án** (bật/tắt), **đồng hồ đếm ngược**, thuật toán mặc định,
  và **phím tắt bind được** (lưu theo `event.code`).
- **`selectNextItem(items, configKey, algorithm, lastItemId)`**: 4 thuật toán chọn mục —
  `uniform` / `unseen` / `least` / `weak` (trọng số theo tỉ lệ sai + thời gian trả lời TB);
  luôn tránh lặp lại ngay mục vừa hiện.
- **`normalizePinyin` / `meaningMatches`**: tự chấm — pinyin chấp nhận có/không dấu thanh, số
  thanh điệu (`hao3`), khoảng trắng tuỳ ý, `v`↔`ü`; nghĩa Việt bỏ dấu + so khớp theo phân đoạn.
- **`Trainer`**: hai chế độ trên cùng nền — **Học từ** (`word`) và **Dịch câu** (`sentence`,
  ngân hàng câu `buildSentenceBank()` = câu độc lập `sentences.csv` + ví dụ của từ + các dòng
  hội thoại; tự bỏ trùng theo chữ Hán). Có màn **chọn nguồn** (nhiều cấp + nhiều
  chủ đề + lọc + xem trước), **đổi chiều học**, **chỉ ôn lỗi sai**, **gõ đáp án tự chấm**, **ghi
  chú**, **đồng hồ**, và **tổng kết + biểu đồ** cuối phiên. Khi hiện đáp án có 3 nút tự chấm
  **Chấm sai / Chấm đúng / Đã thuộc**; chấm xong **tự qua thẻ mới**. **Đã thuộc** ghi nhận 1 lượt
  đúng rồi ẩn mục khỏi phần luyện (`Mastered`). Có **“Thẻ trước”** để xem lại đáp án đã làm và
  **chấm lại** (sửa đúng cả `Progress`, streak, và thống kê phiên). Có **danh sách đã/chưa thuộc**
  để quản lý (tự cập nhật khi đánh dấu đã thuộc). Có **Tạm dừng** (không tính thời gian tạm dừng
  vào thời gian trả lời) và **Kết thúc** (nút có màu phân biệt). Mỗi nút có phím tắt hiện **ngay
  trên nút** (theo phím đang gán). Không còn nút “Bỏ qua”.
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
