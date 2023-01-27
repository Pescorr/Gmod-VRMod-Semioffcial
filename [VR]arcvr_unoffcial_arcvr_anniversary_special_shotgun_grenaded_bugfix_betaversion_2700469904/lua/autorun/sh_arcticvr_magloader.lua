ArcticVR = ArcticVR or {}
ArcticVR.MagazineTable = {}
ArcticVR.NumMagazines = 0
ArcticVR.GenerateMagEntities = true

local dnt_types = {}

function ArcticVR.LoadMagazineType(mag)
	ArcticVR.MagazineTable[mag.Name] = mag
	ArcticVR.NumMagazines = ArcticVR.NumMagazines + 1

	if ArcticVR.GenerateMagEntities then
		if !(dnt_types[mag.Type] or mag.DoNotRegister) and mag.Model then
			local magent = {}
			magent.Base = "arcticvr_mag"
			magent.PrintName = mag.PrintName
			magent.Spawnable = true
			magent.Category = "Arctic VR - Magazines"
			magent.Rounds = mag.Capacity
			magent.ArcticVR = true
			magent.ArcticVRMagazine = true
			magent.MagID = mag.Name

			for i, k in pairs(mag) do
				magent[i] = k
			end

			scripted_ents.Register( magent, "avrmag_" .. mag.Name )
		end
	end
end

-- function ArcticVR.LoadentityType(mag)
	-- ArcticVR.MagazineTable[mag.Name] = mag
	-- ArcticVR.NumMagazines = ArcticVR.NumMagazines + 1

	-- if ArcticVR.GenerateMagEntities then
		-- if !(dnt_types[mag.Type] or mag.DoNotRegister) and mag.Model then
			-- local magent = {}
			-- magent.Base = "arcticvr_mag"
			-- magent.PrintName = mag.PrintName
			-- magent.Spawnable = true
			-- magent.Category = "Arctic VR - Magazines"
			-- magent.Rounds = mag.Capacity
			-- magent.ArcticVR = true
			-- magent.ArcticVRMagazine = true
			-- magent.MagID = mag.Name

			-- for i, k in pairs(mag) do
				-- magent[i] = k
			-- end

			-- scripted_ents.Register( magent, "" .. mag.Name )
		-- end
	-- end
-- end


for k, v in pairs(file.Find("arcticvr/magazines/*", "LUA")) do
	include("arcticvr/magazines/" .. v)
	AddCSLuaFile("arcticvr/magazines/" .. v)
end

if CLIENT then
	spawnmenu.AddCreationTab( "#spawnmenu.category.entities", function()

		local ctrl = vgui.Create( "SpawnmenuContentPanel" )
		ctrl:EnableSearch( "entities", "PopulateEntities" )
		ctrl:CallPopulateHook( "PopulateEntities" )

		return ctrl

	end, "icon16/bricks.png", 20 )
end