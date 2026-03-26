--------[vrmod_popup_cleanup.lua]Start--------
if SERVER then return end

-- ========================================
-- Popup自動クリーンアップ + 強制クローズ
--
-- dermapopups.lua が MakePopup インターセプトで作成した
-- VRメニュー (popup_*) の以下の問題を修正:
--
-- 1. パネルが無効/非表示になっても VRメニューが残り続ける
--    → Think hook で stale 検出 → VRUtilMenuClose
--
-- 2. DMenu（右クリックメニュー）が閉じられない
--    → パネルの子が全て非表示/削除された場合も検出
--
-- 3. 強制クローズ手段がない
--    → コンソールコマンド + VR入力で全popup強制クローズ
--
-- 既存ファイル編集なし。新規ファイルのみ。
-- ========================================

-- ----------------------------------------
-- popup UID のパターン
-- dermapopups.lua は "popup_0", "popup_1", ... を生成する
-- ----------------------------------------
local MAX_POPUP_SCAN = 50 -- 最大スキャン数（通常は数個しかない）

-- ----------------------------------------
-- Stale popup 検出 + 自動クリーンアップ
-- ----------------------------------------
local lastCleanupTime = 0
local CLEANUP_INTERVAL = 0.5 -- 0.5秒ごとにチェック（毎フレームは不要）

hook.Add("Think", "vrmod_unoff_popup_cleanup", function()
	if not g_VR or not g_VR.active then return end

	local now = SysTime()
	if now - lastCleanupTime < CLEANUP_INTERVAL then return end
	lastCleanupTime = now

	-- popup_0 ~ popup_N をスキャンし、stale を検出
	for i = 0, MAX_POPUP_SCAN do
		local uid = "popup_" .. i
		if not VRUtilIsMenuOpen(uid) then continue end

		-- このuidのメニューは開いている。パネルが有効か確認。
		-- VRUtilMenuRenderPanel は menus[uid].panel:IsValid() をチェックするが、
		-- 無効パネルを自動削除はしない。ここで削除する。
		--
		-- 問題: menus テーブルはvrmod_ui.luaのローカル変数で直接アクセス不可。
		-- しかし VRUtilMenuRenderPanel(uid) を呼んだ後にまだ VRUtilIsMenuOpen(uid) が
		-- true なら、パネルは（有効かどうかに関わらず）まだ登録されている。
		--
		-- 代替策: vgui.GetAll() でパネルの生存を間接チェック。
		-- ただしこれは重いので、代わりに VRMod_PostRenderPanel フックを使って
		-- パネル参照を取得する方式を採用。
		--
		-- 最もシンプルな方式: VRUtilMenuClose を呼んで closeFunc を発火させる。
		-- closeFunc 内で dermapopups.lua の allPopups からも除去される。
		-- → ただし有効なパネルも閉じてしまうので、パネル有効性のチェックが必要。
		--
		-- VRUtilMenuRenderPanel の冒頭 (L38) で
		-- "if not menus[uid].panel or not menus[uid].panel:IsValid()" をチェックし
		-- return している。この場合 PaintManual は呼ばれない。
		-- → PaintManual が呼ばれたかどうかをフックで判定できる。
	end
end)

-- ----------------------------------------
-- VRMod_PostRenderPanel フックでパネル有効性を追跡
-- ----------------------------------------
local validPopups = {} -- { uid = { panel = panel, lastRenderTime = SysTime() } }

hook.Add("VRMod_PostRenderPanel", "vrmod_unoff_popup_track", function(uid, menuData)
	if not uid or not menuData then return end

	-- popup_ プレフィックスのメニューのみ追跡
	if not string.StartWith(uid, "popup_") then return end

	if menuData.panel and IsValid(menuData.panel) then
		validPopups[uid] = {
			panel = menuData.panel,
			lastRenderTime = SysTime(),
		}
	end
end)

-- ----------------------------------------
-- Stale検出ロジック（VRMod_PostRenderPanel の情報を使用）
-- ----------------------------------------
hook.Remove("Think", "vrmod_unoff_popup_cleanup") -- 上の仮hookを除去して再定義

hook.Add("Think", "vrmod_unoff_popup_cleanup", function()
	if not g_VR or not g_VR.active then return end

	local now = SysTime()
	if now - lastCleanupTime < CLEANUP_INTERVAL then return end
	lastCleanupTime = now

	-- 追跡中の各popupをチェック
	for uid, info in pairs(validPopups) do
		if not VRUtilIsMenuOpen(uid) then
			-- 既に閉じられた → 追跡から除去
			validPopups[uid] = nil
			continue
		end

		local shouldClose = false

		-- チェック1: パネル自体が無効
		if not IsValid(info.panel) then
			shouldClose = true
		end

		-- チェック2: パネルが非表示になった
		if not shouldClose and IsValid(info.panel) and not info.panel:IsVisible() then
			shouldClose = true
		end

		-- チェック3: DMenu固有 — 子が全て非表示/削除された
		if not shouldClose and IsValid(info.panel) then
			local className = info.panel:GetClassName()
			if className == "DMenu" or className == "DScrollPanel" then
				local children = info.panel:GetChildren()
				if #children == 0 then
					shouldClose = true
				else
					-- 子パネルが全てSetPaintedManually前のパネル参照の場合
					-- dermapopups.lua L29 で panel = panel:GetChildren()[1] に差し替えているため
					-- 元のDMenuパネルの子を確認
					local parent = info.panel:GetParent()
					if IsValid(parent) and parent:GetClassName() == "DMenu" then
						if not parent:IsVisible() then
							shouldClose = true
						end
					end
				end
			end
		end

		-- チェック4: VRUtilMenuRenderPanel が一定時間呼ばれていない
		-- (dermapopups.luaのThink hookからレンダーされているはずだが、
		--  allPopups からuidが除去された場合レンダーされなくなる)
		if not shouldClose and (now - info.lastRenderTime) > 2.0 then
			shouldClose = true
		end

		if shouldClose then
			VRUtilMenuClose(uid)
			validPopups[uid] = nil
		end
	end

	-- popup_* を広くスキャンして、追跡されていないが開いているメニューを検出
	-- (VRMod_PostRenderPanel が発火しなかったケース = パネルが無効で PaintManual がスキップされた)
	for i = 0, MAX_POPUP_SCAN do
		local uid = "popup_" .. i
		if VRUtilIsMenuOpen(uid) and not validPopups[uid] then
			-- 追跡されていない = VRMod_PostRenderPanel が呼ばれていない = パネルが無効
			-- 少し猶予を持たせる（作成直後はまだPostRenderが来ていない可能性）
			-- → 初回検出時はマーク、2回目でクローズ
			if not validPopups["_pending_" .. uid] then
				validPopups["_pending_" .. uid] = { time = now }
			elseif now - validPopups["_pending_" .. uid].time > 1.0 then
				VRUtilMenuClose(uid)
				validPopups["_pending_" .. uid] = nil
			end
		end
	end
end)

-- ----------------------------------------
-- 全Popup強制クローズ
-- ----------------------------------------
local function ForceCloseAllPopups()
	for i = 0, MAX_POPUP_SCAN do
		local uid = "popup_" .. i
		if VRUtilIsMenuOpen(uid) then
			VRUtilMenuClose(uid)
		end
	end
	validPopups = {}
end

-- ----------------------------------------
-- コンソールコマンド
-- ----------------------------------------
concommand.Add("vrmod_unoff_close_popups", function()
	ForceCloseAllPopups()
	print("[VRMod] All popups force-closed")
end)

-- ----------------------------------------
-- VR入力: メニューボタンダブルタップで全popup強制クローズ
-- ----------------------------------------
local lastMenuPress = 0
local DOUBLE_TAP_WINDOW = 0.5 -- 0.5秒以内の2回押しで発動

hook.Add("VRMod_Input", "vrmod_unoff_popup_forceclose", function(action, pressed)
	if not pressed then return end

	-- boolean_menu (メニューボタン) でダブルタップ検出
	if action == "boolean_menu" then
		local now = SysTime()
		if now - lastMenuPress < DOUBLE_TAP_WINDOW then
			-- ダブルタップ検出 → 全popup強制クローズ
			ForceCloseAllPopups()
			lastMenuPress = 0 -- リセット
		else
			lastMenuPress = now
		end
	end
end)

-- ----------------------------------------
-- VRMod_Exit: クリーンアップ
-- ----------------------------------------
hook.Add("VRMod_Exit", "vrmod_unoff_popup_cleanup_exit", function(ply)
	if ply ~= LocalPlayer() then return end
	ForceCloseAllPopups()
	lastMenuPress = 0
	lastCleanupTime = 0
end)

-- ----------------------------------------
-- VRMod_Start: 状態リセット
-- ----------------------------------------
hook.Add("VRMod_Start", "vrmod_unoff_popup_cleanup_start", function(ply)
	if ply ~= LocalPlayer() then return end
	validPopups = {}
	lastMenuPress = 0
end)

--------[vrmod_popup_cleanup.lua]End--------
