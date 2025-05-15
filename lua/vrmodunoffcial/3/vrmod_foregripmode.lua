--[[
vrmod_foregripmode.lua
GmodVR 用のフォアグリップおよび左手持ち機能を提供するMOD。
gmodvr-semioffcial-lua.txt の vrmod.lua から関連機能を抽出し、
他のGmodVRバージョンでも利用可能にすることを目的とする。
]]
if SERVER then return end
-- ConVar definitions
local CVAR_ARCHIVE = FCVAR_ARCHIVE
local CVAR_REPLICATED = FCVAR_REPLICATED
local CVAR_NOTIFY = FCVAR_NOTIFY
-- Foregrip mode related ConVars (from original vrmod_foregripmode.lua)
CreateClientConVar("vrmod_Foregripmode_enable", "1", true, CVAR_ARCHIVE)
CreateClientConVar("vrmod_Foregripmode_range", "13", true, CVAR_ARCHIVE)
CreateClientConVar("vrmod_Foregripmode_key_leftprimary", "1", true, CVAR_ARCHIVE, "0 = OFF 1 = Hold 2 = Toggle", 0, 2)
CreateClientConVar("vrmod_Foregripmode_key_leftgrab", "0", true, CVAR_ARCHIVE, "0 = OFF 1 = Hold 2 = Toggle", 0, 2)
-- ConVars extracted from vrmod.lua related to foregrip and left hand mode
CreateClientConVar("vrmod_LeftHand", "0", true, CVAR_ARCHIVE, "Enable Left Hand Mode")
CreateClientConVar("vrmod_LeftHandmode", "0", true, CVAR_ARCHIVE, "Left Hand Mode Type (0 or 1)")
CreateClientConVar("vrmod_Foregripmode", "0", false, CVAR_ARCHIVE, "Enable Foregrip Mode (controlled by script)")
CreateClientConVar("vrmod_foregrip_rotation_sensitivity", "1.0", true, CVAR_ARCHIVE, "Sensitivity for foregrip rotation")
CreateClientConVar("vrmod_foregrip_pitch_blend", "1.0", true, CVAR_ARCHIVE, "Blending factor for pitch between hands in foregrip mode")
CreateClientConVar("vrmod_foregrip_yaw_blend", "1.0", true, CVAR_ARCHIVE, "Blending factor for yaw between hands in foregrip mode")
CreateClientConVar("vrmod_foregrip_roll_blend", "0.05", true, CVAR_ARCHIVE, "Blending factor for roll between hands in foregrip mode")
-- Get ConVar objects for efficient access
local cv_gripenable = GetConVar("vrmod_Foregripmode_enable")
local cv_range = GetConVar("vrmod_Foregripmode_range")
local cv_key_leftprimary = GetConVar("vrmod_Foregripmode_key_leftprimary")
local cv_key_leftgrab = GetConVar("vrmod_Foregripmode_key_leftgrab")
local cv_uselefthand = GetConVar("vrmod_LeftHand")
local cv_lefthandmode = GetConVar("vrmod_LeftHandmode")
local cv_foregripmode = GetConVar("vrmod_Foregripmode")
local cv_foregrip_rotation_sensitivity = GetConVar("vrmod_foregrip_rotation_sensitivity")
local cv_foregrip_pitch_blend = GetConVar("vrmod_foregrip_pitch_blend")
local cv_foregrip_yaw_blend = GetConVar("vrmod_foregrip_yaw_blend")
local cv_foregrip_roll_blend = GetConVar("vrmod_foregrip_roll_blend")
-- Global state for the mod
local isForegripmodeActive = false -- Renamed from isForegripmodeEnabled to avoid conflict
--[[
Helper function to check if the left hand is close enough to the right hand (viewmodel).
Parameters:
    player: The player entity to check.
Returns:
    boolean: True if hands are close enough, false otherwise.
]]
local function CheckHandTouch(player)
	if not vrmod or not vrmod.GetLeftHandPos or not vrmod.GetRightHandPos then return false end -- Ensure vrmod API is available
	local leftHandPos = vrmod.GetLeftHandPos(player)
	local rightHandPos = vrmod.GetRightHandPos(player) -- Use right hand raw position
	if not leftHandPos or not rightHandPos then return false end
	-- Use the ConVar for the distance threshold

	return leftHandPos:Distance(rightHandPos) < cv_range:GetFloat()
end

--[[
Helper function to check if the active weapon has "vr" in its class name.
Parameters:
    player: The player entity to check.
Returns:
    boolean: True if the weapon name contains "vr", false otherwise.
]]
local function HasVRInWeaponName(player)
	local activeWeapon = player:GetActiveWeapon()
	if IsValid(activeWeapon) then
		local weaponName = string.lower(activeWeapon:GetClass())
		-- Avoid activating foregrip for known VR-specific weapons or tools
		if string.find(weaponName, "vr") or string.find(weaponName, "gmod_tool") or string.find(weaponName, "physgun") then return true end
	end

	return false
end



--[[
Toggles the foregrip mode ConVar based on the input or current state.
Parameters:
    bEnable (optional): Explicitly set the state (true/false). Toggles if nil.
]]
local function ToggleForegripMode(bEnable)
	if bEnable ~= nil then
		isForegripmodeActive = bEnable
	else
		isForegripmodeActive = not isForegripmodeActive
	end

	-- Use RunConsoleCommand to set the ConVar, ensuring it takes effect
	RunConsoleCommand("vrmod_Foregripmode", isForegripmodeActive and "1" or "0")
	-- Ensure left hand mode is disabled when foregrip is active
	if isForegripmodeActive then
		RunConsoleCommand("vrmod_LeftHand", "0")
	end
end

--[[
Input hook to handle foregrip mode activation/deactivation based on key presses and hand positions.
]]
hook.Add(
	"VRMod_Input",
	"VRForegripmodeInput",
	function(action, pressed)
		if not cv_gripenable:GetBool() then return end -- Check if the feature is enabled
		local player = LocalPlayer()
		if not IsValid(player) then return end
		local leftPrimaryMode = cv_key_leftprimary:GetInt()
		local leftGrabMode = cv_key_leftgrab:GetInt()
		local isUsingLeftHand = cv_uselefthand:GetBool() -- Check if left hand mode is active
		-- Determine if conditions are met to potentially change foregrip state
		local canActivateForegrip = CheckHandTouch(player) and not HasVRInWeaponName(player)
		-- Logic for Right-Handed mode (LeftHand ConVar is 0)
		if not isUsingLeftHand then
			if action == "boolean_left_primaryfire" then
				-- Hold to activate
				if leftPrimaryMode == 1 then
					ToggleForegripMode(pressed and canActivateForegrip)
				elseif leftPrimaryMode == 2 then
					-- Toggle
					if pressed and canActivateForegrip then
						ToggleForegripMode()
					end
				end
			elseif action == "boolean_left_pickup" then
				-- Hold to activate
				if leftGrabMode == 1 then
					ToggleForegripMode(pressed and canActivateForegrip)
				elseif leftGrabMode == 2 then
					-- Toggle
					if pressed and canActivateForegrip then
						ToggleForegripMode()
					end
				end
			end
			-- Logic for Left-Handed mode (LeftHand ConVar is 1) - Use right hand inputs
		else
			-- Right hand primary fire
			if action == "boolean_primaryfire" then
				-- Hold to activate (using the same ConVar setting for simplicity)
				if leftPrimaryMode == 1 then
					ToggleForegripMode(pressed and canActivateForegrip)
				elseif leftPrimaryMode == 2 then
					-- Toggle
					if pressed and canActivateForegrip then
						ToggleForegripMode()
					end
				end
			elseif action == "boolean_right_pickup" then
				-- Right hand grab
				-- Hold to activate (using the same ConVar setting)
				if leftGrabMode == 1 then
					ToggleForegripMode(pressed and canActivateForegrip)
				elseif leftGrabMode == 2 then
					-- Toggle
					if pressed and canActivateForegrip then
						ToggleForegripMode()
					end
				end
			end
		end
	end
)

--[[
RenderScene hook to override viewmodel position and angle based on hand tracking data
when Foregrip or Left Hand mode is active.
This function replicates the logic extracted from vrmod.lua.
]]
hook.Add(
	"RenderScene",
	"VRForegripViewModelUpdate",
	function()
		-- Ensure GmodVR is active and tracking data is available
		if not g_VR or not g_VR.active or not g_VR.tracking or not g_VR.tracking.hmd then return end
		if not g_VR.tracking.pose_lefthand or not g_VR.tracking.pose_righthand then return end
		-- Get necessary ConVar values
		local useLeftHand = cv_uselefthand:GetBool()
		local leftHandModeType = cv_lefthandmode:GetBool()
		local useForegrip = cv_foregripmode:GetBool()
		-- Determine the primary hand based on the mode
		local primaryHand = (useLeftHand and not useForegrip) and g_VR.tracking.pose_lefthand or g_VR.tracking.pose_righthand
		local secondaryHand = (useLeftHand and not useForegrip) and g_VR.tracking.pose_righthand or g_VR.tracking.pose_lefthand
		-- Get the network frame if available (for updating hand positions for other players)
		-- This assumes g_VR.net and lerpedFrame structure exists as in the original vrmod.lua context.
		local netFrame = nil
		if g_VR.net and g_VR.net[LocalPlayer():SteamID()] then
			netFrame = g_VR.net[LocalPlayer():SteamID()].lerpedFrame
			-- Fallback if lerpedFrame is not ready, use direct tracking data for local updates
			if not netFrame then
				netFrame = {
					righthandPos = g_VR.tracking.pose_righthand.pos,
					righthandAng = g_VR.tracking.pose_righthand.ang,
					lefthandPos = g_VR.tracking.pose_lefthand.pos,
					lefthandAng = g_VR.tracking.pose_lefthand.ang
				}
			end
		end

		local targetPos, targetAng
		-- Foregrip Mode Logic
		if useForegrip then
			-- Check if viewmodel info is available
			if g_VR.currentvmi then
				local rightHandPos, rightHandAng = primaryHand.pos, primaryHand.ang
				local leftHandPos, leftHandAng = secondaryHand.pos, secondaryHand.ang
				-- Calculate blended angle based on sensitivity and blend factors
				local sensitivity = cv_foregrip_rotation_sensitivity:GetFloat()
				local pitchBlend = cv_foregrip_pitch_blend:GetFloat()
				local yawBlend = cv_foregrip_yaw_blend:GetFloat()
				local rollBlend = cv_foregrip_roll_blend:GetFloat()
				-- Blend pitch, yaw, roll separately based on factors
				local blendedAngPart = Angle(Lerp(pitchBlend, rightHandAng.p, leftHandAng.p), Lerp(yawBlend, rightHandAng.y, leftHandAng.y), Lerp(rollBlend, rightHandAng.r, leftHandAng.r))
				-- Apply overall sensitivity interpolation
				targetAng = LerpAngle(sensitivity, rightHandAng, blendedAngPart)
				targetPos = rightHandPos -- Position is based on the primary (right) hand
				-- Calculate final viewmodel pose
				local finalPos, finalAng = LocalToWorld(g_VR.currentvmi.offsetPos, g_VR.currentvmi.offsetAng, targetPos, targetAng)
				g_VR.viewModelPos = finalPos
				g_VR.viewModelAng = finalAng
			end

			-- Update ViewModel and Network Frame
			if IsValid(g_VR.viewModel) then
				if not g_VR.usingWorldModels then
					g_VR.viewModel:SetPos(g_VR.viewModelPos)
					g_VR.viewModel:SetAngles(g_VR.viewModelAng)
					g_VR.viewModel:SetupBones()
					-- Update netFrame for server replication (if netFrame exists)
					if netFrame then
						local bone_R = g_VR.viewModel:LookupBone("ValveBiped.Bip01_R_Hand")
						if bone_R then
							local mtx_R = g_VR.viewModel:GetBoneMatrix(bone_R)
							if mtx_R then
								netFrame.righthandPos = mtx_R:GetTranslation()
								netFrame.righthandAng = mtx_R:GetAngles() - Angle(0, 0, 180) -- Original adjustment
							end
						end

						local bone_L = g_VR.viewModel:LookupBone("ValveBiped.Bip01_L_Hand")
						if bone_L then
							local mtx_L = g_VR.viewModel:GetBoneMatrix(bone_L)
							if mtx_L then
								netFrame.lefthandPos = mtx_L:GetTranslation()
								netFrame.lefthandAng = mtx_L:GetAngles() -- No adjustment needed for left
							end
						end
					end
				end

				-- Update muzzle attachment info
				g_VR.viewModelMuzzle = g_VR.viewModel:GetAttachment(1)
			end
			-- Left Hand Mode Logic
		elseif useLeftHand then
			-- Check if viewmodel info is available
			if g_VR.currentvmi then
				targetPos, targetAng = primaryHand.pos, primaryHand.ang -- Left hand is primary
				-- Calculate final viewmodel pose
				local finalPos, finalAng = LocalToWorld(g_VR.currentvmi.offsetPos, g_VR.currentvmi.offsetAng, targetPos, targetAng)
				g_VR.viewModelPos = finalPos
				g_VR.viewModelAng = finalAng
			end

			-- Update ViewModel and Network Frame
			if IsValid(g_VR.viewModel) then
				if not g_VR.usingWorldModels then
					g_VR.viewModel:SetPos(g_VR.viewModelPos)
					g_VR.viewModel:SetAngles(g_VR.viewModelAng)
					g_VR.viewModel:SetupBones()
					if netFrame then
						local boneName = ""
						local angleAdjust = Angle(0, 0, 0)
						-- Type 2 (Simulate R hand)
						if leftHandModeType then
							boneName = "ValveBiped.Bip01_R_Hand"
							angleAdjust = Angle(0, 0, 180) -- Simulate right hand adjustment
						else -- Type 1 (Use L hand bone)
							boneName = "ValveBiped.Bip01_L_Hand"
							angleAdjust = Angle(0, 0, 0) -- No adjustment needed for left
						end

						local bone = g_VR.viewModel:LookupBone(boneName)
						if bone then
							local mtx = g_VR.viewModel:GetBoneMatrix(bone)
							if mtx then
								netFrame.lefthandPos = mtx:GetTranslation() -- Always update lefthandPos in netFrame for left hand mode
								netFrame.lefthandAng = mtx:GetAngles() - angleAdjust
							end
						end

						-- In left hand mode, ensure right hand in netframe reflects the actual tracked right hand
						netFrame.righthandPos = g_VR.tracking.pose_righthand.pos
						netFrame.righthandAng = g_VR.tracking.pose_righthand.ang
					end
				end

				g_VR.viewModelMuzzle = g_VR.viewModel:GetAttachment(1)
			end
		else -- Default Right Hand Mode (or when no special mode is active)
			-- Check if viewmodel info is available
			if g_VR.currentvmi then
				targetPos, targetAng = primaryHand.pos, primaryHand.ang -- Right hand is primary
				-- Calculate final viewmodel pose
				local finalPos, finalAng = LocalToWorld(g_VR.currentvmi.offsetPos, g_VR.currentvmi.offsetAng, targetPos, targetAng)
				g_VR.viewModelPos = finalPos
				g_VR.viewModelAng = finalAng
			end

			-- Update ViewModel and Network Frame
			if IsValid(g_VR.viewModel) then
				if not g_VR.usingWorldModels then
					g_VR.viewModel:SetPos(g_VR.viewModelPos)
					g_VR.viewModel:SetAngles(g_VR.viewModelAng)
					g_VR.viewModel:SetupBones()
					if netFrame then
						local bone = g_VR.viewModel:LookupBone("ValveBiped.Bip01_R_Hand")
						if bone then
							local mtx = g_VR.viewModel:GetBoneMatrix(bone)
							if mtx then
								netFrame.righthandPos = mtx:GetTranslation()
								netFrame.righthandAng = mtx:GetAngles() - Angle(0, 0, 180)
							end
						end

						-- In right hand mode, ensure left hand in netframe reflects the actual tracked left hand
						netFrame.lefthandPos = g_VR.tracking.pose_lefthand.pos
						netFrame.lefthandAng = g_VR.tracking.pose_lefthand.ang
					end
				end

				g_VR.viewModelMuzzle = g_VR.viewModel:GetAttachment(1)
			end
		end
	end
)

--[[
Ensure the foregrip mode is disabled when VR exits or the feature is disabled.
]]
local function DisableForegripCleanup()
	if isForegripmodeActive then
		RunConsoleCommand("vrmod_Foregripmode", "0")
		isForegripmodeActive = false
	end
end

hook.Add("VRMod_Exit", "VRForegripModeCleanup", DisableForegripCleanup)
hook.Add("Shutdown", "VRForegripModeShutdownCleanup", DisableForegripCleanup)
-- Add a change callback to disable foregrip mode if the main enable ConVar is turned off
cvars.AddChangeCallback(
	"vrmod_Foregripmode_enable",
	function(convar_name, old_value, new_value)
		if new_value == "0" then
			DisableForegripCleanup()
		end
	end, "VRForegripEnableToggle"
)

print("VRMod Foregrip/LeftHand Mode Extension Loaded")