local enginestat = 0.0
-- コンソールコマンド：プレイヤーが乗っているLVS車両でStartEngine関数を実行
concommand.Add(
    "lvs_toggle_engine",
    function(ply, cmd, args)
        local vehicle = ply:lvsGetVehicle()
        if not IsValid(vehicle) then return end --  print("プレイヤーがLVS車両に乗っていません")
        if vehicle.LFS then return end
        if vehicle.StartEngine then
            vehicle:ToggleEngine()
            enginestat = 0.0
            LocalPlayer():ConCommand("vr_dummy_menu_toggle 1")
        end
    end
)

-- コンソールコマンド：プレイヤーが乗っているLVS車両でStartEngine関数を実行
concommand.Add(
    "lvs_exit_ply",
    function(ply, cmd, args)
        local vehicle = ply:lvsGetVehicle()
        if not IsValid(vehicle) then return end -- print("プレイヤーがLVS車両に乗っていません")
        enginestat = 0.0
        ply:ExitVehicle()
    end
)

-- コンソールコマンド：プレイヤーが乗っているLVS車両でStartEngine関数を実行
concommand.Add(
    "lvs_throttle",
    function(ply, cmd, args)
        local vehicle = ply:lvsGetVehicle()
        if not IsValid(vehicle) then return end --  print("プレイヤーがLVS車両に乗っていません")
        if vehicle.LFS then return end
        enginestat = enginestat + 0.1
        vehicle:SetThrottle(enginestat)
    end
)

-- コンソールコマンド：プレイヤーが乗っているLVS車両でStartEngine関数を実行
concommand.Add(
    "lvs_brake",
    function(ply, cmd, args)
        local vehicle = ply:lvsGetVehicle()
        if not IsValid(vehicle) then return end --print("プレイヤーがLVS車両に乗っていません")
        if vehicle.LFS then return end
        enginestat = enginestat - 0.1
        vehicle:SetThrottle(enginestat)
    end
)

--------
--------
if SERVER then return end
local open = false
-- ConVarを作成
CreateClientConVar("vr_dummy_menu_toggle", 0, true, FCVAR_ARCHIVE)
function VRUtilDummyMenuOpen()
    if open then return end
    open = true
    -- 空白のメニューをMode = 2で開く
    VRUtilMenuOpen(
        "dummymenu",
        512,
        512,
        nil,
        2,
        Vector(13, 6, 10.5),
        Angle(0, -90, 90),
        0.03,
        true,
        function()
            -- Mode = 2
            open = false
            RunConsoleCommand("vr_dummy_menu_toggle", "0") -- メニューを閉じた時にConVarをリセット
        end
    )

    -- メニューのレンダリングフックを追加
    hook.Add(
        "PreRender",
        "vrutil_hook_renderdummymenu",
        function()
            VRUtilMenuRenderStart("dummymenu")
            -- 何もない大きなボタンを描画
            local buttonWidth, buttonHeight = 256, 256
            draw.RoundedBox(8, 0, 0, buttonWidth, buttonHeight, Color(0, 0, 0, 0))
            VRUtilMenuRenderEnd()
        end
    )
end

function VRUtilDummyMenuClose()
    VRUtilMenuClose("dummymenu")
    hook.Remove("PreRender", "vrutil_hook_renderdummymenu")
    open = false
end

-- ConVarの変更を監視
cvars.AddChangeCallback(
    "vr_dummy_menu_toggle",
    function(name, oldvalue, newvalue)
        if newvalue == "1" then
            VRUtilDummyMenuOpen()
        else
            VRUtilDummyMenuClose()
        end
    end, "VRDummyMenuToggle"
)

--
-- Garry's Mod VRでLVS車両を操作するためのLuaスクリプト
-- VRMod_Input フックを新規作成
hook.Add(
    "VRMod_Input",
    "vrmod_LVSconcommand",
    function(action, pressed)
        if action == "boolean_reload" then
            if pressed then
                LocalPlayer():ConCommand("lvs_toggle_engine")
            end

            return
        end

        -- VRで退出アクションが検出された場合、車両を退出
        if action == "boolean_use" then
            if pressed then
                LocalPlayer():ConCommand("lvs_exit_ply")
                LocalPlayer():ConCommand("vr_dummy_menu_toggle 0")
            end

            return
        end
    end
)
-- 他のアクションに対する処理はここに追加...
-- ここに必要に応じて他のVRMod関連のコードを追加...