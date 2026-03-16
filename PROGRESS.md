# vrmod_semioffcial_addonplus 進捗管理

**最終更新**: 2026-03-15（S18: Settings02 DTree実装）

---

## 現在地点

- **オープンベータ** — 既存機能の安定化・改善フェーズ
- **実装量**: 123ファイル（Lua 120 + 無効化2 + 移動元4） / 約17,850行
- **Gitコミット**: 194件+
- **次のアクション**: Settings02 DTreeのVRテスト検証、スポーンメニュータブVRテスト検証、x64 Mode VRテスト検証、input.IsKeyDownエミュレーション検証

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
| S1 | 開発基盤セットアップ | PROGRESS.md, CODE_STATUS.md, LESSONS.md等のドキュメント整備 |
| S2 | Melee相対速度修正 | vrmod_melee_global.lua — 手の速度からHMD速度を差し引き、走行中の誤検出を修正 |
| S2.5 | HUD Stack Overflow緊急修正 | vrmod_ui.lua, vrmod_hud.lua, 7/vrmod_left_hud.lua — VRUtilRenderMenuSystem循環参照修正（canonical original pattern導入+再入ガード） |
| S3 | ワークフロー再設計 | BACKLOG.md新設、reference/CONTEXT_*.md作成、ワークフロールール更新。直線型→ハイブリッド型に移行 |
| S4 | ConVar快適設定プロファイル作成 | reference/CONVAR_BASELINE.md — client.vdf/server.vdfからVRMod関連ConVarを抽出、vrmod_defaults.luaと比較し、座位VR快適設定の設計哲学を考察 |
| S5 | BACKLOG殴り書き・ロードマップ策定 | BACKLOG.md大幅拡充（19セクション40+項目）、開発フェーズ策定（小改善→中規模→再書き出し→大規模の4段階）、NEXT_SESSION.md作成 |
| S6 | バグ修正3件（NEXT_SESSION タスク1-3） | ①vrmod_defaults.lua: lefthandleftfireデフォルト値0→1修正（ConVar不整合解消） ②vrmod_auto_seat_reset.lua: Reset Vehicle Viewを存在しないConCommandからg_VR.menuItems経由に修正（初めて動作するようになった） ③vrmod_holstarsystem.lua/vrmod_left_holstarsystem.lua: 未所持武器のポーチロック問題修正（6箇所に所持チェック追加） |
| S7 | Physgunビーム条件付き可視化（タスク4） | vrmod_pickup_physgun.lua — 3条件すべて満たす時のみビーム表示（①pickup key未押下 ②手が空いている ③拾えるものにヒット）。武器構え中/近接戦闘中の視覚的邪魔を解消。alpha ConVar操作削除、デフォルト値0→100変更、マイグレーションコード追加、VRMod_Exit hookでクリーンアップ追加 |
| S8 | Mirror UI調査・ウィザード形式への計画派生 | タスク5（Mirror UI整理）を調査。重複ボタン（Toggle Mirror 3箇所、Auto Adjust 2箇所）と自動調節ボタンの混乱（Auto Scale/Auto Set）を特定。ユーザーの7年間の経験から「ウィザード形式セットアップ」という理想的UI設計が提案される。大規模すぎるため実装は保留し、将来の大規模タスクとしてBACKLOGに記録。小さく確実に進める方針を再確認 |
| S9 | PDCAワークフロー導入 + 点検実施 | reference/PDCA_WORKFLOW.md新規作成、PDCAセクション追記、.gitignore更新、CODE_STATUS.md集計修正（93→111）、ファイル数修正（101→107）。**Check: 90点** |
| **S10 (ARC9-1)** | **ARC9統合 Session 1: 詳細解析（完了、再調査含む）** | ARC9のViewModel/UI/介入ポイントを徹底解析。handoff/S1_arc9_viewmodel_analysis.md, S1_arc9_ui_analysis.md, S1_intervention_points.md作成。VRMagシステム動作不良の**真の原因**を特定：ARC9は標準ViewModelとは別に独立したClientSideModel配列（VModel[]）を使用してレンダリング。VRModは標準ViewModelボーンを操作するが、実際に見えるのはVModel[]配列。Phase Bの実装方針を「VModel[]配列内のマガジンモデル操作」に決定。SWEP.DrawCustomModel拡張でマガジンモデルの位置を左手に変更する方式を採用。**Check: 解析完了、Session 2へ** |
| **S11 (ARC9-2)** | **ARC9統合 Session 2: Phase A+B実装（v4テスト→本番コード）** | v1〜v3失敗（PlayerSwitchWeapon不発火、VModel[]にマガジンなし、ManipulateBoneScale毎フレームリセット）→ 根本原因特定: ARC9のDoBodygroups()が毎フレーム全ボーンをリセット（sh_bodygroups.lua:44-47）→ v4 DoBodygroupsラッパー方式で成功 → 本番3ファイル作成: vrmod_arc9_core.lua（武器判定・ConVar）、vrmod_arc9_viewmodel.lua（ViewModel自動更新）、vrmod_arc9_magbone_fix.lua（DoBodygroupsラッパーでmagボーン非表示再適用）。VRテストで動作確認済み: boolean_reload→magボーン非表示→vrmagent装填→magボーン復元。**長年のARC9 VRMag未対応問題を解決** |
| **S12** | **input.IsKeyDown VRエミュレーション（Plan+Do）** | 7年間未解決の「VRコントローラーでinput.IsKeyDown()をトリガーできない」問題に対し、Source Engineの内部アーキテクチャを徹底調査。根本原因: CInputSystem::m_ButtonStateビットフィールドがWM_KEYDOWN経由でのみ更新され、SteamVR入力パスと完全に分離。過去の失敗原因を分析（IN_enum/KEY_enum混在、複雑すぎるロジック）。最小限のLuaデトア方式で再挑戦: `!vrmod_input_emu.lua`を新規作成。追加コードは実質1行（`if vrKeys[key] then return true end`）でエラー不可能な構造。`input.LookupKeyBinding()`でユーザーのキーバインドを動的解決。**VRテスト検証待ち** |
| **S13** | **x64 Mode全機能実装（Plan+Do）** | x64 VRModの全10機能+コアを`lua/vrmodUnoffcial/64/`に11ファイル・3,441行で完全再現。**目的**: x64ユーザー奪還・上位互換アドオン化。**アーキテクチャ**: 全ConVarデフォルトOFF（マスター+個別）、`vrmod.x64mode.*`名前空間、`x64mode_*`フックID、`vrmod_x64mode_*`ネット文字列で既存コードと完全分離。**実装モジュール**: ①Core（登録API+メニュータブ） ②Math（8ユーティリティ関数） ③Melee Sounds（8タイプ×31サウンド+素材別デカール） ④Manual Pickup（自動拾得防止） ⑤Weapon Replacer（50+武器ペア自動置換） ⑥Drop Weapon（グリップ離し投擲） ⑦NPC2Rag（NPC→ラグドール+ダメージ転送+Zippy Gore互換） ⑧Numpad（VRテンキー+Keypadタッチ操作） ⑨Hand Cube（物理ハンドShadowController+動的衝突形状） ⑩Glide（6車両タイプ+GetBoneMatrixフォールバック） ⑪Climbing（23+HL2マップラダーデータ、SP限定）。**既存ファイル編集ゼロ**。20 ConVar、43フック、8ネット文字列。**VRテスト検証待ち** |
| **S14** | **整合性ポリシー策定 + actflag修正 + 安全改善ゾーン特定 + Pickupバグ修正** | **整合性ポリシー策定**: 4階層（ネットワーク→フックAPI→ConVar名→同時インストール）を定義、`reference/COMPATIBILITY_POLICY.md`作成。**安全改善ゾーン特定**: 全25共有ルートファイル差分比較、信号機方式で安全判定、`reference/SAFE_IMPROVEMENT_ZONES.md`作成。**actflag修正**: vrmod_pickup_physgun.luaのlocal actflagをクロージャスコープに移動。**Pickupバグ再評価→修正**: ConVar名typo(`vrmod_dev_` vs `vrmod_test_`)でTickフック自動ドロップが完全に死んでいた問題を発見。Tickフックをオリジナル同等に復元（autodrop ConVar制御付き）。VRMod_Exitハンドラも正しいdrop()呼び出しに修正。**ホルスターdupe格納回帰バグ修正**: GMod hook.Callのpairs()非決定的実行順序により、vrmod.Pickup()がheldEntityを消去した後にstoreWeapon()が読む競合状態を発見。Thinkフックフレーム先行キャッシュで解決（vrmod_holstarsystem_type2.lua）
| **S16** | **Settings02 DTree化+ハイブリッドタブ+サイズ修正** | ①Phase 1a: Settings02内のDPropertySheet 5段ネスト→DHorizontalDivider+DTree+コンテンツ切替システムに全面書き換え(1334行)。隠しDPropertySheet方式でモジュール後方互換性完全維持（変更ファイル: vrmod_unoff_addmenu.luaのみ）。②Phase 1b: ユーザーフィードバック反映→ハイブリッド方式に改修。Settings02をDPropertySheet L2に変更し、VRplay/Server/Preset/debugを上タブ、第2階層以下をDTree左サイドバーに配置。CreateTreeTabヘルパー関数で重複削減。③Phase 1c: メニューサイズ550x600→700x680に拡大（コンテンツ領域40%増）。④スポーンメニュータブ設計: spawnmenu.AddToolTab APIによるネイティブ統合の設計書作成（次セッション実装予定）。**教訓**: L29(ハイブリッドタブ+DTree最適解), L30(スポーンメニューAPI並行運用) |
| **S17** | **スポーンメニュータブ実装** | `vrmod_spawnmenu_tab.lua`新規作成（148行）。`spawnmenu.AddToolTab("VRMod")`+`PopulateToolMenu`の2フックパターンでGMod標準Qメニューに「VRMod」タブを追加。CPanel APIで8カテゴリ（General/Input/UI&HUD/Pickup&Weapons/Graphics/Network/Melee/Utility）を1行1設定で記述。既存VRModメニューとの並行運用設計。既存ファイル編集ゼロ。`VRModResetCategory()`/`VRModResetAll()`を再利用。**VRテスト検証待ち** |
| **S18** | **Settings02 DTree実装（ロールバック状態から直接実装）** | 前セッションの`git checkout`事故によりS15メニュー再構成がロールバック。この状況を逆手に取り、クリーンなオリジナル状態に直接DTreeサイドバーを実装。`vrmod_unoff_addmenu.lua`を1120行→1325行に書き換え。**アーキテクチャ**: Settings02をDPanel化、DHorizontalDivider+DTree(左170px)+コンテンツパネル(右)。16パネルをフラットリストでDTreeノード化（カテゴリ分けなし、オリジナルタブ順序維持）。隠しDPropertySheet方式で7モジュール互換性維持（VRplaySheet/pickupSheet/nonVRGunSheet/hudSheet/debugSheet/quickmenuBtnSheet/Settings02Sheet）。timer.Simple(0)で全hook完了後にモジュールタブをDTree末尾に自動抽出。ヘルパー関数3個（CreateTreeTab/AddTreeNode/ExtractSheet）+既存2個修正（CreateUtilityPanel/CreateCardboardPanel）。**変更ファイル**: vrmod_unoff_addmenu.luaのみ。**VRテスト検証待ち** |
| **S15** | **VRModメニュー大規模再構成（v2→v3）** | **3セッション横断プロジェクト（計画→実装→テスト→v3再構成）**。Webベースのドラッグ&ドロップメニュー再構成ツール(`tools/menu_reorganizer/`)を開発・活用。**v2実装（前セッション）**: `vrmod_unoff_addmenu.lua`を全面書き換え、Settings02内にネスト階層（VRplay>input/UI/Character/pickup/non-VRGun/Vehicle/Graphics）を構築。8モジュールファイルのhook名リネーム・ターゲット変更。**v3再構成（本セッション）**: ユーザーのゲーム内テスト後のフィードバックを反映。①HUDをDScrollPanel→DPropertySheetに変換しframe.hudSheet公開 ②gameplay/Misc削除 ③VRStop KeyをSettings02からVRplayに移動 ④Vehicle簡素化 ⑤debug内にTest wrapper追加（vehiclemode+テストハンドル+Reset Vehicle統合）⑥タブ順序変更（VRplay→Server→Preset→debug）⑦x64 Modeをルートレベルに移動 ⑧VRHandHUDsをUI>HUD配下に移動 ⑨VRHolsterをpickup配下に移動 ⑩VRDebug無効化。**hook.Removeパターン発見**: hookリネーム時、旧hook名がメモリに残る問題→hook.Remove()で明示削除が必要。**UX課題浮上**: DPropertySheet 4段ネストでタブバーが画面上部を占有→根本的デザイン見直しの必要性をユーザーが認識 |

---

## ファイル一覧

（各フォルダ内のLuaファイルを参照）

---

## 教訓一覧

（セッション記録内に記載）

---

**次のアクション**: スポーンメニュータブVRテスト検証、BACKLOG緑ゾーンからの選択的バグ修正、x64 Mode VRテスト、ARC9改良、input.IsKeyDownエミュレーション検証もペンディング
