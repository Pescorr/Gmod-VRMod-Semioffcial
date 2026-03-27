--------[vrmod_muzzle_bone_override.lua]--------
-- Weapon Bone Config: unified per-weapon bone override system
-- Manages muzzle direction, foregrip bone, and magazine bone overrides.
-- Saves/loads per-weapon settings to data/vrmod/weapon_bone_config.json.
--------

if SERVER then return end

g_VR = g_VR or {}
g_VR.muzzleBoneOverride = g_VR.muzzleBoneOverride or {}

-----------------------------------------------
-- Section 1: Config Load / Save
-----------------------------------------------

local CONFIG_PATH = "vrmod/weapon_bone_config.json"
local OLD_CONFIG_PATH = "vrmod/muzzle_bone_override.json"

local SaveConfig -- forward declaration (used by LoadConfig for migration)

local function ValidateMuzzleEntry(entry)
	if not istable(entry) or not isstring(entry.mode) then return nil end
	if entry.mode == "viewmodel" then
		return { mode = "viewmodel" }
	elseif entry.mode == "bone" and isstring(entry.boneName) and entry.boneName ~= "" then
		return { mode = "bone", boneName = entry.boneName }
	end
	return nil
end

local function ValidateBoneEntry(entry)
	if not istable(entry) then return nil end
	if isstring(entry.boneName) and entry.boneName ~= "" then
		return { boneName = entry.boneName }
	end
	return nil
end

local function LoadConfig()
	-- Try new path first, then old path for migration
	local jsonData = nil
	local isOldFormat = false

	if file.Exists(CONFIG_PATH, "DATA") then
		jsonData = file.Read(CONFIG_PATH, "DATA")
	elseif file.Exists(OLD_CONFIG_PATH, "DATA") then
		jsonData = file.Read(OLD_CONFIG_PATH, "DATA")
		isOldFormat = true
	end

	if not jsonData or jsonData == "" then
		g_VR.muzzleBoneOverride = {}
		return
	end

	local success, config = pcall(util.JSONToTable, jsonData)
	if not success or not istable(config) then
		ErrorNoHalt("[VRMod WeaponBoneConfig] Failed to parse config file, starting with empty config\n")
		g_VR.muzzleBoneOverride = {}
		return
	end

	local validated = {}
	for class, entry in pairs(config) do
		if not istable(entry) then continue end

		-- Detect old format: entry has "mode" key directly (muzzle-only)
		if isstring(entry.mode) then
			local muzzle = ValidateMuzzleEntry(entry)
			if muzzle then
				validated[class] = { muzzle = muzzle }
			end
		else
			-- New format: entry has sub-tables
			local weaponEntry = {}
			local hasData = false

			if entry.muzzle then
				local m = ValidateMuzzleEntry(entry.muzzle)
				if m then weaponEntry.muzzle = m; hasData = true end
			end
			if entry.foregrip then
				local f = ValidateBoneEntry(entry.foregrip)
				if f then weaponEntry.foregrip = f; hasData = true end
			end
			if entry.magbone then
				local mb = ValidateBoneEntry(entry.magbone)
				if mb then weaponEntry.magbone = mb; hasData = true end
			end

			if hasData then
				validated[class] = weaponEntry
			end
		end
	end

	g_VR.muzzleBoneOverride = validated

	-- If we loaded from old path, save to new path to complete migration
	if isOldFormat and next(validated) then
		SaveConfig()
	end
end

SaveConfig = function()
	if not g_VR.muzzleBoneOverride then return end

	if not file.IsDir("vrmod", "DATA") then
		file.CreateDir("vrmod")
	end

	-- Clean up empty entries before saving
	local toSave = {}
	for class, entry in pairs(g_VR.muzzleBoneOverride) do
		if istable(entry) and (entry.muzzle or entry.foregrip or entry.magbone) then
			toSave[class] = entry
		end
	end

	local jsonData = util.TableToJSON(toSave, true)
	if not jsonData then
		ErrorNoHalt("[VRMod WeaponBoneConfig] Failed to serialize config to JSON\n")
		return
	end

	file.Write(CONFIG_PATH, jsonData)
end

hook.Add("VRMod_Start", "VRMod_WeaponBoneConfig_Init", LoadConfig)

-----------------------------------------------
-- Section 2: Bone Index Cache (for muzzle)
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

hook.Add("VRMod_Exit", "VRMod_WeaponBoneConfig_CacheCleanup", ClearBoneCache)

-----------------------------------------------
-- Section 3: vrmod.ApplyMuzzleOverride(muzzle)
-----------------------------------------------

function vrmod.ApplyMuzzleOverride(muzzle)
	if not muzzle then return end
	if not g_VR.muzzleBoneOverride then return end

	local ply = LocalPlayer()
	if not IsValid(ply) then return end

	local wep = ply:GetActiveWeapon()
	if not IsValid(wep) then return end

	local class = wep:GetClass()
	local fullEntry = g_VR.muzzleBoneOverride[class]
	if not fullEntry then return end

	-- Support both new format (.muzzle sub-key) and old format (.mode at top level)
	local override = fullEntry.muzzle or (fullEntry.mode and fullEntry) or nil
	if not override then return end

	if override.mode == "viewmodel" then
		if not g_VR.viewModelAng then return end
		muzzle.Ang = Angle(g_VR.viewModelAng.p, g_VR.viewModelAng.y, g_VR.viewModelAng.r)
	elseif override.mode == "bone" and override.boneName then
		if not IsValid(g_VR.viewModel) then return end

		local idx = GetCachedBoneIdx(g_VR.viewModel, class, override.boneName)
		if not idx then return end

		local mtx = g_VR.viewModel:GetBoneMatrix(idx)
		if not mtx then return end

		muzzle.Ang = mtx:GetAngles()
	end

	-- IMPORTANT: muzzle.Pos is NEVER modified
end

-----------------------------------------------
-- Section 4: Foregrip & Magbone API Functions
-----------------------------------------------

function vrmod.GetForegripBoneOverride(class)
	if not g_VR.muzzleBoneOverride then return nil end
	local entry = g_VR.muzzleBoneOverride[class]
	if not entry or not entry.foregrip then return nil end
	if not isstring(entry.foregrip.boneName) or entry.foregrip.boneName == "" then return nil end
	return entry.foregrip.boneName
end

function vrmod.GetMagboneOverride(class)
	if not g_VR.muzzleBoneOverride then return nil end
	local entry = g_VR.muzzleBoneOverride[class]
	if not entry or not entry.magbone then return nil end
	if not isstring(entry.magbone.boneName) or entry.magbone.boneName == "" then return nil end
	return entry.magbone.boneName
end

function vrmod.IsMagboneOverride(class, boneName)
	local overrideName = vrmod.GetMagboneOverride(class)
	if overrideName == nil then return nil end -- No override -> caller falls through to auto-detect
	return (string.lower(boneName) == string.lower(overrideName))
end

-----------------------------------------------
-- Section 5: UI - Unified Weapon Bone Config
-----------------------------------------------

local activeConfigFrame = nil

-- Helper: create a bone list panel for a tab
local function CreateBoneListTab(parent, vm, boneCount, specialRows, currentBoneName, onSelectCallback)
	local panel = vgui.Create("DPanel", parent)
	panel.Paint = function() end

	local listView = vgui.Create("DListView", panel)
	listView:Dock(FILL)
	listView:DockMargin(0, 5, 0, 0)
	listView:SetMultiSelect(false)
	listView:AddColumn("Option")
	listView:AddColumn("Description"):SetFixedWidth(160)

	-- Add special options first
	for _, row in ipairs(specialRows) do
		listView:AddLine(row[1], row[2])
	end

	-- Enumerate bones
	if boneCount and boneCount > 0 then
		for i = 0, boneCount - 1 do
			local boneName = vm:GetBoneName(i)
			if boneName and boneName ~= "" then
				listView:AddLine(boneName, "Bone #" .. i)
			end
		end
	end

	-- Select current setting
	if currentBoneName then
		for i = 1, #listView:GetLines() do
			local line = listView:GetLine(i)
			if line and line:GetValue(1) == currentBoneName then
				listView:SelectItem(line)
				break
			end
		end
	else
		-- Select first row (default)
		listView:SelectItem(listView:GetLine(1))
	end

	listView.OnRowSelected = function(_, rowIdx, row)
		if onSelectCallback then
			onSelectCallback(row:GetValue(1), rowIdx)
		end
	end

	panel.listView = listView
	return panel
end

-- Main command
local function OpenWeaponBoneConfig()
	-- Close existing frame if open
	if IsValid(activeConfigFrame) then
		activeConfigFrame:Close()
		activeConfigFrame = nil
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

	-- Save original config for cancel/restore
	g_VR.muzzleBoneOverride = g_VR.muzzleBoneOverride or {}
	local originalEntry = nil
	if g_VR.muzzleBoneOverride[class] then
		originalEntry = table.Copy(g_VR.muzzleBoneOverride[class])
	end

	-- Track laser pointer state
	local laserWasOff = false
	local laserCV = GetConVar("vrmod_laserpointer")
	if laserCV and not laserCV:GetBool() then
		laserWasOff = true
		RunConsoleCommand("vrmod_togglelaserpointer")
	end

	-- Track magbone preview state for cleanup
	local previewMagBoneIdx = nil

	-- Restore function
	local restored = false
	local function RestoreOriginal()
		if restored then return end
		restored = true

		-- Restore config
		g_VR.muzzleBoneOverride = g_VR.muzzleBoneOverride or {}
		if originalEntry then
			g_VR.muzzleBoneOverride[class] = originalEntry
		else
			g_VR.muzzleBoneOverride[class] = nil
		end

		-- Clear caches
		ClearBoneCache()

		-- Restore magbone preview (unhide any temporarily hidden bone)
		if previewMagBoneIdx and IsValid(vm) then
			vm:ManipulateBoneScale(previewMagBoneIdx, Vector(1, 1, 1))
			previewMagBoneIdx = nil
		end

		-- Restore laser pointer
		if laserWasOff then
			local cv = GetConVar("vrmod_laserpointer")
			if cv and cv:GetBool() then
				RunConsoleCommand("vrmod_togglelaserpointer")
			end
		end

		-- Remove hooks
		hook.Remove("Think", "VRMod_WeaponBoneConfig_WeaponWatch")
		hook.Remove("PostDrawTranslucentRenderables", "VRMod_WeaponBoneConfig_ForegripPreview")
	end

	-- Setup bones for enumeration
	vm:SetupBones()
	local boneCount = vm:GetBoneCount()

	-- Extract current settings for each tab
	local currentMuzzle = originalEntry and originalEntry.muzzle or nil
	local currentForegrip = originalEntry and originalEntry.foregrip or nil
	local currentMagbone = originalEntry and originalEntry.magbone or nil

	-- Helper to get/create the config entry for this weapon
	local function EnsureEntry()
		g_VR.muzzleBoneOverride = g_VR.muzzleBoneOverride or {}
		if not g_VR.muzzleBoneOverride[class] then
			g_VR.muzzleBoneOverride[class] = {}
		end
		return g_VR.muzzleBoneOverride[class]
	end

	-- Helper to clean up empty entries
	local function CleanupEntry()
		local entry = g_VR.muzzleBoneOverride and g_VR.muzzleBoneOverride[class]
		if entry and not entry.muzzle and not entry.foregrip and not entry.magbone then
			g_VR.muzzleBoneOverride[class] = nil
		end
	end

	-- Create frame
	local frame = vgui.Create("DFrame")
	frame:SetSize(500, 600)
	frame:Center()
	frame:SetTitle("Weapon Bone Config - " .. class)
	frame:MakePopup()
	activeConfigFrame = frame

	-- Info label
	local infoLabel = vgui.Create("DLabel", frame)
	infoLabel:SetText("Configure bone overrides for this weapon. Laser pointer shows muzzle direction.")
	infoLabel:SetWrap(true)
	infoLabel:Dock(TOP)
	infoLabel:DockMargin(5, 5, 5, 5)
	infoLabel:SetAutoStretchVertical(true)

	-- Tab sheet
	local sheet = vgui.Create("DPropertySheet", frame)
	sheet:Dock(FILL)
	sheet:DockMargin(5, 0, 5, 5)

	--------------------------
	-- Tab 1: Muzzle
	--------------------------
	local muzzleCurrentBone = nil
	if currentMuzzle then
		if currentMuzzle.mode == "viewmodel" then
			muzzleCurrentBone = "(ViewModelAngle) Hand Direction"
		elseif currentMuzzle.mode == "bone" and currentMuzzle.boneName then
			muzzleCurrentBone = currentMuzzle.boneName
		end
	end

	local muzzleTab = CreateBoneListTab(sheet, vm, boneCount,
		{
			{ "(Default) Muzzle Attachment", "GetAttachment(1) - original" },
			{ "(ViewModelAngle) Hand Direction", "Use viewmodel angle" },
		},
		muzzleCurrentBone,
		function(optionText)
			local entry = EnsureEntry()
			if optionText == "(Default) Muzzle Attachment" then
				entry.muzzle = nil
			elseif optionText == "(ViewModelAngle) Hand Direction" then
				entry.muzzle = { mode = "viewmodel" }
			else
				entry.muzzle = { mode = "bone", boneName = optionText }
			end
			CleanupEntry()
			ClearBoneCache()
		end
	)
	sheet:AddSheet("Muzzle", muzzleTab, "icon16/gun.png")

	--------------------------
	-- Tab 2: Foregrip
	--------------------------
	local foregripCurrentBone = currentForegrip and currentForegrip.boneName or nil

	-- Track foregrip preview bone index for sphere rendering
	local previewForegripBoneIdx = nil

	local foregripTab = CreateBoneListTab(sheet, vm, boneCount,
		{
			{ "(Default) Auto-detect", "Keyword-based detection" },
		},
		foregripCurrentBone,
		function(optionText)
			local entry = EnsureEntry()
			if optionText == "(Default) Auto-detect" then
				entry.foregrip = nil
				previewForegripBoneIdx = nil
			else
				entry.foregrip = { boneName = optionText }
				-- Update preview sphere
				if IsValid(vm) then
					previewForegripBoneIdx = vm:LookupBone(optionText)
				end
			end
			CleanupEntry()
		end
	)
	sheet:AddSheet("Foregrip", foregripTab, "icon16/hand.png")

	-- Initialize foregrip preview if there's a current setting
	if foregripCurrentBone and IsValid(vm) then
		previewForegripBoneIdx = vm:LookupBone(foregripCurrentBone)
	end

	--------------------------
	-- Tab 3: Magazine
	--------------------------
	local magboneCurrentBone = currentMagbone and currentMagbone.boneName or nil

	local magboneTab = CreateBoneListTab(sheet, vm, boneCount,
		{
			{ "(Default) Auto-detect", "Keyword-based detection" },
		},
		magboneCurrentBone,
		function(optionText)
			local entry = EnsureEntry()

			-- Restore previously hidden bone
			if previewMagBoneIdx and IsValid(vm) then
				vm:ManipulateBoneScale(previewMagBoneIdx, Vector(1, 1, 1))
				previewMagBoneIdx = nil
			end

			if optionText == "(Default) Auto-detect" then
				entry.magbone = nil
			else
				entry.magbone = { boneName = optionText }
				-- Preview: hide the selected bone
				if IsValid(vm) then
					local idx = vm:LookupBone(optionText)
					if idx then
						vm:ManipulateBoneScale(idx, Vector(0, 0, 0))
						previewMagBoneIdx = idx
					end
				end
			end
			CleanupEntry()
		end
	)
	sheet:AddSheet("Magazine", magboneTab, "icon16/brick.png")

	-- Initialize magbone preview if there's a current setting
	if magboneCurrentBone and IsValid(vm) then
		local idx = vm:LookupBone(magboneCurrentBone)
		if idx then
			vm:ManipulateBoneScale(idx, Vector(0, 0, 0))
			previewMagBoneIdx = idx
		end
	end

	--------------------------
	-- Foregrip preview rendering hook (green sphere)
	--------------------------
	hook.Add("PostDrawTranslucentRenderables", "VRMod_WeaponBoneConfig_ForegripPreview", function(depth, sky)
		if depth or sky then return end
		if not IsValid(frame) then
			hook.Remove("PostDrawTranslucentRenderables", "VRMod_WeaponBoneConfig_ForegripPreview")
			return
		end
		if not previewForegripBoneIdx then return end
		if not IsValid(vm) then return end

		local pos = vm:GetBonePosition(previewForegripBoneIdx)
		if not pos then return end

		render.SetColorMaterial()
		render.DrawSphere(pos, 1, 12, 12, Color(0, 255, 0, 180))
	end)

	--------------------------
	-- Save button
	--------------------------
	local saveBtn = vgui.Create("DButton", frame)
	saveBtn:SetText("Save")
	saveBtn:Dock(BOTTOM)
	saveBtn:DockMargin(5, 2, 5, 5)
	saveBtn.DoClick = function()
		-- Current state in g_VR.muzzleBoneOverride is what we want to save
		SaveConfig()

		-- Notify consuming modules to refresh their caches
		hook.Run("VRMod_WeaponBoneConfigChanged", class)

		-- Build save confirmation message
		local entry = g_VR.muzzleBoneOverride and g_VR.muzzleBoneOverride[class]
		local parts = {}
		if entry then
			if entry.muzzle then
				if entry.muzzle.mode == "viewmodel" then
					parts[#parts + 1] = "Muzzle=ViewModelAngle"
				elseif entry.muzzle.mode == "bone" then
					parts[#parts + 1] = "Muzzle=" .. entry.muzzle.boneName
				end
			end
			if entry.foregrip then
				parts[#parts + 1] = "Foregrip=" .. entry.foregrip.boneName
			end
			if entry.magbone then
				parts[#parts + 1] = "Magazine=" .. entry.magbone.boneName
			end
		end

		if #parts > 0 then
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Saved bone config for " .. class .. ": " .. table.concat(parts, ", "))
		else
			chat.AddText(Color(0, 255, 0), "[VRMod] ", Color(255, 255, 255), "Cleared bone config for " .. class .. " (using defaults)")
		end

		-- Prevent OnClose from restoring the override
		restored = true

		-- Restore laser pointer state only
		if laserWasOff then
			local cv = GetConVar("vrmod_laserpointer")
			if cv and cv:GetBool() then
				RunConsoleCommand("vrmod_togglelaserpointer")
			end
		end

		-- Clean up preview state
		if previewMagBoneIdx and IsValid(vm) then
			vm:ManipulateBoneScale(previewMagBoneIdx, Vector(1, 1, 1))
			previewMagBoneIdx = nil
		end

		hook.Remove("Think", "VRMod_WeaponBoneConfig_WeaponWatch")
		hook.Remove("PostDrawTranslucentRenderables", "VRMod_WeaponBoneConfig_ForegripPreview")

		frame:Close()
		activeConfigFrame = nil
	end

	--------------------------
	-- Cancel button
	--------------------------
	local cancelBtn = vgui.Create("DButton", frame)
	cancelBtn:SetText("Cancel")
	cancelBtn:Dock(BOTTOM)
	cancelBtn:DockMargin(5, 2, 5, 0)
	cancelBtn.DoClick = function()
		RestoreOriginal()
		frame:Close()
		activeConfigFrame = nil
	end

	-- OnClose safety net
	frame.OnClose = function()
		RestoreOriginal()
		activeConfigFrame = nil
	end

	-- Weapon change detection
	local watchClass = class
	hook.Add("Think", "VRMod_WeaponBoneConfig_WeaponWatch", function()
		if not IsValid(frame) then
			hook.Remove("Think", "VRMod_WeaponBoneConfig_WeaponWatch")
			return
		end

		local p = LocalPlayer()
		if not IsValid(p) then return end

		local w = p:GetActiveWeapon()
		if not IsValid(w) or w:GetClass() ~= watchClass then
			chat.AddText(Color(255, 200, 0), "[VRMod] ", Color(255, 255, 255), "Weapon changed, closing bone config")
			RestoreOriginal()
			frame:Close()
			activeConfigFrame = nil
		end
	end)
end

-- Register commands
concommand.Add("vrmod_weapon_bone_config", function() OpenWeaponBoneConfig() end)
concommand.Add("vrmod_muzzle_bone_select", function() OpenWeaponBoneConfig() end) -- backward compat alias
