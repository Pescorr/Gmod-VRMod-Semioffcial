--------[vrmod_addmenu03.lua]Start--------
AddCSLuaFile()
if SERVER then return end
local convars, convarValues = vrmod.GetConvars()
hook.Add(
	"VRMod_Menu",
	"addsettings03",
	function(frame)
		--Settings02 Start
		--add VRMod_Menu Settings02 propertysheet start
		local sheet = vgui.Create("DPropertySheet", frame.DPropertySheet)
		frame.DPropertySheet:AddSheet("VRGrip&Pickup", sheet)
		sheet:Dock(FILL)
		--add VRMod_Menu Settings02 propertysheet end
		-- MenuTab11 (Foregrip) Start
		local MenuTab11 = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Foregrip", MenuTab11, "icon16/controller.png")
		MenuTab11.Paint = function(self, w, h) end
		-- DNumSlider Start
		-- vrmod_Foregripmode_range
		local foregripmode_range = vgui.Create("DNumSlider", MenuTab11)
		foregripmode_range:SetPos(20, 10)
		foregripmode_range:SetSize(370, 25)
		foregripmode_range:SetText("Foregrip Mode Range")
		foregripmode_range:SetMin(1)
		foregripmode_range:SetMax(100)
		foregripmode_range:SetDecimals(0)
		foregripmode_range:SetConVar("vrmod_Foregripmode_range")
		foregripmode_range.OnValueChanged = function(self, value) end
		-- DNumSlider End
		-- DCheckBoxLabel Start
		local foregripmode_enable = MenuTab11:Add("DCheckBoxLabel")
		foregripmode_enable:SetPos(20, 40)
		foregripmode_enable:SetText("Enable Foregrip Mode")
		foregripmode_enable:SetConVar("vrmod_Foregripmode_enable")
		foregripmode_enable:SizeToContents()
		-- DCheckBoxLabel End
		-- DNumSlider Start
		-- vrmod_Foregripmode_key_leftprimary
		local vrmod_Foregripmode_key_leftprimary = vgui.Create("DNumSlider", MenuTab11)
		vrmod_Foregripmode_key_leftprimary:SetPos(20, 70)
		vrmod_Foregripmode_key_leftprimary:SetSize(370, 25)
		vrmod_Foregripmode_key_leftprimary:SetText("Foregrip[boolean_left_primary]Key")
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
		vrmod_Foregripmode_key_leftgrab:SetText("Foregrip[boolean_left_pickup]Key")
		vrmod_Foregripmode_key_leftgrab:SetMin(0)
		vrmod_Foregripmode_key_leftgrab:SetMax(2)
		vrmod_Foregripmode_key_leftgrab:SetDecimals(0)
		vrmod_Foregripmode_key_leftgrab:SetConVar("vrmod_Foregripmode_key_leftgrab")
		vrmod_Foregripmode_key_leftgrab.OnValueChanged = function(self, value) end
		-- DNumSlider End
		-- 全体的な回転感度
		local foregrip_rotation_sensitivity = vgui.Create("DNumSlider", MenuTab11)
		foregrip_rotation_sensitivity:SetPos(20, 130)
		foregrip_rotation_sensitivity:SetSize(370, 25)
		foregrip_rotation_sensitivity:SetText("Overall Rotation Sensitivity")
		foregrip_rotation_sensitivity:SetMin(0)
		foregrip_rotation_sensitivity:SetMax(1)
		foregrip_rotation_sensitivity:SetDecimals(2)
		foregrip_rotation_sensitivity:SetConVar("vrmod_foregrip_rotation_sensitivity")
		foregrip_rotation_sensitivity.OnValueChanged = function(self, value) end
		-- ピッチ軸のブレンド
		local foregrip_pitch_blend = vgui.Create("DNumSlider", MenuTab11)
		foregrip_pitch_blend:SetPos(20, 160)
		foregrip_pitch_blend:SetSize(370, 25)
		foregrip_pitch_blend:SetText("Pitch Axis Blend (0: Right Hand, 1: Left Hand)")
		foregrip_pitch_blend:SetMin(0)
		foregrip_pitch_blend:SetMax(1)
		foregrip_pitch_blend:SetDecimals(2)
		foregrip_pitch_blend:SetConVar("vrmod_foregrip_pitch_blend")
		foregrip_pitch_blend.OnValueChanged = function(self, value) end
		-- ヨー軸のブレンド
		local foregrip_yaw_blend = vgui.Create("DNumSlider", MenuTab11)
		foregrip_yaw_blend:SetPos(20, 190)
		foregrip_yaw_blend:SetSize(370, 25)
		foregrip_yaw_blend:SetText("Yaw Axis Blend (0: Right Hand, 1: Left Hand)")
		foregrip_yaw_blend:SetMin(0)
		foregrip_yaw_blend:SetMax(1)
		foregrip_yaw_blend:SetDecimals(2)
		foregrip_yaw_blend:SetConVar("vrmod_foregrip_yaw_blend")
		foregrip_yaw_blend.OnValueChanged = function(self, value) end
		-- ロール軸のブレンド
		local foregrip_roll_blend = vgui.Create("DNumSlider", MenuTab11) 
		foregrip_roll_blend:SetPos(20, 220)
		foregrip_roll_blend:SetSize(370, 25)
		foregrip_roll_blend:SetText("Roll Axis Blend (0: Right Hand, 1: Left Hand)")
		foregrip_roll_blend:SetMin(0)
		foregrip_roll_blend:SetMax(1)
		foregrip_roll_blend:SetDecimals(2)
		foregrip_roll_blend:SetConVar("vrmod_foregrip_roll_blend")
		foregrip_roll_blend.OnValueChanged = function(self, value) end
		-- MenuTab11 (Foregrip) End
		-- -- MenuTab12 (Entity Teleport) Start
		-- local MenuTab12 = vgui.Create("DPanel", sheet)
		-- sheet:AddSheet("Entity Teleport", MenuTab12, "icon16/wand.png")
		-- MenuTab12.Paint = function(self, w, h) end
		-- -- DCheckBoxLabel Start
		-- local entteleport_enable = MenuTab12:Add("DCheckBoxLabel")
		-- entteleport_enable:SetPos(20, 10)
		-- entteleport_enable:SetText("Enable Entity Teleport")
		-- entteleport_enable:SetConVar("vrmod_test_entteleport_enable")
		-- entteleport_enable:SizeToContents()
		-- -- DCheckBoxLabel End
		-- -- DNumSlider Start
		-- -- vrmod_test_entteleport_range
		-- local entteleport_range = vgui.Create("DNumSlider", MenuTab12)
		-- entteleport_range:SetPos(20, 40)
		-- entteleport_range:SetSize(370, 25)
		-- entteleport_range:SetText("Entity Teleport Range")
		-- entteleport_range:SetMin(1)
		-- entteleport_range:SetMax(100)
		-- entteleport_range:SetDecimals(0)
		-- entteleport_range:SetConVar("vrmod_test_entteleport_range")
		-- entteleport_range.OnValueChanged = function(self, value) end
		-- -- DNumSlider End
		-- -- MenuTab12 (Entity Teleport) End
		-- MenuTab15 (Beam Pickup) Start
		local MenuTab15 = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Beam Pickup", MenuTab15, "icon16/lightning.png")
		MenuTab15.Paint = function(self, w, h) end
		-- DCheckBoxLabel Start
		local beampickup_enable = MenuTab15:Add("DCheckBoxLabel")
		beampickup_enable:SetPos(20, 10)
		beampickup_enable:SetText("Enable Beam Pickup")
		beampickup_enable:SetConVar("vrmod_pickup_beam_enable")
		beampickup_enable:SizeToContents()
		-- DCheckBoxLabel End
		-- DNumSlider Start
		-- vrmod_pickup_beamrange
		local beampickup_range = vgui.Create("DNumSlider", MenuTab15)
		beampickup_range:SetPos(20, 40)
		beampickup_range:SetSize(370, 25)
		beampickup_range:SetText("Beam Pickup Range")
		beampickup_range:SetMin(1)
		beampickup_range:SetMax(1000)
		beampickup_range:SetDecimals(0)
		beampickup_range:SetConVar("vrmod_pickup_beamrange")
		beampickup_range.OnValueChanged = function(self, value) end
		-- DNumSlider End
		-- DNumSlider Start
		-- vrmod_pickup_beamrange02
		local beampickup_range02 = vgui.Create("DNumSlider", MenuTab15)
		beampickup_range02:SetPos(20, 70)
		beampickup_range02:SetSize(370, 25)
		beampickup_range02:SetText("Beam Pickup Range 02")
		beampickup_range02:SetMin(1)
		beampickup_range02:SetMax(100)
		beampickup_range02:SetDecimals(0)
		beampickup_range02:SetConVar("vrmod_pickup_beamrange02")
		beampickup_range02.OnValueChanged = function(self, value) end
		-- DNumSlider End
		-- DNumSlider Start
		-- vrmod_pickup_weight
		local beampickup_weight = vgui.Create("DNumSlider", MenuTab15)
		beampickup_weight:SetPos(20, 100)
		beampickup_weight:SetSize(370, 25)
		beampickup_weight:SetText("Beam Pickup Weight")
		beampickup_weight:SetMin(1)
		beampickup_weight:SetMax(1000)
		beampickup_weight:SetDecimals(0)
		beampickup_weight:SetConVar("vrmod_pickup_weight")
		beampickup_weight.OnValueChanged = function(self, value) end
		-- DCheckBoxLabel Start
		local pickup_beam_damage_enable = MenuTab15:Add("DCheckBoxLabel")
		pickup_beam_damage_enable:SetPos(20, 140)
		pickup_beam_damage_enable:SetText("pickup dummy damage")
		pickup_beam_damage_enable:SetConVar("vrmod_pickup_beam_damage_enable")
		pickup_beam_damage_enable:SizeToContents()
		-- DCheckBoxLabel End
		local pickup_beam_damage = vgui.Create("DNumSlider", MenuTab15)
		pickup_beam_damage:SetPos(20, 160)
		pickup_beam_damage:SetSize(370, 25)
		pickup_beam_damage:SetText("Beam dummy Damage")
		pickup_beam_damage:SetMin(0)
		pickup_beam_damage:SetMax(0.001)
		pickup_beam_damage:SetDecimals(4)
		pickup_beam_damage:SetConVar("vrmod_pickup_beam_damage")
		pickup_beam_damage.OnValueChanged = function(self, value) end
	end
)
-- DNumSlider End
-- MenuTab15 (Beam Pickup) End
--Settings02 end
--------[vrmod_addmenu03.lua]End--------