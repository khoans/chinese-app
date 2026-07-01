<#
================================================================================
 tools/build.ps1  —  Sinh dữ liệu app tiếng Trung từ CSV
--------------------------------------------------------------------------------
 CÁCH DÙNG (người biên soạn):
   Chuột phải file này -> "Run with PowerShell"   (hoặc trong terminal: pwsh ./tools/build.ps1)

 SCRIPT LÀM GÌ:
   1. Quét ĐỆ QUY data/csv/ tìm mọi words.csv (bỏ _TEMPLATE). Cấp có thể nằm trong thư mục
      nhóm, vd data/csv/HSK1, data/csv/BoThu/BT1, data/csv/KhangHy/KX1.
   2. Đọc words.csv (+ conversations.csv, sentences.csv nếu có) của từng cấp.
   3. Sinh file .js cho từng cấp, GOM theo nhóm (vd data/BoThu/bt1.js). ĐỪNG sửa các file này bằng tay.
   4. Sinh data/manifest.js đặt LEVELS (mã cấp) + LEVEL_SRC (đường dẫn .js để app nạp).
   5. Dọn rác: xoá .js sinh ra không còn nguồn CSV + xoá thư mục rỗng.
   6. Tất cả .js sinh ra là UTF-8 KHÔNG BOM.

 Chạy được với PowerShell 7 (pwsh) LẪN Windows PowerShell 5.1 (bản có sẵn trên Windows).

 ⚠️ LƯU Ý CHO NGƯỜI SỬA FILE NÀY: phải lưu ở "UTF-8 CÓ BOM". Nếu lưu không BOM, Windows
    PowerShell 5.1 sẽ đọc sai các dòng tiếng Việt và báo lỗi cú pháp khi "Run with PowerShell".
================================================================================
#>

Set-StrictMode -Version Latest
$ErrorActionPreference = "Stop"

# --- Xác định đường dẫn gốc dự án (thư mục cha của tools/) ---
$scriptFolder  = Split-Path -Parent $MyInvocation.MyCommand.Path
$projectRoot   = Split-Path -Parent $scriptFolder
$csvRoot       = Join-Path $projectRoot "data\csv"
$dataRoot      = Join-Path $projectRoot "data"

if (-not (Test-Path $csvRoot)) {
    Write-Error "Không tìm thấy thư mục $csvRoot. Bạn đã đặt CSV vào data/csv/<CẤP>/ chưa?"
}

# --- Hàm ghi file UTF-8 KHÔNG BOM ---
function Write-Utf8NoBom {
    param([string]$Path, [string]$Content)
    $utf8NoBom = New-Object System.Text.UTF8Encoding($false)
    [System.IO.File]::WriteAllText($Path, $Content, $utf8NoBom)
}

# --- Hàm sắp thứ tự cấp: HSK trước (theo số HSK1<HSK2<...), rồi tới các cấp khác (theo số), tên không số cuối cùng ---
function Get-LevelSortKey {
    param([string]$LevelName)
    if ($LevelName -match '^HSK(\d+)') { return [int]$Matches[1] }          # HSK1..HSK6 -> 1..6 (đứng đầu)
    if ($LevelName -match '^BT(\d+)')  { return 1000 + [int]$Matches[1] }   # BT1..: 100 bộ thủ theo nghĩa
    if ($LevelName -match '^KX(\d+)')  { return 2000 + [int]$Matches[1] }   # KX1..: 214 bộ Khang Hy theo số nét
    if ($LevelName -match '(\d+)')     { return 3000 + [int]$Matches[1] }   # cấp khác có số
    return 9999
}

# --- 1. Tìm cấp: quét ĐỆ QUY mọi words.csv trong data/csv (bỏ _TEMPLATE / thư mục bắt đầu '_') ---
#     Cấp có thể nằm trực tiếp (data/csv/HSK1) hoặc trong thư mục nhóm (data/csv/BoThu/BT1).
$levelFolders = Get-ChildItem -Path $csvRoot -Recurse -File -Filter "words.csv" |
    Where-Object { $_.FullName -notmatch '[\\/]_' } |
    ForEach-Object { $_.Directory } |
    Sort-Object @{ Expression = { Get-LevelSortKey $_.Name } }, FullName

if (-not $levelFolders) {
    Write-Warning "Không thấy words.csv nào trong data/csv/. (Cần vd data/csv/HSK1/words.csv)"
}

$orderedLevelNames = @()   # thứ tự mã cấp, để ghi vào manifest
$orderedSrcs       = @()   # đường dẫn file .js tương ứng (cho loader nạp đúng vị trí)
$generatedFiles    = @{}   # tập đường dẫn .js đã sinh (để dọn rác chính xác)
$summaryLines = @()        # tóm tắt in ra cuối

foreach ($levelFolder in $levelFolders) {
    $levelName = $levelFolder.Name                    # vd "HSK1"
    $levelSlug = $levelName.ToLower()                 # vd "hsk1"
    $wordsCsvPath = Join-Path $levelFolder.FullName "words.csv"
    $convsCsvPath = Join-Path $levelFolder.FullName "conversations.csv"
    $sentencesCsvPath = Join-Path $levelFolder.FullName "sentences.csv"

    if (-not (Test-Path $wordsCsvPath)) {
        Write-Warning "Bỏ qua cấp '$levelName': thiếu words.csv"
        continue
    }

    # --- Đọc từ vựng, ánh xạ cột CSV (tiếng Việt) -> khoá nội bộ ---
    $wordObjects = [System.Collections.Generic.List[object]]::new()
    $wordRows = @(Import-Csv -Path $wordsCsvPath -Encoding utf8)
    foreach ($row in $wordRows) {
        $chuHan = ("" + $row.chuHan).Trim()
        if ([string]::IsNullOrWhiteSpace($chuHan)) { continue }   # bỏ dòng trống
        $wordObjects.Add([ordered]@{
            w     = $chuHan
            p     = ("" + $row.pinyin)
            m     = ("" + $row.nghia)
            ex    = ("" + $row.viDu)
            exp   = ("" + $row.viDuPinyin)
            exm   = ("" + $row.viDuNghia)
            topic = ("" + $row.chuDe)
        })
    }

    # --- Đọc hội thoại (không bắt buộc). Mỗi dòng = 1 câu thoại; gộp theo cột hoiThoai ---
    $conversationObjects = [System.Collections.Generic.List[object]]::new()
    if (Test-Path $convsCsvPath) {
        $convRows = @(Import-Csv -Path $convsCsvPath -Encoding utf8)
        $conversationByTitle = [ordered]@{}   # giữ thứ tự xuất hiện của hội thoại
        foreach ($crow in $convRows) {
            $title = ("" + $crow.hoiThoai).Trim()
            if ([string]::IsNullOrWhiteSpace($title)) { continue }
            if (-not $conversationByTitle.Contains($title)) {
                $conversationByTitle[$title] = [ordered]@{
                    title = $title
                    icon  = ("" + $crow.icon).Trim()
                    lines = [System.Collections.Generic.List[object]]::new()
                }
            }
            # icon: điền ở dòng đầu; nếu dòng đầu để trống mà dòng sau có thì vẫn nhận
            if ([string]::IsNullOrWhiteSpace($conversationByTitle[$title].icon) -and -not [string]::IsNullOrWhiteSpace(("" + $crow.icon))) {
                $conversationByTitle[$title].icon = ("" + $crow.icon).Trim()
            }
            $conversationByTitle[$title].lines.Add([ordered]@{
                who = ("" + $crow.nguoi).Trim()
                zh  = ("" + $crow.cau)
                py  = ("" + $crow.pinyin)
                vi  = ("" + $crow.nghia)
            })
        }
        foreach ($key in $conversationByTitle.Keys) {
            $conversationObjects.Add($conversationByTitle[$key])
        }
    }

    # --- Đọc câu độc lập (không bắt buộc): sentences.csv. Mỗi dòng = 1 câu cho chế độ Dịch câu ---
    $sentenceObjects = [System.Collections.Generic.List[object]]::new()
    if (Test-Path $sentencesCsvPath) {
        $sentenceRows = @(Import-Csv -Path $sentencesCsvPath -Encoding utf8)
        foreach ($srow in $sentenceRows) {
            $cau = ("" + $srow.cau).Trim()
            if ([string]::IsNullOrWhiteSpace($cau)) { continue }   # bỏ dòng trống
            $sentenceObjects.Add([ordered]@{
                zh    = $cau
                py    = ("" + $srow.pinyin)
                vi    = ("" + $srow.nghia)
                topic = ("" + $srow.chuDe)
            })
        }
    }

    # --- Sinh file cấp data/<LEVEL>/<level>.js ---
    $payload = [ordered]@{
        words         = $wordObjects
        conversations = $conversationObjects
        sentences     = $sentenceObjects
    }
    # ConvertTo-Json giữ nguyên chữ Hán (UTF-8), escape an toàn nháy/backslash/xuống dòng.
    $payloadJson = $payload | ConvertTo-Json -Depth 12
    # ép mảng rỗng hiển thị đúng là [] (ConvertTo-Json đôi khi đưa null cho list rỗng)
    if ($wordObjects.Count -eq 0)         { $payloadJson = $payloadJson -replace '"words":\s*null', '"words": []' }
    if ($conversationObjects.Count -eq 0) { $payloadJson = $payloadJson -replace '"conversations":\s*null', '"conversations": []' }
    if ($sentenceObjects.Count -eq 0)     { $payloadJson = $payloadJson -replace '"sentences":\s*null', '"sentences": []' }

    # --- Xác định nhóm (thư mục cha) để GOM file .js: data/csv/BoThu/BT1 -> data/BoThu/bt1.js ---
    $relFromCsv = $levelFolder.FullName.Substring($csvRoot.Length).TrimStart('\', '/')   # vd "BoThu\BT1" hoặc "HSK1"
    $relSegments = $relFromCsv -split '[\\/]'
    if ($relSegments.Length -gt 1) { $groupPath = ($relSegments[0..($relSegments.Length - 2)]) -join '\' }
    else { $groupPath = "" }
    if ($groupPath -eq "") {
        $levelOutFolder = Join-Path $dataRoot $levelName
        $srcPath = "data/$levelName/$levelSlug.js"
    } else {
        $levelOutFolder = Join-Path $dataRoot $groupPath
        $srcPath = "data/" + ($groupPath -replace '\\', '/') + "/$levelSlug.js"
    }

    $header = "// TỰ ĐỘNG SINH từ data/csv/$($relFromCsv -replace '\\','/')/*.csv — ĐỪNG SỬA TAY (chạy tools/build.ps1)."
    $levelJs = "$header`nregisterLevel(""$levelName"", $payloadJson);`n"

    if (-not (Test-Path $levelOutFolder)) { New-Item -ItemType Directory -Path $levelOutFolder | Out-Null }
    $levelOutPath = Join-Path $levelOutFolder "$levelSlug.js"
    Write-Utf8NoBom -Path $levelOutPath -Content $levelJs
    $generatedFiles[(Resolve-Path $levelOutPath).Path] = $true

    $orderedLevelNames += $levelName
    $orderedSrcs += $srcPath
    $summaryLines += ("  {0,-9} {1,4} từ, {2,3} hội thoại, {3,4} câu   -> {4}" -f $levelName, $wordObjects.Count, $conversationObjects.Count, $sentenceObjects.Count, $srcPath)
}

# --- 4. Sinh data/manifest.js (LEVELS = mã cấp; LEVEL_SRC = đường dẫn .js để loader nạp) ---
$levelsJsArray = "[" + (($orderedLevelNames | ForEach-Object { '"' + $_ + '"' }) -join ", ") + "]"
$srcsJsArray   = "[" + (($orderedSrcs       | ForEach-Object { '"' + $_ + '"' }) -join ", ") + "]"
$manifestJs = @"
/* TỰ ĐỘNG SINH — ĐỪNG SỬA TAY (chạy tools/build.ps1). LEVELS = mã cấp; LEVEL_SRC = file .js để nạp. */
var LEVELS = $levelsJsArray;
var LEVEL_SRC = $srcsJsArray;
if (typeof window !== "undefined") { window.LEVELS = LEVELS; window.LEVEL_SRC = LEVEL_SRC; }
if (typeof self !== "undefined") { self.LEVELS = LEVELS; self.LEVEL_SRC = LEVEL_SRC; }
"@
Write-Utf8NoBom -Path (Join-Path $dataRoot "manifest.js") -Content ($manifestJs + "`n")

# --- 5. Dọn rác: xoá .js sinh ra không còn tương ứng cấp, rồi xoá thư mục rỗng (trừ data/csv) ---
$csvPrefix = $csvRoot.TrimEnd('\', '/') + [System.IO.Path]::DirectorySeparatorChar
$generatedJs = Get-ChildItem -Path $dataRoot -Recurse -File -Filter "*.js" |
    Where-Object { -not $_.FullName.StartsWith($csvPrefix) -and $_.Name -ne "registry.js" -and $_.Name -ne "manifest.js" }
foreach ($js in $generatedJs) {
    if (-not $generatedFiles.ContainsKey($js.FullName)) {
        Write-Host "  Dọn rác: xoá $($js.FullName.Substring($projectRoot.Length).TrimStart('\', '/'))" -ForegroundColor Yellow
        Remove-Item -Path $js.FullName -Force
    }
}
# xoá thư mục rỗng (sâu nhất trước), không đụng data/csv
Get-ChildItem -Path $dataRoot -Recurse -Directory |
    Where-Object { -not $_.FullName.StartsWith($csvPrefix) -and $_.FullName -ne $csvRoot } |
    Sort-Object { $_.FullName.Length } -Descending |
    ForEach-Object { if (-not (Get-ChildItem -Path $_.FullName -Force)) { Remove-Item -Path $_.FullName -Force } }

# --- 6. (Tuỳ chọn) Tăng phiên bản cache của service worker nếu có ---
$swPath = Join-Path $projectRoot "sw.js"
if (Test-Path $swPath) {
    $swText = Get-Content -Path $swPath -Raw -Encoding utf8
    $bumpedSw = [regex]::Replace($swText, '(CACHE_VERSION\s*=\s*)(\d+)', {
        param($m) $m.Groups[1].Value + ([int]$m.Groups[2].Value + 1)
    })
    if ($bumpedSw -ne $swText) {
        Write-Utf8NoBom -Path $swPath -Content $bumpedSw
        Write-Host "  Đã tăng CACHE_VERSION trong sw.js" -ForegroundColor Cyan
    }
}

# --- 7. In tóm tắt ---
Write-Host ""
Write-Host "Build xong. Các cấp (đúng thứ tự nạp):" -ForegroundColor Green
Write-Host ("  LEVELS = " + $levelsJsArray)
$summaryLines | ForEach-Object { Write-Host $_ }
Write-Host ""
Write-Host "Mở file HTML (double-click) để xem kết quả. Không cần web server." -ForegroundColor Green
