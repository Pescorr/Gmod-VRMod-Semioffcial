# vrmod_semioffcial_addonplus コードステータス

**最終更新**: 2026-03-01（S9: PDCAワークフロー導入 + S6-S8反映 + 集計修正）

全ファイルの実装ステータス一覧。軽量参照用。

---

## autorun/（6ファイル）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `lua/autorun/vrmodsemioffcial_init.lua` | ✅ | メインエントリーポイント、番号フォルダ順に読込 |
| `lua/autorun/vrmod_dev_excluded_Originalfiles.lua` | ✅ | 開発用ファイル除外システム |
| `lua/autorun/vrmod_lvs_quick_fix.lua` | ✅ | LVS車両クイックフィックス |
| `lua/autorun/vr_card_spawner.lua` | ✅ | カードスポーンシステム |
| `lua/autorun/00_vrmod_compat_init.lua` | ⬜ | x64/semiofficial互換レイヤー（Phase 1 PoC） |
| `lua/autorun/04_vrmod_compat_override.lua` | ⬜ | 互換オーバーライドハンドラ |

## autorun/client/（4ファイル）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `lua/autorun/client/vrmod_debug.lua` | ✅ | デバッグユーティリティ |
| `lua/autorun/client/vrmod_emergencystopper.lua` | ✅ | 緊急停止メカニズム |
| `lua/autorun/client/vrmod_input_tst.lua` | ✅ | 入力テスト |
| `lua/autorun/client/vrmod_presetcreater.lua` | ✅ | プリセット作成UI |

## フォルダ0: コア・API（6ファイル）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `lua/vrmodunoffcial/0/vrmod_api.lua` | ✅ | メインAPI定義、ヘルパー関数 |
| `lua/vrmodunoffcial/0/vrmod_steamvr_bindings.lua` | ✅ | SteamVRコントローラバインディング |
| `lua/vrmodunoffcial/0/vrmod_sranipal.lua` | ✅ | アイトラッキング（SRANIPAL） |
| `lua/vrmodunoffcial/0/vrmod_vregb_radial.lua` | ✅ | ラジアルメニューシステム |
| `lua/vrmodunoffcial/0/cardboardmod.lua` | ✅ | Cardboard VRサポート |
| `lua/vrmodunoffcial/0/vrmod_credits.lua` | ✅ | クレジット表示 |

## フォルダ1: 自動設定・最適化（9ファイル）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `lua/vrmodunoffcial/1/vrmod_add_optimize.lua` | 🔧 | パフォーマンス最適化（Modified） |
| `lua/vrmodunoffcial/1/vrmod_add_autosettings.lua` | ✅ | 自動設定 |
| `lua/vrmodunoffcial/1/vrmod_add_windowfocus_warning.lua` | ✅ | ウィンドウフォーカス警告 |
| `lua/vrmodunoffcial/1/vrmod_doors.lua` | ✅ | ドアインタラクション |
| `lua/vrmodunoffcial/1/vrmod_fbt_device_checker.lua` | ✅ | FBTデバイス検出 |
| `lua/vrmodunoffcial/1/vrmod_server_mirror_remove.lua` | ✅ | サーバーミラー除去 |
| `lua/vrmodunoffcial/1/vrmod_vreservermenu.lua` | ✅ | VREサーバーメニュー |
| `lua/vrmodunoffcial/1/astw2-vrt.lua` | ✅ | VR固有調整 |
| `lua/vrmodunoffcial/1/vrmod_auto_seat_reset.lua` | 🔧 | S6: Reset Vehicle View修正（g_VR.menuItems経由に変更） |

## フォルダ2: ホルスターシステム Type2（3ファイル）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `lua/vrmodunoffcial/2/vrmod_holstarsystem_type2.lua` | ⬜ | Type2ホルスターロジック（新規） |
| `lua/vrmodunoffcial/2/vrmod_holstermenu_type2.lua` | ⬜ | Type2ホルスターメニュー（新規） |
| `lua/vrmodunoffcial/2/vrmod_tediore.lua` | ⬜ | テディオーレ銃メカニクス（新規） |

## フォルダ3: フォアグリップ（2ファイル）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `lua/vrmodunoffcial/3/vrmod_foregripmode.lua` | ✅ | フォアグリップメカニクス |
| `lua/vrmodunoffcial/3/vrmod_addmenu_grip.lua` | 🔧 | フォアグリップメニュー（Modified） |

## フォルダ4: マグボーンシステム（3ファイル）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `lua/vrmodunoffcial/4/vrmod_magbonesystem.lua` | ✅ | マガジンボーン検出・リロード |
| `lua/vrmodunoffcial/4/vrmod_addmenu04.lua` | 🔧 | マグボーンメニュー（Modified） |
| `lua/vrmodunoffcial/4/vrmod_magtester.lua` | ✅ | マガジンテストユーティリティ |

## フォルダ5: 近接攻撃（2ファイル）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `lua/vrmodunoffcial/5/vrmod_melee_global.lua` | 🔧 | 近接攻撃コア（S2: 相対速度に変更済み、トレース方向修正は次回） |
| `lua/vrmodunoffcial/5/vrmod_unoff_menu_melee.lua` | 🔧 | 近接攻撃メニュー（Modified） |

## フォルダ6: ホルスターシステム Type1（5ファイル）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `lua/vrmodunoffcial/6/vrmod_holstarsystem.lua` | 🔧 | S6: 未所持武器ポーチロック修正（右手3箇所に所持チェック追加） |
| `lua/vrmodunoffcial/6/vrmod_left_holstarsystem.lua` | 🔧 | S6: 未所持武器ポーチロック修正（左手3箇所に所持チェック追加） |
| `lua/vrmodunoffcial/6/vrmod_holstermenu_1.lua` | ⬜ | Type1メニュー右（新規） |
| `lua/vrmodunoffcial/6/vrmod_left_holstermenu.lua` | ⬜ | Type1メニュー左（新規） |
| `lua/vrmodunoffcial/6/vrmod_tediore.lua` | ⬜ | テディオーレ（新規） |

## フォルダ7: VR Hand HUD（4ファイル、フォルダ9から移動）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `lua/vrmodunoffcial/7/vrmod_left_hud.lua` | 🔧 | 手のHUD描画・VRUtilRenderMenuSystemラップ（S2.5: 再入ガード追加） |
| `lua/vrmodunoffcial/7/vrmod_autohudctrl.lua` | ⬜ | HUD自動制御（新規、未安定化） |
| `lua/vrmodunoffcial/7/vrmod_hand_hud_menu.lua` | ⬜ | Hand HUDメニューUI（新規、未安定化） |
| `lua/vrmodunoffcial/7/vrmod_hud_crosshair.lua` | ⬜ | VRクロスヘアHUD（新規、未安定化） |

## フォルダ8: 物理・フィジックスガン（2ファイル）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `lua/vrmodunoffcial/8/vrmod_pickup_physgun.lua` | 🔧 | S7: 条件付きビーム可視化実装（3条件すべて満たす時のみ表示） |
| `lua/vrmodunoffcial/8/vrmod_addmenuphys.lua` | 🔧 | 物理ガンメニュー（Modified） |

## フォルダ9: VRピックアップ（4ファイル + 4削除済み）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `lua/vrmodunoffcial/9/vrmod_test_beam_pickup.lua` | ✅ | ビームベースピックアップ |
| `lua/vrmodunoffcial/9/vrmod_test_pickup_entspawn.lua` | ✅ | スポーンベースピックアップ |
| `lua/vrmodunoffcial/9/vrmod_test_pickup_entteleport.lua` | ✅ | テレポートベースピックアップ |
| `lua/vrmodunoffcial/9/vrmod_addmenu_vrpickup.lua` | 🔧 | VRピックアップメニュー（Modified） |
| `lua/vrmodunoffcial/9/vrmod_autohudctrl.lua` | 🚫 | フォルダ7に移動 |
| `lua/vrmodunoffcial/9/vrmod_hand_hud_menu.lua` | 🚫 | フォルダ7に移動 |
| `lua/vrmodunoffcial/9/vrmod_hud_crosshair.lua` | 🚫 | フォルダ7に移動 |
| `lua/vrmodunoffcial/9/vrmod_left_hud.lua` | 🚫 | フォルダ7に移動 |

## ルートファイル: vrmodunoffcial/（50ファイル + 2無効化）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `lua/vrmodunoffcial/vrmod.lua` | ✅ | メインモジュール初期化 |
| `lua/vrmodunoffcial/vrmod_addcvar.lua` | 🔧 | ConVar定義（Modified） |
| `lua/vrmodunoffcial/vrmod_unoff_addmenu.lua` | 🔧 | メインメニュー追加（Modified） |
| `lua/vrmodunoffcial/vrmod_ui_heightadjust.lua` | 🔧 | 身長調整UI（Modified） |
| `lua/vrmodunoffcial/vrmod_defaults.lua` | 🔧 | S6: lefthandleftfireデフォルト値0→1修正 |
| `lua/vrmodunoffcial/vrmod_localization.lua` | ⬜ | 多言語対応（新規） |
| `lua/vrmodunoffcial/vrmod_quickmenu_config.lua` | ⬜ | クイックメニュー設定（新規） |
| `lua/vrmodunoffcial/vrmod_quickmenu_editor.lua` | ⬜ | クイックメニューエディタ（新規） |
| `lua/vrmodunoffcial/vrmod_keyguide_definitions.luadisable` | ⬜ | キーガイド定義（無効化中） |
| `lua/vrmodunoffcial/vrmod_keyguide_hud.luadisable` | ⬜ | キーガイドHUD（無効化中） |
| `lua/vrmodunoffcial/vrmod_actioneditor.lua` | ✅ | SteamVRアクションエディタ |
| `lua/vrmodunoffcial/vrmod_add_key.lua` | ✅ | キーバインドユーティリティ |
| `lua/vrmodunoffcial/vrmod_add_keyboard.lua` | ✅ | キーボード・コントローラサポート |
| `lua/vrmodunoffcial/vrmod_add_presetmenu.lua` | ✅ | プリセットメニュー |
| `lua/vrmodunoffcial/vrmod_character.lua` | ✅ | キャラクターアニメーション・IK |
| `lua/vrmodunoffcial/vrmod_character_fbt.lua` | ✅ | フルボディトラッキング |
| `lua/vrmodunoffcial/vrmod_character_hands.lua` | ✅ | ハンドモデルシステム |
| `lua/vrmodunoffcial/vrmod_dermapopups.lua` | ✅ | DERMAポップアップ |
| `lua/vrmodunoffcial/vrmod_flashlight.lua` | ✅ | フラッシュライト |
| `lua/vrmodunoffcial/vrmod_glide02.lua` | ✅ | Glide入力v2 |
| `lua/vrmodunoffcial/vrmod_glideinput.lua` | ✅ | Glide入力 |
| `lua/vrmodunoffcial/vrmod_glide_extended_input.lua` | ✅ | Glide拡張入力 |
| `lua/vrmodunoffcial/vrmod_glide_server_handlers.lua` | ✅ | Glideサーバーハンドラ |
| `lua/vrmodunoffcial/glide_server_handlers.lua` | ✅ | サーバーハンドラ |
| `lua/vrmodunoffcial/vrmod_halos.lua` | ✅ | グロー/ハロー効果 |
| `lua/vrmodunoffcial/vrmod_hud.lua` | 🔧 | HUDシステム（S2.5: canonical original参照に変更） |
| `lua/vrmodunoffcial/vrmod_input.lua` | ✅ | 入力ハンドリング |
| `lua/vrmodunoffcial/vrmod_locomotion_1_righthand.lua` | ✅ | 右手移動 |
| `lua/vrmodunoffcial/vrmod_locomotion_2_lefthand.lua` | ✅ | 左手移動 |
| `lua/vrmodunoffcial/vrmod_locomotion_3_hmd.lua` | ✅ | HMD移動 |
| `lua/vrmodunoffcial/vrmod_locomotion_6_legacy.lua` | ✅ | レガシー移動 |
| `lua/vrmodunoffcial/vrmod_lvs_beta.lua` | ✅ | LVS車両統合 |
| `lua/vrmodunoffcial/vrmod_lvs_inputbeta.lua` | ✅ | LVS入力ベータ |
| `lua/vrmodunoffcial/vrmod_lvs_inputspecial.lua` | ✅ | LVS特殊入力 |
| `lua/vrmodunoffcial/vrmod_lvs_input_single.lua` | ✅ | LVSシングル入力 |
| `lua/vrmodunoffcial/vrmod_lvsspecial.lua` | ✅ | LVS特殊処理 |
| `lua/vrmodunoffcial/vrmod_mapbrowser.lua` | ✅ | マップブラウザ |
| `lua/vrmodunoffcial/vrmod_menu.lua` | ✅ | メニューフレームワーク |
| `lua/vrmodunoffcial/vrmod_network.lua` | ✅ | ネットワーク同期 |
| `lua/vrmodunoffcial/vrmod_pickup.lua` | ✅ | ジェネリックピックアップ |
| `lua/vrmodunoffcial/vrmod_pickup_arcvr.lua` | ✅ | ArcVRピックアップ |
| `lua/vrmodunoffcial/vrmod_pmchange.lua` | ✅ | プレイヤーモデル変更 |
| `lua/vrmodunoffcial/vrmod_seated.lua` | ✅ | シートモード |
| `lua/vrmodunoffcial/vrmod_simfphysremix.lua` | ✅ | SimfPhys車両 |
| `lua/vrmodunoffcial/vrmod_spawnmenu_contextmenu.lua` | ✅ | スポーン/コンテキストメニュー |
| `lua/vrmodunoffcial/vrmod_ui.lua` | 🔧 | UIフレームワーク（S2.5: _origVRUtilRenderMenuSystem保存追加） |
| `lua/vrmodunoffcial/vrmod_ui_chat.lua` | ✅ | チャットUI |
| `lua/vrmodunoffcial/vrmod_ui_dummymenu.lua` | ✅ | ダミーメニュー（テスト） |
| `lua/vrmodunoffcial/vrmod_ui_quickmenu.lua` | ✅ | クイックメニューUI |
| `lua/vrmodunoffcial/vrmod_ui_weaponselect.lua` | ✅ | 武器選択UI |
| `lua/vrmodunoffcial/vrmod_viewmodelinfo.lua` | ✅ | ビューモデル情報 |
| `lua/vrmodunoffcial/vrmod_worldtips.lua` | ✅ | ワールドスペースツールチップ |

## エンティティ（4ファイル）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `lua/entities/vrmod_pickup/shared.lua` | ✅ | ピックアップエンティティ定義 |
| `lua/entities/vrmod_pickup/init.lua` | ✅ | ピックアップサーバー初期化 |
| `lua/entities/vrmod_pickup/cl_init.lua` | ✅ | ピックアップクライアント初期化 |
| `lua/entities/vrmod_magent/shared.lua` | ✅ | マガジンエンティティ |

## 武器（1ファイル）

| ファイル | ステータス | 備考 |
|---------|-----------|------|
| `lua/weapons/weapon_vrmod_empty.lua` | ✅ | 空武器プレースホルダー |

---

## 集計

| カテゴリ | ファイル数 |
|---------|-----------|
| ✅ 完成（変更不要） | 73 |
| 🔧 要修正/修正済み | 18 |
| ⬜ 未着手（新規/無効化） | 16 |
| 🚫 削除済み（移動） | 4 |
| **合計** | **111**（実ファイル107 + 移動元4） |
