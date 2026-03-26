-- VRMod Semi-Official Addon Plus - Menu Click Actions
-- QuickMenu/WeaponSelect のメニュー表示中クリックアクション
-- VRMod_MenuClick フック (vrmod_ui.lua) を listen して処理

-- ============================================================================
-- SERVER: 武器ドロップ net ハンドラ
-- ============================================================================
if SERVER then
	util.AddNetworkString("vrmod_unoff_weapondrop")

	local dropCooldown = {}
	net.Receive("vrmod_unoff_weapondrop", function(len, ply)
		if not IsValid(ply) then return end

		-- Rate limit: 1 drop per 0.5s per player
		local sid = ply:SteamID64() or "unknown"
		if dropCooldown[sid] and dropCooldown[sid] > CurTime() then return end
		dropCooldown[sid] = CurTime() + 0.5

		local weaponClass = net.ReadString()
		if not isstring(weaponClass) or #weaponClass == 0 or #weaponClass > 80 then return end

		-- Validate: player must own this weapon
		local wep = nil
		for _, w in pairs(ply:GetWeapons()) do
			if w:GetClass() == weaponClass then
				wep = w
				break
			end
		end
		if not IsValid(wep) then return end

		ply:DropWeapon(wep)
	end)

	return -- Server doesn't need client code
end

-- ============================================================================
-- CLIENT: QuickMenu クリックハンドラ
-- ============================================================================
hook.Add("VRMod_MenuClick", "vrmod_unoff_quickmenu_click", function(menuUID, button)
	if menuUID ~= "miscmenu" then return end
	if button ~= "primaryfire" then return end

	local menuItemIndex = g_VR._quickmenuHoveredIndex
	if not menuItemIndex then return end

	local menuItem = g_VR.menuItems and g_VR.menuItems[menuItemIndex]
	if not menuItem then return end

	-- Execute click action only if registered
	if menuItem.clickFunc then
		g_VR._menuClickActionUsed = true
		local ok, err = pcall(menuItem.clickFunc)
		if not ok then
			print("[VRMod] QuickMenu clickFunc error: " .. tostring(err))
		end
		surface.PlaySound("UI/buttonclick.wav")
	end
end)

-- ============================================================================
-- CLIENT: WeaponSelect クリックハンドラ
-- ============================================================================
hook.Add("VRMod_MenuClick", "vrmod_unoff_weaponmenu_click", function(menuUID, button)
	if menuUID ~= "weaponmenu" then return end

	local hoveredClass = g_VR._weaponmenuHoveredClass
	local hoveredWep = g_VR._weaponmenuHoveredWep
	if not hoveredClass then return end

	if button == "primaryfire" then
		-- Toggle favorite
		vrmod.ToggleWeaponFavorite(hoveredClass)
		g_VR._menuClickActionUsed = true
		g_VR._weaponmenuForceRedraw = true
		surface.PlaySound("UI/buttonclick.wav")
	elseif button == "secondaryfire" then
		-- Drop weapon
		if IsValid(hoveredWep) then
			net.Start("vrmod_unoff_weapondrop")
			net.WriteString(hoveredClass)
			net.SendToServer()
			g_VR._menuClickActionUsed = true
			surface.PlaySound("UI/buttonclickrelease.wav")
		end
	end
end)

-- ============================================================================
-- CLIENT: API — QuickMenuアイテムにクリックアクションを登録
-- ============================================================================
-- vrmod.AddInGameMenuItem() で登録したアイテムに、クリック専用アクションを追加する。
-- clickFunc未登録のアイテムは、クリックしても何も起きない。
--
-- Usage:
--   vrmod.AddInGameMenuItem("MyToggle", 3, 0, function() ... end)
--   vrmod.SetMenuItemClickAction("MyToggle", function()
--       -- primary_fire クリック時のアクション
--   end)
function vrmod.SetMenuItemClickAction(name, clickFunc)
	if not g_VR or not g_VR.menuItems then return false end
	for i = 1, #g_VR.menuItems do
		if g_VR.menuItems[i].name == name then
			g_VR.menuItems[i].clickFunc = clickFunc
			return true
		end
	end
	return false
end

-- ============================================================================
-- CLIENT: VR終了時のクリーンアップ
-- ============================================================================
hook.Add("VRMod_Exit", "vrmod_unoff_menuclick_cleanup", function()
	g_VR._quickmenuHoveredIndex = nil
	g_VR._weaponmenuHoveredWep = nil
	g_VR._weaponmenuHoveredClass = nil
	g_VR._menuClickActionUsed = false
	g_VR._weaponmenuForceRedraw = false
end)
