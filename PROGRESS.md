# vrmod_semioffcial_addonplus 進捗管理

**最終更新**: 2026-03-10（S12: input.IsKeyDown VRエミュレーション — Plan会話）

---

## 現在地点

- **オープンベータ** — 既存機能の安定化・改善フェーズ
- **実装量**: 110ファイル（Lua 108 + 無効化2） / 約14,250行
- **Gitコミット**: 194件
- **次のアクション**: input.IsKeyDownエミュレーションのVRテスト検証

---

## フェーズ一覧

| Phase | 内容 | セッション数 | 状態 |
|-------|------|------------|------|
| **0** | プロジェクトセットアップ・ドキュメント作成 | 1 | ✅ |
| **1** | コア・API基盤（フォルダ0） | — | ✅ |
| **2** | 主要機能実装（フォルダ1〜9） | — | ✅ |
| **3** | LVS/車両統合・マルチプレイ対応 | — | 🔧 |
| **4** | 互換性レイヤー（x64/semiofficial切替） | — | 🔧 |
| **5** | ローカライゼーション・デフォルト値整備 | — | 🔧 |
| **6** | HUD整理・カスタムHUD削除 | — | 🔧 |
| **7** | クイックメニュー・キーガイド | — | ⬜ |
| **8** | テスト・ポリッシュ・安定版リリース | — | ⬜ |

---

## 完了済みセッション一覧

### Pre-Template Era（〜2025/07）

194コミットの既存開発。テンプレートシステム導入前のため詳細セッション記録なし。

主な開発経過（Gitログより）:
- 2025/04〜05: LVS/Simfphys車両統合、マルチプレイラグ修正
- 2025/05: LVSバグ修正・ロールバック対応（複数回）
- 2025/07: LVS Server処理再変更、weapon interaction削除

### Template Era（S1〜）

| セッション | 内容 | 成果物 |
|-----------|------|--------|
| S1 | 開発基盤セットアップ | MEMORY.md, PROGRESS.md, CODE_STATUS.md, LESSONS.md, CLAUDE.md拡張 |
| S2 | Melee相対速度修正 | vrmod_melee_global.lua — 手の速度からHMD速度を差し引き、走行中の誤検出を修正 |
| S2.5 | HUD Stack Overflow緊急修正 | vrmod_ui.lua, vrmod_hud.lua, 7/vrmod_left_hud.lua — VRUtilRenderMenuSystem循環参照修正（canonical original pattern導入+再入ガード） |
| S3 | ワークフロー再設計 | MEMORY.md軽量化、BACKLOG.md新設、reference/CONTEXT_*.md作成、CLAUDE.mdセッションルール更新。直線型→ハイブリッド型に移行 |
| S4 | ConVar快適設定プロファイル作成 | reference/CONVAR_BASELINE.md — client.vdf/server.vdfからVRMod関連ConVarを抽出、vrmod_defaults.luaと比較し、座位VR快適設定の設計哲学を考察 |
| S5 | BACKLOG殴り書き・ロードマップ策定 | BACKLOG.md大幅拡充（19セクション40+項目）、開発フェーズ策定（小改善→中規模→再書き出し→大規模の4段階）、NEXT_SESSION.md作成 |
| S6 | バグ修正3件（NEXT_SESSION タスク1-3） | ①vrmod_defaults.lua: lefthandleftfireデフォルト値0→1修正（ConVar不整合解消） ②vrmod_auto_seat_reset.lua: Reset Vehicle Viewを存在しないConCommandからg_VR.menuItems経由に修正（初めて動作するようになった） ③vrmod_holstarsystem.lua/vrmod_left_holstarsystem.lua: 未所持武器のポーチロック問題修正（6箇所に所持チェック追加） |
| S7 | Physgunビーム条件付き可視化（タスク4） | vrmod_pickup_physgun.lua — 3条件すべて満たす時のみビーム表示（①pickup key未押下 ②手が空いている ③拾えるものにヒット）。武器構え中/近接戦闘中の視覚的邪魔を解消。alpha ConVar操作削除、デフォルト値0→100変更、マイグレーションコード追加、VRMod_Exit hookでクリーンアップ追加 |
| S8 | Mirror UI調査・ウィザード形式への計画派生 | タスク5（Mirror UI整理）を調査。重複ボタン（Toggle Mirror 3箇所、Auto Adjust 2箇所）と自動調節ボタンの混乱（Auto Scale/Auto Set）を特定。ユーザーの7年間の経験から「ウィザード形式セットアップ」という理想的UI設計が提案される。大規模すぎるため実装は保留し、将来の大規模タスクとしてBACKLOGに記録。小さく確実に進める方針を再確認 |
| S9 | PDCAワークフロー導入 + 点検実施 | reference/PDCA_WORKFLOW.md新規作成、CLAUDE.md/MEMORY.mdにPDCAセクション追記、.gitignoreにhandoff/+claude_talk_save/追加、CODE_STATUS.md集計修正（93→111）、ファイル数修正（101→107）。**Check: 90点** |
| **S10 (ARC9-1)** | **ARC9統合 Session 1: 詳細解析（完了、再調査含む）** | ARC9のViewModel/UI/介入ポイントを徹底解析。handoff/S1_arc9_viewmodel_analysis.md, S1_arc9_ui_analysis.md, S1_intervention_points.md作成。VRMagシステム動作不良の**真の原因**を特定：ARC9は標準ViewModelとは別に独立したClientSideModel配列（VModel[]）を使用してレンダリング。VRModは標準ViewModelボーンを操作するが、実際に見えるのはVModel[]配列。Phase Bの実装方針を「VModel[]配列内のマガジンモデル操作」に決定。SWEP.DrawCustomModel拡張でマガジンモデルの位置を左手に変更する方式を採用。**Check: 解析完了、Session 2へ** |
| **S11 (ARC9-2)** | **ARC9統合 Session 2: Phase A+B実装（v4テスト→本番コード）** | v1〜v3失敗（PlayerSwitchWeapon不発火、VModel[]にマガジンなし、ManipulateBoneScale毎フレームリセット）→ 根本原因特定: ARC9のDoBodygroups()が毎フレーム全ボーンをリセット（sh_bodygroups.lua:44-47）→ v4 DoBodygroupsラッパー方式で成功 → 本番3ファイル作成: vrmod_arc9_core.lua（武器判定・ConVar）、vrmod_arc9_viewmodel.lua（ViewModel自動更新）、vrmod_arc9_magbone_fix.lua（DoBodygroupsラッパーでmagボーン非表示再適用）。VRテストで動作確認済み: boolean_reload→magボーン非表示→vrmagent装填→magボーン復元。**長年のARC9 VRMag未対応問題を解決** |
| **S12** | **input.IsKeyDown VRエミュレーション（Plan+Do）** | 7年間未解決の「VRコントローラーでinput.IsKeyDown()をトリガーできない」問題に対し、Source Engineの内部アーキテクチャを徹底調査。根本原因: CInputSystem::m_ButtonStateビットフィールドがWM_KEYDOWN経由でのみ更新され、SteamVR入力パスと完全に分離。過去の失敗原因を分析（IN_enum/KEY_enum混在、複雑すぎるロジック）。最小限のLuaデトア方式で再挑戦: `!vrmod_input_emu.lua`を新規作成。追加コードは実質1行（`if vrKeys[key] then return true end`）でエラー不可能な構造。`input.LookupKeyBinding()`でユーザーのキーバインドを動的解決。**VRテスト検証待ち** |

---

## ファイル一覧

CODE_STATUS.md を参照。

---

## 教訓一覧

LESSONS.md を参照。

---

**次のアクション**: ARC9改良（左手追従、空弾倉落下応用）またはBACKLOGから選択
