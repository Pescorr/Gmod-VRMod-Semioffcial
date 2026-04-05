--[[
    Module 16: VR Ragdoll Grab — Phase 1 Client
    - ragdoll + NPC 検出（極細・短距離トレース）
    - NPC検出時: gripでragdoll化リクエスト送信
    - ragdoll生成通知受信 → physgun再トリガー（自動掴み）
    - hit位置にインジケーター表示

    Phase 1: 既存physgunフローの自動化テスト用。
]]

if SERVER then return end

g_VR = g_VR or {}
vrmod = vrmod or {}

-- ============================================================================
-- ConVars
-- ============================================================================

local enableCvar -- サーバーで作成済み（FCVAR_REPLICATED）、遅延取得

local GRAB_RANGE = 100 -- トレース距離（units）、physgunより大幅に短い

-- ============================================================================
-- State
-- ============================================================================

-- 各手の検出状態: { entity, hitPos, isNPC } or nil
local detected = { left = nil, right = nil }
local HANDS = { "left", "right" }

-- physgun再トリガー待ち状態
local pendingRetrigger = { left = false, right = false }

-- ============================================================================
-- Materials（遅延初期化）
-- ============================================================================

local mat_glow

-- ============================================================================
-- Detection: 毎フレーム、各手から極細トレースでragdoll/NPC検出
-- ============================================================================

hook.Add("PostDrawTranslucentRenderables", "VRMod_RagdollGrab_Indicator", function(depth, sky)
    if depth or sky then return end
    if not g_VR.active then
        detected.left = nil
        detected.right = nil
        return
    end

    -- ConVar遅延取得
    if not enableCvar then
        enableCvar = GetConVar("vrmod_unoff_ragdoll_grab_enable")
    end
    if enableCvar and not enableCvar:GetBool() then
        detected.left = nil
        detected.right = nil
        return
    end

    if not mat_glow then
        mat_glow = Material("sprites/light_glow02_add")
    end

    local ply = LocalPlayer()

    for _, hand in ipairs(HANDS) do
        local pose = g_VR.tracking["pose_" .. hand .. "hand"]
        if not pose then
            detected[hand] = nil
            continue
        end

        local startPos = pose.pos
        local endPos = startPos + pose.ang:Forward() * GRAB_RANGE

        local tr = util.TraceLine({
            start = startPos,
            endpos = endPos,
            filter = ply
        })

        if tr.Hit and IsValid(tr.Entity) then
            local ent = tr.Entity
            local isRagdoll = (ent:GetClass() == "prop_ragdoll")
            local isNPC = ent:IsNPC()

            if isRagdoll or isNPC then
                detected[hand] = {
                    entity = ent,
                    hitPos = tr.HitPos,
                    isNPC = isNPC
                }

                -- インジケーター描画
                render.SetMaterial(mat_glow)
                if isNPC then
                    -- NPC: 赤系（ragdoll化対象）
                    render.DrawSprite(tr.HitPos, 5, 5, Color(255, 80, 80, 200))
                else
                    -- ragdoll: オレンジ（physgun掴み対象）
                    render.DrawSprite(tr.HitPos, 4, 4, Color(255, 150, 50, 180))
                end
            else
                detected[hand] = nil
            end
        else
            detected[hand] = nil
        end
    end
end)

-- ============================================================================
-- Input: gripボタンでNPC ragdoll化リクエスト
-- ============================================================================

hook.Add("VRMod_Input", "VRMod_RagdollGrab_Input", function(action, pressed)
    if not pressed then return end
    if not g_VR.active then return end

    -- ConVar遅延取得
    if not enableCvar then
        enableCvar = GetConVar("vrmod_unoff_ragdoll_grab_enable")
    end
    if enableCvar and not enableCvar:GetBool() then return end

    -- gripボタン判定
    local isLeft
    if action == "boolean_left_pickup" then
        isLeft = true
    elseif action == "boolean_right_pickup" then
        isLeft = false
    else
        return
    end

    local hand = isLeft and "left" or "right"
    local d = detected[hand]
    if not d or not IsValid(d.entity) then return end

    -- NPC検出時: ragdoll化リクエスト送信
    if d.isNPC then
        net.Start("vrmod_ragdoll_grab_ragdollize")
        net.WriteEntity(d.entity)
        net.WriteBool(isLeft)
        net.SendToServer()
    end
    -- prop_ragdoll検出時: physgunが同フレームで処理（介入不要）
end)

-- ============================================================================
-- Net Receive: ragdoll生成通知 → physgun再トリガー
-- ============================================================================

net.Receive("vrmod_ragdoll_grab_created", function()
    local ragdoll = net.ReadEntity()
    local isLeft = net.ReadBool()
    local prefix = isLeft and "left" or "right"

    if not g_VR.active then return end

    -- ragdollがクライアントに到達するまで少し待ってからphysgun再トリガー
    -- timer.Simple(0) = 次フレーム、ネットワーキング遅延を考慮して2段階
    pendingRetrigger[prefix] = true

    timer.Simple(0, function()
        if not g_VR.active then
            pendingRetrigger[prefix] = false
            return
        end

        -- physgunのpickupアクションを再送信
        -- vrmod.PhysgunAction_prefix(false) = pickup（dropではない）
        local fn = vrmod["PhysgunAction_" .. prefix]
        if fn then
            fn(false)
        end

        -- まだentityが有効でなければもう1フレーム待つ
        if not IsValid(ragdoll) then
            timer.Simple(0, function()
                if not g_VR.active then
                    pendingRetrigger[prefix] = false
                    return
                end
                if fn then
                    fn(false)
                end
                pendingRetrigger[prefix] = false
            end)
        else
            pendingRetrigger[prefix] = false
        end
    end)
end)

-- ============================================================================
-- Public API
-- ============================================================================

vrmod.RagdollGrab = vrmod.RagdollGrab or {}

--- 指定した手がragdoll/NPCを検出しているか
--- @param hand string "left" or "right"
--- @return Entity|nil
function vrmod.RagdollGrab.GetDetected(hand)
    local d = detected[hand]
    if d and IsValid(d.entity) then
        return d.entity
    end
    return nil
end

--- 指定した手のトレースhit位置
--- @param hand string "left" or "right"
--- @return Vector|nil
function vrmod.RagdollGrab.GetHitPos(hand)
    local d = detected[hand]
    if d and IsValid(d.entity) then
        return d.hitPos
    end
    return nil
end

--- 指定した手の検出対象がNPCか
--- @param hand string "left" or "right"
--- @return boolean
function vrmod.RagdollGrab.IsNPC(hand)
    local d = detected[hand]
    return d and d.isNPC or false
end

-- ============================================================================

print("[VRMod] Module 16: Ragdoll Grab (Phase 1) loaded (CL)")
