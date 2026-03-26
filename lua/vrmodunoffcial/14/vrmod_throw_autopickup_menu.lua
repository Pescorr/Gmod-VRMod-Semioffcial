--[[
    Module 15: VR Throw Auto-Pickup — Menu
    VRThrow タブ内に Auto-Pickup 設定を追加する。
    Module 14の VRThrow タブが存在する前提で、その下にコントロールを追加。
]]

AddCSLuaFile()
if SERVER then return end

hook.Add(
    "VRMod_Menu",
    "addsettings_vrthrow_autopickup",
    function(frame)
        if not frame.VRplaySheet then return end

        -- Module 14のVRThrowタブを検索
        local throwTab = nil
        for _, tab in ipairs(frame.VRplaySheet:GetItems()) do
            if tab.Name == "VRThrow" then
                throwTab = tab
                break
            end
        end

        if not throwTab then
            -- Module 14が無効の場合は独立タブを作成
            local mainPanel = vgui.Create("DPanel", frame.VRplaySheet)
            frame.VRplaySheet:AddSheet("AutoPickup", mainPanel, "icon16/bomb.png")
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

            local resetBtn = form:Button(
                VRModL and VRModL("btn_restore_defaults", "Restore Default Settings")
                or "Restore Default Settings"
            )
            resetBtn.DoClick = function()
                if VRModResetCategory then
                    VRModResetCategory("throw_autopickup")
                else
                    RunConsoleCommand("vrmod_unoff_throw_autopickup", "1")
                    RunConsoleCommand("vrmod_unoff_throw_autopickup_debug", "0")
                end
                chat.AddText(Color(0, 255, 0), "[VRThrow AutoPickup] Settings reset to defaults.")
            end
            return
        end

        -- Module 14のVRThrowタブ内のスクロールパネルを取得
        local mainPanel = throwTab.Panel
        if not IsValid(mainPanel) then return end

        -- 既存のスクロールパネルを探す
        local scroll = nil
        for _, child in ipairs(mainPanel:GetChildren()) do
            if child:GetClassName() == "DScrollPanel" then
                scroll = child
                break
            end
        end
        if not IsValid(scroll) then return end

        -- Auto-Pickup セクション追加
        local form = vgui.Create("DForm", scroll)
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
    end
)
