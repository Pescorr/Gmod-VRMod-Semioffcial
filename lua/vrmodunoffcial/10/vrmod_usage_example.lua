-- -- Example usage of the VRMod Ragdoll System

-- -- Create a ragdoll entity
-- local function CreateVRControlledRagdoll()
--     -- Create a ragdoll at player's position
--     local ragdoll = ents.Create("prop_ragdoll")
--     ragdoll:SetModel("models/player/Group01/male_07.mdl") -- Use any model you want
    
--     -- Position it in front of the player
--     local pos = LocalPlayer():GetPos() + LocalPlayer():GetForward() * 50
--     pos.z = pos.z + 30 -- Raise it off the ground
--     ragdoll:SetPos(pos)
    
--     -- Face the ragdoll toward the player
--     local ang = (LocalPlayer():GetPos() - pos):Angle()
--     ang.p = 0
--     ragdoll:SetAngles(ang)
    
--     ragdoll:Spawn()
--     ragdoll:Activate()
    
--     -- Add a custom property to identify it as VR-controlled
--     ragdoll.IsVRControlled = true
    
--     -- Start VR control
--     g_VR.StartRagdollSystem(ragdoll, {
--         smoothingFactor = 0.3,    -- Less smoothing = faster response
--         updateInterval = 0.01,    -- Update rate in seconds
--         offsetPos = Vector(0, 0, 0), -- Offset from VR position
--         offsetAng = Angle(0, 0, 0)   -- Offset from VR angles
--     })
    
--     -- Return the created ragdoll
--     return ragdoll
-- end

-- -- Scene recording system
-- local SceneRecorder = {
--     recording = false,
--     frames = {},
--     currentFrame = 0,
--     ragdoll = nil,
--     interval = 0.05, -- Record at 20 fps
--     lastRecordTime = 0
-- }

-- function SceneRecorder:StartRecording(ragdoll)
--     if self.recording then return end
    
--     self.ragdoll = ragdoll
--     self.frames = {}
--     self.currentFrame = 0
--     self.lastRecordTime = SysTime()
--     self.recording = true
    
--     print("Scene recording started")
-- end

-- function SceneRecorder:StopRecording()
--     if not self.recording then return end
    
--     self.recording = false
--     print("Scene recording stopped. Recorded " .. #self.frames .. " frames.")
-- end

-- function SceneRecorder:RecordFrame()
--     if not self.recording or not IsValid(self.ragdoll) then return end
    
--     local currentTime = SysTime()
--     if currentTime - self.lastRecordTime < self.interval then return end
    
--     -- Record position, angles and bone data
--     local frame = {
--         pos = self.ragdoll:GetPos(),
--         ang = self.ragdoll:GetAngles(),
--         bones = {}
--     }
    
--     -- Record bone positions for important bones
--     local bonesToRecord = {
--         "ValveBiped.Bip01_Head1",
--         "ValveBiped.Bip01_L_Hand",
--         "ValveBiped.Bip01_R_Hand",
--         "ValveBiped.Bip01_Spine",
--         "ValveBiped.Bip01_L_Foot",
--         "ValveBiped.Bip01_R_Foot"
--     }
    
--     for _, boneName in ipairs(bonesToRecord) do
--         local boneId = self.ragdoll:LookupBone(boneName)
--         if boneId then
--             local pos, ang = self.ragdoll:GetBonePosition(boneId)
--             frame.bones[boneName] = {
--                 pos = pos,
--                 ang = ang
--             }
--         end
--     end
    
--     self.frames[#self.frames + 1] = frame
--     self.lastRecordTime = currentTime
    
--     -- Debug info
--     if #self.frames % 20 == 0 then
--         print("Recorded frame " .. #self.frames)
--     end
-- end

-- function SceneRecorder:PlaybackScene()
--     if #self.frames == 0 or self.recording then return end
    
--     -- Create a new ragdoll for playback if needed
--     if not IsValid(self.ragdoll) then
--         self.ragdoll = CreateVRControlledRagdoll()
--         g_VR.StopRagdollSystem(self.ragdoll:EntIndex()) -- Stop VR control for playback
--     end
    
--     self.currentFrame = 1
    
--     -- Start playback timer
--     timer.Create("ScenePlayback", self.interval, #self.frames, function()
--         if not IsValid(self.ragdoll) then
--             timer.Remove("ScenePlayback")
--             return
--         end
        
--         local frame = self.frames[self.currentFrame]
--         if frame then
--             -- Apply position and angles
--             self.ragdoll:SetPos(frame.pos)
--             self.ragdoll:SetAngles(frame.ang)
            
--             -- Apply bone positions
--             for boneName, boneData in pairs(frame.bones) do
--                 local boneId = self.ragdoll:LookupBone(boneName)
--                 if boneId then
--                     local matrix = self.ragdoll:GetBoneMatrix(boneId)
--                     if matrix then
--                         matrix:SetTranslation(boneData.pos)
--                         matrix:SetAngles(boneData.ang)
--                         self.ragdoll:SetBoneMatrix(boneId, matrix)
--                     end
--                 end
--             end
            
--             -- Increment frame counter
--             self.currentFrame = self.currentFrame + 1
--         end
--     end)
    
--     print("Scene playback started")
-- end

-- function SceneRecorder:SaveScene(filename)
--     if #self.frames == 0 then
--         print("No scene to save")
--         return
--     end
    
--     filename = filename or "vrscene_" .. os.time() .. ".json"
    
--     -- Prepare data for serialization
--     local data = {
--         model = self.ragdoll:GetModel(),
--         frameCount = #self.frames,
--         frameInterval = self.interval,
--         frames = {}
--     }
    
--     -- Convert frames to serializable format
--     for i, frame in ipairs(self.frames) do
--         local serializedFrame = {
--             pos = { x = frame.pos.x, y = frame.pos.y, z = frame.pos.z },
--             ang = { p = frame.ang.p, y = frame.ang.y, r = frame.ang.r },
--             bones = {}
--         }
        
--         for boneName, boneData in pairs(frame.bones) do
--             serializedFrame.bones[boneName] = {
--                 pos = { x = boneData.pos.x, y = boneData.pos.y, z = boneData.pos.z },
--                 ang = { p = boneData.ang.p, y = boneData.ang.y, r = boneData.ang.r }
--             }
--         end
        
--         data.frames[i] = serializedFrame
--     end
    
--     -- Convert to JSON
--     local json = util.TableToJSON(data, true)
    
--     -- Save to file
--     file.CreateDir("vrscenes")
--     file.Write("vrscenes/" .. filename, json)
    
--     print("Scene saved to data/vrscenes/" .. filename)
-- end

-- function SceneRecorder:LoadScene(filename)
--     if not file.Exists("vrscenes/" .. filename, "DATA") then
--         print("Scene file not found: " .. filename)
--         return false
--     end
    
--     local json = file.Read("vrscenes/" .. filename, "DATA")
--     local data = util.JSONToTable(json)
    
--     if not data or not data.frames then
--         print("Invalid scene file format")
--         return false
--     end
    
--     -- Create a new ragdoll for playback
--     if IsValid(self.ragdoll) then
--         self.ragdoll:Remove()
--     end
    
--     self.ragdoll = ents.Create("prop_ragdoll")
--     self.ragdoll:SetModel(data.model or "models/player/Group01/male_07.mdl")
    
--     local pos = LocalPlayer():GetPos() + LocalPlayer():GetForward() * 50
--     pos.z = pos.z + 30
--     self.ragdoll:SetPos(pos)
    
--     local ang = (LocalPlayer():GetPos() - pos):Angle()
--     ang.p = 0
--     self.ragdoll:SetAngles(ang)
    
--     self.ragdoll:Spawn()
--     self.ragdoll:Activate()
    
--     -- Convert frames from serialized format
--     self.frames = {}
--     self.interval = data.frameInterval or 0.05
    
--     for i, serializedFrame in ipairs(data.frames) do
--         local frame = {
--             pos = Vector(serializedFrame.pos.x, serializedFrame.pos.y, serializedFrame.pos.z),
--             ang = Angle(serializedFrame.ang.p, serializedFrame.ang.y, serializedFrame.ang.r),
--             bones = {}
--         }
        
--         for boneName, boneData in pairs(serializedFrame.bones) do
--             frame.bones[boneName] = {
--                 pos = Vector(boneData.pos.x, boneData.pos.y, boneData.pos.z),
--                 ang = Angle(boneData.ang.p, boneData.ang.y, boneData.ang.r)
--             }
--         end
        
--         self.frames[i] = frame
--     end
    
--     print("Scene loaded with " .. #self.frames .. " frames")
--     return true
-- end

-- -- Register console commands
-- concommand.Add("vrmod_ragdoll_create", function()
--     local ragdoll = CreateVRControlledRagdoll()
--     print("Created VR-controlled ragdoll: " .. ragdoll:EntIndex())
-- end)

-- concommand.Add("vrmod_ragdoll_record_start", function()
--     local trace = LocalPlayer():GetEyeTrace()
--     if IsValid(trace.Entity) and trace.Entity:GetClass() == "prop_ragdoll" then
--         SceneRecorder:StartRecording(trace.Entity)
--     else
--         print("Look at a ragdoll to start recording")
--     end
-- end)

-- concommand.Add("vrmod_ragdoll_record_stop", function()
--     SceneRecorder:StopRecording()
-- end)

-- concommand.Add("vrmod_ragdoll_play", function()
--     SceneRecorder:PlaybackScene()
-- end)

-- concommand.Add("vrmod_ragdoll_save", function(ply, cmd, args)
--     local filename = args[1] or "scene.json"
--     SceneRecorder:SaveScene(filename)
-- end)

-- concommand.Add("vrmod_ragdoll_load", function(ply, cmd, args)
--     local filename = args[1] or "scene.json"
--     SceneRecorder:LoadScene(filename)
-- end)

-- -- Hook for recording frames
-- hook.Add("Think", "VRRecorderThink", function()
--     if SceneRecorder.recording then
--         SceneRecorder:RecordFrame()
--     end
-- end)

-- -- Hook for cleaning up on exit
-- hook.Add("VRMod_Exit", "VRRecorderCleanup", function()
--     SceneRecorder:StopRecording()
--     if timer.Exists("ScenePlayback") then
--         timer.Remove("ScenePlayback")
--     end
-- end)

-- -- Print help message
-- print("\n----- VRMod Ragdoll System Commands -----")
-- print("vrmod_ragdoll_create - Create a new VR-controlled ragdoll")
-- print("vrmod_ragdoll_record_start - Start recording a scene (look at a ragdoll)")
-- print("vrmod_ragdoll_record_stop - Stop recording")
-- print("vrmod_ragdoll_play - Play back the recorded scene")
-- print("vrmod_ragdoll_save [filename] - Save the scene to a file")
-- print("vrmod_ragdoll_load [filename] - Load a scene from a file")
-- print("vrmod_ragdoll_debug 1/0 - Enable/disable debug visualization")
-- print("----------------------------------------\n")
