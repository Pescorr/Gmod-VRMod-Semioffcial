if CLIENT then
	concommand.Add(
		"vrmod_dev_printvmbones",
		function(ply)
			local vm = ply:GetViewModel()
			print("SWEP.BoneIndices = {")
			for i = 0, vm:GetBoneCount() - 1 do
				print(" " .. vm:GetBoneName(i) .. " = " .. tostring(i) .. ",")
			end

			print("}")
		end
	)

	-- function vrmod.GetViewModelLeftHandPos(ply)
	-- 	local vm = ply and ply:GetViewModel() or LocalPlayer():GetViewModel()
	-- 	if not IsValid(vm) then return end
	-- 	local leftHandBoneIndex = vm:LookupBone("ValveBiped.Bip01_L_Hand")
	-- 	if not leftHandBoneIndex then return end
	-- 	local boneMatrix = vm:GetBoneMatrix(leftHandBoneIndex)
	-- 	if not boneMatrix then return end

	-- 	return boneMatrix:GetTranslation()
	-- end 

	-- function vrmod.GetViewModelBone(ply, boneName)
	-- 	local vm = ply and ply:GetViewModel() or LocalPlayer():GetViewModel()
	-- 	if not IsValid(vm) then return end
	-- 	local boneIndex = vm:LookupBone(boneName)
	-- 	if not boneIndex then return end
	-- 	local boneMatrix = vm:GetBoneMatrix(boneIndex)
	-- 	if not boneMatrix then return end
	-- 	local pos, ang = boneMatrix:GetTranslation(), boneMatrix:GetAngles()

	-- 	return pos, ang
	-- end

	-- function vrmod.GetMagBonePos(ply)
	-- 	local vm = ply and ply:GetViewModel() or LocalPlayer():GetViewModel()
	-- 	if not IsValid(vm) then return vrmod.GetRightHandPos() end
	-- 	local magBoneIndex = nil
	-- 	for i = 0, vm:GetBoneCount() - 1 do
	-- 		local boneName = vm:GetBoneName(i)
	-- 		if string.find(boneName, "mag") then
	-- 			magBoneIndex = i
	-- 			break
	-- 		end
	-- 	end

	-- 	if magBoneIndex then
	-- 		local boneMatrix = vm:GetBoneMatrix(magBoneIndex)
	-- 		if boneMatrix then return boneMatrix:GetTranslation() end
	-- 	end

	-- 	return vrmod.GetRightHandPos()
	-- end

	-- function vrmod.ToggleMagBoneVisibility(ply, visible)
	-- 	local vm = ply and ply:GetViewModel() or LocalPlayer():GetViewModel()
	-- 	if not IsValid(vm) then return end
	-- 	for i = 0, vm:GetBoneCount() - 1 do
	-- 		local boneName = vm:GetBoneName(i)
	-- 		if string.find(boneName, "mag") then
	-- 			vm:ManipulateBoneScale(i, visible and Vector(1, 1, 1) or Vector(0, 0, 0))
	-- 			break
	-- 		end
	-- 	end
	-- end
end