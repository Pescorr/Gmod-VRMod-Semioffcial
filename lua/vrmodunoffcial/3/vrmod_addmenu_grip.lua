--------[vrmod_addmenu03.lua]Start--------
AddCSLuaFile()
if SERVER then return end
local L = VRModL or function(_, fb) return fb or "" end
local convars, convarValues = vrmod.GetConvars()
hook.Add(
	"VRMod_Menu",
	"addsettingsgrip",
	function(frame)
		if not frame or not frame.DPropertySheet then return end

		local ok, err = pcall(function()
		-- MenuTab11 (Foregrip) Start
		local MenuTab11 = vgui.Create("DPanel")
		MenuTab11.Paint = function(self, w, h) end
		-- DNumSlider Start
		-- vrmod_Foregripmode_range
		local foregripmode_range = vgui.Create("DNumSlider", MenuTab11)
		foregripmode_range:SetPos(20, 10)
		foregripmode_range:SetSize(370, 25)
		foregripmode_range:SetText(L("Foregrip Mode Range", "Foregrip Mode Range"))
		foregripmode_range:SetMin(1)
		foregripmode_range:SetMax(100)
		foregripmode_range:SetDecimals(0)
		foregripmode_range:SetConVar("vrmod_Foregripmode_range")
		foregripmode_range.OnValueChanged = function(self, value) end
		-- DNumSlider End
		-- DCheckBoxLabel Start
		local foregripmode_enable = MenuTab11:Add("DCheckBoxLabel")
		foregripmode_enable:SetPos(20, 40)
		foregripmode_enable:SetText(L("Enable Foregrip Mode", "Enable Foregrip Mode"))
		foregripmode_enable:SetConVar("vrmod_Foregripmode_enable")
		foregripmode_enable:SizeToContents()
		-- DCheckBoxLabel End
		-- DNumSlider Start
		-- vrmod_Foregripmode_key_leftprimary
		local vrmod_Foregripmode_key_leftprimary = vgui.Create("DNumSlider", MenuTab11)
		vrmod_Foregripmode_key_leftprimary:SetPos(20, 70)
		vrmod_Foregripmode_key_leftprimary:SetSize(370, 25)
		vrmod_Foregripmode_key_leftprimary:SetText(L("Foregrip[boolean_left_primary]Key", "Foregrip[boolean_left_primary]Key"))
		vrmod_Foregripmode_key_leftprimary:SetMin(0)
		vrmod_Foregripmode_key_leftprimary:SetMax(2)
		vrmod_Foregripmode_key_leftprimary:SetDecimals(0)
		vrmod_Foregripmode_key_leftprimary:SetConVar("vrmod_Foregripmode_key_leftprimary")
		vrmod_Foregripmode_key_leftprimary.OnValueChanged = function(self, value) end
		-- DNumSlider End
		-- DNumSlider Start
		-- vrmod_Foregripmode_key_leftprimary
		local vrmod_Foregripmode_key_leftgrab = vgui.Create("DNumSlider", MenuTab11)
		vrmod_Foregripmode_key_leftgrab:SetPos(20, 100)
		vrmod_Foregripmode_key_leftgrab:SetSize(370, 25)
		vrmod_Foregripmode_key_leftgrab:SetText(L("Foregrip[boolean_left_pickup]Key", "Foregrip[boolean_left_pickup]Key"))
		vrmod_Foregripmode_key_leftgrab:SetMin(0)
		vrmod_Foregripmode_key_leftgrab:SetMax(2)
		vrmod_Foregripmode_key_leftgrab:SetDecimals(0)
		vrmod_Foregripmode_key_leftgrab:SetConVar("vrmod_Foregripmode_key_leftgrab")
		vrmod_Foregripmode_key_leftgrab.OnValueChanged = function(self, value) end
		-- DNumSlider End

		-- Advanced Settings
		local rotationBlend = vgui.Create("DNumSlider", MenuTab11)
		rotationBlend:SetPos(20, 140)
		rotationBlend:SetSize(370, 25)
		rotationBlend:SetText(L("Rotation Blend", "Rotation Blend"))
		rotationBlend:SetMin(0)
		rotationBlend:SetMax(1)
		rotationBlend:SetDecimals(2)
		rotationBlend:SetConVar("vrmod_Foregripmode_rotation_blend")

		local offsetX = vgui.Create("DNumSlider", MenuTab11)
		offsetX:SetPos(20, 170)
		offsetX:SetSize(370, 25)
		offsetX:SetText(L("Offset X", "Offset X"))
		offsetX:SetMin(-50)
		offsetX:SetMax(50)
		offsetX:SetDecimals(2)
		offsetX:SetConVar("vrmod_Foregripmode_offset_x")

		local offsetY = vgui.Create("DNumSlider", MenuTab11)
		offsetY:SetPos(20, 200)
		offsetY:SetSize(370, 25)
		offsetY:SetText(L("Offset Y", "Offset Y"))
		offsetY:SetMin(-50)
		offsetY:SetMax(50)
		offsetY:SetDecimals(2)
		offsetY:SetConVar("vrmod_Foregripmode_offset_y")

		local offsetZ = vgui.Create("DNumSlider", MenuTab11)
		offsetZ:SetPos(20, 230)
		offsetZ:SetSize(370, 25)
		offsetZ:SetText(L("Offset Z", "Offset Z"))
		offsetZ:SetMin(-50)
		offsetZ:SetMax(50)
		offsetZ:SetDecimals(2)
		offsetZ:SetConVar("vrmod_Foregripmode_offset_z")

		local angPitch = vgui.Create("DNumSlider", MenuTab11)
		angPitch:SetPos(20, 260)
		angPitch:SetSize(370, 25)
		angPitch:SetText(L("Angle Pitch", "Angle Pitch"))
		angPitch:SetMin(-180)
		angPitch:SetMax(180)
		angPitch:SetDecimals(2)
		angPitch:SetConVar("vrmod_Foregripmode_ang_pitch")

		local angYaw = vgui.Create("DNumSlider", MenuTab11)
		angYaw:SetPos(20, 290)
		angYaw:SetSize(370, 25)
		angYaw:SetText(L("Angle Yaw", "Angle Yaw"))
		angYaw:SetMin(-180)
		angYaw:SetMax(180)
		angYaw:SetDecimals(2)
		angYaw:SetConVar("vrmod_Foregripmode_ang_yaw")

		local angRoll = vgui.Create("DNumSlider", MenuTab11)
		angRoll:SetPos(20, 320)
		angRoll:SetSize(370, 25)
		angRoll:SetText(L("Angle Roll", "Angle Roll"))
		angRoll:SetMin(-180)
		angRoll:SetMax(180)
		angRoll:SetDecimals(2)
		angRoll:SetConVar("vrmod_Foregripmode_ang_roll")

		-- Restore Defaults Button for Advanced Settings
		local resetButtonAdvanced = vgui.Create("DButton", MenuTab11)
		resetButtonAdvanced:SetPos(20, 360)
		resetButtonAdvanced:SetSize(200, 30)
		resetButtonAdvanced:SetText(L("Restore Advanced Defaults", "Restore Advanced Defaults"))
		resetButtonAdvanced.DoClick = function()
			RunConsoleCommand("vrmod_Foregripmode_rotation_blend", "1")
			RunConsoleCommand("vrmod_Foregripmode_offset_x", "0")
			RunConsoleCommand("vrmod_Foregripmode_offset_y", "0")
			RunConsoleCommand("vrmod_Foregripmode_offset_z", "0")
			RunConsoleCommand("vrmod_Foregripmode_ang_pitch", "0")
			RunConsoleCommand("vrmod_Foregripmode_ang_yaw", "0")
			RunConsoleCommand("vrmod_Foregripmode_ang_roll", "0")
		end

		-- Add Restore Defaults Button
		local resetButton = vgui.Create("DButton", MenuTab11)
		resetButton:SetPos(20, 400)
		resetButton:SetSize(200, 30)
		resetButton:SetText(L("Restore Default Settings", "Restore Default Settings"))
		resetButton.DoClick = function()
			RunConsoleCommand("vrmod_Foregripmode_range", "30")
			RunConsoleCommand("vrmod_Foregripmode_enable", "1")
			RunConsoleCommand("vrmod_Foregripmode_key_leftprimary", "1")
			RunConsoleCommand("vrmod_Foregripmode_key_leftgrab", "1")
		end

		-- Dual-mode registration
		if frame.Settings02Register then
			local success = frame.Settings02Register("foregrip", "Foregrip", "icon16/controller.png", MenuTab11)
			if not success then
				frame.DPropertySheet:AddSheet("Foregrip", MenuTab11, "icon16/controller.png")
			end
		else
			frame.DPropertySheet:AddSheet("Foregrip", MenuTab11, "icon16/controller.png")
		end
		-- MenuTab11 (Foregrip) End

		end) -- pcall end
		if not ok then
			print("[VRMod] Menu hook error (addsettingsgrip): " .. tostring(err))
		end
	end
)
--------[vrmod_addmenu03.lua]End--------
