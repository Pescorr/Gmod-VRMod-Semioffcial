--[[
    Module 15: Hand Sync Mode — Menu
    VRplaySheet に Hand Sync タブを追加する。
]]

AddCSLuaFile()
if SERVER then return end

hook.Add(
    "VRMod_Menu",
    "addsettings_handsyncmode",
    function(frame)
        if not frame.VRplaySheet then return end

        local mainPanel = vgui.Create("DPanel", frame.VRplaySheet)
        frame.VRplaySheet:AddSheet("Hand Sync", mainPanel, "icon16/hand.png")
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
        local resetBtn = form:Button(
            VRModL and VRModL("btn_restore_defaults", "Restore Default Settings")
            or "Restore Default Settings"
        )
        resetBtn.DoClick = function()
            RunConsoleCommand("vrmod_unoff_hand_sync_mode", "0")
            chat.AddText(Color(0, 255, 0), "[Hand Sync] Settings reset to defaults.")
        end
    end
)
