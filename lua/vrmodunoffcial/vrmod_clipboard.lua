-- vrmod_clipboard.lua
-- VR Clipboard Module: VR内でのテキストコピー/ペースト + ファイルベースのテキスト管理
-- 既存ファイルを変更せず、独立モジュールとして動作する

if not CLIENT then return end

print("[VR Clipboard] Module loaded")

local CLIPBOARD_FILE = "vrmod_clipboard.txt"
local CLIPBOARD_UID = "vrmod_clipboard"
local PANEL_WIDTH = 420
local PANEL_HEIGHT = 380

-- 内部クリップボードバッファ
local clipBuffer = ""

-- カラーパレット（VR内視認性重視）
local COLOR_BG = Color(20, 20, 25, 240)
local COLOR_BG_LIGHT = Color(35, 35, 42, 255)
local COLOR_BG_HEADER = Color(45, 45, 55, 255)
local COLOR_BORDER = Color(80, 80, 95, 255)
local COLOR_TEXT = Color(230, 230, 240, 255)
local COLOR_TEXT_DIM = Color(150, 150, 165, 255)
local COLOR_ACCENT = Color(90, 140, 255, 255)
local COLOR_BTN = Color(50, 50, 62, 255)
local COLOR_BTN_COPY = Color(40, 100, 60, 255)
local COLOR_BTN_PASTE = Color(40, 60, 100, 255)
local COLOR_BTN_CLEAR = Color(100, 40, 40, 255)
local COLOR_ITEM = Color(40, 40, 50, 255)
local COLOR_ITEM_HOVER = Color(55, 55, 68, 255)
local COLOR_SEPARATOR = Color(60, 60, 75, 200)

---------------------------------------------------------------------------
-- ファイル操作
---------------------------------------------------------------------------

--- ファイルからクリップボード項目を読み込む
--- @return table 文字列の配列（空行除外）
local function LoadClipboardItems()
	local content = file.Read(CLIPBOARD_FILE, "DATA")
	if not content or content == "" then return {} end

	local items = {}
	for _, line in ipairs(string.Explode("\n", content)) do
		line = string.Trim(line)
		if line ~= "" then
			items[#items + 1] = line
		end
	end

	return items
end

--- デフォルトファイルを作成（存在しない場合のみ）
local function EnsureClipboardFile()
	if file.Exists(CLIPBOARD_FILE, "DATA") then return end

	file.Write(CLIPBOARD_FILE, "Hello\nThank you\nGG\nNice\n")
end

--- バッファの内容をファイル末尾に追記
--- @param text string 追記するテキスト
--- @return boolean 成功したかどうか
local function AppendToFile(text)
	if not text or text == "" then return false end

	-- file.Appendは.txt拡張子のみ動作する
	file.Append(CLIPBOARD_FILE, text .. "\n")
	return true
end

---------------------------------------------------------------------------
-- Copy / Paste ロジック
---------------------------------------------------------------------------

--- アクティブなテキスト入力欄からテキストをコピー
--- @return string コピーしたテキスト（空文字列 = 失敗）
local function DoCopy()
	local entry = vgui.GetKeyboardFocus()
	if not IsValid(entry) then return "" end

	local fullText = entry:GetText()
	if not fullText or fullText == "" then return "" end

	-- 選択範囲があれば選択テキストのみ、なければ全テキスト
	local text = fullText
	if entry.GetSelectedTextRange then
		local s, e = entry:GetSelectedTextRange()
		if s and e and s ~= e then
			text = string.sub(fullText, s + 1, e)
		end
	end

	if text == "" then return "" end

	clipBuffer = text
	SetClipboardText(text)

	return text
end

--- アクティブなテキスト入力欄にテキストをペースト
--- @return boolean 成功したかどうか
local function DoPaste()
	if clipBuffer == "" then return false end

	local entry = vgui.GetKeyboardFocus()
	if not IsValid(entry) then return false end

	local fullText = entry:GetText() or ""

	-- 選択範囲があれば置換、なければ末尾に追加
	if entry.GetSelectedTextRange then
		local s, e = entry:GetSelectedTextRange()
		if s and e and s ~= e then
			entry:SetText(string.sub(fullText, 1, s) .. clipBuffer .. string.sub(fullText, e + 1))
			if entry.SetCaretPos then
				entry:SetCaretPos(s + #clipBuffer)
			end
			return true
		end
	end

	-- カーソル位置に挿入（GetCaretPosが使えれば）
	if entry.GetCaretPos then
		local pos = entry:GetCaretPos()
		if pos and pos > 0 and pos < #fullText then
			entry:SetText(string.sub(fullText, 1, pos) .. clipBuffer .. string.sub(fullText, pos + 1))
			if entry.SetCaretPos then
				entry:SetCaretPos(pos + #clipBuffer)
			end
			return true
		end
	end

	-- フォールバック: 末尾に追加
	entry:SetText(fullText .. clipBuffer)
	return true
end

---------------------------------------------------------------------------
-- UI ヘルパー
---------------------------------------------------------------------------

--- ボタンを作成するヘルパー
--- @param parent Panel 親パネル
--- @param text string ボタンテキスト
--- @param x number X座標
--- @param y number Y座標
--- @param w number 幅
--- @param h number 高さ
--- @param bgColor Color 背景色
--- @param onClick function クリック時のコールバック
--- @return Panel 作成したボタン
local function CreateButton(parent, text, x, y, w, h, bgColor, onClick)
	local btn = vgui.Create("DButton", parent)
	btn:SetPos(x, y)
	btn:SetSize(w, h)
	btn:SetText(text)
	btn:SetTextColor(COLOR_TEXT)
	btn:SetFont("HudSelectionText")
	btn.bgColor = bgColor
	btn.hoverColor = Color(
		math.min(bgColor.r + 20, 255),
		math.min(bgColor.g + 20, 255),
		math.min(bgColor.b + 20, 255),
		bgColor.a
	)
	btn.DoClick = onClick

	btn.Paint = function(self, pw, ph)
		local col = self:IsHovered() and self.hoverColor or self.bgColor
		draw.RoundedBox(4, 0, 0, pw, ph, col)
		surface.SetDrawColor(COLOR_BORDER)
		surface.DrawOutlinedRect(0, 0, pw, ph, 1)
	end

	return btn
end

---------------------------------------------------------------------------
-- メインパネル構築
---------------------------------------------------------------------------

local function OpenClipboardPanel()
	print("[VR Clipboard] OpenClipboardPanel called")
	print("[VR Clipboard] VRUtilMenuOpen exists:", VRUtilMenuOpen ~= nil)
	print("[VR Clipboard] VRUtilIsMenuOpen exists:", VRUtilIsMenuOpen ~= nil)

	-- トグル動作: 既に開いていれば閉じる
	if VRUtilIsMenuOpen and VRUtilIsMenuOpen(CLIPBOARD_UID) then
		print("[VR Clipboard] Already open, closing")
		VRUtilMenuClose(CLIPBOARD_UID)
		return
	end

	-- ファイル確認
	EnsureClipboardFile()

	-- メインパネル
	local panel = vgui.Create("DPanel")
	panel:SetPos(0, 0)
	panel:SetSize(PANEL_WIDTH, PANEL_HEIGHT)
	panel.Paint = function(self, w, h)
		draw.RoundedBox(6, 0, 0, w, h, COLOR_BG)
		surface.SetDrawColor(COLOR_BORDER)
		surface.DrawOutlinedRect(0, 0, w, h, 1)
	end

	local padding = 8
	local innerW = PANEL_WIDTH - padding * 2
	local yPos = padding

	---------------------------------------------------------------------------
	-- ヘッダー
	---------------------------------------------------------------------------
	local header = vgui.Create("DPanel", panel)
	header:SetPos(padding, yPos)
	header:SetSize(innerW, 28)
	header.Paint = function(self, w, h)
		draw.RoundedBoxEx(4, 0, 0, w, h, COLOR_BG_HEADER, true, true, false, false)
		draw.SimpleText("VR Clipboard", "HudSelectionText", 10, h / 2, COLOR_ACCENT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
	yPos = yPos + 32

	---------------------------------------------------------------------------
	-- バッファ表示エリア
	---------------------------------------------------------------------------
	local bufferDisplay = vgui.Create("DPanel", panel)
	bufferDisplay:SetPos(padding, yPos)
	bufferDisplay:SetSize(innerW, 40)
	bufferDisplay.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, COLOR_BG_LIGHT)
		surface.SetDrawColor(COLOR_BORDER)
		surface.DrawOutlinedRect(0, 0, w, h, 1)

		local displayText = clipBuffer ~= "" and clipBuffer or "(empty)"
		local displayColor = clipBuffer ~= "" and COLOR_TEXT or COLOR_TEXT_DIM

		-- テキストが長い場合は省略
		local maxChars = 45
		if #displayText > maxChars then
			displayText = string.sub(displayText, 1, maxChars) .. "..."
		end

		draw.SimpleText(displayText, "HudSelectionText", 8, h / 2, displayColor, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
	end
	yPos = yPos + 44

	---------------------------------------------------------------------------
	-- 操作ボタン行: [Copy] [Paste] [Clear]
	---------------------------------------------------------------------------
	local btnW = math.floor((innerW - 8) / 3)
	local btnH = 30

	CreateButton(panel, "Copy", padding, yPos, btnW, btnH, COLOR_BTN_COPY, function()
		local copied = DoCopy()
		if copied ~= "" then
			bufferDisplay:InvalidateLayout()
		end
	end)

	CreateButton(panel, "Paste", padding + btnW + 4, yPos, btnW, btnH, COLOR_BTN_PASTE, function()
		DoPaste()
	end)

	CreateButton(panel, "Clear", padding + (btnW + 4) * 2, yPos, btnW, btnH, COLOR_BTN_CLEAR, function()
		clipBuffer = ""
		bufferDisplay:InvalidateLayout()
	end)

	yPos = yPos + btnH + 8

	---------------------------------------------------------------------------
	-- セパレータ + Saved Items ラベル
	---------------------------------------------------------------------------
	local sepLabel = vgui.Create("DPanel", panel)
	sepLabel:SetPos(padding, yPos)
	sepLabel:SetSize(innerW, 20)
	sepLabel.Paint = function(self, w, h)
		surface.SetDrawColor(COLOR_SEPARATOR)
		surface.DrawLine(0, h / 2, w, h / 2)
		-- 中央にラベル
		local labelW = 100
		draw.RoundedBox(0, (w - labelW) / 2, 0, labelW, h, COLOR_BG)
		draw.SimpleText("Saved Items", "HudSelectionText", w / 2, h / 2, COLOR_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
	end
	yPos = yPos + 24

	---------------------------------------------------------------------------
	-- スクロール可能なアイテムリスト
	---------------------------------------------------------------------------
	local listHeight = PANEL_HEIGHT - yPos - 46 -- 下部ボタン用スペース確保
	local scrollPanel = vgui.Create("DScrollPanel", panel)
	scrollPanel:SetPos(padding, yPos)
	scrollPanel:SetSize(innerW, listHeight)

	-- スクロールバーのスタイル
	local sbar = scrollPanel:GetVBar()
	sbar:SetWide(8)
	sbar.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, COLOR_BG_LIGHT)
	end
	sbar.btnGrip.Paint = function(self, w, h)
		draw.RoundedBox(4, 0, 0, w, h, COLOR_BORDER)
	end
	sbar.btnUp.Paint = function() end
	sbar.btnDown.Paint = function() end

	--- アイテムリストを（再）構築
	local function PopulateItems()
		scrollPanel:Clear()

		local items = LoadClipboardItems()
		if #items == 0 then
			local empty = vgui.Create("DPanel", scrollPanel)
			empty:SetSize(innerW - 12, 30)
			empty:Dock(TOP)
			empty:DockMargin(0, 2, 0, 2)
			empty.Paint = function(self, w, h)
				draw.SimpleText("(no saved items)", "HudSelectionText", w / 2, h / 2, COLOR_TEXT_DIM, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
			end
			return
		end

		for i, itemText in ipairs(items) do
			local itemBtn = vgui.Create("DButton", scrollPanel)
			itemBtn:SetSize(innerW - 12, 26)
			itemBtn:Dock(TOP)
			itemBtn:DockMargin(0, 2, 0, 0)
			itemBtn:SetText("")
			itemBtn:SetMouseInputEnabled(true)

			-- 表示用テキスト（長い場合省略）
			local displayText = itemText
			if #displayText > 40 then
				displayText = string.sub(displayText, 1, 40) .. "..."
			end

			itemBtn.Paint = function(self, w, h)
				local bgCol = self:IsHovered() and COLOR_ITEM_HOVER or COLOR_ITEM
				draw.RoundedBox(3, 0, 0, w, h, bgCol)

				-- 番号
				draw.SimpleText(tostring(i) .. ".", "HudSelectionText", 8, h / 2, COLOR_TEXT_DIM, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
				-- テキスト
				draw.SimpleText(displayText, "HudSelectionText", 28, h / 2, COLOR_TEXT, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
			end

			itemBtn.DoClick = function()
				clipBuffer = itemText
				SetClipboardText(itemText)
				bufferDisplay:InvalidateLayout()
			end
		end
	end

	PopulateItems()

	yPos = yPos + listHeight + 4

	---------------------------------------------------------------------------
	-- 下部ボタン行: [Save to File] [Delete] [Reload]
	---------------------------------------------------------------------------
	local bottomBtnW = math.floor((innerW - 8) / 3)

	CreateButton(panel, "Save", padding, yPos, bottomBtnW, 30, COLOR_BTN, function()
		if clipBuffer ~= "" then
			AppendToFile(clipBuffer)
			PopulateItems()
		end
	end)

	CreateButton(panel, "Delete", padding + bottomBtnW + 4, yPos, bottomBtnW, 30, COLOR_BTN_CLEAR, function()
		-- バッファの内容と一致する行をファイルから削除
		if clipBuffer == "" then return end

		local items = LoadClipboardItems()
		local newItems = {}
		local removed = false
		for _, item in ipairs(items) do
			if item == clipBuffer and not removed then
				removed = true -- 最初の一致のみ削除
			else
				newItems[#newItems + 1] = item
			end
		end

		if removed then
			file.Write(CLIPBOARD_FILE, table.concat(newItems, "\n") .. "\n")
			PopulateItems()
		end
	end)

	CreateButton(panel, "Reload", padding + (bottomBtnW + 4) * 2, yPos, bottomBtnW, 30, COLOR_BTN, function()
		PopulateItems()
	end)

	---------------------------------------------------------------------------
	-- VRメニューとして表示
	---------------------------------------------------------------------------
	if VRUtilMenuOpen then
		print("[VR Clipboard] Calling VRUtilMenuOpen")
		VRUtilMenuOpen(
			CLIPBOARD_UID,
			PANEL_WIDTH,
			PANEL_HEIGHT,
			panel,
			1,                   -- attachment: 左手
			Vector(4, 6, 5.5),
			Angle(0, -90, 10),
			0.03,                -- scale
			true,                -- cursorEnabled
			function()
				if IsValid(panel) then
					panel:Remove()
				end
			end
		)
		print("[VR Clipboard] VRUtilMenuOpen called successfully")
	else
		print("[VR Clipboard] ERROR: VRUtilMenuOpen is nil!")
	end
end

---------------------------------------------------------------------------
-- コマンド登録
---------------------------------------------------------------------------
concommand.Add("vrmod_clipboard", function()
	OpenClipboardPanel()
end)
