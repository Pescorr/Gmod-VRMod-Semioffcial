-- ASTW2 VRMod Fix
-- このスクリプトはVRModでASTW2ベースの武器使用時のViewmodel表示問題を修正します
if CLIENT then
    -- VRModが存在するか確認するヘルパー関数
    local function IsVRModActive()
        return vrmod and vrmod.IsPlayerInVR and vrmod.IsPlayerInVR(LocalPlayer())
    end

    -- ASTW2ベースの武器かどうかを確認
    local function IsASTW2Weapon(wep)
        return wep and wep.ASTWTWO
    end

    -- オリジナルの関数を保存
    local original_CalcViewModelView = CalcViewModelView
    local original_PreDrawViewModel = PreDrawViewModel
    -- Viewmodelを透明にするためのマテリアル
    local invisible_material = CreateMaterial(
        "ASTW2_VRMod_Invisible",
        "VertexLitGeneric",
        {
            ["$basetexture"] = "models/debug/debugwhite",
            ["$alpha"] = 1,
            ["$translucent"] = 1,
            ["$vertexalpha"] = 1,
            ["$vertexcolor"] = 1
        }
    )

    -- Viewmodelのレンダリングを制御するフック
    hook.Add(
        "PreDrawViewModel",
        "ASTW2_VRMod_HideViewModel",
        function(vm, ply, weapon)
            -- VRModがアクティブで、ASTW2ベースの武器を持っている場合
            if IsVRModActive() and IsASTW2Weapon(weapon) then
                -- Viewmodelを透明にする
                render.SetColorModulation(0, 0, 0)
                render.SetBlend(0) -- 完全に透明にする
                render.MaterialOverride(invisible_material)
                -- 他のフックが呼ばれないようにtrueを返す

                return true
            end
        end
    )

    -- 後処理のためのフック
    hook.Add(
        "PostDrawViewModel",
        "ASTW2_VRMod_ResetViewModel",
        function(vm, ply, weapon)
            if IsVRModActive() and IsASTW2Weapon(weapon) then
                -- マテリアルとブレンドをリセット
                render.MaterialOverride(nil)
                render.SetBlend(1)
            end
        end
    )

    -- 既存のViewModelDrawn関数を拡張するためのフック
    hook.Add(
        "Think",
        "ASTW2_VRMod_SetupWeapons",
        function()
            local ply = LocalPlayer()
            if not IsValid(ply) then return end
            local wep = ply:GetActiveWeapon()
            if IsValid(wep) and IsASTW2Weapon(wep) and wep.ViewModelDrawn then
                -- 元のViewModelDrawn関数を保存
                if not wep._originalViewModelDrawn then
                    wep._originalViewModelDrawn = wep.ViewModelDrawn
                    -- 新しいViewModelDrawn関数を設定
                    wep.ViewModelDrawn = function(self, ...)
                        if IsVRModActive() then
                            return
                        else -- VRModがアクティブな場合、何もしない
                            return self._originalViewModelDrawn(self, ...)
                        end
                    end
                    -- 非VRの場合は元の関数を呼び出す
                end
            end
        end
    )

    -- GMODのビューモデルポジション計算をオーバーライド
    hook.Add(
        "CalcViewModelView",
        "ASTW2_VRMod_AdjustViewModel",
        function(weapon, vm, oldPos, oldAng, pos, ang)
            if IsVRModActive() and IsASTW2Weapon(weapon) then return pos + Vector(0, 0, 0), ang end -- VRModアクティブ時はViewModel位置を遠くに移動して見えないようにする
        end
    )

    -- プレイヤーがVRモードから出入りした際に武器を再度装備し直す処理
    local wasInVR = false
    hook.Add(
        "Think",
        "ASTW2_VRMod_WeaponReset",
        function()
            local ply = LocalPlayer()
            if not IsValid(ply) then return end
            local isInVR = IsVRModActive()
            if wasInVR ~= isInVR then
                wasInVR = isInVR
                -- プレイヤーの武器を取得
                local wep = ply:GetActiveWeapon()
                if IsValid(wep) and IsASTW2Weapon(wep) then
                    -- VRモード切替時に武器の表示を更新
                    timer.Simple(
                        0.1,
                        function()
                            if IsValid(wep) then
                                wep:Deploy()
                            end
                        end
                    )
                end
            end
        end
    )

    -- コンソールコマンドでデバッグを可能にする
    concommand.Add(
        "astw2_vrmod_debug",
        function()
            local ply = LocalPlayer()
            local wep = ply:GetActiveWeapon()
            print("VRMod Active:", IsVRModActive())
            print("Current Weapon:", wep)
            print("Is ASTW2:", IsASTW2Weapon(wep))
            if IsValid(wep) then
                print("Weapon Class:", wep:GetClass())
                print("Weapon Model:", wep:GetModel())
                print("ViewModel:", ply:GetViewModel():GetModel())
            end
        end
    )
end