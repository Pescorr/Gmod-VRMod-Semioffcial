$curBase = 'R:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\addons\vrmod_semioffcial\lua'
$failBase = 'R:\SteamLibrary\steamapps\common\GarrysMod\garrysmod\vrmod_semioffcial_backup\20260513failed\vrmod_semioffcial\lua'

$cur = Get-ChildItem $curBase -Recurse -Filter '*.lua' | ForEach-Object {
    $_.FullName.Substring($curBase.Length + 1)
}
$fail = Get-ChildItem $failBase -Recurse -Filter '*.lua' | ForEach-Object {
    $_.FullName.Substring($failBase.Length + 1)
}

Write-Host "現在版ファイル数: $($cur.Count)"
Write-Host "failed版ファイル数: $($fail.Count)"

$diff = Compare-Object $cur $fail

Write-Host ""
Write-Host "=== 現在版のみ(追加されたファイル) ==="
$added = $diff | Where-Object { $_.SideIndicator -eq '<=' }
if ($added) {
    foreach ($item in $added) {
        Write-Host ("  + " + $item.InputObject)
    }
} else {
    Write-Host "  (なし)"
}

Write-Host ""
Write-Host "=== failed版のみ(現在版で削除されたファイル) ==="
$removed = $diff | Where-Object { $_.SideIndicator -eq '=>' }
if ($removed) {
    foreach ($item in $removed) {
        Write-Host ("  - " + $item.InputObject)
    }
} else {
    Write-Host "  (なし)"
}

$common = $cur | Where-Object { $fail -contains $_ }
Write-Host ""
Write-Host "=== 共通ファイル数: $($common.Count) ==="

# 共通ファイルのサイズ比較
Write-Host ""
Write-Host "=== 共通ファイルでサイズが異なるもの ==="
foreach ($f in $common) {
    $curPath = Join-Path $curBase $f
    $failPath = Join-Path $failBase $f
    $curSize = (Get-Item $curPath).Length
    $failSize = (Get-Item $failPath).Length
    if ($curSize -ne $failSize) {
        Write-Host ("  ~ " + $f + " (現在:" + $curSize + ", failed:" + $failSize + ")")
    }
}

# 共通ファイルで内容が同じもの
$sameCount = 0
foreach ($f in $common) {
    $curPath = Join-Path $curBase $f
    $failPath = Join-Path $failBase $f
    $curContent = Get-Content $curPath -Raw
    $failContent = Get-Content $failPath -Raw
    if ($curContent -eq $failContent) {
        $sameCount++
    }
}
Write-Host ""
Write-Host "=== 内容が完全に同じファイル数: $sameCount ==="
