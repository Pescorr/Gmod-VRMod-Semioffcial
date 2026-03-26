--------[vrmod_addmenu03.lua]Start--------
AddCSLuaFile()
if SERVER then return end
local convars, convarValues = vrmod.GetConvars()
hook.Add(
	"VRMod_Menu",
	"addsettingsvrpickupbeam",
	function(frame)
		if not frame.physgunSheet then return end
		-- MenuTab15 (Cone Pickup Assist) Start
		local MenuTab15 = vgui.Create("DPanel", frame.physgunSheet)
		frame.physgunSheet:AddSheet("Pickup Assist", MenuTab15, "icon16/lightning.png")
		MenuTab15.Paint = function(self, w, h) end

		local yPos = 10

		-- Enable checkbox
		local beampickup_enable = MenuTab15:Add("DCheckBoxLabel")
		beampickup_enable:SetPos(20, yPos)
		beampickup_enable:SetText("Enable Cone Pickup Assist")
		beampickup_enable:SetConVar("vrmod_pickup_beam_enable")
		beampickup_enable:SizeToContents()
		yPos = yPos + 30

		-- Sphere Range slider
		local sphere_range = vgui.Create("DNumSlider", MenuTab15)
		sphere_range:SetPos(20, yPos)
		sphere_range:SetSize(370, 25)
		sphere_range:SetText("Pickup Assist Range (units)")
		sphere_range:SetMin(1)
		sphere_range:SetMax(1000)
		sphere_range:SetDecimals(0)
		sphere_range:SetConVar("vrmod_pickup_beam_cone_range")
		yPos = yPos + 30

		-- Max Retries slider
		local retry_max = vgui.Create("DNumSlider", MenuTab15)
		retry_max:SetPos(20, yPos)
		retry_max:SetSize(370, 25)
		retry_max:SetText("Max Retry Ticks")
		retry_max:SetMin(1)
		retry_max:SetMax(30)
		retry_max:SetDecimals(0)
		retry_max:SetConVar("vrmod_pickup_beam_retry_max")
		yPos = yPos + 30

		-- Weight slider (server limit)
		local beampickup_weight = vgui.Create("DNumSlider", MenuTab15)
		beampickup_weight:SetPos(20, yPos)
		beampickup_weight:SetSize(370, 25)
		beampickup_weight:SetText("Max Pickup Weight (Server)")
		beampickup_weight:SetMin(1)
		beampickup_weight:SetMax(1000)
		beampickup_weight:SetDecimals(0)
		beampickup_weight:SetConVar("vrmod_pickup_weight")
		yPos = yPos + 30

		-- Client weight limit slider
		local client_weight = vgui.Create("DNumSlider", MenuTab15)
		client_weight:SetPos(20, yPos)
		client_weight:SetSize(370, 25)
		client_weight:SetText("Client Weight Limit (0=off)")
		client_weight:SetMin(0)
		client_weight:SetMax(1000)
		client_weight:SetDecimals(0)
		client_weight:SetConVar("vrmod_unoff_pickup_weight_client")
		yPos = yPos + 30

		-- Client pickup limit slider
		local client_limit = vgui.Create("DNumSlider", MenuTab15)
		client_limit:SetPos(20, yPos)
		client_limit:SetSize(370, 25)
		client_limit:SetText("Client Pickup Limit (0=off,1=std,2=strict,3=disable)")
		client_limit:SetMin(0)
		client_limit:SetMax(3)
		client_limit:SetDecimals(0)
		client_limit:SetConVar("vrmod_unoff_pickup_limit_client")
		yPos = yPos + 35

		-- Rotation section
		local rotate_enable = MenuTab15:Add("DCheckBoxLabel")
		rotate_enable:SetPos(20, yPos)
		rotate_enable:SetText("Enable Held Entity Rotation (SecFire + Wrist Twist)")
		rotate_enable:SetConVar("vrmod_unoff_rotate_held_enable")
		rotate_enable:SizeToContents()
		yPos = yPos + 25

		local rotate_speed = vgui.Create("DNumSlider", MenuTab15)
		rotate_speed:SetPos(20, yPos)
		rotate_speed:SetSize(370, 25)
		rotate_speed:SetText("Rotation Sensitivity")
		rotate_speed:SetMin(0)
		rotate_speed:SetMax(3.0)
		rotate_speed:SetDecimals(1)
		rotate_speed:SetConVar("vrmod_unoff_rotate_held_speed")
		yPos = yPos + 35

		-- Damage section
		local pickup_beam_damage_enable = MenuTab15:Add("DCheckBoxLabel")
		pickup_beam_damage_enable:SetPos(20, yPos)
		pickup_beam_damage_enable:SetText("Enable Ragdoll Beam Damage")
		pickup_beam_damage_enable:SetConVar("vrmod_pickup_beam_damage_enable")
		pickup_beam_damage_enable:SizeToContents()
		yPos = yPos + 25

		local pickup_beam_damage = vgui.Create("DNumSlider", MenuTab15)
		pickup_beam_damage:SetPos(20, yPos)
		pickup_beam_damage:SetSize(370, 25)
		pickup_beam_damage:SetText("Beam Damage Amount")
		pickup_beam_damage:SetMin(0)
		pickup_beam_damage:SetMax(0.001)
		pickup_beam_damage:SetDecimals(4)
		pickup_beam_damage:SetConVar("vrmod_pickup_beam_damage")
		yPos = yPos + 35

		-- HUD overlay checkbox
		local hud_enable = MenuTab15:Add("DCheckBoxLabel")
		hud_enable:SetPos(20, yPos)
		hud_enable:SetText("Show Held Entity Info on HUD")
		hud_enable:SetConVar("vrmod_unoff_pickup_hud")
		hud_enable:SizeToContents()
		yPos = yPos + 35

		-- Restore Defaults Button
		local resetButton = vgui.Create("DButton", MenuTab15)
		resetButton:SetPos(20, yPos)
		resetButton:SetSize(200, 30)
		resetButton:SetText(VRModL("btn_restore_defaults", "Restore Default Settings"))
		resetButton.DoClick = function()
			VRModResetCategory("beam_pickup")
			VRModResetCategory("client_weight")
			VRModResetCategory("rotation")
		end

	end
)
--------[vrmod_addmenu03.lua]End--------
