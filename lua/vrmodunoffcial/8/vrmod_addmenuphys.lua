AddCSLuaFile()
if SERVER then return end
local convars, convarValues = vrmod.GetConvars()
hook.Add(
	"VRMod_Menu",
	"addsettingsvrphysgun",
	function(frame)
		--Settings02 Start
		--add VRMod_Menu Settings02 propertysheet start
		local sheet = vgui.Create("DPropertySheet", frame.DPropertySheet)
		frame.DPropertySheet:AddSheet("VRPhysgun", sheet)
		sheet:Dock(FILL)
		--add VRMod_Menu Settings02 propertysheet end
		
		
		-- MenuTab16 (Physgun Left) Start
		local physgunmaxrange = GetConVar("physgun_maxrange") or CreateClientConVar("physgun_maxrange", "4096", true, false)
		local MenuTab16 = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Physgun Left", MenuTab16, "icon16/brick.png")
		MenuTab16.Paint = function(self, w, h) end
		
		-- タイトル
		local title = vgui.Create("DLabel", MenuTab16)
		title:SetText("VR Physgun Settings (LEFT HAND)")
		title:SetFont("DermaDefaultBold")
		title:SetTextColor(Color(0, 0, 0))
		title:SetPos(20, 10)
		title:SizeToContents()
		
		-- ビーム有効/無効
		local enableBeam = vgui.Create("DCheckBoxLabel", MenuTab16)
		enableBeam:SetText("Enable Physgun Beams")
		enableBeam:SetConVar("vrmod_left_physgun_beam_enable")
		enableBeam:SetPos(20, 35)
		enableBeam:SizeToContents()
		
		-- ビーム距離
		local beamRange = vgui.Create("DNumSlider", MenuTab16)
		beamRange:SetText("Beam Range")
		beamRange:SetMin(10)
		beamRange:SetMax(physgunmaxrange:GetFloat())
		beamRange:SetDecimals(0)
		beamRange:SetConVar("vrmod_left_physgun_beam_range")
		beamRange:SetPos(20, 65)
		beamRange:SetSize(370, 20)
		
		-- ビーム色 - Alpha
		local colorA = vgui.Create("DNumSlider", MenuTab16)
		colorA:SetText("Beam Alpha")
		colorA:SetMin(0)
		colorA:SetMax(255)
		colorA:SetDecimals(0)
		colorA:SetConVar("vrmod_left_physgun_beam_color_a")
		colorA:SetPos(20, 95)
		colorA:SetSize(370, 20)
		
		-- ダメージ有効/無効
		local enableDamage = vgui.Create("DCheckBoxLabel", MenuTab16)
		enableDamage:SetText("Enable Beam Damage")
		enableDamage:SetConVar("vrmod_left_physgun_beam_damage_enable")
		enableDamage:SetPos(20, 125)
		enableDamage:SizeToContents()
		
		-- ダメージ量
		local damageAmount = vgui.Create("DNumSlider", MenuTab16)
		damageAmount:SetText("Beam Damage Amount")
		damageAmount:SetMin(0.0001)
		damageAmount:SetMax(0.0100)
		damageAmount:SetDecimals(4)
		damageAmount:SetConVar("vrmod_left_physgun_beam_damage")
		damageAmount:SetPos(20, 155)
		damageAmount:SetSize(370, 20)
		
		-- 引き寄せ機能有効/無効
		local enablePull = vgui.Create("DCheckBoxLabel", MenuTab16)
		enablePull:SetText("Enable Pull Feature (Grip Button)")
		enablePull:SetConVar("vrmod_left_physgun_pull_enable")
		enablePull:SetPos(20, 185)
		enablePull:SizeToContents()
		
		-- 使い方説明
		local instructions = vgui.Create("DLabel", MenuTab16)
		instructions:SetText("Use the left hand trigger to grab objects and grip button to pull them closer")
		instructions:SetTextColor(Color(0, 0, 0))
		instructions:SetPos(20, 215)
		instructions:SetSize(370, 40)
		instructions:SetWrap(true)
		-- MenuTab16 (Physgun Left) End
		
		-- MenuTab17 (Physgun Right) Start
		local MenuTab17 = vgui.Create("DPanel", sheet)
		sheet:AddSheet("Physgun Right", MenuTab17, "icon16/brick_add.png")
		MenuTab17.Paint = function(self, w, h) end
		
		-- タイトル
		local title = vgui.Create("DLabel", MenuTab17)
		title:SetText("VR Physgun Settings (RIGHT HAND)")
		title:SetFont("DermaDefaultBold")
		title:SetTextColor(Color(0, 0, 0))
		title:SetPos(20, 10)
		title:SizeToContents()
		
		-- ビーム有効/無効
		local enableBeam = vgui.Create("DCheckBoxLabel", MenuTab17)
		enableBeam:SetText("Enable Physgun Beams")
		enableBeam:SetConVar("vrmod_right_physgun_beam_enable")
		enableBeam:SetPos(20, 35)
		enableBeam:SizeToContents()
		
		-- ビーム距離
		local beamRange = vgui.Create("DNumSlider", MenuTab17)
		beamRange:SetText("Beam Range")
		beamRange:SetMin(10)
		beamRange:SetMax(physgunmaxrange:GetFloat())
		beamRange:SetDecimals(0)
		beamRange:SetConVar("vrmod_right_physgun_beam_range")
		beamRange:SetPos(20, 65)
		beamRange:SetSize(370, 20)
		
		-- ビーム色 - Alpha
		local colorA = vgui.Create("DNumSlider", MenuTab17)
		colorA:SetText("Beam Alpha")
		colorA:SetMin(0)
		colorA:SetMax(255)
		colorA:SetDecimals(0)
		colorA:SetConVar("vrmod_right_physgun_beam_color_a")
		colorA:SetPos(20, 95)
		colorA:SetSize(370, 20)
		
		-- ダメージ有効/無効
		local enableDamage = vgui.Create("DCheckBoxLabel", MenuTab17)
		enableDamage:SetText("Enable Beam Damage")
		enableDamage:SetConVar("vrmod_right_physgun_beam_damage_enable")
		enableDamage:SetPos(20, 125)
		enableDamage:SizeToContents()
		
		-- ダメージ量
		local damageAmount = vgui.Create("DNumSlider", MenuTab17)
		damageAmount:SetText("Beam Damage Amount")
		damageAmount:SetMin(0.0001)
		damageAmount:SetMax(0.0100)
		damageAmount:SetDecimals(4)
		damageAmount:SetConVar("vrmod_right_physgun_beam_damage")
		damageAmount:SetPos(20, 155)
		damageAmount:SetSize(370, 20)
		
		-- 引き寄せ機能有効/無効
		local enablePull = vgui.Create("DCheckBoxLabel", MenuTab17)
		enablePull:SetText("Enable Pull Feature (Grip Button)")
		enablePull:SetConVar("vrmod_right_physgun_pull_enable")
		enablePull:SetPos(20, 185)
		enablePull:SizeToContents()
		
		-- 使い方説明
		local instructions = vgui.Create("DLabel", MenuTab17)
		instructions:SetText("Use the right hand trigger to grab objects and grip button to pull them closer")
		instructions:SetTextColor(Color(0, 0, 0))
		instructions:SetPos(20, 215)
		instructions:SetSize(370, 40)
		instructions:SetWrap(true)
		-- MenuTab17 (Physgun Right) End
	end
)

-- Physgunシステムのメニュー登録を削除（既にタブに移行したため）
hook.Remove("VRMod_Menu", "vrmod_physgun_menu_left")
hook.Remove("VRMod_Menu", "vrmod_physgun_menu_right")