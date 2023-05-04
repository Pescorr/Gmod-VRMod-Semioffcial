if SERVER then return end

local meta = getmetatable(vgui.GetWorldPanel())
local orig = meta.MakePopup

local popupCount = 0
local basePos, baseAng
local _, convarValues = vrmod.GetConvars()


meta.MakePopup = function(...)
	local args = {...}
	orig(unpack(args))
	
	if not g_VR.threePoints then return end
	
	local panel = args[1]
	
	timer.Simple(0.01,function() --wait because makepopup might be called before menu is fully built
		if not IsValid(panel) then return end
	
		if panel:GetName() == "DMenu" then
			--temporary hack because paintmanual doesnt seem to work on the dmenu for some reason
			panel = panel:GetChildren()[1]
			panel.Paint = function(self,w,h) surface.SetDrawColor(255,255,255,255) surface.DrawRect( 0, 0, w, h ) end
		end
	
		if popupCount == 0 then
			local ang = Angle(0,g_VR.tracking.hmd.ang.yaw-90,45)
			basePos, baseAng = WorldToLocal( g_VR.tracking.hmd.pos + Vector(0,0,-20) + Angle(0,g_VR.tracking.hmd.ang.yaw,0):Forward()*30 + ang:Forward()*ScrW()*-0.02 + ang:Right()*ScrH()*-0.02, ang, g_VR.origin, g_VR.originAngle)
		end
		
		--right = down, up = normal, forward = right
		local ang = baseAng
		local pos = basePos + ang:Up()*popupCount*0.1
		
		local mode = convarValues.vrmod_attach_popup

		if mode == 1 then
		--
		VRUtilMenuOpen("popup_"..popupCount, ScrW(),ScrH(), panel, mode, Vector(20,11,8), Angle(0,-90,50), 0.03, true, function() --forw, left, up
			timer.Simple(0.1,function()
				if not g_VR.active and IsValid(panel) then
					panel:MakePopup() --make sure we don't leave unclickable panels open when exiting vr
				end
			end)
			popupCount = popupCount - 1
		end)
		popupCount = popupCount + 1
		
		VRUtilMenuRenderPanel(uid)
		--
		elseif mode == 3 then
		VRUtilMenuOpen("popup_"..popupCount, ScrW(),ScrH(), panel, 3, Vector(30,20,10), Angle(0,-90,90), 0.03, true, function() --forw, left, up
			timer.Simple(0.001,function()
				if not g_VR.active and IsValid(panel) then
					panel:MakePopup() --make sure we don't leave unclickable panels open when exiting vr
				end
			end)
			popupCount = popupCount - 1
		end)
		popupCount = popupCount + 1
		
		VRUtilMenuRenderPanel(uid)
		--
		else
		VRUtilMenuOpen("popup_"..popupCount, ScrW(),ScrH(), panel, mode, pos,ang, 0.03, true, function() --forw, left, up
			timer.Simple(0.001,function()
				if !g_VR.active and IsValid(panel) then
					panel:MakePopup() --make sure we don't leave unclickable panels open when exiting vr
				end
			end)
			popupCount = popupCount - 1
		end)
		popupCount = popupCount + 1
		
		VRUtilMenuRenderPanel(uid)

		end
	end)
		
end

hook.Add("VRMod_Start","dermapopups",function(ply)
	if ply ~= LocalPlayer() then return end
	vgui.GetWorldPanel():SetSize(ScrW(),ScrH())
end)

hook.Add("VRMod_Exit","dermapopups",function(ply)
	if ply ~= LocalPlayer() then return end
	
	vgui.GetWorldPanel():SetSize(ScrW(),ScrH())
end)
