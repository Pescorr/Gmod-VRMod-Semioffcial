if CLIENT then return end
-- コンソールコマンド 'remove_reflective_glass' を追加して、func_reflective_glass エンティティを削除する
concommand.Add(
    "remove_reflective_glass",
    function(ply, cmd, args)
        -- 実行者が管理者か確認
        if not IsValid(ply) or ply:IsAdmin() then
            -- func_reflective_glass エンティティを検索して削除
            for _, ent in ipairs(ents.FindByClass("func_reflective_glass")) do
                ent:Remove()
            end

            -- 実行者がいる場合は、操作が成功したことを通知
            if IsValid(ply) then
                ply:PrintMessage(HUD_PRINTCONSOLE, "Removed all func_reflective_glass entities.")
            end
        else
            -- 実行者が管理者でない場合は、拒否メッセージを表示
            ply:PrintMessage(HUD_PRINTCONSOLE, "You must be an admin to use this command.")
        end
    end
)

