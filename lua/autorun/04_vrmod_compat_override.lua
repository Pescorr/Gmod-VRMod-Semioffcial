-- VRMod Compatibility System - Override Handlers
-- Phase 1: Proof of Concept - Character Animation Override Only

if not VRModCompat then
    ErrorNoHalt("[VRModCompat Override] VRModCompat not initialized! Make sure 00_vrmod_compat_init.lua loaded first.\n")
    return
end

VRModCompat.Print("Loading override system...")

-- オーバーライドハンドラーのテーブル
VRModCompat.overrideHandlers = {}

-- ===================================================================
-- Character Animation Override Handler
-- ===================================================================

VRModCompat.overrideHandlers["vrmod/player/cl_character.lua"] = {
    -- x64版のフックを削除し、semiofficial版を有効にする
    toSemiofficial = function()
        VRModCompat.Print("Switching character animation to semiofficial version...")

        -- 両方のバージョンが同じフック識別子を使用しているため、
        -- 単純にsemiofficial版を再登録するだけで上書きできる
        -- ただし、念のため明示的に削除してから再登録する

        local success, err = pcall(function()
            -- 主要なキャラクターアニメーションフックを削除
            hook.Remove("VRMod_PreRender", "vrutil_hook_calcplyrenderpos")
            hook.Remove("PrePlayerDraw", "vrutil_hook_preplayerdraw")
            hook.Remove("PostPlayerDraw", "vrutil_hook_postplayerdraw")
            hook.Remove("CalcMainActivity", "vrutil_hook_calcmainactivity")
            hook.Remove("DoAnimationEvent", "vrutil_hook_doanimationevent")
            hook.Remove("VRMod_Start", "vrmod_characterstart")
            hook.Remove("VRMod_Exit", "vrmod_characterstop")

            -- semiofficial版のvrmod_character.luaを再読み込み
            -- 注意: これはクライアント側でのみ動作
            if CLIENT then
                local charFile = "vrmodunoffcial/vrmod_character.lua"
                if file.Exists("lua/" .. charFile, "GAME") then
                    include(charFile)
                    VRModCompat.PrintSuccess("Semiofficial character animation system loaded")
                else
                    VRModCompat.PrintWarning("Could not find semiofficial character file: ", charFile)
                end
            end
        end)

        if not success then
            VRModCompat.PrintError("Failed to switch to semiofficial: ", err)
        end
    end,

    -- semiofficial版のフックを削除し、x64版を有効にする
    toX64 = function()
        VRModCompat.Print("Switching character animation to x64 version...")

        local success, err = pcall(function()
            -- 主要なキャラクターアニメーションフックを削除
            hook.Remove("VRMod_PreRender", "vrutil_hook_calcplyrenderpos")
            hook.Remove("PrePlayerDraw", "vrutil_hook_preplayerdraw")
            hook.Remove("PostPlayerDraw", "vrutil_hook_postplayerdraw")
            hook.Remove("CalcMainActivity", "vrutil_hook_calcmainactivity")
            hook.Remove("DoAnimationEvent", "vrutil_hook_doanimationevent")
            hook.Remove("VRMod_Start", "vrmod_characterstart")
            hook.Remove("VRMod_Exit", "vrmod_characterstop")

            -- x64版のvrmod/player/cl_character.luaを再読み込み
            if CLIENT then
                local charFile = "vrmod/player/cl_character.lua"
                if file.Exists("lua/" .. charFile, "GAME") then
                    include(charFile)
                    VRModCompat.PrintSuccess("x64 character animation system loaded")
                else
                    VRModCompat.PrintWarning("Could not find x64 character file: ", charFile)
                end
            end
        end)

        if not success then
            VRModCompat.PrintError("Failed to switch to x64: ", err)
        end
    end,
}

-- ===================================================================
-- 汎用オーバーライド適用関数
-- ===================================================================

function VRModCompat.OverrideFunctionality(x64File, semiFile)
    local handler = VRModCompat.overrideHandlers[x64File]
    if handler and handler.toSemiofficial then
        handler.toSemiofficial()
    else
        VRModCompat.PrintWarning("No override handler for: ", x64File)
    end
end

function VRModCompat.RestoreX64Functionality(x64File)
    local handler = VRModCompat.overrideHandlers[x64File]
    if handler and handler.toX64 then
        handler.toX64()
    else
        VRModCompat.PrintWarning("No override handler for: ", x64File)
    end
end

-- ===================================================================
-- オーバーライドの適用 (InitPostEntity フックで実行)
-- ===================================================================

hook.Add("InitPostEntity", "VRModCompat_ApplyOverrides", function()
    VRModCompat.Print("Applying overrides...")

    -- 設定に基づいてオーバーライドを適用
    for x64File, semiFile in pairs(VRModCompat.fileMap) do
        local choice = VRModCompat.config.overrides[x64File]

        if choice == "semiofficial" then
            VRModCompat.Print("Override: ", VRModCompat.featureNames[x64File] or x64File, " → semiofficial")
            VRModCompat.OverrideFunctionality(x64File, semiFile)

        elseif choice == "x64" then
            VRModCompat.Print("Override: ", VRModCompat.featureNames[x64File] or x64File, " → x64")
            VRModCompat.RestoreX64Functionality(x64File)

        else
            -- 選択されていない場合は、デフォルト（両方読み込まれたまま、後から読み込まれた方が優先）
            VRModCompat.Print("No override for: ", VRModCompat.featureNames[x64File] or x64File, " (using default)")
        end
    end

    VRModCompat.PrintSuccess("Override application complete!")
    VRModCompat.Print("")
    VRModCompat.Print("Test commands:")
    VRModCompat.Print("  vrmod_compat_test_x64   - Switch to x64 character animation")
    VRModCompat.Print("  vrmod_compat_test_semi  - Switch to semiofficial character animation")
    VRModCompat.Print("  vrmod_compat_status     - Show current status")
    VRModCompat.Print("")
    VRModCompat.PrintWarning("Note: Changes require map reload to take full effect")
end)

VRModCompat.Print("Override system loaded!")
