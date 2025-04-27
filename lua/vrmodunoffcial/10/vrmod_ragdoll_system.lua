-- -- VRMod Ragdoll System
-- -- This module allows VR movements to be applied to ragdolls in Garry's Mod
-- -- Inspired by the VRMod character system

-- if CLIENT then
--     g_VR = g_VR or {}
    
--     -- Main data structures
--     local ragdollSystems = {}
--     local activeRagdolls = {}
--     local zeroVec, zeroAng = Vector(), Angle()
    
--     -- Configuration
--     local config = {
--         updateRate = 0.01,   -- Update rate in seconds
--         maxDistance = 300,   -- Maximum distance to control a ragdoll
--         smoothingFactor = 0.4, -- Smoothing factor for movement (0-1)
--         debugMode = false    -- Enable debug visualization
--     }
    
--     -- Get convars
--     local convars = vrmod.GetConvars()
    
--     -- Recursively builds bone info table
--     local function BuildRagdollBoneInfo(ragdoll, boneId, infoTable, orderTable, notFirst)
--         local bones = notFirst and ragdoll:GetChildBones(boneId) or {boneId}
        
--         for _, boneIndex in pairs(bones) do
--             local boneName = ragdoll:GetBoneName(boneIndex)
--             local parentBoneId = ragdoll:GetBoneParent(boneIndex)
            
--             -- Get bone matrices
--             local parentMatrix = ragdoll:GetBoneMatrix(parentBoneId)
--             local boneMatrix = ragdoll:GetBoneMatrix(boneIndex)
            
--             if parentMatrix and boneMatrix then
--                 local parentPos, parentAng = parentMatrix:GetTranslation(), parentMatrix:GetAngles()
--                 local bonePos, boneAng = boneMatrix:GetTranslation(), boneMatrix:GetAngles()
                
--                 -- Calculate relative position and angle
--                 local relPos, relAng = WorldToLocal(bonePos, boneAng, parentPos, parentAng)
                
--                 -- Store bone info
--                 infoTable[boneIndex] = {
--                     name = boneName,
--                     pos = Vector(0, 0, 0),
--                     ang = Angle(0, 0, 0),
--                     parent = parentBoneId,
--                     relativePos = relPos,
--                     relativeAng = relAng,
--                     offsetAng = Angle(0, 0, 0),
--                     targetMatrix = nil
--                 }
                
--                 orderTable[#orderTable + 1] = boneIndex
--             end
--         end
        
--         -- Process child bones
--         for _, boneIndex in pairs(bones) do
--             BuildRagdollBoneInfo(ragdoll, boneIndex, infoTable, orderTable, true)
--         end
--     end
    
--     -- Maps bones between VR tracked points and ragdoll
--     local function MapBones(ragdoll)
--         local boneMap = {
--             head = ragdoll:LookupBone("ValveBiped.Bip01_Head1") or -1,
--             neck = ragdoll:LookupBone("ValveBiped.Bip01_Neck1") or -1,
--             spine = ragdoll:LookupBone("ValveBiped.Bip01_Spine") or -1,
--             spine1 = ragdoll:LookupBone("ValveBiped.Bip01_Spine1") or -1,
--             spine2 = ragdoll:LookupBone("ValveBiped.Bip01_Spine2") or -1,
--             spine4 = ragdoll:LookupBone("ValveBiped.Bip01_Spine4") or -1,
--             pelvis = ragdoll:LookupBone("ValveBiped.Bip01_Pelvis") or -1,
            
--             leftClavicle = ragdoll:LookupBone("ValveBiped.Bip01_L_Clavicle") or -1,
--             leftUpperArm = ragdoll:LookupBone("ValveBiped.Bip01_L_UpperArm") or -1,
--             leftForearm = ragdoll:LookupBone("ValveBiped.Bip01_L_Forearm") or -1,
--             leftHand = ragdoll:LookupBone("ValveBiped.Bip01_L_Hand") or -1,
            
--             rightClavicle = ragdoll:LookupBone("ValveBiped.Bip01_R_Clavicle") or -1,
--             rightUpperArm = ragdoll:LookupBone("ValveBiped.Bip01_R_UpperArm") or -1,
--             rightForearm = ragdoll:LookupBone("ValveBiped.Bip01_R_Forearm") or -1,
--             rightHand = ragdoll:LookupBone("ValveBiped.Bip01_R_Hand") or -1,
            
--             leftThigh = ragdoll:LookupBone("ValveBiped.Bip01_L_Thigh") or -1,
--             leftCalf = ragdoll:LookupBone("ValveBiped.Bip01_L_Calf") or -1,
--             leftFoot = ragdoll:LookupBone("ValveBiped.Bip01_L_Foot") or -1,
            
--             rightThigh = ragdoll:LookupBone("ValveBiped.Bip01_R_Thigh") or -1,
--             rightCalf = ragdoll:LookupBone("ValveBiped.Bip01_R_Calf") or -1,
--             rightFoot = ragdoll:LookupBone("ValveBiped.Bip01_R_Foot") or -1,
            
--             -- Finger bones could be added here
--         }
        
--         -- Verify all essential bones are found
--         local missingBones = {}
--         local essentialBones = {"head", "spine", "leftHand", "rightHand"}
--         for _, boneName in ipairs(essentialBones) do
--             if boneMap[boneName] == -1 then
--                 table.insert(missingBones, boneName)
--             end
--         end
        
--         if #missingBones > 0 then
--             print("VRMod Ragdoll: Missing essential bones: " .. table.concat(missingBones, ", "))
--             return nil
--         end
        
--         return boneMap
--     end
    
--     -- Calculate bone lengths
--     local function CalculateBoneLengths(ragdoll, boneMap)
--         local lengths = {}
        
--         -- Calculate arm lengths
--         if boneMap.leftUpperArm ~= -1 and boneMap.leftForearm ~= -1 then
--             local upperPos = ragdoll:GetBonePosition(boneMap.leftUpperArm)
--             local forearmPos = ragdoll:GetBonePosition(boneMap.leftForearm)
--             lengths.upperArmLen = upperPos:Distance(forearmPos)
--         end
        
--         if boneMap.leftForearm ~= -1 and boneMap.leftHand ~= -1 then
--             local forearmPos = ragdoll:GetBonePosition(boneMap.leftForearm)
--             local handPos = ragdoll:GetBonePosition(boneMap.leftHand)
--             lengths.lowerArmLen = forearmPos:Distance(handPos)
--         end
        
--         -- Calculate leg lengths
--         if boneMap.leftThigh ~= -1 and boneMap.leftCalf ~= -1 then
--             local thighPos = ragdoll:GetBonePosition(boneMap.leftThigh)
--             local calfPos = ragdoll:GetBonePosition(boneMap.leftCalf)
--             lengths.upperLegLen = thighPos:Distance(calfPos)
--         end
        
--         if boneMap.leftCalf ~= -1 and boneMap.leftFoot ~= -1 then
--             local calfPos = ragdoll:GetBonePosition(boneMap.leftCalf)
--             local footPos = ragdoll:GetBonePosition(boneMap.leftFoot)
--             lengths.lowerLegLen = calfPos:Distance(footPos)
--         end
        
--         if boneMap.leftClavicle ~= -1 and boneMap.leftUpperArm ~= -1 then
--             local claviclePos = ragdoll:GetBonePosition(boneMap.leftClavicle)
--             local upperArmPos = ragdoll:GetBonePosition(boneMap.leftUpperArm)
--             lengths.clavicleLen = claviclePos:Distance(upperArmPos)
--         end
        
--         return lengths
--     end
    
--     -- Initialize a ragdoll for VR control
--     local function RagdollInit(ragdoll, options)
--         if not IsValid(ragdoll) then return false end
        
--         local ragdollId = ragdoll:EntIndex()
        
--         -- Check if this ragdoll is already initialized
--         if ragdollSystems[ragdollId] then return false end
        
--         local boneMap = MapBones(ragdoll)
--         if not boneMap then return false end
        
--         -- Setup ragdoll data structure
--         ragdollSystems[ragdollId] = {
--             entity = ragdoll,
--             boneInfo = {},
--             boneOrder = {},
--             boneMap = boneMap,
--             boneLengths = CalculateBoneLengths(ragdoll, boneMap),
--             options = options or {},
--             lastUpdateTime = 0,
--             offsetPos = options.offsetPos or Vector(0, 0, 0),
--             offsetAng = options.offsetAng or Angle(0, 0, 0),
--             targetPos = ragdoll:GetPos(),
--             targetAng = ragdoll:GetAngles(),
--             smoothingFactor = options.smoothingFactor or config.smoothingFactor
--         }
        
--         -- Build bone information tables
--         BuildRagdollBoneInfo(ragdoll, 0, ragdollSystems[ragdollId].boneInfo, ragdollSystems[ragdollId].boneOrder)
        
--         print("VRMod: Ragdoll system initialized for entity " .. ragdollId)
--         return true
--     end
    
--     -- Update the ragdoll's IK to match VR movements
--     local function UpdateRagdollIK(ragdollId)
--         local system = ragdollSystems[ragdollId]
--         if not system or not IsValid(system.entity) then return end
        
--         local ragdoll = system.entity
--         local boneMap = system.boneMap
--         local boneInfo = system.boneInfo
        
--         -- Get current VR tracking data
--         local hmdPos = g_VR.tracking.hmd.pos
--         local hmdAng = g_VR.tracking.hmd.ang
--         local leftHandPos = g_VR.tracking.pose_lefthand.pos
--         local leftHandAng = g_VR.tracking.pose_lefthand.ang
--         local rightHandPos = g_VR.tracking.pose_righthand.pos
--         local rightHandAng = g_VR.tracking.pose_righthand.ang
        
--         -- Calculate ragdoll target position based on HMD
--         local forward = Angle(0, hmdAng.yaw, 0):Forward()
--         system.targetPos = hmdPos - forward * 10 - Vector(0, 0, 40) -- Offset to place head at HMD position
--         system.targetAng = Angle(0, hmdAng.yaw, 0)
        
--         -- Apply smoothing to ragdoll position and angle
--         local smoothing = system.smoothingFactor
--         ragdoll:SetPos(LerpVector(smoothing, ragdoll:GetPos(), system.targetPos))
--         ragdoll:SetAngles(LerpAngle(smoothing, ragdoll:GetAngles(), system.targetAng))
        
--         -- Update head bone to match HMD orientation
--         if boneMap.head ~= -1 and boneInfo[boneMap.head] then
--             local headRelativeAng = WorldToLocal(zeroVec, hmdAng, zeroVec, Angle(0, hmdAng.yaw, 0))
--             local mtx = ragdoll:GetBoneMatrix(boneMap.head)
--             if mtx then
--                 local baseAng = mtx:GetAngles()
--                 local targetAng = Angle(baseAng.pitch + headRelativeAng.pitch, 
--                                         baseAng.yaw, 
--                                         baseAng.roll + headRelativeAng.roll)
                
--                 mtx:SetAngles(targetAng)
--                 ragdoll:SetBoneMatrix(boneMap.head, mtx)
--             end
--         end
        
--         -- Update hand bones to match controller positions
--         if boneMap.leftHand ~= -1 and boneInfo[boneMap.leftHand] then
--             local localPos, localAng = WorldToLocal(leftHandPos, leftHandAng, 
--                                                    ragdoll:GetPos(), ragdoll:GetAngles())
--             local mtx = ragdoll:GetBoneMatrix(boneMap.leftHand)
--             if mtx then
--                 mtx:SetTranslation(ragdoll:LocalToWorld(localPos))
--                 mtx:SetAngles(leftHandAng)
--                 ragdoll:SetBoneMatrix(boneMap.leftHand, mtx)
--             end
--         end
        
--         if boneMap.rightHand ~= -1 and boneInfo[boneMap.rightHand] then
--             local localPos, localAng = WorldToLocal(rightHandPos, rightHandAng, 
--                                                    ragdoll:GetPos(), ragdoll:GetAngles())
--             local mtx = ragdoll:GetBoneMatrix(boneMap.rightHand)
--             if mtx then
--                 mtx:SetTranslation(ragdoll:LocalToWorld(localPos))
--                 mtx:SetAngles(rightHandAng)
--                 ragdoll:SetBoneMatrix(boneMap.rightHand, mtx)
--             end
--         end
        
--         -- Here we would add IK calculations for arms and legs
--         -- This would be similar to the IK in vrmod_character.lua but adapted for ragdolls
        
--         -- Update physics to match bone positions if necessary
--         -- This could use PhysWake() and other physics methods to make the ragdoll follow our bone manipulations
--     end
    
--     -- Render hook
--     local function RagdollRenderHook()
--         if not g_VR.active then return end
        
--         local curTime = SysTime()
        
--         for ragdollId, system in pairs(activeRagdolls) do
--             if IsValid(system.entity) and system.lastUpdateTime + system.updateInterval <= curTime then
--                 system.lastUpdateTime = curTime
--                 UpdateRagdollIK(ragdollId)
--             end
--         end
--     end
    
--     -- Debug visualization
--     local function DrawDebugInfo()
--         if not config.debugMode then return end
        
--         for ragdollId, system in pairs(activeRagdolls) do
--             if IsValid(system.entity) then
--                 local ragdoll = system.entity
                
--                 -- Draw lines between VR tracked points and corresponding bones
--                 render.DrawLine(g_VR.tracking.hmd.pos, ragdoll:GetBonePosition(system.boneMap.head), Color(255, 0, 0))
--                 render.DrawLine(g_VR.tracking.pose_lefthand.pos, ragdoll:GetBonePosition(system.boneMap.leftHand), Color(0, 255, 0))
--                 render.DrawLine(g_VR.tracking.pose_righthand.pos, ragdoll:GetBonePosition(system.boneMap.rightHand), Color(0, 0, 255))
                
--                 -- Draw target position
--                 render.DrawWireframeBox(system.targetPos, system.targetAng, Vector(-5, -5, -5), Vector(5, 5, 5), Color(255, 255, 0))
--             end
--         end
--     end
    
--     -- Public API to start controlling a ragdoll
--     function g_VR.StartRagdollSystem(ragdoll, options)
--         if not g_VR.active then
--             print("VRMod: VR is not active, cannot start ragdoll system")
--             return false
--         end
        
--         if not IsValid(ragdoll) then
--             print("VRMod: Invalid ragdoll entity")
--             return false
--         end
        
--         local ragdollId = ragdoll:EntIndex()
        
--         -- Initialize the ragdoll if needed
--         if not ragdollSystems[ragdollId] and not RagdollInit(ragdoll, options) then
--             print("VRMod: Failed to initialize ragdoll system")
--             return false
--         end
        
--         -- Set as active
--         activeRagdolls[ragdollId] = {
--             entity = ragdoll,
--             updateInterval = options and options.updateInterval or config.updateRate,
--             lastUpdateTime = 0
--         }
        
--         -- Add hooks if this is the first active ragdoll
--         if table.Count(activeRagdolls) == 1 then
--             hook.Add("PostDrawTranslucentRenderables", "vrmod_ragdoll_debug", DrawDebugInfo)
--             hook.Add("VRMod_PreRender", "vrmod_ragdoll_update", RagdollRenderHook)
--         end
        
--         print("VRMod: Started ragdoll system for entity " .. ragdollId)
--         return true
--     end
    
--     -- Public API to stop controlling a ragdoll
--     function g_VR.StopRagdollSystem(ragdollId)
--         if not ragdollId then
--             -- Stop all ragdoll systems
--             activeRagdolls = {}
--             hook.Remove("PostDrawTranslucentRenderables", "vrmod_ragdoll_debug")
--             hook.Remove("VRMod_PreRender", "vrmod_ragdoll_update")
--             print("VRMod: Stopped all ragdoll systems")
--             return true
--         end
        
--         if not activeRagdolls[ragdollId] then
--             print("VRMod: Ragdoll system not active for entity " .. ragdollId)
--             return false
--         end
        
--         -- Remove from active ragdolls
--         activeRagdolls[ragdollId] = nil
        
--         -- Remove hooks if no active ragdolls remain
--         if table.Count(activeRagdolls) == 0 then
--             hook.Remove("PostDrawTranslucentRenderables", "vrmod_ragdoll_debug")
--             hook.Remove("VRMod_PreRender", "vrmod_ragdoll_update")
--         end
        
--         print("VRMod: Stopped ragdoll system for entity " .. ragdollId)
--         return true
--     end
    
--     -- Public API to set ragdoll options
--     function g_VR.SetRagdollOptions(ragdollId, options)
--         if not ragdollSystems[ragdollId] then
--             print("VRMod: Ragdoll system not initialized for entity " .. ragdollId)
--             return false
--         end
        
--         for k, v in pairs(options) do
--             ragdollSystems[ragdollId].options[k] = v
--         end
        
--         return true
--     end
    
--     -- Public API to toggle debug mode
--     function g_VR.SetRagdollDebug(enabled)
--         config.debugMode = enabled
--         print("VRMod: Ragdoll debug mode " .. (enabled and "enabled" or "disabled"))
--     end
    
--     -- Commands for testing
--     concommand.Add("vrmod_ragdoll_test", function(ply, cmd, args)
--         local trace = ply:GetEyeTrace()
--         if IsValid(trace.Entity) and trace.Entity:GetClass() == "prop_ragdoll" then
--             g_VR.StartRagdollSystem(trace.Entity)
--         else
--             print("VRMod: Look at a ragdoll to start controlling it")
--         end
--     end)
    
--     concommand.Add("vrmod_ragdoll_stop", function(ply, cmd, args)
--         g_VR.StopRagdollSystem()
--     end)
    
--     concommand.Add("vrmod_ragdoll_debug", function(ply, cmd, args)
--         g_VR.SetRagdollDebug(args[1] == "1")
--     end)
    
--     -- Hook into VRMod system
--     hook.Add("VRMod_Start", "vrmod_ragdoll_start", function()
--         print("VRMod: Ragdoll system available")
--     end)
    
--     hook.Add("VRMod_Exit", "vrmod_ragdoll_exit", function()
--         g_VR.StopRagdollSystem() -- Stop all ragdoll systems
--     end)
-- end

-- if SERVER then
--     -- Server-side code would go here if needed
--     -- For example:
--     -- - Network synchronization
--     -- - Commands to create and control ragdolls
--     -- - Server-side physics manipulation
--     util.AddNetworkString("vrmod_ragdoll_sync")
    
--     hook.Add("PlayerSpawn", "vrmod_ragdoll_playerspawn", function(ply)
--         -- Reset any ragdoll control when player respawns
--     end)
-- end
