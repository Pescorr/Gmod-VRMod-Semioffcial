--------[vrmod_arc9_viewmodel.lua]Start--------
-- ARC9 ViewModel自動更新
-- ARC9武器装備時にvrmod.UpdateViewmodelInfo()を自動呼び出し
-- VRMod_Start/VRMod_Exitフックで初期化/クリーンアップ

if SERVER then return end

local lastARC9Weapon = nil

hook.Add("Think", "VRMod_ARC9_ViewmodelAutoUpdate", function()
    if not g_VR or not g_VR.active then return end
    if not vrmod.IsARC9Enabled() then return end

    local ply = LocalPlayer()
    if not IsValid(ply) then return end

    local wep = ply:GetActiveWeapon()

    if vrmod.IsARC9Weapon(wep) then
        if lastARC9Weapon ~= wep then
            lastARC9Weapon = wep
            vrmod.UpdateViewmodelInfo(wep, true)
            vrmod.ARC9Log("ViewModel auto-updated: " .. wep:GetClass())
        end
    else
        if lastARC9Weapon ~= nil then
            lastARC9Weapon = nil
        end
    end
end)

hook.Add("VRMod_Start", "VRMod_ARC9_ViewmodelInit", function()
    lastARC9Weapon = nil
    vrmod.ARC9Log("ARC9 viewmodel tracking initialized")
end)

hook.Add("VRMod_Exit", "VRMod_ARC9_ViewmodelCleanup", function()
    lastARC9Weapon = nil
    vrmod.ARC9Log("ARC9 viewmodel tracking cleared")
end)
--------[vrmod_arc9_viewmodel.lua]End--------
