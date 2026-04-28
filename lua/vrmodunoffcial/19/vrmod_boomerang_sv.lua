if CLIENT then return end

print("[Boomerang] Server module initialized")

util.AddNetworkString("vrmod_boomerang_throw")
util.AddNetworkString("vrmod_boomerang_pickup")

local convarEnabled    = CreateClientConVar("vrmod_boomerang_enabled",    1,    true, false)
local convarReturnTime = CreateClientConVar("vrmod_boomerang_returntime", 2.0,  true,  false)
local convarMaxDist    = CreateClientConVar("vrmod_boomerang_maxdist",    15,   true,  false)
local convarBaseForce  = CreateClientConVar("vrmod_boomerang_baseforce",  30,   true,  false)
local convarMaxForce   = CreateClientConVar("vrmod_boomerang_maxforce",   120,  true,  false)
local convarPickupDist = CreateClientConVar("vrmod_boomerang_pickupdist", 1.5,  true,  false)

local function CleanupBoomerang(ent)
    if not IsValid(ent) then return end
    ent.boomerangData = nil
    ent:SetNetworkedBool("BoomerangActive", false)
    local hookName = "BoomerangThink_" .. tostring(ent):gsub("%D+", "")
    hook.Remove(hookName, "Think")
end

local function BoomerangThinkWrapper(ent)
    if not IsValid(ent) then
        CleanupBoomerang(ent)
        return
    end
    
    local data = ent.boomerangData
    if not data or not IsValid(data.ply) then
        CleanupBoomerang(ent)
        return
    end
    
    local ply = data.ply
    if not ply:Alive() then
        CleanupBoomerang(ent)
        return
    end
    
    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then
        CleanupBoomerang(ent)
        return
    end
    
    local plyPos = ply:GetPos()
    local entPos = ent:GetPos()
    local dist = (plyPos - entPos):Length()
    
    if dist > data.maxDist * 2 then
        CleanupBoomerang(ent)
        return
    end
    
    local elapsed = CurTime() - data.throwTime
    
    if not data.returnStarted then
        if elapsed >= data.returnTime or dist >= data.maxDist then
            data.returnStarted = true
        else
            return
        end
    end
    
    local dir = (plyPos - entPos):GetNormalized()
    local distRatio = math.Clamp(dist / data.maxDist, 0, 1)
    local timeElapsed = math.Clamp((elapsed - data.returnTime) / data.returnTime, 0, 1)
    local forceRatio = distRatio * 0.5 + timeElapsed * 0.5
    local force = Lerp(forceRatio, data.baseForce, data.maxForce)
    
    phys:AddForce(dir * force, entPos)
    phys:SetAngularDamping(0.95)
    
    if dist <= data.pickupDist then
        CleanupBoomerang(ent)
        
        net.Start("vrmod_boomerang_pickup")
            net.WriteEntity(ent)
        net.Send(ply)
    end
end

net.Receive("vrmod_boomerang_throw", function(len, ply)
    if not IsValid(ply) then return end
    
    local ent = net.ReadEntity()
    local handVel = net.ReadVector()
    
    if not IsValid(ent) then return end
    
    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then return end
    
    if ent:IsPlayer() or ent:IsNPC() then return end
    
    local enabled = convarEnabled:GetInt()
    if enabled ~= 1 then return end
    
    local steamid = ply:SteamID64()
    local heldData = g_VR[steamid] and g_VR[steamid].heldItems[1]
    if heldData and IsValid(heldData.ent) and heldData.ent == ent then
        return
    end
    
    ent:SetNetworkedBool("BoomerangActive", true)
    
    ent.boomerangData = {
        ply           = ply,
        throwTime     = CurTime(),
        handVel       = handVel,
        returnStarted = false,
        maxDist       = convarMaxDist:GetFloat(),
        returnTime    = convarReturnTime:GetFloat(),
        baseForce     = convarBaseForce:GetFloat(),
        maxForce      = convarMaxForce:GetFloat(),
        pickupDist    = convarPickupDist:GetFloat()
    }
    
    local hookName = "BoomerangThink_" .. tostring(ent):gsub("%D+", "")
    hook.Add("Think", hookName, function()
        BoomerangThinkWrapper(ent)
    end)
end)

hook.Add("PlayerDisconnected", "VRModBoomerang_Cleanup", function(ply)
    local steamid = ply:SteamID64()
    for _, ent in ipairs(ents.FindByClass("*")) do
        if ent.boomerangData and ent.boomerangData.ply == ply then
            CleanupBoomerang(ent)
        end
    end
end)

hook.Add("PlayerDeath", "VRModBoomerang_CleanupDeath", function(victim)
    for _, ent in ipairs(ents.FindByClass("*")) do
        if ent.boomerangData and ent.boomerangData.ply == victim then
            CleanupBoomerang(ent)
        end
    end
end)
