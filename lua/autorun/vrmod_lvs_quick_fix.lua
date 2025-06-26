-- -- VRMod Vehicle Input Quick Fix

-- if SERVER then return end

-- local function DisableRedundantHooks()
--     -- 問題のあるThinkフックを削除
--     timer.Simple(0.5, function()
--         hook.Remove("Think", "glide_vr_update")
--         hook.Remove("Think", "VRMod_Glide_Extended_ThinkUpdate") 
--         hook.Remove("Think", "vre_simfphysfix_remix_think")
        
--         -- print("[VRMod QuickFix] 重複する車両入力フックを無効化しました")
--     end)
-- end

-- -- 初期化時とVRMod開始時に実行
-- hook.Add("InitPostEntity", "vrmod_quickfix_init", DisableRedundantHooks)
-- hook.Add("VRMod_Start", "vrmod_quickfix_start", DisableRedundantHooks)

-- -- 定期的にチェック（他のアドオンが後から追加する可能性があるため）
-- timer.Create("vrmod_quickfix_monitor", 10, 0, DisableRedundantHooks)

-- VRMod 車両操作遅延修正（シンプル版）

if SERVER then return end

-- print("[VRMod Fix] 車両操作の遅延修正を適用中...")

-- CreateClientConVarの高速化
local _CreateClientConVar = CreateClientConVar
local _GetConVar = GetConVar

function CreateClientConVar(name, ...)
    -- すでに存在するConVarは作成せずに返す
    local existing = _GetConVar(name)
    if existing then
        return existing
    end
    return _CreateClientConVar(name, ...)
end

-- print("[VRMod Fix] 修正を適用しました。車両操作の遅延が改善されるはずです。")