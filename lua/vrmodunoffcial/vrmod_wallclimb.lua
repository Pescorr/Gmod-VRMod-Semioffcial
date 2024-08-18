-- if CLIENT then
--     local CLIMB_DISTANCE = 100 -- クライミング可能な最大距離
--     local CLIMB_FORCE = 1000 -- クライミング力

--     local climbing = {left = false, right = false}
--     local climbPos = {left = Vector(), right = Vector()}
--     local lastPos = {left = Vector(), right = Vector()}
--     local climbDir = {left = Vector(), right = Vector()}
--     local climbAng = {left = Angle(), right = Angle()}
--     local climbLerp = {left = 0, right = 0}
--     local climbDeltaOld = {left = Vector(), right = Vector()}

--     -- クライミング音声の設定
--     local climbStartSound = Sound("physics/concrete/concrete_impact_soft1.wav")
--     local climbEndSound = Sound("physics/concrete/concrete_impact_soft2.wav")

--     local csize = 5
--     local climbTr = {
--         left = {
--             start = Vector(),
--             endpos = Vector(),
--             mins = Vector(-csize, -csize, -csize),
--             maxs = Vector(csize, csize, csize),
--             output = {}
--         },
--         right = {
--             start = Vector(),
--             endpos = Vector(),
--             mins = Vector(-csize, -csize, -csize),
--             maxs = Vector(csize, csize, csize),
--             output = {}
--         }
--     }

--     local upVec = Vector(0, 0, 1)
--     local zeroVec = Vector()

--     local function StartClimbing(hand)
--         if not climbing[hand] then
--             local handPos = g_VR.tracking["pose_" .. hand .. "hand"].pos
--             climbTr[hand].start:Set(handPos)
--             climbTr[hand].endpos:Set(handPos)
--             climbTr[hand].filter = LocalPlayer()
            
--             util.TraceHull(climbTr[hand])
            
--             if climbTr[hand].output.Hit then
--                 if climbTr[hand].output.HitWorld or (climbTr[hand].output.Entity:GetClass() == "prop_physics" and (not IsValid(climbTr[hand].output.Entity:GetPhysicsObject()) or not climbTr[hand].output.Entity:GetPhysicsObject():IsMotionEnabled())) then
--                     climbing[hand] = true
--                     climbPos[hand]:Set(handPos)
--                     climbDir[hand] = climbTr[hand].output.HitNormal
--                     climbAng[hand] = g_VR.tracking["pose_" .. hand .. "hand"].ang
--                     lastPos[hand]:Set(handPos)
--                     climbLerp[hand] = 1
                    
--                     if g_VR.tracking["pose_" .. hand .. "hand"].vel:Length() > 50 then
--                         LocalPlayer():EmitSound(climbStartSound, 75, 100, 0.75)
--                     else
--                         LocalPlayer():EmitSound(climbStartSound, 75, 100, 0.5)
--                     end
--                 end
--             end
--         end
--     end

--     local function StopClimbing(hand)
--         if climbing[hand] then
--             climbing[hand] = false
--             climbLerp[hand] = 0
--             if g_VR.tracking["pose_" .. hand .. "hand"].vel:Length() > 50 then
--                 LocalPlayer():EmitSound(climbEndSound, 75, 100, 0.5)
--             end
--         end
--     end

--     hook.Add("VRMod_Input", "VRClimbing", function(action, pressed)
--         if action == "boolean_left_pickup" then
--             if pressed then StartClimbing("left") else StopClimbing("left") end
--         elseif action == "boolean_right_pickup" then
--             if pressed then StartClimbing("right") else StopClimbing("right") end
--         end
--     end)

--     hook.Add("CreateMove", "VRClimbing", function(cmd)
--         if not g_VR.active then return end

--         local ply = LocalPlayer()
--         local pos = ply:GetPos()
--         local targetPos = Vector(pos)

--         for _, hand in ipairs({"left", "right"}) do
--             if climbing[hand] or climbLerp[hand] > 0 then
--                 local handPos = g_VR.tracking["pose_" .. hand .. "hand"].pos
--                 local climbDelta = LocalToWorld(climbPos[hand] - handPos, angle_zero, climbPos[hand] - handPos, climbDir[hand]:Angle())
                
--                 if not climbing[hand] then
--                     climbDelta:Set(climbDeltaOld[hand])
--                 else
--                     climbDeltaOld[hand]:Set(climbDelta)
--                 end

--                 climbLerp[hand] = math.Approach(climbLerp[hand], climbing[hand] and 1 or 0, FrameTime() * 0.5)
                
--                 if climbing[hand == "left" and "right" or "left"] or climbLerp[hand == "left" and "right" or "left"] > 0 then
--                     climbDelta:Mul(Lerp(climbLerp[hand == "left" and "right" or "left"], 1, 0.5))
--                 end

--                 targetPos:Add(LerpVector(climbLerp[hand], zeroVec, climbDelta))
--             end
--         end

--         if targetPos:DistToSqr(pos) > 250000 then -- 500^2
--             targetPos:Set(pos)
--         end

--         cmd:SetForwardMove(targetPos.x - pos.x)
--         cmd:SetSideMove(targetPos.y - pos.y)
--         cmd:SetUpMove(targetPos.z - pos.z)
--     end)

--     hook.Add("VRMod_PreRender", "VRClimbing", function()
--         for _, hand in ipairs({"left", "right"}) do
--             if climbing[hand] then
--                 local handPose = g_VR.tracking["pose_" .. hand .. "hand"]
--                 local newPos = climbPos[hand]
--                 if hand == "left" then
--                     vrmod.SetLeftHandPose(newPos, climbAng[hand])
--                 else
--                     vrmod.SetRightHandPose(newPos, climbAng[hand])
--                 end
--             end
--         end
--     end)

--     -- デバッグ用の視覚的表現
--     hook.Add("PostDrawTranslucentRenderables", "VRClimbing", function()
--         if not g_VR.active then return end

--         for _, hand in ipairs({"left", "right"}) do
--             if climbing[hand] then
--                 local handPos = g_VR.tracking["pose_" .. hand .. "hand"].pos
--                 render.DrawLine(handPos, climbPos[hand], Color(0, 255, 0), true)
--                 render.DrawWireframeSphere(climbPos[hand], 5, 10, 10, Color(255, 0, 0), true)
--             end
--         end
--     end)
-- end