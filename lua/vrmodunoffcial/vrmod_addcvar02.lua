if CLIENT then
	hook.Add(
		"VRMod_Input",
		"vrutil_novrweapon",
		function(action, pressed)
			if hook.Call("VRMod_AllowDefaultAction", nil, action) == false then return end
			-- if action == "boolean_secondaryfire" then
			-- 	LocalPlayer():ConCommand(pressed and "arccw_dev_benchgun 1" or "arccw_dev_benchgun 0")
			-- 	return
			-- end
			if action == "boolean_flashlight" and pressed then
				LocalPlayer():ConCommand("arccw_firemode")
				LocalPlayer():ConCommand("arccw_toggle_ubgl")

				return
			end
		end
	)
	-- -- 依存するConVarを事前に定義
	-- local convars = {
	-- 	vrmod_seatedoffset = GetConVar("vrmod_seatedoffset"),
	-- 	vrmod_scale = GetConVar("vrmod_scale"),
	-- }
	-- -- 設定値を取得するためのユーティリティ関数
	-- local function getConvarValues()
	-- 	return {
	-- 		vrmod_seatedoffset = convars.vrmod_seatedoffset:GetFloat(),
	-- 		vrmod_characterEyeHeight = GetConVar("vrmod_characterEyeHeight"):GetFloat(),
	-- 		vrmod_scale = convars.vrmod_scale:GetFloat(),
	-- 	}
	-- end
	-- -- concommand 1: seatedoffsetの計算と設定
	-- concommand.Add(
	-- 	"set_vrmod_seatedoffset",
	-- 	function()
	-- 		local convarValues = getConvarValues()
	-- 		local newSeatedOffset = convarValues.vrmod_characterEyeHeight - (g_VR.tracking.hmd.pos.z - convarValues.vrmod_seatedoffset - g_VR.origin.z)
	-- 		convars.vrmod_seatedoffset:SetFloat(newSeatedOffset)
	-- 	end
	-- )
	-- -- concommand 2: VRのスケールの計算と設定
	-- concommand.Add(
	-- 	"adjust_vrmod_scale",
	-- 	function()
	-- 		local convarValues = getConvarValues()
	-- 		g_VR.scale = convarValues.vrmod_characterEyeHeight / ((g_VR.tracking.hmd.pos.z - g_VR.origin.z) / g_VR.scale)
	-- 		convars.vrmod_scale:SetFloat(g_VR.scale)
	-- 	end
	-- )


    local function CreateVRMenuEditor()
        local frame = vgui.Create("DFrame")
        frame:SetSize(600, 400)
        frame:SetTitle("VR Quick Menu Editor")
        frame:Center()
        frame:MakePopup()
    
        local gridSize = 6
        local cellSize = 80
        local padding = 5
    
        local grid = {}
        for i = 1, gridSize do
            grid[i] = {}
            for j = 1, gridSize do
                grid[i][j] = nil
            end
        end
    
        -- 現在のメニューアイテムを格子に配置
        for k, v in pairs(g_VR.menuItems) do
            local x = v.slot + 1
            local y = v.slotPos + 1
            if x <= gridSize and y <= gridSize then
                grid[x][y] = {name = v.name, func = v.func}
            end
        end
    
        local function CreateDraggableButton(name, x, y)
            local button = vgui.Create("DButton", frame)
            button:SetSize(cellSize, cellSize)
            button:SetPos(x * (cellSize + padding), y * (cellSize + padding))
            button:SetText(name)
            button.Dragging = false
            button.Held = false
    
            function button:OnMousePressed()
                self.Held = true
                self:MouseCapture(true)
            end
    
            function button:OnMouseReleased()
                self:MouseCapture(false)
                self.Held = false
                if self.Dragging then
                    self.Dragging = false
                    -- ドロップ位置を計算
                    local dropX = math.floor(self:GetPos().x / (cellSize + padding)) + 1
                    local dropY = math.floor(self:GetPos().y / (cellSize + padding)) + 1
                    if dropX >= 1 and dropX <= gridSize and dropY >= 1 and dropY <= gridSize then
                        -- グリッド位置を更新
                        grid[dropX][dropY] = {name = self:GetText(), func = self.originalFunc}
                    end
                    self:SetPos((dropX-1) * (cellSize + padding), (dropY-1) * (cellSize + padding))
                end
            end
    
            function button:Think()
                if self.Held then
                    if not self.Dragging and self.Held then
                        self.Dragging = true
                    end
                    if self.Dragging then
                        local x, y = gui.MousePos()
                        local px, py = self:GetParent():LocalToScreen(0, 0)
                        self:SetPos(x - px - cellSize/2, y - py - cellSize/2)
                    end
                end
            end
    
            return button
        end
    
        -- グリッドにボタンを配置
        for i = 1, gridSize do
            for j = 1, gridSize do
                if grid[i][j] then
                    local button = CreateDraggableButton(grid[i][j].name, i-1, j-1)
                    button.originalFunc = grid[i][j].func
                end
            end
        end
    
        local applyButton = vgui.Create("DButton", frame)
        applyButton:SetText("Apply Changes")
        applyButton:SetPos(10, frame:GetTall() - 40)
        applyButton:SetSize(580, 30)
        applyButton.DoClick = function()
            -- 新しい配置を g_VR.menuItems に適用
            g_VR.menuItems = {}
            for i = 1, gridSize do
                for j = 1, gridSize do
                    if grid[i][j] then
                        table.insert(g_VR.menuItems, {
                            name = grid[i][j].name,
                            slot = i - 1,
                            slotPos = j - 1,
                            func = grid[i][j].func
                        })
                    end
                end
            end
            frame:Close()
        end
    end
    
    concommand.Add("vr_menu_editor", CreateVRMenuEditor)end


