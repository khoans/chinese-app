<#
================================================================================
 tools/build.ps1  —  Sinh dữ liệu app tiếng Trung từ CSV
--------------------------------------------------------------------------------
 CÁCH DÙNG (người biên soạn):
   Chuột phải file này -> "Run with PowerShell"   (hoặc trong terminal: pwsh ./tools/build.ps1)

 SCRIPT LÀM GÌ:
   1. Quét data/csv/ tìm các thư mục cấp (mọi thư mục trừ _TEMPLATE), vd HSK1, HSK2.
   2. Đọc words.csv (và conversations.csv nếu có) của từng cấp.
   3. Sinh data/<LEVEL>/<level>.js gọi registerLevel(...). ĐỪNG sửa các file này bằng tay.
   4. Sinh data/manifest.js đặt biến LEVELS (đúng thứ tự cấp).
   5. Dọn rác: xoá thư mục cấp .js đã sinh nhưng CSV không còn.
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

# --- 1. Tìm các thư mục cấp trong data/csv (bỏ _TEMPLATE và mọi thư mục bắt đầu bằng '_') ---
$levelFolders = Get-ChildItem -Path $csvRoot -Directory |
    Where-Object { $_.Name -notlike "_*" } |
    Sort-Object @{ Expression = { Get-LevelSortKey $_.Name } }, Name

if (-not $levelFolders) {
    Write-Warning "Không thấy thư mục cấp nào trong data/csv/. (Cần vd data/csv/HSK1/words.csv)"
}

$orderedLevelNames = @()   # thứ tự cấp cuối cùng, để ghi vào manifest
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

    $header = "// TỰ ĐỘNG SINH từ data/csv/$levelName/*.csv — ĐỪNG SỬA TAY (chạy tools/build.ps1)."
    $levelJs = "$header`nregisterLevel(""$levelName"", $payloadJson);`n"

    $levelOutFolder = Join-Path $dataRoot $levelName
    if (-not (Test-Path $levelOutFolder)) { New-Item -ItemType Directory -Path $levelOutFolder | Out-Null }
    $levelOutPath = Join-Path $levelOutFolder "$levelSlug.js"
    Write-Utf8NoBom -Path $levelOutPath -Content $levelJs

    $orderedLevelNames += $levelName
    $summaryLines += ("  {0,-8} {1,4} từ, {2,3} hội thoại, {3,4} câu" -f $levelName, $wordObjects.Count, $conversationObjects.Count, $sentenceObjects.Count)
}

# --- 4. Sinh data/manifest.js ---
$levelsJsArray = "[" + (($orderedLevelNames | ForEach-Object { '"' + $_ + '"' }) -join ", ") + "]"
$manifestJs = @"
/* TỰ ĐỘNG SINH — ĐỪNG SỬA TAY (chạy tools/build.ps1). Danh sách cấp cho app tự nạp. */
var LEVELS = $levelsJsArray;
if (typeof window !== "undefined") window.LEVELS = LEVELS;
if (typeof self !== "undefined") self.LEVELS = LEVELS;
"@
Write-Utf8NoBom -Path (Join-Path $dataRoot "manifest.js") -Content ($manifestJs + "`n")

# --- 5. Dọn rác: xoá thư mục cấp .js đã sinh mà CSV không còn ---
$validLevelSet = @{}
foreach ($lvName in $orderedLevelNames) { $validLevelSet[$lvName] = $true }
$existingDataDirs = Get-ChildItem -Path $dataRoot -Directory | Where-Object { $_.Name -ne "csv" }
foreach ($existingDir in $existingDataDirs) {
    if (-not $validLevelSet.ContainsKey($existingDir.Name)) {
        Write-Host "  Dọn rác: xoá data/$($existingDir.Name)/ (không còn CSV nguồn)" -ForegroundColor Yellow
        Remove-Item -Path $existingDir.FullName -Recurse -Force
    }
}

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
