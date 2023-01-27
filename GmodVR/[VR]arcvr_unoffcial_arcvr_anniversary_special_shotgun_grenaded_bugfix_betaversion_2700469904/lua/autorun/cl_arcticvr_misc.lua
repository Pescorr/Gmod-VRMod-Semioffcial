concommand.Add("arcticvr_printvmbones", function(ply)
    local vm = ply:GetViewModel()

    print("SWEP.BoneIndices = {")
    for i = 0, (vm:GetBoneCount() - 1) do
        print(" " .. vm:GetBoneName(i) .. " = " .. tostring(i) .. ",")
    end
    print("}")
end)

concommand.Add("arcticvr_printmats", function(ply)
    PrintTable(ply:GetViewModel():GetMaterials())
end)

concommand.Add("arcticvr_printgvr", function(ply)
    PrintTable(g_VR)
end)


CreateClientConVar("arcticvr_2h_sens", "0.5")
CreateClientConVar("arcticvr_virtualstock", "1")
CreateClientConVar("arcticvr_headpouch", "0")
CreateClientConVar("arcticvr_hybridpouch", "0")
CreateClientConVar("arcticvr_infpouch", "0")
CreateClientConVar("arcticvr_defpouchdist", "16.0")
CreateClientConVar("arcticvr_headpouchdist", "8.0")
CreateClientConVar("arcticvr_hybridpouchdist", "13.5")
CreateClientConVar("arcticvr_gunmelee_damage","10.0")
CreateClientConVar("arcticvr_gunmelee_velthreshold","2")
CreateClientConVar("arcticvr_gunmelee_Delay","0.03")
CreateClientConVar("arcticvr_grip_alternative_mode","0")
CreateClientConVar("arcticvr_slide_magnification","1.0")
-- CreateClientConVar("arcticvr_weppouchsize","13.5")
-- CreateClientConVar("arcticvr_weppouch","1")