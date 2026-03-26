--------[vrmod_arc9_core.lua]Start--------
-- ARC9統合コア: 武器判定、ConVar、ユーティリティ
-- ARC9武器を検出し、VRMod統合機能のON/OFFを制御する

if SERVER then return end

-- ARC9武器判定
vrmod.IsARC9Weapon = function(wep)
    return IsValid(wep) and wep.ARC9 == true
end

-- ConVar定義（キャッシュ済み — 毎フレームGetConVar()を回避）
local arc9Enable = CreateClientConVar("vrmod_arc9_enable", "1", true, false, "Enable/Disable ARC9 VR integration")
local arc9MagEnable = CreateClientConVar("vrmod_arc9_magbone_fix_enable", "1", true, false, "Enable/Disable ARC9 magazine bone fix")
local arc9MagTrack = CreateClientConVar("vrmod_arc9_magbone_track", "1", true, false, "ARC9 mag bone mode: 0=hide only (old), 1=follow left hand (new)")
local arc9Debug = CreateClientConVar("vrmod_arc9_debug", "0", true, false, "Enable ARC9 debug logging")

-- 有効判定
vrmod.IsARC9Enabled = function()
    return arc9Enable:GetBool()
end

vrmod.IsARC9FixEnabled = function()
    return arc9Enable:GetBool() and arc9MagEnable:GetBool()
end

-- 追従モード判定（fix有効 かつ trackモード有効）
vrmod.IsARC9MagTrackEnabled = function()
    return arc9Enable:GetBool() and arc9MagEnable:GetBool() and arc9MagTrack:GetBool()
end

-- デバッグログ
vrmod.ARC9Log = function(msg)
    if arc9Debug:GetBool() then
        print("[VRMod-ARC9] " .. msg)
    end
end
--------[vrmod_arc9_core.lua]End--------
