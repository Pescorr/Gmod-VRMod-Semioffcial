
----[VRPickupSystem]start----
	function vrmod_pickup_lua()
		g_VR = g_VR or {}
		vrmod = vrmod or {}
		scripted_ents.Register(
			{
				Type = "anim",
				Base = "vrmod_pickup"
			}, "vrmod_pickup"
		)

		local _, convarValues = vrmod.GetConvars()
		vrmod.AddCallbackedConvar("vrmod_pickup_limit", nil, 1, FCVAR_REPLICATED + FCVAR_NOTIFY + FCVAR_ARCHIVE, "", 0, 3, tonumber) --cvarName, valueName, defaultValue, flags, helptext, min, max, conversionFunc, callbackFunc
		vrmod.AddCallbackedConvar("vrmod_pickup_centered", nil, 1, FCVAR_REPLICATED + FCVAR_ARCHIVE, "", 0, 1, tonumber) --cvarName, valueName, defaultValue, flags, helptext, min, max, conversionFunc, callbackFunc
		vrmod.AddCallbackedConvar("vrmod_dev_pickup_limit_droptest", nil, 1, FCVAR_REPLICATED + FCVAR_ARCHIVE, "", 0, 2, tonumber) --cvarName, valueName, defaultValue, flags, helptext, min, max, conversionFunc, callbackFunc
		vrmod.AddCallbackedConvar("vrmod_pickup_range", nil, 1.1, FCVAR_REPLICATED + FCVAR_ARCHIVE, "", 0.0, 999.0, tonumber) --cvarName, valueName, defaultValue, flags, helptext, min, max, conversionFunc, callbackFunc
		vrmod.AddCallbackedConvar("vrmod_pickup_weight", nil, 100, FCVAR_REPLICATED + FCVAR_ARCHIVE, "", 0, 99999, tonumber) --cvarName, valueName, defaultValue, flags, helptext, min, max, conversionFunc, callbackFunc
		if CLIENT then
			function vrmod.Pickup(bLeftHand, bDrop)
				net.Start("vrmod_pickup")
				net.WriteBool(bLeftHand)
				net.WriteBool(bDrop or false)
				local pose = bLeftHand and g_VR.tracking.pose_lefthand or g_VR.tracking.pose_righthand
				net.WriteVector(pose.pos)
				net.WriteAngle(pose.ang)
				if bDrop then
					net.WriteVector(pose.vel)
					net.WriteVector(pose.angvel)
					g_VR[bLeftHand and "heldEntityLeft" or "heldEntityRight"] = nil
				end

				net.SendToServer()
			end

			net.Receive(
				"vrmod_pickup",
				function(len)
					local ply = net.ReadEntity()
					local ent = net.ReadEntity()
					local bDrop = net.ReadBool()
					if bDrop then
						--print("client received drop")
						if IsValid(ent) and ent.RenderOverride == ent.VRPickupRenderOverride then
							ent.RenderOverride = nil
						end

						hook.Call("VRMod_Drop", nil, ply, ent)
					else
						local bLeftHand = net.ReadBool()
						local localPos = net.ReadVector()
						local localAng = net.ReadAngle()
						--
						local steamid = IsValid(ply) and ply:SteamID()
						if g_VR.net[steamid] == nil then return end
						--
						ent.RenderOverride = function()
							if g_VR.net[steamid] == nil then return end
							local wpos, wang
							if bLeftHand then
								wpos, wang = LocalToWorld(localPos, localAng, g_VR.net[steamid].lerpedFrame.lefthandPos, g_VR.net[steamid].lerpedFrame.lefthandAng)
							else
								wpos, wang = LocalToWorld(localPos, localAng, g_VR.net[steamid].lerpedFrame.righthandPos, g_VR.net[steamid].lerpedFrame.righthandAng)
							end

							ent:SetPos(wpos)
							ent:SetAngles(wang)
							ent:SetupBones()
							ent:DrawModel()
						end

						ent.VRPickupRenderOverride = ent.RenderOverride
						if ply == LocalPlayer() then
							g_VR[bLeftHand and "heldEntityLeft" or "heldEntityRight"] = ent
						end

						--]]
						hook.Call("VRMod_Pickup", nil, ply, ent)
					end
				end
			)
		elseif SERVER then
			util.AddNetworkString("vrmod_pickup")
			local pickupController = nil
			local pickupList = {}
			local pickupCount = 0
			function drop(steamid, bLeftHand, handPos, handAng, handVel, handAngVel)
				for i = 1, pickupCount do
					local t = pickupList[i]
					if not t then continue end -- 追加: tがnilの場合はスキップ
					if t.steamid ~= steamid or t.left ~= bLeftHand then continue end
					local phys = t.phys
					-- 修正: tがテーブルであることを確認
					if not istable(t) or not t.ent then
						drop(t.steamid, t.left)
						break
					end

					if IsValid(phys) and IsValid(t.ent) then
						t.ent:SetCollisionGroup(t.collisionGroup)
						pickupController:RemoveFromMotionController(phys)
						if handPos then
							local wPos, wAng = LocalToWorld(t.localPos, t.localAng, handPos, handAng)
							phys:SetPos(wPos)
							phys:SetAngles(wAng)
							phys:SetVelocity(t.ply:GetVelocity() + handVel)
							phys:AddAngleVelocity(-phys:GetAngleVelocity() + phys:WorldToLocalVector(handAngVel))
							phys:Wake()
						end
					end

					net.Start("vrmod_pickup")
					net.WriteEntity(t.ply)
					net.WriteEntity(t.ent)
					net.WriteBool(true) --drop
					net.Broadcast()
					if g_VR[t.steamid] then
						g_VR[t.steamid].heldItems[bLeftHand and 1 or 2] = nil
					end

					pickupList[i] = pickupList[pickupCount]
					pickupList[pickupCount] = nil
					pickupCount = pickupCount - 1
					if pickupCount == 0 then
						pickupController:StopMotionController()
						pickupController:Remove()
						pickupController = nil
						hook.Remove("Tick", "vrmod_pickup")
					end

					hook.Call("VRMod_Drop", nil, t.ply, t.ent)

					return
				end
			end

			--pes&chatgptstart
			function shouldPickUp(ent)
				local vphys = ent:GetPhysicsObject()
				-- ここで、エンティティが拾われるべきかどうかを判断するコードを追加します。
				-- 拾われるべきでないエンティティの場合は、false を返します。
				-- 例: エンティティのクラス名が "not_pickable" の場合、false を返す
				if ent:GetModel() == "models/hunter/plates/plate.mdl" and IsValid(vphys) and vphys:GetMass() == 20 and ent:GetNoDraw() == true then return false end
				-- 他の条件を追加することができます。
				if ent:GetNoDraw() == true then return false end
				-- 上記の条件に一致しない場合、エンティティは拾われるべきと判断されます。

				return true
			end

			--pes&chatgptend
			function pickup(ply, bLeftHand, handPos, handAng)
				local steamid = ply:SteamID()
				local pickupPoint = LocalToWorld(Vector(0.5, bLeftHand and -0.05 or 0.05, 0), Angle(), handPos, handAng)
				local entities = ents.FindInSphere(pickupPoint, 110)
				for k = 1, #entities do
					local v = entities[k]
					--pescorrzonestart
					-- ここで shouldPickUp 関数を使用して、エンティティが拾われるべきかどうかをチェックします。
					if not shouldPickUp(v) then continue end
					if convarValues.vrmod_pickup_limit == 3 then return end
					if convarValues.vrmod_pickup_limit == 2 then
						if not IsValid(v) or not IsValid(v:GetPhysicsObject()) or ply:InVehicle() or not v:GetPhysicsObject():IsMoveable() or v:GetPhysicsObject():GetMass() > convarValues.vrmod_pickup_weight or v:GetPhysicsObject():HasGameFlag(FVPHYSICS_MULTIOBJECT_ENTITY) or v == ply or (v.CPPICanPickup ~= nil and not v:CPPICanPickup(ply)) then continue end
					end

					if convarValues.vrmod_pickup_limit == 1 then
						if not IsValid(v) or not IsValid(v:GetPhysicsObject()) or v == ply or ply:InVehicle() or v:GetMoveType() ~= MOVETYPE_VPHYSICS or v:GetPhysicsObject():GetMass() > convarValues.vrmod_pickup_weight then continue end
					end

					if convarValues.vrmod_pickup_limit == 0 then
						if not IsValid(v) or not IsValid(v:GetPhysicsObject()) or v == ply or ply:InVehicle() or v:GetPhysicsObject():GetMass() > convarValues.vrmod_pickup_weight then continue end
					end

					--pescorrzoneend
					if not WorldToLocal(pickupPoint - v:GetPos(), Angle(), Vector(), v:GetAngles()):WithinAABox(v:OBBMins() * convarValues.vrmod_pickup_range, v:OBBMaxs() * convarValues.vrmod_pickup_range) then continue end
					if hook.Call("VRMod_Pickup", nil, ply, v) == false then return end
					-- Ragdoll pickup modification
					if convarValues.vrmod_pickup_centered == 1 then
						if IsValid(v:GetPhysicsObject()) then
							local offset = handPos - v:GetPos() - Vector(3.5, 1.25, 0)
							for i = 0, v:GetPhysicsObjectCount() - 1 do
								local phys = v:GetPhysicsObjectNum(i)
								if IsValid(phys) then
									phys:SetPos(phys:GetPos() - offset)
								end
							end

							v:SetAngles(handAng + Angle(0,0,-15))
						end
					end

					if pickupController == nil then
						pickupController = ents.Create("vrmod_pickup")
						pickupController:Spawn()
						pickupController.ShadowParams = {
							secondstoarrive = 0.00005, --1/cv_tickrate:GetInt()
							maxangular = 5000,
							maxangulardamp = 5000,
							maxspeed = 2000000,
							maxspeeddamp = 20000,
							dampfactor = 0.3,
							teleportdistance = 2000,
							deltatime = 0,
						}

						function pickupController:PhysicsSimulate(phys, deltatime)
							phys:Wake()
							local t = phys:GetEntity().vrmod_pickup_info
							local frame = g_VR[t.steamid] and g_VR[t.steamid].latestFrame
							if not frame then return end
							local handPos, handAng = LocalToWorld(t.left and frame.lefthandPos or frame.righthandPos, t.left and frame.lefthandAng or frame.righthandAng, t.ply:GetPos(), Angle()) --frame is relative to ply pos when on foot
							self.ShadowParams.pos, self.ShadowParams.angle = LocalToWorld(t.localPos, t.localAng, handPos, handAng)
							--this doesn't have to be inside PhysicsSimulate, we could potentially get rid of the motion controller entirely (as a micro optimization) and do this from the tick hook, but it seems to work better from here
							phys:ComputeShadowControl(self.ShadowParams)
						end

						pickupController:StartMotionController()
						hook.Add(
							"Tick",
							"vrmod_pickup",
							function()
								--drop items that have become immovable or invalid
								for i = 1, pickupCount do
									local t = pickupList[i]
									if t == nil then
										i = 0
										break
									end

									--pescorrzonestart
									if convarValues.vrmod_test_pickup_limit_droptest == 2 then
										drop(t.steamid, t.left)
									end

									if convarValues.vrmod_test_pickup_limit_droptest == 1 then
										if not IsValid(t.phys) or not t.phys:IsMoveable() or not g_VR[t.steamid] or not t.ply:Alive() or t.ply:InVehicle() then
											if not g_VR[t.steamid] or t.ply:InVehicle() then
												--print("dropping invalid")
												drop(t.steamid, t.left)
											end
										end
									end

									if convarValues.vrmod_test_pickup_limit_droptest == 0 then
										if not g_VR[t.steamid] or t.ply:InVehicle() then
											--print("dropping invalid")
											drop(t.steamid, t.left)
										end
									end
									--pescorrzoneend
								end
							end
						)
					end

					--if the item is already being held we should overwrite the existing pickup instead of adding a new one
					local index = pickupCount + 1
					for k2 = 1, pickupCount do
						local v2 = pickupList[k2]
						if not v2 then continue end -- 追加: v2がnilの場合はスキップ
						if not istable(v2) then continue end -- 追加: v2がテーブルでない場合はスキップ
						if v == v2.ent then
							index = k2
							-- 修正: g_VR[v2.steamid]とheldItemsの存在を確認
							if g_VR[v2.steamid] and g_VR[v2.steamid].heldItems then
								g_VR[v2.steamid].heldItems[v2.left and 1 or 2] = nil
							end

							break
						end
					end

					--new pickup
					if index > pickupCount then
						--print("new pickup")
						ply:PickupObject(v) --this is done to trigger map logic
						timer.Simple(
							0,
							function()
								ply:DropObject()
							end
						)

						pickupCount = pickupCount + 1
						if pickupController ~= nil or v ~= nil then
							pickupController:AddToMotionController(v:GetPhysicsObject())
							v:PhysWake()
						else
							ply:DropObject()
						end
					end

					--print("existing pickup")
					--print("existing pickup")
					local localPos, localAng = WorldToLocal(v:GetPos(), v:GetAngles(), handPos, handAng)
					pickupList[index] = {
						ent = v,
						phys = v:GetPhysicsObject(),
						left = bLeftHand,
						localPos = localPos,
						localAng = localAng,
						collisionGroup = pickupList[index] and pickupList[index].collisionGroup or v:GetCollisionGroup(),
						steamid = steamid,
						ply = ply
					}

					g_VR[steamid].heldItems = g_VR[steamid].heldItems or {}
					g_VR[steamid].heldItems[bLeftHand and 1 or 2] = pickupList[index]
					v.vrmod_pickup_info = pickupList[index]
					v:SetCollisionGroup(COLLISION_GROUP_PASSABLE_DOOR) --don't collide with the player
					net.Start("vrmod_pickup")
					net.WriteEntity(ply)
					net.WriteEntity(v)
					net.WriteBool(bDrop)
					net.WriteBool(bLeftHand)
					net.WriteVector(localPos)
					net.WriteAngle(localAng)
					net.Broadcast()
				end
			end

			vrmod.NetReceiveLimited(
				"vrmod_pickup",
				10,
				400,
				function(len, ply)
					local bLeftHand = net.ReadBool()
					local bDrop = net.ReadBool()
					if not bDrop then
						pickup(ply, bLeftHand, net.ReadVector(), net.ReadAngle())
					else
						drop(ply:SteamID(), bLeftHand, net.ReadVector(), net.ReadAngle(), net.ReadVector(), net.ReadVector())
					end
				end
			)

			hook.Add(
				"VRMod_Exit",
				"pickupreset",
				function(ply, ent)
					pickupCount = 0
					hook.Call("VRMod_Drop", nil, ply, ent)
				end
			)

			-- table.remove(g_VR[ply:SteamID()].heldItems)
			--block the gmod default pickup for vr players
			hook.Add(
				"AllowPlayerPickup",
				"vrmod",
				function(ply)
					if g_VR[ply:SteamID()] ~= nil then return false end
				end
			)
		end

		
		-- if SERVER then
		-- 	-- サーバー側でconcommandを登録
		-- 	concommand.Add(
		-- 		"vrmod_reset_pickup",
		-- 		function(ply)
		-- 			if not ply:IsValid() or not ply:IsSuperAdmin() then return end -- プレイヤーが無効または管理者でない場合は実行しない
		-- 			-- pickupListテーブルをクリアする
		-- 			pickupList = {}
		-- 			pickupCount = 0
		-- 			-- 既存のpickupControllerを削除する
		-- 			if IsValid(pickupController) then
		-- 				pickupController:Remove()
		-- 				pickupController = nil
		-- 			end

		-- 			-- クライアントにメッセージを送信する
		-- 			net.Start("vrmod_pickup_reset")
		-- 			net.Broadcast()
		-- 			print("VRMod pickup table has been reset by " .. ply:Nick())
		-- 		end
		-- 	)

		-- 	-- クライアントにメッセージを送信するためのネットワークストリングを登録
		-- 	util.AddNetworkString("vrmod_pickup_reset")
		-- elseif CLIENT then
		-- 	-- クライアント側でネットワークメッセージを受信したときの処理を登録
		-- 	net.Receive(
		-- 		"vrmod_pickup_reset",
		-- 		function()
		-- 			-- クライアント側のheldItemsテーブルをクリアする
		-- 			local steamid = LocalPlayer():SteamID()
		-- 			if g_VR[steamid] then
		-- 				g_VR[steamid].heldItems = {}
		-- 			end

		-- 			-- クライアント側のheldEntityLeftとheldEntityRightを解放する
		-- 			g_VR.heldEntityLeft = nil
		-- 			g_VR.heldEntityRight = nil
		-- 			print("VRMod pickup table has been reset")
		-- 		end
		-- 	)
		-- end
	end

	vrmod_pickup_lua()
	concommand.Add(
		"vrmod_lua_reset_pickup_classic",
		function(ply, cmd, args)
			vrmod_pickup_lua()
		end
	)
----[VRPickupSystem]end----
