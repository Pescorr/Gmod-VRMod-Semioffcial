--[[
    Module 15: Hand Sync Mode — Menu
    Settings02 DTree に Hand Sync パネルを追加する（スタンドアロン時はタブ）。
]]

AddCSLuaFile()
if SERVER then return end

hook.Add(
    "VRMod_Menu",
    "addsettings_handsyncmode",
    function(frame)
        if not frame or not frame.DPropertySheet then return end

        local ok, err = pcall(function()
        local mainPanel = vgui.Create("DPanel")
        mainPanel.Paint = function(self, w, h) end

        local scroll = vgui.Create("DScrollPanel", mainPanel)
        scroll:Dock(FILL)

        local form = vgui.Create("DForm", scroll)
        form:SetName("Hand Sync Settings")
        form:Dock(TOP)
        form.Header:SetVisible(false)
        form.Paint = function(self, w, h) end

        -- メインスイッチ: ON = empty hand維持 / OFF = 元の仕様
        form:CheckBox("Always use Empty Hand fingers", "vrmod_unoff_hand_sync_mode")

        form:Help(
            "ON: All weapons use empty-hand style natural finger tracking. "
            .. "VR controller input (trigger/grip) moves fingers naturally.\n\n"
            .. "OFF: Default behavior. Fingers use weapon-specific grip pose."
        )

        -- Reset button
        local resetBtn = form:Button("Restore Default Settings")
        resetBtn.DoClick = function()
            RunConsoleCommand("vrmod_unoff_hand_sync_mode", "1")
            chat.AddText(Color(0, 255, 0), "[Hand Sync] Settings reset to defaults.")
        end

        -- Dual-mode registration
        if frame.Settings02Register then
            local success = frame.Settings02Register("handsync", "Hand Sync", "icon16/hand.png", mainPanel)
            if not success then
                frame.DPropertySheet:AddSheet("Hand Sync", mainPanel, "icon16/hand.png")
            end
        else
            frame.DPropertySheet:AddSheet("Hand Sync", mainPanel, "icon16/hand.png")
        end

        end) -- pcall end
        if not ok then
            print("[VRMod] Menu hook error (addsettings_handsyncmode): " .. tostring(err))
        end
    end
)
