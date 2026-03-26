--[[
    VRMod Feature Guide: Mode Definitions + Renderers
    7つのモード定義 — 1クリックトグル / ウィザード / トラブルシュート
    + Toggle / Wizard UI描画関数
]]

AddCSLuaFile()
if SERVER then return end

vrmod = vrmod or {}
vrmod.fguide = vrmod.fguide or {}

-- ============================================================
-- Mode Data Definitions
-- ============================================================
vrmod.fguide.modes = {
    -- ================================================================
    -- 1. Streamer Mode (1-click toggle)
    -- ================================================================
    {
        key = "streamer",
        type = "toggle",
        icon = "icon16/television.png",
        convars = {
            { name = "vrmod_cameraoverride", on = "0", off = "1" },
        },
    },

    -- ================================================================
    -- 2. Seated Play (1-click toggle + auto command)
    -- ================================================================
    {
        key = "seated",
        type = "toggle",
        icon = "icon16/user_go.png",
        convars = {
            { name = "vrmod_seated", on = "1", off = "0" },
        },
        commands_on = {
            { "vrmod_seatedoffset_auto" },
        },
    },

    -- ================================================================
    -- 3. Left-Handed Mode (1-click toggle)
    -- ================================================================
    {
        key = "lefthand",
        type = "toggle",
        icon = "icon16/arrow_turn_left.png",
        convars = {
            { name = "vrmod_LeftHand", on = "1", off = "0" },
        },
    },

    -- ================================================================
    -- 4. Height & Appearance Wizard
    -- ================================================================
    {
        key = "height",
        type = "wizard",
        icon = "icon16/arrow_inout.png",
        steps = {
            {
                action = function()
                    RunConsoleCommand("vrmod_character_auto")
                end,
            },
            {
                action = function()
                    RunConsoleCommand("vrmod_disable_mirrors", "0")
                end,
            },
            {
                -- Step 3: Fine-tune eye height (instruction only, no action)
            },
            {
                action = function()
                    local cv = GetConVar("vrmod_hide_head")
                    if cv then
                        RunConsoleCommand("vrmod_hide_head", cv:GetBool() and "0" or "1")
                    end
                end,
            },
        },
    },

    -- ================================================================
    -- 5. FBT Setup Wizard
    -- ================================================================
    {
        key = "fbt",
        type = "wizard",
        icon = "icon16/group.png",
        steps = {
            {
                action = function()
                    RunConsoleCommand("vrmod_info")
                end,
            },
            {
                -- Step 2: Set tracker roles in SteamVR (instruction only)
            },
            {
                action = function()
                    RunConsoleCommand("vrmod_exit")
                    timer.Simple(1, function()
                        RunConsoleCommand("vrmod_start")
                    end)
                end,
            },
            {
                -- Step 4: Calibrate (instruction only)
            },
        },
    },

    -- ================================================================
    -- 6. Troubleshoot (handled by troubleshoot.lua)
    -- ================================================================
    {
        key = "troubleshoot",
        type = "troubleshoot",
        icon = "icon16/exclamation.png",
    },

    -- ================================================================
    -- 7. Performance Wizard
    -- ================================================================
    {
        key = "performance",
        type = "wizard",
        icon = "icon16/lightning.png",
        steps = {
            {
                action = function()
                    RunConsoleCommand("gmod_mcore_test", "1")
                    RunConsoleCommand("mat_queue_mode", "-1")
                end,
            },
            {
                action = function()
                    RunConsoleCommand("vrmod_rtWidth_Multiplier", "1.6")
                end,
            },
            {
                action = function()
                    RunConsoleCommand("r_mapextents", "65536")
                end,
            },
            {
                -- Step 4: Check result (instruction only)
            },
        },
    },
}

-- ============================================================
-- Helper: find mode definition by key
-- ============================================================
local function FindMode(modeKey)
    for _, mode in ipairs(vrmod.fguide.modes) do
        if mode.key == modeKey then return mode end
    end
    return nil
end

-- ============================================================
-- Helper: check if a toggle mode is currently "on"
-- ============================================================
local function IsToggleOn(mode)
    if not mode.convars or #mode.convars == 0 then return false end
    -- Check the first convar to determine state
    local cv = GetConVar(mode.convars[1].name)
    if not cv then return false end
    return cv:GetString() == mode.convars[1].on
end

-- ============================================================
-- Helper: apply toggle state
-- ============================================================
local function ApplyToggle(mode, turnOn)
    if not mode.convars then return end
    for _, cvarDef in ipairs(mode.convars) do
        local val = turnOn and cvarDef.on or cvarDef.off
        RunConsoleCommand(cvarDef.name, val)
    end
    -- Run on-commands if turning on
    if turnOn and mode.commands_on then
        for _, cmd in ipairs(mode.commands_on) do
            RunConsoleCommand(unpack(cmd))
        end
    end
end

-- ============================================================
-- Renderer: Toggle Mode
-- ============================================================
local function RenderToggleMode(parent, mode)
    local L = vrmod.fguide.L
    local COLORS = vrmod.fguide.COLORS
    local modeKey = mode.key

    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:Dock(FILL)

    -- Header with icon and title
    local header = vgui.Create("DPanel", scroll)
    header:Dock(TOP)
    header:DockMargin(0, 0, 0, 0)
    header:SetTall(50)
    local headerIcon = mode.icon or "icon16/page.png"
    header.Paint = function(self, w, h)
        surface.SetDrawColor(COLORS.bg_topbar)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(COLORS.border)
        surface.DrawLine(0, h - 1, w, h - 1)
        -- Icon
        local mat = Material(headerIcon, "smooth")
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(15, (h - 20) / 2, 20, 20)
        -- Title
        draw.SimpleText(L("mode_" .. modeKey .. "_title", modeKey), "VRFGuide_Title",
            45, h / 2 - 2, COLORS.text_primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Description
    local descPanel = vgui.Create("DPanel", scroll)
    descPanel:Dock(TOP)
    descPanel:DockMargin(15, 15, 15, 0)
    descPanel:SetTall(60)
    descPanel.Paint = function() end

    local descLabel = vgui.Create("DLabel", descPanel)
    descLabel:SetFont("VRFGuide_Body")
    descLabel:SetText(L("mode_" .. modeKey .. "_desc", ""))
    descLabel:SetTextColor(COLORS.text_secondary)
    descLabel:Dock(FILL)
    descLabel:SetWrap(true)
    descLabel:SetAutoStretchVertical(true)

    -- ConVar info
    local cvarInfo = vgui.Create("DLabel", scroll)
    cvarInfo:SetFont("VRFGuide_Small")
    cvarInfo:SetText(L("mode_" .. modeKey .. "_cvar_info", ""))
    cvarInfo:SetTextColor(Color(120, 120, 140))
    cvarInfo:Dock(TOP)
    cvarInfo:DockMargin(15, 10, 15, 5)
    cvarInfo:SetAutoStretchVertical(true)

    -- Current status display
    local statusPanel = vgui.Create("DPanel", scroll)
    statusPanel:Dock(TOP)
    statusPanel:DockMargin(15, 5, 15, 10)
    statusPanel:SetTall(30)

    local isOn = IsToggleOn(mode)

    statusPanel.Paint = function(self, w, h)
        local currentOn = IsToggleOn(mode)
        local bgCol = currentOn and Color(40, 70, 50, 255) or Color(70, 45, 45, 255)
        draw.RoundedBox(4, 0, 0, w, h, bgCol)
        local statusKey = currentOn and ("mode_" .. modeKey .. "_status_on") or ("mode_" .. modeKey .. "_status_off")
        local statusCol = currentOn and Color(100, 220, 100) or Color(220, 140, 100)
        draw.SimpleText(L(statusKey, ""), "VRFGuide_BodyBold", 12, h / 2,
            statusCol, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Big toggle button
    local btnPanel = vgui.Create("DPanel", scroll)
    btnPanel:Dock(TOP)
    btnPanel:DockMargin(15, 10, 15, 10)
    btnPanel:SetTall(50)
    btnPanel.Paint = function() end

    local toggleBtn = vgui.Create("DButton", btnPanel)
    toggleBtn:Dock(FILL)
    toggleBtn:SetText("")
    toggleBtn:SetTall(50)

    toggleBtn.Paint = function(self, w, h)
        local currentOn = IsToggleOn(mode)
        local bgCol
        if currentOn then
            bgCol = self:IsHovered() and COLORS.toggle_off_hover or COLORS.toggle_off
        else
            bgCol = self:IsHovered() and COLORS.toggle_on_hover or COLORS.toggle_on
        end
        draw.RoundedBox(6, 0, 0, w, h, bgCol)

        local btnKey = currentOn and ("mode_" .. modeKey .. "_btn_off") or ("mode_" .. modeKey .. "_btn_on")
        draw.SimpleText(L(btnKey, "Toggle"), "VRFGuide_ToggleBtn",
            w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
    end

    toggleBtn.DoClick = function()
        local currentOn = IsToggleOn(mode)
        ApplyToggle(mode, not currentOn)
    end

    -- Tip text
    local tipLabel = vgui.Create("DLabel", scroll)
    tipLabel:SetFont("VRFGuide_Body")
    tipLabel:SetText(L("mode_" .. modeKey .. "_tip", ""))
    tipLabel:SetTextColor(COLORS.accent)
    tipLabel:Dock(TOP)
    tipLabel:DockMargin(15, 15, 15, 10)
    tipLabel:SetWrap(true)
    tipLabel:SetAutoStretchVertical(true)

    -- Extra info for seated mode
    if modeKey == "seated" then
        local autoLabel = vgui.Create("DLabel", scroll)
        autoLabel:SetFont("VRFGuide_Small")
        autoLabel:SetText(L("mode_seated_auto_adjust", ""))
        autoLabel:SetTextColor(COLORS.text_secondary)
        autoLabel:Dock(TOP)
        autoLabel:DockMargin(15, 5, 15, 10)
        autoLabel:SetAutoStretchVertical(true)
    end

    return scroll
end

-- ============================================================
-- Renderer: Wizard Mode
-- ============================================================
local function RenderWizardMode(parent, mode)
    local L = vrmod.fguide.L
    local COLORS = vrmod.fguide.COLORS
    local modeKey = mode.key

    local scroll = vgui.Create("DScrollPanel", parent)
    scroll:Dock(FILL)

    -- Header with icon and title
    local header = vgui.Create("DPanel", scroll)
    header:Dock(TOP)
    header:DockMargin(0, 0, 0, 0)
    header:SetTall(50)
    local headerIcon = mode.icon or "icon16/page.png"
    header.Paint = function(self, w, h)
        surface.SetDrawColor(COLORS.bg_topbar)
        surface.DrawRect(0, 0, w, h)
        surface.SetDrawColor(COLORS.border)
        surface.DrawLine(0, h - 1, w, h - 1)
        -- Icon
        local mat = Material(headerIcon, "smooth")
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(mat)
        surface.DrawTexturedRect(15, (h - 20) / 2, 20, 20)
        -- Title
        draw.SimpleText(L("mode_" .. modeKey .. "_title", modeKey), "VRFGuide_Title",
            45, h / 2 - 2, COLORS.text_primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
    end

    -- Description
    local descLabel = vgui.Create("DLabel", scroll)
    descLabel:SetFont("VRFGuide_Body")
    descLabel:SetText(L("mode_" .. modeKey .. "_desc", ""))
    descLabel:SetTextColor(COLORS.text_secondary)
    descLabel:Dock(TOP)
    descLabel:DockMargin(15, 15, 15, 10)
    descLabel:SetWrap(true)
    descLabel:SetAutoStretchVertical(true)

    -- Steps
    if not mode.steps then return scroll end

    for i, step in ipairs(mode.steps) do
        local stepTitleKey = "mode_" .. modeKey .. "_step" .. i .. "_title"
        local stepDescKey = "mode_" .. modeKey .. "_step" .. i .. "_desc"
        local stepBtnKey = "mode_" .. modeKey .. "_step" .. i .. "_btn"

        local stepTitle = L(stepTitleKey, "Step " .. i)
        local stepDesc = L(stepDescKey, "")
        local stepBtnLabel = L(stepBtnKey, "")

        -- Step container
        local stepPanel = vgui.Create("DPanel", scroll)
        stepPanel:Dock(TOP)
        stepPanel:DockMargin(12, 8, 12, 0)
        -- We'll set the height after building content

        stepPanel.Paint = function(self, w, h)
            draw.RoundedBox(6, 0, 0, w, h, COLORS.step_bg)
            -- Left accent border
            surface.SetDrawColor(COLORS.step_border)
            surface.DrawRect(0, 0, 3, h)
        end

        -- Step number + title row
        local titleRow = vgui.Create("DPanel", stepPanel)
        titleRow:Dock(TOP)
        titleRow:DockMargin(0, 0, 0, 0)
        titleRow:SetTall(36)
        titleRow.Paint = function(self, w, h)
            -- Step number circle
            draw.RoundedBox(14, 10, 6, 24, 24, COLORS.step_number)
            draw.SimpleText(tostring(i), "VRFGuide_BodyBold",
                22, 18, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            -- Step title
            draw.SimpleText(stepTitle, "VRFGuide_StepTitle",
                44, h / 2, COLORS.text_primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        -- Step description
        local descLbl = vgui.Create("DLabel", stepPanel)
        descLbl:SetFont("VRFGuide_Body")
        descLbl:SetText(stepDesc)
        descLbl:SetTextColor(COLORS.text_secondary)
        descLbl:Dock(TOP)
        descLbl:DockMargin(44, 0, 12, 6)
        descLbl:SetWrap(true)
        descLbl:SetAutoStretchVertical(true)

        -- Action button (if this step has an action)
        if step.action and stepBtnLabel ~= "" then
            local btnContainer = vgui.Create("DPanel", stepPanel)
            btnContainer:Dock(TOP)
            btnContainer:DockMargin(44, 4, 12, 10)
            btnContainer:SetTall(36)
            btnContainer.Paint = function() end

            local actionBtn = vgui.Create("DButton", btnContainer)
            actionBtn:SetText("")
            actionBtn:Dock(LEFT)
            actionBtn:SetWide(200)
            actionBtn:SetTall(36)
            actionBtn.Paint = function(self, w, h)
                local bgCol = self:IsHovered() and COLORS.wizard_btn_hover or COLORS.wizard_btn
                draw.RoundedBox(4, 0, 0, w, h, bgCol)
                draw.SimpleText(stepBtnLabel, "VRFGuide_BodyBold",
                    w / 2, h / 2, Color(255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            actionBtn.DoClick = function()
                local ok, err = pcall(step.action)
                if not ok then
                    print("[VRMod FGuide] Step action error: " .. tostring(err))
                end
            end
        else
            -- No action button — add a small bottom margin
            local spacer = vgui.Create("DPanel", stepPanel)
            spacer:Dock(TOP)
            spacer:SetTall(6)
            spacer.Paint = function() end
        end

        -- Pre-calculate step panel height
        -- titleRow=36, descLbl margins=6 bottom, btn or spacer
        local expectedH = 36  -- titleRow
        if step.action and stepBtnLabel ~= "" then
            expectedH = expectedH + 36 + 14  -- btnContainer + margins (4 top + 10 bottom)
        else
            expectedH = expectedH + 6  -- spacer
        end
        expectedH = expectedH + 50  -- desc label estimate + margins
        stepPanel:SetTall(math.max(expectedH, 80))

        -- Deferred: recalculate after layout is finalized
        timer.Simple(0, function()
            if not IsValid(stepPanel) then return end
            local totalH = 0
            for _, child in ipairs(stepPanel:GetChildren()) do
                totalH = totalH + child:GetTall()
                local _, t, _, b = child:GetDockMargin()
                totalH = totalH + t + b
            end
            stepPanel:SetTall(math.max(totalH, 80))
        end)
    end

    -- Bottom padding
    local bottomPad = vgui.Create("DPanel", scroll)
    bottomPad:Dock(TOP)
    bottomPad:SetTall(20)
    bottomPad.Paint = function() end

    return scroll
end

-- ============================================================
-- Main dispatch: RenderMode
-- Called by core.lua BuildModePanel
-- ============================================================
function vrmod.fguide.RenderMode(parent, modeKey)
    local mode = FindMode(modeKey)
    if not mode then
        local lbl = vgui.Create("DLabel", parent)
        lbl:SetText("Unknown mode: " .. modeKey)
        lbl:SetFont("VRFGuide_Body")
        lbl:SetTextColor(vrmod.fguide.COLORS.text_primary)
        lbl:Dock(FILL)
        return lbl
    end

    if mode.type == "toggle" then
        return RenderToggleMode(parent, mode)
    elseif mode.type == "wizard" then
        return RenderWizardMode(parent, mode)
    end

    -- Fallback for unknown type
    local lbl = vgui.Create("DLabel", parent)
    lbl:SetText("Unsupported mode type: " .. tostring(mode.type))
    lbl:SetFont("VRFGuide_Body")
    lbl:SetTextColor(vrmod.fguide.COLORS.text_primary)
    lbl:Dock(FILL)
    return lbl
end

print("[VRMod] Feature Guide modes loaded")
