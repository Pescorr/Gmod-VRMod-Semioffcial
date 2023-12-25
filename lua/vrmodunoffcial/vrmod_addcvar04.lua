-- local function DrawRedFrameAroundButtons()
--     local function drawFrame(panel)
--         if panel:GetClassName() == "DButton" then
--             local x, y = panel:LocalToScreen(0, 0)
--             local w, h = panel:GetSize()

--             surface.SetDrawColor(255, 0, 0, 255) -- 赤色
--             surface.DrawOutlinedRect(x, y, w, h)
--         end
--     end

--     local function searchPanels(panel)
--         if not IsValid(panel) then return end
--         drawFrame(panel)

--         local children = panel:GetChildren()
--         for _, child in ipairs(children) do
--             searchPanels(child)
--         end
--     end

--     searchPanels(vgui.GetWorldPanel())
-- end

-- hook.Add("HUDPaint", "DrawRedFrameAroundAllButtons", DrawRedFrameAroundButtons)
