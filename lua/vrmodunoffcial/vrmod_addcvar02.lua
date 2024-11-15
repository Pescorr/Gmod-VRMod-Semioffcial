if CLIENT then
    hook.Add(
        "VRMod_Input",
        "vrutil_novrweapon",
        function(action, pressed)
            if hook.Call("VRMod_AllowDefaultAction", nil, action) == false then return end

            if action == "boolean_chat" and pressed then
                LocalPlayer():ConCommand("arccw_firemode")

                return
            end
            if action == "boolean_flashlight" and pressed then
                LocalPlayer():ConCommand("arccw_toggle_ubgl")

                return
            end

        end
    )

    -- -- 依存するConVarを事前に定義
    -- local convars = {
    -- 	vrmod_seatedoffset = GetConVar("vrmod_seatedoffset"),
    -- 	vrmod_scale = GetConVar("vrmod_scale"),
    -- }
    -- -- 設定値を取得するためのユーティリティ関数
    -- local function getConvarValues()
    -- 	return {
    -- 		vrmod_seatedoffset = convars.vrmod_seatedoffset:GetFloat(),
    -- 		vrmod_characterEyeHeight = GetConVar("vrmod_characterEyeHeight"):GetFloat(),
    -- 		vrmod_scale = convars.vrmod_scale:GetFloat(),
    -- 	}
    -- end
    -- -- concommand 1: seatedoffsetの計算と設定
    -- concommand.Add(
    -- 	"set_vrmod_seatedoffset",
    -- 	function()
    -- 		local convarValues = getConvarValues()
    -- 		local newSeatedOffset = convarValues.vrmod_characterEyeHeight - (g_VR.tracking.hmd.pos.z - convarValues.vrmod_seatedoffset - g_VR.origin.z)
    -- 		convars.vrmod_seatedoffset:SetFloat(newSeatedOffset)
    -- 	end
    -- )
    -- -- concommand 2: VRのスケールの計算と設定
    -- concommand.Add(
    -- 	"adjust_vrmod_scale",
    -- 	function()
    -- 		local convarValues = getConvarValues()
    -- 		g_VR.scale = convarValues.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z - g_VR.origin.z) / g_VR.scale)
    -- 		convars.vrmod_scale:SetFloat(g_VR.scale)
    -- 	end
    -- )
end

-- hook.Add(
--     "VRMod_Menu",
--     "AddHidePartsOptions",
--     function(frame)
--         local form = frame.SettingsForm -- 既存の設定フォームがあると仮定
--         form:CheckBox("Hide Head", "vrmod_hide_head")
--         form:CheckBox("Hide Body", "vrmod_hide_body")
--         form:CheckBox("Hide Arms", "vrmod_hide_arms")
--         form:CheckBox("Hide Legs", "vrmod_hide_legs")
--     end
-- )