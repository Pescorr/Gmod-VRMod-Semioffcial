--[[
    Module 16: VR Ragdoll Grab — Phase 1 Server
    - vrmod_pickupをprop_ragdoll対象時にブロック → vrphysgunに委ねる
    - NPC→ragdoll即時変換（grip時にNPCをragdoll化）
    - ragdoll生成後にクライアントへ通知 → physgun再トリガー

    Phase 1: 既存physgunフローの自動化テスト用。
    新規ファイルのみ、既存ファイル変更なし。
]]

if CLIENT then return end

g_VR = g_VR or {}
vrmod = vrmod or {}

-- ============================================================================
-- ConVars
-- ============================================================================

local enableCvar = CreateConVar(
    "vrmod_unoff_ragdoll_grab_enable", "1",
    FCVAR_REPLICATED + FCVAR_ARCHIVE,
    "Enable VR ragdoll grab (blocks vrmod_pickup for ragdolls)", 0, 1
)

-- ============================================================================
-- Network
-- ============================================================================

util.AddNetworkString("vrmod_ragdoll_grab_ragdollize") -- C→S: NPC ragdoll化リクエスト
util.AddNetworkString("vrmod_ragdoll_grab_created")    -- S→C: ragdoll生成完了通知

-- ============================================================================
-- vrmod_pickup ブロック（prop_ragdoll対象時のみ）
-- ============================================================================

-- VRMod_Pickup hook: vrmod_pickup.lua:196 で呼ばれる
-- return false でそのエンティティのpickupをキャンセル
-- vrphysgunの VRPhysgun_CanPickup_* は意図的にブロックしない
hook.Add("VRMod_Pickup", "VRMod_RagdollGrab_BlockPickup", function(ply, ent)
    if not enableCvar:GetBool() then return end
    if IsValid(ent) and ent:GetClass() == "prop_ragdoll" then
        return false
    end
end)

-- ============================================================================
-- NPC → Ragdoll 即時変換
-- ============================================================================

--- NPCからprop_ragdollを生成し、NPCを削除する
--- @param npc Entity NPC entity
--- @return Entity|nil 生成されたragdoll
local function RagdollizeNPC(npc)
    if not IsValid(npc) then return nil end

    local ragdoll = ents.Create("prop_ragdoll")
    if not IsValid(ragdoll) then return nil end

    ragdoll:SetModel(npc:GetModel())
    ragdoll:SetSkin(npc:GetSkin() or 0)
    ragdoll:SetPos(npc:GetPos())
    ragdoll:SetAngles(npc:GetAngles())

    -- ボディグループコピー
    for i = 0, (npc:GetNumBodyGroups() or 1) - 1 do
        ragdoll:SetBodygroup(i, npc:GetBodygroup(i))
    end

    ragdoll:Spawn()
    ragdoll:Activate()

    -- NPCのボーン姿勢をragdollにコピー（ポーズ再現）
    for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
        local phys = ragdoll:GetPhysicsObjectNum(i)
        if IsValid(phys) then
            local boneId = ragdoll:TranslatePhysBoneToBone(i)
            if boneId and boneId >= 0 then
                local pos, ang = npc:GetBonePosition(boneId)
                if pos and pos ~= npc:GetPos() then
                    phys:SetPos(pos)
                    phys:SetAngles(ang)
                    phys:Wake()
                end
            end
        end
    end

    -- Phase 1: NPCを即削除（Phase 2でスタン→温存に変更予定）
    npc:Remove()

    return ragdoll
end

-- ============================================================================
-- Net Receive: Ragdollize リクエスト
-- ============================================================================

-- レート制限付き受信（利用可能ならvrmod.NetReceiveLimited使用）
local netReceive = (vrmod.NetReceiveLimited)
    or function(name, _, _, fn) net.Receive(name, fn) end

netReceive("vrmod_ragdoll_grab_ragdollize", 5, 200, function(len, ply)
    if not IsValid(ply) then return end
    if not enableCvar:GetBool() then return end

    local steamid = ply:SteamID()
    if not g_VR[steamid] then return end

    local npcEnt = net.ReadEntity()
    local isLeft = net.ReadBool()

    -- バリデーション
    if not IsValid(npcEnt) then return end
    if not npcEnt:IsNPC() then return end

    -- NPC → ragdoll 変換
    local ragdoll = RagdollizeNPC(npcEnt)
    if not IsValid(ragdoll) then return end

    -- クライアントに通知: 生成されたragdoll + 手の左右
    net.Start("vrmod_ragdoll_grab_created")
    net.WriteEntity(ragdoll)
    net.WriteBool(isLeft)
    net.Send(ply)
end)

-- ============================================================================
-- Cleanup
-- ============================================================================

hook.Add("VRMod_Exit", "VRMod_RagdollGrab_Exit", function(ply)
    -- Phase 2: grab state cleanup
end)

hook.Add("PlayerDisconnected", "VRMod_RagdollGrab_Disconnect", function(ply)
    -- Phase 2: grab state cleanup
end)

-- ============================================================================

print("[VRMod] Module 16: Ragdoll Grab (Phase 1) loaded (SV)")
