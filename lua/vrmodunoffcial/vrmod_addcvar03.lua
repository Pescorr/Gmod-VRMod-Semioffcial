if CLIENT then

-- Module for Left Grip Mode in VRMod
local LeftGripMode = {}

-- Define a new ConVar
local leftGripModeActive = CreateClientConVar("vrmod_leftgripmode", "0",true, FCVAR_ARCHIVE, "Enable or disable left grip mode in VRMod")

-- Function to update the view model based on the left grip mode
function LeftGripMode.UpdateViewModel(g_VR, netFrame)
    -- Check if the left grip mode is active
    if leftGripModeActive:GetBool() then
        -- Left grip mode logic goes here
        if g_VR.currentvmi then
            local pos, ang = LocalToWorld(g_VR.currentvmi.offsetPos, g_VR.currentvmi.offsetAng, g_VR.tracking.pose_righthand.pos, g_VR.tracking.pose_lefthand.ang)
            g_VR.viewModelPos = pos
            g_VR.viewModelAng = ang
        end

        if IsValid(g_VR.viewModel) then
            if not g_VR.usingWorldModels then
                g_VR.viewModel:SetPos(g_VR.viewModelPos)
                g_VR.viewModel:SetAngles(g_VR.viewModelAng)
                g_VR.viewModel:SetupBones()

                -- Override hand pose in net frame
                if netFrame then
                    local b = g_VR.viewModel:LookupBone("ValveBiped.Bip01_R_Hand")
                    if b then
                        local mtx = g_VR.viewModel:GetBoneMatrix(b)
                        netFrame.righthandPos = mtx:GetTranslation()
                        netFrame.righthandAng = mtx:GetAngles() - Angle(0, 0, 180)
                    end

                    local c = g_VR.viewModel:LookupBone("ValveBiped.Bip01_L_Hand")
                    if c then
                        local mtxl = g_VR.viewModel:GetBoneMatrix(c)
                        netFrame.lefthandPos = mtxl:GetTranslation()
                        netFrame.lefthandAng = mtxl:GetAngles() - Angle(0, 0, 0)
                    end
                end
            end

            g_VR.viewModelMuzzle = g_VR.viewModel:GetAttachment(1)
        end
    end
end



	function VRUtilRemoveHooker()
		hook.Remove("PreDrawTranslucentRenderables", "vrmod_floatinghands_dummymirror")
		hook.Remove("RenderScene", "vrutil_hook_renderscene")
		hook.Remove("PreDrawViewModel", "vrutil_hook_predrawviewmodel")
		hook.Remove("DrawPhysgunBeam", "vrutil_hook_drawphysgunbeam")
		hook.Remove("PreDrawHalos", "vrutil_hook_predrawhalos")
		hook.Remove("EntityFireBullets", "vrutil_hook_entityfirebullets")
		hook.Remove("Tick", "vrutil_hook_tick")
		hook.Remove("PostDrawSkyBox", "vrutil_hook_postdrawskybox")
		hook.Remove("CalcView", "vrutil_hook_calcview")
		hook.Remove("PostDrawTranslucentRenderables", "vr_laserpointer")
		hook.Remove("CalcViewModelView", "vrutil_hook_calcviewmodelview")
		hook.Remove("PostDrawTranslucentRenderables", "vrutil_hook_drawplayerandviewmodel")
		hook.Remove("PreDrawPlayerHands", "vrutil_hook_predrawplayerhands")
		hook.Remove("PreDrawViewModel", "vrutil_hook_predrawviewmodel")
		hook.Remove("ShouldDrawLocalPlayer", "vrutil_hook_shoulddrawlocalplayer")
		-- VRMod Startup Custom Actions
		hook.Remove("CreateMove", "vrmod_startup_loadcustomactions") -- &#8203;``【oaicite:12】``&#8203;
		-- Drawing Local Player and Laser Pointer
		hook.Remove("ShouldDrawLocalPlayer", "vrutil_hook_shoulddrawlocalplayer") -- &#8203;``【oaicite:11】``&#8203;
		hook.Remove("PostDrawTranslucentRenderables", "vr_laserpointer") -- &#8203;``【oaicite:10】``&#8203;
		-- Blocking GMOD Default Pickup for VR Players
		hook.Remove("AllowPlayerPickup", "vrmod") -- &#8203;``【oaicite:9】``&#8203;
		-- VRMod Start and Exit Hooks for Derma Popups
		hook.Remove("VRMod_Start", "dermapopups") -- &#8203;``【oaicite:8】``&#8203;
		hook.Remove("VRMod_Exit", "dermapopups") -- &#8203;``【oaicite:7】``&#8203;
		-- VRMod Shutdown Hook
		-- Starting Hands Only in VRMod
		hook.Remove("VRMod_Start", "vrmod_starthandsonly") -- &#8203;``【oaicite:5】``&#8203;
		-- 3D Audio Fix
		hook.Remove("CalcView", "vrutil_hook_calcview") -- &#8203;``【oaicite:3】``&#8203;
		-- VRMod Pickup and Exit Hooks
		hook.Remove("VRMod_Exit", "pickupreset") -- &#8203;``【oaicite:2】``&#8203;
		-- VRMod Exit Vehicle Hook
		hook.Remove("VRMod_ExitVehicle", "vrmod_floatinghands") -- &#8203;``【oaicite:1】``&#8203;
		-- Stopping Hands Only in VRMod
		hook.Remove("VRMod_Exit", "vrmod_stophandsonly") -- &#8203;``【oaicite:0】``&#8203;
		-- VRMod Character System Start and Stop
		hook.Remove("VRMod_Start", "vrmod_characterstart") -- &#8203;``【oaicite:11】``&#8203;
		hook.Remove("VRMod_Exit", "vrmod_characterstop") -- &#8203;``【oaicite:10】``&#8203;
		-- VRMod Network Hooks for Player Death and Spawn
		hook.Remove("PlayerDeath", "vrutil_hook_playerdeath") -- &#8203;``【oaicite:9】``&#8203;
		hook.Remove("PlayerSpawn", "vrutil_hook_playerspawn") -- &#8203;``【oaicite:8】``&#8203;
		-- VRMod Full Body Tracking (FBT) Test Input and Show Trackers
		hook.Remove("PostDrawTranslucentRenderables", "fbt_test_showtrackers") -- &#8203;``【oaicite:7】``&#8203;
		hook.Remove("VRMod_Input", "fbt_test_input") -- &#8203;``【oaicite:6】``&#8203;
		-- VRMod Flashlight
		hook.Remove("VRMod_Exit", "flashlight") -- &#8203;``【oaicite:5】``&#8203;
		hook.Remove("PlayerSwitchFlashlight", "vrmod_flashlight") -- &#8203;``【oaicite:4】``&#8203;
		-- VRMod UI Height Adjustment Menu Input
		hook.Remove("VRMod_Input", "vrmodheightmenuinput") -- &#8203;``【oaicite:3】``&#8203;
		hook.Remove("VRMod_Start", "vrmod_OpenHeightMenuOnStartup") -- &#8203;``【oaicite:2】``&#8203;
		-- VRMod Character System Pre and Post Player Draw
		hook.Remove("PrePlayerDraw", "vrutil_hook_preplayerdraw") -- &#8203;``【oaicite:1】``&#8203;
		hook.Remove("PostPlayerDraw", "vrutil_hook_postplayerdraw") -- &#8203;``【oaicite:0】``&#8203;
		-- VRMod HUD Start and Exit Hooks
		hook.Remove("VRMod_Menu", "vrmod_hud") -- &#8203;``【oaicite:8】``&#8203;
		hook.Remove("VRMod_Start", "hud") -- &#8203;``【oaicite:7】``&#8203;
		hook.Remove("VRMod_Exit", "hud") -- &#8203;``【oaicite:6】``&#8203;
		-- VRMod Flashlight Exit Hook and Player Switch Flashlight
		hook.Remove("VRMod_Exit", "flashlight") -- &#8203;``【oaicite:5】``&#8203;
		hook.Remove("PlayerSwitchFlashlight", "vrmod_flashlight") -- &#8203;``【oaicite:4】``&#8203;
		-- VRMod Pickup for ArcVR Start Hook
		hook.Remove("VRMod_Start", "arc_pickup_compat") -- &#8203;``【oaicite:3】``&#8203;
		-- VRMod Locomotion PreRender Hooks
		hook.Remove("VRMod_PreRender", "teleport") -- Lefthand, Righthand, and General&#8203;``【oaicite:2】``&#8203;&#8203;``【oaicite:1】``&#8203;&#8203;``【oaicite:0】``&#8203;
		-- VRMod HUD Start and Exit Hooks
		hook.Remove("VRMod_Menu", "vrmod_hud") -- &#8203;``【oaicite:8】``&#8203;
		hook.Remove("VRMod_Start", "hud") -- &#8203;``【oaicite:7】``&#8203;
		hook.Remove("VRMod_Exit", "hud") -- &#8203;``【oaicite:6】``&#8203;
		-- VRMod Flashlight Exit Hook and Player Switch Flashlight
		hook.Remove("VRMod_Exit", "flashlight") -- &#8203;``【oaicite:5】``&#8203;
		hook.Remove("PlayerSwitchFlashlight", "vrmod_flashlight") -- &#8203;``【oaicite:4】``&#8203;
		-- VRMod Pickup for ArcVR Start Hook
		hook.Remove("VRMod_Start", "arc_pickup_compat") -- &#8203;``【oaicite:3】``&#8203;
		-- VRMod Locomotion PreRender Hooks
		hook.Remove("VRMod_PreRender", "teleport") -- Lefthand, Righthand, and General&#8203;``【oaicite:2】``&#8203;&#8203;``【oaicite:1】``&#8203;&#8203;``【oaicite:0】``&#8203;
		-- VRE Simfphys Remix Input and Overrides Hooks
		hook.Remove("VRE_simphys_Overrides", "vre_simfphysfix_override") -- &#8203;``【oaicite:17】``&#8203;
		hook.Remove("VRMod_Input", "vre_onlocomotion_action") -- &#8203;``【oaicite:16】``&#8203;
		-- VRMod HUD Menu, Start, and Exit Hooks
		hook.Remove("VRMod_Menu", "vrmod_hud") -- &#8203;``【oaicite:15】``&#8203;
		hook.Remove("VRMod_Start", "hud") -- &#8203;``【oaicite:14】``&#8203;
		hook.Remove("VRMod_Exit", "hud") -- &#8203;``【oaicite:13】``&#8203;
		-- VRMod Seated Mode Menu and Start Hooks
		hook.Remove("VRMod_Menu", "vrmod_n_seated") -- &#8203;``【oaicite:12】``&#8203;
		hook.Remove("VRMod_Start", "seatedmode") -- &#8203;``【oaicite:11】``&#8203;
		-- VRMod Default Pickup Block
		hook.Remove("AllowPlayerPickup", "vrmod") -- &#8203;``【oaicite:10】``&#8203;
		-- VRMod Flashlight Exit and Player Switch Flashlight Hooks
		hook.Remove("VRMod_Exit", "flashlight") -- &#8203;``【oaicite:9】``&#8203;
		hook.Remove("PlayerSwitchFlashlight", "vrmod_flashlight") -- &#8203;``【oaicite:8】``&#8203;
		-- VRMod ArcVR Pickup Compatibility Start Hook
		hook.Remove("VRMod_Start", "arc_pickup_compat") -- &#8203;``【oaicite:7】``&#8203;
		-- VRMod Halos Exit Hook
		hook.Remove("VRMod_Exit", "halos") -- &#8203;``【oaicite:6】``&#8203;
		-- VRMod VRE Add Menu PreRender Hook
		hook.Remove("PreRender", "vre_renderaddvrmenumenu") -- &#8203;``【oaicite:5】``&#8203;
		-- VRMod Seated Mode Tracking Hook
		hook.Remove("VRMod_Tracking", "seatedmode") -- &#8203;``【oaicite:4】``&#8203;
		-- VRMod Player Model Change InitPostEntity Hook
		hook.Remove("InitPostEntity", "vrmod_pmchange") -- &#8203;``【oaicite:3】``&#8203;
		-- VRMod Menu Show On Startup and Populate Tool Menu Hooks
		hook.Remove("CreateMove", "vrmod_showonstartup") -- &#8203;``【oaicite:2】``&#8203;
		hook.Remove("PopulateToolMenu", "vrmod_addspawnmenu") -- &#8203;``【oaicite:1】``&#8203;
		-- VRMod UI Chat ChatText Hook
		hook.Remove("ChatText", "vrutil_hook_chattext") -- &#8203;``【oaicite:0】``&#8203;
	end

	concommand.Add(
		"vrmod_dev_removehooker",
		function(ply, cmd, args)
			VRUtilClientExit()
			VRUtilRemoveHooker()
		end
	)
end