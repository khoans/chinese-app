# HANDOFF.md — Bàn giao đầy đủ cho phiên AI/lập trình viên mới

> Mục tiêu: đọc xong file này là **nắm trọn** app đang chạy thế nào, dữ liệu ở đâu, được phép
> đổi gì, và cách kiểm chứng **không cần trình duyệt**. Đọc kèm: [`CLAUDE.md`](CLAUDE.md) (kiến
> trúc gọn), [`README.md`](README.md) (hướng dẫn người biên soạn), [`data/csv/README.md`](data/csv/README.md).

---

## 0. TL;DR (30 giây)

- App học tiếng Trung HSK: **một file `index.html`** (~1700 dòng), **vanilla JS**, không framework,
  không backend, không bước build lúc chạy. **Chạy bằng cách double-click** (`file://`).
- Dữ liệu **KHÔNG nhúng trong HTML**. Nguồn gốc là **CSV** trong `data/csv/`; `tools/build.ps1`
  sinh ra các file `.js`; app nạp qua `data/registry.js` + `data/manifest.js` + `document.write`.
- Hiện có **4 cấp**: `HSK1`, `HSK2` (từ vựng), `BoThu` ("Bộ thủ thông dụng", 100 bộ), `KhangHy`
  ("Bộ thủ đầy đủ", 214 bộ Khang Hy). Tổng **690 từ**, 5 hội thoại, 2 câu mẫu, 29 chủ đề. Bên
  trong 2 cấp bộ thủ được chia nhỏ bằng **chủ đề** (`chuDe`).
- Ràng buộc TUYỆT ĐỐI: **không phá `file://`** (không `fetch`, không ES module để nạp dữ liệu).

---

## 1. App là gì & ràng buộc bất biến

- **Thuần client-side**, vanilla JS, mở bằng `file://` (double-click `index.html`). Có thể deploy
  tĩnh (GitHub Pages…) nhưng không bắt buộc.
- Cần internet **chỉ cho**: font Google, thư viện **`hanzi-writer`** (CDN, dùng ở "Tập viết") và
  Web Speech (TTS/mic). Mọi thứ khác chạy offline. `hanzi-writer` có đường lùi (fallback) sẵn —
  **đừng làm hỏng**.
- **Bất biến — ĐỪNG phá:**
  1. Giữ chạy `file://`: nạp dữ liệu **chỉ bằng `<script>` + `document.write` đồng bộ**, KHÔNG
     `fetch`/ES module/`async`/`defer`.
  2. Không đổi **tên trường dữ liệu**: từ `w/p/m/ex/exp/exm/lv/topic`; hội thoại
     `title/icon/lines/who/zh/py/vi`; câu `zh/py/vi/topic`.
  3. Không đổi **id DOM cũ** và **khoá localStorage** đã có (xem §7).
  4. **Không sửa tay** các file `.js` sinh ra (`data/**/<level>.js`, `data/manifest.js`) — build
     ghi đè. Chỉ sửa **CSV** trong `data/csv/`.
  5. Dữ liệu sau build phải **khớp 100%** với CSV nguồn (dữ liệu HSK gốc đã được xác minh khớp).

---

## 2. Trạng thái hiện tại (snapshot)

- File app: **`index.html`** (từng tên `hoc-tieng-trung-hsk1-2_1.html`, đã đổi).
- 4 cấp: `HSK1, HSK2, BoThu, KhangHy`. 690 từ / 5 hội thoại / 2 câu mẫu / 29 chủ đề.
- Git: repo cục bộ, nhánh `main`, **chưa có remote** (chưa push). Lịch sử commit gần nhất:
  ```
  cd76b3f Gom cấp bộ thủ vào thư mục nhóm (BoThu / KhangHy)
  5d4a624 Thêm đủ 214 bộ Khang Hy theo số nét (KX1–KX6)
  212bbe9 Mở rộng bộ thủ: thêm 6 cấp nghĩa (BT5–BT10)
  dbee9f1 Tách bộ thủ thành 4 cấp riêng (BT1–BT4)
  8121188 Hướng dẫn nontech + sửa build chạy trên Windows PowerShell 5.1
  90610a8 Đổi tên app thành index.html
  0f64da5 Tái cấu trúc dữ liệu CSV + bổ sung phần Luyện tập nâng cao
  ```
- Quy ước git của repo: commit message tiếng Việt; kết thúc bằng
  `Co-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>`. **Chỉ commit khi được
  yêu cầu.** Cảnh báo CRLF→LF khi add là **vô hại** (BOM của CSV vẫn giữ).

---

## 3. Cây thư mục (chú thích)

```
index.html                      # APP — toàn bộ UI + logic + CSS trong 1 file
HANDOFF.md  CLAUDE.md  README.md # tài liệu
data/
  registry.js                   # registerLevel() + HSKData (NẠP ĐẦU TIÊN). Viết tay, ổn định.
  manifest.js                   # TỰ SINH: var LEVELS + var LEVEL_SRC
  HSK1/hsk1.js  HSK2/hsk2.js     # TỰ SINH (cấp trực tiếp)
  BoThu/bothu.js                # TỰ SINH — cấp "Bộ thủ thông dụng" (100 bộ)
  KhangHy/khanghy.js            # TỰ SINH — cấp "Bộ thủ đầy đủ" (214 bộ Khang Hy)
  csv/                          # ⇦ NGUỒN DỮ LIỆU GỐC (chỉ sửa ở đây)
    HSK1/  words.csv  conversations.csv  sentences.csv
    HSK2/  words.csv  conversations.csv  sentences.csv
    BoThu/   words.csv          # cấp "Bộ thủ thông dụng" (chuDe = "Bộ thủ N · nhóm")
    KhangHy/ words.csv          # cấp "Bộ thủ đầy đủ" (chuDe = mốc số nét)
    _TEMPLATE/ words.csv conversations.csv sentences.csv   # mẫu; BỊ BỎ QUA khi build
    README.md
tools/
  build.ps1                     # CSV -> *.js + manifest.js  (UTF-8 CÓ BOM! xem §5)
```

> **CSV → JS:** cấp trực tiếp `data/csv/HSK1/` → `data/HSK1/hsk1.js`; cấp trong thư mục nhóm
> `data/csv/<Nhóm>/<CODE>/` → `data/<Nhóm>/<code>.js`. (Cơ chế gom-nhóm vẫn còn cho ai muốn dùng.)

---

## 4. Cơ chế nạp dữ liệu (QUAN TRỌNG — phải chạy `file://`)

Thứ tự nạp trong `index.html`, ngay trước phần JS chính:

```
data/registry.js  →  data/manifest.js  →  (document.write theo LEVEL_SRC)  →  JS chính của app
```

1. **`data/registry.js`** (viết tay): định nghĩa `registerLevel(level, {words, conversations,
   sentences})` gom vào đối tượng toàn cục **`HSKData`**:
   - `HSKData.words()` → mọi từ, đã **tự gắn `w.lv`** theo cấp.
   - `HSKData.conversations()` → hội thoại (đã gắn `lv`).
   - `HSKData.sentences()` → câu độc lập (đã gắn `lv`) cho chế độ Dịch câu.
   - `HSKData.levels()` → mảng mã cấp theo thứ tự đăng ký.
   - `HSKData.topics()` → **tự suy ra** danh sách chủ đề từ trường `topic` của từ vựng (giữ thứ
     tự xuất hiện lần đầu). Người biên soạn chỉ cần gõ `chuDe` vào CSV.
   - Ghi `registerLevel`/`HSKData` ra cả `self`/`window` để chạy được cả trong worker.
2. **`data/manifest.js`** (TỰ SINH): `var LEVELS = ["HSK1",...]` (mã cấp) và
   `var LEVEL_SRC = ["data/HSK1/hsk1.js","data/BoThu/bt1.js",...]` (đường dẫn .js). Ghi ra `window`+`self`.
3. **Bộ nạp inline** (trong HTML): duyệt `LEVEL_SRC`, `document.write("<script src=...>")` **đồng bộ,
   đúng thứ tự** khi trang đang parse. Có **fallback**: nếu thiếu `LEVEL_SRC` thì suy từ `LEVELS`
   theo kiểu cũ `data/<lv>/<lv lowercase>.js`.
4. **JS chính** đọc dữ liệu qua `const WORDS = HSKData.words()`, `CONVS = HSKData.conversations()`,
   `TOPICS = HSKData.topics()`. Nút chọn cấp và tiêu đề **sinh động** từ `LEVELS`.

> ⚠️ Vì sao `document.write` external script chạy được: trình duyệt thật **chặn parser** và chạy
> script tuần tự trước script inline kế tiếp — đúng trên `file://`. (jsdom nạp bất đồng bộ nên khi
> test bằng jsdom phải "bundle" nội tuyến — xem §8.)

---

## 5. Build (`tools/build.ps1`)

Chạy: chuột phải → **Run with PowerShell**, hoặc `pwsh ./tools/build.ps1`, hoặc (nếu bị chặn)
`powershell -ExecutionPolicy Bypass -File .\tools\build.ps1`. **Chạy được trên cả Windows
PowerShell 5.1 lẫn PowerShell 7.**

Việc build làm:
1. **Quét đệ quy** `data/csv/` tìm mọi `words.csv` (bỏ mọi đường dẫn có segment bắt đầu `_`, vd
   `_TEMPLATE`). Mỗi thư mục chứa `words.csv` = một **cấp**; mã cấp = tên thư mục lá.
2. Đọc `words.csv` (+ `conversations.csv`, `sentences.csv` nếu có), ánh xạ cột (§6).
3. Sinh `.js` từng cấp, **gom theo nhóm** (thư mục cha trong csv → thư mục cùng tên trong data).
4. Sinh `data/manifest.js` (`LEVELS` + `LEVEL_SRC`).
5. **Dọn rác**: xoá `.js` sinh ra không còn nguồn CSV, rồi xoá thư mục rỗng (không đụng `data/csv`,
   `registry.js`, `manifest.js`).
6. Thứ tự cấp (`Get-LevelSortKey`): **HSK** (số 1..6) → **BT** (1000+n) → **KX** (2000+n) → cấp
   khác có số (3000+n) → không số (cuối).

> **BẪY 1 — BOM:** `build.ps1` phải lưu **UTF-8 CÓ BOM**. Nếu lưu không BOM, Windows PowerShell 5.1
> đọc sai tiếng Việt → lỗi cú pháp khi "Run with PowerShell". (Các tool Edit giữ BOM; nếu dùng
> Write toàn file thì phải thêm lại BOM.)
>
> **BẪY 2 — CSV:** file CSV lưu **UTF-8 CÓ BOM** (để Excel đọc chữ Hán). File `.js` sinh ra
> **KHÔNG BOM**. PowerShell 5.1 `ConvertTo-Json` escape chữ Hán thành `\uXXXX` (vô hại, vẫn đúng);
> PowerShell 7 giữ chữ Hán nguyên. Cả hai cho dữ liệu tương đương.
>
> **BẪY 3 — biến PowerShell không phân biệt hoa/thường**: đặt tên biến khác hẳn nhau.

---

## 6. Định dạng CSV & ánh xạ cột

**`words.csv`** (bắt buộc mỗi cấp): `chuHan, pinyin, nghia, viDu, viDuPinyin, viDuNghia, chuDe`
→ ánh xạ `w, p, m, ex, exp, exm, topic`.

**`conversations.csv`** (tuỳ chọn): `hoiThoai, icon, nguoi, cau, pinyin, nghia`. Mỗi dòng = 1 câu
thoại; gộp theo `hoiThoai` (icon lấy ở dòng đầu). → `title/icon` + `lines:[{who,zh,py,vi}]`.

**`sentences.csv`** (tuỳ chọn): `cau, pinyin, nghia, chuDe` → câu độc lập `{zh,py,vi,topic}` cho
chế độ Dịch câu.

- Dòng đầu = tiêu đề cột (KHÔNG xoá). Dòng trống (thiếu `chuHan`/`cau`/`hoiThoai`) bị bỏ qua.
- **Ngân hàng câu Dịch câu** = `sentences.csv` + câu ví dụ của từ (`viDu`) + các dòng hội thoại,
  **tự bỏ trùng theo chữ Hán** (xem `buildSentenceBank()`).

---

## 7. Cấp độ, nhãn, và bộ thủ

- **Mã cấp** = tên thư mục lá: `HSK1`, `HSK2`, `BoThu`, `KhangHy`. Trường `w.lv` dùng mã này.
- **Nhãn hiển thị** qua `levelLabel(lv)` + `LEVEL_LABELS` (trong `index.html`): `HSK1`→"HSK 1";
  `BoThu`→"Bộ thủ thông dụng"; `KhangHy`→"Bộ thủ đầy đủ". Thêm nhãn kiểu cấp mới = thêm 1 dòng.
- **Ô chọn chủ đề LỌC THEO CẤP** (`topicsForLevel`/`renderTopicOptions`): chọn cấp → dropdown chỉ
  hiện chủ đề của cấp đó, và `topic` reset về `ALL`. Nhờ vậy thanh cấp gọn (5 nút) mà vẫn chia nhỏ được.
- **Hai phần bộ thủ** (mỗi phần là MỘT cấp, MỘT `words.csv`; chia nhỏ bằng **chủ đề**):
  - `BoThu` (`data/csv/BoThu/words.csv`) — ~**100 bộ thông dụng**; `chuDe` = "Bộ thủ N · <nhóm>"
    (10 nhóm nghĩa: Người & cơ thể … Màu sắc & trừu tượng); **có** câu ví dụ.
  - `KhangHy` (`data/csv/KhangHy/words.csv`) — đủ **214 bộ Khang Hy**; `chuDe` = mốc số nét
    ("1–2 nét"…"10–17 nét"); dạng chữ Khang Hy chuẩn (một số phồn thể 見 車 馬 龍 齒…); **KHÔNG**
    câu ví dụ (`ex` rỗng → app tự ẩn khung).
  - Bộ thủ là **từ vựng bình thường** (có `lv`) → mọi chế độ dùng ngay.
- Tiêu đề header (`#lvRange`) hiện "HSK 1–2 · Bộ thủ". Thanh chọn cấp (`.seg`) gọn: **5 nút**
  (Tất cả · HSK 1 · HSK 2 · Bộ thủ thông dụng · Bộ thủ đầy đủ), có `flex-wrap` phòng khi thêm cấp.

---

## 8. Phần "Luyện tập" — nền học chung (nằm trong JS chính của `index.html`)

Đây là phần logic lớn nhất & phức tạp nhất. 4 tab con của nhóm **练 Luyện tập**: **Học từ**
(`trainWord`), **Dịch câu** (`trainSentence`), **Thống kê** (`stats`), **Cài đặt** (`settings`).

### Các module (đều là `const` trong phạm vi `<script>` chính)

- **`Store`** — bọc `localStorage`, khoá = tiền tố `zh_` + tên + hậu tố `_v1`. Đổi shape dữ liệu
  thì **tăng hậu tố**, đừng sửa ngầm.
- **`Progress`** — "bộ nhớ học" **lâu dài** dùng cho thuật toán chọn mục (KHÔNG phải số liệu người
  dùng xem). Lưu theo **"khóa cấu hình học"**:
  `configKey = kind + "::" + direction + "::" + sortedLevels + "::" + sortedTopics`.
  - `itemStat`: mỗi mục `{correct, wrong, timeout, totalTimeMs, timedCount}`.
  - `itemId`: từ = `"W|"+lv+"|"+w`; câu = `"S|"+zh`.
  - `record(cfg,id,outcome,ms)`, `adjust(cfg,id,old,new)` (dời 1 lượt khi chấm lại),
    `setStreakCurrent`, `streakOf`, `statsForConfig`, `setNote/noteOf`, `resetAll/clearConfig`.
- **`Mastered`** (`zh_mastered_v1`) — tập mục "đã thuộc" theo `itemId` **toàn cục**. `buildPool`
  loại các mục đã thuộc → không xuất hiện khi luyện. Quản lý được ở danh sách đã/chưa thuộc.
- **`Sessions`** (`zh_sessions_v1`, tối đa 60) — **mỗi lần luyện = 1 phiên**; đây là **số liệu
  người dùng xem**. Mỗi phiên: `{id, time, endTime, kind, direction, levels, topics, correct,
  wrong, timeout, accuracy, avgTimeMs, bestStreak, items:{itemId:{...}}, sequence:[...]}`.
  Trang **Thống kê** hiển thị theo phiên (chọn phiên → bảng theo mục + biểu đồ).
- **`Settings`** (`zh_settings_v1`) — `{typingOn, timerOn, timerSec, algorithm, keys:{...}}`.
- **`Trainer`** — máy luyện cho cả `word` và `sentence`. Trạng thái phiên trong `active`. Luồng:
  - **Màn chọn nguồn** (`renderSetup`): chọn nhiều cấp + nhiều chủ đề + lọc + xem trước + đổi chiều
    + thuật toán + "chỉ ôn lỗi sai" + công tắc gõ + đồng hồ + **danh sách đã/chưa thuộc**.
  - **Màn luyện** (`renderPracticeShell`): prompt → (gõ đáp án hoặc "Hiện đáp án") → **3 nút tự
    chấm** ✗ Chấm sai / ✓ Chấm đúng / ★ Đã thuộc → `gradeAndAdvance()` ghi thống kê + **tự qua thẻ
    mới**. **"Thẻ trước"** (`renderPrevious`/`reGrade`) cho xem lại & **chấm lại** (sửa đúng cả
    `Progress`, streak, thống kê phiên). **Tạm dừng** (`togglePause`, không tính thời gian dừng) +
    **Kết thúc** (nút có màu). Ghi chú từng mục. Đồng hồ đếm ngược tuỳ chọn.
  - **Tổng kết** (`endSession`): lưu phiên vào `Sessions`, hiện summary + biểu đồ.
- **`StatsPage`** — trang Thống kê theo **phiên** (dropdown phiên, bảng theo mục sắp xếp được,
  biểu đồ, nút xoá tất cả).
- **`SettingsPage`** — công tắc gõ/đồng hồ, thuật toán mặc định, **gán lại phím tắt**;
  `installGlobalKeys()` gắn 1 handler `keydown` toàn cục (chỉ tác dụng khi đang ở tab Luyện tập;
  trong ô nhập chỉ `Enter`/`Esc`).

### Thuật toán & chuẩn hoá

- **`selectNextItem(items, configKey, algorithm, lastId)`** — 4 thuật toán: `uniform` (đều),
  `unseen` (ưu tiên chưa gặp), `least` (gặp ít nhất), `weak` (ưu tiên mục yếu: trọng số theo tỉ lệ
  sai + thời gian trả lời TB; mục chưa có dữ liệu = trọng số vừa phải). **Luôn tránh lặp lại ngay**
  mục vừa hiện.
- **`normalizePinyin`** — chấp nhận có/không dấu thanh, **số thanh điệu** (`hao3`), khoảng trắng
  tuỳ ý, `v`↔`ü`. **`meaningMatches`** — nghĩa Việt bỏ dấu + so khớp theo phân đoạn (`,` `;` `/`).

### Chiều học (`direction`)

- Từ: `vi2zh` (nghĩa→chữ/pinyin), `zh2vi` (chữ→nghĩa+pinyin), `audio2zh` (nghe TTS→chữ/nghĩa).
- Câu: `zh2vi` (câu Trung→nghĩa Việt), `vi2zh` (nghĩa→câu Trung), `audio2zh` (nghe câu).

### Phím tắt (bind được, hiện NGAY TRÊN nút)

Hành động & phím mặc định: `reveal`=Space, `correct`=1, `wrong`=2, `mastered`=3, `speak`=P,
`pause`=H, `end`=Esc. Đổi trong **Cài đặt**; lưu theo `event.code`.

---

## 9. Các khoá localStorage (tiền tố `zh_`, hậu tố `_v1`)

| Khoá | Nội dung |
|------|----------|
| `zh_progress_v1`   | bộ nhớ học theo configKey (cho thuật toán) |
| `zh_streak_v1`     | streak theo configKey |
| `zh_sessions_v1`   | **các phiên luyện** (số liệu người dùng xem) |
| `zh_mastered_v1`   | tập "đã thuộc" theo itemId |
| `zh_notes_v1`      | ghi chú theo itemId |
| `zh_settings_v1`   | gõ/đồng hồ/thuật toán/phím tắt |
| `zh_trainConfig_v1`| nguồn học đã chọn lần trước (word/sentence) |
| `zh_autoAudio_v1`  | công tắc tự đọc phát âm ("1"/"0") |
| `zh_appWidth_v1`   | độ rộng giao diện (thanh kéo) |
| `zh_history_v1`    | (LEGACY) lịch sử phiên kiểu cũ — nay dùng `zh_sessions_v1`; `Progress` còn API nhưng `endSession` không ghi nữa |

> Đổi **shape** của bất kỳ khoá nào → **tăng `_v1`→`_v2`** (Store), đừng sửa ngầm.

---

## 10. Các tính năng khác & quy ước UI

- **Nhóm điều hướng** (thứ tự): Học → Luyện tập → Tập viết → Trò chơi & Kiểm tra → Hội thoại.
  Các chế độ cổ điển (thẻ ghi nhớ, tập viết `hanzi-writer`, trắc nghiệm, ghép cặp, gõ pinyin,
  luyện nghe, luyện nói, hội thoại) **giữ nguyên như bản gốc**.
- **Công tắc tự đọc phát âm** (nút 🔊/🔇 ở header): gate các lần **tự phát** (khi hiện câu/mục mới,
  và khi reveal trong Luyện tập). Nút 🔊 thủ công + phím tắt đọc **luôn** phát. Dùng
  `autoSpeak()` (đã gate) vs `speak()` (thủ công).
- **Thanh kéo kích thước** (dưới header): đặt `--app-width` (320–1000px), lưu localStorage.
- **Thanh nhóm & thanh chế độ con**: cuộn ngang được + **nút mũi tên ‹ ›** (tự hiện/ẩn theo tràn).
  Xem `setupNavArrows`/`updateAllNavArrows`.
- **Responsive**: bố cục co giãn tới ~360px; nhiều dải cuộn ngang; `.seg` tự xuống dòng.
- Đọc phát âm: Web Speech API giọng `zh-CN`. Luyện nói: `SpeechRecognition` (cần Chrome + mic).

---

## 11. Kiểm chứng KHÔNG cần trình duyệt (rất quan trọng)

Không có trình duyệt trong môi trường CI/agent. Cách đã dùng trong dự án:

**(a) Mô phỏng nạp bằng Node** (nhanh, không cần cài gì) — kiểm dữ liệu & `HSKData`:
```bash
node -e "global.window=global;global.self=global;const fs=require('fs'),vm=require('vm');
vm.runInThisContext(fs.readFileSync('data/registry.js','utf8'));
vm.runInThisContext(fs.readFileSync('data/manifest.js','utf8'));
LEVEL_SRC.forEach(s=>vm.runInThisContext(fs.readFileSync(s,'utf8')));
console.log('levels',LEVELS.length,'words',HSKData.words().length,
            'sentences',HSKData.sentences().length,'topics',HSKData.topics().length);"
```
Và `node --check` mọi `.js` sinh ra.

**(b) Kiểm UI + logic bằng jsdom** (cần `npm i jsdom` ở thư mục tạm — KHÔNG cài vào repo). Vì jsdom
nạp `document.write`-script **bất đồng bộ**, phải **"bundle"**: đọc `index.html`, thay 2 thẻ
`<script src="data/registry.js">`, `manifest.js` bằng nội dung nội tuyến, thay **bộ nạp
`document.write`** bằng nội tuyến các file trong `LEVEL_SRC`, bỏ `<script src="https…">` + `<link>`,
rồi `new JSDOM(html, {runScripts:'dangerously', pretendToBeVisual:true, beforeParse(w){…})` với stub
`w.speechSynthesis`, `w.SpeechSynthesisUtterance`, `w.HanziWriter`. Sau đó **dispatch click/keydown**
để lái UI và kiểm `document`. (Trong phiên trước, các harness kiểu này sống ở thư mục scratchpad tạm
— **không nằm trong repo**; hãy tự tạo lại theo mô tả này khi cần.)

**(c) Loader thật trên `file://`**: `new JSDOM(html,{resources:'usable', url:'file:///…/index.html'})`
— nạp đúng file theo `LEVEL_SRC` (lưu ý jsdom bất đồng bộ nên `totalN` có thể = 0 lúc đo sớm, nhưng
`HSKData` cuối cùng đúng).

**(d) Round-trip thêm/xoá cấp**: tạo `data/csv/<nhóm>/<CODE>/words.csv` vài dòng → build → kiểm
`manifest.js` có cấp + file `.js` xuất hiện → xoá → build lại → biến mất (dọn rác đúng).

Luôn kiểm **trung thực dữ liệu HSK**: so `HSKData.words()` (lọc `/^HSK/`) với bản gốc phải khớp 100%.

---

## 12. Công thức cho các việc thường gặp

- **Thêm/sửa từ:** sửa `data/csv/<cấp>/words.csv` (Excel, lưu CSV UTF-8) → `pwsh ./tools/build.ps1`.
- **Thêm câu Dịch câu:** thêm dòng vào `data/csv/<cấp>/sentences.csv`.
- **Thêm cấp HSK mới:** chép `data/csv/_TEMPLATE/` → `data/csv/HSK3/`, điền, build → nút tự hiện.
- **Thêm/sửa bộ thủ thông dụng:** `data/csv/BoThu/words.csv` (cột `chuDe` = "Bộ thủ N · <nhóm>"
  để tạo/đặt chủ đề mới). **Sửa 214 bộ:** `data/csv/KhangHy/words.csv` (cột `chuDe` = mốc số nét).
- Sau MỌI thay đổi CSV: **chạy build**, rồi kiểm §11.

---

## 13. Việc còn có thể làm (gợi ý, chưa làm)

- **214 bộ hiện soạn một lượt** — nên rà lại tên Hán-Việt/pinyin các bộ hiếm (龠 鬯 黹 黽…).
- Thanh cấp đã gọn (5 nút) sau khi gộp BoThu/KhangHy; chủ đề lọc theo cấp.
- Chưa có remote git / chưa deploy. Chưa có service worker (build có sẵn nhánh tăng cache nếu thêm `sw.js`).
- `zh_history_v1` là legacy — có thể dọn khi tiện.

---

## 14. Nhớ nhất (checklist trước khi sửa)

1. Sửa **CSV**, KHÔNG sửa `.js` sinh ra. Chạy `build.ps1` sau đó.
2. Giữ `file://` — không `fetch`/ES module/`async`/`defer` cho nạp dữ liệu.
3. Không đổi tên trường dữ liệu, id DOM, khoá localStorage.
4. `build.ps1` giữ **UTF-8 CÓ BOM**; `.js` sinh ra **không BOM**; CSV **có BOM**.
5. Kiểm chứng bằng Node/jsdom (§11); đối chiếu dữ liệu HSK khớp 100%.
6. Chỉ commit khi được yêu cầu; message tiếng Việt + dòng Co-Authored-By.
