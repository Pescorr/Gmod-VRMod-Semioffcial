<!-- Template v1.0 -->
# {project_name} 進捗管理

**最終更新**: {date} ({milestone})

---

## 現在地点

- **{current_phase}** — {brief_description}
- **実装量**: {file_count}ファイル / 約{line_count}行
- **次のアクション**: NEXT_SESSION.md参照

---

## フェーズ一覧

<!-- Track all planned phases. Update status emoji as you progress -->
<!-- 状態の凡例: ✅ 完了, 🔧 進行中, ⬜ 未着手 -->

| Phase | 内容 | セッション数 | 状態 |
|-------|------|------------|------|
| **0** | {description: e.g. プロジェクトセットアップ、ドキュメント作成} | {count} | ✅ |
| **1** | {description: e.g. コア基盤} | {estimate} | ⬜ |
| **2** | {description: e.g. 主要機能} | {estimate} | ⬜ |
| **3** | {description: e.g. 応用機能} | {estimate} | ⬜ |
| **4** | {description: e.g. テスト・ポリッシュ} | {estimate} | ⬜ |

**合計見込み**: 約{N}セッション

---

## 完了済みセッション一覧

<!-- Group sessions by phase or era for readability -->

### {phase_or_era_name}（S{start}〜S{end}）

| セッション | 内容 | 成果物 |
|-----------|------|--------|
| S1 | {description} | {deliverables: files created/modified} |

<!-- Add more era sections as project progresses -->
<!-- Example:
### Phase 0: セットアップ（S1）

| セッション | 内容 | 成果物 |
|-----------|------|--------|
| S1 | プロジェクト初期化、ドキュメント作成 | CLAUDE.md, DEVELOPMENT_POLICY.md, 初期ファイル構成 |

### Phase 1: コア基盤（S2〜S4）

| セッション | 内容 | 成果物 |
|-----------|------|--------|
| S2 | データベース設計 | migrations/001_init.sql, src/db/schema.ts |
| S3 | 認証基盤 | src/auth/login.ts, src/auth/middleware.ts |
| S4 | API基盤 | src/api/routes.ts, src/api/handlers/ |
-->

---

## ファイル一覧

CODE_STATUS.md を参照。

---

## 教訓一覧

LESSONS.md を参照。

---

**次のアクション**: NEXT_SESSION.md を参照
