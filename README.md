# App học tiếng Trung (HSK)

Một app học tiếng Trung **thuần client-side** (vanilla JS, không framework, không backend,
không bước build lúc chạy). Mở được bằng cách **double-click file HTML** (`file://`) — không cần
web server, không cần internet (trừ phần tập viết nét dùng thư viện `hanzi-writer` từ CDN).

File app: **`index.html`**

---

## Dành cho người biên soạn nội dung (KHÔNG cần biết lập trình)

Toàn bộ từ vựng & hội thoại nằm trong **file CSV** ở `data/csv/`. Bạn chỉ cần:

1. Mở CSV bằng **Excel / Google Sheets**, sửa, lưu (định dạng **CSV UTF-8**).
2. Chuột phải `tools/build.ps1` → **“Run with PowerShell”**.
3. Mở lại file HTML để xem kết quả.

Thêm cấp mới (vd HSK3)? Chép thư mục `data/csv/_TEMPLATE/` → `data/csv/HSK3/`, điền CSV, build —
**nút cấp mới tự xuất hiện**, không phải sửa HTML.

👉 Hướng dẫn chi tiết: [`data/csv/README.md`](data/csv/README.md)

---

## Kiến trúc (dành cho lập trình viên)

Xem [`CLAUDE.md`](CLAUDE.md) để hiểu cơ chế nạp dữ liệu chạy trên `file://`, quy trình build,
và cấu trúc các tính năng học ở tab **“Luyện tập”**.

### Cây thư mục
```
index.html   # app (1 file)
data/
  registry.js                   # registerLevel() + HSKData (NẠP ĐẦU TIÊN)
  manifest.js                   # TỰ SINH: var LEVELS = [...]
  <LEVEL>/<level>.js            # TỰ SINH từ CSV (vd data/HSK1/hsk1.js)
  csv/<LEVEL>/words.csv         # NGUỒN DỮ LIỆU GỐC (người biên soạn sửa)
  csv/<LEVEL>/conversations.csv # hội thoại (không bắt buộc)
  csv/<LEVEL>/sentences.csv     # câu mẫu cho chế độ "Dịch câu" (không bắt buộc)
  csv/_TEMPLATE/                # mẫu để chép khi thêm cấp
  csv/README.md                 # hướng dẫn biên soạn
tools/
  build.ps1                     # CSV -> <level>.js + manifest.js
```
