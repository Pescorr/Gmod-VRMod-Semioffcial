<!-- Template v1.0 -->
# {project_name} コードステータス

**最終更新**: {date} ({milestone})

全ファイルの実装ステータス一覧。軽量参照用。

---

## {module_1_name}（{file_count}ファイル）

<!-- One table per module/directory. Keep descriptions to one line -->

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `{path/file1}` | ✅ | {one_line_description} |
| `{path/file2}` | 🔧 | {what_needs_modification} |
| `{path/file3}` | ⬜ | {what_will_be_created} |

## {module_2_name}（{file_count}ファイル）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `{path/file1}` | ✅ | {one_line_description} |

<!-- Add sections for each module/directory in your project -->

<!-- Example:
## src/auth/（3ファイル）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `src/auth/login.ts` | ✅ | ログイン処理、JWT生成 |
| `src/auth/middleware.ts` | ✅ | 認証ミドルウェア |
| `src/auth/register.ts` | ⬜ | Phase 2で実装予定 |

## src/api/（2ファイル）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `src/api/routes.ts` | ✅ | ルーティング定義 |
| `src/api/handlers.ts` | 🔧 | エラーハンドリング追加が必要 |
-->

---

## 集計

| カテゴリ | ファイル数 |
|---------|-----------|
| ✅ 完成（変更不要） | {N} |
| 🔧 要修正 | {N} |
| ⬜ 未着手（新規作成） | {N} |
| **合計** | **{N}** |

---

<!-- 凡例 -->
<!-- ✅ = 完成、変更不要 -->
<!-- 🔧 = 要修正（何が必要か備考に記載） -->
<!-- ⬜ = 未着手、新規作成 -->
<!-- 🚫 = 廃止・削除 -->
