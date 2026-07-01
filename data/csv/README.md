# Hướng dẫn biên soạn dữ liệu (dành cho người KHÔNG rành lập trình)

Toàn bộ từ vựng và hội thoại của app nằm trong các file **CSV** ở thư mục này.
Bạn chỉ cần **mở bằng Excel / Google Sheets, sửa, lưu**, rồi **chạy 1 script** — KHÔNG
phải đụng vào file HTML hay code.

---

## 1. Cây thư mục

```
data/csv/
  HSK1/
    words.csv            ← từ vựng cấp HSK1
    conversations.csv    ← hội thoại cấp HSK1 (không bắt buộc)
  HSK2/
    words.csv
    conversations.csv
  _TEMPLATE/             ← thư mục mẫu, CHÉP khi thêm cấp mới
    words.csv
    conversations.csv
```

> ⚠️ Khi lưu bằng Excel, chọn định dạng **CSV UTF-8 (Comma delimited)** để chữ Hán không bị lỗi.

---

## 2. Sửa / thêm TỪ VỰNG

Mở `data/csv/<CẤP>/words.csv`. Dòng đầu là **tiêu đề cột — KHÔNG được xoá**. Mỗi dòng là một từ:

| Cột          | Ý nghĩa                                             | Bắt buộc |
|--------------|-----------------------------------------------------|:--------:|
| `chuHan`     | chữ Hán hiển thị                                    | ✅ |
| `pinyin`     | phiên âm pinyin (nên có dấu thanh)                  |   |
| `nghia`      | nghĩa tiếng Việt                                    |   |
| `viDu`       | câu ví dụ (chữ Hán)                                 |   |
| `viDuPinyin` | pinyin của câu ví dụ                                |   |
| `viDuNghia`  | nghĩa câu ví dụ (tiếng Việt)                        |   |
| `chuDe`      | chủ đề (gõ tự do; các từ cùng tên chủ đề gộp 1 nhóm)|   |

**Chủ đề tự động**: chỉ cần gõ tên chủ đề vào cột `chuDe`. App tự gom danh sách chủ đề từ đây —
không phải khai báo ở đâu khác.

---

## 3. Sửa / thêm HỘI THOẠI

Mở `data/csv/<CẤP>/conversations.csv`. **Mỗi dòng là MỘT câu thoại**. Các dòng có cùng
`hoiThoai` sẽ gộp thành một hội thoại, theo đúng thứ tự dòng trong file.

| Cột        | Ý nghĩa                                           |
|------------|---------------------------------------------------|
| `hoiThoai` | tên hội thoại (khoá gộp nhóm)                      |
| `icon`     | 1 chữ Hán làm biểu tượng (chỉ cần điền ở dòng đầu) |
| `nguoi`    | người nói: `A` hoặc `B`                           |
| `cau`      | câu (chữ Hán)                                      |
| `pinyin`   | pinyin của câu                                    |
| `nghia`    | nghĩa tiếng Việt                                  |

---

## 4. Thêm một CẤP MỚI (ví dụ HSK3)

1. **Chép** thư mục `data/csv/_TEMPLATE/` và **đổi tên** thành `data/csv/HSK3/`.
2. Điền `words.csv` (và `conversations.csv` nếu muốn).
3. Chạy build (mục 5).
4. Nút **“HSK3”** sẽ **tự xuất hiện** trong app — bạn KHÔNG phải sửa HTML.

> Thứ tự cấp trong app dựa vào **số** trong tên (HSK1 → HSK2 → … → HSK6).

---

## 5. Chạy script để cập nhật app

Sau mỗi lần sửa CSV:

- **Cách dễ nhất**: chuột phải `tools/build.ps1` → **“Run with PowerShell”**.
- Hoặc trong terminal: `pwsh ./tools/build.ps1`

Script sẽ đọc CSV và sinh lại dữ liệu app (`data/<CẤP>/<cấp>.js` + `data/manifest.js`),
đồng thời **tự dọn** các cấp đã xoá. Cuối cùng nó in tóm tắt số từ / hội thoại mỗi cấp.

Xong! **Mở file HTML** (double-click) để xem kết quả — không cần internet, không cần web server.

---

## 6. Những điều nên tránh

- ❌ Đừng xoá dòng tiêu đề cột trong CSV.
- ❌ Đừng sửa tay các file trong `data/<CẤP>/*.js` hay `data/manifest.js` — chúng **tự sinh**,
  lần build sau sẽ ghi đè.
- ❌ Đừng lưu CSV ở định dạng khác ngoài **CSV UTF-8**.
