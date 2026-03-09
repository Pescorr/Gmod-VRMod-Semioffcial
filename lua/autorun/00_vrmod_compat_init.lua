-- VRMod Compatibility System - Core Initialization
-- vrmod-x64 と vrmod_semioffcial_addonplus の互換性システム
-- Phase 1: Proof of Concept - Character Animation Override

print("[VRModCompat] Initializing compatibility system...")

-- グローバルテーブルの作成
VRModCompat = VRModCompat or {}
VRModCompat.version = 1
VRModCompat.phase = "proof_of_concept" -- フェーズ1：プルーフオブコンセプト

-- 設定構造
VRModCompat.config = {
    mode = "test_character_animation",  -- テストモード
    overrides = {},                      -- ファイルごとの選択 (例: ["vrmod/player/cl_character.lua"] = "x64" or "semiofficial")
}

-- ファイルマッピングテーブル (x64ファイル → semioffcialファイル)
-- Phase 1では1つだけテスト
VRModCompat.fileMap = {
    -- Character Animation (プルーフオブコンセプトでテストする唯一の機能)
    ["vrmod/player/cl_character.lua"] = "vrmodunoffcial/vrmod_character.lua",

    -- 将来的に追加する予定の競合（Phase 2以降）
    -- ["vrmod/input/sh_buttons.lua"] = "vrmodunoffcial/vrmod_input.lua",
    -- ["vrmod/pickup/sh_pickup.lua"] = "vrmodunoffcial/vrmod_pickup.lua",
    -- ["vrmod/ui/cl_hud.lua"] = "vrmodunoffcial/vrmod_hud.lua",
    -- など15+の競合...
}

-- ユーザーフレンドリーな機能名
VRModCompat.featureNames = {
    ["vrmod/player/cl_character.lua"] = "Character Animation & IK",
    -- 将来的に追加...
}

-- 読み込み状態の追跡
VRModCompat.loaded = {
    x64 = false,
    semiofficial = false,
}

-- デバッグメッセージ用のヘルパー関数
function VRModCompat.Print(...)
    MsgC(Color(100, 200, 255), "[VRModCompat] ", Color(255, 255, 255), ...)
    MsgN()
end

function VRModCompat.PrintSuccess(...)
    MsgC(Color(100, 255, 100), "[VRModCompat] ✓ ", Color(255, 255, 255), ...)
    MsgN()
end

function VRModCompat.PrintWarning(...)
    MsgC(Color(255, 200, 100), "[VRModCompat] ⚠ ", Color(255, 255, 255), ...)
    MsgN()
end

function VRModCompat.PrintError(...)
    MsgC(Color(255, 100, 100), "[VRModCompat] ✗ ", Color(255, 255, 255), ...)
    MsgN()
end

-- アドオンの読み込みを検出
hook.Add("Initialize", "VRModCompat_DetectAddons", function()
    -- vrmod-x64の検出
    if vrmod and vrmod.version then
        VRModCompat.loaded.x64 = true
        VRModCompat.Print("Detected vrmod-x64 (version: ", vrmod.version or "unknown", ")")
    end

    -- vrmod_semiofficial_addonplusの検出
    if vrmod and VRMOD_DEFAULTS then
        VRModCompat.loaded.semiofficial = true
        VRModCompat.Print("Detected vrmod_semiofficial_addonplus")
    end
end)

-- テスト用：手動でオーバーライドを切り替えるコマンド
concommand.Add("vrmod_compat_test_x64", function()
    VRModCompat.config.overrides["vrmod/player/cl_character.lua"] = "x64"
    VRModCompat.Print("Set character animation to x64 version")
    VRModCompat.PrintWarning("Reload the map (disconnect + reconnect) to apply changes")
end)

concommand.Add("vrmod_compat_test_semi", function()
    VRModCompat.config.overrides["vrmod/player/cl_character.lua"] = "semiofficial"
    VRModCompat.Print("Set character animation to semiofficial version")
    VRModCompat.PrintWarning("Reload the map (disconnect + reconnect) to apply changes")
end)

concommand.Add("vrmod_compat_status", function()
    VRModCompat.Print("=== VRMod Compatibility System Status ===")
    VRModCompat.Print("Version: ", VRModCompat.version)
    VRModCompat.Print("Phase: ", VRModCompat.phase)
    VRModCompat.Print("")
    VRModCompat.Print("Detected addons:")
    VRModCompat.Print("  vrmod-x64: ", VRModCompat.loaded.x64 and "YES" or "NO")
    VRModCompat.Print("  vrmod_semiofficial: ", VRModCompat.loaded.semiofficial and "YES" or "NO")
    VRModCompat.Print("")
    VRModCompat.Print("Current overrides:")
    for file, choice in pairs(VRModCompat.config.overrides) do
        local featureName = VRModCompat.featureNames[file] or file
        VRModCompat.Print("  ", featureName, ": ", choice)
    end
    if table.Count(VRModCompat.config.overrides) == 0 then
        VRModCompat.Print("  (none - using default behavior)")
    end
    VRModCompat.Print("==========================================")
end)

VRModCompat.PrintSuccess("Core initialization complete!")
VRModCompat.Print("Use 'vrmod_compat_status' to check system status")
VRModCompat.Print("Use 'vrmod_compat_test_x64' or 'vrmod_compat_test_semi' to test override (Phase 1)")
