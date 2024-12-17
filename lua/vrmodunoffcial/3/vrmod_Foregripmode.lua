AddCSLuaFile()
if SERVER then return end
local some_threshold = CreateClientConVar("vrmod_Foregripmode_range", "13", true, FCVAR_ARCHIVE)
local left_primary = CreateClientConVar("vrmod_Foregripmode_key_leftprimary", "1", true, FCVAR_ARCHIVE, "0 = OFF 1 = Hold 2 = Toggle")
local left_grab = CreateClientConVar("vrmod_Foregripmode_key_leftgrab", "0", true, FCVAR_ARCHIVE, "0 = OFF 1 = Hold 2 = Toggle")
local gripenable = CreateClientConVar("vrmod_Foregripmode_enable", 1, true, FCVAR_ARCHIVE)
local dummylefthand = GetConVar("vrmod_LeftHand")
local isForegripmodeEnabled = false
local function CheckHandTouch(player)
    local leftHandPos = vrmod.GetLeftHandPos(player)
    local rightViewModelPos = vrmod.GetRightHandPos(player)
    if not leftHandPos or not rightViewModelPos then return false end
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

local function ToggleForegripMode(bEnable)
    if bEnable ~= nil then
        isForegripmodeEnabled = bEnable
    else
        isForegripmodeEnabled = not isForegripmodeEnabled
    end

    if isForegripmodeEnabled then
        LocalPlayer():ConCommand("vrmod_Foregripmode 1")
    else
        LocalPlayer():ConCommand("vrmod_Foregripmode 0")
    end
end

hook.Add(
    "VRMod_Input",
    "VRForegripmodeInput",
    function(action, pressed)
        if not gripenable:GetBool() then return end
        local leftPrimaryMode = left_primary:GetInt()
        local leftGrabMode = left_grab:GetInt()
        local dummyleft = dummylefthand:GetBool()
        if not dummyleft then
            if action == "boolean_left_primaryfire" then
                if leftPrimaryMode == 1 then
                    if pressed and CheckHandTouch(LocalPlayer()) and not HasVRInWeaponName(LocalPlayer()) then
                        ToggleForegripMode(true)
                    else
                        ToggleForegripMode(false)
                    end
                elseif leftPrimaryMode == 2 then
                    if pressed and CheckHandTouch(LocalPlayer()) and not HasVRInWeaponName(LocalPlayer()) then
                        ToggleForegripMode()
                    end
                end
            end

            if action == "boolean_left_pickup" then
                if leftGrabMode == 1 then
                    if pressed and CheckHandTouch(LocalPlayer()) and not HasVRInWeaponName(LocalPlayer()) then
                        ToggleForegripMode(true)
                    else
                        ToggleForegripMode(false)
                    end
                elseif leftGrabMode == 2 then
                    if pressed and CheckHandTouch(LocalPlayer()) and not HasVRInWeaponName(LocalPlayer()) then
                        ToggleForegripMode()
                    end
                end
            end
        end

        if dummyleft then
            if action == "boolean_right_pickup" then
                if leftGrabMode == 1 then
                    if pressed and CheckHandTouch(LocalPlayer()) and not HasVRInWeaponName(LocalPlayer()) then
                        ToggleForegripMode(true)
                    else
                        ToggleForegripMode(false)
                    end
                elseif leftGrabMode == 2 then
                    if pressed and CheckHandTouch(LocalPlayer()) and not HasVRInWeaponName(LocalPlayer()) then
                        ToggleForegripMode()
                    end
                end
            end

            if action == "boolean_primaryfire" then
                if leftPrimaryMode == 1 then
                    if pressed and CheckHandTouch(LocalPlayer()) and not HasVRInWeaponName(LocalPlayer()) then
                        ToggleForegripMode(true)
                    else
                        ToggleForegripMode(false)
                    end
                elseif leftPrimaryMode == 2 then
                    if pressed and CheckHandTouch(LocalPlayer()) and not HasVRInWeaponName(LocalPlayer()) then
                        ToggleForegripMode()
                    end
                end
            end
        end
    end
)