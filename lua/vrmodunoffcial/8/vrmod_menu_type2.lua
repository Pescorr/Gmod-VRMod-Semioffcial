-- hook.Add("VRMod_Menu", "vrmod_settings", function(frame)
--     local settingsPanel = vgui.Create("DPanel", frame)
--     settingsPanel:Dock(FILL)
--     settingsPanel:DockPadding(10, 10, 10, 10)

--     local categoryList = vgui.Create("DCategoryList", settingsPanel)
--     categoryList:Dock(FILL)

--     -- VR基本設定
--     local basicSettings = categoryList:Add("VR基本設定")
--     local basicForm = vgui.Create("DForm")
--     basicForm:SetName("")
--     basicSettings:SetContents(basicForm)
    
--     basicForm:CheckBox("HUD Enable", "vrmod_hud")
--     basicForm:CheckBox("Enable seated mode", "vrmod_seated")
--     basicForm:CheckBox("Alternative Character Yaw", "vrmod_oldcharacteryaw")
--     basicForm:CheckBox("VRMod Menu Show on Startup", "vrmod_showonstartup")
--     basicForm:NumSlider("Scale", "vrmod_scale", 1, 100, 1)
--     basicForm:NumSlider("Character Eye Height", "vrmod_characterEyeHeight", 10.0, 100.8, 1)
    
--     -- HUD設定
--     local hudSettings = categoryList:Add("HUD設定")
--     local hudForm = vgui.Create("DForm")
--     hudForm:SetName("")
--     hudSettings:SetContents(hudForm)

--     hudForm:NumSlider("HUD Scale", "vrmod_hudscale", 0.01, 0.20, 2)
--     hudForm:NumSlider("HUD Distance", "vrmod_huddistance", 1, 200, 0)
--     hudForm:NumSlider("HUD Curve", "vrmod_hudcurve", 1, 100, 0)
--     hudForm:NumSlider("HUD Alpha", "vrmod_hudtestalpha", 0, 255, 0)
--     hudForm:CheckBox("HUD Only While Pressing Menu Key", "vrmod_hud_visible_quickmenukey")

--     -- 入力設定
--     local inputSettings = categoryList:Add("入力設定")
--     local inputForm = vgui.Create("DForm")
--     inputForm:SetName("")
--     inputSettings:SetContents(inputForm)

--     inputForm:CheckBox("Auto Jump Duck", "vrmod_autojumpduck")
--     inputForm:CheckBox("Enable Teleport", "vrmod_allow_teleport_client")
--     inputForm:CheckBox("Left Hand Mode", "vrmod_LeftHand")
--     inputForm:CheckBox("Left Hand Fire", "vrmod_lefthandleftfire")
--     inputForm:CheckBox("VR Disable Pickup (Client)", "vr_pickup_disable_client")

--     -- メニュー表示設定
--     local menuSettings = categoryList:Add("メニュー表示設定")
--     local menuForm = vgui.Create("DForm")
--     menuForm:SetName("")
--     menuSettings:SetContents(menuForm)

--     local quickmenuAttach = menuForm:ComboBox("Quickmenu Attach Position", "vrmod_attach_quickmenu")
--     quickmenuAttach:AddChoice("Left Hand", "1")
--     quickmenuAttach:AddChoice("Right Hand", "2")
--     quickmenuAttach:AddChoice("HMD", "3")
--     quickmenuAttach:AddChoice("Static", "4")

--     menuForm:CheckBox("Menu & UI Red Outline", "vrmod_ui_outline")
--     menuForm:CheckBox("UI Render Alternative", "vrmod_ui_realtime")
--     menuForm:CheckBox("Desktop Camera Override", "vrmod_cameraoverride")

--     -- パフォーマンス設定
--     local perfSettings = categoryList:Add("パフォーマンス設定")
--     local perfForm = vgui.Create("DForm")
--     perfForm:SetName("")
--     perfSettings:SetContents(perfForm)

--     perfForm:CheckBox("Enable Multi-core Rendering", "gmod_mcore_test")
--     perfForm:CheckBox("Mirror Optimization", "vrmod_mirror_optimization")
--     perfForm:NumSlider("Render Target Width", "vrmod_rtWidth_Multiplier", 0.1, 5.0, 1)
--     perfForm:NumSlider("Render Target Height", "vrmod_rtHeight_Multiplier", 0.1, 5.0, 1)
--     perfForm:CheckBox("Automatic Resolution Set", "vrmod_scr_alwaysautosetting")
--     perfForm:CheckBox("Skybox Enable", "r_3dsky")
    
--     -- ネットワーク設定
--     local netSettings = categoryList:Add("ネットワーク設定")
--     local netForm = vgui.Create("DForm")
--     netForm:SetName("")
--     netSettings:SetContents(netForm)

--     netForm:NumSlider("Net Delay", "vrmod_net_delay", 0, 1, 3)
--     netForm:NumSlider("Net Delay Max", "vrmod_net_delaymax", 0, 100, 3)
--     netForm:NumSlider("Net Stored Frames", "vrmod_net_storedframes", 1, 25, 3)
--     netForm:NumSlider("Net Tickrate", "vrmod_net_tickrate", 1, 100, 3)

--     -- クイックメニュー設定
--     local quickSettings = categoryList:Add("クイックメニュー設定")
--     local quickForm = vgui.Create("DForm")
--     quickForm:SetName("")
--     quickSettings:SetContents(quickForm)

--     quickForm:CheckBox("Map Browser", "vrmod_quickmenu_mapbrowser_enable")
--     quickForm:CheckBox("VR Exit", "vrmod_quickmenu_exit")
--     quickForm:CheckBox("Chat", "vrmod_quickmenu_chat")
--     quickForm:CheckBox("Toggle Mirror", "vrmod_quickmenu_togglemirror")
--     quickForm:CheckBox("Spawn Menu", "vrmod_quickmenu_spawn_menu")
--     quickForm:CheckBox("Context Menu", "vrmod_quickmenu_context_menu")

--     -- ボタンパネル
--     local buttonPanel = vgui.Create("DPanel", settingsPanel)
--     buttonPanel:Dock(BOTTOM)
--     buttonPanel:DockMargin(0, 5, 0, 0)
--     buttonPanel:SetTall(30)
--     buttonPanel.Paint = function() end

--     local applyButton = vgui.Create("DButton", buttonPanel)
--     applyButton:Dock(RIGHT)
--     applyButton:SetWide(100)
--     applyButton:SetText("Apply & Restart")
--     applyButton.DoClick = function()
--         RunConsoleCommand("vrmod_restart")
--     end

--     local resetButton = vgui.Create("DButton", buttonPanel)
--     resetButton:Dock(RIGHT)
--     resetButton:DockMargin(0, 0, 5, 0)
--     resetButton:SetWide(100)
--     resetButton:SetText("Reset All")
--     resetButton.DoClick = function()
--         RunConsoleCommand("vrmod_character_reset")
--     end

--     -- 初期状態で全カテゴリを折りたたむ
--     timer.Simple(0, function()
--         for _, category in pairs(categoryList:GetChildren()) do
--             if category.Toggle then
--                 category:Toggle()
--             end
--         end
--     end)
-- end)