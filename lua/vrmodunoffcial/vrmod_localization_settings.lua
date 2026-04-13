-- VRMod Semi-Official - Settings Registry Localization Extension
-- Extends VRMOD_LANG tables defined in vrmod_localization.lua
-- Keys are English label text from vrmod_settings02_registry.lua and vrmod_spawnmenu_tab.lua

if SERVER then return end
if not VRMOD_LANG then return end

local function AddSettings(lang, entries)
    if not VRMOD_LANG[lang] then return end
    for k, v in pairs(entries) do
        VRMOD_LANG[lang][k] = v
    end
end

-- ============================================================================
-- Japanese / 日本語
-- ============================================================================
AddSettings("ja", {
    -- ==============================
    -- Category labels
    -- ==============================
    ["Character"] = "キャラクター",
    ["UI"] = "UI設定",
    ["Optimize"] = "最適化",
    ["Quick Menu"] = "クイックメニュー",
    ["VRStop Key"] = "VR停止キー",
    ["Misc"] = "その他",
    ["Animation"] = "アニメーション",
    ["Network(Server)"] = "ネットワーク(サーバー)",
    ["Commands"] = "コマンド",
    ["Vehicle"] = "車両",
    ["Magazine"] = "マガジン",
    ["Utility"] = "ユーティリティ",
    ["Cardboard"] = "段ボールVR",
    ["C++ Module"] = "C++モジュール",
    ["Key Mapping"] = "キーマッピング",
    ["Modules"] = "モジュール管理",

    -- ==============================
    -- VR category items
    -- ==============================
    ["Jumpkey Auto Duck"] = "ジャンプキー自動しゃがみ",
    ["Teleport Enable"] = "テレポート有効化",
    ["Teleport Hand (0=Left 1=Right 2=Head)"] = "テレポート基準 (0=左 1=右 2=頭)",
    ["Flashlight Attachment (0=R 1=L 2=HMD)"] = "ライト取り付け位置 (0=右 1=左 2=HMD)",
    ["Toggle Laser Pointer"] = "レーザーポインター切替",
    ["Weapon Viewmodel Setting"] = "武器ビューモデル設定",
    ["Weapon Bone Config"] = "武器ボーン設定",
    ["Pickup Weight (Server)"] = "ピックアップ重量 (サーバー)",
    ["Pickup Range (Server)"] = "ピックアップ範囲 (サーバー)",
    ["Pickup Limit (Server)"] = "ピックアップ制限 (サーバー)",
    ["Manual Pickup"] = "手動ピックアップ",
    ["Restore Default Settings"] = "デフォルト設定に戻す",

    -- ==============================
    -- Character category items
    -- ==============================
    ["Character Scale"] = "キャラクタースケール",
    ["Character Eye Height"] = "キャラクター目線の高さ",
    ["Crouch Threshold"] = "しゃがみ閾値",
    ["Head to HMD Distance"] = "頭とHMDの距離",
    ["Z Near"] = "Z近接値",
    ["Seated Mode"] = "座席モード",
    ["Seated Offset"] = "座席オフセット",
    ["Alternative Character Yaw"] = "キャラクター回転 変更",
    ["Character Animation Enable"] = "アニメーション有効化",
    ["Hide Head"] = "頭を非表示",
    ["Idle Animation"] = "待機アニメーション",
    ["Walk Animation"] = "歩行アニメーション",
    ["Run Animation"] = "走行アニメーション",
    ["Jump Animation"] = "ジャンプアニメーション",
    ["Left Hand"] = "左手モード",
    ["Left Hand Fire"] = "左手モード+左手トリガー射撃",
    ["Left Hand Hold Mode"] = "左手ホールドモード",
    ["Apply VR Settings (Requires VRMod Restart)"] = "VR設定を適用 (VRMod再起動が必要)",
    ["Auto Adjust VR Settings"] = "VR設定を自動調整",

    -- Section/help: Character
    ["Head Hide Settings"] = "頭非表示設定",
    ["Animations"] = "アニメーション",
    ["Left Hand (WIP)"] = "左手 (開発中)",

    -- ==============================
    -- UI category items
    -- ==============================
    ["HUD Enable"] = "HUD有効化",
    ["HUD Curve"] = "HUDカーブ",
    ["HUD Distance"] = "HUD距離",
    ["HUD Scale"] = "HUDスケール",
    ["HUD Alpha"] = "HUD透明度",
    ["HUD Only While Pressing Menu Key"] = "メニューキー押下中のみHUD表示",
    ["Quickmenu Attach Position"] = "クイックメニュー取り付け位置",
    ["Weapon Menu Attach Position"] = "武器メニュー取り付け位置",
    ["Popup Window Attach Position"] = "ポップアップウィンドウ取り付け位置",
    ["Menu & UI Red Outline"] = "メニュー&UI赤枠表示",
    ["UI Render Alternative"] = "UI代替レンダリング",
    ["Desktop 3rd Person Camera"] = "デスクトップ三人称カメラ",
    ["Keyboard UI Chat Key"] = "キーボードUIチャットキー",
    ["VRE Attach Left Hands"] = "VRE左手に取り付け",
    ["Show VR UI on Desktop Window"] = "デスクトップウィンドウにVR UIを表示",
    ["Toggle VR Keyboard"] = "VRキーボード切替",
    ["Open Action Editor"] = "アクションエディタを開く",
    ["VR UI Height"] = "VR UI高さ",
    ["VR UI Width"] = "VR UI幅",
    ["VR HUD Height"] = "VR HUD高さ",
    ["VR HUD Width"] = "VR HUD幅",
    ["Always Auto-Detect Resolution on VR Start"] = "VR開始時に常に解像度を自動検出",

    -- Section: UI
    ["Screen Resolution"] = "画面解像度",

    -- ==============================
    -- Optimize category items
    -- ==============================
    ["Skybox Enable (Client)"] = "スカイボックス有効 (クライアント)",
    ["Shadows & Flashlights Effect Enable (Client)"] = "影とライト効果を有効化 (クライアント)",
    ["Visible Range of Map"] = "マップの表示範囲",
    ["VRMod Optimization Level (0-4)"] = "VRMod最適化レベル (0-4)",
    ["Apply Optimization Now"] = "今すぐ最適化を適用",
    ["Remove All Reflective Glass"] = "全ての反射ガラスを除去",
    ["Reset Render Targets"] = "レンダーターゲットをリセット",
    ["Update Render Targets"] = "レンダーターゲットを更新",
    ["Apply Quest 2 + Virtual Desktop Preset"] = "Quest 2 + Virtual Desktopプリセットを適用",
    ["Reset RT Multipliers to Default"] = "RT倍率をデフォルトに戻す",

    -- Section: Optimize
    ["Mirror & Reflection"] = "鏡と反射",
    ["Render Target"] = "レンダーターゲット",

    -- Help: Optimize
    ["0:None 1:No changes 2:Reset 3:VR safe 4:Max(flash warn)"] = "0:なし 1:変更なし 2:リセット 3:最適化 4:超最適化(!点滅注意!))",

    -- ==============================
    -- Opt.VR category items
    -- ==============================
    ["Water Reflections"] = "水面反射",
    ["Water Refractions"] = "水面屈折",
    ["Force Expensive Water"] = "高品質水面を強制",
    ["Force Water Reflect Entities"] = "水面のエンティティ反射を強制",
    ["VR Mirror Optimization"] = "VRミラー最適化",
    ["Reflective Glass Toggle"] = "反射ガラス切替",
    ["Disable Mirrors"] = "鏡を無効化",
    ["Multi-core Rendering"] = "マルチコアレンダリング",
    ["Multicore Rendering Mode"] = "マルチコアレンダリングモード",

    -- Help: Opt.VR / Opt.Gmod
    ["Changes apply immediately in spawn menu."] = "変更はスポーンメニューで即座に適用されます。",

    -- ==============================
    -- Opt.Gmod category items
    -- ==============================
    ["Max Shadows Rendered"] = "最大シャドウ描画数",
    ["Flashlight Shadow Resolution"] = "フラッシュライトシャドウ解像度",
    ["Texture Quality (lower=better)"] = "テクスチャ品質 (低い=高品質)",
    ["Level of Detail"] = "詳細レベル",
    ["Root Level of Detail"] = "ルート詳細レベル",
    ["AI Expression Frequency"] = "AI表情更新頻度",
    ["Detail Distance"] = "ディテール表示距離",
    ["Fast Specular"] = "反射高速描写",
    ["Water Overlay Size"] = "水面オーバーレイサイズ",
    ["Draw Detail Props"] = "物品ディテール描画",
    ["Specular Reflections"] = "テクスチャ反射",

    -- ==============================
    -- Quick Menu category items
    -- ==============================
    ["Map Browser"] = "マップブラウザ",
    ["VR Exit"] = "VR EXIT",
    ["UI Reset"] = "UI RESET",
    ["VRE GBRadial & Add Menu"] = "VRE GBRadial & addMenu",
    ["Chat"] = "チャット",
    ["Keyboard"] = "Keyboard",
    ["Toggle Mirror"] = "Toggle Mirror",
    ["Spawn Menu"] = "スポーンメニュー",
    ["No Clip"] = "No Clip",
    ["Context Menu"] = "コンテキストメニュー",
    ["ArcCW Customize"] = "ArcCWカスタマイズ",
    ["Toggle Vehicle Mode"] = "運転できない時に押す",

    -- ==============================
    -- VRStop Key category items
    -- ==============================
    ["Hold Time (Seconds)"] = "長押し時間 (秒)",
    ["FPS Guard Enable"] = "FPSガード有効化",
    ["FPS Drop Threshold (ms)"] = "FPS低下閾値 (ms)",
    ["Retry Count"] = "リトライ回数",
    ["Emergency FPS Enable"] = "緊急FPS停止有効化",
    ["FPS Threshold"] = "FPS閾値",
    ["Duration (Seconds)"] = "持続時間 (秒)",

    -- Section: VRStop Key
    ["FPS Guard"] = "FPSガード",
    ["Emergency FPS Stop"] = "緊急FPS停止",

    -- Help: VRStop Key
    ["Emergency Stop key must be set in VRMod Menu (key binder)."] = "緊急停止キーはVRModメニュー(キーバインダー)で設定してください。",
    ["Automatically stops VR when frame time exceeds threshold."] = "フレーム時間が閾値を超えるとVRを自動停止します。",
    ["Stops VR if FPS stays below threshold for the specified duration."] = "FPSが指定時間内に閾値を下回り続けるとVRを停止します。",

    -- ==============================
    -- Misc category items
    -- ==============================
    ["VRMod Menu Show on Startup"] = "起動時にVRModメニューを表示",
    ["Error Check Method"] = "エラーチェック方法",
    ["ModuleError VRMod Menu Lock"] = "モジュールエラー時VRModメニューロック",
    ["Player Model Change (forPAC3)"] = "プレイヤーモデル変更 (PAC3用)",
    ["VR Disable Pickup (Client)"] = "VRピックアップ無効化 (クライアント)",
    ["Enable LVS Pickup Handle"] = "LVSピックアップハンドル有効化",
    ["VRMod Menu Type"] = "VRModメニュータイプ",
    ["Use Custom QuickMenu"] = "カスタムクイックメニューを使用",
    ["Auto Seat Reset"] = "シート自動リセット",
    ["Sight Bodypart"] = "サイト用ボディパーツ",
    ["Developer Mode (requires restart)"] = "開発者モード (再起動が必要)",
    ["Restore Misc Defaults"] = "その他設定をデフォルトに戻す",

    -- ==============================
    -- Animation category items
    -- ==============================
    ["Reset to Default"] = "デフォルトにリセット",

    -- Help: Animation
    ["Enter animation names (e.g., ACT_HL2MP_IDLE)"] = "アニメーション名を入力 (例: ACT_HL2MP_IDLE)",

    -- ==============================
    -- Graphics02 category items
    -- ==============================
    ["Automatic Resolution Set"] = "解像度自動設定",
    ["Quest 2 / Virtual Desktop Preset"] = "Quest 2 / Virtual Desktopプリセット",

    -- ==============================
    -- Network(Server) category items
    -- ==============================
    ["Allow VR Teleport (Server)"] = "VRテレポートを許可 (サーバー)",

    -- ==============================
    -- Commands category items
    -- ==============================
    ["Toggle Door Collision Debug"] = "ドア当たり判定デバッグ切替",
    ["Toggle Playspace Debug"] = "プレイスペースデバッグ切替",
    ["Toggle Network Debug"] = "ネットワークデバッグ切替",
    ["Print VR Devices Info"] = "VRデバイス情報を表示",
    ["Start Cardboard VR"] = "段ボールVR開始",
    ["Exit Cardboard VR"] = "段ボールVR終了",
    ["Toggle Radial Menu"] = "ラジアルメニュー切替",
    ["Toggle Server Menu"] = "サーバーメニュー切替",

    -- Section: Commands
    ["Debug Visualization"] = "デバッグ表示",
    ["Device Information"] = "デバイス情報",
    ["Cardboard VR"] = "段ボールVR",
    ["VRE Integration"] = "VRE統合",

    -- ==============================
    -- Vehicle category items
    -- ==============================
    ["Main Mode (On-Foot)"] = "メインモード (徒歩)",
    ["Driving Mode (Vehicle)"] = "運転モード (車両)",
    ["Both Modes (Main+Driving)"] = "両方のモード (メイン+運転)",
    ["Auto Mode (Restore)"] = "自動モード (復元)",
    ["LVS Networked Mode"] = "LVSネットワークモード",
    ["Reset Vehicle Settings"] = "車両設定をリセット",

    -- ==============================
    -- Magazine category items
    -- ==============================
    ["Enable VR Magazine System"] = "VRマガジンシステム有効化",
    ["Enable Magazine Pouch"] = "マガジンポーチ有効化",
    ["VR Magazine bone or bonegroup"] = "VRマガジンボーン/ボーングループ",
    ["Magazine Enter Sound"] = "マガジン挿入音",
    ["Magazine Enter Range"] = "マガジン挿入範囲",
    ["Magazine Enter Model"] = "マガジン挿入モデル",
    ["[WIP] WeaponModel Mag Grab/Eject"] = "[開発中] 武器モデルマグ掴み/排出",
    ["Angle Pitch"] = "角度ピッチ",
    ["Angle Yaw"] = "角度ヨー",
    ["Angle Roll"] = "角度ロール",
    ["Magazine Bone Names"] = "マガジンボーン名",
    ["Pouch Location"] = "ポーチの位置",
    ["Pouch Distance"] = "ポーチの距離",
    ["Infinite Pouch (any distance)"] = "無限ポーチ (距離無制限)",
    ["Sync to ArcVR ConVars"] = "ArcVR ConVarと同期",
    ["Enable ARC9 VR Integration"] = "ARC9 VR統合を有効化",
    ["Enable ARC9 Magazine Bone Fix"] = "ARC9マガジンボーン修正を有効化",
    ["ARC9 Mag Bone: Follow Left Hand / Hide Only"] = "ARC9マグボーン: 左手追従 / 非表示のみ",

    -- Section: Magazine
    ["Magazine Position"] = "マガジン位置",
    ["Pouch Position (shared with ArcVR)"] = "ポーチ位置 (ArcVRと共有)",
    ["ARC9 Weapon Settings"] = "ARC9武器設定",

    -- Help: Magazine
    ["Magazine Pouch: reach left hand to body pouch + Pickup to spawn vrmagent."] = "マガジンポーチ: 左手をボディポーチに伸ばす + ピックアップでvrmagentを生成。",

    -- ==============================
    -- Utility category items
    -- ==============================
    ["Auto-Detect Screen Resolution"] = "画面解像度を自動検出",
    ["Reset VGUI Panels"] = "VGUIパネルをリセット",
    ["Generate VR Config Data"] = "VR設定データを生成",
    ["Auto-generate on VR startup"] = "VR起動時に自動生成",
    ["Start VR"] = "VR開始",
    ["Exit VR"] = "VR終了",
    ["Reset All Settings"] = "全設定をリセット",
    ["Print VR Info"] = "VR情報を表示",
    ["Reset Lua Modules"] = "Luaモジュールをリセット",

    -- Section: Utility
    ["Screen & VGUI"] = "画面 & VGUI",
    ["VR Config Data Generation"] = "VR設定データ生成",
    ["Core VR Control"] = "VRコア操作",

    -- ==============================
    -- Cardboard category items
    -- ==============================
    ["Cardboard Scale"] = "段ボールVRスケール",
    ["Cardboard Sensitivity"] = "段ボールVR感度",

    -- Help: Cardboard
    ["Cardboard VR mode (phone sensor emulation)"] = "段ボールVRモード (スマホセンサーエミュレーション)",

    -- ==============================
    -- C++ Module category items
    -- ==============================
    ["Input Mode"] = "入力モード",
    ["Module Error: Lock VRMod Menu"] = "モジュールエラー: VRModメニューロック",
    ["Re-extract Module Files"] = "モジュールファイルを再展開",
    ["Open Keybinding Editor"] = "キーバインドエディタを開く",
    ["Open Module Folder Guide"] = "モジュールフォルダガイドを開く",
    ["Print Module Diagnostics"] = "モジュール診断情報を表示",

    -- Section: C++ Module
    ["Settings"] = "設定",
    ["Actions"] = "アクション",
    ["Troubleshooting"] = "トラブルシューティング",

    -- Help: C++ Module
    ["If module is not working: 1) Go to garrysmod/data/vrmod_module/ 2) Rename install.txt -> install.bat 3) Run install.bat, restart Gmod 4) Add GarrysMod folder to AV exclusions if blocked"] = "モジュールが動作しない場合: 1) garrysmod/data/vrmod_module/ に移動 2) install.txt を install.bat にリネーム 3) install.bat を実行し、Gmodを再起動 4) ブロックされた場合はGarrysMod フォルダをウイルス対策の除外リストに追加",

    -- ==============================
    -- Key Mapping category items
    -- ==============================
    ["Enable Input Emulation"] = "入力エミュレーション有効化",
    ["Enable C++ Engine Injection"] = "C++エンジンインジェクション有効化",
    ["Open Visual Keyboard Editor"] = "ビジュアルキーボードエディタを開く",
    ["Print Current Mapping"] = "現在のマッピングを表示",

    -- Section: Key Mapping
    ["Key Assignment"] = "キー割り当て",
    ["Debug"] = "デバッグ",

    -- Help: Key Mapping
    ["Click a keyboard key, then press a VR controller button to assign."] = "キーボードのキーをクリックし、VRコントローラーのボタンを押して割り当て。",

    -- ==============================
    -- Modules category items
    -- ==============================
    ["Addon-Only Mode (skip root files)"] = "アドオン専用モード (ルートファイルをスキップ)",
    ["Legacy Mode (load only core features)"] = "レガシーモード (コア機能のみ読み込み)",
    ["[2] Holster Type2"] = "[2] ホルスター タイプ2",
    ["[3] Foregrip"] = "[3] フォアグリップ",
    ["[4] Magbone/ARC9"] = "[4] マグボーン/ARC9",
    ["[5] Melee"] = "[5] 近接戦闘",
    ["[6] Holster Type1"] = "[6] ホルスター タイプ1",
    ["[7] VR Hand HUD"] = "[7] VRハンドHUD",
    ["[8] Physgun"] = "[8] 物理ガン",
    ["[9] VR Pickup"] = "[9] VRピックアップ",
    ["[10] Debug"] = "[10] デバッグ",
    ["[11] (Reserved)"] = "[11] (予約済み)",
    ["[12] Guide"] = "[12] ガイド",
    ["[13] RealMech"] = "[13] RealMech",
    ["[14] Throw"] = "[14] 投げる",

    -- Section: Modules
    ["Addon-Only Mode"] = "アドオン専用モード",
    ["Legacy Mode"] = "レガシーモード",
    ["Feature Modules"] = "機能モジュール",

    -- Help: Modules
    ["Changes require Gmod restart to take effect."] = "変更を反映するにはGmodの再起動が必要です。",

    -- ==============================
    -- Combo option labels
    -- ==============================
    ["Right Hand"] = "右手",
    ["Pelvis (Hip)"] = "骨盤 (ヒップ)",
    ["Head"] = "頭",
    ["Spine (Chest)"] = "背骨 (胸)",
    ["SteamVR Bindings (Default)"] = "SteamVRバインド (デフォルト)",
    ["Lua Keybinding"] = "Luaキーバインド",

    -- ==============================
    -- Standalone buttons (spawnmenu_tab.lua)
    -- ==============================
    ["Open VRMod Menu"] = "VRModメニューを開く",
    ["Auto-Detect Resolution"] = "解像度を自動検出",
})

-- ============================================================================
-- Chinese Simplified / 简体中文
-- ============================================================================
AddSettings("zh", {
    -- ==============================
    -- Category labels
    -- ==============================
    ["Character"] = "角色",
    ["UI"] = "UI设置",
    ["Optimize"] = "优化",
    ["Quick Menu"] = "快捷菜单",
    ["VRStop Key"] = "VR停止键",
    ["Misc"] = "杂项",
    ["Animation"] = "动画",
    ["Network(Server)"] = "网络(服务器)",
    ["Commands"] = "命令",
    ["Vehicle"] = "载具",
    ["Magazine"] = "弹匣",
    ["Utility"] = "实用工具",
    ["Cardboard"] = "纸盒VR",
    ["C++ Module"] = "C++模块",
    ["Key Mapping"] = "按键映射",
    ["Modules"] = "模块管理",

    -- ==============================
    -- VR category items
    -- ==============================
    ["Jumpkey Auto Duck"] = "跳跃键自动蹲下",
    ["Teleport Enable"] = "启用传送",
    ["Teleport Hand (0=Left 1=Right 2=Head)"] = "传送手 (0=左 1=右 2=头)",
    ["Flashlight Attachment (0=R 1=L 2=HMD)"] = "手电筒安装位置 (0=右 1=左 2=HMD)",
    ["Toggle Laser Pointer"] = "切换激光指示器",
    ["Weapon Viewmodel Setting"] = "武器视角模型设置",
    ["Weapon Bone Config"] = "武器骨骼配置",
    ["Pickup Weight (Server)"] = "拾取重量 (服务器)",
    ["Pickup Range (Server)"] = "拾取范围 (服务器)",
    ["Pickup Limit (Server)"] = "拾取限制 (服务器)",
    ["Manual Pickup"] = "手动拾取",
    ["Restore Default Settings"] = "恢复默认设置",

    -- ==============================
    -- Character category items
    -- ==============================
    ["Character Scale"] = "角色缩放",
    ["Character Eye Height"] = "角色眼睛高度",
    ["Crouch Threshold"] = "蹲下阈值",
    ["Head to HMD Distance"] = "头部到HMD距离",
    ["Z Near"] = "Z近裁面",
    ["Seated Mode"] = "坐姿模式",
    ["Seated Offset"] = "坐姿偏移量",
    ["Alternative Character Yaw"] = "替代角色偏航",
    ["Character Animation Enable"] = "启用角色动画",
    ["Hide Head"] = "隐藏头部",
    ["Idle Animation"] = "待机动画",
    ["Walk Animation"] = "行走动画",
    ["Run Animation"] = "奔跑动画",
    ["Jump Animation"] = "跳跃动画",
    ["Left Hand"] = "左手",
    ["Left Hand Fire"] = "左手开火",
    ["Left Hand Hold Mode"] = "左手持握模式",
    ["Apply VR Settings (Requires VRMod Restart)"] = "应用VR设置 (需要重启VRMod)",
    ["Auto Adjust VR Settings"] = "自动调整VR设置",

    -- Section/help: Character
    ["Head Hide Settings"] = "头部隐藏设置",
    ["Animations"] = "动画",
    ["Left Hand (WIP)"] = "左手 (开发中)",

    -- ==============================
    -- UI category items
    -- ==============================
    ["HUD Enable"] = "启用HUD",
    ["HUD Curve"] = "HUD曲率",
    ["HUD Distance"] = "HUD距离",
    ["HUD Scale"] = "HUD缩放",
    ["HUD Alpha"] = "HUD透明度",
    ["HUD Only While Pressing Menu Key"] = "仅在按下菜单键时显示HUD",
    ["Quickmenu Attach Position"] = "快捷菜单附着位置",
    ["Weapon Menu Attach Position"] = "武器菜单附着位置",
    ["Popup Window Attach Position"] = "弹窗附着位置",
    ["Menu & UI Red Outline"] = "菜单和UI红色边框",
    ["UI Render Alternative"] = "UI替代渲染",
    ["Desktop 3rd Person Camera"] = "桌面第三人称摄像机",
    ["Keyboard UI Chat Key"] = "键盘UI聊天键",
    ["VRE Attach Left Hands"] = "VRE附着到左手",
    ["Show VR UI on Desktop Window"] = "在桌面窗口显示VR UI",
    ["Toggle VR Keyboard"] = "切换VR键盘",
    ["Open Action Editor"] = "打开动作编辑器",
    ["VR UI Height"] = "VR UI高度",
    ["VR UI Width"] = "VR UI宽度",
    ["VR HUD Height"] = "VR HUD高度",
    ["VR HUD Width"] = "VR HUD宽度",
    ["Always Auto-Detect Resolution on VR Start"] = "VR启动时始终自动检测分辨率",

    -- Section: UI
    ["Screen Resolution"] = "屏幕分辨率",

    -- ==============================
    -- Optimize category items
    -- ==============================
    ["Skybox Enable (Client)"] = "启用天空盒 (客户端)",
    ["Shadows & Flashlights Effect Enable (Client)"] = "启用阴影和灯光效果 (客户端)",
    ["Visible Range of Map"] = "地图可视范围",
    ["VRMod Optimization Level (0-4)"] = "VRMod优化等级 (0-4)",
    ["Apply Optimization Now"] = "立即应用优化",
    ["Remove All Reflective Glass"] = "移除所有反光玻璃",
    ["Reset Render Targets"] = "重置渲染目标",
    ["Update Render Targets"] = "更新渲染目标",
    ["Apply Quest 2 + Virtual Desktop Preset"] = "应用Quest 2 + Virtual Desktop预设",
    ["Reset RT Multipliers to Default"] = "将RT倍率恢复为默认值",

    -- Section: Optimize
    ["Mirror & Reflection"] = "镜面与反射",
    ["Render Target"] = "渲染目标",

    -- Help: Optimize
    ["0:None 1:No changes 2:Reset 3:VR safe 4:Max(flash warn)"] = "0:无 1:不变 2:重置 3:VR安全 4:最大(闪屏警告)",

    -- ==============================
    -- Opt.VR category items
    -- ==============================
    ["Water Reflections"] = "水面反射",
    ["Water Refractions"] = "水面折射",
    ["Force Expensive Water"] = "强制高质量水面",
    ["Force Water Reflect Entities"] = "强制水面反射实体",
    ["VR Mirror Optimization"] = "VR镜像优化",
    ["Reflective Glass Toggle"] = "反光玻璃开关",
    ["Disable Mirrors"] = "禁用镜像",
    ["Multi-core Rendering"] = "多核渲染",
    ["Multicore Rendering Mode"] = "多核渲染模式",

    -- Help: Opt.VR / Opt.Gmod
    ["Changes apply immediately in spawn menu."] = "更改会在载入菜单中立即生效。",

    -- ==============================
    -- Opt.Gmod category items
    -- ==============================
    ["Max Shadows Rendered"] = "最大阴影渲染数",
    ["Flashlight Shadow Resolution"] = "手电筒阴影分辨率",
    ["Texture Quality (lower=better)"] = "纹理质量 (数值越低=越好)",
    ["Level of Detail"] = "细节等级",
    ["Root Level of Detail"] = "根细节等级",
    ["AI Expression Frequency"] = "AI表情更新频率",
    ["Detail Distance"] = "细节显示距离",
    ["Fast Specular"] = "快速镜面反射",
    ["Water Overlay Size"] = "水面覆盖层大小",
    ["Draw Detail Props"] = "绘制细节模型",
    ["Specular Reflections"] = "镜面反射",

    -- ==============================
    -- Quick Menu category items
    -- ==============================
    ["Map Browser"] = "地图浏览器",
    ["VR Exit"] = "退出VR",
    ["UI Reset"] = "重置UI",
    ["VRE GBRadial & Add Menu"] = "VRE GBRadial和附加菜单",
    ["Chat"] = "聊天",
    ["Keyboard"] = "键盘",
    ["Toggle Mirror"] = "切换镜像",
    ["Spawn Menu"] = "道具菜单",
    ["No Clip"] = "穿墙飞行",
    ["Context Menu"] = "上下文菜单",
    ["ArcCW Customize"] = "ArcCW自定义",
    ["Toggle Vehicle Mode"] = "切换载具模式",

    -- ==============================
    -- VRStop Key category items
    -- ==============================
    ["Hold Time (Seconds)"] = "按住时间 (秒)",
    ["FPS Guard Enable"] = "启用FPS保护",
    ["FPS Drop Threshold (ms)"] = "FPS下降阈值 (ms)",
    ["Retry Count"] = "重试次数",
    ["Emergency FPS Enable"] = "启用紧急FPS停止",
    ["FPS Threshold"] = "FPS阈值",
    ["Duration (Seconds)"] = "持续时间 (秒)",

    -- Section: VRStop Key
    ["FPS Guard"] = "FPS保护",
    ["Emergency FPS Stop"] = "紧急FPS停止",

    -- Help: VRStop Key
    ["Emergency Stop key must be set in VRMod Menu (key binder)."] = "紧急停止键必须在VRMod菜单(按键绑定器)中设置。",
    ["Automatically stops VR when frame time exceeds threshold."] = "当帧时间超过阈值时自动停止VR。",
    ["Stops VR if FPS stays below threshold for the specified duration."] = "如果FPS在指定时间内持续低于阈值则停止VR。",

    -- ==============================
    -- Misc category items
    -- ==============================
    ["VRMod Menu Show on Startup"] = "启动时显示VRMod菜单",
    ["Error Check Method"] = "错误检查方式",
    ["ModuleError VRMod Menu Lock"] = "模块错误时锁定VRMod菜单",
    ["Player Model Change (forPAC3)"] = "玩家模型更改 (用于PAC3)",
    ["VR Disable Pickup (Client)"] = "禁用VR拾取 (客户端)",
    ["Enable LVS Pickup Handle"] = "启用LVS拾取手柄",
    ["VRMod Menu Type"] = "VRMod菜单类型",
    ["Use Custom QuickMenu"] = "使用自定义快捷菜单",
    ["Auto Seat Reset"] = "自动座位重置",
    ["Sight Bodypart"] = "瞄准身体部位",
    ["Developer Mode (requires restart)"] = "开发者模式 (需要重启)",
    ["Restore Misc Defaults"] = "恢复杂项默认设置",

    -- ==============================
    -- Animation category items
    -- ==============================
    ["Reset to Default"] = "恢复默认",

    -- Help: Animation
    ["Enter animation names (e.g., ACT_HL2MP_IDLE)"] = "输入动画名称 (例如: ACT_HL2MP_IDLE)",

    -- ==============================
    -- Graphics02 category items
    -- ==============================
    ["Automatic Resolution Set"] = "自动设置分辨率",
    ["Quest 2 / Virtual Desktop Preset"] = "Quest 2 / Virtual Desktop预设",

    -- ==============================
    -- Network(Server) category items
    -- ==============================
    ["Allow VR Teleport (Server)"] = "允许VR传送 (服务器)",

    -- ==============================
    -- Commands category items
    -- ==============================
    ["Toggle Door Collision Debug"] = "切换门碰撞调试",
    ["Toggle Playspace Debug"] = "切换游玩空间调试",
    ["Toggle Network Debug"] = "切换网络调试",
    ["Print VR Devices Info"] = "打印VR设备信息",
    ["Start Cardboard VR"] = "启动纸盒VR",
    ["Exit Cardboard VR"] = "退出纸盒VR",
    ["Toggle Radial Menu"] = "切换径向菜单",
    ["Toggle Server Menu"] = "切换服务器菜单",

    -- Section: Commands
    ["Debug Visualization"] = "调试可视化",
    ["Device Information"] = "设备信息",
    ["Cardboard VR"] = "纸盒VR",
    ["VRE Integration"] = "VRE集成",

    -- ==============================
    -- Vehicle category items
    -- ==============================
    ["Main Mode (On-Foot)"] = "主模式 (步行)",
    ["Driving Mode (Vehicle)"] = "驾驶模式 (载具)",
    ["Both Modes (Main+Driving)"] = "双模式 (主+驾驶)",
    ["Auto Mode (Restore)"] = "自动模式 (恢复)",
    ["LVS Networked Mode"] = "LVS联网模式",
    ["Reset Vehicle Settings"] = "重置载具设置",

    -- ==============================
    -- Magazine category items
    -- ==============================
    ["Enable VR Magazine System"] = "启用VR弹匣系统",
    ["Enable Magazine Pouch"] = "启用弹匣弹药袋",
    ["VR Magazine bone or bonegroup"] = "VR弹匣骨骼/骨骼组",
    ["Magazine Enter Sound"] = "弹匣插入音效",
    ["Magazine Enter Range"] = "弹匣插入范围",
    ["Magazine Enter Model"] = "弹匣插入模型",
    ["[WIP] WeaponModel Mag Grab/Eject"] = "[开发中] 武器模型弹匣抓取/弹出",
    ["Angle Pitch"] = "俯仰角",
    ["Angle Yaw"] = "偏航角",
    ["Angle Roll"] = "翻滚角",
    ["Magazine Bone Names"] = "弹匣骨骼名称",
    ["Pouch Location"] = "弹药袋位置",
    ["Pouch Distance"] = "弹药袋距离",
    ["Infinite Pouch (any distance)"] = "无限弹药袋 (任意距离)",
    ["Sync to ArcVR ConVars"] = "同步到ArcVR ConVar",
    ["Enable ARC9 VR Integration"] = "启用ARC9 VR集成",
    ["Enable ARC9 Magazine Bone Fix"] = "启用ARC9弹匣骨骼修复",
    ["ARC9 Mag Bone: Follow Left Hand / Hide Only"] = "ARC9弹匣骨骼: 跟随左手 / 仅隐藏",

    -- Section: Magazine
    ["Magazine Position"] = "弹匣位置",
    ["Pouch Position (shared with ArcVR)"] = "弹药袋位置 (与ArcVR共享)",
    ["ARC9 Weapon Settings"] = "ARC9武器设置",

    -- Help: Magazine
    ["Magazine Pouch: reach left hand to body pouch + Pickup to spawn vrmagent."] = "弹匣弹药袋: 将左手伸向身体弹药袋 + 拾取以生成vrmagent。",

    -- ==============================
    -- Utility category items
    -- ==============================
    ["Auto-Detect Screen Resolution"] = "自动检测屏幕分辨率",
    ["Reset VGUI Panels"] = "重置VGUI面板",
    ["Generate VR Config Data"] = "生成VR配置数据",
    ["Auto-generate on VR startup"] = "VR启动时自动生成",
    ["Start VR"] = "启动VR",
    ["Exit VR"] = "退出VR",
    ["Reset All Settings"] = "重置所有设置",
    ["Print VR Info"] = "打印VR信息",
    ["Reset Lua Modules"] = "重置Lua模块",

    -- Section: Utility
    ["Screen & VGUI"] = "屏幕和VGUI",
    ["VR Config Data Generation"] = "VR配置数据生成",
    ["Core VR Control"] = "核心VR控制",

    -- ==============================
    -- Cardboard category items
    -- ==============================
    ["Cardboard Scale"] = "纸盒VR缩放",
    ["Cardboard Sensitivity"] = "纸盒VR灵敏度",

    -- Help: Cardboard
    ["Cardboard VR mode (phone sensor emulation)"] = "纸盒VR模式 (手机传感器模拟)",

    -- ==============================
    -- C++ Module category items
    -- ==============================
    ["Input Mode"] = "输入模式",
    ["Module Error: Lock VRMod Menu"] = "模块错误: 锁定VRMod菜单",
    ["Re-extract Module Files"] = "重新提取模块文件",
    ["Open Keybinding Editor"] = "打开按键绑定编辑器",
    ["Open Module Folder Guide"] = "打开模块文件夹指南",
    ["Print Module Diagnostics"] = "打印模块诊断信息",

    -- Section: C++ Module
    ["Settings"] = "设置",
    ["Actions"] = "操作",
    ["Troubleshooting"] = "故障排除",

    -- Help: C++ Module
    ["If module is not working: 1) Go to garrysmod/data/vrmod_module/ 2) Rename install.txt -> install.bat 3) Run install.bat, restart Gmod 4) Add GarrysMod folder to AV exclusions if blocked"] = "如果模块不工作: 1) 前往 garrysmod/data/vrmod_module/ 2) 将 install.txt 重命名为 install.bat 3) 运行 install.bat，重启Gmod 4) 如果被拦截，将GarrysMod文件夹添加到杀毒软件排除列表",

    -- ==============================
    -- Key Mapping category items
    -- ==============================
    ["Enable Input Emulation"] = "启用输入模拟",
    ["Enable C++ Engine Injection"] = "启用C++引擎注入",
    ["Open Visual Keyboard Editor"] = "打开可视键盘编辑器",
    ["Print Current Mapping"] = "打印当前映射",

    -- Section: Key Mapping
    ["Key Assignment"] = "按键分配",
    ["Debug"] = "调试",

    -- Help: Key Mapping
    ["Click a keyboard key, then press a VR controller button to assign."] = "点击键盘按键，然后按下VR控制器按钮进行绑定。",

    -- ==============================
    -- Modules category items
    -- ==============================
    ["Addon-Only Mode (skip root files)"] = "仅插件模式 (跳过根文件)",
    ["Legacy Mode (load only core features)"] = "传统模式 (仅加载核心功能)",
    ["[2] Holster Type2"] = "[2] 枪套 类型2",
    ["[3] Foregrip"] = "[3] 前握把",
    ["[4] Magbone/ARC9"] = "[4] 弹匣骨骼/ARC9",
    ["[5] Melee"] = "[5] 近战",
    ["[6] Holster Type1"] = "[6] 枪套 类型1",
    ["[7] VR Hand HUD"] = "[7] VR手部HUD",
    ["[8] Physgun"] = "[8] 物理枪",
    ["[9] VR Pickup"] = "[9] VR拾取",
    ["[10] Debug"] = "[10] 调试",
    ["[11] (Reserved)"] = "[11] (保留)",
    ["[12] Guide"] = "[12] 指南",
    ["[13] RealMech"] = "[13] RealMech",
    ["[14] Throw"] = "[14] 投掷",

    -- Section: Modules
    ["Addon-Only Mode"] = "仅插件模式",
    ["Legacy Mode"] = "传统模式",
    ["Feature Modules"] = "功能模块",

    -- Help: Modules
    ["Changes require Gmod restart to take effect."] = "更改需要重启Gmod才能生效。",

    -- ==============================
    -- Combo option labels
    -- ==============================
    ["Right Hand"] = "右手",
    ["Pelvis (Hip)"] = "骨盆 (臀部)",
    ["Head"] = "头部",
    ["Spine (Chest)"] = "脊柱 (胸部)",
    ["SteamVR Bindings (Default)"] = "SteamVR绑定 (默认)",
    ["Lua Keybinding"] = "Lua按键绑定",

    -- ==============================
    -- Standalone buttons (spawnmenu_tab.lua)
    -- ==============================
    ["Open VRMod Menu"] = "打开VRMod菜单",
    ["Auto-Detect Resolution"] = "自动检测分辨率",
})

-- ============================================================================
-- Russian / Русский
-- ============================================================================
AddSettings("ru", {
    -- ==============================
    -- Category labels
    -- ==============================
    ["Character"] = "Персонаж",
    ["UI"] = "Интерфейс",
    ["Optimize"] = "Оптимизация",
    ["Quick Menu"] = "Быстрое меню",
    ["VRStop Key"] = "Клавиша остановки VR",
    ["Misc"] = "Разное",
    ["Animation"] = "Анимация",
    ["Network(Server)"] = "Сеть (Сервер)",
    ["Commands"] = "Команды",
    ["Vehicle"] = "Транспорт",
    ["Magazine"] = "Магазин",
    ["Utility"] = "Утилиты",
    ["Cardboard"] = "Картонный VR",
    ["C++ Module"] = "Модуль C++",
    ["Key Mapping"] = "Назначение клавиш",
    ["Modules"] = "Управление модулями",

    -- ==============================
    -- VR category items
    -- ==============================
    ["Jumpkey Auto Duck"] = "Авто-присед при прыжке",
    ["Teleport Enable"] = "Включить телепортацию",
    ["Teleport Hand (0=Left 1=Right 2=Head)"] = "Рука телепортации (0=Левая 1=Правая 2=Голова)",
    ["Flashlight Attachment (0=R 1=L 2=HMD)"] = "Крепление фонарика (0=Пр. 1=Лев. 2=HMD)",
    ["Toggle Laser Pointer"] = "Переключить лазерный указатель",
    ["Weapon Viewmodel Setting"] = "Настройка модели оружия",
    ["Weapon Bone Config"] = "Настройка костей оружия",
    ["Pickup Weight (Server)"] = "Вес подбора (Сервер)",
    ["Pickup Range (Server)"] = "Дальность подбора (Сервер)",
    ["Pickup Limit (Server)"] = "Лимит подбора (Сервер)",
    ["Manual Pickup"] = "Ручной подбор",
    ["Restore Default Settings"] = "Восстановить настройки по умолчанию",

    -- ==============================
    -- Character category items
    -- ==============================
    ["Character Scale"] = "Масштаб персонажа",
    ["Character Eye Height"] = "Высота глаз персонажа",
    ["Crouch Threshold"] = "Порог приседания",
    ["Head to HMD Distance"] = "Расстояние от головы до HMD",
    ["Z Near"] = "Ближняя плоскость Z",
    ["Seated Mode"] = "Сидячий режим",
    ["Seated Offset"] = "Смещение сидячего режима",
    ["Alternative Character Yaw"] = "Альтернативный поворот персонажа",
    ["Character Animation Enable"] = "Включить анимацию персонажа",
    ["Hide Head"] = "Скрыть голову",
    ["Idle Animation"] = "Анимация покоя",
    ["Walk Animation"] = "Анимация ходьбы",
    ["Run Animation"] = "Анимация бега",
    ["Jump Animation"] = "Анимация прыжка",
    ["Left Hand"] = "Левая рука",
    ["Left Hand Fire"] = "Стрельба левой рукой",
    ["Left Hand Hold Mode"] = "Режим удержания левой рукой",
    ["Apply VR Settings (Requires VRMod Restart)"] = "Применить настройки VR (требуется перезапуск VRMod)",
    ["Auto Adjust VR Settings"] = "Автонастройка VR",

    -- Section/help: Character
    ["Head Hide Settings"] = "Настройки скрытия головы",
    ["Animations"] = "Анимации",
    ["Left Hand (WIP)"] = "Левая рука (в разработке)",

    -- ==============================
    -- UI category items
    -- ==============================
    ["HUD Enable"] = "Включить HUD",
    ["HUD Curve"] = "Кривизна HUD",
    ["HUD Distance"] = "Расстояние HUD",
    ["HUD Scale"] = "Масштаб HUD",
    ["HUD Alpha"] = "Прозрачность HUD",
    ["HUD Only While Pressing Menu Key"] = "HUD только при нажатии клавиши меню",
    ["Quickmenu Attach Position"] = "Позиция крепления быстрого меню",
    ["Weapon Menu Attach Position"] = "Позиция крепления меню оружия",
    ["Popup Window Attach Position"] = "Позиция крепления всплывающего окна",
    ["Menu & UI Red Outline"] = "Красная обводка меню и UI",
    ["UI Render Alternative"] = "Альтернативный рендеринг UI",
    ["Desktop 3rd Person Camera"] = "Камера от третьего лица на рабочем столе",
    ["Keyboard UI Chat Key"] = "Клавиша чата UI клавиатуры",
    ["VRE Attach Left Hands"] = "VRE крепление к левой руке",
    ["Show VR UI on Desktop Window"] = "Показать VR UI на рабочем столе",
    ["Toggle VR Keyboard"] = "Переключить VR-клавиатуру",
    ["Open Action Editor"] = "Открыть редактор действий",
    ["VR UI Height"] = "Высота VR UI",
    ["VR UI Width"] = "Ширина VR UI",
    ["VR HUD Height"] = "Высота VR HUD",
    ["VR HUD Width"] = "Ширина VR HUD",
    ["Always Auto-Detect Resolution on VR Start"] = "Всегда определять разрешение при запуске VR",

    -- Section: UI
    ["Screen Resolution"] = "Разрешение экрана",

    -- ==============================
    -- Optimize category items
    -- ==============================
    ["Skybox Enable (Client)"] = "Включить скайбокс (Клиент)",
    ["Shadows & Flashlights Effect Enable (Client)"] = "Включить тени и эффекты фонарика (Клиент)",
    ["Visible Range of Map"] = "Видимый диапазон карты",
    ["VRMod Optimization Level (0-4)"] = "Уровень оптимизации VRMod (0-4)",
    ["Apply Optimization Now"] = "Применить оптимизацию сейчас",
    ["Remove All Reflective Glass"] = "Удалить все отражающие стёкла",
    ["Reset Render Targets"] = "Сбросить цели рендеринга",
    ["Update Render Targets"] = "Обновить цели рендеринга",
    ["Apply Quest 2 + Virtual Desktop Preset"] = "Применить пресет Quest 2 + Virtual Desktop",
    ["Reset RT Multipliers to Default"] = "Сбросить множители RT по умолчанию",

    -- Section: Optimize
    ["Mirror & Reflection"] = "Зеркала и отражения",
    ["Render Target"] = "Цели рендеринга",

    -- Help: Optimize
    ["0:None 1:No changes 2:Reset 3:VR safe 4:Max(flash warn)"] = "0:Нет 1:Без изменений 2:Сброс 3:VR безопасный 4:Макс.(предупр. о вспышках)",

    -- ==============================
    -- Opt.VR category items
    -- ==============================
    ["Water Reflections"] = "Отражения воды",
    ["Water Refractions"] = "Преломление воды",
    ["Force Expensive Water"] = "Принудительная качественная вода",
    ["Force Water Reflect Entities"] = "Принудительное отражение объектов в воде",
    ["VR Mirror Optimization"] = "Оптимизация VR-зеркала",
    ["Reflective Glass Toggle"] = "Переключение отражающего стекла",
    ["Disable Mirrors"] = "Отключить зеркала",
    ["Multi-core Rendering"] = "Многоядерный рендеринг",
    ["Multicore Rendering Mode"] = "Режим многоядерного рендеринга",

    -- Help: Opt.VR / Opt.Gmod
    ["Changes apply immediately in spawn menu."] = "Изменения применяются сразу в меню спавна.",

    -- ==============================
    -- Opt.Gmod category items
    -- ==============================
    ["Max Shadows Rendered"] = "Максимум отрисованных теней",
    ["Flashlight Shadow Resolution"] = "Разрешение теней фонарика",
    ["Texture Quality (lower=better)"] = "Качество текстур (ниже=лучше)",
    ["Level of Detail"] = "Уровень детализации",
    ["Root Level of Detail"] = "Корневой уровень детализации",
    ["AI Expression Frequency"] = "Частота AI-выражений",
    ["Detail Distance"] = "Дистанция деталей",
    ["Fast Specular"] = "Быстрое зеркальное отражение",
    ["Water Overlay Size"] = "Размер водного наложения",
    ["Draw Detail Props"] = "Отрисовка детальных объектов",
    ["Specular Reflections"] = "Зеркальные отражения",

    -- ==============================
    -- Quick Menu category items
    -- ==============================
    ["Map Browser"] = "Браузер карт",
    ["VR Exit"] = "Выход из VR",
    ["UI Reset"] = "Сброс UI",
    ["VRE GBRadial & Add Menu"] = "VRE GBRadial и доп. меню",
    ["Chat"] = "Чат",
    ["Keyboard"] = "Клавиатура",
    ["Toggle Mirror"] = "Переключить зеркало",
    ["Spawn Menu"] = "Меню спавна",
    ["No Clip"] = "Ноуклип",
    ["Context Menu"] = "Контекстное меню",
    ["ArcCW Customize"] = "Настройка ArcCW",
    ["Toggle Vehicle Mode"] = "Переключить режим транспорта",

    -- ==============================
    -- VRStop Key category items
    -- ==============================
    ["Hold Time (Seconds)"] = "Время удержания (секунды)",
    ["FPS Guard Enable"] = "Включить защиту FPS",
    ["FPS Drop Threshold (ms)"] = "Порог падения FPS (мс)",
    ["Retry Count"] = "Количество повторов",
    ["Emergency FPS Enable"] = "Включить аварийную остановку FPS",
    ["FPS Threshold"] = "Порог FPS",
    ["Duration (Seconds)"] = "Длительность (секунды)",

    -- Section: VRStop Key
    ["FPS Guard"] = "Защита FPS",
    ["Emergency FPS Stop"] = "Аварийная остановка FPS",

    -- Help: VRStop Key
    ["Emergency Stop key must be set in VRMod Menu (key binder)."] = "Клавиша аварийной остановки должна быть назначена в меню VRMod (привязка клавиш).",
    ["Automatically stops VR when frame time exceeds threshold."] = "Автоматически останавливает VR, когда время кадра превышает порог.",
    ["Stops VR if FPS stays below threshold for the specified duration."] = "Останавливает VR, если FPS остаётся ниже порога в течение указанного времени.",

    -- ==============================
    -- Misc category items
    -- ==============================
    ["VRMod Menu Show on Startup"] = "Показывать меню VRMod при запуске",
    ["Error Check Method"] = "Метод проверки ошибок",
    ["ModuleError VRMod Menu Lock"] = "Блокировка меню VRMod при ошибке модуля",
    ["Player Model Change (forPAC3)"] = "Смена модели игрока (для PAC3)",
    ["VR Disable Pickup (Client)"] = "Отключить VR-подбор (Клиент)",
    ["Enable LVS Pickup Handle"] = "Включить рукоятку подбора LVS",
    ["VRMod Menu Type"] = "Тип меню VRMod",
    ["Use Custom QuickMenu"] = "Использовать своё быстрое меню",
    ["Auto Seat Reset"] = "Автосброс сиденья",
    ["Sight Bodypart"] = "Часть тела для прицеливания",
    ["Developer Mode (requires restart)"] = "Режим разработчика (требуется перезапуск)",
    ["Restore Misc Defaults"] = "Сбросить прочие настройки",

    -- ==============================
    -- Animation category items
    -- ==============================
    ["Reset to Default"] = "Сбросить по умолчанию",

    -- Help: Animation
    ["Enter animation names (e.g., ACT_HL2MP_IDLE)"] = "Введите название анимации (напр., ACT_HL2MP_IDLE)",

    -- ==============================
    -- Graphics02 category items
    -- ==============================
    ["Automatic Resolution Set"] = "Автоустановка разрешения",
    ["Quest 2 / Virtual Desktop Preset"] = "Пресет Quest 2 / Virtual Desktop",

    -- ==============================
    -- Network(Server) category items
    -- ==============================
    ["Allow VR Teleport (Server)"] = "Разрешить VR-телепортацию (Сервер)",

    -- ==============================
    -- Commands category items
    -- ==============================
    ["Toggle Door Collision Debug"] = "Переключить отладку столкновений с дверьми",
    ["Toggle Playspace Debug"] = "Переключить отладку игрового пространства",
    ["Toggle Network Debug"] = "Переключить отладку сети",
    ["Print VR Devices Info"] = "Вывести информацию об устройствах VR",
    ["Start Cardboard VR"] = "Запустить картонный VR",
    ["Exit Cardboard VR"] = "Выйти из картонного VR",
    ["Toggle Radial Menu"] = "Переключить радиальное меню",
    ["Toggle Server Menu"] = "Переключить серверное меню",

    -- Section: Commands
    ["Debug Visualization"] = "Визуализация отладки",
    ["Device Information"] = "Информация об устройстве",
    ["Cardboard VR"] = "Картонный VR",
    ["VRE Integration"] = "Интеграция VRE",

    -- ==============================
    -- Vehicle category items
    -- ==============================
    ["Main Mode (On-Foot)"] = "Основной режим (пешком)",
    ["Driving Mode (Vehicle)"] = "Режим вождения (транспорт)",
    ["Both Modes (Main+Driving)"] = "Оба режима (основной+вождение)",
    ["Auto Mode (Restore)"] = "Автоматический режим (восстановление)",
    ["LVS Networked Mode"] = "Сетевой режим LVS",
    ["Reset Vehicle Settings"] = "Сбросить настройки транспорта",

    -- ==============================
    -- Magazine category items
    -- ==============================
    ["Enable VR Magazine System"] = "Включить систему VR-магазинов",
    ["Enable Magazine Pouch"] = "Включить подсумок для магазинов",
    ["VR Magazine bone or bonegroup"] = "Кость или группа костей VR-магазина",
    ["Magazine Enter Sound"] = "Звук вставки магазина",
    ["Magazine Enter Range"] = "Дальность вставки магазина",
    ["Magazine Enter Model"] = "Модель вставки магазина",
    ["[WIP] WeaponModel Mag Grab/Eject"] = "[В разработке] Захват/извлечение магазина модели оружия",
    ["Angle Pitch"] = "Угол наклона",
    ["Angle Yaw"] = "Угол рыскания",
    ["Angle Roll"] = "Угол крена",
    ["Magazine Bone Names"] = "Названия костей магазина",
    ["Pouch Location"] = "Расположение подсумка",
    ["Pouch Distance"] = "Дистанция подсумка",
    ["Infinite Pouch (any distance)"] = "Бесконечный подсумок (любая дистанция)",
    ["Sync to ArcVR ConVars"] = "Синхронизация с ArcVR ConVar",
    ["Enable ARC9 VR Integration"] = "Включить интеграцию ARC9 VR",
    ["Enable ARC9 Magazine Bone Fix"] = "Включить исправление кости магазина ARC9",
    ["ARC9 Mag Bone: Follow Left Hand / Hide Only"] = "Кость магазина ARC9: следовать за левой рукой / только скрыть",

    -- Section: Magazine
    ["Magazine Position"] = "Позиция магазина",
    ["Pouch Position (shared with ArcVR)"] = "Позиция подсумка (общая с ArcVR)",
    ["ARC9 Weapon Settings"] = "Настройки оружия ARC9",

    -- Help: Magazine
    ["Magazine Pouch: reach left hand to body pouch + Pickup to spawn vrmagent."] = "Подсумок: протяните левую руку к подсумку на теле + Подбор для создания vrmagent.",

    -- ==============================
    -- Utility category items
    -- ==============================
    ["Auto-Detect Screen Resolution"] = "Автоопределение разрешения экрана",
    ["Reset VGUI Panels"] = "Сбросить панели VGUI",
    ["Generate VR Config Data"] = "Сгенерировать данные конфигурации VR",
    ["Auto-generate on VR startup"] = "Автогенерация при запуске VR",
    ["Start VR"] = "Запустить VR",
    ["Exit VR"] = "Выйти из VR",
    ["Reset All Settings"] = "Сбросить все настройки",
    ["Print VR Info"] = "Вывести информацию о VR",
    ["Reset Lua Modules"] = "Сбросить модули Lua",

    -- Section: Utility
    ["Screen & VGUI"] = "Экран и VGUI",
    ["VR Config Data Generation"] = "Генерация данных конфигурации VR",
    ["Core VR Control"] = "Основное управление VR",

    -- ==============================
    -- Cardboard category items
    -- ==============================
    ["Cardboard Scale"] = "Масштаб картонного VR",
    ["Cardboard Sensitivity"] = "Чувствительность картонного VR",

    -- Help: Cardboard
    ["Cardboard VR mode (phone sensor emulation)"] = "Режим картонного VR (эмуляция датчиков телефона)",

    -- ==============================
    -- C++ Module category items
    -- ==============================
    ["Input Mode"] = "Режим ввода",
    ["Module Error: Lock VRMod Menu"] = "Ошибка модуля: заблокировать меню VRMod",
    ["Re-extract Module Files"] = "Повторно извлечь файлы модуля",
    ["Open Keybinding Editor"] = "Открыть редактор привязок клавиш",
    ["Open Module Folder Guide"] = "Открыть руководство по папке модуля",
    ["Print Module Diagnostics"] = "Вывести диагностику модуля",

    -- Section: C++ Module
    ["Settings"] = "Настройки",
    ["Actions"] = "Действия",
    ["Troubleshooting"] = "Устранение неполадок",

    -- Help: C++ Module
    ["If module is not working: 1) Go to garrysmod/data/vrmod_module/ 2) Rename install.txt -> install.bat 3) Run install.bat, restart Gmod 4) Add GarrysMod folder to AV exclusions if blocked"] = "Если модуль не работает: 1) Перейдите в garrysmod/data/vrmod_module/ 2) Переименуйте install.txt в install.bat 3) Запустите install.bat, перезапустите Gmod 4) Добавьте папку GarrysMod в исключения антивируса, если заблокировано",

    -- ==============================
    -- Key Mapping category items
    -- ==============================
    ["Enable Input Emulation"] = "Включить эмуляцию ввода",
    ["Enable C++ Engine Injection"] = "Включить инъекцию движка C++",
    ["Open Visual Keyboard Editor"] = "Открыть визуальный редактор клавиатуры",
    ["Print Current Mapping"] = "Вывести текущие назначения",

    -- Section: Key Mapping
    ["Key Assignment"] = "Назначение клавиш",
    ["Debug"] = "Отладка",

    -- Help: Key Mapping
    ["Click a keyboard key, then press a VR controller button to assign."] = "Нажмите клавишу на клавиатуре, затем нажмите кнопку VR-контроллера для назначения.",

    -- ==============================
    -- Modules category items
    -- ==============================
    ["Addon-Only Mode (skip root files)"] = "Режим только аддона (пропуск корневых файлов)",
    ["Legacy Mode (load only core features)"] = "Устаревший режим (загрузка только основных функций)",
    ["[2] Holster Type2"] = "[2] Кобура тип 2",
    ["[3] Foregrip"] = "[3] Передний хват",
    ["[4] Magbone/ARC9"] = "[4] Кость магазина/ARC9",
    ["[5] Melee"] = "[5] Ближний бой",
    ["[6] Holster Type1"] = "[6] Кобура тип 1",
    ["[7] VR Hand HUD"] = "[7] VR HUD на руке",
    ["[8] Physgun"] = "[8] Физпушка",
    ["[9] VR Pickup"] = "[9] VR-подбор",
    ["[10] Debug"] = "[10] Отладка",
    ["[11] (Reserved)"] = "[11] (Зарезервировано)",
    ["[12] Guide"] = "[12] Руководство",
    ["[13] RealMech"] = "[13] RealMech",
    ["[14] Throw"] = "[14] Бросок",

    -- Section: Modules
    ["Addon-Only Mode"] = "Режим только аддона",
    ["Legacy Mode"] = "Устаревший режим",
    ["Feature Modules"] = "Функциональные модули",

    -- Help: Modules
    ["Changes require Gmod restart to take effect."] = "Для применения изменений требуется перезапуск Gmod.",

    -- ==============================
    -- Combo option labels
    -- ==============================
    ["Right Hand"] = "Правая рука",
    ["Pelvis (Hip)"] = "Таз (бедро)",
    ["Head"] = "Голова",
    ["Spine (Chest)"] = "Позвоночник (грудь)",
    ["SteamVR Bindings (Default)"] = "Привязки SteamVR (по умолчанию)",
    ["Lua Keybinding"] = "Привязка Lua",

    -- ==============================
    -- Standalone buttons (spawnmenu_tab.lua)
    -- ==============================
    ["Open VRMod Menu"] = "Открыть меню VRMod",
    ["Auto-Detect Resolution"] = "Автоопределение разрешения",
})

-- ============================================================================
-- vrmod_unoff_addmenu.lua strings
-- ============================================================================
AddSettings("ja", {
    -- Section headers
    ["=== Screen & VGUI ==="] = "=== 画面 & VGUI ===",
    ["=== VR Config Data Generation ==="] = "=== VR設定データ生成 ===",
    ["=== Core VR Control ==="] = "=== VRコア操作 ===",
    ["=== Cardboard VR Settings ==="] = "=== 段ボールVR設定 ===",
    ["=== Cardboard Commands ==="] = "=== 段ボールVRコマンド ===",
    ["=== Screen Resolution Settings ==="] = "=== 画面解像度設定 ===",
    ["=== Mirror & Reflection Management ==="] = "=== 鏡と反射の管理 ===",
    ["=== Render Target Settings ==="] = "=== レンダーターゲット設定 ===",
    ["=== Debug Visualization ==="] = "=== デバッグ表示 ===",
    ["=== Device Information ==="] = "=== デバイス情報 ===",
    ["=== Cardboard VR Support ==="] = "=== 段ボールVRサポート ===",
    ["=== VRE (VR Essentials) Integration ==="] = "=== VRE (VR Essentials) 統合 ===",
    ["=== Module Status ==="] = "=== モジュール状態 ===",
    ["=== Settings ==="] = "=== 設定 ===",
    ["=== Actions ==="] = "=== アクション ===",
    ["=== Troubleshooting ==="] = "=== トラブルシューティング ===",
    ["=== Input Emulation Status ==="] = "=== 入力エミュレーション状態 ===",
    ["=== Key Assignment ==="] = "=== キー割り当て ===",
    ["=== Debug ==="] = "=== デバッグ ===",

    -- chat.AddText messages
    ["Screen resolution auto-detected!"] = "画面解像度を自動検出しました！",
    ["VGUI panels reset"] = "VGUIパネルをリセットしました",
    ["VR config data generated! (VMT files converted)"] = "VR設定データを生成しました！ (VMTファイル変換済み)",
    ["All VR settings reset!"] = "全VR設定をリセットしました！",
    ["VR info printed to console"] = "VR情報をコンソールに出力しました",
    ["Lua modules reset"] = "Luaモジュールをリセットしました",
    ["Cardboard VR mode started"] = "段ボールVRモードを開始しました",
    ["Cardboard VR mode exited"] = "段ボールVRモードを終了しました",
    ["Optimization applied!"] = "最適化を適用しました！",
    ["All reflective glass removed from map"] = "マップの全反射ガラスを除去しました",
    ["Render targets reset (VR will exit)"] = "レンダーターゲットをリセットしました (VRが終了します)",
    ["Render targets updated"] = "レンダーターゲットを更新しました",
    ["Quest 2 preset applied, VR restarting..."] = "Quest 2プリセットを適用、VR再起動中...",
    ["Render target multipliers reset to default (2.0)"] = "レンダーターゲット倍率をデフォルト(2.0)にリセットしました",
    ["VR devices info printed to console"] = "VRデバイス情報をコンソールに出力しました",
    ["Switched to Main input mode"] = "メイン入力モードに切り替えました",
    ["Switched to Driving input mode"] = "運転入力モードに切り替えました",
    ["Both input modes enabled"] = "両方の入力モードを有効化しました",
    ["Input mode restored to automatic"] = "入力モードを自動に復元しました",
    ["Switched to LFS mode"] = "LFSモードに切り替えました",
    ["Switched to SimfPhys mode"] = "SimfPhysモードに切り替えました",
    ["Vehicle settings reset to defaults"] = "車両設定をデフォルトにリセットしました",
    ["Module files re-extracted. Check console for details."] = "モジュールファイルを再展開しました。詳細はコンソールを確認してください。",
    ["Go to: garrysmod/data/vrmod_module/"] = "移動先: garrysmod/data/vrmod_module/",
    ["Module diagnostics printed to console."] = "モジュール診断情報をコンソールに出力しました。",

    -- Button/label text (not in registry)
    ["Default"] = "デフォルト",
    ["Apply"] = "適用",
    ["Start Cardboard VR Mode"] = "段ボールVRモードを開始",
    ["Exit Cardboard VR Mode"] = "段ボールVRモードを終了",
    ["Enable Seated Mode"] = "座位モードを有効化",
    ["Character Animation Enable (Client)"] = "キャラクターアニメーション有効化 (クライアント)",
    ["Head Hide Position X"] = "頭非表示位置 X",
    ["Head Hide Position Y"] = "頭非表示位置 Y",
    ["Head Hide Position Z"] = "頭非表示位置 Z",
    ["Idle Animation (default: ACT_HL2MP_IDLE)"] = "待機アニメーション (デフォルト: ACT_HL2MP_IDLE)",
    ["Walk Animation (default: ACT_HL2MP_WALK)"] = "歩行アニメーション (デフォルト: ACT_HL2MP_WALK)",
    ["Run Animation (default: ACT_HL2MP_RUN)"] = "走行アニメーション (デフォルト: ACT_HL2MP_RUN)",
    ["Jump Animation (default: ACT_HL2MP_JUMP_PASSIVE)"] = "ジャンプアニメーション (デフォルト: ACT_HL2MP_JUMP_PASSIVE)",
    ["Left Hand (WIP)"] = "左手 (開発中)",
    ["Left Hand Fire (WIP)"] = "左手で射撃 (開発中)",
    ["Left Hand Hold Mode (WIP)"] = "左手ホールドモード (開発中)",
    ["Apply VR Settings (Requires VRMod Restart)"] = "VR設定を適用 (VRMod再起動が必要)",
    ["Auto Adjust VR Settings (Requires VRMod Restart)"] = "VR設定を自動調整 (VRMod再起動が必要)",
    ["Character Head to HMD Distance"] = "キャラクターの頭とHMDの距離",
    ["Manual Pickup (by Hugo)"] = "手動ピックアップ (by Hugo)",
    ["[Jumpkey Auto Duck]\nON => Jumpkey = IN_DUCK + IN_JUMP\nOFF => Jumpkey = IN_JUMP"] = "[ジャンプキー自動しゃがみ]\nON => ジャンプキー = IN_DUCK + IN_JUMP\nOFF => ジャンプキー = IN_JUMP",
    ["[Teleport Enable]"] = "[テレポート有効化]",
    ["[Teleport Hand]\n0 = Left Hand  1 = Right Hand  2 = Head"] = "[テレポート手]\n0 = 左手  1 = 右手  2 = 頭",
    ["[Flashlight Attachment]\n0 = Right Hand 1 = Left Hand\n 2 = HMD"] = "[懐中電灯取り付け]\n0 = 右手 1 = 左手\n 2 = HMD",
    ["Remove All Reflective Glass from Map"] = "マップの全反射ガラスを除去",
    ["Reset Render Target Multipliers to Default"] = "レンダーターゲット倍率をデフォルトに戻す",
    ["Render Target Width Multiplier"] = "レンダーターゲット幅倍率",
    ["Render Target Height Multiplier"] = "レンダーターゲット高さ倍率",
    ["VRMod Optimization Level"] = "VRMod最適化レベル",
    ["Custom Width & Height (Quest 2 / Virtual Desktop)"] = "カスタム幅&高さ (Quest 2 / Virtual Desktop)",
    ["Emergency Stop Key:"] = "緊急停止キー:",
    ["Enable Developer Mode (requires VRMod restart)"] = "開発者モードを有効化 (VRMod再起動が必要)",
    ["Developer Mode enables advanced debug settings.\nToggle this and restart VRMod to apply changes."] = "開発者モードは高度なデバッグ設定を有効にします。\n切り替えた後、VRModを再起動して変更を適用してください。",
    ["Input Mode:"] = "入力モード:",
    ["Enable Input Emulation (vrmod_unoff_input_emu)"] = "入力エミュレーション有効化 (vrmod_unoff_input_emu)",
    ["Enable C++ Engine Injection (vrmod_unoff_cpp_keyinject)"] = "C++エンジンインジェクション有効化 (vrmod_unoff_cpp_keyinject)",
    ["Always Auto-Detect Resolution on VR Start"] = "VR開始時に常に解像度を自動検出",
    ["Net Delay"] = "ネット遅延",
    ["Net Delay Max"] = "ネット最大遅延",
    ["Net Stored Frames"] = "ネット保存フレーム数",
    ["Net Tickrate"] = "ネットティックレート",
    ["Position X"] = "位置 X",
    ["Position Y"] = "位置 Y",
    ["Position Z"] = "位置 Z",
    ["<< Tree View"] = "<< ツリー表示",
    [">> Guide View"] = ">> ガイド表示",
    ["Emergency Stop"] = "緊急停止",
    ["VR Commands"] = "VRコマンド",
    ["VR Magazine System"] = "VRマガジンシステム",

    -- Help text
    ["Show/hide the virtual keyboard for text input in VR"] = "VRでのテキスト入力用仮想キーボードの表示/非表示",
    ["Configure VR controller bindings (Note: Disabled while VR is active)"] = "VRコントローラーバインドを設定 (注意: VR動作中は無効)",
    ["WARNING: Changing these settings requires VR restart to take effect"] = "警告: これらの設定を変更するにはVRの再起動が必要です",
    ["Automatically detect and set optimal screen resolution when entering VR"] = "VR開始時に最適な画面解像度を自動検出して設定",
    ["Manually trigger optimization based on current vrmod_gmod_optimization level"] = "現在のvrmod_gmod_optimizationレベルに基づき手動で最適化を実行",
    ["Forcibly removes all reflective surfaces from the map (may cause visual glitches)"] = "マップの全反射面を強制除去します (視覚的な不具合が発生する可能性があります)",
    ["Reset VR render targets (VR mode will exit)"] = "VRレンダーターゲットをリセット (VRモードが終了します)",
    ["Update render targets with current multiplier settings"] = "現在の倍率設定でレンダーターゲットを更新",
    ["Set optimal render target multipliers for Quest 2 + Virtual Desktop (VR will restart)"] = "Quest 2 + Virtual Desktop用の最適なレンダーターゲット倍率を設定 (VRが再起動します)",
    ["Reset both multipliers to default value (2.0)"] = "両方の倍率をデフォルト値(2.0)にリセット",
    ["Visualize collision boxes, playspace boundaries, and network traffic"] = "当たり判定ボックス、プレイスペース境界、ネットワークトラフィックを可視化",
    ["Display all connected VR tracking devices and FBT status"] = "接続中の全VRトラッキングデバイスとFBT状態を表示",
    ["Alternative VR mode using phone sensors (no HMD required)"] = "スマホセンサーを使った代替VRモード (HMD不要)",
    ["Alternative VR mode using phone sensors (for testing without HMD)"] = "スマホセンサーを使った代替VRモード (HMDなしテスト用)",
    ["VRE addon must be installed for these commands to work"] = "これらのコマンドを使用するにはVREアドオンのインストールが必要です",

    -- Vehicle panel
    ["Main Mode\n(On-Foot)"] = "メインモード\n(徒歩)",
    ["Driving Mode\n(Vehicle)"] = "運転モード\n(車両)",
    ["Both Modes\n(Main + Driving)"] = "両方のモード\n(メイン + 運転)",
    ["Auto Mode\n(Restore)"] = "自動モード\n(復元)",
    ["Use main controller bindings (on-foot controls)"] = "メインコントローラーバインドを使用 (徒歩操作)",
    ["Use driving controller bindings (vehicle controls)"] = "運転コントローラーバインドを使用 (車両操作)",
    ["Use both main and driving bindings simultaneously"] = "メインと運転の両方のバインドを同時使用",
    ["LVS Networked Mode (1 = multiplayer, 0 = singleplayer)"] = "LVSネットワークモード (1 = マルチ, 0 = シングル)",
    ["LFS Mode"] = "LFSモード",
    ["SimfPhys Mode"] = "SimfPhysモード",
    ["[Auto Seat Reset] Disable seat mode when entering vehicle"] = "[シート自動リセット] 車両搭乗時にシートモードを無効化",

    -- VRModL code-key buttons
    ["btn_restore_defaults"] = "デフォルト設定に戻す",

    -- Optimization description
    ["Optimization Levels:\n0: No optimization applied\n1: No changes - VRMod does not modify any ConVars\n2: Reset - Restores water reflections, disables mirror optimization\n3: Optimization ON - Water/mirrors/specular OFF, gmod_mcore_test 0 (VR safe)\n4: Max optimization - All of Lv3 + gmod_mcore_test 1 (!!Right eye flash WARNING!!)"] = "最適化レベル:\n0: 最適化なし\n1: 変更なし - VRModはConVarを変更しません\n2: リセット - 水面反射を復元、ミラー最適化を無効化\n3: 最適化ON - 水面/ミラー/スペキュラーOFF、gmod_mcore_test 0 (VR安全)\n4: 最大最適化 - Lv3の全項目 + gmod_mcore_test 1 (!!右目フラッシュ警告!!)",
})

AddSettings("zh", {
    -- Section headers
    ["=== Screen & VGUI ==="] = "=== 屏幕和VGUI ===",
    ["=== VR Config Data Generation ==="] = "=== VR配置数据生成 ===",
    ["=== Core VR Control ==="] = "=== 核心VR控制 ===",
    ["=== Cardboard VR Settings ==="] = "=== 纸盒VR设置 ===",
    ["=== Cardboard Commands ==="] = "=== 纸盒VR命令 ===",
    ["=== Screen Resolution Settings ==="] = "=== 屏幕分辨率设置 ===",
    ["=== Mirror & Reflection Management ==="] = "=== 镜面与反射管理 ===",
    ["=== Render Target Settings ==="] = "=== 渲染目标设置 ===",
    ["=== Debug Visualization ==="] = "=== 调试可视化 ===",
    ["=== Device Information ==="] = "=== 设备信息 ===",
    ["=== Cardboard VR Support ==="] = "=== 纸盒VR支持 ===",
    ["=== VRE (VR Essentials) Integration ==="] = "=== VRE (VR Essentials) 集成 ===",
    ["=== Module Status ==="] = "=== 模块状态 ===",
    ["=== Settings ==="] = "=== 设置 ===",
    ["=== Actions ==="] = "=== 操作 ===",
    ["=== Troubleshooting ==="] = "=== 故障排除 ===",
    ["=== Input Emulation Status ==="] = "=== 输入模拟状态 ===",
    ["=== Key Assignment ==="] = "=== 按键分配 ===",
    ["=== Debug ==="] = "=== 调试 ===",

    -- chat.AddText messages
    ["Screen resolution auto-detected!"] = "屏幕分辨率已自动检测！",
    ["VGUI panels reset"] = "VGUI面板已重置",
    ["VR config data generated! (VMT files converted)"] = "VR配置数据已生成！(VMT文件已转换)",
    ["All VR settings reset!"] = "所有VR设置已重置！",
    ["VR info printed to console"] = "VR信息已输出到控制台",
    ["Lua modules reset"] = "Lua模块已重置",
    ["Cardboard VR mode started"] = "纸盒VR模式已启动",
    ["Cardboard VR mode exited"] = "纸盒VR模式已退出",
    ["Optimization applied!"] = "优化已应用！",
    ["All reflective glass removed from map"] = "已移除地图中所有反光玻璃",
    ["Render targets reset (VR will exit)"] = "渲染目标已重置 (VR将退出)",
    ["Render targets updated"] = "渲染目标已更新",
    ["Quest 2 preset applied, VR restarting..."] = "Quest 2预设已应用，VR正在重启...",
    ["Render target multipliers reset to default (2.0)"] = "渲染目标倍率已重置为默认值(2.0)",
    ["VR devices info printed to console"] = "VR设备信息已输出到控制台",
    ["Switched to Main input mode"] = "已切换到主输入模式",
    ["Switched to Driving input mode"] = "已切换到驾驶输入模式",
    ["Both input modes enabled"] = "已启用双输入模式",
    ["Input mode restored to automatic"] = "输入模式已恢复为自动",
    ["Switched to LFS mode"] = "已切换到LFS模式",
    ["Switched to SimfPhys mode"] = "已切换到SimfPhys模式",
    ["Vehicle settings reset to defaults"] = "载具设置已重置为默认值",
    ["Module files re-extracted. Check console for details."] = "模块文件已重新提取。请查看控制台了解详情。",
    ["Go to: garrysmod/data/vrmod_module/"] = "前往: garrysmod/data/vrmod_module/",
    ["Module diagnostics printed to console."] = "模块诊断信息已输出到控制台。",

    -- Button/label text (not in registry)
    ["Default"] = "默认",
    ["Apply"] = "应用",
    ["Start Cardboard VR Mode"] = "启动纸盒VR模式",
    ["Exit Cardboard VR Mode"] = "退出纸盒VR模式",
    ["Enable Seated Mode"] = "启用坐姿模式",
    ["Character Animation Enable (Client)"] = "启用角色动画 (客户端)",
    ["Head Hide Position X"] = "头部隐藏位置 X",
    ["Head Hide Position Y"] = "头部隐藏位置 Y",
    ["Head Hide Position Z"] = "头部隐藏位置 Z",
    ["Idle Animation (default: ACT_HL2MP_IDLE)"] = "待机动画 (默认: ACT_HL2MP_IDLE)",
    ["Walk Animation (default: ACT_HL2MP_WALK)"] = "行走动画 (默认: ACT_HL2MP_WALK)",
    ["Run Animation (default: ACT_HL2MP_RUN)"] = "奔跑动画 (默认: ACT_HL2MP_RUN)",
    ["Jump Animation (default: ACT_HL2MP_JUMP_PASSIVE)"] = "跳跃动画 (默认: ACT_HL2MP_JUMP_PASSIVE)",
    ["Left Hand (WIP)"] = "左手 (开发中)",
    ["Left Hand Fire (WIP)"] = "左手开火 (开发中)",
    ["Left Hand Hold Mode (WIP)"] = "左手持握模式 (开发中)",
    ["Apply VR Settings (Requires VRMod Restart)"] = "应用VR设置 (需要重启VRMod)",
    ["Auto Adjust VR Settings (Requires VRMod Restart)"] = "自动调整VR设置 (需要重启VRMod)",
    ["Character Head to HMD Distance"] = "角色头部到HMD距离",
    ["Manual Pickup (by Hugo)"] = "手动拾取 (by Hugo)",
    ["[Jumpkey Auto Duck]\nON => Jumpkey = IN_DUCK + IN_JUMP\nOFF => Jumpkey = IN_JUMP"] = "[跳跃键自动蹲下]\nON => 跳跃键 = IN_DUCK + IN_JUMP\nOFF => 跳跃键 = IN_JUMP",
    ["[Teleport Enable]"] = "[启用传送]",
    ["[Teleport Hand]\n0 = Left Hand  1 = Right Hand  2 = Head"] = "[传送手]\n0 = 左手  1 = 右手  2 = 头部",
    ["[Flashlight Attachment]\n0 = Right Hand 1 = Left Hand\n 2 = HMD"] = "[手电筒安装]\n0 = 右手 1 = 左手\n 2 = HMD",
    ["Remove All Reflective Glass from Map"] = "移除地图中所有反光玻璃",
    ["Reset Render Target Multipliers to Default"] = "将渲染目标倍率恢复为默认值",
    ["Render Target Width Multiplier"] = "渲染目标宽度倍率",
    ["Render Target Height Multiplier"] = "渲染目标高度倍率",
    ["VRMod Optimization Level"] = "VRMod优化等级",
    ["Custom Width & Height (Quest 2 / Virtual Desktop)"] = "自定义宽高 (Quest 2 / Virtual Desktop)",
    ["Emergency Stop Key:"] = "紧急停止键:",
    ["Enable Developer Mode (requires VRMod restart)"] = "启用开发者模式 (需要重启VRMod)",
    ["Developer Mode enables advanced debug settings.\nToggle this and restart VRMod to apply changes."] = "开发者模式启用高级调试设置。\n切换后重启VRMod以应用更改。",
    ["Input Mode:"] = "输入模式:",
    ["Enable Input Emulation (vrmod_unoff_input_emu)"] = "启用输入模拟 (vrmod_unoff_input_emu)",
    ["Enable C++ Engine Injection (vrmod_unoff_cpp_keyinject)"] = "启用C++引擎注入 (vrmod_unoff_cpp_keyinject)",
    ["Always Auto-Detect Resolution on VR Start"] = "VR启动时始终自动检测分辨率",
    ["Net Delay"] = "网络延迟",
    ["Net Delay Max"] = "最大网络延迟",
    ["Net Stored Frames"] = "网络存储帧数",
    ["Net Tickrate"] = "网络Tick速率",
    ["Position X"] = "位置 X",
    ["Position Y"] = "位置 Y",
    ["Position Z"] = "位置 Z",
    ["<< Tree View"] = "<< 树形视图",
    [">> Guide View"] = ">> 指南视图",
    ["Emergency Stop"] = "紧急停止",
    ["VR Commands"] = "VR命令",
    ["VR Magazine System"] = "VR弹匣系统",

    -- Help text
    ["Show/hide the virtual keyboard for text input in VR"] = "显示/隐藏VR中文本输入的虚拟键盘",
    ["Configure VR controller bindings (Note: Disabled while VR is active)"] = "配置VR控制器绑定 (注意: VR运行时禁用)",
    ["WARNING: Changing these settings requires VR restart to take effect"] = "警告: 更改这些设置需要重启VR才能生效",
    ["Automatically detect and set optimal screen resolution when entering VR"] = "进入VR时自动检测并设置最佳屏幕分辨率",
    ["Manually trigger optimization based on current vrmod_gmod_optimization level"] = "根据当前vrmod_gmod_optimization等级手动触发优化",
    ["Forcibly removes all reflective surfaces from the map (may cause visual glitches)"] = "强制移除地图中所有反射表面 (可能导致视觉异常)",
    ["Reset VR render targets (VR mode will exit)"] = "重置VR渲染目标 (VR模式将退出)",
    ["Update render targets with current multiplier settings"] = "使用当前倍率设置更新渲染目标",
    ["Set optimal render target multipliers for Quest 2 + Virtual Desktop (VR will restart)"] = "设置Quest 2 + Virtual Desktop的最佳渲染目标倍率 (VR将重启)",
    ["Reset both multipliers to default value (2.0)"] = "将两个倍率重置为默认值(2.0)",
    ["Visualize collision boxes, playspace boundaries, and network traffic"] = "可视化碰撞箱、游玩空间边界和网络流量",
    ["Display all connected VR tracking devices and FBT status"] = "显示所有已连接的VR追踪设备和FBT状态",
    ["Alternative VR mode using phone sensors (no HMD required)"] = "使用手机传感器的替代VR模式 (无需HMD)",
    ["Alternative VR mode using phone sensors (for testing without HMD)"] = "使用手机传感器的替代VR模式 (无HMD测试用)",
    ["VRE addon must be installed for these commands to work"] = "需要安装VRE插件才能使用这些命令",

    -- Vehicle panel
    ["Main Mode\n(On-Foot)"] = "主模式\n(步行)",
    ["Driving Mode\n(Vehicle)"] = "驾驶模式\n(载具)",
    ["Both Modes\n(Main + Driving)"] = "双模式\n(主 + 驾驶)",
    ["Auto Mode\n(Restore)"] = "自动模式\n(恢复)",
    ["Use main controller bindings (on-foot controls)"] = "使用主控制器绑定 (步行控制)",
    ["Use driving controller bindings (vehicle controls)"] = "使用驾驶控制器绑定 (载具控制)",
    ["Use both main and driving bindings simultaneously"] = "同时使用主控制和驾驶绑定",
    ["LVS Networked Mode (1 = multiplayer, 0 = singleplayer)"] = "LVS联网模式 (1 = 多人, 0 = 单人)",
    ["LFS Mode"] = "LFS模式",
    ["SimfPhys Mode"] = "SimfPhys模式",
    ["[Auto Seat Reset] Disable seat mode when entering vehicle"] = "[自动座位重置] 进入载具时禁用座位模式",

    -- VRModL code-key buttons
    ["btn_restore_defaults"] = "恢复默认设置",

    -- Optimization description
    ["Optimization Levels:\n0: No optimization applied\n1: No changes - VRMod does not modify any ConVars\n2: Reset - Restores water reflections, disables mirror optimization\n3: Optimization ON - Water/mirrors/specular OFF, gmod_mcore_test 0 (VR safe)\n4: Max optimization - All of Lv3 + gmod_mcore_test 1 (!!Right eye flash WARNING!!)"] = "优化等级:\n0: 未应用优化\n1: 无更改 - VRMod不修改任何ConVar\n2: 重置 - 恢复水面反射，禁用镜面优化\n3: 优化开启 - 水面/镜面/高光关闭，gmod_mcore_test 0 (VR安全)\n4: 最大优化 - Lv3全部 + gmod_mcore_test 1 (!!右眼闪烁警告!!)",
})

AddSettings("ru", {
    -- Section headers
    ["=== Screen & VGUI ==="] = "=== Экран и VGUI ===",
    ["=== VR Config Data Generation ==="] = "=== Генерация данных конфигурации VR ===",
    ["=== Core VR Control ==="] = "=== Основное управление VR ===",
    ["=== Cardboard VR Settings ==="] = "=== Настройки картонного VR ===",
    ["=== Cardboard Commands ==="] = "=== Команды картонного VR ===",
    ["=== Screen Resolution Settings ==="] = "=== Настройки разрешения экрана ===",
    ["=== Mirror & Reflection Management ==="] = "=== Управление зеркалами и отражениями ===",
    ["=== Render Target Settings ==="] = "=== Настройки целей рендеринга ===",
    ["=== Debug Visualization ==="] = "=== Визуализация отладки ===",
    ["=== Device Information ==="] = "=== Информация об устройстве ===",
    ["=== Cardboard VR Support ==="] = "=== Поддержка картонного VR ===",
    ["=== VRE (VR Essentials) Integration ==="] = "=== Интеграция VRE (VR Essentials) ===",
    ["=== Module Status ==="] = "=== Состояние модуля ===",
    ["=== Settings ==="] = "=== Настройки ===",
    ["=== Actions ==="] = "=== Действия ===",
    ["=== Troubleshooting ==="] = "=== Устранение неполадок ===",
    ["=== Input Emulation Status ==="] = "=== Состояние эмуляции ввода ===",
    ["=== Key Assignment ==="] = "=== Назначение клавиш ===",
    ["=== Debug ==="] = "=== Отладка ===",

    -- chat.AddText messages
    ["Screen resolution auto-detected!"] = "Разрешение экрана определено автоматически!",
    ["VGUI panels reset"] = "Панели VGUI сброшены",
    ["VR config data generated! (VMT files converted)"] = "Данные конфигурации VR сгенерированы! (VMT-файлы конвертированы)",
    ["All VR settings reset!"] = "Все настройки VR сброшены!",
    ["VR info printed to console"] = "Информация о VR выведена в консоль",
    ["Lua modules reset"] = "Модули Lua сброшены",
    ["Cardboard VR mode started"] = "Режим картонного VR запущен",
    ["Cardboard VR mode exited"] = "Режим картонного VR завершён",
    ["Optimization applied!"] = "Оптимизация применена!",
    ["All reflective glass removed from map"] = "Все отражающие стёкла удалены с карты",
    ["Render targets reset (VR will exit)"] = "Цели рендеринга сброшены (VR завершится)",
    ["Render targets updated"] = "Цели рендеринга обновлены",
    ["Quest 2 preset applied, VR restarting..."] = "Пресет Quest 2 применён, VR перезапускается...",
    ["Render target multipliers reset to default (2.0)"] = "Множители целей рендеринга сброшены по умолчанию (2.0)",
    ["VR devices info printed to console"] = "Информация об устройствах VR выведена в консоль",
    ["Switched to Main input mode"] = "Переключено на основной режим ввода",
    ["Switched to Driving input mode"] = "Переключено на режим вождения",
    ["Both input modes enabled"] = "Оба режима ввода включены",
    ["Input mode restored to automatic"] = "Режим ввода восстановлен в автоматический",
    ["Switched to LFS mode"] = "Переключено на режим LFS",
    ["Switched to SimfPhys mode"] = "Переключено на режим SimfPhys",
    ["Vehicle settings reset to defaults"] = "Настройки транспорта сброшены по умолчанию",
    ["Module files re-extracted. Check console for details."] = "Файлы модуля извлечены повторно. Подробности в консоли.",
    ["Go to: garrysmod/data/vrmod_module/"] = "Перейдите в: garrysmod/data/vrmod_module/",
    ["Module diagnostics printed to console."] = "Диагностика модуля выведена в консоль.",

    -- Button/label text (not in registry)
    ["Default"] = "По умолч.",
    ["Apply"] = "Применить",
    ["Start Cardboard VR Mode"] = "Запустить картонный VR",
    ["Exit Cardboard VR Mode"] = "Выйти из картонного VR",
    ["Enable Seated Mode"] = "Включить сидячий режим",
    ["Character Animation Enable (Client)"] = "Включить анимацию персонажа (Клиент)",
    ["Head Hide Position X"] = "Позиция скрытия головы X",
    ["Head Hide Position Y"] = "Позиция скрытия головы Y",
    ["Head Hide Position Z"] = "Позиция скрытия головы Z",
    ["Idle Animation (default: ACT_HL2MP_IDLE)"] = "Анимация покоя (по умолч.: ACT_HL2MP_IDLE)",
    ["Walk Animation (default: ACT_HL2MP_WALK)"] = "Анимация ходьбы (по умолч.: ACT_HL2MP_WALK)",
    ["Run Animation (default: ACT_HL2MP_RUN)"] = "Анимация бега (по умолч.: ACT_HL2MP_RUN)",
    ["Jump Animation (default: ACT_HL2MP_JUMP_PASSIVE)"] = "Анимация прыжка (по умолч.: ACT_HL2MP_JUMP_PASSIVE)",
    ["Left Hand (WIP)"] = "Левая рука (в разработке)",
    ["Left Hand Fire (WIP)"] = "Стрельба левой рукой (в разработке)",
    ["Left Hand Hold Mode (WIP)"] = "Режим удержания левой рукой (в разработке)",
    ["Apply VR Settings (Requires VRMod Restart)"] = "Применить настройки VR (требуется перезапуск VRMod)",
    ["Auto Adjust VR Settings (Requires VRMod Restart)"] = "Автонастройка VR (требуется перезапуск VRMod)",
    ["Character Head to HMD Distance"] = "Расстояние от головы персонажа до HMD",
    ["Manual Pickup (by Hugo)"] = "Ручной подбор (by Hugo)",
    ["[Jumpkey Auto Duck]\nON => Jumpkey = IN_DUCK + IN_JUMP\nOFF => Jumpkey = IN_JUMP"] = "[Авто-присед при прыжке]\nON => Прыжок = IN_DUCK + IN_JUMP\nOFF => Прыжок = IN_JUMP",
    ["[Teleport Enable]"] = "[Включить телепортацию]",
    ["[Teleport Hand]\n0 = Left Hand  1 = Right Hand  2 = Head"] = "[Рука телепортации]\n0 = Левая  1 = Правая  2 = Голова",
    ["[Flashlight Attachment]\n0 = Right Hand 1 = Left Hand\n 2 = HMD"] = "[Крепление фонарика]\n0 = Правая 1 = Левая\n 2 = HMD",
    ["Remove All Reflective Glass from Map"] = "Удалить все отражающие стёкла с карты",
    ["Reset Render Target Multipliers to Default"] = "Сбросить множители целей рендеринга",
    ["Render Target Width Multiplier"] = "Множитель ширины цели рендеринга",
    ["Render Target Height Multiplier"] = "Множитель высоты цели рендеринга",
    ["VRMod Optimization Level"] = "Уровень оптимизации VRMod",
    ["Custom Width & Height (Quest 2 / Virtual Desktop)"] = "Своя ширина и высота (Quest 2 / Virtual Desktop)",
    ["Emergency Stop Key:"] = "Клавиша аварийной остановки:",
    ["Enable Developer Mode (requires VRMod restart)"] = "Включить режим разработчика (требуется перезапуск VRMod)",
    ["Developer Mode enables advanced debug settings.\nToggle this and restart VRMod to apply changes."] = "Режим разработчика включает расширенные настройки отладки.\nПереключите и перезапустите VRMod для применения.",
    ["Input Mode:"] = "Режим ввода:",
    ["Enable Input Emulation (vrmod_unoff_input_emu)"] = "Включить эмуляцию ввода (vrmod_unoff_input_emu)",
    ["Enable C++ Engine Injection (vrmod_unoff_cpp_keyinject)"] = "Включить инъекцию движка C++ (vrmod_unoff_cpp_keyinject)",
    ["Always Auto-Detect Resolution on VR Start"] = "Всегда определять разрешение при запуске VR",
    ["Net Delay"] = "Сетевая задержка",
    ["Net Delay Max"] = "Макс. сетевая задержка",
    ["Net Stored Frames"] = "Сохранённые сетевые кадры",
    ["Net Tickrate"] = "Сетевой тикрейт",
    ["Position X"] = "Позиция X",
    ["Position Y"] = "Позиция Y",
    ["Position Z"] = "Позиция Z",
    ["<< Tree View"] = "<< Дерево",
    [">> Guide View"] = ">> Руководство",
    ["Emergency Stop"] = "Аварийная остановка",
    ["VR Commands"] = "Команды VR",
    ["VR Magazine System"] = "Система VR-магазинов",

    -- Help text
    ["Show/hide the virtual keyboard for text input in VR"] = "Показать/скрыть виртуальную клавиатуру для ввода текста в VR",
    ["Configure VR controller bindings (Note: Disabled while VR is active)"] = "Настроить привязки VR-контроллера (Примечание: отключено при активном VR)",
    ["WARNING: Changing these settings requires VR restart to take effect"] = "ВНИМАНИЕ: Изменение этих настроек требует перезапуска VR",
    ["Automatically detect and set optimal screen resolution when entering VR"] = "Автоматически определять и устанавливать оптимальное разрешение при входе в VR",
    ["Manually trigger optimization based on current vrmod_gmod_optimization level"] = "Вручную запустить оптимизацию на основе текущего уровня vrmod_gmod_optimization",
    ["Forcibly removes all reflective surfaces from the map (may cause visual glitches)"] = "Принудительно удаляет все отражающие поверхности с карты (возможны визуальные артефакты)",
    ["Reset VR render targets (VR mode will exit)"] = "Сбросить цели рендеринга VR (режим VR завершится)",
    ["Update render targets with current multiplier settings"] = "Обновить цели рендеринга с текущими множителями",
    ["Set optimal render target multipliers for Quest 2 + Virtual Desktop (VR will restart)"] = "Установить оптимальные множители для Quest 2 + Virtual Desktop (VR перезапустится)",
    ["Reset both multipliers to default value (2.0)"] = "Сбросить оба множителя до значения по умолчанию (2.0)",
    ["Visualize collision boxes, playspace boundaries, and network traffic"] = "Визуализировать коллизии, границы игрового пространства и сетевой трафик",
    ["Display all connected VR tracking devices and FBT status"] = "Показать все подключённые устройства VR-отслеживания и статус FBT",
    ["Alternative VR mode using phone sensors (no HMD required)"] = "Альтернативный VR через датчики телефона (HMD не требуется)",
    ["Alternative VR mode using phone sensors (for testing without HMD)"] = "Альтернативный VR через датчики телефона (для тестирования без HMD)",
    ["VRE addon must be installed for these commands to work"] = "Для работы этих команд необходим аддон VRE",

    -- Vehicle panel
    ["Main Mode\n(On-Foot)"] = "Основной режим\n(пешком)",
    ["Driving Mode\n(Vehicle)"] = "Режим вождения\n(транспорт)",
    ["Both Modes\n(Main + Driving)"] = "Оба режима\n(основной + вождение)",
    ["Auto Mode\n(Restore)"] = "Автоматический режим\n(восстановление)",
    ["Use main controller bindings (on-foot controls)"] = "Основные привязки контроллера (пешие элементы управления)",
    ["Use driving controller bindings (vehicle controls)"] = "Привязки вождения (элементы управления транспортом)",
    ["Use both main and driving bindings simultaneously"] = "Использовать обе привязки одновременно",
    ["LVS Networked Mode (1 = multiplayer, 0 = singleplayer)"] = "Сетевой режим LVS (1 = мультиплеер, 0 = одиночная)",
    ["LFS Mode"] = "Режим LFS",
    ["SimfPhys Mode"] = "Режим SimfPhys",
    ["[Auto Seat Reset] Disable seat mode when entering vehicle"] = "[Автосброс сиденья] Отключить режим сиденья при посадке в транспорт",

    -- VRModL code-key buttons
    ["btn_restore_defaults"] = "Восстановить настройки по умолчанию",

    -- Optimization description
    ["Optimization Levels:\n0: No optimization applied\n1: No changes - VRMod does not modify any ConVars\n2: Reset - Restores water reflections, disables mirror optimization\n3: Optimization ON - Water/mirrors/specular OFF, gmod_mcore_test 0 (VR safe)\n4: Max optimization - All of Lv3 + gmod_mcore_test 1 (!!Right eye flash WARNING!!)"] = "Уровни оптимизации:\n0: Оптимизация не применена\n1: Без изменений - VRMod не изменяет ConVar\n2: Сброс - Восстановление отражений воды, отключение оптимизации зеркал\n3: Оптимизация ВКЛ - Вода/зеркала/блеск ВЫКЛ, gmod_mcore_test 0 (безопасно для VR)\n4: Макс. оптимизация - Всё из Ур.3 + gmod_mcore_test 1 (!!ВНИМАНИЕ: вспышка правого глаза!!)",
})

-- ============================================================================
-- vrmod_add_keyboard.lua strings
-- ============================================================================
AddSettings("ja", {
    ["Mode: Text Input"] = "モード: テキスト入力",
    ["Mode: Key Inject"] = "モード: キー入力",
    ["Mode: Assignment"] = "モード: 割り当て",
    ["[Key Inject]"] = "[キー入力]",
    ["[Text Input]"] = "[テキスト入力]",
    ["[Full Keyboard >>]"] = "[フルキーボード >>]",
    ["[Inject]"] = "[入力]",
    ["[Input]"] = "[テキスト]",
    ["[Assign]"] = "[割り当て]",
    ["[Page 1: Keys]"] = "[ページ1: キー]",
    ["[Page 2: Symbols]"] = "[ページ2: 記号]",
    ["[<< Classic]"] = "[<< クラシック]",
    ["Capture cancelled. Click a key to assign."] = "キャプチャがキャンセルされました。キーをクリックして割り当ててください。",
    ["Click a key to assign a VR controller action."] = "キーをクリックしてVRコントローラーアクションを割り当ててください。",
})
AddSettings("zh", {
    ["Mode: Text Input"] = "模式: 文本输入",
    ["Mode: Key Inject"] = "模式: 按键注入",
    ["Mode: Assignment"] = "模式: 分配",
    ["[Key Inject]"] = "[按键注入]",
    ["[Text Input]"] = "[文本输入]",
    ["[Full Keyboard >>]"] = "[完整键盘 >>]",
    ["[Inject]"] = "[注入]",
    ["[Input]"] = "[输入]",
    ["[Assign]"] = "[分配]",
    ["[Page 1: Keys]"] = "[页面1: 按键]",
    ["[Page 2: Symbols]"] = "[页面2: 符号]",
    ["[<< Classic]"] = "[<< 经典]",
    ["Capture cancelled. Click a key to assign."] = "捕获已取消。点击按键进行分配。",
    ["Click a key to assign a VR controller action."] = "点击按键分配VR控制器动作。",
})
AddSettings("ru", {
    ["Mode: Text Input"] = "Режим: Ввод текста",
    ["Mode: Key Inject"] = "Режим: Инъекция клавиш",
    ["Mode: Assignment"] = "Режим: Назначение",
    ["[Key Inject]"] = "[Инъекция]",
    ["[Text Input]"] = "[Ввод текста]",
    ["[Full Keyboard >>]"] = "[Полная клавиатура >>]",
    ["[Inject]"] = "[Инъекция]",
    ["[Input]"] = "[Ввод]",
    ["[Assign]"] = "[Назначить]",
    ["[Page 1: Keys]"] = "[Стр.1: Клавиши]",
    ["[Page 2: Symbols]"] = "[Стр.2: Символы]",
    ["[<< Classic]"] = "[<< Классика]",
    ["Capture cancelled. Click a key to assign."] = "Захват отменён. Нажмите клавишу для назначения.",
    ["Click a key to assign a VR controller action."] = "Нажмите клавишу, чтобы назначить действие VR-контроллера.",
})

-- ============================================================================
-- vrmod_quickmenu_editor.lua strings
-- ============================================================================
AddSettings("ja", {
    ["Enable Custom Quick Menu"] = "カスタムクイックメニューを有効化",
    ["Menu Items:"] = "メニューアイテム:",
    ["Add"] = "追加",
    ["Edit"] = "編集",
    ["Delete"] = "削除",
    ["Save"] = "保存",
    ["Reload"] = "再読込",
    ["Preview (6x10 Grid):"] = "プレビュー (6x10 グリッド):",
    ["Edit Item"] = "アイテム編集",
    ["Add Item"] = "アイテム追加",
    ["Name:"] = "名前:",
    ["Action Type:"] = "アクション種別:",
    ["Action Value:"] = "アクション値:",
    ["Cancel"] = "キャンセル",
    ["Quick Menu config saved!"] = "クイックメニュー設定を保存しました！",
    ["Failed to save config!"] = "設定の保存に失敗しました！",
    ["Name and Action Value are required!"] = "名前とアクション値は必須です！",
    ["Quick Menu Editor"] = "クイックメニューエディタ",
})
AddSettings("zh", {
    ["Enable Custom Quick Menu"] = "启用自定义快捷菜单",
    ["Menu Items:"] = "菜单项:",
    ["Add"] = "添加",
    ["Edit"] = "编辑",
    ["Delete"] = "删除",
    ["Save"] = "保存",
    ["Reload"] = "重新加载",
    ["Preview (6x10 Grid):"] = "预览 (6x10 网格):",
    ["Edit Item"] = "编辑项目",
    ["Add Item"] = "添加项目",
    ["Name:"] = "名称:",
    ["Action Type:"] = "动作类型:",
    ["Action Value:"] = "动作值:",
    ["Cancel"] = "取消",
    ["Quick Menu config saved!"] = "快捷菜单配置已保存！",
    ["Failed to save config!"] = "保存配置失败！",
    ["Name and Action Value are required!"] = "名称和动作值为必填项！",
    ["Quick Menu Editor"] = "快捷菜单编辑器",
})
AddSettings("ru", {
    ["Enable Custom Quick Menu"] = "Включить пользовательское быстрое меню",
    ["Menu Items:"] = "Пункты меню:",
    ["Add"] = "Добавить",
    ["Edit"] = "Редактировать",
    ["Delete"] = "Удалить",
    ["Save"] = "Сохранить",
    ["Reload"] = "Перезагрузить",
    ["Preview (6x10 Grid):"] = "Предпросмотр (сетка 6x10):",
    ["Edit Item"] = "Редактировать",
    ["Add Item"] = "Добавить",
    ["Name:"] = "Имя:",
    ["Action Type:"] = "Тип действия:",
    ["Action Value:"] = "Значение действия:",
    ["Cancel"] = "Отмена",
    ["Quick Menu config saved!"] = "Конфигурация быстрого меню сохранена!",
    ["Failed to save config!"] = "Не удалось сохранить конфигурацию!",
    ["Name and Action Value are required!"] = "Имя и значение действия обязательны!",
    ["Quick Menu Editor"] = "Редактор быстрого меню",
})

-- ============================================================================
-- vrmod_input_emu_keyboard_ui.lua strings
-- ============================================================================
AddSettings("ja", {
    ["VR Key Assignment Editor"] = "VRキー割り当てエディタ",
    ["Enable Input Emulation"] = "入力エミュレーション有効化",
    ["C++ Engine Injection"] = "C++エンジンインジェクション",
    ["Clear All"] = "全てクリア",
    ["Sure? Click!"] = "本当に？クリック！",
    ["All key assignments cleared."] = "全てのキー割り当てをクリアしました。",
    ["Click 'Sure? Click!' again to clear all, or click elsewhere to cancel."] = "もう一度「本当に？クリック！」を押して全クリア、他の場所をクリックでキャンセル。",
    ["Clear cancelled."] = "クリアがキャンセルされました。",
    ["Reset Defaults"] = "デフォルトにリセット",
    ["Key assignments reset to defaults."] = "キー割り当てをデフォルトにリセットしました。",
    ["Click 'Sure? Click!' again to reset to defaults, or click elsewhere to cancel."] = "もう一度「本当に？クリック！」を押してデフォルトにリセット、他の場所をクリックでキャンセル。",
    ["Reset cancelled."] = "リセットがキャンセルされました。",
    ["Auto Assign"] = "自動割り当て",
    ["Click 'Sure? Click!' again to auto-assign from current keybinds."] = "もう一度「本当に？クリック！」を押して現在のキーバインドから自動割り当て。",
    ["Auto assign cancelled."] = "自動割り当てがキャンセルされました。",
    ["Close"] = "閉じる",
    ["Assign new action..."] = "新しいアクションを割り当て...",
})
AddSettings("zh", {
    ["VR Key Assignment Editor"] = "VR按键分配编辑器",
    ["Enable Input Emulation"] = "启用输入模拟",
    ["C++ Engine Injection"] = "C++引擎注入",
    ["Clear All"] = "清除全部",
    ["Sure? Click!"] = "确定？点击！",
    ["All key assignments cleared."] = "所有按键分配已清除。",
    ["Click 'Sure? Click!' again to clear all, or click elsewhere to cancel."] = "再次点击「确定？点击！」清除全部，点击其他地方取消。",
    ["Clear cancelled."] = "清除已取消。",
    ["Reset Defaults"] = "重置默认",
    ["Key assignments reset to defaults."] = "按键分配已重置为默认。",
    ["Click 'Sure? Click!' again to reset to defaults, or click elsewhere to cancel."] = "再次点击「确定？点击！」重置为默认，点击其他地方取消。",
    ["Reset cancelled."] = "重置已取消。",
    ["Auto Assign"] = "自动分配",
    ["Click 'Sure? Click!' again to auto-assign from current keybinds."] = "再次点击「确定？点击！」从当前键位自动分配。",
    ["Auto assign cancelled."] = "自动分配已取消。",
    ["Close"] = "关闭",
    ["Assign new action..."] = "分配新动作...",
})
AddSettings("ru", {
    ["VR Key Assignment Editor"] = "Редактор назначений VR-клавиш",
    ["Enable Input Emulation"] = "Включить эмуляцию ввода",
    ["C++ Engine Injection"] = "Инъекция через C++ движок",
    ["Clear All"] = "Очистить всё",
    ["Sure? Click!"] = "Уверены? Жмите!",
    ["All key assignments cleared."] = "Все назначения клавиш очищены.",
    ["Click 'Sure? Click!' again to clear all, or click elsewhere to cancel."] = "Нажмите «Уверены? Жмите!» ещё раз, чтобы очистить всё, или нажмите в другом месте для отмены.",
    ["Clear cancelled."] = "Очистка отменена.",
    ["Reset Defaults"] = "Сбросить по умолчанию",
    ["Key assignments reset to defaults."] = "Назначения клавиш сброшены по умолчанию.",
    ["Click 'Sure? Click!' again to reset to defaults, or click elsewhere to cancel."] = "Нажмите «Уверены? Жмите!» ещё раз для сброса, или нажмите в другом месте для отмены.",
    ["Reset cancelled."] = "Сброс отменён.",
    ["Auto Assign"] = "Автоназначение",
    ["Click 'Sure? Click!' again to auto-assign from current keybinds."] = "Нажмите «Уверены? Жмите!» ещё раз для автоназначения из текущих привязок.",
    ["Auto assign cancelled."] = "Автоназначение отменено.",
    ["Close"] = "Закрыть",
    ["Assign new action..."] = "Назначить новое действие...",
})

-- ============================================================================
-- vrmod_add_presetmenu.lua / vrmod_presetcreater.lua strings
-- ============================================================================
AddSettings("ja", {
    ["Save Preset"] = "プリセットを保存",
    ["Load Preset"] = "プリセットを読み込み",
    ["Delete Preset"] = "プリセットを削除",
})
AddSettings("zh", {
    ["Save Preset"] = "保存预设",
    ["Load Preset"] = "加载预设",
    ["Delete Preset"] = "删除预设",
})
AddSettings("ru", {
    ["Save Preset"] = "Сохранить пресет",
    ["Load Preset"] = "Загрузить пресет",
    ["Delete Preset"] = "Удалить пресет",
})

-- ============================================================================
-- vrmod_locomotion_*.lua strings
-- ============================================================================
AddSettings("ja", {
    ["Controller oriented locomotion"] = "コントローラー方向ベースの移動",
    ["Smooth turning"] = "スムーズターン",
    ["Smooth turn rate"] = "スムーズターン速度",
})
AddSettings("zh", {
    ["Controller oriented locomotion"] = "手柄朝向移动",
    ["Smooth turning"] = "平滑转向",
    ["Smooth turn rate"] = "平滑转向速度",
})
AddSettings("ru", {
    ["Controller oriented locomotion"] = "Ориентация движения по контроллеру",
    ["Smooth turning"] = "Плавный поворот",
    ["Smooth turn rate"] = "Скорость плавного поворота",
})

-- ============================================================================
-- vrmod_lua_keybinding.lua strings
-- ============================================================================
AddSettings("ja", {
    ["VR not active"] = "VR非アクティブ",
    ["Input Mode:"] = "入力モード:",
    ["Physical Input"] = "物理入力",
    ["Mapped To (Game Action)"] = "マッピング先 (ゲームアクション)",
})
AddSettings("zh", {
    ["VR not active"] = "VR未激活",
    ["Input Mode:"] = "输入模式:",
    ["Physical Input"] = "物理输入",
    ["Mapped To (Game Action)"] = "映射到 (游戏动作)",
})
AddSettings("ru", {
    ["VR not active"] = "VR не активен",
    ["Input Mode:"] = "Режим ввода:",
    ["Physical Input"] = "Физический ввод",
    ["Mapped To (Game Action)"] = "Привязано к (игровое действие)",
})

-- ============================================================================
-- vrmod_menu.lua strings
-- ============================================================================
AddSettings("ja", {
    ["Module not installed.\n1. Go to garrysmod/data/vrmod_module/\n2. Rename install.txt -> install.bat\n3. Run install.bat, then restart Gmod"] = "モジュール未インストール\n1. garrysmod/data/vrmod_module/ を開く\n2. install.txt を install.bat にリネーム\n3. install.bat を実行し、Gmodを再起動",
    ["Open Module Folder"] = "モジュールフォルダを開く",
    ["Exit"] = "終了",
})
AddSettings("zh", {
    ["Module not installed.\n1. Go to garrysmod/data/vrmod_module/\n2. Rename install.txt -> install.bat\n3. Run install.bat, then restart Gmod"] = "模块未安装\n1. 前往 garrysmod/data/vrmod_module/\n2. 将 install.txt 重命名为 install.bat\n3. 运行 install.bat，然后重启Gmod",
    ["Open Module Folder"] = "打开模块文件夹",
    ["Exit"] = "退出",
})
AddSettings("ru", {
    ["Module not installed.\n1. Go to garrysmod/data/vrmod_module/\n2. Rename install.txt -> install.bat\n3. Run install.bat, then restart Gmod"] = "Модуль не установлен\n1. Перейдите в garrysmod/data/vrmod_module/\n2. Переименуйте install.txt в install.bat\n3. Запустите install.bat, перезапустите Gmod",
    ["Open Module Folder"] = "Открыть папку модуля",
    ["Exit"] = "Выход",
})

-- ============================================================================
-- vrmod_muzzle_bone_override.lua strings
-- ============================================================================
AddSettings("ja", {
    ["Configure bone overrides for this weapon. Laser pointer shows muzzle direction."] = "この武器のボーンオーバーライドを設定します。レーザーポインターがマズル方向を表示します。",
})
AddSettings("zh", {
    ["Configure bone overrides for this weapon. Laser pointer shows muzzle direction."] = "配置此武器的骨骼覆盖。激光指示器显示枪口方向。",
})
AddSettings("ru", {
    ["Configure bone overrides for this weapon. Laser pointer shows muzzle direction."] = "Настроить переопределения костей для этого оружия. Лазерный указатель показывает направление дула.",
})

-- ============================================================================
-- vrmod_viewmodelinfo.lua strings
-- ============================================================================
AddSettings("ja", {
    ["New"] = "新規",
    ["Reset Current Weapon"] = "現在の武器をリセット",
    ["Tip: Drag slider labels for fine adjustment"] = "ヒント: スライダーラベルをドラッグして微調整",
    ["Offset Position:"] = "オフセット位置:",
    ["Offset Angle:"] = "オフセット角度:",
    ["Auto Adjust"] = "自動調整",
    ["Reset to Zero"] = "ゼロにリセット",
    ["Apply"] = "適用",
})
AddSettings("zh", {
    ["New"] = "新建",
    ["Reset Current Weapon"] = "重置当前武器",
    ["Tip: Drag slider labels for fine adjustment"] = "提示: 拖动滑块标签进行微调",
    ["Offset Position:"] = "偏移位置:",
    ["Offset Angle:"] = "偏移角度:",
    ["Auto Adjust"] = "自动调整",
    ["Reset to Zero"] = "重置为零",
    ["Apply"] = "应用",
})
AddSettings("ru", {
    ["New"] = "Новый",
    ["Reset Current Weapon"] = "Сбросить текущее оружие",
    ["Tip: Drag slider labels for fine adjustment"] = "Совет: перетаскивайте метки слайдеров для точной настройки",
    ["Offset Position:"] = "Смещение позиции:",
    ["Offset Angle:"] = "Смещение угла:",
    ["Auto Adjust"] = "Автоподбор",
    ["Reset to Zero"] = "Сбросить в ноль",
    ["Apply"] = "Применить",
})

-- ============================================================================
-- vrmod_addononly_menu.lua strings
-- ============================================================================
AddSettings("ja", {
    ["Addon-Only Mode Active"] = "アドオン専用モード有効",
    ["Root files are not loaded. Using external VRMod as base."] = "ルートファイルは読み込まれていません。外部VRModをベースとして使用中。",
    ["Changes require Gmod restart to take effect."] = "変更を反映するにはGmodの再起動が必要です。",
    ["Disable Addon-Only Mode (requires restart)"] = "アドオン専用モードを無効化 (再起動が必要)",
})
AddSettings("zh", {
    ["Addon-Only Mode Active"] = "仅插件模式已激活",
    ["Root files are not loaded. Using external VRMod as base."] = "根文件未加载。使用外部VRMod作为基础。",
    ["Changes require Gmod restart to take effect."] = "更改需要重启Gmod才能生效。",
    ["Disable Addon-Only Mode (requires restart)"] = "禁用仅插件模式 (需要重启)",
})
AddSettings("ru", {
    ["Addon-Only Mode Active"] = "Режим только аддонов активен",
    ["Root files are not loaded. Using external VRMod as base."] = "Корневые файлы не загружены. Используется внешний VRMod как база.",
    ["Changes require Gmod restart to take effect."] = "Изменения требуют перезапуска Gmod.",
    ["Disable Addon-Only Mode (requires restart)"] = "Отключить режим только аддонов (требуется перезапуск)",
})

-- ============================================================================
-- vrmod_clipboard.lua strings
-- ============================================================================
AddSettings("ja", {
    ["VR Clipboard"] = "VRクリップボード",
    ["Saved Items"] = "保存済みアイテム",
})
AddSettings("zh", {
    ["VR Clipboard"] = "VR剪贴板",
    ["Saved Items"] = "已保存项目",
})
AddSettings("ru", {
    ["VR Clipboard"] = "VR-буфер обмена",
    ["Saved Items"] = "Сохранённые элементы",
})

-- ============================================================================
-- vrmod_mapbrowser.lua strings
-- ============================================================================
AddSettings("ja", {
    ["Start Game"] = "ゲーム開始",
})
AddSettings("zh", {
    ["Start Game"] = "开始游戏",
})
AddSettings("ru", {
    ["Start Game"] = "Начать игру",
})

-- ============================================================================
-- vrmod.lua / vrmod_api.lua strings
-- ============================================================================
AddSettings("ja", {
    ["Desktop view:"] = "デスクトップ表示:",
    ["Locomotion:"] = "移動方式:",
})
AddSettings("zh", {
    ["Desktop view:"] = "桌面视图:",
    ["Locomotion:"] = "移动方式:",
})
AddSettings("ru", {
    ["Desktop view:"] = "Вид рабочего стола:",
    ["Locomotion:"] = "Передвижение:",
})

-- ============================================================================
-- vrmod_ui_weaponselect.lua strings
-- ============================================================================
AddSettings("ja", {
    ["HEALTH"] = "体力",
    ["SUIT"] = "スーツ",
    ["AMMO"] = "弾薬",
    ["ALT"] = "予備",
})
AddSettings("zh", {
    ["HEALTH"] = "生命",
    ["SUIT"] = "护甲",
    ["AMMO"] = "弹药",
    ["ALT"] = "备用",
})
AddSettings("ru", {
    ["HEALTH"] = "ЗДОРОВЬЕ",
    ["SUIT"] = "БРОНЯ",
    ["AMMO"] = "ПАТРОНЫ",
    ["ALT"] = "ДОП.",
})

-- ============================================================================
-- Phase 5: draw text strings (fps_guard, clipboard, wizard)
-- ============================================================================
AddSettings("ja", {
    ["[VR FPS Guard] \n Gmod window is not focused \n disable -> [vrmod_unoff_fps_guard_focus 0]"] = "[VR FPS Guard] \n Gmodウィンドウがフォーカスされていません \n 無効化 -> [vrmod_unoff_fps_guard_focus 0]",
    ["(no saved items)"] = "(保存済みアイテムなし)",
    ["Step"] = "ステップ",
    ["Setup Complete!"] = "セットアップ完了！",
})
AddSettings("zh", {
    ["[VR FPS Guard] \n Gmod window is not focused \n disable -> [vrmod_unoff_fps_guard_focus 0]"] = "[VR FPS Guard] \n Gmod窗口未获得焦点 \n 禁用 -> [vrmod_unoff_fps_guard_focus 0]",
    ["(no saved items)"] = "(无已保存项目)",
    ["Step"] = "步骤",
    ["Setup Complete!"] = "设置完成！",
})
AddSettings("ru", {
    ["[VR FPS Guard] \n Gmod window is not focused \n disable -> [vrmod_unoff_fps_guard_focus 0]"] = "[VR FPS Guard] \n Окно Gmod не в фокусе \n отключить -> [vrmod_unoff_fps_guard_focus 0]",
    ["(no saved items)"] = "(нет сохранённых элементов)",
    ["Step"] = "Шаг",
    ["Setup Complete!"] = "Настройка завершена!",
})

-- ========================================
-- Phase 6: Remaining UI strings (vrmod.lua, holstermenu, tabs, scattered)
-- ========================================

-- vrmod.lua settings panel
AddSettings("ja", {
    ["Use floating hands"] = "フローティングハンドを使用",
    ["  No PM sync (keep PM animations)"] = "  PMモデル同期なし（PMアニメーション維持）",
    ["Use weapon world models"] = "武器ワールドモデルを使用",
    ["Add laser pointer to tools/weapons"] = "ツール/武器にレーザーポインターを追加",
    ["Show height adjustment menu"] = "身長調整メニューを表示",
    ["Alternative head angle manipulation method"] = "代替頭部角度操作方式",
    ["Less precise, compatibility for jigglebones"] = "精度は低いが、ジグルボーン互換性あり",
    ["Automatically start VR after map loads"] = "マップ読み込み後にVRを自動開始",
    ["Replace door use mechanics (when available)"] = "ドア使用メカニクスを置換（利用可能時）",
    ["Enable engine postprocessing"] = "エンジンポストプロセッシングを有効化",
    ["none"] = "なし",
    ["left eye"] = "左目",
    ["right eye"] = "右目",
    ["Edit custom controller input actions"] = "カスタムコントローラー入力アクションを編集",
    ["Reset settings to default"] = "設定をデフォルトにリセット",
    ["Controller offsets"] = "コントローラーオフセット",
    ["Apply offsets"] = "オフセットを適用",
})
AddSettings("zh", {
    ["Use floating hands"] = "使用浮动手部",
    ["  No PM sync (keep PM animations)"] = "  不同步PM模型（保持PM动画）",
    ["Use weapon world models"] = "使用武器世界模型",
    ["Add laser pointer to tools/weapons"] = "为工具/武器添加激光指示器",
    ["Show height adjustment menu"] = "显示身高调整菜单",
    ["Alternative head angle manipulation method"] = "替代头部角度操控方式",
    ["Less precise, compatibility for jigglebones"] = "精度较低，但兼容骨骼晃动",
    ["Automatically start VR after map loads"] = "地图加载后自动启动VR",
    ["Replace door use mechanics (when available)"] = "替换门使用机制（可用时）",
    ["Enable engine postprocessing"] = "启用引擎后处理",
    ["none"] = "无",
    ["left eye"] = "左眼",
    ["right eye"] = "右眼",
    ["Edit custom controller input actions"] = "编辑自定义控制器输入动作",
    ["Reset settings to default"] = "重置为默认设置",
    ["Controller offsets"] = "控制器偏移",
    ["Apply offsets"] = "应用偏移",
})
AddSettings("ru", {
    ["Use floating hands"] = "Плавающие руки",
    ["  No PM sync (keep PM animations)"] = "  Без синхронизации PM (сохранить анимации PM)",
    ["Use weapon world models"] = "Мировые модели оружия",
    ["Add laser pointer to tools/weapons"] = "Лазерный указатель для инструментов/оружия",
    ["Show height adjustment menu"] = "Показать меню настройки роста",
    ["Alternative head angle manipulation method"] = "Альтернативный метод управления углом головы",
    ["Less precise, compatibility for jigglebones"] = "Менее точный, совместимость с jigglebones",
    ["Automatically start VR after map loads"] = "Автозапуск VR после загрузки карты",
    ["Replace door use mechanics (when available)"] = "Замена механики дверей (если доступно)",
    ["Enable engine postprocessing"] = "Включить постобработку движка",
    ["none"] = "нет",
    ["left eye"] = "левый глаз",
    ["right eye"] = "правый глаз",
    ["Edit custom controller input actions"] = "Редактировать пользовательские действия ввода",
    ["Reset settings to default"] = "Сбросить настройки по умолчанию",
    ["Controller offsets"] = "Смещения контроллера",
    ["Apply offsets"] = "Применить смещения",
})

-- Holster menu (Type2)
AddSettings("ja", {
    ["Type2"] = "Type2",
    ["Type2 Holster Settings"] = "Type2ホルスター設定",
    ["=== Basic Settings ==="] = "=== 基本設定 ===",
    ["System Enable"] = "システム有効化",
    ["Visible Name"] = "名前表示",
    ["Visible HUD"] = "HUD表示",
    ["Left Hand Weapon Enable"] = "左手武器を有効化",
    ["L/R Sync Mode (share slots between hands)"] = "左右同期モード（スロット共有）",
    ["Pickup Sound"] = "ピックアップ音",
    ["=== Release / Tediore ==="] = "=== リリース / テディオール ===",
    ["[release -> Emptyhand] Enable"] = "[リリース → 素手] 有効化",
    ["[Tediore like reload] Enable"] = "[テディオール式リロード] 有効化",
    ["Trash Weapon on Drop"] = "ドロップ時に武器を破棄",
    ["=== Dupe Settings ==="] = "=== デュプリケート設定 ===",
    ["Reusable Dupe (infinite retrieve)"] = "再利用可能デュプリケート（無限取り出し）",
    ["Enable"] = "有効化",
    ["Weapon/Entity (Read-only)"] = "武器/エンティティ（読み取り専用）",
    ["Left Hand Weapon (Read-only)"] = "左手武器（読み取り専用）",
    ["Sphere Size"] = "球体サイズ",
    ["Shape"] = "形状",
    ["sphere"] = "球体",
    ["box"] = "ボックス",
    ["Box Width (X)"] = "ボックス幅 (X)",
    ["Box Height (Y)"] = "ボックス高さ (Y)",
    ["Box Depth Up (Z+)"] = "ボックス深さ上 (Z+)",
    ["Box Depth Down (Z-)"] = "ボックス深さ下 (Z-)",
})
AddSettings("zh", {
    ["Type2"] = "Type2",
    ["Type2 Holster Settings"] = "Type2枪套设置",
    ["=== Basic Settings ==="] = "=== 基本设置 ===",
    ["System Enable"] = "系统启用",
    ["Visible Name"] = "显示名称",
    ["Visible HUD"] = "显示HUD",
    ["Left Hand Weapon Enable"] = "启用左手武器",
    ["L/R Sync Mode (share slots between hands)"] = "左右同步模式（共享槽位）",
    ["Pickup Sound"] = "拾取音效",
    ["=== Release / Tediore ==="] = "=== 释放 / Tediore ===",
    ["[release -> Emptyhand] Enable"] = "[释放 → 空手] 启用",
    ["[Tediore like reload] Enable"] = "[Tediore式换弹] 启用",
    ["Trash Weapon on Drop"] = "丢弃时销毁武器",
    ["=== Dupe Settings ==="] = "=== 复制设置 ===",
    ["Reusable Dupe (infinite retrieve)"] = "可重复使用复制（无限取回）",
    ["Enable"] = "启用",
    ["Weapon/Entity (Read-only)"] = "武器/实体（只读）",
    ["Left Hand Weapon (Read-only)"] = "左手武器（只读）",
    ["Sphere Size"] = "球体大小",
    ["Shape"] = "形状",
    ["sphere"] = "球体",
    ["box"] = "方盒",
    ["Box Width (X)"] = "方盒宽度 (X)",
    ["Box Height (Y)"] = "方盒高度 (Y)",
    ["Box Depth Up (Z+)"] = "方盒深度上 (Z+)",
    ["Box Depth Down (Z-)"] = "方盒深度下 (Z-)",
})
AddSettings("ru", {
    ["Type2"] = "Type2",
    ["Type2 Holster Settings"] = "Настройки кобуры Type2",
    ["=== Basic Settings ==="] = "=== Основные настройки ===",
    ["System Enable"] = "Включить систему",
    ["Visible Name"] = "Показывать имя",
    ["Visible HUD"] = "Показывать HUD",
    ["Left Hand Weapon Enable"] = "Оружие в левой руке",
    ["L/R Sync Mode (share slots between hands)"] = "Синхронизация Л/П (общие слоты)",
    ["Pickup Sound"] = "Звук подбора",
    ["=== Release / Tediore ==="] = "=== Отпускание / Tediore ===",
    ["[release -> Emptyhand] Enable"] = "[отпускание → пустая рука] Вкл.",
    ["[Tediore like reload] Enable"] = "[перезарядка Tediore] Вкл.",
    ["Trash Weapon on Drop"] = "Уничтожить оружие при сбросе",
    ["=== Dupe Settings ==="] = "=== Настройки дупликации ===",
    ["Reusable Dupe (infinite retrieve)"] = "Многоразовый дупликат (бесконечное извлечение)",
    ["Enable"] = "Включить",
    ["Weapon/Entity (Read-only)"] = "Оружие/Объект (только чтение)",
    ["Left Hand Weapon (Read-only)"] = "Оружие левой руки (только чтение)",
    ["Sphere Size"] = "Размер сферы",
    ["Shape"] = "Форма",
    ["sphere"] = "сфера",
    ["box"] = "куб",
    ["Box Width (X)"] = "Ширина (X)",
    ["Box Height (Y)"] = "Высота (Y)",
    ["Box Depth Up (Z+)"] = "Глубина вверх (Z+)",
    ["Box Depth Down (Z-)"] = "Глубина вниз (Z-)",
})

-- Holster menu (Type1 + Display)
AddSettings("ja", {
    ["Type1"] = "Type1",
    ["Right Hand Holster Settings"] = "右手ホルスター設定",
    ["Left Hand Holster Settings"] = "左手ホルスター設定",
    ["=== Pelvis Holster ==="] = "=== 腰ホルスター ===",
    ["Enable Pelvis Holster"] = "腰ホルスターを有効化",
    ["Range"] = "範囲",
    ["Weapon Lock (Read-only)"] = "武器ロック（読み取り専用）",
    ["Stored Weapon (Read-only)"] = "格納中の武器（読み取り専用）",
    ["Enable Custom Command"] = "カスタムコマンドを有効化",
    ["Custom Pickup Command"] = "カスタムピックアップコマンド",
    ["Custom Put Command"] = "カスタムプットコマンド",
    ["=== Head Holster ==="] = "=== 頭部ホルスター ===",
    ["Enable Head Holster"] = "頭部ホルスターを有効化",
    ["=== Spine Holster ==="] = "=== 背中ホルスター ===",
    ["Enable Spine Holster"] = "背中ホルスターを有効化",
    ["=== Pelvis Holster (Left) ==="] = "=== 腰ホルスター（左） ===",
    ["=== Head Holster (Left) ==="] = "=== 頭部ホルスター（左） ===",
    ["=== Spine Holster (Left) ==="] = "=== 背中ホルスター（左） ===",
    ["Display"] = "表示",
    ["Display Settings (Type1/Type2 Common)"] = "表示設定（Type1/Type2共通）",
    ["=== Type1 Display ==="] = "=== Type1 表示 ===",
    ["Visible Range"] = "範囲表示",
    ["Head Visible"] = "頭部表示",
    ["=== Type1 Left Display ==="] = "=== Type1 左手表示 ===",
    ["Visible Range (Left)"] = "範囲表示（左）",
    ["Visible Name (Left)"] = "名前表示（左）",
    ["VRHolster"] = "VRホルスター",
})
AddSettings("zh", {
    ["Type1"] = "Type1",
    ["Right Hand Holster Settings"] = "右手枪套设置",
    ["Left Hand Holster Settings"] = "左手枪套设置",
    ["=== Pelvis Holster ==="] = "=== 腰部枪套 ===",
    ["Enable Pelvis Holster"] = "启用腰部枪套",
    ["Range"] = "范围",
    ["Weapon Lock (Read-only)"] = "武器锁定（只读）",
    ["Stored Weapon (Read-only)"] = "存储的武器（只读）",
    ["Enable Custom Command"] = "启用自定义命令",
    ["Custom Pickup Command"] = "自定义拾取命令",
    ["Custom Put Command"] = "自定义放置命令",
    ["=== Head Holster ==="] = "=== 头部枪套 ===",
    ["Enable Head Holster"] = "启用头部枪套",
    ["=== Spine Holster ==="] = "=== 背部枪套 ===",
    ["Enable Spine Holster"] = "启用背部枪套",
    ["=== Pelvis Holster (Left) ==="] = "=== 腰部枪套（左） ===",
    ["=== Head Holster (Left) ==="] = "=== 头部枪套（左） ===",
    ["=== Spine Holster (Left) ==="] = "=== 背部枪套（左） ===",
    ["Display"] = "显示",
    ["Display Settings (Type1/Type2 Common)"] = "显示设置（Type1/Type2通用）",
    ["=== Type1 Display ==="] = "=== Type1 显示 ===",
    ["Visible Range"] = "显示范围",
    ["Head Visible"] = "显示头部",
    ["=== Type1 Left Display ==="] = "=== Type1 左手显示 ===",
    ["Visible Range (Left)"] = "显示范围（左）",
    ["Visible Name (Left)"] = "显示名称（左）",
    ["VRHolster"] = "VR枪套",
})
AddSettings("ru", {
    ["Type1"] = "Type1",
    ["Right Hand Holster Settings"] = "Настройки кобуры правой руки",
    ["Left Hand Holster Settings"] = "Настройки кобуры левой руки",
    ["=== Pelvis Holster ==="] = "=== Кобура на поясе ===",
    ["Enable Pelvis Holster"] = "Включить кобуру на поясе",
    ["Range"] = "Дальность",
    ["Weapon Lock (Read-only)"] = "Блокировка оружия (только чтение)",
    ["Stored Weapon (Read-only)"] = "Хранимое оружие (только чтение)",
    ["Enable Custom Command"] = "Включить пользовательскую команду",
    ["Custom Pickup Command"] = "Пользовательская команда подбора",
    ["Custom Put Command"] = "Пользовательская команда размещения",
    ["=== Head Holster ==="] = "=== Кобура на голове ===",
    ["Enable Head Holster"] = "Включить кобуру на голове",
    ["=== Spine Holster ==="] = "=== Кобура на спине ===",
    ["Enable Spine Holster"] = "Включить кобуру на спине",
    ["=== Pelvis Holster (Left) ==="] = "=== Кобура на поясе (левая) ===",
    ["=== Head Holster (Left) ==="] = "=== Кобура на голове (левая) ===",
    ["=== Spine Holster (Left) ==="] = "=== Кобура на спине (левая) ===",
    ["Display"] = "Отображение",
    ["Display Settings (Type1/Type2 Common)"] = "Настройки отображения (Type1/Type2 общие)",
    ["=== Type1 Display ==="] = "=== Type1 Отображение ===",
    ["Visible Range"] = "Видимый диапазон",
    ["Head Visible"] = "Голова видима",
    ["=== Type1 Left Display ==="] = "=== Type1 Левая отображение ===",
    ["Visible Range (Left)"] = "Видимый диапазон (левый)",
    ["Visible Name (Left)"] = "Видимое имя (левый)",
    ["VRHolster"] = "VR кобура",
})

-- Slot names (holster Type2)
AddSettings("ja", {
    ["Slot 1 - Head Right"] = "スロット1 - 頭部右",
    ["Slot 2 - Head Left"] = "スロット2 - 頭部左",
    ["Slot 3 - Chest Right"] = "スロット3 - 胸部右",
    ["Slot 4 - Chest Left"] = "スロット4 - 胸部左",
    ["Slot 5 - Chest Center"] = "スロット5 - 胸部中央",
    ["Slot 6 - Pelvis (Bone)"] = "スロット6 - 腰（ボーン）",
    ["Slot 7 - Head (Bone)"] = "スロット7 - 頭部（ボーン）",
    ["Slot 8 - Spine (Bone)"] = "スロット8 - 背骨（ボーン）",
})
AddSettings("zh", {
    ["Slot 1 - Head Right"] = "槽位1 - 头部右",
    ["Slot 2 - Head Left"] = "槽位2 - 头部左",
    ["Slot 3 - Chest Right"] = "槽位3 - 胸部右",
    ["Slot 4 - Chest Left"] = "槽位4 - 胸部左",
    ["Slot 5 - Chest Center"] = "槽位5 - 胸部中央",
    ["Slot 6 - Pelvis (Bone)"] = "槽位6 - 腰部（骨骼）",
    ["Slot 7 - Head (Bone)"] = "槽位7 - 头部（骨骼）",
    ["Slot 8 - Spine (Bone)"] = "槽位8 - 脊柱（骨骼）",
})
AddSettings("ru", {
    ["Slot 1 - Head Right"] = "Слот 1 - Голова справа",
    ["Slot 2 - Head Left"] = "Слот 2 - Голова слева",
    ["Slot 3 - Chest Right"] = "Слот 3 - Грудь справа",
    ["Slot 4 - Chest Left"] = "Слот 4 - Грудь слева",
    ["Slot 5 - Chest Center"] = "Слот 5 - Грудь по центру",
    ["Slot 6 - Pelvis (Bone)"] = "Слот 6 - Таз (кость)",
    ["Slot 7 - Head (Bone)"] = "Слот 7 - Голова (кость)",
    ["Slot 8 - Spine (Bone)"] = "Слот 8 - Позвоночник (кость)",
})

-- Tab names + misc UI
AddSettings("ja", {
    ["Settings"] = "設定",
    ["Settings02"] = "設定02",
    ["Addons"] = "アドオン",
    ["On Foot"] = "歩行時",
    ["In Vehicle"] = "乗車時",
    ["Muzzle"] = "マズル",
    ["Foregrip"] = "フォアグリップ",
    ["Magazine"] = "マガジン",
    ["VRMOD MENU"] = "VRMODメニュー",
    ["Enable HUD"] = "HUDを有効化",
    ["Enable SRanipal"] = "SRanipalを有効化",
    ["For Vive Pro Eye / Vive Facial Tracker"] = "Vive Pro Eye / Vive Facial Tracker用",
    ["Enable seated offset"] = "坐姿オフセットを有効化",
    ["Adjust from height adjustment menu"] = "身長調整メニューから調整",
})
AddSettings("zh", {
    ["Settings"] = "设置",
    ["Settings02"] = "设置02",
    ["Addons"] = "插件",
    ["On Foot"] = "步行时",
    ["In Vehicle"] = "乘车时",
    ["Muzzle"] = "枪口",
    ["Foregrip"] = "前握把",
    ["Magazine"] = "弹匣",
    ["VRMOD MENU"] = "VRMOD菜单",
    ["Enable HUD"] = "启用HUD",
    ["Enable SRanipal"] = "启用SRanipal",
    ["For Vive Pro Eye / Vive Facial Tracker"] = "适用于Vive Pro Eye / Vive面部追踪器",
    ["Enable seated offset"] = "启用坐姿偏移",
    ["Adjust from height adjustment menu"] = "从身高调整菜单进行调整",
})
AddSettings("ru", {
    ["Settings"] = "Настройки",
    ["Settings02"] = "Настройки02",
    ["Addons"] = "Дополнения",
    ["On Foot"] = "Пешком",
    ["In Vehicle"] = "В транспорте",
    ["Muzzle"] = "Дульный срез",
    ["Foregrip"] = "Передняя рукоять",
    ["Magazine"] = "Магазин",
    ["VRMOD MENU"] = "Меню VRMOD",
    ["Enable HUD"] = "Включить HUD",
    ["Enable SRanipal"] = "Включить SRanipal",
    ["For Vive Pro Eye / Vive Facial Tracker"] = "Для Vive Pro Eye / Vive Facial Tracker",
    ["Enable seated offset"] = "Включить смещение сидя",
    ["Adjust from height adjustment menu"] = "Настройте в меню регулировки роста",
})

-- Quickmenu editor + keyboard binding + modules
AddSettings("ja", {
    ["Up"] = "上へ",
    ["Down"] = "下へ",
    ["Slot (0-5):"] = "スロット (0-5):",
    ["Position (0-9):"] = "位置 (0-9):",
    ["OK"] = "OK",
    ["SteamVR Bindings (Default)"] = "SteamVRバインド（デフォルト）",
    ["Lua Keybinding (Recommended)"] = "Luaキーバインド（推奨）",
    ["(none)"] = "(なし)",
    ["Changes require Gmod restart to take effect."] = "変更はGmodの再起動後に反映されます。",
    ["=== Addon-Only Mode ==="] = "=== アドオン専用モード ===",
    ["Addon-Only Mode (skip root files, use external VRMod)"] = "アドオン専用モード（ルートファイルをスキップ、外部VRModを使用）",
    ["ON = Root files (vrmod.lua, input, character, etc.) are not loaded.\nUse this with legacy/original VRMod as your base VRMod.\nOnly numbered folder modules are loaded as add-on features."] = "ON = ルートファイル（vrmod.lua、入力、キャラクター等）を読み込みません。\nレガシー/オリジナルVRModをベースとして使用してください。\n番号付きフォルダモジュールのみアドオン機能として読み込まれます。",
    ["=== Legacy Mode ==="] = "=== レガシーモード ===",
    ["Legacy Mode (load only core features)"] = "レガシーモード（コア機能のみ読み込み）",
    ["ON = only folders 0 (Core) and 1 (Auto-settings) load.\nAll features below are disabled regardless of their individual setting."] = "ON = フォルダ0（コア）と1（自動設定）のみ読み込み。\n以下の全機能は個別設定に関係なく無効化されます。",
    ["=== Feature Modules ==="] = "=== 機能モジュール ===",
    ["Press a VR controller button to assign to [%s]..."] = "VRコントローラーのボタンを押して [%s] に割り当て...",
    ["Assigned [%s] to [%s]. Click another key or switch mode."] = "[%s] を [%s] に割り当てました。別のキーをクリックするかモードを切り替えてください。",
    ["Removed [%s] from [%s]."] = "[%s] を [%s] から削除しました。",
    ["Remove:"] = "削除:",
    ["Reassign (new capture)"] = "再割り当て（新規キャプチャ）",
})
AddSettings("zh", {
    ["Up"] = "上移",
    ["Down"] = "下移",
    ["Slot (0-5):"] = "槽位 (0-5):",
    ["Position (0-9):"] = "位置 (0-9):",
    ["OK"] = "确定",
    ["SteamVR Bindings (Default)"] = "SteamVR绑定（默认）",
    ["Lua Keybinding (Recommended)"] = "Lua按键绑定（推荐）",
    ["(none)"] = "(无)",
    ["Changes require Gmod restart to take effect."] = "更改需要重启Gmod才能生效。",
    ["=== Addon-Only Mode ==="] = "=== 仅插件模式 ===",
    ["Addon-Only Mode (skip root files, use external VRMod)"] = "仅插件模式（跳过根文件，使用外部VRMod）",
    ["ON = Root files (vrmod.lua, input, character, etc.) are not loaded.\nUse this with legacy/original VRMod as your base VRMod.\nOnly numbered folder modules are loaded as add-on features."] = "ON = 不加载根文件（vrmod.lua、输入、角色等）。\n请将传统/原版VRMod作为基础VRMod使用。\n仅加载编号文件夹模块作为附加功能。",
    ["=== Legacy Mode ==="] = "=== 传统模式 ===",
    ["Legacy Mode (load only core features)"] = "传统模式（仅加载核心功能）",
    ["ON = only folders 0 (Core) and 1 (Auto-settings) load.\nAll features below are disabled regardless of their individual setting."] = "ON = 仅加载文件夹0（核心）和1（自动设置）。\n以下所有功能无论单独设置如何都将被禁用。",
    ["=== Feature Modules ==="] = "=== 功能模块 ===",
    ["Press a VR controller button to assign to [%s]..."] = "按下VR控制器按钮以分配到 [%s]...",
    ["Assigned [%s] to [%s]. Click another key or switch mode."] = "已将 [%s] 分配到 [%s]。点击另一个按键或切换模式。",
    ["Removed [%s] from [%s]."] = "已从 [%s] 移除 [%s]。",
    ["Remove:"] = "移除:",
    ["Reassign (new capture)"] = "重新分配（新捕获）",
})
AddSettings("ru", {
    ["Up"] = "Вверх",
    ["Down"] = "Вниз",
    ["Slot (0-5):"] = "Слот (0-5):",
    ["Position (0-9):"] = "Позиция (0-9):",
    ["OK"] = "OK",
    ["SteamVR Bindings (Default)"] = "Привязки SteamVR (по умолчанию)",
    ["Lua Keybinding (Recommended)"] = "Lua-привязки (рекомендуется)",
    ["(none)"] = "(нет)",
    ["Changes require Gmod restart to take effect."] = "Изменения требуют перезапуска Gmod.",
    ["=== Addon-Only Mode ==="] = "=== Режим только дополнений ===",
    ["Addon-Only Mode (skip root files, use external VRMod)"] = "Режим только дополнений (пропуск корневых файлов, внешний VRMod)",
    ["ON = Root files (vrmod.lua, input, character, etc.) are not loaded.\nUse this with legacy/original VRMod as your base VRMod.\nOnly numbered folder modules are loaded as add-on features."] = "ON = Корневые файлы (vrmod.lua, ввод, персонаж и т.д.) не загружаются.\nИспользуйте с устаревшим/оригинальным VRMod как базой.\nЗагружаются только пронумерованные модули как дополнения.",
    ["=== Legacy Mode ==="] = "=== Устаревший режим ===",
    ["Legacy Mode (load only core features)"] = "Устаревший режим (только базовые функции)",
    ["ON = only folders 0 (Core) and 1 (Auto-settings) load.\nAll features below are disabled regardless of their individual setting."] = "ON = загружаются только папки 0 (Ядро) и 1 (Автонастройки).\nВсе функции ниже отключены вне зависимости от настроек.",
    ["=== Feature Modules ==="] = "=== Функциональные модули ===",
    ["Press a VR controller button to assign to [%s]..."] = "Нажмите кнопку VR-контроллера для назначения [%s]...",
    ["Assigned [%s] to [%s]. Click another key or switch mode."] = "[%s] назначено на [%s]. Нажмите другую клавишу или смените режим.",
    ["Removed [%s] from [%s]."] = "[%s] удалено из [%s].",
    ["Remove:"] = "Удалить:",
    ["Reassign (new capture)"] = "Переназначить (новый захват)",
})

-- Sub-addon remaining strings
AddSettings("ja", {
    ["Add"] = "追加",
    ["Status: Checking..."] = "ステータス: チェック中...",
    ["Status:"] = "ステータス:",
    ["Attachment Mode"] = "アタッチメントモード",
    ["Current weapon: %s"] = "現在の武器: %s",
    ["Attachments: %s"] = "アタッチメント: %s",
    ["Attachments: (none)"] = "アタッチメント: (なし)",
    ["Current weapon: (no ArcVR weapon)"] = "現在の武器: (ArcVR武器なし)",
    ["Attachments: ---"] = "アタッチメント: ---",
})
AddSettings("zh", {
    ["Add"] = "添加",
    ["Status: Checking..."] = "状态: 检查中...",
    ["Status:"] = "状态:",
    ["Attachment Mode"] = "附着模式",
    ["Current weapon: %s"] = "当前武器: %s",
    ["Attachments: %s"] = "附件: %s",
    ["Attachments: (none)"] = "附件: (无)",
    ["Current weapon: (no ArcVR weapon)"] = "当前武器: (无ArcVR武器)",
    ["Attachments: ---"] = "附件: ---",
})
AddSettings("ru", {
    ["Add"] = "Добавить",
    ["Status: Checking..."] = "Статус: Проверка...",
    ["Status:"] = "Статус:",
    ["Attachment Mode"] = "Режим крепления",
    ["Current weapon: %s"] = "Текущее оружие: %s",
    ["Attachments: %s"] = "Вложения: %s",
    ["Attachments: (none)"] = "Вложения: (нет)",
    ["Current weapon: (no ArcVR weapon)"] = "Текущее оружие: (нет оружия ArcVR)",
    ["Attachments: ---"] = "Вложения: ---",
})

-- Phase 6 audit additions (actioneditor, quickmenu editor, HMD)
AddSettings("ja", {
    ["VRMod Custom Input Action Editor"] = "VRModカスタム入力アクションエディター",
    ["name                    [driving]    concmd on press                                                   concmd on release"] = "名前                    [運転]    押した時のコマンド                                                   離した時のコマンド",
    ["REMOVE"] = "削除",
    ["ADD"] = "追加",
    ["Console Command"] = "コンソールコマンド",
    ["ConVar Toggle"] = "ConVarトグル",
    ["HMD"] = "HMD",
})
AddSettings("zh", {
    ["VRMod Custom Input Action Editor"] = "VRMod自定义输入动作编辑器",
    ["name                    [driving]    concmd on press                                                   concmd on release"] = "名称                    [驾驶]    按下时的命令                                                   松开时的命令",
    ["REMOVE"] = "移除",
    ["ADD"] = "添加",
    ["Console Command"] = "控制台命令",
    ["ConVar Toggle"] = "ConVar切换",
    ["HMD"] = "HMD",
})
AddSettings("ru", {
    ["VRMod Custom Input Action Editor"] = "Редактор пользовательских действий VRMod",
    ["name                    [driving]    concmd on press                                                   concmd on release"] = "имя                    [вождение]    команда при нажатии                                                   команда при отпускании",
    ["REMOVE"] = "УДАЛИТЬ",
    ["ADD"] = "ДОБАВИТЬ",
    ["Console Command"] = "Консольная команда",
    ["ConVar Toggle"] = "Переключение ConVar",
    ["HMD"] = "HMD",
})

-- C++ Module page + Tree node labels
AddSettings("ja", {
    -- Status panel
    ["Status:"] = "ステータス:",
    ["Version:"] = "バージョン:",
    ["Type:"] = "タイプ:",
    ["Latest:"] = "最新:",
    ["Extracted .dat:"] = "展開済み .dat:",
    ["Installed"] = "インストール済み",
    ["Not installed"] = "未インストール",
    ["Error (loaded but failed)"] = "エラー（読み込み後に失敗）",
    ["Found"] = "検出",
    ["Missing"] = "未検出",
    -- Troubleshooting
    ["If module is not working:\n" ..
    "1. Go to garrysmod/data/vrmod_module/\n" ..
    "2. Rename install.txt -> install.bat\n" ..
    "3. Run install.bat, then restart Gmod\n" ..
    "4. If antivirus blocks it, add GarrysMod\n" ..
    "   folder to your AV exclusions\n" ..
    "5. Windows Defender: Settings > Virus\n" ..
    "   protection > Exclusions"] =
    "モジュールが動作しない場合:\n" ..
    "1. garrysmod/data/vrmod_module/ を開く\n" ..
    "2. install.txt を install.bat にリネーム\n" ..
    "3. install.bat を実行し、Gmodを再起動\n" ..
    "4. ウイルス対策ソフトがブロックする場合、\n" ..
    "   GarrysMod フォルダを除外リストに追加\n" ..
    "5. Windows Defender: 設定 > ウイルスと\n" ..
    "   脅威の防止 > 除外",
    -- Tree nodes
    ["C++ Module"] = "C++モジュール",
    ["Character"] = "キャラクター",
    ["Optimize"] = "最適化",
    ["Opt.VR"] = "VR最適化",
    ["Opt.Gmod"] = "Gmod最適化",
    ["Quick Menu"] = "クイックメニュー",
    ["VRStop Key"] = "VR停止キー",
    ["Misc"] = "その他",
    ["Animation"] = "アニメーション",
    ["Graphics02"] = "グラフィック02",
    ["Network(Server)"] = "ネットワーク(サーバー)",
    ["Commands"] = "コマンド",
    ["Vehicle"] = "乗り物",
    ["Utility"] = "ユーティリティ",
    ["Cardboard"] = "Cardboard",
    ["Key Mapping"] = "キーマッピング",
    ["Modules"] = "モジュール",
})
AddSettings("zh", {
    -- Status panel
    ["Status:"] = "状态:",
    ["Version:"] = "版本:",
    ["Type:"] = "类型:",
    ["Latest:"] = "最新版:",
    ["Extracted .dat:"] = "已解压 .dat:",
    ["Installed"] = "已安装",
    ["Not installed"] = "未安装",
    ["Error (loaded but failed)"] = "错误（加载后失败）",
    ["Found"] = "已找到",
    ["Missing"] = "缺失",
    -- Troubleshooting
    ["If module is not working:\n" ..
    "1. Go to garrysmod/data/vrmod_module/\n" ..
    "2. Rename install.txt -> install.bat\n" ..
    "3. Run install.bat, then restart Gmod\n" ..
    "4. If antivirus blocks it, add GarrysMod\n" ..
    "   folder to your AV exclusions\n" ..
    "5. Windows Defender: Settings > Virus\n" ..
    "   protection > Exclusions"] =
    "模块不工作时:\n" ..
    "1. 打开 garrysmod/data/vrmod_module/\n" ..
    "2. 将 install.txt 重命名为 install.bat\n" ..
    "3. 运行 install.bat，然后重启Gmod\n" ..
    "4. 如果杀毒软件阻止，请将GarrysMod\n" ..
    "   文件夹添加到杀毒软件排除列表\n" ..
    "5. Windows Defender: 设置 > 病毒和\n" ..
    "   威胁防护 > 排除项",
    -- Tree nodes
    ["C++ Module"] = "C++模块",
    ["Character"] = "角色",
    ["Optimize"] = "优化",
    ["Opt.VR"] = "VR优化",
    ["Opt.Gmod"] = "Gmod优化",
    ["Quick Menu"] = "快捷菜单",
    ["VRStop Key"] = "VR停止键",
    ["Misc"] = "杂项",
    ["Animation"] = "动画",
    ["Graphics02"] = "图形02",
    ["Network(Server)"] = "网络(服务器)",
    ["Commands"] = "命令",
    ["Vehicle"] = "载具",
    ["Utility"] = "工具",
    ["Cardboard"] = "Cardboard",
    ["Key Mapping"] = "按键映射",
    ["Modules"] = "模块",
})
AddSettings("ru", {
    -- Status panel
    ["Status:"] = "Статус:",
    ["Version:"] = "Версия:",
    ["Type:"] = "Тип:",
    ["Latest:"] = "Последняя:",
    ["Extracted .dat:"] = "Извлечённый .dat:",
    ["Installed"] = "Установлен",
    ["Not installed"] = "Не установлен",
    ["Error (loaded but failed)"] = "Ошибка (загружен, но сбой)",
    ["Found"] = "Найден",
    ["Missing"] = "Отсутствует",
    -- Troubleshooting
    ["If module is not working:\n" ..
    "1. Go to garrysmod/data/vrmod_module/\n" ..
    "2. Rename install.txt -> install.bat\n" ..
    "3. Run install.bat, then restart Gmod\n" ..
    "4. If antivirus blocks it, add GarrysMod\n" ..
    "   folder to your AV exclusions\n" ..
    "5. Windows Defender: Settings > Virus\n" ..
    "   protection > Exclusions"] =
    "Если модуль не работает:\n" ..
    "1. Откройте garrysmod/data/vrmod_module/\n" ..
    "2. Переименуйте install.txt -> install.bat\n" ..
    "3. Запустите install.bat, перезапустите Gmod\n" ..
    "4. Если антивирус блокирует, добавьте папку\n" ..
    "   GarrysMod в исключения антивируса\n" ..
    "5. Windows Defender: Настройки > Защита от\n" ..
    "   вирусов > Исключения",
    -- Tree nodes
    ["C++ Module"] = "Модуль C++",
    ["Character"] = "Персонаж",
    ["Optimize"] = "Оптимизация",
    ["Opt.VR"] = "Опт. VR",
    ["Opt.Gmod"] = "Опт. Gmod",
    ["Quick Menu"] = "Быстрое меню",
    ["VRStop Key"] = "Клавиша остановки VR",
    ["Misc"] = "Разное",
    ["Animation"] = "Анимация",
    ["Graphics02"] = "Графика02",
    ["Network(Server)"] = "Сеть (Сервер)",
    ["Commands"] = "Команды",
    ["Vehicle"] = "Транспорт",
    ["Utility"] = "Утилиты",
    ["Cardboard"] = "Cardboard",
    ["Key Mapping"] = "Назначение клавиш",
    ["Modules"] = "Модули",
})

print("[VRMod] Settings localization extension loaded")
