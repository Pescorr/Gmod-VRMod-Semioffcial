if SERVER then return end

	g_VR = g_VR or {}
	g_VR.characterYaw = 0
	local convars,convarValues = vrmod.GetConvars()

function VRUtilOpenHeightMenu()
	if not g_VR.threePoints or VRUtilIsMenuOpen("heightmenu") then return end
	
	--create mirror
	
	rt_mirror = GetRenderTarget( "rt_vrmod_heightcalmirror", 2048, 2048)
	mat_mirror = CreateMaterial("mat_vrmod_heightcalmirror", "Core_DX90", {["$basetexture"] = "rt_vrmod_heightcalmirror", ["$model"] = "1"})
	
	local mirrorYaw = 0
	
	hook.Add( "PreDrawTranslucentRenderables", "vrmodheightmirror", function(depth, skybox) 
		if depth or skybox or not (EyePos()==g_VR.eyePosLeft or EyePos()==g_VR.eyePosRight) then return end
	
		local ad = math.AngleDifference(EyeAngles().yaw, mirrorYaw)
		if math.abs(ad) > 45 then
			mirrorYaw = mirrorYaw + (ad > 0 and 45 or -45)
		end
	
		local mirrorPos = Vector(g_VR.tracking.hmd.pos.x, g_VR.tracking.hmd.pos.y, g_VR.origin.z + 45) + Angle(0,mirrorYaw,0):Forward()*50
		local mirrorAng = Angle(0,mirrorYaw-90,90)
		
		-- g_VR.menus.heightmenu.pos = mirrorPos + Vector(0,0,30) + mirrorAng:Forward()*-15
		-- g_VR.menus.heightmenu.ang = mirrorAng
		
		local camPos = LocalToWorld( WorldToLocal( EyePos(), Angle(), mirrorPos, mirrorAng) * Vector(1,1,-1), Angle(), mirrorPos, mirrorAng)
		local camAng = EyeAngles()
		camAng = Angle(camAng.pitch, mirrorAng.yaw + (mirrorAng.yaw - camAng.yaw), 180-camAng.roll)
	
		cam.Start({x = 0, y = 0, w = 2048, h = 2048, type = "3D", fov = g_VR.view.fov, aspect = -g_VR.view.aspectratio, origin = camPos, angles = camAng})
			render.PushRenderTarget(rt_mirror)
				render.Clear(200,230,255,0,true,true)
				render.CullMode(1)
					local alloworig = g_VR.allowPlayerDraw
					g_VR.allowPlayerDraw = true
					cam.Start3D() cam.End3D()
					local ogEyePos = EyePos
					EyePos = function() return Vector(0,0,0) end
					local ogRenderOverride = LocalPlayer().RenderOverride
					LocalPlayer().RenderOverride = nil
					render.SuppressEngineLighting(true)
					LocalPlayer():DrawModel()
					render.SuppressEngineLighting(false)
					EyePos = ogEyePos
					LocalPlayer().RenderOverride = ogRenderOverride
					g_VR.allowPlayerDraw = alloworig
					cam.Start3D() cam.End3D()
				render.CullMode(0)
			render.PopRenderTarget()
		cam.End3D()
	
		render.SetMaterial(mat_mirror)
		render.DrawQuadEasy(mirrorPos,mirrorAng:Up(),30,60,Color(255,255,255,255),0)

	end )

	--create controls
	
	local mode = convarValues.vrmod_attach_heightmenu
	
	if mode == 0 then

		VRUtilMenuOpen("heightmenu", 300, 512, nil, 0, Vector(), Angle(), 0.1, true, function()
			hook.Remove("PreDrawTranslucentRenderables", "vrmodheightmirror")
			hook.Remove("VRMod_Input","vrmodheightmenuinput")
		end)

	else
	
		VRUtilMenuOpen("heightmenu", 300, 512, nil, 1, Vector(4,6,15.5), Angle(0,-90,60), 0.03, true, function()
			hook.Remove("PreDrawTranslucentRenderables", "vrmodheightmirror")
			hook.Remove("VRMod_Input","vrmodheightmenuinput")
		end)

	end

	
	local buttons, renderControls
	
	renderControls = function()
		VRUtilMenuRenderStart("heightmenu")
		VRUtilMenuRenderEnd()
	end
	
	renderControls()
	
end

hook.Add("VRMod_Start","vrmod_OpenHeightMenuOnStartup",function(ply)
	if ply == LocalPlayer() and convars.vrmod_heightmenu:GetBool() then
		timer.Create("vrmod_HeightMenuStartupWait",1,0,function()
			if g_VR.threePoints then
				timer.Remove("vrmod_HeightMenuStartupWait")
				VRUtilOpenHeightMenu()
			end
		end)
	end
end)
