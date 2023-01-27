ArcticVR = ArcticVR or {}
ArcticVR.AttachmentTable = {}
ArcticVR.AttachmentIDTable = {}
ArcticVR.NumAttachments = 1
ArcticVR.GenerateAttEntities = true

local dnt_types = {}

function ArcticVR.LoadAttachmentType(att)
	ArcticVR.AttachmentTable[att.Name] = att
	ArcticVR.AttachmentIDTable[ArcticVR.NumAttachments] = att.Name

	att.ID = ArcticVR.NumAttachments

	if ArcticVR.GenerateAttEntities then
		if !(dnt_types[att.Type] or att.DoNotRegister) and att.WorldModel or att.Model then
			local attent = {}
			attent.Base = "arcticvr_att"
			attent.PrintName = att.PrintName
			attent.Spawnable = true
			attent.Category = "Arctic VR - Attachments"
			attent.Model = att.WorldModel or att.Model
			attent.ArcticVR = true
			attent.ArcticVRAttachment = true
			attent.AttID = att.Name

			for i, k in pairs(att) do
				attent[i] = k
			end

			scripted_ents.Register( attent, "avratt_" .. att.Name )
		end
	end

	ArcticVR.NumAttachments = ArcticVR.NumAttachments + 1
end

for k, v in pairs(file.Find("arcticvr/attachments/*", "LUA")) do
	include("arcticvr/attachments/" .. v)
	AddCSLuaFile("arcticvr/attachments/" .. v)
end

if CLIENT then
	spawnmenu.AddCreationTab( "#spawnmenu.category.entities", function()

		local ctrl = vgui.Create( "SpawnmenuContentPanel" )
		ctrl:EnableSearch( "entities", "PopulateEntities" )
		ctrl:CallPopulateHook( "PopulateEntities" )

		return ctrl

	end, "icon16/bricks.png", 20 )
end