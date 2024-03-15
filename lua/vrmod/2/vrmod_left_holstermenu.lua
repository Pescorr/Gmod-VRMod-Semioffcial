if SERVER then return end
-- local convars, convarValues = vrmod.GetConvars()
hook.Add(
    "VRMod_Menu",
    "pVRHolsterMenu_left",
    function(frame)
        local sheet = vgui.Create("DPropertySheet", frame.DPropertySheet)
        frame.DPropertySheet:AddSheet("Holster(left)", sheet)
        sheet:Dock(FILL)
        -- Panel "ConVar編集メニュー" for Left Hand
        local panelConVarEditor = vgui.Create("DPanel", sheet)
        panelConVarEditor.Paint = function(self, w, h)
            draw.RoundedBox(4, 0, 0, w, h, Color(0, 0, 0, self:GetAlpha()))
        end

        sheet:AddSheet("ConVar (Left)", panelConVarEditor, "icon16/wrench.png")
        local scrollPanel = vgui.Create("DScrollPanel", sheet)
        scrollPanel:Dock(FILL)
        local posY = 40
        -- CheckBox ConVars for Left Hand
        local checkBoxConVars = {
            {
                convar = "vrmod_weppouch_left_Spine",
                label = "Spine Enable (Left)"
            },
            {
                convar = "vrmod_weppouch_left_Head",
                label = "Head Enable (Left)"
            },
            {
                convar = "vrmod_weppouch_left_Pelvis",
                label = "Pelvis Enable (Left)"
            }
        }

        for _, data in pairs(checkBoxConVars) do
            local checkBox = vgui.Create("DCheckBoxLabel", sheet)
            checkBox:SetPos(25, posY)
            checkBox:SetText(data.label)
            checkBox:SetConVar(data.convar)
            checkBox:SizeToContents()
            posY = posY + 20
        end

        -- DNumSlider ConVars for Pouch Range (Left Hand)
        local numSliderConVars = {
            {
                convar = "vrmod_weppouch_left_dist_spine",
                label = "Pouch Range (Spine, Left)"
            },
            {
                convar = "vrmod_weppouch_left_dist_head",
                label = "Pouch Range (Head, Left)"
            },
            {
                convar = "vrmod_weppouch_left_dist_Pelvis",
                label = "Pouch Range (Pelvis, Left)"
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
        
        -- DTextEntry ConVars for Left Hand
        local textEntryConVars = {"vrmod_weppouch_weapon_left_Spine", "vrmod_weppouch_weapon_left_Head", "vrmod_weppouch_weapon_left_Pelvis", "vrmod_weppouch_customcvar_left_spine_cmd", "vrmod_weppouch_customcvar_left_head_cmd", "vrmod_weppouch_customcvar_left_pelvis_cmd", "vrmod_weppouch_customcvar_left_spine_put_cmd", "vrmod_weppouch_customcvar_left_head_put_cmd", "vrmod_weppouch_customcvar_left_pelvis_put_cmd"}
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

        -- CheckBox ConVars for Lock (Left Hand)
        local checkBoxConVars02 = {
            {
                convar = "vrmod_weppouch_weapon_lock_left_Spine",
                label = "Spine Lock"
            },
            {
                convar = "vrmod_weppouch_weapon_lock_left_Head",
                label = "Head Lock"
            },
            {
                convar = "vrmod_weppouch_weapon_lock_left_Pelvis",
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

        -- CheckBox ConVars for Custom Convar Mode (Left Hand)
        local checkBoxConVars03 = {
            {
                convar = "vrmod_weppouch_customcvar_left_spine_enable",
                label = "Spine Convarmode"
            },
            {
                convar = "vrmod_weppouch_customcvar_left_head_enable",
                label = "Head Convarmode"
            },
            {
                convar = "vrmod_weppouch_customcvar_left_pelvis_enable",
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