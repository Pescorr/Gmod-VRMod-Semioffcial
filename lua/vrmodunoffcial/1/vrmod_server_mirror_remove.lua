-- func_reflective_glass エンティティを削除するためのコマンドを追加
concommand.Add(
    "remove_reflective_glass",
    function(ply, cmd, args)
        -- サーバーコンソールからの実行を許可
        if not IsValid(ply) then
            local count = 0
            -- すべての反射ガラスを検索して削除
            for _, ent in ipairs(ents.FindByClass("func_reflective_glass")) do
                if IsValid(ent) then
                    ent:Remove()
                    count = count + 1
                end
            end
            print(string.format("Removed %d reflective glass entities", count))
            return
        end

        -- プレイヤーの権限チェック
        if not ply:IsAdmin() then
            ply:ChatPrint("You must be an admin to use this command!")
            return 
        end

        local count = 0
        -- すべての反射ガラスを検索して削除
        for _, ent in ipairs(ents.FindByClass("func_reflective_glass")) do
            if IsValid(ent) then
                ent:Remove()
                count = count + 1
            end
        end

        -- 結果を通知
        ply:ChatPrint(string.format("Removed %d reflective glass entities", count))
    end
)