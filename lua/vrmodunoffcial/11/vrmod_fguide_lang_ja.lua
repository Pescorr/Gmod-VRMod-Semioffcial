-- VRMod Feature Guide - Japanese Language Strings
-- 日本語文字列

AddCSLuaFile()
if SERVER then return end

VRMOD_FGUIDE_LANG = VRMOD_FGUIDE_LANG or {}
VRMOD_FGUIDE_LANG.ja = {

-- ============================================================
-- UI Chrome
-- ============================================================
window_title = "VR機能ガイド",
lang_label = "言語:",
topbar_subtitle = "複数の機能を組み合わせて最高のVR体験を",
btn_open_main_menu = "メインVRModメニューを開く",
btn_open_settings = "設定を開く (Settings02)",
status_modes = "モード",
status_lang_en = "英語",
status_lang_ja = "日本語",
status_lang_ru = "ロシア語",
status_lang_zh = "中国語",

-- ============================================================
-- Sidebar
-- ============================================================
sidebar_welcome = "概要",
sidebar_group_toggle = "ワンクリック切替",
sidebar_group_wizard = "セットアップ手順",
sidebar_group_troubleshoot = "トラブルシュート",

-- ============================================================
-- Welcome Page
-- ============================================================
welcome_title = "VR機能ガイド",
welcome_desc = "このアドオンには多くの機能があり、組み合わせることでさらに便利になります。\nこのガイドでは、よくあるプレイスタイルを数クリックで設定する方法を紹介します。\n\n左のサイドバーからモードを選んで始めましょう。",
welcome_section_toggle = "ワンクリック切替",
welcome_toggle_desc = "1回クリックするだけで複数の設定を一括変更するモードです。\n配信者モード、着席プレイ、左利きモード。",
welcome_section_wizard = "セットアップ手順",
welcome_wizard_desc = "上から順にボタンを押していくだけのステップバイステップガイドです。\n身長調整、フルボディトラッキング設定、パフォーマンス最適化。",
welcome_section_troubleshoot = "トラブルシュート",
welcome_troubleshoot_desc = "問題が発生していますか？いくつかの質問に答えると解決策が見つかります。\n移動、表示、クラッシュ、操作、パフォーマンスの問題に対応。",
vr_status_title = "VRステータス",
vr_status_active = "VRは有効です",
vr_status_inactive = "VRは無効です。メインVRModメニューからVRを開始してください（コンソール: vrmod）",

-- ============================================================
-- Mode: Streamer
-- ============================================================
mode_streamer_title = "配信者モード",
mode_streamer_desc = "VRゲームプレイの配信・録画用です。\nカメラオーバーライドを無効にして、視聴者に通常の三人称視点を表示します（VRの歪んだ映像ではなく）。",
mode_streamer_tip = "あなたはVRでプレイしながら、視聴者には通常のゲーム画面が表示されます。配信に最適！",
mode_streamer_cvar_info = "ConVar: vrmod_cameraoverride",
mode_streamer_btn_on = "配信者モードを有効にする",
mode_streamer_btn_off = "配信者モードを無効にする",
mode_streamer_status_on = "有効 - 視聴者に通常画面を表示中",
mode_streamer_status_off = "無効 - 視聴者にVR画面を表示中",

-- ============================================================
-- Mode: Seated
-- ============================================================
mode_seated_title = "着席プレイ",
mode_seated_desc = "座った状態でVRをプレイします。\n高さオフセットを追加して、座っていてもキャラクターが通常の高さで立つようにします。",
mode_seated_tip = "有効にした後、自動調整コマンドで着席時の高さを設定できます。",
mode_seated_cvar_info = "ConVar: vrmod_seated",
mode_seated_btn_on = "着席モードを有効にする",
mode_seated_btn_off = "着席モードを無効にする",
mode_seated_status_on = "有効 - 着席時の高さオフセット適用中",
mode_seated_status_off = "無効 - 立位プレイ",
mode_seated_auto_adjust = "有効にすると、着席時の高さが自動調整されます。",

-- ============================================================
-- Mode: Left-Handed
-- ============================================================
mode_lefthand_title = "左利きモード",
mode_lefthand_desc = "利き手を左に切り替えます。\n左コントローラーが射撃やインタラクションのメインハンドになります。",
mode_lefthand_tip = "武器操作、トリガー、すべてのインタラクションが左手に切り替わります。",
mode_lefthand_cvar_info = "ConVar: vrmod_LeftHand",
mode_lefthand_btn_on = "左利きモードを有効にする",
mode_lefthand_btn_off = "左利きモードを無効にする",
mode_lefthand_status_on = "有効 - 左手がメインハンド",
mode_lefthand_status_off = "無効 - 右手がメインハンド",

-- ============================================================
-- Wizard: Height & Appearance
-- ============================================================
mode_height_title = "身長と外見",
mode_height_desc = "VRの体を実際の身長と体格に合わせて調整します。\n上から順にステップを進めてください。",
mode_height_step1_title = "自動調整",
mode_height_step1_desc = "キャラクターの身長を自動で調整します。\nまっすぐ立ってからボタンを押してください。",
mode_height_step1_btn = "自動調整",
mode_height_step2_title = "ミラーを有効化",
mode_height_step2_desc = "VRミラーを有効にしてキャラクターの見た目を確認します。\n自動調整の結果を確認するのに使いましょう。",
mode_height_step2_btn = "ミラーを有効化",
mode_height_step3_title = "目の高さを微調整",
mode_height_step3_desc = "自動調整が完璧でない場合、手動で目の高さを調整してください。\nコンソールで: vrmod_characterEyeHeight <値>（デフォルト: 66.8）\n大きい値 = 背が高くなる、小さい値 = 背が低くなる。",
mode_height_step4_title = "頭モデルを非表示",
mode_height_step4_desc = "キャラクターの髪や頭が視界をふさいでいる場合、これをトグルして非表示にできます。",
mode_height_step4_btn = "頭の表示を切替",

-- ============================================================
-- Wizard: FBT Setup
-- ============================================================
mode_fbt_title = "フルボディトラッキング",
mode_fbt_desc = "Viveトラッカーなどのデバイスでフルボディトラッキングを設定します。\nステップに従ってトラッカーを構成してください。",
mode_fbt_step1_title = "トラッカーの状態を確認",
mode_fbt_step1_desc = "接続されているVRデバイスとトラッカー情報をコンソールに出力します。\nトラッカーがオンになっていて、SteamVRで認識されていることを確認してください。",
mode_fbt_step1_btn = "デバイスを確認",
mode_fbt_step2_title = "トラッカーロールの設定",
mode_fbt_step2_desc = "SteamVR設定 > コントローラー > トラッカーの管理で:\n各トラッカーに役割を割り当てます（左足、右足、腰）。\nこのステップはSteamVRで行います。Garry's Modではありません。",
mode_fbt_step3_title = "VRModを再起動",
mode_fbt_step3_desc = "トラッカー構成を検出するためにVRModの再起動が必要です。\nVRが一時的に停止して再起動します。",
mode_fbt_step3_btn = "VRを再起動",
mode_fbt_step4_title = "キャリブレーション",
mode_fbt_step4_desc = "Tポーズ（両腕を真横に伸ばす）をとり、数秒間じっとしてください。\nシステムがトラッカーの位置をキャラクターの体に合わせます。",

-- ============================================================
-- Wizard: Performance
-- ============================================================
mode_performance_title = "パフォーマンス",
mode_performance_desc = "Garry's ModのVRパフォーマンスを最適化します。\nステップに従って一般的な最適化を適用してください。",
mode_performance_step1_title = "マルチコアレンダリングを有効化",
mode_performance_step1_desc = "マルチスレッドレンダリングを有効にしてCPU利用効率を改善します。\nVRで最も効果的な最適化の一つです。",
mode_performance_step1_btn = "適用",
mode_performance_step2_title = "レンダリング解像度を下げる",
mode_performance_step2_desc = "VRレンダーターゲットの解像度を0.8倍に下げます。\nわずかな画質低下と引き換えに、GPU負荷を大幅に軽減します。",
mode_performance_step2_btn = "適用 (0.8x)",
mode_performance_step3_title = "追加の最適化",
mode_performance_step3_desc = "Source Engineの追加最適化を適用します。\n大きなマップのレンダリング改善のためマップ範囲制限を拡大します。",
mode_performance_step3_btn = "適用",
mode_performance_step4_title = "結果を確認",
mode_performance_step4_desc = "コンソールで cl_showfps 1 と入力してFPSを確認してください。\nVRでは快適なプレイにヘッドセットのリフレッシュレートの約2倍が必要です。\nまだ遅い場合は、アドオン数を減らすか小さいマップを試してください。",

-- ============================================================
-- Mode: Troubleshoot
-- ============================================================
mode_troubleshoot_title = "トラブルシュート",
mode_troubleshoot_desc = "質問に答えて問題の解決策を見つけましょう。\n選択肢をクリックして進むか、「戻る」ボタンで前の質問に戻れます。",
ts_btn_back = "戻る",
ts_btn_start_over = "最初からやり直す",
ts_solution_title = "解決策",

-- Troubleshoot: Root
ts_root_question = "どのような問題が発生していますか？",
ts_cant_move = "動けない",
ts_display = "表示の問題",
ts_crash = "クラッシュ / エラー",
ts_controls = "操作が効かない",
ts_perf = "パフォーマンスが悪い",

-- Troubleshoot: Can't Move
ts_cant_move_question = "コンソール（~）またはメインメニューは開いていますか？",
ts_yes = "はい",
ts_no = "いいえ",
ts_cant_move_close = "~キーでコンソールを閉じるか、ESCでメインメニューを閉じてください。これらが開いている間は移動できません。",
ts_cant_move_2_question = "特殊なゲームモード（Helix、DarkRPなど）をプレイしていますか？",
ts_no_sandbox = "いいえ / Sandbox",
ts_cant_move_gamemode = "一部のゲームモード（特にHelix）はVR移動を制限します。ノークリップ（Vキー）を試してください。それで動けるなら、ゲームモード側の制限です。",
ts_cant_move_3_question = "手は動かせるが歩けない状態ですか？",
ts_hands_ok = "はい - 手は動くが歩けない",
ts_nothing = "いいえ - 何も動かない",
ts_cant_move_stick = "SteamVRのコントローラーバインドを確認してください。SteamVR設定 > コントローラー > コントローラーバインドの管理 > VRModを選択。サムスティック/トラックパッドが移動に割り当てられていることを確認してください。",
ts_cant_move_frozen = "試してください: 1) コンソールで vrmod_stop → vrmod_start。2) まだ動かない場合、VRMod以外のすべてのアドオンを無効にして再試行。3) SteamVR Homeでヘッドセットが正しくトラッキングされているか確認。",

-- Troubleshoot: Display
ts_display_question = "何が見えていますか？",
ts_gray_eye = "片目がグレー",
ts_flicker = "画面がちらつく",
ts_borders = "黒い枠が見える",
ts_head = "頭/髪が見える",
ts_wobble = "視界が伸びる/ゆらぐ",
ts_display_gray = "アドオンの競合が最も一般的な原因です。すべてのアドオンを無効にしてVRModだけでテストしてください。正常なら、アドオンを一つずつ再有効にして原因を特定します。ReShadeは既知の原因です。",
ts_display_flicker_question = "SteamVRのデスクトップゲームシアターは無効にしていますか？",
ts_dont_know = "わからない / いいえ",
ts_yes_disabled = "はい、無効にしている",
ts_display_flicker_fix = "Steamライブラリ > Garry's Modを右クリック > プロパティ > 一般 > 「SteamVRがアクティブな間デスクトップゲームシアターを使用する」のチェックを外す。また起動オプションに -window を追加。",
ts_display_flicker_2 = "SteamVR設定でモーションスムージングを無効にしてみてください（ビデオ > モーションスムージング > OFF）。また、アドオンの競合を確認するためすべて無効にしてテスト。",
ts_display_borders = "視界の周りの黒い枠はQuest 3のFOV差による既知の問題です。SteamVRのレンダリング解像度を調整してみてください（設定 > ビデオ > レンダリング解像度）。これはVRMod上流の制限です。",
ts_display_head_question = "設定で「頭を非表示」を有効にしていますか？",
ts_yes_still_visible = "はい、でもまだ見える",
ts_display_head_fix = "VRModメニュー > キャラクター > vrmod_hide_head を有効にしてください。頭のボーンをVR視点からオフセットします。",
ts_display_head_adjust = "vrmod_hide_head_pos_y（前後オフセット）を調整してください。デフォルトは20。30-40に増やしてみてください。鏡で結果を確認。",
ts_display_wobble = "SteamVRでモーションスムージングを無効にしてください。Steamインストールフォルダ > config > steamvr.vrsettingsを見つけて、モーションスムージングをfalseに設定。視界のゆらぎの最も一般的な原因です。",

-- Troubleshoot: Crash
ts_crash_question = "クラッシュはいつ発生しますか？",
ts_on_start = "VR開始時（vrmod_start）",
ts_gameplay = "プレイ中",
ts_error_msg = "コンソールにエラーメッセージ",
ts_crash_start_question = "起動オプションに -dxlevel 95 を設定していますか？",
ts_crash_dxlevel = "GModの起動オプションに -dxlevel 95 を追加してください（Steam > GMod > プロパティ > 起動オプション）。一度ゲームを起動したら -dxlevel 95 を削除（一度だけ実行すればOK）。またデスクトップゲームシアターも無効にしてください。",
ts_crash_start_2 = "試してください: 1) Steamでファイルの整合性を確認。2) SteamVRを再インストール。3) VRMod以外のすべてのアドオンを無効に。4) 起動オプションに -window -novid を試す。",
ts_crash_gameplay = "アドオンの競合の可能性が高いです。VRModだけで安定するかテスト。安定するなら、アドオンを一つずつ追加。レンダリング/HUD/プレイヤーモデル系のアドオンが競合しやすいです。",
ts_crash_error_question = "どのようなエラーが表示されていますか？",
ts_module = "モジュールが未インストール",
ts_manifest = "SetActionManifestPath failed",
ts_version = "モジュールバージョンが不明",
ts_other = "その他 / 読めない",
ts_crash_module = "catse.net/vrmodからVRModモジュールをダウンロードして、DLLを garrysmod/lua/bin/ に配置してください。ウイルス対策がブロックする場合は例外を追加。semiofficial アドオンは「オリジナル」「semiofficial」両方のモジュールで動作します。",
ts_crash_manifest = "SteamVR側の問題です。SteamVRを完全に終了 > PCを再起動 > 必要ならSteamVRを再インストール。すべてのVRModバージョンで発生します。",
ts_crash_version = "モジュールバージョンの不一致です。catse.net/vrmodから最新モジュールを再ダウンロードしてください。garrysmod/lua/bin/にvrmod DLLが1つだけあることを確認。",
ts_crash_other = "コンソールで完全なエラーメッセージを確認してください。一般的な修正: 1) GModファイルを検証。2) SteamVRを再インストール。3) ReShadeがあれば削除。4) 他のアドオンなしで試す。エラーが続く場合は、完全なエラーテキストと共に報告してください。",

-- Troubleshoot: Controls
ts_controls_question = "具体的に何が動きませんか？",
ts_grab = "物をつかめない / 拾えない",
ts_use = "Useキーが効かない",
ts_trigger = "トリガーが発射しない",
ts_vehicle = "車両の操作",
ts_controls_grab = "手をもっとオブジェクトに近づけてください。つかみ範囲は vrmod_pickup_range で設定（デフォルト: 1.1）。設定で増やせます。また vrmod_manualpickups が有効か確認。",
ts_controls_use = "Oculus/Metaコントローラーの場合：トリガーを完全に押す必要があります（半押しではなく）。SteamVRバインドで「Use」アクションがトリガーに割り当てられているか確認。",
ts_controls_trigger = "VRModのSteamVRコントローラーバインドを確認してください。SteamVR設定 > コントローラー > バインドの管理 > VRMod。必要ならデフォルトバインドにリセット。",
ts_controls_vehicle_question = "車両に乗れますか？",
ts_cant_enter = "車両に乗れない",
ts_cant_drive = "乗れるが運転できない",
ts_cant_shoot = "車両から撃てない",
ts_vehicle_enter = "車両に近づいてUseキー（トリガーを完全に押す）を押してください。一部の車両アドオン（SimFPhys）では、ドア部分を見る必要がある場合があります。",
ts_vehicle_drive = "SteamVRバインドの「In Vehicle」カテゴリを確認。ステアリングとスロットルが割り当てられている必要があります。また vrmod_lvs_input_mode 0（レガシー）または 1（ネットワーク）で入力モードを切り替えてみてください。",
ts_vehicle_shoot = "SteamVRバインドで「In Vehicle」>「turret_primary_fire」がトリガーに割り当てられているか確認。LVS車両では武器選択のバインドも必要な場合があります。",

-- Troubleshoot: Performance
ts_perf_question = "VRなしのデスクトップFPSはいくつですか？（cl_showfps 1 で確認）",
ts_low = "200 FPS未満",
ts_med = "200-400 FPS",
ts_high = "400 FPS以上",
ts_perf_low = "ベースFPSがVRには低すぎます。アドオン数を減らし、小さいマップを使い、GModのグラフィック設定を下げてください。VRはFPSがおよそ半分になります（2回レンダリングするため）。このガイドのパフォーマンスウィザードで素早く最適化できます。",
ts_perf_med = "以下の最適化を試してください: 1) gmod_mcore_test 1（マルチコア）。2) mat_queue_mode -1（自動）。3) vrmod_rtWidth_Multiplier を1.6に下げる。4) 不要なアドオンを無効に。このガイドのパフォーマンスウィザードでワンクリック適用できます。",
ts_perf_high = "ベースFPSは良好です。VRがまだ遅い場合: 1) SteamVRのレンダリング解像度を下げる（設定 > ビデオ）。2) モーションスムージングを無効に。3) 特定のアドオン競合を確認。4) 小さいマップで問題を切り分け。",

}

print("[VRMod] Feature Guide JA language loaded")
