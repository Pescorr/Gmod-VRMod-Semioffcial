-- if SERVER then
--     util.AddNetworkString("VRRagdoll_Spawn")
--     util.AddNetworkString("VRRagdoll_Remove")

--     local RAGDOLL_UPDATE_RATE = 0.01
--     local FORCE_MULTIPLIER = 50
    
--     -- Store active VR ragdolls
--     local vrRagdolls = {}

--     -- Get VR character bone information
--     local function GetVRBoneInfo(ply)
--         local steamid = ply:SteamID()
        
--         -- Verify VR is active for this player
--         if not g_VR[steamid] then return nil end
        
--         -- Get character info directly from the VRMod system
--         local characterInfo = g_VR[steamid].characterInfo
--         if not characterInfo then return nil end
        
--         -- Make sure we have bone info
--         if not characterInfo.boneinfo then return nil end
        
--         return characterInfo
--     end

--     -- Primary function for updating ragdoll pose
--     local function UpdateRagdollPose(ragdoll, ply)
--         if not IsValid(ragdoll) or not IsValid(ply) then return end
        
--         local charInfo = GetVRBoneInfo(ply)
--         if not charInfo then return end

--         -- Iterate through all physics bones
--         for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
--             local phys = ragdoll:GetPhysicsObjectNum(i)
--             if not IsValid(phys) then continue end

--             local boneID = ragdoll:TranslatePhysBoneToBone(i)
--             if not boneID then continue end

--             -- Get bone info from VR character system
--             local boneInfo = charInfo.boneinfo[boneID]
--             if not boneInfo or not boneInfo.pos or not boneInfo.ang then continue end

--             -- Get target position and angles from VR character
--             local targetPos = boneInfo.pos
--             local targetAng = boneInfo.ang

--             -- Current physics object state
--             local currentPos = phys:GetPos()
--             local currentAng = phys:GetAngles()

--             -- Apply forces to match VR character pose
--             local deltaPos = targetPos - currentPos
--             local force = deltaPos * FORCE_MULTIPLIER * phys:GetMass()
--             phys:ApplyForceCenter(force)

--             -- Apply angular forces
--             local deltaAng = (targetAng - currentAng)
--             deltaAng:Normalize()
--             local torque = deltaAng * FORCE_MULTIPLIER * phys:GetMass()
--             phys:ApplyTorqueCenter(torque)

--             -- Add damping for smoother movement
--             phys:AddVelocity(-phys:GetVelocity() * 0.1)
--             phys:AddAngleVelocity(-phys:GetAngleVelocity() * 0.1)
--         end
--     end

--     -- Create VR ragdoll
--     local function CreateVRRagdoll(ply)
--         -- Verify player and VR state
--         if not IsValid(ply) or not g_VR[ply:SteamID()] then return end
        
--         -- Clean up existing ragdoll
--         if vrRagdolls[ply:SteamID()] then
--             vrRagdolls[ply:SteamID()]:Remove()
--         end
        
--         -- Create new ragdoll
--         local ragdoll = ents.Create("prop_ragdoll")
--         ragdoll:SetModel(ply:GetModel())
--         ragdoll:SetPos(ply:GetPos())
--         ragdoll:SetAngles(ply:GetAngles())
--         ragdoll:Spawn()
--         ragdoll:Activate()

--         -- Set up physics objects
--         for i = 0, ragdoll:GetPhysicsObjectCount() - 1 do
--             local phys = ragdoll:GetPhysicsObjectNum(i)
--             if IsValid(phys) then
--                 phys:EnableGravity(false)
--                 phys:SetMass(1)
--                 phys:SetDamping(0.7, 0.7)
--             end
--         end

--         -- Store references
--         vrRagdolls[ply:SteamID()] = ragdoll
--         ragdoll.VRPlayer = ply

--         -- Create update timer
--         timer.Create("VRRagdoll_" .. ply:SteamID(), RAGDOLL_UPDATE_RATE, 0, function()
--             if IsValid(ragdoll) and IsValid(ply) then
--                 UpdateRagdollPose(ragdoll, ply)
--             else
--                 timer.Remove("VRRagdoll_" .. ply:SteamID())
--                 if IsValid(ragdoll) then
--                     ragdoll:Remove()
--                 end
--                 vrRagdolls[ply:SteamID()] = nil
--             end
--         end)

--         return ragdoll
--     end

--     -- Network message handlers
--     net.Receive("VRRagdoll_Spawn", function(len, ply)
--         if IsValid(ply) and g_VR[ply:SteamID()] then
--             CreateVRRagdoll(ply)
--         end
--     end)

--     net.Receive("VRRagdoll_Remove", function(len, ply)
--         if vrRagdolls[ply:SteamID()] then
--             vrRagdolls[ply:SteamID()]:Remove()
--             vrRagdolls[ply:SteamID()] = nil
--             timer.Remove("VRRagdoll_" .. ply:SteamID())
--         end
--     end)

--     -- Cleanup hooks
--     hook.Add("PlayerDisconnected", "VRRagdoll_Cleanup", function(ply)
--         if vrRagdolls[ply:SteamID()] then
--             vrRagdolls[ply:SteamID()]:Remove()
--             vrRagdolls[ply:SteamID()] = nil
--             timer.Remove("VRRagdoll_" .. ply:SteamID())
--         end
--     end)
-- end

-- if CLIENT then
--     -- Console commands
--     concommand.Add("vr_ragdoll_spawn", function(ply, cmd, args)
--         if g_VR.active then
--             net.Start("VRRagdoll_Spawn")
--             net.SendToServer()
--         end
--     end)

--     concommand.Add("vr_ragdoll_remove", function(ply, cmd, args)
--         net.Start("VRRagdoll_Remove")
--         net.SendToServer()
--     end)

--     -- VR exit cleanup
--     hook.Add("VRMod_Exit", "VRRagdoll_Exit", function(ply)
--         net.Start("VRRagdoll_Remove")
--         net.SendToServer()
--     end)
-- end