if SERVER then return end
local open = false
local button1on = 0
local button2on = GetConVar("vrmod_attach_popup"):GetInt() or 0
local button3on = GetConVar("vrmod_attach_quickmenu"):GetInt() or 0
local button4on = GetConVar("vrmod_allow_teleport_client"):GetInt() or 0
local button5on = 0
local button6on = GetConVar("vrmod_vehicle_reticlemode"):GetInt() or 0
local button7on = GetConVar("vrmod_laserpointer"):GetInt() or 0
local button8on = GetConVar("arcticvr_2h_sens"):GetInt() or 0
local button9on = 0
local buttonAon = GetConVar("vrmod_pickup_retry"):GetInt() or 0
local buttonBon = GetConVar("vr_pickup_disable_client"):GetInt() or 0
local buttonCon = 0
local buttonDon = 0
local BUTTON_2TIER = {Color(80, 0, 51), Color(51, 120, 51)}
local BUTTON_3TIER = {Color(80, 0, 51), Color(142, 111, 48), Color(51, 120, 51)}
local BUTTON_4TIER = {Color(80, 0, 51), Color(142, 111, 48), Color(51, 120, 51), Color(0, 0, 139)}
local BUTTON_5TIER = {Color(80, 0, 51), Color(142, 111, 48), Color(51, 120, 51), Color(0, 0, 139), Color(139, 0, 139)}
function VREaddvrmenuToggle()
	if not open then
		VREaddvrmenuOpen()
	else
		VRUtilMenuClose("vremenu_addvrmenu")
	end
end

function VREaddvrmenuOpen()
	if open then return end
	open = true
	local vreaddvrmenuPanel = vgui.Create("DPanel")
	vreaddvrmenuPanel:SetPos(0, 0)
	vreaddvrmenuPanel:SetSize(600, 650)
	function vreaddvrmenuPanel:GetSize()
		return 450, 310
	end

	local grid = vgui.Create("DGrid", vreaddvrmenuPanel)
	grid:SetPos(10, 30)
	grid:SetCols(4)
	grid:SetColWide(150)
	grid:SetRowHeight(80)
	local backbutton = vgui.Create("DButton", vreaddvrmenuPanel)
	backbutton:SetText("<---")
	backbutton:SetSize(60, 30)
	backbutton:SetPos(260, 270)
	backbutton:SetTextColor(Color(255, 255, 255))
	backbutton.DoClick = function()
		VRUtilMenuClose("vremenu_addvrmenu")
	end

	function backbutton:Paint(w, h)
		draw.RoundedBox(8, 0, 0, w, h, Color(0, 122, 204))
	end

	-- Activate bothmode to be able to press buttons even when using a vehicle.
	LocalPlayer():ConCommand("vrmod_keymode_both")

	--3button toggle start
	local button2 = vgui.Create("DButton")
	button2:SetText("attach_popup: ")
	local ccval2 = {"HMD", "Left", "Right"}
	button2:SetSize(120, 60)
	button2:SetTextColor(Color(255, 255, 255))
	grid:AddItem(button2)
	button2.DoClick = function()
		--command start
		if button2on == 0 then
			button2on = 1
			LocalPlayer():ConCommand("vrmod_attach_popup 1")
		elseif button2on == 1 then
			button2on = 2
			LocalPlayer():ConCommand("vrmod_attach_popup 4")
		else
			button2on = 0
			LocalPlayer():ConCommand("vrmod_attach_popup 3")
		end
	end

	--command end
	function button2:Paint(w, h)
		button2:SetText("attach_popup: " .. ccval2[button2on + 1])
		draw.RoundedBox(8, 0, 0, w, h, BUTTON_3TIER[math.abs(button2on + 1)])
	end

	--3button toggle end
	--3button toggle start
	local button3 = vgui.Create("DButton")
	button3:SetText("attach Menu hand")
	local ccval3 = {"HMD", "Left", "Right"}
	button3:SetSize(120, 60)
	button3:SetTextColor(Color(255, 255, 255))
	grid:AddItem(button3)
	button3.DoClick = function()
		--command start
		if button3on == 0 then
			button3on = 1
			LocalPlayer():ConCommand("vrmod_attach_weaponmenu 1")
			LocalPlayer():ConCommand("vrmod_attach_quickmenu 1")
		elseif button3on == 1 then
			button3on = 2
			LocalPlayer():ConCommand("vrmod_attach_weaponmenu 4")
			LocalPlayer():ConCommand("vrmod_attach_quickmenu 4")
		else
			button3on = 0
			LocalPlayer():ConCommand("vrmod_attach_weaponmenu 3")
			LocalPlayer():ConCommand("vrmod_attach_quickmenu 3")
		end
	end

	--command end
	function button3:Paint(w, h)
		button3:SetText("attach Menu hand: " .. ccval3[button3on + 1])
		draw.RoundedBox(8, 0, 0, w, h, BUTTON_3TIER[math.abs(button3on + 1)])
	end
	--3button toggle end

	--2button toggle start
	local teleposerver = GetConVar("vrmod_allow_teleport")
	if teleposerver:GetBool() then
		local button4 = vgui.Create("DButton")
		button4:SetText("allow_teleport: ")
		button4:SetSize(120, 60)
		button4:SetTextColor(Color(255, 255, 255))
		grid:AddItem(button4)
		button4.DoClick = function()
			--command start
			if button4on == 1 then
				button4on = 0
				LocalPlayer():ConCommand("vrmod_allow_teleport_client 0")
			else
				button4on = 1
				local teleposerver = GetConVar("vrmod_allow_teleport")
				if teleposerver:GetBool() then
					LocalPlayer():ConCommand("vrmod_allow_teleport_client 1")
				end
			end
		end

		--command end
		function button4:Paint(w, h)
			button4:SetText("allow_teleport: " .. GetConVar("vrmod_allow_teleport_client"):GetInt())
			draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[math.abs(button4on - 2)])
		end
	end

	--2button toggle start
	local button5 = vgui.Create("DButton")
	-- local button5on = button5on
	local ccval5 = {"both", "normal", "Walk", "Drive"}
	button5:SetText("keymode: ")
	button5:SetSize(120, 60)
	button5:SetTextColor(Color(255, 255, 255))
	grid:AddItem(button5)
	button5.DoClick = function()
		--command start
		if button5on == 0 then
			button5on = 1
			LocalPlayer():ConCommand("vrmod_keymode_restore")
		elseif button5on == 1 then
			button5on = 2
			LocalPlayer():ConCommand("vrmod_keymode_main")
		elseif button5on == 2 then
			button5on = 3
			LocalPlayer():ConCommand("vrmod_keymode_driving")
		else
			button5on = 0
			LocalPlayer():ConCommand("vrmod_keymode_both")
		end
	end

	--command end
	function button5:Paint(w, h)
		button5:SetText("keymode: " .. ccval5[button5on + 1])
		draw.RoundedBox(8, 0, 0, w, h, BUTTON_4TIER[button5on + 1])
	end

	--2button toggle end
	--2button toggle start
	local button6 = vgui.Create("DButton")
	button6:SetText("Vehicle mode\n")
	local ccval6 = {"[simfphys/HL2Jeep]\nLFS/TANK", "simfphys/HL2Jeep\n[LFS/TANK]"}
	button6:SetSize(120, 60)
	button6:SetTextColor(Color(255, 255, 255))
	grid:AddItem(button6)
	button6.DoClick = function()
		--command start
		if button6on == 1 then
			button6on = 0
			LocalPlayer():ConCommand("vrmod_simfmode")
		else
			button6on = 1
			LocalPlayer():ConCommand("vrmod_lfsmode")
		end
	end

	--command end
	function button6:Paint(w, h)
		button6:SetText("Vehicle mode\n" .. ccval6[button6on + 1])
		draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[math.abs(button6on - 2)])
	end

	--2button toggle end
	--2button toggle start
	local button7 = vgui.Create("DButton")
	button7:SetText("Laserpointer: ")
	button7:SetSize(120, 60)
	button7:SetTextColor(Color(255, 255, 255))
	grid:AddItem(button7)
	button7.DoClick = function()
		--command start
		if button7on == 1 then
			button7on = 0
			LocalPlayer():ConCommand("vrmod_togglelaserpointer")
		else
			button7on = 1
			LocalPlayer():ConCommand("vrmod_togglelaserpointer")
		end
	end

	--command end
	function button7:Paint(w, h)
		button7:SetText("Laserpointer: " .. GetConVar("vrmod_laserpointer"):GetInt())
		draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[math.abs(button7on - 2)])
	end

	--2button toggle end
	if not not GetConVar("arcticvr_2h_sens") then
		--button toggle start
		local button8 = vgui.Create("DButton")
		button8:SetText("ArcVR:ForeGrip-POW :")
		button8:SetSize(120, 60)
		button8:SetTextColor(Color(255, 255, 255))
		grid:AddItem(button8)
		button8.DoClick = function()
			--command start
			if button8on == 0 then
				button8on = 1
				LocalPlayer():ConCommand("arcticvr_2h_sens 1.0")
			elseif button8on == 1 then
				button8on = 2
				LocalPlayer():ConCommand("arcticvr_2h_sens 2.0")
			else
				button8on = 0
				LocalPlayer():ConCommand("arcticvr_2h_sens 0.5")
			end
		end

		--command end
		function button8:Paint(w, h)
			button8:SetText("ArcVR:ForeGrip-POW :" .. GetConVar("arcticvr_2h_sens"):GetInt())
			draw.RoundedBox(8, 0, 0, w, h, BUTTON_3TIER[button8on + 1])
		end

		--button toggle end
		--button toggle start
		local button9 = vgui.Create("DButton")
		button9:SetText("ArcVR_PouchMode: \n")
		button9:SetSize(120, 60)
		local ccval9 = {"default", "hybrid", "head", "inf"}
		button9:SetTextColor(Color(255, 255, 255))
		grid:AddItem(button9)
		button9.DoClick = function()
			--command start				
			if button9on == 0 then
				button9on = 1
				LocalPlayer():ConCommand("arcticvr_hybridpouch 1")
				LocalPlayer():ConCommand("arcticvr_headpouch 0")
				LocalPlayer():ConCommand("arcticvr_infpouch 0")
			elseif button9on == 1 then
				button9on = 2
				LocalPlayer():ConCommand("arcticvr_hybridpouch 0")
				LocalPlayer():ConCommand("arcticvr_headpouch 1")
				LocalPlayer():ConCommand("arcticvr_infpouch 0")
			elseif button9on == 2 then
				button9on = 3
				LocalPlayer():ConCommand("arcticvr_hybridpouch 0")
				LocalPlayer():ConCommand("arcticvr_headpouch 0")
				LocalPlayer():ConCommand("arcticvr_infpouch 1")
			else
				button9on = 0
				LocalPlayer():ConCommand("arcticvr_hybridpouch 0")
				LocalPlayer():ConCommand("arcticvr_headpouch 0")
				LocalPlayer():ConCommand("arcticvr_infpouch 0")
			end
		end

		--command end
		function button9:Paint(w, h)
			button9:SetText("ArcVR_PouchMode: \n" .. ccval9[button9on + 1])
			draw.RoundedBox(8, 0, 0, w, h, BUTTON_4TIER[button9on + 1])
			if GetConVar("vrmod_floatinghands"):GetBool() then
				button9:SetText("ArcVR_PouchMode \n Floating hand Mode")
				draw.RoundedBox(8, 0, 0, w, h, BUTTON_4TIER[button9on + 1])
			end
		end
		--button toggle end
	end

	if not not GetConVar("vrgrab_range") then
		--2button toggle start
		local buttonA = vgui.Create("DButton")
		local ccvalA = {"Item/Gun", "Everything"}
		buttonA:SetText("Pickup Possible\n")
		buttonA:SetSize(120, 60)
		buttonA:SetTextColor(Color(255, 255, 255))
		grid:AddItem(buttonA)
		buttonA.DoClick = function()
			--command start
			if buttonAon == 1 then
				buttonAon = 0
				LocalPlayer():ConCommand("vrmod_pickup_retry 1")
			else
				buttonAon = 1
				LocalPlayer():ConCommand("vrmod_pickup_retry 0")
							end
		end

		--command end
		function buttonA:Paint(w, h)
			buttonA:SetText("Pickup Possible\n" .. ccvalA[buttonAon + 1])
			draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[math.abs(buttonAon - 2)])
		end
		--2button toggle end
	end

	--2button toggle start		
	local buttonB = vgui.Create("DButton")
	buttonB:SetText("disable\npickup: ")
	buttonB:SetSize(120, 60)
	buttonB:SetTextColor(Color(255, 255, 255))
	grid:AddItem(buttonB)
	buttonB.DoClick = function()
		--command start
		if buttonBon == 1 then
			buttonBon = 0
			LocalPlayer():ConCommand("vr_pickup_disable_client 1")
		else
			buttonBon = 1
			LocalPlayer():ConCommand("vr_pickup_disable_client 0")
		end
	end

	--command end
	function buttonB:Paint(w, h)
		buttonB:SetText("pickup_disable: " .. GetConVar("vr_pickup_disable_client"):GetInt())
		draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[math.abs(buttonBon - 2)])
	end

	-- --2button toggle end
	--2button toggle start
	local buttonX = vgui.Create("DButton")
	buttonX:SetText("Server Convar")
	buttonX:SetSize(120, 60)
	buttonX:SetTextColor(Color(255, 255, 255))
	grid:AddItem(buttonX)
	buttonX.DoClick = function()
		--command start
		LocalPlayer():ConCommand("vre_addvrmenu")
		LocalPlayer():ConCommand("vre_svmenu")
	end

	--command end
	function buttonX:Paint(w, h)
		buttonX:SetText("Server Convar")
		draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[1])
	end

	--2button toggle end
	-- --2button toggle start
	-- local button(valuehere) = vgui.Create("DButton")
	-- local button(valuehere)on = 0
	-- button(valuehere):SetText("(namehere): ")
	-- button(valuehere):SetSize(120, 60)
	-- button(valuehere):SetTextColor(Color(255, 255, 255))
	-- grid:AddItem(button(valuehere))
	-- button(valuehere).DoClick = function()
	-- --command start
	-- if button(valuehere)on == 1 then
	-- button(valuehere)on = 0
	-- LocalPlayer():ConCommand("(converhere) 0")
	-- else
	-- button(valuehere)on = 1
	-- LocalPlayer():ConCommand("(converhere) 1")
	-- end
	-- --command end
	-- end
	-- function button(valuehere):Paint(w, h)
	-- button(valuehere):SetText("(namehere): "..GetConVar("(converhere)"):GetInt())
	-- draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[math.abs(button(valuehere)on -2)])
	-- end
	-- -- (valuehere)
	-- -- (namehere)
	-- -- (converhere)
	-- --2button toggle end
	-- --2button toggle start
	-- local button(valuehere) = vgui.Create("DButton")
	-- local button(valuehere)on = 0
	-- button(valuehere):SetText("(namehere): ")
	-- button(valuehere):SetSize(120, 60)
	-- button(valuehere):SetTextColor(Color(255, 255, 255))
	-- grid:AddItem(button(valuehere))
	-- button(valuehere).DoClick = function()
	-- --command start
	-- if button(valuehere)on == 1 then
	-- button(valuehere)on = 0
	-- LocalPlayer():ConCommand("(converhere) 0")
	-- else
	-- button(valuehere)on = 1
	-- LocalPlayer():ConCommand("(converhere) 1")
	-- end
	-- --command end
	-- end
	-- function button(valuehere):Paint(w, h)
	-- button(valuehere):SetText("(namehere): "..GetConVar("(converhere)"):GetInt())
	-- draw.RoundedBox(8, 0, 0, w, h, BUTTON_2TIER[math.abs(button(valuehere)on -2)])
	-- end
	-- -- (valuehere)
	-- -- (namehere)
	-- -- (converhere)
	-- --2button toggle end
	-- Menu code ends here
	local ply = LocalPlayer()
	local renderCount = 0
	local tmp = Angle(0, g_VR.tracking.hmd.ang.yaw - 90, 60) --Forward() = right, Right() = back, Up() = up (relative to panel, panel forward is looking at top of panel from middle of panel, up is normal)
	local pos, ang = WorldToLocal(g_VR.tracking.pose_righthand.pos + tmp:Forward() * -9 + tmp:Right() * -11 + tmp:Up() * -7, tmp, g_VR.origin, g_VR.originAngle)
	local mode = 4
	--uid, width, height, panel, attachment, pos, ang, scale, cursorEnabled, closeFunc
	if vre_menuguiattachment:GetInt("vre_ui_attachtohand") == 1 then
		pos, ang = Vector(4, 6, 5.5), Angle(0, -90, 10) --Forward(), Right(), Up() --Vector(10,6,13), Angle(0,-90,50)
		mode = 1
	else
		pos, ang = WorldToLocal(g_VR.tracking.pose_righthand.pos + tmp:Forward() * -9 + tmp:Right() * -11 + tmp:Up() * -7, tmp, g_VR.origin, g_VR.originAngle)
		mode = 4
	end

	VRUtilMenuOpen(
		"vremenu_addvrmenu",
		600,
		310,
		vreaddvrmenuPanel,
		mode,
		pos,
		ang,
		0.03,
		true,
		function()
			vreaddvrmenuPanel:Remove()
			vreaddvrmenuPanel = nil
			hook.Remove("PreRender", "vre_renderaddvrmenu")
			open = false
		end
	)

	hook.Add(
		"PreRender",
		"vre_renderaddvrmenumenu",
		function()
			if VRUtilIsMenuOpen("miscmenu") or VRUtilIsMenuOpen("vremenu") then
				VRUtilMenuClose("vremenu_addvrmenu")
			elseif IsValid(vreaddvrmenuPanel) then
				function vreaddvrmenuPanel:Paint(w, h)
					surface.SetDrawColor(Color(51, 51, 51, 200))
					surface.DrawRect(0, 0, w, h)
				end

				VRUtilMenuRenderPanel("vremenu_addvrmenu")
			end
		end
	)
end

concommand.Add(
	"vre_addvrmenu",
	function(ply, cmd, args)
		if g_VR.net[ply:SteamID()] then
			VREMenuClose()
			VREaddvrmenuToggle()
		end
	end
)