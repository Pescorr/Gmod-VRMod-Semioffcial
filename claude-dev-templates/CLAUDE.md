<!-- Template v1.0 — このファイルは~50行以内に収めること -->
# {project_name}

## 絶対ルール（核心原則）
<!-- 3-7個の原則。各1行。理由はDEVELOPMENT_POLICY.mdに記載 -->
1. {principle_1: e.g. 既存APIとの互換性を維持する}
2. {principle_2: e.g. フェールセーフ（障害が他に波及しない）}
3. {principle_3: e.g. 構造は単純に（過度な抽象化禁止）}

## 禁止事項
<!-- 絶対にやってはいけないこと。"- 行為: 簡潔な理由" の形式 -->
- {prohibition_1: e.g. ユーザーの既存設定を破壊する変更}
- {prohibition_2: e.g. テストなしでのリリース}

## コーディング規約
<!-- 言語/フレームワーク固有の規約。1行1規約 -->
- {convention_1: e.g. ファイル命名: feature_name.ts}
- {convention_2: e.g. エラーハンドリング: try-catch必須}
- {convention_3: e.g. 関数は単一責任}

## 基本前提
<!-- このプロジェクトの不変の前提。2-4行 -->
- {assumption_1: e.g. このプロジェクトは単体で動作する（外部依存なし）}
- {assumption_2: e.g. Node.js 20+, TypeScript 5.x}

## 現在地
<!-- 毎セッション更新。3-5行 -->
- {current_phase_and_status}
- 実装済み: {summary_metric: e.g. 15ファイル / 約2,000行}
- 詳細タスク: NEXT_SESSION.md参照
- 進捗履歴: PROGRESS.md参照
- 全原則の詳細: DEVELOPMENT_POLICY.md参照（迷った時のみ）

## セッション運用ルール
- 1セッション1〜2タスクに限定する（欲張らない）
- 引き継ぎファイル作成は簡潔に（NEXT_SESSION.mdにコード埋込禁止、パス参照のみ）
- 修正・バグ発見のたびにLESSONS.mdを更新する

## Compact Instructions
圧縮時に必ず保持すること:
- 修正中のファイル一覧と現在の状態
- エラーメッセージとその解決策
- 上記核心原則と禁止事項
- 現在のタスク進捗
- {project_specific_critical_data: e.g. 固定のモジュール順序、DB スキーマ}
