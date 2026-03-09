# vrmod_semioffcial_addonplus

## プロジェクト概要
semiofficial/オリジナルVRMod上で動く追加アドオン。
VRでのgmod体験をより楽しくする機能を追加していく。

## ターゲット
- **主対象**: semiofficial + オリジナル（v21）VRMod
- **x64**: 動けばラッキー、サポートはしない
- **C++モジュール**: semiofficial/オリジナル/x64で同一API（16関数）

## 基本原則
1. **出すことが最優先** — 完璧より完成を目指す
2. **VR未使用時に影響を与えない** — VR接続時のみ動作
3. **既存のsemiofficial/オリジナルの動作を壊さない**
4. **小さく出して、反応を見る** — 1機能ずつリリース

## コーディング規約
- C++モジュール関数はpcall保護必須
- 防御的初期化: `vrmod.X = vrmod.X or {}`
- ConVar: 毎フレーム`GetConVar()`禁止、ローカル変数で遅延初期化
- ConVar名: `vrmod_unoff_*` を使用
- `string.StartWith`（sなし）が正しいGLua API
- `file.Append`は`.txt`拡張子のみ動作

## フォルダ構造
```
lua/
  autorun/          — エントリーポイント（起動時に自動読込）
  autorun/client/   — クライアント側autorun
  entities/         — カスタムエンティティ
  weapons/          — 武器定義
  vrmodunoffcial/   — メインコード（番号付きフォルダで読込順序制御）
    0/ — コア・API（steamvr_bindings, api等）
    1/ — 自動設定・最適化
    2/ — ホルスターシステム Type2
    3/ — フォアグリップ
    4/ — マグボーンシステム
    5/ — 近接攻撃
    6/ — ホルスターシステム Type1
    8/ — 物理・フィジックスガンピックアップ
    9/ — VRピックアップ
materials/          — VMTファイル
models/             — モデルファイル
reference/          — 解析ドキュメント（gitignore対象、Workshop非公開）
```

## 解析ドキュメント（reference/）
REプロジェクトから引き継いだ解析データ + セッション別コンテキスト。開発時の参照用:
- `CONTEXT_MELEE.md` — Melee系タスク用コンテキスト
- `CONTEXT_HUD_FIX.md` — HUD修正コンテキスト
- `CONTEXT_X64_COMPARISON.md` — x64比較・採用判断
- `CONTEXT_PICKUP.md` — Pickup系タスク用コンテキスト
- `ANALYSIS_REPORT.md` — semiofficial コード解析
- `ANALYSIS_REPORT_X64.md` — x64 コード解析
- `ANALYSIS_REPORT_PICKUP.md` — Pickupシステム詳細解析
- `ANALYSIS_REPORT_MODULE_*.md` — C++モジュール解析
- `COMPARATIVE_ANALYSIS*.md` — semiofficial/x64比較
- `SEMIOFFICIAL_FEATURES_DETAILED.md` — semiofficial機能詳細
- `CODE_SNIPPETS.md` — コードスニペット集
- `DEVELOPMENT_POLICY.md` — 開発ポリシー詳細

## 禁止事項
- カスタムHUD要素を描画しない（既存HUDをRT→VR手に表示）
- x64固有機能（ハンドキューブ、独自メニュー等）に依存しない
- VR終了後にConVar変更・フックを残留させない

## Current Status
- **フェーズ**: オープンベータ（既存機能の安定化・改善）
- **規模**: 107ファイル（Lua 105 + 無効化2） / 約14,000行 / 194コミット
- **トラッキング**: PROGRESS.md, CODE_STATUS.md, LESSONS.md, BACKLOG.md
- **開発ポリシー詳細**: reference/DEVELOPMENT_POLICY.md
- **テンプレート**: claude-dev-templates/

## Session Operating Rules
- 1セッション1〜2タスクに制限する
- **セッション開始**: ユーザーがタスクを指定（BACKLOGから or 衝動的、どちらでもOK）
- **セッション開始**: Claudeは関連するreference/ファイルのみ読む（MEMORY.mdのReference Index参照）
- **セッション中**: 間違いを修正したらLESSONS.mdを更新する
- **セッション終了**: PROGRESS.mdに成果を簡潔に記録
- **セッション終了**: 複数セッション必要な場合のみNEXT_SESSION.md作成
- **セッション終了**: 新しい教訓があればLESSONS.md更新
- ハンドオフは簡潔に（コード埋め込み不可、ファイルパス+行範囲のみ）
- BACKLOG.md: プレイ中に気づいた問題のメモ帳。ユーザーが随時追記

## PDCAサイクル型ワークフロー

1タスク = P→D→C→A の4つの専用会話（小タスクでも例外なし）
- **P (Plan)** — 計画、handoff/S{N}_plan.md 作成
- **D (Do)** — handoff/S{N}_plan.md を読んで実装、handoff/S{N}_do.md 作成
- **C (Check)** — ユーザーが採点、handoff/S{N}_check.md 記録
- **A (Action)** — 60点未満の場合のみ修正
- 詳細: reference/PDCA_WORKFLOW.md

## 会話保存
- 会話終了後、ユーザーが手動で claude_talk_save/ に保存

## 緊急時: 会話解析専用セッション
- 「プランが失敗しました」でユーザーが発動
- claude_talk_save/ から議事録を添付して失敗分析

## 定期大規模点検（5-10タスクごと）
- CODE_STATUS.md一括更新、BACKLOG整理、優先順位再評価

## Compact Instructions
圧縮時に必ず保持:
- 修正中のファイル一覧と現在の状態
- エラーメッセージとその解決策
- 上記基本原則と禁止事項
- 現在のタスク進捗
- トラッキングファイルの存在（PROGRESS.md, CODE_STATUS.md, LESSONS.md）
