--------[vrmod_addmenu03.lua]Start--------
AddCSLuaFile()
if SERVER then return end
local convars, convarValues = vrmod.GetConvars()
hook.Add(
	"VRMod_Menu",
	"addsettingsgrip",
	function(frame)
		--Settings02 Start
		--add VRMod_Menu Settings02 propertysheet start
		local sheet = vgui.Create("DPropertySheet", frame.DPropertySheet)
		frame.DPropertySheet:AddSheet("VRGrip", sheet)
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
		-- MenuTab11 (Foregrip) End

		



	end
)
-- DNumSlider End
-- MenuTab15 (Beam Pickup) End
--Settings02 end
--------[vrmod_addmenu03.lua]End--------