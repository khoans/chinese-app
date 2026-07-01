# App học tiếng Trung (HSK) — Hướng dẫn sử dụng

App học tiếng Trung chạy **ngay trên máy bạn**, không cần cài đặt, không cần internet
(trừ phần tập viết nét chữ). Toàn bộ nội dung (từ vựng, câu, hội thoại) nằm trong các **file
bảng tính CSV** — bạn tự sửa bằng **Excel** rồi chạy **một cú nhấp chuột** là xong. **Không cần
biết lập trình.**

> Tài liệu này dành cho **người dùng và người biên soạn nội dung**. Nếu bạn là lập trình viên
> (hoặc AI trợ lý), xem thêm [`CLAUDE.md`](CLAUDE.md) để hiểu kiến trúc kỹ thuật.

---

## Phần 1 — Mở app để học (đơn giản nhất)

1. Mở thư mục dự án.
2. **Nhấp đúp (double-click) vào file `index.html`.**
3. App mở ra trong trình duyệt. Xong! Không cần internet.

> 💡 Nên mở bằng **Google Chrome** để dùng được đầy đủ (đặc biệt phần **Luyện nói** cần micro).
> Nếu máy mở bằng trình duyệt khác: chuột phải `index.html` → **Open with** → chọn **Chrome**.

**Các nhóm trong app** (thanh trên cùng, vuốt/nhấn mũi tên ‹ › để xem hết):

| Nhóm | Làm gì |
|------|--------|
| **Học** | Thẻ ghi nhớ (chạm thẻ để lật xem nghĩa) |
| **Luyện tập** | Học từ / Dịch câu có chấm điểm, lưu tiến độ, thống kê; kèm Cài đặt |
| **Tập viết** | Viết chữ Hán theo đúng thứ tự nét |
| **Trò chơi & Kiểm tra** | Trắc nghiệm, ghép cặp, gõ pinyin, luyện nghe, luyện nói |
| **Hội thoại** | Nghe & đọc các đoạn hội thoại |

> 📌 Tiến độ ở tab **Luyện tập** được lưu **trong máy** (trong trình duyệt bạn đang dùng). Đổi máy
> hoặc đổi trình duyệt thì tiến độ không đi theo. Có thể xóa tiến độ ở **Luyện tập → Thống kê**.

---

## Phần 2 — Sửa / thêm nội dung (dành cho người biên soạn)

Toàn bộ nội dung nằm trong thư mục **`data/csv/`**, chia theo cấp (HSK1, HSK2, …). Mỗi cấp có
tối đa 3 file:

| File | Chứa gì | Bắt buộc? |
|------|---------|:---------:|
| `words.csv` | **Từ vựng** (chữ Hán, pinyin, nghĩa, ví dụ, chủ đề) | ✅ |
| `conversations.csv` | **Hội thoại** (từng câu thoại A/B) | Không |
| `sentences.csv` | **Câu mẫu** cho chế độ *Dịch câu* | Không |

### Bước 1 — Mở file CSV bằng Excel
- Chuột phải file (vd `data/csv/HSK1/words.csv`) → **Open with** → **Excel**.
- (Hoặc mở Excel trước, rồi **File → Open** và chọn file.)

### Bước 2 — Sửa nội dung
- **Mỗi dòng = một từ (hoặc một câu).** Thêm từ mới = thêm một dòng mới.
- **KHÔNG xóa dòng tiêu đề** (dòng đầu tiên ghi tên cột).
- Điền theo đúng cột (xem bảng cột ở **Phần 4**).

### Bước 3 — Lưu file ĐÚNG ĐỊNH DẠNG (quan trọng!)
- Bấm **File → Save** (Ctrl+S).
- Nếu Excel hỏi định dạng, **giữ nguyên `CSV UTF-8 (Comma delimited)`** rồi bấm **Save** / **Yes**.
- ⚠️ **ĐỪNG** dùng “Save As” đổi sang `.xlsx`. Phải giữ đuôi **`.csv`**, kiểu **CSV UTF-8**
  (nếu không, chữ Hán sẽ bị lỗi thành dấu hỏi ���).

### Bước 4 — Chạy “build” để app cập nhật
Cách dễ nhất:
- Chuột phải file **`tools/build.ps1`** → **“Run with PowerShell”**.
- Một cửa sổ xanh/đen hiện ra, in vài dòng tóm tắt (vd `HSK1  149 từ, 5 hội thoại, 2 câu`) → xong,
  đóng lại.

<details>
<summary><b>Nếu “Run with PowerShell” không hiện, cửa sổ nháy rồi tắt, hoặc báo lỗi “execution policy”</b></summary>

Windows đôi khi chặn chạy script. Làm cách này thay thế:

1. Bấm nút **Start**, gõ `powershell`, mở **Windows PowerShell**.
2. Dán nguyên dòng dưới đây (đổi đường dẫn cho đúng chỗ bạn để dự án) rồi **Enter**:

   ```powershell
   powershell -ExecutionPolicy Bypass -File "C:\Users\khoan\Desktop\chinese-app\tools\build.ps1"
   ```

   *(Mẹo lấy đường dẫn: chuột phải `build.ps1` → “Copy as path”, rồi dán vào giữa hai dấu ngoặc kép.)*

3. Nếu vẫn không chạy, có thể máy chưa có PowerShell mới — cài **PowerShell 7** miễn phí của Microsoft
   rồi thử lại (mở bằng `pwsh` thay cho `powershell`).
</details>

### Bước 5 — Xem kết quả
- Nếu app đang mở, bấm **F5** (tải lại). Nếu chưa, **nhấp đúp `index.html`**.
- Nội dung mới đã xuất hiện. 🎉

> **Tóm tắt vòng lặp:** Sửa CSV trong Excel → Lưu (CSV UTF-8) → chạy `tools/build.ps1` → mở lại app.

---

## Phần 3 — Thêm một CẤP MỚI (ví dụ HSK3)

1. Vào `data/csv/`. **Chép** cả thư mục **`_TEMPLATE`** (Ctrl+C, Ctrl+V).
2. **Đổi tên** bản chép thành tên cấp mới, ví dụ **`HSK3`**.
3. Mở `data/csv/HSK3/words.csv` bằng Excel, điền từ vựng (và `sentences.csv` / `conversations.csv`
   nếu muốn).
4. Chạy `tools/build.ps1` (Phần 2, Bước 4).
5. Mở lại app — **nút “HSK 3” tự xuất hiện** trong bộ lọc cấp. **Không phải sửa gì trong app.**

> Thứ tự cấp dựa trên **số** trong tên (HSK1 → HSK2 → HSK3…). Xóa một cấp = xóa thư mục CSV của
> nó rồi chạy build lại; app tự bỏ cấp đó.

**Tên cấp hiển thị ra sao:**
- Thư mục bắt đầu bằng `HSK` + số → hiện **“HSK 1”, “HSK 2”…** (và luôn xếp **trước**).
- Thư mục bắt đầu bằng `BT` + số → hiện **“Bộ thủ 1”, “Bộ thủ 2”…** (xếp **sau** các cấp HSK).
- Tên khác → hiện đúng như tên thư mục.

---

## Phần 3b — Bộ thủ (chia theo chủ đề để dễ học)

Có sẵn **10 cấp Bộ thủ** (~100 bộ thủ Hán tự thông dụng), chia theo nhóm nghĩa cho dễ nhớ:

| Cấp | Nhóm | Ví dụ |
|-----|------|-------|
| **Bộ thủ 1** | Người & cơ thể | 人 口 女 心 手 目 … |
| **Bộ thủ 2** | Thiên nhiên | 日 月 水 火 山 雨 … |
| **Bộ thủ 3** | Động thực vật | 马 鱼 鸟 牛 竹 米 … |
| **Bộ thủ 4** | Đồ vật & tính chất | 门 车 衣 食 金 大 小 … |
| **Bộ thủ 5** | Cơ thể & sức khỏe | 骨 血 牙 齿 皮 身 肉 … |
| **Bộ thủ 6** | Con người & hành động | 父 士 老 走 飞 行 … |
| **Bộ thủ 7** | Động vật (mở rộng) | 犬 虎 龙 龟 鹿 角 贝 … |
| **Bộ thủ 8** | Cây cỏ & khoáng vật | 麦 麻 瓜 谷 玉 王 … |
| **Bộ thủ 9** | Đồ vật & công cụ (mở rộng) | 戈 斤 矛 舟 页 音 瓦 … |
| **Bộ thủ 10** | Màu sắc & trừu tượng | 白 黑 青 赤 黄 色 文 高 … |

- **Học bộ thủ:** trên app chọn nút cấp **“Bộ thủ 1…10”**, hoặc vào **Luyện tập → Học từ** rồi tick
  các cấp Bộ thủ ở màn chọn nguồn.
- **Thêm bộ thủ:** mở `data/csv/BT1/words.csv` (…BT2 … BT10) bằng Excel, thêm dòng, lưu, chạy build.
- **Thêm một nhóm bộ thủ mới:** chép một thư mục `data/csv/BT10/` → `data/csv/BT11/`, sửa nội dung,
  build → nút “Bộ thủ 11” tự xuất hiện.

### Bộ đầy đủ 214 bộ Khang Hy (theo số nét) — độc lập

Ngoài 10 cấp “Bộ thủ” theo nghĩa ở trên, còn có bộ **đầy đủ 214 bộ thủ Khang Hy** xếp **theo số
nét**, để tra cứu/học có hệ thống. **Hai phần độc lập** — bạn chọn học phần nào cũng được:

| Cấp (trên app) | Gồm |
|-----|-----|
| **214 bộ · 1–2 nét** | 一 丨 丶 乙 二 人 儿 八 刀 力 十 又 … |
| **214 bộ · 3 nét** | 口 土 大 女 子 山 巾 弓 … |
| **214 bộ · 4 nét** | 心 手 日 月 木 水 火 牛 犬 … |
| **214 bộ · 5–6 nét** | 玉 田 目 石 竹 米 耳 舟 虫 … |
| **214 bộ · 7–9 nét** | 見 言 走 足 車 金 門 雨 頁 風 食 … |
| **214 bộ · 10+ nét** | 馬 骨 高 魚 鳥 鹿 黑 鼻 齒 龍 龜 龠 |

- Dùng **dạng chữ Khang Hy chuẩn** (một số bộ ở dạng phồn thể như 見 車 馬 龍) và **không kèm câu
  ví dụ** (đây là bảng tra bộ thủ). Cột `chuDe` là **số nét** (vd “5 nét”) để lọc.
- Sửa/thêm: `data/csv/KX1/words.csv` … `KX6/words.csv`.

---

## Phần 4 — Ý nghĩa các cột trong CSV

**`words.csv`** — từ vựng:

| Cột | Ý nghĩa | Ví dụ |
|-----|---------|-------|
| `chuHan` | chữ Hán (bắt buộc) | 爱 |
| `pinyin` | phiên âm (nên có dấu thanh) | ài |
| `nghia` | nghĩa tiếng Việt | yêu |
| `viDu` | câu ví dụ (chữ Hán) | 我爱你。 |
| `viDuPinyin` | pinyin câu ví dụ | wǒ ài nǐ 。 |
| `viDuNghia` | nghĩa câu ví dụ | Anh yêu em. |
| `chuDe` | chủ đề (gõ tự do; cùng tên = cùng nhóm) | Động từ thường dùng |

**`sentences.csv`** — câu mẫu cho *Dịch câu* (muốn thêm bao nhiêu câu tùy ý cho một chủ đề):

| Cột | Ý nghĩa |
|-----|---------|
| `cau` | câu tiếng Trung (bắt buộc) |
| `pinyin` | pinyin của câu |
| `nghia` | nghĩa tiếng Việt |
| `chuDe` | chủ đề |

**`conversations.csv`** — hội thoại (mỗi dòng là một câu thoại; các dòng cùng `hoiThoai` gộp thành
một đoạn theo thứ tự):

| Cột | Ý nghĩa |
|-----|---------|
| `hoiThoai` | tên đoạn hội thoại (khoá gộp nhóm) |
| `icon` | 1 chữ Hán làm biểu tượng (chỉ cần điền ở dòng đầu mỗi đoạn) |
| `nguoi` | người nói: `A` hoặc `B` |
| `cau` | câu (chữ Hán) |
| `pinyin` | pinyin |
| `nghia` | nghĩa tiếng Việt |

> **Chủ đề tự động:** chỉ cần gõ tên chủ đề vào cột `chuDe`. App tự gom danh sách chủ đề — không
> phải khai báo ở đâu khác.

---

## Phần 5 — Lỗi thường gặp & cách xử lý

| Hiện tượng | Nguyên nhân & cách sửa |
|-----------|------------------------|
| Chữ Hán biến thành `���` hoặc dấu hỏi | File lưu sai kiểu. Mở lại bằng Excel → **File → Save As** → chọn **CSV UTF-8** → lưu đè. |
| Chạy build xong app không đổi | Chưa **tải lại** app. Bấm **F5**, hoặc đóng rồi mở lại `index.html`. |
| “Run with PowerShell” báo lỗi / nháy rồi tắt | Xem hộp mở rộng ở **Phần 2, Bước 4** (dùng lệnh `-ExecutionPolicy Bypass`). |
| Nút cấp mới không xuất hiện | Chưa chạy build sau khi thêm thư mục, hoặc thư mục thiếu `words.csv`. |
| Phần **Luyện nói** không nghe được micro | Cần mở bằng **Chrome** và cho phép micro; cần có mạng. |
| Sửa nhầm, muốn quay lại | Các file trong `data/<CẤP>/*.js` và `data/manifest.js` là **tự sinh** — cứ chạy build lại, chúng được tạo lại từ CSV. |

> ❗ **ĐỪNG sửa tay** các file trong `data/<CẤP>/` (vd `data/HSK1/hsk1.js`) hay `data/manifest.js`
> — mỗi lần build chúng bị ghi đè. Chỉ sửa **file CSV trong `data/csv/`**.

---

## Cây thư mục (tham khảo)

```
index.html                      # App — nhấp đúp để mở
data/
  csv/                          # ⇦ NƠI BẠN SỬA NỘI DUNG
    HSK1/  words.csv  conversations.csv  sentences.csv
    HSK2/  words.csv  conversations.csv  sentences.csv
    BT1/ … BT10/                # 10 cấp "Bộ thủ" theo nghĩa (100 bộ thông dụng)
    KX1/ … KX6/                 # 214 bộ Khang Hy theo số nét (độc lập)
    _TEMPLATE/                  # mẫu để chép khi thêm cấp mới
    README.md                   # bản hướng dẫn biên soạn ngắn gọn
  registry.js, manifest.js      # TỰ SINH — đừng sửa tay
  HSK1/hsk1.js, HSK2/hsk2.js    # TỰ SINH — đừng sửa tay
tools/
  build.ps1                     # ⇦ CHẠY FILE NÀY sau khi sửa CSV
CLAUDE.md                       # tài liệu kỹ thuật (cho lập trình viên)
```
