-- --------[vrmod_addononly_menu.lua]Start--------
-- Addon-Only Mode Menu: 他VRModのメニューに「Addons」タブを追加し、
-- モジュールメニューの受け皿（隠しDPropertySheet）とModulesパネルを提供する。
-- 通常モードでは一切実行されない。
if SERVER then return end
if not VRMOD_ADDON_ONLY_MODE then return end

-- フォルダ番号 → 表示名（initと同一定義）
local FOLDER_NAMES = {
    ["0"]  = "Core/API",
    ["1"]  = "Auto-settings/Optimize",
    ["2"]  = "Holster Type2",
    ["3"]  = "Foregrip",
    ["4"]  = "Magbone/ARC9",
    ["5"]  = "Melee",
    ["6"]  = "Holster Type1",
    ["7"]  = "VR Hand HUD",
    ["8"]  = "Physgun",
    ["9"]  = "VR Pickup",
    ["10"] = "Debug",
    ["11"] = "(Reserved)",
    ["12"] = "Guide",
}

-- DTree Navigation Helper: DHorizontalDivider + DTree(左) + コンテンツパネル(右)
local function CreateTreeTab(parent)
    local divider = vgui.Create("DHorizontalDivider", parent)
    divider:Dock(FILL)
    divider:SetDividerWidth(4)
    divider:SetLeftMin(120)
    divider:SetRightMin(200)
    divider:SetLeftWidth(170)

    local tree = vgui.Create("DTree", divider)
    tree:SetShowIcons(true)

    local contentContainer = vgui.Create("DPanel", divider)
    contentContainer.Paint = function() end

    divider:SetLeft(tree)
    divider:SetRight(contentContainer)

    local panels = {}

    local function showPanel(key)
        for k, p in pairs(panels) do
            if IsValid(p) then
                p:SetVisible(k == key)
            end
        end
    end

    local function registerPanel(key, panel)
        panel:SetParent(contentContainer)
        panel:Dock(FILL)
        panel:SetVisible(false)
        panels[key] = panel
    end

    return tree, contentContainer, showPanel, registerPanel
end

-- DTree Navigation Helper: ノード追加
local function AddTreeNode(tree, label, key, icon, showPanel)
    local node = tree:AddNode(label, icon)
    node.DoClick = function()
        showPanel(key)
    end
    return node
end

-- DTree Navigation Helper: 隠しDPropertySheetからタブを抽出してDTreeに追加
local function ExtractSheet(hiddenSheet, tree, showPanel, registerPanel)
    if not IsValid(hiddenSheet) then return end
    local items = hiddenSheet:GetItems()
    if not items then return end
    for _, item in ipairs(items) do
        if item.Tab and item.Panel then
            local tabName = item.Tab:GetText():Trim()
            local key = "mod_" .. tabName
            registerPanel(key, item.Panel)
            AddTreeNode(tree, tabName, key, "icon16/plugin.png", showPanel)
        end
    end
    hiddenSheet:Remove()
end

-- 他VRModのメニューに「Addons」タブを追加
hook.Add("VRMod_Menu", "vrmod_addononly_menu", function(frame)
    if not IsValid(frame) then return end

    -- frame.DPropertySheet が無い場合は追加できない
    if not IsValid(frame.DPropertySheet) then return end

    -- 「Addons」タブのコンテナ
    local addonsTab = vgui.Create("DPanel", frame.DPropertySheet)
    addonsTab.Paint = function() end
    frame.DPropertySheet:AddSheet("Addons", addonsTab, "icon16/bricks.png")

    -- DTree + コンテンツエリア構築
    local tree, contentContainer, showPanel, registerPanel = CreateTreeTab(addonsTab)

    -- ========================================
    -- 隠しDPropertySheet（モジュールメニューの受け皿）
    -- vrmod_unoff_addmenu.lua と同じ frame.XXXSheet パターン
    -- ========================================
    local hiddenSheets = {
        "VRplaySheet", "pickupSheet", "nonVRGunSheet",
        "hudSheet", "debugSheet", "quickmenuBtnSheet", "Settings02Sheet"
    }
    for _, sheetName in ipairs(hiddenSheets) do
        local hidden = vgui.Create("DPropertySheet", addonsTab)
        hidden:SetVisible(false)
        hidden:SetSize(0, 0)
        frame[sheetName] = hidden
    end

    -- ========================================
    -- Panel: Modules (Feature Loading Control)
    -- ========================================
    do
    local modulesScroll = vgui.Create("DScrollPanel")

    -- Addon-Only Mode 表示
    local modeLabel = vgui.Create("DLabel", modulesScroll)
    modeLabel:Dock(TOP)
    modeLabel:DockMargin(10, 8, 10, 2)
    modeLabel:SetText("Addon-Only Mode Active")
    modeLabel:SetFont("DermaDefaultBold")
    modeLabel:SetTextColor(Color(80, 200, 80))
    modeLabel:SetAutoStretchVertical(true)

    local modeDesc = vgui.Create("DLabel", modulesScroll)
    modeDesc:Dock(TOP)
    modeDesc:DockMargin(10, 0, 10, 4)
    modeDesc:SetText("Root files are not loaded. Using external VRMod as base.")
    modeDesc:SetAutoStretchVertical(true)
    modeDesc:SetWrap(true)
    modeDesc:SetTextColor(Color(180, 180, 180))

    -- 再起動警告
    local restartWarning = vgui.Create("DLabel", modulesScroll)
    restartWarning:Dock(TOP)
    restartWarning:DockMargin(10, 6, 10, 4)
    restartWarning:SetText("Changes require Gmod restart to take effect.")
    restartWarning:SetFont("DermaDefaultBold")
    restartWarning:SetTextColor(Color(255, 80, 80))
    restartWarning:SetAutoStretchVertical(true)

    -- Addon-Only モード解除ボタン
    local disableBtn = vgui.Create("DButton", modulesScroll)
    disableBtn:Dock(TOP)
    disableBtn:DockMargin(10, 4, 10, 8)
    disableBtn:SetTall(25)
    disableBtn:SetText("Disable Addon-Only Mode (requires restart)")
    disableBtn.DoClick = function()
        RunConsoleCommand("vrmod_unoff_addon_only_mode", "0")
        chat.AddText(Color(255, 200, 0), "[VRMod] ", Color(255, 255, 255), "Addon-Only Mode will be disabled after restart.")
    end

    -- === Feature Modules セクション ===
    local featureSectionLabel = vgui.Create("DLabel", modulesScroll)
    featureSectionLabel:Dock(TOP)
    featureSectionLabel:DockMargin(10, 6, 10, 2)
    featureSectionLabel:SetText("=== Feature Modules ===")
    featureSectionLabel:SetFont("DermaDefaultBold")
    featureSectionLabel:SizeToContents()

    -- ソート用キー（フォルダ0-12全て）
    local sortedFolders = {}
    for k in pairs(FOLDER_NAMES) do sortedFolders[#sortedFolders + 1] = k end
    table.sort(sortedFolders, function(a, b) return tonumber(a) < tonumber(b) end)

    for _, k in ipairs(sortedFolders) do
        local cv = GetConVar("vrmod_unoff_load_" .. k)
        if cv then
            local cb = vgui.Create("DCheckBoxLabel", modulesScroll)
            cb:Dock(TOP)
            cb:DockMargin(10, 3, 10, 0)
            cb:SetText("[" .. k .. "] " .. FOLDER_NAMES[k])
            cb:SetConVar("vrmod_unoff_load_" .. k)
            cb:SizeToContents()
        end
    end

    registerPanel("modules", modulesScroll)
    AddTreeNode(tree, "Modules", "modules", "icon16/bricks.png", showPanel)
    end -- Modules panel

    -- デフォルトでModulesパネルを表示
    showPanel("modules")

    -- Deferred: モジュールメニューの隠しシートをDTreeに展開
    timer.Simple(0, function()
        if not IsValid(tree) then return end
        ExtractSheet(frame.VRplaySheet, tree, showPanel, registerPanel)
        ExtractSheet(frame.pickupSheet, tree, showPanel, registerPanel)
        ExtractSheet(frame.nonVRGunSheet, tree, showPanel, registerPanel)
        ExtractSheet(frame.hudSheet, tree, showPanel, registerPanel)
        ExtractSheet(frame.debugSheet, tree, showPanel, registerPanel)
        ExtractSheet(frame.quickmenuBtnSheet, tree, showPanel, registerPanel)
        ExtractSheet(frame.Settings02Sheet, tree, showPanel, registerPanel)
    end)
end)
-- --------[vrmod_addononly_menu.lua]End--------
