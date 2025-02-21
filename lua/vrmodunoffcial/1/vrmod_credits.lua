-- if SERVER then return end

-- local credits = [[
-- Special Thanks:
-- -出資者1 - Gold Supporter
-- -出資者2 - Silver Supporter
-- -出資者3 - Bronze Supporter

-- VRMod Developers:
-- -Developer1 - Lead Developer
-- -Developer2 - Contributor
-- -Developer3 - UI Developer
-- ]]

-- hook.Add("VRMod_Menu", "credits", function(frame)
--     local panel = vgui.Create("DPanel", frame.DPropertySheet)
--     frame.DPropertySheet:AddSheet("Credits", panel)
    
--     local richtext = vgui.Create("RichText", panel)
--     richtext:Dock(FILL)
--     richtext:InsertColorChange(0, 0, 0, 255)
--     richtext:AppendText(credits)
--     richtext.PerformLayout = function(self)
--         richtext:SetBGColor(255, 255, 255, 255)
--         richtext:SetFGColor(0, 0, 0, 255)
--         richtext:SetFontInternal("DermaDefault")
--     end
-- end)
