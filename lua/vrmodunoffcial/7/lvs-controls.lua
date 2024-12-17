-- LVS Controls Configuration Module
local lvsControls = {}

-- デフォルトのコントロール設定
local defaultControls = {
    throttle = "vector1_forward",
    brake = "vector1_reverse",
    steer = "vector2_steer",
    weapon1 = "boolean_primaryfire",
    weapon2 = "boolean_secondaryfire",
    exit = "boolean_use"
}

-- コンバーの作成
CreateClientConVar("vrmod_lvs_controls_enabled", "1", true, FCVAR_ARCHIVE)

-- カスタムコントロールの保存/読み込み
function lvsControls.SaveConfig(config)
    file.Write("vrmod/lvs_controls.txt", util.TableToJSON(config))
end

function lvsControls.LoadConfig()
    if file.Exists("vrmod/lvs_controls.txt", "DATA") then
        return util.JSONToTable(file.Read("vrmod/lvs_controls.txt", "DATA"))
    end
    return defaultControls
end

-- コントロール設定UIの作成
function lvsControls.CreateSettingsUI(parent)
    local panel = vgui.Create("DPanel", parent)
    panel:Dock(FILL)
    
    local controls = lvsControls.LoadConfig()
    
    -- 各コントロールの設定UIを作成
    for control, action in pairs(controls) do
        local row = vgui.Create("DPanel", panel)
        row:Dock(TOP)
        row:DockMargin(5, 5, 5, 0)
        
        local label = vgui.Create("DLabel", row)
        label:SetText(control)
        label:Dock(LEFT)
        
        local binder = vgui.Create("DBinder", row)
        binder:Dock(FILL)
        binder:SetValue(input.GetKeyCode(action))
        
        function binder:OnChange(num)
            controls[control] = input.GetKeyName(num)
            lvsControls.SaveConfig(controls)
        end
    end
    
    return panel
end

-- 入力処理の更新
hook.Add("VRMod_Input", "LVSControlsHandler", function(action, pressed)
    if not vrmod.IsPlayerInVR(LocalPlayer()) then return end
    
    local controls = lvsControls.LoadConfig()
    local vehicle = LocalPlayer():GetVehicle()
    
    if IsValid(vehicle) and vehicle.LVS then
        -- カスタム設定に基づいて入力を処理
        for control, boundAction in pairs(controls) do
            if action == boundAction then
                net.Start("LVS_Input")
                net.WriteString(control)
                net.WriteBool(pressed)
                net.SendToServer()
            end
        end
    end
end)

return lvsControls
