#!/bin/bash
# create_upload.sh - Steam Workshopアップロード用フォルダ作成
# Usage: bash create_upload.sh [output_dir]
#   デフォルト出力先: ../vrmod_semioffcial_upload
#
# このスクリプトは開発用ファイルを除外したクリーンなアドオンフォルダを作成します。
# x64モードフォルダ(64/)、バックアップ、開発ドキュメント等は除外されます。

set -e

SRC="$(cd "$(dirname "$0")" && pwd)"
DST="${1:-$(dirname "$SRC")/vrmod_semioffcial_upload}"

echo "=========================================="
echo " Workshop Upload Folder Creator"
echo "=========================================="
echo "Source: $SRC"
echo "Output: $DST"
echo ""

# 既存の出力先があれば削除して再作成
if [ -d "$DST" ]; then
    echo "[CLEAN] Removing existing output folder..."
    rm -rf "$DST"
fi
mkdir -p "$DST"

# --- ルートファイル ---
echo "[COPY] addon.json, LICENSE..."
cp "$SRC/addon.json" "$DST/"
cp "$SRC/LICENSE" "$DST/"

# --- lua/ (64/フォルダを除外) ---
echo "[COPY] lua/ (excluding 64/ x64mode)..."
cp -r "$SRC/lua" "$DST/"
rm -rf "$DST/lua/vrmodunoffcial/64"

# --- materials/, models/ ---
echo "[COPY] materials/..."
cp -r "$SRC/materials" "$DST/"
echo "[COPY] models/..."
cp -r "$SRC/models" "$DST/"

# --- 不要ファイル削除 ---
echo "[CLEAN] Removing dev/backup files..."
find "$DST" -name "*.backup" -delete 2>/dev/null || true
find "$DST" -name "*bak_*" -delete 2>/dev/null || true
find "$DST" -name "GmodVR -APIDocument.txt" -delete 2>/dev/null || true

# --- 結果表示 ---
FILE_COUNT=$(find "$DST" -type f | wc -l)
echo ""
echo "=========================================="
echo " DONE"
echo "=========================================="
echo "Output: $DST"
echo "Files:  $FILE_COUNT"
echo ""
echo "Excluded:"
echo "  - lua/vrmodunoffcial/64/ (x64 mode)"
echo "  - *.backup, *bak_* files"
echo "  - GmodVR -APIDocument.txt"
echo "  - All dev files (.md, reference/, backup_*, etc. are not in source copy)"
echo ""
echo "Ready for Workshop upload."
