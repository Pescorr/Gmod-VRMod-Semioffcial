<!-- Template v1.0 -->
# NEXT_SESSION.md テンプレート

> **使い方**: このファイルをコピーして NEXT_SESSION.md を作成する。
> ★マークのセクションは**必須**。☆マークのセクションは**任意**（あると望ましい）。
> プレースホルダー（`{...}`）を実際の内容に置き換えること。
> セクションの順序は変えないこと。内容が該当しない場合は「該当なし」と記入する。
> **コード埋込禁止** — ファイルパスと行番号で参照すること。

---

# ★ {project_name} セッション{N}: {title}

## ★ セッション情報
- **セッション番号**: {N}
- **前提**: {prerequisites: e.g. 前セッション完了、特定のライブラリインストール済み}
- **目標**: {one_sentence_goal}
- **推定所要時間**: {estimate: e.g. 2-3時間}

---

## ★ 開始前チェックリスト（必須）

以下のファイルをこの順序で読み込んでください：

1. **CLAUDE.md**（自動読込済み）
   - 目的: 核心原則と禁止事項の確認

2. **LESSONS.md**
   - パス: {full_path}
   - 目的: このセッションに関連する教訓の確認

3. **NEXT_SESSION.md**（このファイル）
   - パス: {full_path}
   - 目的: 作業手順の確認

4. **{additional_reference}**（{required_or_optional}）
   - パス: {full_path}
   - 目的: {why_read_this}

<!-- Add items 5, 6... as needed -->

確認完了後：

- [ ] 核心原則を再確認した
- [ ] 禁止事項を再確認した
- [ ] 前セッションの成果物が存在することを確認した
- [ ] {session_specific_check}

---

## ★ 目標

### 主要成果物
<!-- Each deliverable: filename, estimated lines, brief description -->
1. {deliverable_1: e.g. src/auth/login.ts (~150行) — ログイン処理}
2. {deliverable_2}
3. {deliverable_3}

### 成功基準
<!-- Verifiable, checkbox-able criteria -->
- [ ] {criterion_1: e.g. ログインフローが正常動作する}
- [ ] {criterion_2: e.g. エラー時に適切なメッセージが表示される}
- [ ] {criterion_3}

---

## ★ 作業内容（優先順）

<!-- Implementation sessions: specify file paths and features -->
<!-- Research sessions: specify investigation targets and questions -->

### タスク1: {task_name}

**ファイルパス**: `{full_path}`
**目的**: {what_this_achieves}

**機能**:
- {feature_1}
- {feature_2}
- {feature_3}

**重要な設計判断**:
- {decision_and_why}

**依存するシステム**:
- {dependency_1: e.g. auth module (src/auth/), database schema (migrations/)}

---

### タスク2: {task_name}

<!-- Same structure as Task 1 -->

---

### タスク3: {task_name}

<!-- Same structure. Omit if only 1-2 tasks -->

---

## ★ 動作確認（完了後に実行）

> テストケースは検証環境で分類すること

### 環境A: {easy_test_environment} で確認可能
<!-- e.g. "ローカル環境", "ユニットテスト", "ブラウザ", "CLIコマンド" -->

#### TC1: {test_name}
```{language}
{test_command_or_steps}
```
**期待結果**: {expected_output}

#### TC2: {test_name}
```{language}
{test_command_or_steps}
```
**期待結果**: {expected_output}

### 環境B: {harder_test_environment} が必要
<!-- e.g. "ステージングサーバー", "実機デバイス", "VRヘッドセット", "CI/CD" -->

#### TC{N}: {test_name}
{description_only}

---

## ★ 品質基準（全て満たすこと）

- [ ] **動作確認済み**: 全テストケースが成功
- [ ] **命名規則**: {convention: e.g. camelCase}を守っている
- [ ] **依存関係**: {rule: e.g. 循環依存がない}
- [ ] **コメント**: 実装意図が説明されている
- [ ] **エラーハンドリング**: エラーが起きても致命的にならない
- [ ] {session_specific_quality_gate}

---

## ★ 過去セッションで学んだ注意事項

> LESSONS.md から、このセッションに関連するものを番号で引用

- L{N}: {lesson_summary}
- L{M}: {lesson_summary}
- L{K}: {lesson_summary}

---

## ★ セッション終了前のタスク

> **このセクションは引き継ぎシステムの生命線**。必ず全項目を実行すること。

1. **PROGRESS.md更新**: このセッションの成果をタスク一覧に追記
2. **CODE_STATUS.md更新**: 新規/修正ファイルのステータス更新
3. **LESSONS.md更新**: 新たな知見があれば番号付きで追記
4. **NEXT_SESSION.md作成**（次のセッション用）: このテンプレートに従う
5. **動作確認結果を記録**: テスト結果をPROGRESS.mdに追記

---

## ★ 参考資料（優先順）

1. CLAUDE.md（自動読込）
2. LESSONS.md
3. {session_specific_reference}
4. {additional_reference}

---

## ☆ 補足: 後続セッションの見通し

> 任意セクション。次の2-3セッションの予定を書いておくと、コンテキスト理解が速い。

| セッション | 内容 | 前提 |
|-----------|------|------|
| **S{N}** (今回) | {current} | {prerequisites} |
| **S{N+1}** | {next_plan} | 今回完了 |
| **S{N+2}** | {after_next_plan} | S{N+1}完了 |

---

準備が完了したら、作業を開始してください。
全ての品質基準を満たし、テストケースが成功することを確認してください。
