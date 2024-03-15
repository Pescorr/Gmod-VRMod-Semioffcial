if SERVER then return end

local function CheckHandTouch(player)
    local leftHandPos = vrmod.GetLeftHandPos(player)
    local rightViewModelPos = vrmod.GetRightHandPos(player)
    local some_threshold = CreateClientConVar("vrmod_Foregripmode_range", "13", true, FCVAR_ARCHIVE) -- 必要に応じて調整
    if not leftHandPos or not rightViewModelPos then return false end -- 一方または両方の位置が nil のため、チェックを実行できない
    if leftHandPos:Distance(rightViewModelPos) < some_threshold:GetFloat() then return true end

    return false
end

local function HasVRInWeaponName(player)
    local activeWeapon = player:GetActiveWeapon()
    if IsValid(activeWeapon) then
        local weaponName = string.lower(activeWeapon:GetClass())
        if string.find(weaponName, "vr") then return true end
    end

    return false
end

local gripenable = CreateClientConVar("vrmod_Foregripmode_enable", 1, true, FCVAR_ARCHIVE)
hook.Add(
    "VRMod_Input",
    "VRForegripmodeInput",
    function(action, pressed)
        if gripenable:GetBool() then
            if action == "boolean_left_pickup" or action == "boolean_left_primaryfire" then
                if pressed and CheckHandTouch(LocalPlayer()) and not HasVRInWeaponName(LocalPlayer()) then
                    LocalPlayer():ConCommand("vrmod_Foregripmode 1")
                else
                    LocalPlayer():ConCommand("vrmod_Foregripmode 0")
                end

                return
            end
        end
    end
)