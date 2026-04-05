--[[
    Module 15: VR Throw Auto-Pickup — Menu
    VRThrow パネル内に Auto-Pickup 設定を追加する。
    VRThrow が存在しない場合は独立パネルとして登録（Settings02 or タブ）。
]]

AddCSLuaFile()
if SERVER then return end

hook.Add(
    "VRMod_Menu",
    "addsettings_vrthrow_autopickup",
    function(frame)
        if not frame or not frame.DPropertySheet then return end

        local ok, err = pcall(function()

        -- ========================================
        -- Step 1: VRThrow のスクロールパネルを探す
        -- ========================================
        local targetScroll = nil

        -- 方法A: frame._vrthrow_scroll (S33 dual-mode API)
        if IsValid(frame._vrthrow_scroll) then
            targetScroll = frame._vrthrow_scroll
        end

        -- 方法B: DPropertySheet から "VRThrow" タブを探す (スタンドアロン時)
        if not targetScroll then
            for _, tab in ipairs(frame.DPropertySheet:GetItems()) do
                if tab.Name == "VRThrow" then
                    local mainPanel = tab.Panel
                    if IsValid(mainPanel) then
                        for _, child in ipairs(mainPanel:GetChildren()) do
                            if child:GetClassName() == "DScrollPanel" then
                                targetScroll = child
                                break
                            end
                        end
                    end
                    break
                end
            end
        end

        -- ========================================
        -- Step 2A: VRThrow が見つかった → そこにマージ
        -- ========================================
        if IsValid(targetScroll) then
            local form = vgui.Create("DForm", targetScroll)
            form:SetName("Auto-Pickup Settings")
            form:Dock(TOP)
            form:DockMargin(0, 8, 0, 0)
            form.Paint = function(self, w, h) end

            form:Help("--- Auto-Pickup (Module 15) ---")
            form:CheckBox("Enable Auto-Pickup (hold grip to catch)", "vrmod_unoff_throw_autopickup")
            form:Help(
                "Hold grip button while throwing a grenade to catch the projectile. "
                .. "Release grip to physically throw it."
            )
            form:CheckBox("Debug: Log Auto-Pickup Events", "vrmod_unoff_throw_autopickup_debug")
            return
        end

        -- ========================================
        -- Step 2B: VRThrow が無い → 独立パネルとして登録
        -- ========================================
        local mainPanel = vgui.Create("DPanel")
        mainPanel.Paint = function(self, w, h) end

        local scroll = vgui.Create("DScrollPanel", mainPanel)
        scroll:Dock(FILL)

        local form = vgui.Create("DForm", scroll)
        form:SetName("VR Throw Auto-Pickup")
        form:Dock(TOP)
        form.Header:SetVisible(false)
        form.Paint = function(self, w, h) end

        form:CheckBox("Enable Auto-Pickup (hold grip to catch)", "vrmod_unoff_throw_autopickup")
        form:Help(
            "Hold grip button while throwing a grenade to catch the projectile in your hand. "
            .. "Release grip to physically throw it with VR hand motion. "
            .. "Requires Module 14 (VR Throw) to detect throwable weapons."
        )
        form:CheckBox("Debug: Log Auto-Pickup Events", "vrmod_unoff_throw_autopickup_debug")

        local resetBtn = form:Button("Restore Default Settings")
        resetBtn.DoClick = function()
            RunConsoleCommand("vrmod_unoff_throw_autopickup", "1")
            RunConsoleCommand("vrmod_unoff_throw_autopickup_debug", "0")
            chat.AddText(Color(0, 255, 0), "[VRThrow AutoPickup] Settings reset to defaults.")
        end

        -- Dual-mode registration
        if frame.Settings02Register then
            local success = frame.Settings02Register("throw_autopickup", "AutoPickup", "icon16/bomb.png", mainPanel)
            if not success then
                frame.DPropertySheet:AddSheet("AutoPickup", mainPanel, "icon16/bomb.png")
            end
        else
            frame.DPropertySheet:AddSheet("AutoPickup", mainPanel, "icon16/bomb.png")
        end

        end) -- pcall end
        if not ok then
            print("[VRMod] Menu hook error (addsettings_vrthrow_autopickup): " .. tostring(err))
        end
    end
)
