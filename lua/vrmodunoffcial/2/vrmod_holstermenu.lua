if SERVER then return end
-- local convars, convarValues = vrmod.GetConvars()
hook.Add(
    "VRMod_Menu",
    "pVRHolsterMenu",
    function(frame)
        --Settings02 Start
        --add VRMod_Menu Settings02 propertysheet start
        local sheet = vgui.Create("DPropertySheet", frame.DPropertySheet)
        frame.DPropertySheet:AddSheet("Holster(right)", sheet)
        sheet:Dock(FILL)
        --add VRMod_Menu Settings02 propertysheet end
        -- Panel "ConVar編集メニュー" Start
        local panelConVarEditor = vgui.Create("DPanel", sheet)
        panelConVarEditor.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, self:GetAlpha()))
        end

        sheet:AddSheet("ConVar(Right)", panelConVarEditor, "icon16/wrench.png")
        local scrollPanel = vgui.Create("DScrollPanel", sheet)
        scrollPanel:Dock(FILL)
        local posY = 40
        -- CheckBox ConVars
        local checkBoxConVars0A = {
            {
                convar = "vrmod_weppouch_Spine",
                label = "Spine Enable"
            },
            {
                convar = "vrmod_weppouch_Head",
                label = "Head Enable"
            },
            {
                convar = "vrmod_weppouch_Pelvis",
                label = "Pelvis Enable"
            }
        }

        for _, data in pairs(checkBoxConVars0A) do
            local checkBox = vgui.Create("DCheckBoxLabel", sheet)
            checkBox:SetPos(20, posY)
            checkBox:SetText(data.label)
            checkBox:SetConVar(data.convar)
            checkBox:SizeToContents()
            posY = posY + 20
        end

        -- CheckBox ConVars
        local checkBoxConVars0B = {
            {
                convar = "vrmod_pickupoff_weaponholster",
                label = "Pickup Off -> Weapon Holster"
            },
            {
                convar = "vrmod_weapondrop_enable",
                label = "[WIP]Weapon Drop Enable"
            },
            {
                convar = "vrmod_weapondrop_trashwep",
                label = "[WIP][Weapon Drop Mode]"
            }
        }

        for _, data in pairs(checkBoxConVars0B) do
            local checkBox0B = vgui.Create("DCheckBoxLabel", sheet)
            checkBox0B:SetPos(115, posY - 60)
            checkBox0B:SetText(data.label)
            checkBox0B:SetConVar(data.convar)
            checkBox0B:SizeToContents()
            posY = posY + 20
        end

        -- CheckBox ConVars
        local checkBoxConVars0C = {
            {
                convar = "vrmod_weppouch_visiblerange",
                label = "Pouchrange\nVisible"
            }
        }
        for _, data in pairs(checkBoxConVars0C) do
            local ConVars0C = vgui.Create("DCheckBoxLabel", sheet)
            ConVars0C:SetPos(290, posY - 120)
            ConVars0C:SetText(data.label)
            ConVars0C:SetConVar(data.convar)
            ConVars0C:SizeToContents()
        posY = posY + 20
        end
        posY = posY - 80
        -- DNumSlider ConVars
        local numSliderConVars = {
            {
                convar = "vrmod_weppouch_dist_spine",
                label = "pouch range (Spine)"
            },
            {
                convar = "vrmod_weppouch_dist_head",
                label = "pouch range (Head)"
            },
            {
                convar = "vrmod_weppouch_dist_Pelvis",
                label = "pouch range (Pelvis)"
            }
        }

        for _, data in pairs(numSliderConVars) do
            local slider = vgui.Create("DNumSlider", sheet)
            slider:SetPos(25, posY)
            slider:SetSize(320, 25)
            slider:SetText(data.label)
            slider:SetMin(0)
            slider:SetMax(50)
            slider:SetDecimals(0)
            slider:SetConVar(data.convar)
            posY = posY + 30
        end

        -- DTextEntry ConVars
        local textEntryConVars = {"vrmod_weppouch_weapon_Spine", "vrmod_weppouch_weapon_Head", "vrmod_weppouch_weapon_Pelvis", "vrmod_weppouch_customcvar_spine_cmd", "vrmod_weppouch_customcvar_head_cmd", "vrmod_weppouch_customcvar_pelvis_cmd", "vrmod_weppouch_customcvar_spine_put_cmd", "vrmod_weppouch_customcvar_head_put_cmd", "vrmod_weppouch_customcvar_pelvis_put_cmd"}
        for _, convar in pairs(textEntryConVars) do
            local label = vgui.Create("DLabel", sheet)
            label:SetPos(20, posY)
            label:SetText(convar)
            label:SizeToContents()
            local textEntry = vgui.Create("DTextEntry", sheet)
            textEntry:SetPos(20, posY)
            textEntry:SetSize(320, 20)
            textEntry:SetConVar(convar)
            textEntry:SetValue(GetConVarString(convar))
            posY = posY + 20
        end

        -- CheckBox ConVars
        local checkBoxConVars02 = {
            {
                convar = "vrmod_weppouch_weapon_lock_Spine",
                label = "Spine Lock"
            },
            {
                convar = "vrmod_weppouch_weapon_lock_Head",
                label = "Head Lock"
            },
            {
                convar = "vrmod_weppouch_weapon_lock_Pelvis",
                label = "Pelvis Lock"
            }
        }

        for _, data in pairs(checkBoxConVars02) do
            local checkBox02 = vgui.Create("DCheckBoxLabel", sheet)
            checkBox02:SetPos(220, posY - 178)
            checkBox02:SetText(data.label)
            checkBox02:SetConVar(data.convar)
            checkBox02:SizeToContents()
            posY = posY + 20
        end

        -- CheckBox ConVars
        local checkBoxConVars03 = {
            {
                convar = "vrmod_weppouch_customcvar_spine_enable",
                label = "Spine Convarmode"
            },
            {
                convar = "vrmod_weppouch_customcvar_head_enable",
                label = "Head Convarmode"
            },
            {
                convar = "vrmod_weppouch_customcvar_pelvis_enable",
                label = "Pelvis Convarmode"
            }
        }

        for _, data in pairs(checkBoxConVars03) do
            local checkBox03 = vgui.Create("DCheckBoxLabel", sheet)
            checkBox03:SetPos(220, posY - 178)
            checkBox03:SetText(data.label)
            checkBox03:SetConVar(data.convar)
            checkBox03:SizeToContents()
            posY = posY + 20
        end
    end
)
-- Derma Panel End
-- Panel "ConVar編集メニュー" End	