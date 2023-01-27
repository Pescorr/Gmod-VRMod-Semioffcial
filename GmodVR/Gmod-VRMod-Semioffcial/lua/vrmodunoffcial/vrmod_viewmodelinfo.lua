if CLIENT then

	g_VR = g_VR or {}
	g_VR.viewModelInfo = g_VR.viewModelInfo or {}
	
	g_VR.viewModelInfo.autoOffsetAddPos = Vector(1,0.2, 0)

	
	g_VR.currentvmi = nil
	
	
	g_VR.viewModelInfo.gmod_tool = {
		--modelOverride = "models/weapons/w_toolgun.mdl",
		offsetPos = Vector(-12, 6.5, 7), --forw, left, up
		offsetAng = Angle(0, 0, 0),
	}
	
	g_VR.viewModelInfo.weapon_physgun = {
		offsetPos = Vector(-24.5, 13.4, 14.5),
		offsetAng = Angle(0, 0, 0),
	}
	
	g_VR.viewModelInfo.weapon_physcannon = {
		offsetPos = Vector(-24.5, 13.4, 14.5),
		offsetAng = Angle(0, 0, 0),
	}
	
	
	g_VR.viewModelInfo.weapon_shotgun = {
		offsetPos = Vector(-14.5, 10, 8.5),
		offsetAng = Angle(0, 0, 0),
	}
	
	g_VR.viewModelInfo.weapon_rpg = {
		offsetPos = Vector(-27.5, 19, 10.5),
		offsetAng = Angle(0, 0, 0),
	}
	
	g_VR.viewModelInfo.weapon_crossbow = {
		offsetPos = Vector(-14.5, 10, 8.5),
		offsetAng = Angle(0, 0, 0),
	}
	
	g_VR.viewModelInfo.weapon_medkit = {
		offsetPos = Vector(-23,10,5),
		offsetAng = Angle(0, 0, 0),
	}
	
	g_VR.viewModelInfo.weapon_crowbar = {
		wrongMuzzleAng = true
	}
	
	g_VR.viewModelInfo.weapon_stunstick = {
		wrongMuzzleAng = true
	}
	
end