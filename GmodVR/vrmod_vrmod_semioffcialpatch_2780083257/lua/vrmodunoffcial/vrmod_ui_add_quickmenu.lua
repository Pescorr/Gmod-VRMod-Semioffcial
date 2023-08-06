if CLIENT then
	local button1on = 0
	vrmod.AddInGameMenuItem(
		"seated mode",
		1,
		2,
		function()
			if button1on == 1 then
				button1on = 0
				LocalPlayer():ConCommand("vrmod_seated 1")
			else
				button1on = 1
				LocalPlayer():ConCommand("vrmod_seated 0")
			end
		end
	)

	vrmod.AddInGameMenuItem(
		"VRE addmenu",
		0,
		2,
		function()
			LocalPlayer():ConCommand("vre_addvrmenu")
		end
	)

	vrmod.AddInGameMenuItem(
		"vre gb-radial",
		0,
		3,
		function()
			LocalPlayer():ConCommand("vre_gb-radial")
		end
	)
	--
end