--------[vrmod_muzzle_bone_override.lua]--------
-- Muzzle Bone Override: per-weapon muzzle direction correction
-- Allows users to select a specific bone as the firing direction reference
-- for weapons whose muzzle attachment angle is wrong (90/180 degrees off).
--------

if SERVER then return end

g_VR = g_VR or {}
g_VR.muzzleBoneOverride = g_VR.muzzleBoneOverride or {}

-----------------------------------------------
-- Section 1: Config Load / Save
-----------------------------------------------

local CONFIG_PATH = "vrmod/muzzle_bone_override.json"

local function LoadMuzzleBoneConfig()
	if not file.Exists(CONFIG_PATH, "DATA") then
		g_VR.muzzleBoneOverride = {}
		return
	end

	local jsonData = file.Read(CONFIG_PATH, "DATA")
	if not jsonData or jsonData == "" then
		g_VR.muzzleBoneOverride = {}
		return
	end

	local success, config = pcall(util.JSONToTable, jsonData)
	if not success or not istable(config) then
		ErrorNoHalt("[VRMod MuzzleBoneOverride] Failed to parse config file, starting with empty config\n")
		g_VR.muzzleBoneOverride = {}
		return
	end

	-- Validate each entry
	local validated = {}
	for class, entry in pairs(config) do
		if istable(entry) and isstring(entry.mode) then
			if entry.mode == "viewmodel" then
				validated[class] = { mode = "viewmodel" }
			elseif entry.mode == "bone" and isstring(entry.boneName) and entry.boneName ~= "" then
				validated[class] = { mode = "bone", boneName = entry.boneName }
			end
		end
	end

	g_VR.muzzleBoneOverride = validated
end

local function SaveMuzzleBoneConfig()
	if not g_VR.muzzleBoneOverride then return end

	if not file.IsDir("vrmod", "DATA") then
		file.CreateDir("vrmod")
	end

	local jsonData = util.TableToJSON(g_VR.muzzleBoneOverride, true)
	if not jsonData then
		ErrorNoHalt("[VRMod MuzzleBoneOverride] Failed to serialize config to JSON\n")
		return
	end

	file.Write(CONFIG_PATH, jsonData)
end

hook.Add("VRMod_Start", "VRMod_MuzzleBoneOverride_Init", LoadMuzzleBoneConfig)

-----------------------------------------------
-- Section 2: Bone Index Cache
-----------------------------------------------

local boneCache = { class = "", boneName = "", boneIdx = nil, resolved = false }

local function GetCachedBoneIdx(vm, class, boneName)
	if boneCache.class == class and boneCache.boneName == boneName and boneCache.resolved then
		return boneCache.boneIdx -- nil means "bone not found" (cached negative result)
	end

	local idx = vm:LookupBone(boneName)
	boneCache = { class = class, boneName = boneName, boneIdx = idx, resolved = true }
	return idx
end

local function ClearBoneCache()
	boneCache = { class = "", boneName = "", boneIdx = nil, resolved = false }
end

hook.Add("VRMod_Exit", "VRMod_MuzzleBoneOverride_CacheCleanup", ClearBoneCache)

-----------------------------------------------
-- Section 3: vrmod.ApplyMuzzleOverride(muzzle)
-----------------------------------------------

function vrmod.ApplyMuzzleOverride(muzzle)
	-- Guard: muzzle table must exist
	if not muzzle then return end

	-- Guard: override config must exist
	if not g_VR.muzzleBoneOverride then return end

	-- Guard: valid player and weapon
	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) then return end

	local class = wep:GetClass()
	local override = g_VR.muzzleBoneOverride[class]
	if not override then return end -- No override for this weapon -> use default

	if override.mode == "viewmodel" then
		-- Use the viewmodel's angle (hand direction with offset applied)
		if not g_VR.viewModelAng then return end
		muzzle.Ang = Angle(g_VR.viewModelAng.p, g_VR.viewModelAng.y, g_VR.viewModelAng.r)
	elseif override.mode == "bone" and override.boneName then
		-- Use a specific bone's angle from the positioned viewmodel
		if not IsValid(g_VR.viewModel) then return end

		local idx = GetCachedBoneIdx(g_VR.viewModel, class, override.boneName)
		if not idx then return end -- Bone not found -> use default (no modification)

		local mtx = g_VR.viewModel:GetBoneMatrix(idx)
		if not mtx then return end

		muzzle.Ang = mtx:GetAngles()
	end

	-- IMPORTANT: muzzle.Pos is NEVER modified
end

-----------------------------------------------
-- Section 4: UI - Console Command + DFrame
-----------------------------------------------

local activeMuzzleFrame = nil

concommand.Add("vrmod_muzzle_bone_select", function()
	-- Close existing frame if open
	if IsValid(activeMuzzleFrame) then
		activeMuzzleFrame:Close()
		activeMuzzleFrame = nil
	end

	-- Validate VR state
	if not g_VR or not g_VR.active then
		chat.AddText(Color(255, 0, 0), "[VRMod] ", Color(255, 255, 255), "VR is not active")
		return
	end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) then
		chat.AddText(Color(255, 0, 0), "[VRMod] ", Color(255, 255, 255), "No weapon equipped")
		return
	end

	local class = wep:GetClass()

	local vm = ply:GetViewModel()
	if not IsValid(vm) then
		chat.AddText(Color(255, 0, 0), "[VRMod] ", Color(255, 255, 255), "No viewmodel available for: " .. class)
		return
	end

	-- Save original override for cancel/restore
	local originalOverride = nil
	if g_VR.muzzleBoneOverride and g_VR.muzzleBoneOverride[class] then
		originalOverride = table.Copy(g_VR.muzzleBoneOverride[class])
	end

	-- Track if we auto-enabled the laser pointer
	local laserWasOff = false
	local laserCV = GetConVar("vrmod_laserpointer")
	if laserCV and not laserCV:GetBool() then
		laserWasOff = true
		RunConsoleCommand("vrmod_togglelaserpointer")
	end

	-- Restore function (used by Cancel and OnClose)
	local restored = false
	local function RestoreOriginal()
		if restored then return end
		restored = true

		-- Restore override config
		g_VR.muzzleBoneOverride = g_VR.muzzleBoneOverride or {}
		if originalOverride then
			g_VR.muzzleBoneOverride[class] = originalOverride
		else
			g_VR.muzzleBoneOverride[class] = nil
		end

		-- Clear bone cache so it re-resolves
		ClearBoneCache()

		-- Restore laser pointer if we auto-enabled it
		if laserWasOff then
			local cv = GetConVar("vrmod_laserpointer")
			if cv and cv:GetBool() then
				RunConsoleCommand("vrmod_togglelaserpointer")
			end
		end

		-- Remove weapon watch hook
		hook.Remove("Think", "VRMod_MuzzleBoneUI_WeaponWatch")
	end

	-- Create frame
	local frame = vgui.Create("DFrame")
	frame:SetSize(400, 500)
	frame:Center()
	frame:SetTitle("Muzzle Direction Override - " .. class)
	frame:MakePopup()
	activeMuzzleFrame = frame

	-- Info label
	local infoLabel = vgui.Create("DLabel", frame)
	infoLabel:SetText("Select a bone/mode. The laser pointer shows the direction in real-time.")
	infoLabel:SetWrap(true)
	infoLabel:Dock(TOP)
	infoLabel:DockMargin(5, 5, 5, 5)
	infoLabel:SetAutoStretchVertical(true)

	-- Current setting label
	local currentLabel = vgui.Create("DLabel", frame)
	local currentText = "Current: (Default) Muzzle Attachment"
	if originalOverride then
		if originalOverride.mode == "viewmodel" then
			currentText = "Current: (ViewModelAngle) Hand Direction"
		elseif originalOverride.mode == "bone" then
			currentText = "Current: Bone - " .. (originalOverride.boneName or "?")
		end
	end
	currentLabel:SetText(currentText)
	currentLabel:Dock(TOP)
	currentLabel:DockMargin(5, 0, 5, 5)
	currentLabel:SetAutoStretchVertical(true)

	-- List view
	local listView = vgui.Create("DListView", frame)
	listView:Dock(FILL)
	listView:DockMargin(5, 5, 5, 5)
	listView:SetMultiSelect(false)
	listView:AddColumn("Option")
	listView:AddColumn("Description"):SetFixedWidth(160)

	-- Add special options
	listView:AddLine("(Default) Muzzle Attachment", "GetAttachment(1) - original")
	listView:AddLine("(ViewModelAngle) Hand Direction", "Use viewmodel angle")

	-- Enumerate bones from the viewmodel
	vm:SetupBones()
	local boneCount = vm:GetBoneCount()
	if boneCount and boneCount > 0 then
		for i = 0, boneCount - 1 do
			local boneName = vm:GetBoneName(i)
			if boneName and boneName ~= "" then
				listView:AddLine(boneName, "Bone #" .. i)
			end
		end
	end

	-- Select current setting in the list
	if not originalOverride then
		listView:SelectItem(listView:GetLine(1))
	elseif originalOverride.mode == "viewmodel" then
		listView:SelectItem(listView:GetLine(2))
	elseif originalOverride.mode == "bone" and originalOverride.boneName then
		for i = 1, #listView:GetLines() do
			local line = listView:GetLine(i)
			if line and line:GetValue(1) == originalOverride.boneName then
				listView:SelectItem(line)
				break
			end
		end
	end

	-- On row selected: apply temporary override for real-time laser preview
	listView.OnRowSelected = function(_, rowIdx, row)
		local optionText = row:GetValue(1)

		g_VR.muzzleBoneOverride = g_VR.muzzleBoneOverride or {}

		if optionText == "(Default) Muzzle Attachment" then
			-- Remove override -> use default
			g_VR.muzzleBoneOverride[class] = nil
		elseif optionText == "(ViewModelAngle) Hand Direction" then
			g_VR.muzzleBoneOverride[class] = { mode = "viewmodel" }
		else
			-- It's a bone name
			g_VR.muzzleBoneOverride[class] = { mode = "bone", boneName = optionText }
		end

		-- Clear bone cache so it re-resolves immediately
		ClearBoneCache()
	end

	-- Save button
	local saveBtn = vgui.Create("DButton", frame)
	saveBtn:SetText("Save")
	saveBtn:Dock(BOTTOM)
	saveBtn:DockMargin(5, 2, 5, 5)
	saveBtn.DoClick = function()
		-- Current state in g_VR.muzzleBoneOverride is already what we want
		SaveMuzzleBoneConfig()

		local currentOverride = g_VR.muzzleBoneOverride and g_VR.muzzleBoneOverride[class]
		if currentOverride then
			if currentOverride.mode == "viewmodel" then
				chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Saved muzzle override for " .. class .. ": ViewModelAngle")
			elseif currentOverride.mode == "bone" then
				chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Saved muzzle override for " .. class .. ": " .. currentOverride.boneName)
			end
		else
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Removed muzzle override for " .. class .. " (using default)")
		end

		-- Restore laser pointer state only, don't restore override
		restored = true -- Prevent OnClose from restoring the override
		if laserWasOff then
			local cv = GetConVar("vrmod_laserpointer")
			if cv and cv:GetBool() then
				RunConsoleCommand("vrmod_togglelaserpointer")
			end
		end
		hook.Remove("Think", "VRMod_MuzzleBoneUI_WeaponWatch")

		frame:Close()
		activeMuzzleFrame = nil
	end

	-- Cancel button
	local cancelBtn = vgui.Create("DButton", frame)
	cancelBtn:SetText("Cancel")
	cancelBtn:Dock(BOTTOM)
	cancelBtn:DockMargin(5, 2, 5, 0)
	cancelBtn.DoClick = function()
		RestoreOriginal()
		frame:Close()
		activeMuzzleFrame = nil
	end

	-- OnClose safety net (handles X button, Escape, etc.)
	frame.OnClose = function()
		RestoreOriginal()
		activeMuzzleFrame = nil
	end

	-- Weapon change detection: close UI if weapon changes
	local watchClass = class
	hook.Add("Think", "VRMod_MuzzleBoneUI_WeaponWatch", function()
		if not IsValid(frame) then
			hook.Remove("Think", "VRMod_MuzzleBoneUI_WeaponWatch")
			return
		end

		local p = LocalPlayer()
		if not IsValid(p) then return end

		local w = p:GetActiveWeapon()
		if not IsValid(w) or w:GetClass() ~= watchClass then
			chat.AddText(Color(255, 200, 0), "[VRMod] ", Color(255, 255, 255), "Weapon changed, closing muzzle bone selector")
			RestoreOriginal()
			frame:Close()
			activeMuzzleFrame = nil
		end
	end)
end)
