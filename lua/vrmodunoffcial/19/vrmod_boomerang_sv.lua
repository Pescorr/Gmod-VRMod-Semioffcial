if CLIENT then return end

vrmod = vrmod or {}
vrmod.boomerang = vrmod.boomerang or {}
local B = vrmod.boomerang

B.active = B.active or {}
B.convarCache = B.convarCache or {}

-- ConVar definitions
B.cvarEnabled    = CreateConVar("vrmod_unoff_boomerang_enabled",    "1",   FCVAR_ARCHIVE, "Enable boomerang return effect")
B.cvarFlightTime = CreateConVar("vrmod_unoff_boomerang_flights",    "3",   FCVAR_ARCHIVE, "Flight time before return")
B.cvarArcHeight  = CreateConVar("vrmod_unoff_boomerang_arcm",       "3",   FCVAR_ARCHIVE, "Arc height in meters")
B.cvarReturnDist = CreateConVar("vrmod_unoff_boomerang_returndist", "1.5", FCVAR_ARCHIVE, "Distance to trigger pickup")

local function refreshConvars()
    B.convarCache.enabled    = B.cvarEnabled:GetInt()
    B.convarCache.flights    = math.max(0.5, B.cvarFlightTime:GetFloat())
    B.convarCache.arcm       = math.max(0, B.cvarArcHeight:GetFloat())
    B.convarCache.returndist = math.max(0.3, B.cvarReturnDist:GetFloat())
end
refreshConvars()
timer.Create("VRModBoomerang_ConvarRefresh", 2, 0, refreshConvars)

-- Network string for triggering client-side pickup
util.AddNetworkString("vrmod_boomerang_pickup")

-- Detect left hand from entity's pickup metadata
local function wasLeftHand(ent)
    if not IsValid(ent) then return false end
    return ent.vrmod_pickup_info and ent.vrmod_pickup_info.left == true
end

-- VRMod_Drop hook - detect left-hand drops
hook.Add("VRMod_Drop", "vrmod_unoff_boomerang_drop", function(ply, ent)
    if B.convarCache.enabled ~= 1 then return end
    if not IsValid(ent) then return end
    if not IsValid(ply) then return end

    if not wasLeftHand(ent) then return end

    -- Must have valid physics object for force manipulation
    local phys = ent:GetPhysicsObject()
    if not IsValid(phys) then return end

    B.active[ent] = {
        ply       = ply,
        throwPos  = ent:GetPos(),
        startTime = CurTime(),
    }

    pcall(function() ent:EmitSound("vrmod/boomerang/throw.wav", 50, math.Rand(85, 115)) end)
end)

-- Process single boomerang. Returns true if should be removed from active.
local function processBoomerang(ent, data)
    local ply = data.ply

    if not IsValid(ply) or not ply:Alive() then
        if IsValid(ent) then ent.vrmod_boomerang_active = false end
        return true
    end

    if not IsValid(ent) then
        return true
    end

    local now = CurTime()
    local elapsed = now - data.startTime
    local flightTime = B.convarCache.flights
    local phys = ent:GetPhysicsObject()
    local entPos = ent:GetPos()

    if elapsed >= flightTime then
        -- === RETURN PHASE ===
        local plyPos = ply:GetPos()
        local dist = (plyPos - entPos):Length()

        if dist <= B.convarCache.returndist then
            -- Close enough - trigger client pickup
            ent.vrmod_boomerang_active = false

            pcall(function()
                net.Start("vrmod_boomerang_pickup")
                    net.WriteEntity(ply)
                    net.WriteEntity(ent)
                net.Send(ply)
            end)

            return true
        else
            if IsValid(phys) then
                local dir = (plyPos - entPos):GetNormalized()
                local accel = math.min(dist * 15, 600)
                pcall(function()
                    phys:AddForce(dir * accel, entPos)
                    phys:SetAngularDamping(0.9)
                end)
            end
        end

        return false
    else
        -- === OUTBOUND/ARC PHASE ===
        if IsValid(phys) then
            local t = elapsed / flightTime
            local plyPos = ply:GetPos()
            local startPos = data.throwPos

            -- Arc target: linear horizontal + sine arc vertical
            local targetZ = startPos.z + (plyPos.z - startPos.z) * t + math.sin(math.pi * t) * B.convarCache.arcm
            local targetPos = Vector(
                startPos.x + (plyPos.x - startPos.x) * t,
                startPos.y + (plyPos.y - startPos.y) * t,
                targetZ
            )

            local correctionDir = (targetPos - entPos):GetNormalized()
            pcall(function()
                phys:AddForce(correctionDir * 30, entPos)
                phys:SetAngularDamping(0.9)
            end)
        end

        return false
    end
end

-- Shared Think hook
hook.Add("Think", "vrmod_unoff_boomerang_think", function()
    local toRemove = {}

    for ent, data in pairs(B.active) do
        local ok, shouldRemove = pcall(processBoomerang, ent, data)
        if not ok then
            -- Error occurred - cleanup to prevent infinite error loop
            print("[Boomerang] ERROR in processBoomerang: " .. tostring(shouldRemove))
            if IsValid(ent) then ent.vrmod_boomerang_active = false end
            table.insert(toRemove, ent)
        elseif shouldRemove then
            table.insert(toRemove, ent)
        end
    end

    for _, ent in ipairs(toRemove) do
        B.active[ent] = nil
    end
end)

-- Cleanup hooks
hook.Add("PlayerDisconnected", "vrmod_unoff_boomerang_disconnect", function(ply)
    for ent, data in pairs(B.active) do
        if data.ply == ply then
            if IsValid(ent) then ent.vrmod_boomerang_active = false end
            B.active[ent] = nil
        end
    end
end)

hook.Add("PlayerDeath", "vrmod_unoff_boomerang_death", function(victim)
    for ent, data in pairs(B.active) do
        if data.ply == victim then
            if IsValid(ent) then ent.vrmod_boomerang_active = false end
            B.active[ent] = nil
        end
    end
end)

print("[Boomerang SV] Module loaded - VRMod_Drop hook active")
