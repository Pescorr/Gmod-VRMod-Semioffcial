--------[vrmod_holstermenu.txt]Start--------
if SERVER then return end
local convars, convarValues = vrmod.GetConvars()
hook.Add(
    "VRMod_Menu",
    "pVRholstermenutype2",
    function(frame)
        --Settings02 Start
        --add VRMod_Menu Settings02 propertysheet start
        local sheet = vgui.Create("DPropertySheet", frame.DPropertySheet)
        frame.DPropertySheet:AddSheet("VRHolster", sheet)
        sheet:Dock(FILL)
        local MenuTab16 = vgui.Create("DPanel", sheet)
        sheet:AddSheet("VRHolster", MenuTab16, "icon16/briefcase.png")
        MenuTab16.Paint = function(self, w, h) end
        local holster_enabled = MenuTab16:Add("DCheckBoxLabel")
        holster_enabled:SetPos(20, 10)
        holster_enabled:SetText("Enable Holster System")
        holster_enabled:SetConVar("vrmod_pouch_enabled")
        holster_enabled:SizeToContents()
        local holster_visiblename = MenuTab16:Add("DCheckBoxLabel")
        holster_visiblename:SetPos(20, 40)
        holster_visiblename:SetText("Show Entity Names(pouch)")
        holster_visiblename:SetConVar("vrmod_pouch_visiblename")
        holster_visiblename:SizeToContents()
        local vrmod_pouch_visiblename_hud = MenuTab16:Add("DCheckBoxLabel")
        vrmod_pouch_visiblename_hud:SetPos(20, 70)
        vrmod_pouch_visiblename_hud:SetText("Show Entity Names(hud)")
        vrmod_pouch_visiblename_hud:SetConVar("vrmod_pouch_visiblename_hud")
        vrmod_pouch_visiblename_hud:SizeToContents()
        local holster_pickup_sound = vgui.Create("DTextEntry", MenuTab16)
        holster_pickup_sound:SetPos(20, 100)
        holster_pickup_sound:SetSize(370, 25)
        holster_pickup_sound:SetText("Holster Pickup Sound")
        holster_pickup_sound:SetConVar("vrmod_pouch_pickup_sound")
        local holsterPositions = {
            {
                part = "Head",
                side = "Right"
            },
            {
                part = "Head",
                side = "Left"
            },
            {
                part = "Chest",
                side = "Right"
            },
            {
                part = "Chest",
                side = "Left"
            },
            {
                part = "Chest",
                side = "Center"
            }
        }

        for i = 1, 5 do
            local holster_size = vgui.Create("DNumSlider", MenuTab16)
            holster_size:SetPos(20, 160 + (i - 1) * 30)
            holster_size:SetSize(370, 25)
            holster_size:SetText(holsterPositions[i].part .. " (" .. holsterPositions[i].side .. ") Holster Size")
            holster_size:SetMin(1)
            holster_size:SetMax(100)
            holster_size:SetDecimals(0)
            holster_size:SetConVar("vrmod_pouch_size_" .. i)
            holster_size.OnValueChanged = function(self, value) end
        end

        -- releaseタブの追加
        local MenuTab12 = vgui.Create("DPanel", sheet)
        sheet:AddSheet("VRHolster2", MenuTab12, "icon16/gun.png")
        MenuTab12.Paint = function(self, w, h) end
        -- vrmod_release.luaのconvarを操作するメニュー項目の追加
        local releaseenable_checkbox = MenuTab12:Add("DCheckBoxLabel")
        releaseenable_checkbox:SetPos(20, 10)
        releaseenable_checkbox:SetText("[release -> Emptyhand] Enable")
        releaseenable_checkbox:SetConVar("vrmod_pickupoff_weaponholster")
        releaseenable_checkbox:SizeToContents()
        local dropenable_checkbox = MenuTab12:Add("DCheckBoxLabel")
        dropenable_checkbox:SetPos(20, 40)
        dropenable_checkbox:SetText("[Tediore like reload] Enable")
        dropenable_checkbox:SetConVar("vrmod_weapondrop_enable")
        dropenable_checkbox:SizeToContents()
        local dropmode_checkbox = MenuTab12:Add("DCheckBoxLabel")
        dropmode_checkbox:SetPos(20, 70)
        dropmode_checkbox:SetText("Trash Weapon on Drop")
        dropmode_checkbox:SetConVar("vrmod_weapondrop_trashwep")
        dropmode_checkbox:SizeToContents()
        local vrmod_pouch_lefthandwep_enable = MenuTab12:Add("DCheckBoxLabel")
        vrmod_pouch_lefthandwep_enable:SetPos(20, 100)
        vrmod_pouch_lefthandwep_enable:SetText("vrmod_pouch_lefthandwep_enable")
        vrmod_pouch_lefthandwep_enable:SetConVar("vrmod_pouch_lefthandwep_enable")
        vrmod_pouch_lefthandwep_enable:SizeToContents()
        -- vrmod_pouch_weapon_1からvrmod_pouch_weapon_5を操作するメニュー項目の追加
        for i = 1, 5 do
            local weapon_textentry = vgui.Create("DTextEntry", MenuTab12)
            weapon_textentry:SetPos(20, 160 + (i - 1) * 30)
            weapon_textentry:SetSize(370, 25)
            weapon_textentry:SetText("Weapon Slot " .. i)
            weapon_textentry:SetConVar("vrmod_pouch_weapon_" .. i)
        end
    end
)
--------[vrmod_holstermenu.txt]End--------