
-- 指定されたプレイヤーが持っているアイテムを落とす関数
function DropItemsHeldByPlayer(player, leftHand)
    local steamid = player:SteamID()
    if g_VR[steamid] then
        local heldItems = g_VR[steamid].heldItems
        if leftHand then
            -- 左手に持っているアイテムを落とす
            if heldItems[1] then
                player:DropObject(heldItems[1])
                heldItems[1] = nil
            end
        else
            -- 右手に持っているアイテムを落とす
            if heldItems[2] then
                player:DropObject(heldItems[2])
                heldItems[2] = nil
            end
        end
    end
end



-- プレイヤーがVRを退出する際に呼び出される関数
local function CleanupPlayerVRData(steamid)
    -- 指定されたSteamIDを持つプレイヤーのデータをg_VRテーブルから削除
    if g_VR[steamid] ~= nil then
        g_VR[steamid] = nil

        -- プレイヤーを取得
        local ply = player.GetBySteamID(steamid)
        if IsValid(ply) then
            -- ビューオフセットを元に戻す
            ply:SetCurrentViewOffset(ply.originalViewOffset)
            ply:SetViewOffset(ply.originalViewOffset)

            -- 必要な場合はその他のクリーンアップ処理をここに追加
        end

        -- 退出メッセージを全プレイヤーに送信
        net.Start("vrutil_net_exit")
        net.WriteString(steamid)
        net.Broadcast()

        -- VRMod_Exitフックを実行
        hook.Run("VRMod_Exit", ply)
    end
end

-- ネットワークメッセージ受信時の処理
net.Receive("vrutil_net_exit", function(len)
    local steamid = net.ReadString()
    CleanupPlayerVRData(steamid)
end)
