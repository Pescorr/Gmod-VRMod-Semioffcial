-- VRMod Feature Guide - Menu Integration
-- Settings02 DTree に Feature Guide ノードを追加
-- Pattern: hidden DPropertySheet → deferred extraction → DTree node

AddCSLuaFile()
if SERVER then return end

hook.Add("VRMod_Menu", "addsettings_fguide", function(frame)
	if not frame.Settings02Sheet then return end

	local panel = vgui.Create("DPanel", frame.Settings02Sheet)
	frame.Settings02Sheet:AddSheet("Feature Guide", panel, "icon16/book_open.png")
	panel.Paint = function(self, w, h)
		draw.RoundedBox(0, 0, 0, w, h, Color(30, 30, 35))
	end

	local inner = vgui.Create("DPanel", panel)
	inner:Dock(FILL)
	inner:DockMargin(20, 20, 20, 20)
	inner.Paint = function() end

	-- Title
	local title = vgui.Create("DLabel", inner)
	title:SetFont("DermaLarge")
	title:SetText("VR Feature Guide")
	title:SetTextColor(Color(220, 220, 230))
	title:Dock(TOP)
	title:SetAutoStretchVertical(true)

	-- Description
	local desc = vgui.Create("DLabel", inner)
	desc:SetFont("DermaDefault")
	desc:SetText(
		"Learn how to combine semiofficial VRMod features for the best experience.\n\n" ..
		"- Toggle Modes: One-click feature switches (Streamer, Seated, Left-hand)\n" ..
		"- Wizard Modes: Step-by-step setup guides (Height, Full-body, Performance)\n" ..
		"- Troubleshoot: Interactive Q&A to solve common VR problems\n\n" ..
		"Available in English, Japanese, Russian, and Chinese."
	)
	desc:SetTextColor(Color(180, 180, 190))
	desc:Dock(TOP)
	desc:DockMargin(0, 10, 0, 20)
	desc:SetWrap(true)
	desc:SetAutoStretchVertical(true)

	-- Open button
	local btn = vgui.Create("DButton", inner)
	btn:SetText("Open Feature Guide")
	btn:SetFont("DermaDefaultBold")
	btn:Dock(TOP)
	btn:SetTall(40)
	btn:DockMargin(0, 0, 300, 0)
	btn:SetTextColor(Color(255, 255, 255))
	btn.Paint = function(self, w, h)
		local col = self:IsHovered() and Color(70, 130, 220) or Color(50, 110, 200)
		draw.RoundedBox(6, 0, 0, w, h, col)
	end
	btn.DoClick = function()
		RunConsoleCommand("vrmod_fguide")
	end

	-- Console hint
	local hint = vgui.Create("DLabel", inner)
	hint:SetFont("DermaDefault")
	hint:SetText("Console: vrmod_fguide")
	hint:SetTextColor(Color(120, 120, 135))
	hint:Dock(TOP)
	hint:DockMargin(0, 8, 0, 0)
	hint:SetAutoStretchVertical(true)
end)

print("[VRMod] Feature Guide menu integration loaded")
