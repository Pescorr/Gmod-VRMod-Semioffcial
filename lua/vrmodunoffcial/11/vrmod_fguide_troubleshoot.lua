--[[
    VRMod Feature Guide: Troubleshoot Decision Tree + Renderer
    分岐型フローチャート — テキストはL()キーで言語ファイルから取得
    L() key mapping:
      Question text: ts_{nodeKey}_question  (fallback: node.question)
      Option label:  ts_{option.key}        (fallback: option.label)
      Solution text: ts_{nodeKey}           (fallback: node.solution)
]]

AddCSLuaFile()
if SERVER then return end

vrmod = vrmod or {}
vrmod.fguide = vrmod.fguide or {}

-- ============================================================
-- Decision Tree Data
-- Option keys match lang file ts_ keys exactly
-- ============================================================
vrmod.fguide.troubleshoot = {
    -- ============================================================
    -- Root: What's the problem?
    -- ============================================================
    root = {
        question = "What kind of problem are you having?",
        options = {
            { label = "Can't move",             key = "cant_move",    next = "cant_move" },
            { label = "Display issues",         key = "display",      next = "display" },
            { label = "Crash / Error",          key = "crash",        next = "crash" },
            { label = "Controls not working",   key = "controls",     next = "controls" },
            { label = "Performance is bad",     key = "perf",         next = "perf" },
        },
    },

    -- ============================================================
    -- Branch: Can't Move
    -- ============================================================
    cant_move = {
        question = "Is the console (~) or main menu open?",
        options = {
            { label = "Yes", key = "yes", next = "cant_move_close" },
            { label = "No",  key = "no",  next = "cant_move_2" },
        },
    },
    cant_move_close = {
        solution = "Close the console with ~ key, or close the main menu with ESC. You cannot move while these are open.",
    },
    cant_move_2 = {
        question = "Are you in a special gamemode (Helix, DarkRP, etc.)?",
        options = {
            { label = "Yes",          key = "yes",        next = "cant_move_gamemode" },
            { label = "No / Sandbox", key = "no_sandbox", next = "cant_move_3" },
        },
    },
    cant_move_gamemode = {
        solution = "Some gamemodes (especially Helix) restrict VR movement. Try noclip (V key). If that works, it's a gamemode limitation.",
    },
    cant_move_3 = {
        question = "Can you move your hands but not walk?",
        options = {
            { label = "Yes - hands work, can't walk", key = "hands_ok", next = "cant_move_stick" },
            { label = "No - nothing moves at all",    key = "nothing",  next = "cant_move_frozen" },
        },
    },
    cant_move_stick = {
        solution = "Check SteamVR controller bindings. Go to SteamVR Settings > Controllers > Manage Controller Bindings > select VRMod. Make sure the thumbstick/trackpad is bound to movement.",
    },
    cant_move_frozen = {
        solution = "Try: 1) vrmod_stop then vrmod_start in console. 2) If still frozen, disable all other addons and retry. 3) Check if your headset is tracking properly in SteamVR Home.",
    },

    -- ============================================================
    -- Branch: Display Issues
    -- ============================================================
    display = {
        question = "What do you see?",
        options = {
            { label = "One eye is gray",        key = "gray_eye", next = "display_gray" },
            { label = "Screen flickering",      key = "flicker",  next = "display_flicker" },
            { label = "Black borders",          key = "borders",  next = "display_borders" },
            { label = "Head/hair in view",      key = "head",     next = "display_head" },
            { label = "View stretches/wobbles", key = "wobble",   next = "display_wobble" },
        },
    },
    display_gray = {
        solution = "Addon conflict is the most common cause. Disable ALL other addons, test VRMod alone. If it works, re-enable addons one by one to find the culprit. ReShade is a known cause.",
    },
    display_flicker = {
        question = "Is SteamVR Desktop Game Theatre disabled?",
        options = {
            { label = "I don't know / No",    key = "dont_know",    next = "display_flicker_fix" },
            { label = "Yes, it's disabled",   key = "yes_disabled", next = "display_flicker_2" },
        },
    },
    display_flicker_fix = {
        solution = "Steam Library > Right-click Garry's Mod > Properties > General > Uncheck 'Use Desktop Game Theatre while SteamVR is active'. Also add -window to launch options.",
    },
    display_flicker_2 = {
        solution = "Try disabling Motion Smoothing in SteamVR settings (Video > Motion Smoothing > OFF). Also disable all other addons to check for conflicts.",
    },
    display_borders = {
        solution = "Black borders around vision are a known issue with Quest 3 due to FOV differences. Try adjusting SteamVR render resolution (Settings > Video > Render Resolution). This is an upstream VRMod limitation.",
    },
    display_head = {
        question = "Have you enabled 'Hide Head' in settings?",
        options = {
            { label = "No",                    key = "no",                next = "display_head_fix" },
            { label = "Yes, but still visible", key = "yes_still_visible", next = "display_head_adjust" },
        },
    },
    display_head_fix = {
        solution = "Go to VRMod menu > Character > enable vrmod_hide_head. This offsets head bones from your VR view.",
    },
    display_head_adjust = {
        solution = "Adjust vrmod_hide_head_pos_y (front/back offset). Default is 20. Try increasing to 30-40. Use the mirror to check results.",
    },
    display_wobble = {
        solution = "Disable Motion Smoothing in SteamVR. Find steamvr.vrsettings in your Steam install folder > config, and set Motion Smoothing to false. This is the most common cause of view wobble/stretching.",
    },

    -- ============================================================
    -- Branch: Crash / Error
    -- ============================================================
    crash = {
        question = "When does the crash happen?",
        options = {
            { label = "On VR start (vrmod_start)", key = "on_start",  next = "crash_start" },
            { label = "During gameplay",           key = "gameplay",   next = "crash_gameplay" },
            { label = "Error message in console",  key = "error_msg", next = "crash_error" },
        },
    },
    crash_start = {
        question = "Do you have -dxlevel 95 in launch options?",
        options = {
            { label = "No / I don't know", key = "dont_know", next = "crash_dxlevel" },
            { label = "Yes",               key = "yes",       next = "crash_start_2" },
        },
    },
    crash_dxlevel = {
        solution = "Add -dxlevel 95 to GMod launch options (Steam > GMod > Properties > Launch Options). Start the game once, then REMOVE -dxlevel 95 (it only needs to run once). Also ensure Desktop Game Theatre is disabled.",
    },
    crash_start_2 = {
        solution = "Try: 1) Verify GMod file integrity in Steam. 2) Reinstall SteamVR. 3) Disable all addons except VRMod. 4) Try -window -novid launch options.",
    },
    crash_gameplay = {
        solution = "Most likely an addon conflict. Test with only VRMod enabled. If stable, add addons back one by one. Rendering/HUD/playermodel addons are most likely to conflict.",
    },
    crash_error = {
        question = "What error do you see?",
        options = {
            { label = "Module not installed",         key = "module",   next = "crash_module" },
            { label = "SetActionManifestPath failed", key = "manifest", next = "crash_manifest" },
            { label = "Unknown module version",       key = "version",  next = "crash_version" },
            { label = "Other / can't read it",        key = "other",    next = "crash_other" },
        },
    },
    crash_module = {
        solution = "Download the VRMod module from catse.net/vrmod and place the DLL in garrysmod/lua/bin/. If antivirus blocks it, add an exception. The semiofficial addon works with both 'original' and 'semiofficial' modules.",
    },
    crash_manifest = {
        solution = "This is a SteamVR-side issue. Fully quit SteamVR > Restart PC > Reinstall SteamVR if needed. Happens across all VRMod versions.",
    },
    crash_version = {
        solution = "Module version mismatch. Re-download the latest module from catse.net/vrmod. Make sure you only have ONE vrmod DLL in garrysmod/lua/bin/.",
    },
    crash_other = {
        solution = "Check console for the full error. Common fixes: 1) Verify GMod files. 2) Reinstall SteamVR. 3) Remove ReShade if installed. 4) Try with no other addons. If the error persists, report it with the full error text.",
    },

    -- ============================================================
    -- Branch: Controls Not Working
    -- ============================================================
    controls = {
        question = "What specifically isn't working?",
        options = {
            { label = "Can't grab / pick up objects", key = "grab",    next = "controls_grab" },
            { label = "Use key doesn't work",         key = "use",     next = "controls_use" },
            { label = "Trigger doesn't fire",         key = "trigger", next = "controls_trigger" },
            { label = "Vehicle controls",             key = "vehicle", next = "controls_vehicle" },
        },
    },
    controls_grab = {
        solution = "Move your hand closer to the object. The grab range is set by vrmod_pickup_range (default 1.1). You can increase it in settings. Also check vrmod_manualpickups is enabled.",
    },
    controls_use = {
        solution = "For Oculus/Meta controllers: the trigger must be FULLY pressed (not half-pressed). Also check SteamVR bindings - the 'Use' action should be bound to the trigger.",
    },
    controls_trigger = {
        solution = "Check SteamVR controller bindings for VRMod. Go to SteamVR Settings > Controllers > Manage Bindings > VRMod. Reset to default bindings if needed.",
    },
    controls_vehicle = {
        question = "Can you get IN the vehicle?",
        options = {
            { label = "Can't enter vehicle",       key = "cant_enter", next = "vehicle_enter" },
            { label = "In vehicle but can't drive", key = "cant_drive", next = "vehicle_drive" },
            { label = "Can't shoot from vehicle",   key = "cant_shoot", next = "vehicle_shoot" },
        },
    },
    vehicle_enter = {
        solution = "Approach the vehicle and press the Use key (fully press trigger). For some vehicle addons (SimFPhys), you may need to look at the door area specifically.",
    },
    vehicle_drive = {
        solution = "Check SteamVR bindings for 'In Vehicle' category. Steering and throttle should be bound. Also try vrmod_lvs_input_mode 0 (legacy) or 1 (networked) to switch input modes.",
    },
    vehicle_shoot = {
        solution = "In SteamVR bindings, check 'In Vehicle' > 'turret_primary_fire' is bound to trigger. For LVS vehicles, weapon selection may also need binding.",
    },

    -- ============================================================
    -- Branch: Performance
    -- ============================================================
    perf = {
        question = "What's your desktop FPS WITHOUT VR? (check with cl_showfps 1)",
        options = {
            { label = "Below 200 FPS", key = "low",  next = "perf_low" },
            { label = "200-400 FPS",   key = "med",  next = "perf_med" },
            { label = "Above 400 FPS", key = "high", next = "perf_high" },
        },
    },
    perf_low = {
        solution = "Your base FPS is too low for comfortable VR. Reduce addon count, use smaller maps, lower GMod graphics settings. VR roughly halves your FPS (rendering twice). Use the Performance wizard button in this guide for quick optimizations.",
    },
    perf_med = {
        solution = "Try these optimizations: 1) gmod_mcore_test 1 (multicore). 2) mat_queue_mode -1 (auto). 3) Reduce vrmod_rtWidth_Multiplier to 1.6. 4) Disable unnecessary addons. Use the Performance wizard in this guide for one-click apply.",
    },
    perf_high = {
        solution = "Your base FPS is good. If VR is still slow: 1) Lower SteamVR render resolution (Settings > Video). 2) Disable Motion Smoothing. 3) Check for specific addon conflicts. 4) Try a small map to isolate the issue.",
    },
}

-- ============================================================
-- Troubleshoot Renderer
-- Creates an interactive decision tree UI
-- ============================================================
function vrmod.fguide.RenderTroubleshoot(parent)
    local L = vrmod.fguide.L
    local COLORS = vrmod.fguide.COLORS
    local tree = vrmod.fguide.troubleshoot

    -- Navigation state (local to this panel instance)
    local history = {}
    local currentNodeKey = "root"

    -- Container that will be rebuilt on navigation
    local outerPanel = vgui.Create("DPanel", parent)
    outerPanel:Dock(FILL)
    outerPanel.Paint = function() end

    -- Content scroll panel (will be rebuilt on each navigation)
    local contentScroll = nil

    -- ============================================================
    -- Build the UI for a given node
    -- ============================================================
    local function ShowNode(nodeKey)
        currentNodeKey = nodeKey
        local node = tree[nodeKey]
        if not node then return end

        -- Remove old content
        if IsValid(contentScroll) then contentScroll:Remove() end

        contentScroll = vgui.Create("DScrollPanel", outerPanel)
        contentScroll:Dock(FILL)

        -- Header
        local header = vgui.Create("DPanel", contentScroll)
        header:Dock(TOP)
        header:SetTall(50)
        header.Paint = function(self, w, h)
            surface.SetDrawColor(COLORS.bg_topbar)
            surface.DrawRect(0, 0, w, h)
            surface.SetDrawColor(COLORS.border)
            surface.DrawLine(0, h - 1, w, h - 1)
            local mat = Material("icon16/exclamation.png", "smooth")
            surface.SetDrawColor(255, 255, 255, 255)
            surface.SetMaterial(mat)
            surface.DrawTexturedRect(15, (h - 20) / 2, 20, 20)
            draw.SimpleText(L("mode_troubleshoot_title", "Troubleshoot"), "VRFGuide_Title",
                45, h / 2 - 2, COLORS.text_primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
        end

        -- Description (only on root)
        if nodeKey == "root" then
            local descLabel = vgui.Create("DLabel", contentScroll)
            descLabel:SetFont("VRFGuide_Body")
            descLabel:SetText(L("mode_troubleshoot_desc", ""))
            descLabel:SetTextColor(COLORS.text_secondary)
            descLabel:Dock(TOP)
            descLabel:DockMargin(15, 12, 15, 5)
            descLabel:SetWrap(true)
            descLabel:SetAutoStretchVertical(true)
        end

        -- ============================================
        -- Question node
        -- ============================================
        if node.question then
            -- Question text
            local questionText = L("ts_" .. nodeKey .. "_question", node.question)

            local questionPanel = vgui.Create("DPanel", contentScroll)
            questionPanel:Dock(TOP)
            questionPanel:DockMargin(15, 15, 15, 10)
            questionPanel:SetTall(40)
            questionPanel.Paint = function(self, w, h)
                draw.RoundedBox(4, 0, 0, w, h, Color(50, 55, 70, 255))
                draw.SimpleText(questionText, "VRFGuide_TSQuestion",
                    15, h / 2, COLORS.text_primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            -- Auto-height for question (if text is long)
            surface.SetFont("VRFGuide_TSQuestion")
            local textW = surface.GetTextSize(questionText)
            local availW = 630 -- approximate content width
            if textW > availW then
                local lines = math.ceil(textW / availW)
                questionPanel:SetTall(20 + lines * 22)
                questionPanel.Paint = function(self, w, h)
                    draw.RoundedBox(4, 0, 0, w, h, Color(50, 55, 70, 255))
                end
                -- Use a DLabel for wrapping
                questionPanel:Clear()
                local qLabel = vgui.Create("DLabel", questionPanel)
                qLabel:SetFont("VRFGuide_TSQuestion")
                qLabel:SetText(questionText)
                qLabel:SetTextColor(COLORS.text_primary)
                qLabel:Dock(FILL)
                qLabel:DockMargin(15, 6, 15, 6)
                qLabel:SetWrap(true)
                qLabel:SetAutoStretchVertical(true)
            end

            -- Option buttons
            if node.options then
                for _, opt in ipairs(node.options) do
                    local optLabel = L("ts_" .. opt.key, opt.label)

                    local optBtn = vgui.Create("DButton", contentScroll)
                    optBtn:Dock(TOP)
                    optBtn:DockMargin(15, 4, 15, 0)
                    optBtn:SetTall(40)
                    optBtn:SetText("")

                    optBtn.Paint = function(self, w, h)
                        local bgCol = self:IsHovered() and COLORS.ts_option_hover or COLORS.ts_option
                        draw.RoundedBox(4, 0, 0, w, h, bgCol)
                        -- Arrow indicator
                        draw.SimpleText(">", "VRFGuide_BodyBold",
                            15, h / 2, COLORS.accent, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                        -- Option text
                        draw.SimpleText(optLabel, "VRFGuide_TSOption",
                            30, h / 2, COLORS.text_primary, TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
                    end

                    optBtn.DoClick = function()
                        if opt.next and tree[opt.next] then
                            table.insert(history, currentNodeKey)
                            ShowNode(opt.next)
                        end
                    end
                end
            end

        -- ============================================
        -- Solution node (terminal)
        -- ============================================
        elseif node.solution then
            local solutionText = L("ts_" .. nodeKey, node.solution)

            -- Solution header
            local solHeader = vgui.Create("DPanel", contentScroll)
            solHeader:Dock(TOP)
            solHeader:DockMargin(15, 15, 15, 5)
            solHeader:SetTall(30)
            solHeader.Paint = function(self, w, h)
                draw.SimpleText(L("ts_solution_title", "Solution"), "VRFGuide_Section",
                    0, h / 2, Color(100, 220, 100), TEXT_ALIGN_LEFT, TEXT_ALIGN_CENTER)
            end

            -- Solution text in a highlighted box
            local solPanel = vgui.Create("DPanel", contentScroll)
            solPanel:Dock(TOP)
            solPanel:DockMargin(15, 0, 15, 10)

            local solLabel = vgui.Create("DLabel", solPanel)
            solLabel:SetFont("VRFGuide_TSSolution")
            solLabel:SetText(solutionText)
            solLabel:SetTextColor(COLORS.text_primary)
            solLabel:Dock(FILL)
            solLabel:DockMargin(15, 12, 15, 12)
            solLabel:SetWrap(true)
            solLabel:SetAutoStretchVertical(true)

            -- Calculate panel height
            surface.SetFont("VRFGuide_TSSolution")
            local tw = surface.GetTextSize(solutionText)
            local lines = math.max(1, math.ceil(tw / 600))
            solPanel:SetTall(lines * 20 + 30)

            solPanel.Paint = function(self, w, h)
                draw.RoundedBox(6, 0, 0, w, h, COLORS.ts_solution_bg)
            end
        end

        -- ============================================
        -- Navigation buttons (Back / Start Over)
        -- ============================================
        local navPanel = vgui.Create("DPanel", contentScroll)
        navPanel:Dock(TOP)
        navPanel:DockMargin(15, 20, 15, 10)
        navPanel:SetTall(40)
        navPanel.Paint = function() end

        if #history > 0 then
            -- Back button
            local backBtn = vgui.Create("DButton", navPanel)
            backBtn:SetText("")
            backBtn:Dock(LEFT)
            backBtn:SetWide(120)
            backBtn.Paint = function(self, w, h)
                local bgCol = self:IsHovered() and COLORS.ts_back_hover or COLORS.ts_back_btn
                draw.RoundedBox(4, 0, 0, w, h, bgCol)
                draw.SimpleText("< " .. L("ts_btn_back", "Back"), "VRFGuide_BodyBold",
                    w / 2, h / 2, COLORS.text_primary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            backBtn.DoClick = function()
                local prevKey = table.remove(history)
                if prevKey then ShowNode(prevKey) end
            end

            -- Start Over button
            local startOverBtn = vgui.Create("DButton", navPanel)
            startOverBtn:SetText("")
            startOverBtn:Dock(LEFT)
            startOverBtn:DockMargin(8, 0, 0, 0)
            startOverBtn:SetWide(150)
            startOverBtn.Paint = function(self, w, h)
                local bgCol = self:IsHovered() and COLORS.ts_back_hover or COLORS.ts_back_btn
                draw.RoundedBox(4, 0, 0, w, h, bgCol)
                draw.SimpleText(L("ts_btn_start_over", "Start Over"), "VRFGuide_Body",
                    w / 2, h / 2, COLORS.text_secondary, TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
            end
            startOverBtn.DoClick = function()
                history = {}
                ShowNode("root")
            end
        end

        -- Bottom padding
        local bottomPad = vgui.Create("DPanel", contentScroll)
        bottomPad:Dock(TOP)
        bottomPad:SetTall(20)
        bottomPad.Paint = function() end
    end

    -- Start at root
    ShowNode("root")

    return outerPanel
end

print("[VRMod] Feature Guide troubleshoot loaded")
