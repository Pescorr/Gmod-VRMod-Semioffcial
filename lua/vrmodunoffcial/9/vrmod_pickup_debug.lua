--[vrmod_pickup_debug.lua]start--
-- Pickup state visualizer: HUD overlay + debug menu integration
-- HUD: ConVar vrmod_unoff_pickup_hud (toggleable, works in VR)
-- Debug: integrated into Debug Monitor tab (developer mode required)
-- Console: vrmod_pickup_debug_dump (server log), vrmod_pickup_debug_reset (emergency)
AddCSLuaFile()

-----------------------------------------------------------------------
-- SERVER
-----------------------------------------------------------------------
if SERVER then
	if not util then return end
	util.AddNetworkString("vrmod_pickup_dbg_req")
	util.AddNetworkString("vrmod_pickup_dbg_res")

	net.Receive("vrmod_pickup_dbg_req", function(len, ply)
		if not IsValid(ply) then return end
		net.Start("vrmod_pickup_dbg_res")

		if not vrmod or not vrmod.pickupDebug then
			net.WriteUInt(0, 4) -- not available
			net.Send(ply)
			return
		end

		local pickupList, pickupCount, pickupController = vrmod.pickupDebug()

		net.WriteUInt(1, 4) -- data available
		net.WriteUInt(pickupCount, 8)
		net.WriteBool(IsValid(pickupController))

		local MAX_SEND = 16
		local sendCount = math.min(pickupCount, MAX_SEND)
		for i = 1, sendCount do
			local t = pickupList[i]
			if not t or not istable(t) then
				net.WriteUInt(0, 2)
			else
				local entV = IsValid(t.ent)
				local physV = IsValid(t.phys)
				local plyV = IsValid(t.ply)
				net.WriteUInt(entV and physV and plyV and 1 or 2, 2)
				net.WriteBool(entV)
				net.WriteBool(physV)
				net.WriteBool(plyV)
				net.WriteBool(t.left or false)
				net.WriteString(t.steamid or "?")
				net.WriteString(entV and tostring(t.ent:GetClass()) or "?")
				net.WriteFloat(physV and t.phys:GetMass() or -1)
				net.WriteBool(physV and t.phys:IsMoveable() or false)
				net.WriteString(plyV and t.ply:Nick() or "?")
			end
		end

		net.Send(ply)
	end)

	-- Server console dump
	concommand.Add("vrmod_pickup_debug_dump", function()
		if not vrmod or not vrmod.pickupDebug then print("[VRMod] pickupDebug not available") return end
		local list, count, ctrl = vrmod.pickupDebug()
		print("=== Pickup Table: count=" .. count .. " ctrl=" .. tostring(ctrl) .. " ===")
		for i = 1, count do
			local t = list[i]
			if not t or not istable(t) then
				print("  [" .. i .. "] CORRUPT")
			else
				print(string.format("  [%d] %s hand=%s ply=%s mass=%.0f %s",
					i, IsValid(t.ent) and t.ent:GetClass() or "INVALID",
					t.left and "L" or "R", tostring(t.steamid),
					IsValid(t.phys) and t.phys:GetMass() or -1,
					(IsValid(t.ent) and IsValid(t.phys) and IsValid(t.ply)) and "OK" or "ERR"))
			end
		end
	end)

	-- Emergency reset (no confirmation popup)
	concommand.Add("vrmod_pickup_debug_reset", function()
		if not vrmod or not vrmod.pickupDebug then return end
		local list, count = vrmod.pickupDebug()
		for i = count, 1, -1 do
			local t = list[i]
			if t and istable(t) and t.steamid and drop then
				pcall(drop, t.steamid, t.left)
			else
				list[i] = nil
			end
		end
		print("[VRMod] Pickup table force-reset done")
	end)

	return
end

-----------------------------------------------------------------------
-- CLIENT: HUD overlay + debug panel integration
-----------------------------------------------------------------------

-- ConVar
CreateClientConVar("vrmod_unoff_pickup_hud", 0, true, FCVAR_ARCHIVE, "Show held entity info on HUD", 0, 1)

local cv_hud

-- ========================================
-- Part 1: HUD Overlay (works for all users)
-- Shows what each hand is holding
-- ========================================

surface.CreateFont("VRPickupHUD", {
	font = "Arial",
	size = 16,
	weight = 600,
})

surface.CreateFont("VRPickupHUDSmall", {
	font = "Arial",
	size = 13,
	weight = 500,
})

local function GetHeldInfo(ent)
	if not IsValid(ent) then return nil end
	local info = {}
	info.class = ent:GetClass()
	info.model = ent:GetModel()
	local phys = ent:GetPhysicsObject()
	if IsValid(phys) then
		info.mass = phys:GetMass()
		info.frozen = not phys:IsMoveable()
	end
	-- Short display name: use model filename if prop, else class
	if info.model and string.find(info.class, "prop_") then
		info.name = string.GetFileFromFilename(info.model) or info.class
		info.name = string.StripExtension(info.name)
	else
		info.name = info.class
	end
	return info
end

local function DrawHandInfo(x, y, label, info, align)
	local textAlign = align or TEXT_ALIGN_LEFT
	local clrLabel = Color(160, 180, 220, 200)
	local clrName = Color(230, 235, 245, 230)
	local clrMass = Color(170, 200, 170, 200)
	local clrFrozen = Color(240, 180, 60, 200)

	draw.SimpleText(label, "VRPickupHUDSmall", x, y, clrLabel, textAlign)
	y = y + 16

	if not info then
		draw.SimpleText("--", "VRPickupHUD", x, y, Color(100, 105, 115, 150), textAlign)
		return
	end

	draw.SimpleText(info.name, "VRPickupHUD", x, y, clrName, textAlign)
	y = y + 18

	local detail = ""
	if info.mass then
		detail = string.format("%.0f kg", info.mass)
	end
	if info.frozen then
		detail = detail .. " [FROZEN]"
		draw.SimpleText(detail, "VRPickupHUDSmall", x, y, clrFrozen, textAlign)
	elseif detail ~= "" then
		draw.SimpleText(detail, "VRPickupHUDSmall", x, y, clrMass, textAlign)
	end
end

hook.Add("HUDPaint", "vrmod_unoff_pickup_hud", function()
	if not cv_hud then cv_hud = GetConVar("vrmod_unoff_pickup_hud") end
	if not cv_hud or not cv_hud:GetBool() then return end
	if not g_VR or not g_VR.active then return end

	local scrW, scrH = ScrW(), ScrH()
	local marginBottom = 80
	local marginSide = 20
	local y = scrH - marginBottom

	-- Left hand
	local leftEnt = g_VR.heldEntityLeft
	local leftPhys = g_VR["physgunHeldEntity_left"]
	local leftInfo = GetHeldInfo(leftEnt) or GetHeldInfo(leftPhys)
	if leftInfo and leftPhys and not leftEnt then
		leftInfo.name = leftInfo.name .. " [PHY]"
	end

	-- Right hand
	local rightEnt = g_VR.heldEntityRight
	local rightPhys = g_VR["physgunHeldEntity_right"]
	local rightInfo = GetHeldInfo(rightEnt) or GetHeldInfo(rightPhys)
	if rightInfo and rightPhys and not rightEnt then
		rightInfo.name = rightInfo.name .. " [PHY]"
	end

	-- Only draw if something is held
	if not leftInfo and not rightInfo then return end

	-- Semi-transparent background bar
	local barH = 54
	local barY = y - barH
	surface.SetDrawColor(0, 0, 0, 100)
	surface.DrawRect(0, barY, scrW, barH)

	DrawHandInfo(marginSide, barY + 2, "LEFT HAND", leftInfo, TEXT_ALIGN_LEFT)
	DrawHandInfo(scrW - marginSide, barY + 2, "RIGHT HAND", rightInfo, TEXT_ALIGN_RIGHT)
end)

-- ========================================
-- Part 2: Debug Menu Tab Integration
-- (developer_mode required, added to Debug Monitor)
-- ========================================

-- Server data cache for debug panel
local serverDebugData = nil
local lastPollTime = 0

net.Receive("vrmod_pickup_dbg_res", function()
	local mode = net.ReadUInt(4)
	if mode == 0 then
		serverDebugData = { available = false, time = CurTime() }
		return
	end

	local d = {
		available = true,
		time = CurTime(),
		count = net.ReadUInt(8),
		ctrlValid = net.ReadBool(),
		slots = {},
	}

	for i = 1, d.count do
		local status = net.ReadUInt(2)
		if status == 0 then
			table.insert(d.slots, { corrupt = true })
		else
			local s = {
				corrupt = false,
				entValid = net.ReadBool(),
				physValid = net.ReadBool(),
				plyValid = net.ReadBool(),
				isLeft = net.ReadBool(),
				steamid = net.ReadString(),
				class = net.ReadString(),
				mass = net.ReadFloat(),
				moveable = net.ReadBool(),
				nick = net.ReadString(),
			}
			s.ok = s.entValid and s.physValid and s.plyValid
			table.insert(d.slots, s)
		end
	end

	serverDebugData = d
end)

local function PollServer()
	if CurTime() - lastPollTime < 0.5 then return end
	lastPollTime = CurTime()
	net.Start("vrmod_pickup_dbg_req")
	net.SendToServer()
end

-- Debug Menu Tab (only when developer mode is on)
hook.Add("VRMod_Menu", "vrmod_pickup_debug_menutab", function(frame)
	local devMode = GetConVar("vrmod_unoff_developer_mode")
	if not devMode or not devMode:GetBool() then return end
	if not frame.debugSheet then return end

	local panel = vgui.Create("DPanel", frame.debugSheet)
	frame.debugSheet:AddSheet("Pickup Table", panel, "icon16/table.png")

	panel.Paint = function(self, w, h)
		-- Poll
		PollServer()

		-- Background
		draw.RoundedBox(4, 0, 0, w, h, Color(30, 30, 35))

		local x, y = 10, 8

		-- Title
		draw.SimpleText("Pickup Table Inspector", "DermaDefaultBold", x, y, Color(220, 225, 235))
		y = y + 22

		local d = serverDebugData
		if not d then
			draw.SimpleText("Requesting data...", "DermaDefault", x, y, Color(150, 150, 150))
			return
		end

		if not d.available then
			draw.SimpleText("vrmod.pickupDebug() not available", "DermaDefault", x, y, Color(240, 70, 70))
			draw.SimpleText("Start VR first, then reopen this tab", "DermaDefault", x, y + 16, Color(130, 130, 130))
			return
		end

		-- Status line
		local ctrlClr = d.ctrlValid and Color(80, 200, 80) or Color(130, 130, 130)
		draw.SimpleText(d.ctrlValid and "Controller: ACTIVE" or "Controller: nil", "DermaDefault", x, y, ctrlClr)

		local countClr = d.count > 0 and Color(220, 225, 235) or Color(130, 130, 130)
		draw.SimpleText("Count: " .. d.count, "DermaDefault", x + 150, y, countClr)

		local age = CurTime() - d.time
		draw.SimpleText(string.format("%.1fs ago", age), "DermaDefault", w - 70, y, age < 1.5 and Color(80, 200, 80) or Color(240, 70, 70))
		y = y + 20

		-- Column header
		draw.RoundedBox(2, 4, y, w - 8, 16, Color(45, 45, 55))
		draw.SimpleText("#", "DermaDefault", 10, y, Color(100, 130, 200))
		draw.SimpleText("Status", "DermaDefault", 26, y, Color(100, 130, 200))
		draw.SimpleText("Hand", "DermaDefault", 70, y, Color(100, 130, 200))
		draw.SimpleText("Entity", "DermaDefault", 110, y, Color(100, 130, 200))
		draw.SimpleText("Mass", "DermaDefault", 260, y, Color(100, 130, 200))
		draw.SimpleText("Move", "DermaDefault", 310, y, Color(100, 130, 200))
		draw.SimpleText("Player", "DermaDefault", 360, y, Color(100, 130, 200))
		y = y + 18

		if d.count == 0 then
			draw.SimpleText("Table empty (nothing held)", "DermaDefault", 10, y + 4, Color(130, 130, 130))
			return
		end

		for i, s in ipairs(d.slots) do
			local bgClr = s.corrupt and Color(80, 25, 25, 200) or (i % 2 == 0 and Color(38, 40, 50) or Color(30, 33, 40))
			draw.RoundedBox(2, 4, y, w - 8, 17, bgClr)

			if s.corrupt then
				draw.SimpleText(i, "DermaDefault", 10, y, Color(240, 70, 70))
				draw.SimpleText("CORRUPT", "DermaDefaultBold", 26, y, Color(240, 70, 70))
			else
				draw.SimpleText(i, "DermaDefault", 10, y, Color(130, 130, 130))
				draw.SimpleText(s.ok and "OK" or "ERR", "DermaDefaultBold", 26, y, s.ok and Color(80, 200, 80) or Color(240, 70, 70))
				draw.SimpleText(s.isLeft and "L" or "R", "DermaDefault", 70, y, Color(220, 225, 235))
				draw.SimpleText(s.class, "DermaDefault", 110, y, s.entValid and Color(220, 225, 235) or Color(240, 70, 70))
				draw.SimpleText(s.mass >= 0 and string.format("%.0f", s.mass) or "?", "DermaDefault", 260, y, Color(220, 225, 235))
				draw.SimpleText(s.moveable and "yes" or "FRZ", "DermaDefault", 310, y, s.moveable and Color(80, 200, 80) or Color(240, 190, 40))
				draw.SimpleText(s.nick, "DermaDefault", 360, y, s.plyValid and Color(130, 130, 130) or Color(240, 70, 70))
			end

			y = y + 18
			if y > h - 30 then break end
		end
	end
end)

-- Also add HUD toggle to Pickup Assist menu
hook.Add("VRMod_Menu", "vrmod_pickup_hud_menu", function(frame)
	if not frame.physgunSheet then return end
	-- Find the Pickup Assist tab and add the HUD checkbox
	-- We'll add it as a separate simple hook that adds to Settings02 tree
end)

-- Console command to toggle HUD
concommand.Add("vrmod_pickup_hud_toggle", function()
	if not cv_hud then cv_hud = GetConVar("vrmod_unoff_pickup_hud") end
	if cv_hud then
		RunConsoleCommand("vrmod_unoff_pickup_hud", cv_hud:GetBool() and "0" or "1")
		local state = not cv_hud:GetBool()
		chat.AddText(Color(100, 200, 255), "[VRMod] ", Color(255, 255, 255), "Pickup HUD: " .. (state and "ON" or "OFF"))
	end
end)

print("[VRMod] Pickup debug/HUD system loaded")
--[vrmod_pickup_debug.lua]end--
