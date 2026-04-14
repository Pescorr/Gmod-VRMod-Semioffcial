-- vrmod_desktop_mirror_cl.lua
-- VR Desktop Mirror: Captures the Gmod desktop framebuffer and displays it
-- as an interactive flat panel in VR, enabling operation of any desktop UI.
--
-- Capture: render.CopyRenderTargetToTexture (primary) or
-- UpdateScreenEffectTexture + surface.DrawTexturedRect (fallback)
--
-- Display: cam.Start3D2D in PostDrawTranslucentRenderables (same as VRUtilMenuOpen)
-- Input: input.SetCursorPos + gui.InternalMousePressed (same as vrmod_ui.lua)
--
-- Phase 2: Realtime capture, dual-hand cursor, 4 attachment modes, viewmodel-style offset

if SERVER then return end

-- ============================================================================
-- ConVars
-- ============================================================================
local cvEnabled = CreateClientConVar("vrmod_desktop_mirror", "0", true, false,
    "Enable VR Desktop Mirror", 0, 1)
local cvScale = CreateClientConVar("vrmod_desktop_mirror_scale", "0.050", true, false,
    "Desktop mirror world scale", 0.005, 0.1)
local cvDistance = CreateClientConVar("vrmod_desktop_mirror_distance", "60", true, false,
    "Desktop mirror distance from origin (units)", 10, 200)
-- Phase 2 ConVars
local cvRealtime = CreateClientConVar("vrmod_desktop_mirror_realtime", "1", true, false,
    "Enable realtime capture mode", 0, 1)
local cvInterval = CreateClientConVar("vrmod_desktop_mirror_interval", "0.01", true, false,
    "Realtime capture interval in seconds", 0.01, 5.0)
local cvAttach = CreateClientConVar("vrmod_desktop_mirror_attach", "3", true, false,
    "Attachment mode: 1=left hand, 2=right hand, 3=HMD follow, 4=world fixed", 1, 4)
-- Hand/HMD attachment offset (viewmodel-style position/rotation adjustment)
local cvPosX = CreateClientConVar("vrmod_desktop_mirror_pos_x", "50", true, false,
    "Attachment local X offset (forward)", -50, 50)
local cvPosY = CreateClientConVar("vrmod_desktop_mirror_pos_y", "0", true, false,
    "Attachment local Y offset (right)", -50, 50)
local cvPosZ = CreateClientConVar("vrmod_desktop_mirror_pos_z", "-27.5", true, false,
    "Attachment local Z offset (up)", -50, 50)
local cvAngP = CreateClientConVar("vrmod_desktop_mirror_ang_p", "-180", true, false,
    "Attachment local pitch", -180, 180)
local cvAngY = CreateClientConVar("vrmod_desktop_mirror_ang_y", "94", true, false,
    "Attachment local yaw", -180, 180)
local cvAngR = CreateClientConVar("vrmod_desktop_mirror_ang_r", "-134.2", true, false,
    "Attachment local roll", -180, 180)
-- V2: Mirror Mode — replace VR UI interaction with desktop mirror cursor/input
local cvMirrorMode = CreateClientConVar("vrmod_desktop_mirror_mode", "0", true, false,
    "Mirror Mode: replace VR UI interaction with desktop mirror", 0, 1)
-- V2: Transparent Input — don't block primaryfire/secondaryfire when menu is focused
local cvTransparentInput = CreateClientConVar("vrmod_desktop_mirror_transparent_input", "0", true, false,
    "Transparent Input: allow shooting/actions while VR menu is open in mirror mode", 0, 1)

-- ============================================================================
-- Version detection: semiofficial vs original VRMod
-- ============================================================================
-- g_VR.moduleSemiVersion: >= 100 on semiofficial (v103+), 0 on original, nil if not loaded
-- V2 features (Mirror Mode, auto-start, selective mirror) require semiofficial infrastructure:
--   - g_VR.desktopMirrorMode flag (read by vrmod_ui.lua to bypass VR cursor)
--   - g_VR.desktopMirrorTransparentInput flag (read by vrmod_input.lua)
--   - vrmod_unoff_desktop_ui_mirror ConVar (registered by semiofficial's vrmod_ui.lua)
--   - g_VR.desktopPopupCount (set by semiofficial's vrmod_dermapopups.lua)
local function IsSemiofficial()
    return g_VR ~= nil
       and g_VR.moduleSemiVersion ~= nil
       and g_VR.moduleSemiVersion >= 100
end

-- ============================================================================
-- State
-- ============================================================================
local mirrorActive = false
local mirrorAutoStarted = false  -- true when auto-started by vrmod_ui_desktop_mirror

-- Render target and material
local captureRT = nil
local captureMat = nil
local captureWidth = 0
local captureHeight = 0

-- Capture scheduling
local captureRequested = false
local lastCaptureTime = 0
local CAPTURE_COOLDOWN = 0.05 -- 50ms minimum between captures

-- Cursor / interaction
local mirrorFocused = false
local mirrorCursorX = -1
local mirrorCursorY = -1
local mirrorCursorWorldPos = nil
local screenClickerEnabled = false

-- Phase 2: Dual-hand cursor
local activeHand = nil  -- "left" / "right" / nil
local activeHandDist = 0

-- Phase 2: World-fixed mode initial yaw
local startYaw = nil

-- V2: Saved desktop_ui_mirror value for restoration on mirror mode off
local prevDesktopUiMirrorValue = nil

-- Beam material for cursor laser
local beamRT = nil
local beamMat = nil

-- ============================================================================
-- V2: Mirror Mode helpers
-- ============================================================================
-- Force vrmod_unoff_desktop_ui_mirror=1 for mirror mode (panels must render on desktop)
local function ForceDesktopUiMirror()
    local cv = GetConVar("vrmod_unoff_desktop_ui_mirror")
    if cv and cv:GetInt() ~= 1 then
        prevDesktopUiMirrorValue = cv:GetInt()
        RunConsoleCommand("vrmod_unoff_desktop_ui_mirror", "1")
    end
end

local function RestoreDesktopUiMirror()
    if prevDesktopUiMirrorValue ~= nil then
        RunConsoleCommand("vrmod_unoff_desktop_ui_mirror", tostring(prevDesktopUiMirrorValue))
        prevDesktopUiMirrorValue = nil
    end
end

-- Update transparent input flag (only active when mirror mode is also active)
local function UpdateTransparentInputFlag()
    if g_VR.desktopMirrorMode and cvTransparentInput:GetBool() then
        g_VR.desktopMirrorTransparentInput = true
    else
        g_VR.desktopMirrorTransparentInput = nil
    end
end

-- ============================================================================
-- RT and Material Creation
-- ============================================================================
local function CreateCaptureResources()
    local w, h = ScrW(), ScrH()
    if captureRT and captureWidth == w and captureHeight == h then
        return true -- Already valid
    end

    captureWidth = w
    captureHeight = h

    -- RT name includes dimensions (L51: GetRenderTarget caches by name,
    -- different sizes need different names)
    local rtName = "vrmod_rt_desktop_mirror_" .. w .. "x" .. h
    captureRT = GetRenderTarget(rtName, w, h, false)
    if not captureRT then
        print("[VRMod Desktop Mirror] ERROR: Failed to create render target")
        return false
    end

    -- Material referencing the RT
    local matName = "vrmod_mat_desktop_mirror_" .. w .. "x" .. h
    captureMat = Material("!" .. matName)
    if not captureMat or captureMat:IsError() then
        captureMat = CreateMaterial(matName, "UnlitGeneric", {
            ["$basetexture"] = captureRT:GetName(),
            ["$translucent"] = 0,
        })
    end

    -- Beam material for cursor laser (green to distinguish from menu's blue)
    if not beamRT then
        beamRT = GetRenderTarget("vrmod_rt_dm_beam", 64, 64, false)
        if beamRT then
            beamMat = CreateMaterial("vrmod_mat_dm_beam", "UnlitGeneric", {
                ["$basetexture"] = beamRT:GetName(),
                ["$ignorez"] = 1,
            })
            render.PushRenderTarget(beamRT)
            render.Clear(0, 255, 128, 255) -- Cyan-green
            render.PopRenderTarget()
        end
    end

    -- Clear the capture RT to black
    render.PushRenderTarget(captureRT)
    render.Clear(0, 0, 0, 255)
    render.PopRenderTarget()

    return true
end

-- ============================================================================
-- Capture: Screenshot the desktop framebuffer into our RT
-- ============================================================================

-- Capture strategy: try methods in order of reliability
-- Method 1: render.CopyRenderTargetToTexture (direct GPU blit, simplest)
-- Method 2: UpdateScreenEffectTexture + UnlitGeneric material + surface.DrawTexturedRect
--           (all standard GLua API calls, guaranteed to work)
local captureMethod = nil -- auto-detect on first call
local screenCopyMat = nil -- lazy-init material for method 2

local function DoCapture()
    if not captureRT then return end

    local now = RealTime()
    if now - lastCaptureTime < CAPTURE_COOLDOWN then
        -- Too soon; keep the request flag so next frame tries again
        return
    end

    local ok, err

    -- Method 1: Direct framebuffer → RT copy (preferred, single GPU call)
    if captureMethod ~= 2 then
        ok, err = pcall(function()
            render.CopyRenderTargetToTexture(captureRT)
        end)
        if ok then
            captureMethod = 1
            captureRequested = false
            lastCaptureTime = now
            return
        end
        -- Method 1 failed on first attempt, log and fall through
        if captureMethod == nil then
            print("[VRMod Desktop Mirror] CopyRenderTargetToTexture failed, trying fallback: " .. tostring(err))
        end
    end

    -- Method 2: Screen effect texture blit via surface draw
    -- Uses only well-known, stable GLua APIs
    ok, err = pcall(function()
        render.UpdateScreenEffectTexture()
        -- Create material from screen effect texture (once)
        if not screenCopyMat then
            local texName = render.GetScreenEffectTexture():GetName()
            screenCopyMat = CreateMaterial("vrmod_dm_screencopy", "UnlitGeneric", {
                ["$basetexture"] = texName,
                ["$translucent"] = 0,
            })
        end
        render.PushRenderTarget(captureRT)
        cam.Start2D()
        render.Clear(0, 0, 0, 255)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.SetMaterial(screenCopyMat)
        surface.DrawTexturedRect(0, 0, captureWidth, captureHeight)
        cam.End2D()
        render.PopRenderTarget()
    end)

    if ok then
        captureMethod = 2
        captureRequested = false
        lastCaptureTime = now
    else
        print("[VRMod Desktop Mirror] Capture error (both methods failed): " .. tostring(err))
    end
end

local function RequestCapture()
    captureRequested = true
end

local function RequestDelayedCapture(delay)
    local timerName = "vrmod_dm_delayed_" .. tostring(delay)
    timer.Create(timerName, delay, 1, function()
        if mirrorActive then
            RequestCapture()
        end
    end)
end

-- ============================================================================
-- Display: Render the captured RT as a flat panel in VR
-- ============================================================================

-- Phase 2: 4 attachment modes via LocalToWorld (vrmod_ui.lua L86-94 pattern)
local function GetMirrorTransform()
    local mode = cvAttach:GetInt()
    local scale = cvScale:GetFloat()
    local W, H = captureWidth, captureHeight

    if mode == 1 then -- Left hand attachment
        if not g_VR.tracking or not g_VR.tracking.pose_lefthand then
            return nil, nil, nil
        end
        local basePos = g_VR.tracking.pose_lefthand.pos
        local baseAng = g_VR.tracking.pose_lefthand.ang
        local localPos = Vector(cvPosX:GetFloat(), cvPosY:GetFloat(), cvPosZ:GetFloat())
        local localAng = Angle(cvAngP:GetFloat(), cvAngY:GetFloat(), cvAngR:GetFloat())
        local wPos, wAng = LocalToWorld(localPos, localAng, basePos, baseAng)
        wPos = wPos + wAng:Forward() * (W * scale * -0.5)
                    + wAng:Right() * (H * scale * -0.5)
        return wPos, wAng, scale

    elseif mode == 2 then -- Right hand attachment
        if not g_VR.tracking or not g_VR.tracking.pose_righthand then
            return nil, nil, nil
        end
        local basePos = g_VR.tracking.pose_righthand.pos
        local baseAng = g_VR.tracking.pose_righthand.ang
        local localPos = Vector(cvPosX:GetFloat(), cvPosY:GetFloat(), cvPosZ:GetFloat())
        local localAng = Angle(cvAngP:GetFloat(), cvAngY:GetFloat(), cvAngR:GetFloat())
        local wPos, wAng = LocalToWorld(localPos, localAng, basePos, baseAng)
        wPos = wPos + wAng:Forward() * (W * scale * -0.5)
                    + wAng:Right() * (H * scale * -0.5)
        return wPos, wAng, scale

    elseif mode == 3 then -- HMD follow
        if not g_VR.tracking or not g_VR.tracking.hmd then
            return nil, nil, nil
        end
        local basePos = g_VR.tracking.hmd.pos
        local baseAng = g_VR.tracking.hmd.ang
        local localPos = Vector(cvPosX:GetFloat(), cvPosY:GetFloat(), cvPosZ:GetFloat())
        local localAng = Angle(cvAngP:GetFloat(), cvAngY:GetFloat(), cvAngR:GetFloat())
        local wPos, wAng = LocalToWorld(localPos, localAng, basePos, baseAng)
        wPos = wPos + wAng:Forward() * (W * scale * -0.5)
                    + wAng:Right() * (H * scale * -0.5)
        return wPos, wAng, scale

    else -- mode == 4: World fixed (Phase 1 original, unchanged)
        if not g_VR.origin then return nil, nil, nil end
        local distance = cvDistance:GetFloat()
        local baseYaw = startYaw or 0
        if g_VR.originAngle and not startYaw then
            baseYaw = g_VR.originAngle.y
        end
        local ang = Angle(0, baseYaw - 90, 90)
        local forward = Angle(0, baseYaw, 0):Forward()
        local pos = g_VR.origin + forward * distance + Vector(0, 0, 50)
        local halfScale = scale * 0.5
        pos = pos + ang:Forward() * (captureWidth * -halfScale)
                  + ang:Right() * (captureHeight * -halfScale)
        return pos, ang, scale
    end
end

-- Phase 2: Raycast a single hand against the mirror panel plane
-- Same math as vrmod_ui.lua L109-135
-- Returns: hit, cursorX, cursorY, distance, hitWorldPos
local function RaycastHand(handPoseKey, panelPos, panelAng, scale, W, H)
    if not g_VR.tracking or not g_VR.tracking[handPoseKey] then
        return false, -1, -1, 99999, nil
    end

    local startPos = g_VR.tracking[handPoseKey].pos
    local dir = g_VR.tracking[handPoseKey].ang:Forward()
    local normal = panelAng:Up()

    local A = normal:Dot(dir)
    if A >= 0 then return false, -1, -1, 99999, nil end

    local B = normal:Dot(panelPos - startPos)
    if B >= 0 then return false, -1, -1, 99999, nil end

    local dist = B / A
    if dist > 500 then return false, -1, -1, 99999, nil end

    local hitPos = startPos + dir * dist
    local tp = WorldToLocal(hitPos, Angle(0, 0, 0), panelPos, panelAng)
    local cx = tp.x * (1 / scale)
    local cy = -tp.y * (1 / scale) -- Negate Y: local Y is Right, screen Y is -Right

    if cx > 0 and cy > 0 and cx < W and cy < H then
        return true, cx, cy, dist, hitPos
    end

    return false, -1, -1, 99999, nil
end

local function DrawMirrorPanel()
    if not g_VR or not g_VR.active then return end
    -- Explicit false check: semiofficial sets isVRRendering=false during desktop pass (skip).
    -- Original VRMod: isVRRendering=nil (not false), so panel draws on all passes (acceptable).
    if g_VR.isVRRendering == false then return end
    if not captureMat then return end

    local pos, ang, scale = GetMirrorTransform()
    if not pos then return end -- Tracking data not ready

    -- Draw the panel texture
    cam.IgnoreZ(true)
    cam.Start3D2D(pos, ang, scale)

    -- Background (slightly dark in case RT is transparent)
    surface.SetDrawColor(20, 20, 20, 255)
    surface.DrawRect(0, 0, captureWidth, captureHeight)

    -- The captured desktop image
    surface.SetDrawColor(255, 255, 255, 255)
    surface.SetMaterial(captureMat)
    surface.DrawTexturedRect(0, 0, captureWidth, captureHeight)

    -- Cursor crosshair (when focused)
    if mirrorFocused and mirrorCursorX >= 0 and mirrorCursorY >= 0 then
        local cx, cy = mirrorCursorX, mirrorCursorY
        -- White crosshair with dark outline for visibility
        surface.SetDrawColor(0, 0, 0, 200)
        surface.DrawRect(cx - 12, cy - 2, 24, 5)
        surface.DrawRect(cx - 2, cy - 12, 5, 24)
        surface.SetDrawColor(255, 255, 255, 255)
        surface.DrawRect(cx - 10, cy - 1, 20, 3)
        surface.DrawRect(cx - 1, cy - 10, 3, 20)
    end

    -- Border: cyan when focused, gray when not
    if mirrorFocused then
        surface.SetDrawColor(0, 255, 200, 220)
    else
        surface.SetDrawColor(100, 100, 100, 120)
    end
    surface.DrawOutlinedRect(0, 0, captureWidth, captureHeight, 3)

    cam.End3D2D()
    cam.IgnoreZ(false)

    -- ================================================================
    -- Phase 2: Dual-hand cursor raycast
    -- Both hands raycast; closer hand wins
    -- Hand attached to panel is excluded (can't point at own hand)
    -- VR native menus take priority: skip raycast when menuFocus is set
    -- ================================================================
    mirrorFocused = false
    mirrorCursorX = -1
    mirrorCursorY = -1
    mirrorCursorWorldPos = nil
    activeHand = nil

    -- VR native menus (keyboard, quickmenu etc.) take priority over mirror interaction
    if g_VR.menuFocus then return end

    local attachMode = cvAttach:GetInt()

    -- Left hand raycast (excluded when panel attached to left hand)
    local lhit, lcx, lcy, ldist, lhitPos = false, -1, -1, 99999, nil
    if attachMode ~= 1 then
        lhit, lcx, lcy, ldist, lhitPos = RaycastHand(
            "pose_lefthand", pos, ang, scale, captureWidth, captureHeight)
    end

    -- Right hand raycast (excluded when panel attached to right hand)
    local rhit, rcx, rcy, rdist, rhitPos = false, -1, -1, 99999, nil
    if attachMode ~= 2 then
        rhit, rcx, rcy, rdist, rhitPos = RaycastHand(
            "pose_righthand", pos, ang, scale, captureWidth, captureHeight)
    end

    -- Pick the closer hand
    if lhit and rhit then
        if ldist < rdist then
            activeHand = "left"
        else
            activeHand = "right"
        end
    elseif lhit then
        activeHand = "left"
    elseif rhit then
        activeHand = "right"
    end

    -- Apply the winner
    if activeHand == "left" then
        mirrorFocused = true
        mirrorCursorX = lcx
        mirrorCursorY = lcy
        mirrorCursorWorldPos = lhitPos
        activeHandDist = ldist
    elseif activeHand == "right" then
        mirrorFocused = true
        mirrorCursorX = rcx
        mirrorCursorY = rcy
        mirrorCursorWorldPos = rhitPos
        activeHandDist = rdist
    end

    -- Draw beam + position desktop cursor
    if mirrorFocused and mirrorCursorWorldPos then
        local handPose = activeHand == "left" and "pose_lefthand" or "pose_righthand"
        if beamMat and g_VR.tracking[handPose] then
            local beamColor = activeHand == "left"
                and Color(128, 200, 0) or Color(0, 255, 128)
            render.SetMaterial(beamMat)
            render.DrawBeam(
                g_VR.tracking[handPose].pos, mirrorCursorWorldPos,
                0.1, 0, 1, beamColor)
        end
        input.SetCursorPos(math.floor(mirrorCursorX), math.floor(mirrorCursorY))
    end
end

-- ============================================================================
-- Input: Forward VR controller actions to desktop mouse events
-- Phase 2: Dual-hand support (left trigger = boolean_left_pickup)
-- VR native menus take priority: yield input when menuFocus is set
-- ============================================================================
local function HandleInput(action, pressed)
    if not mirrorActive then return end
    if not mirrorFocused then return end
    -- VR native menus take priority: yield input to VR UI system (defense-in-depth)
    if g_VR.menuFocus then return end

    -- Determine if this is a click from the active hand's trigger
    local isClick = false
    if activeHand == "right" and action == "boolean_primaryfire" then
        isClick = true
    elseif activeHand == "left" and action == "boolean_left_primaryfire" then
        isClick = true
    end

    -- Left click (from either hand's trigger)
    if isClick then
        if not screenClickerEnabled then
            gui.EnableScreenClicker(true)
            screenClickerEnabled = true
        end
        if pressed then
            gui.InternalMousePressed(MOUSE_LEFT)
            RequestCapture()
            RequestDelayedCapture(0.5)
        else
            gui.InternalMouseReleased(MOUSE_LEFT)
            RequestCapture()
            RequestDelayedCapture(0.3)
        end
        return false -- Block default action
    end

    -- Secondary fire → Right click (works from either hand when focused)
    if action == "boolean_secondaryfire" then
        if not screenClickerEnabled then
            gui.EnableScreenClicker(true)
            screenClickerEnabled = true
        end
        if pressed then
            gui.InternalMousePressed(MOUSE_RIGHT)
            RequestCapture()
            RequestDelayedCapture(0.5)
        else
            gui.InternalMouseReleased(MOUSE_RIGHT)
            RequestCapture()
        end
        return false
    end

    -- Back → Scroll down
    if action == "boolean_back" then
        if pressed then
            gui.InternalMouseWheeled(-2)
            gui.InternalMousePressed(MOUSE_WHEEL_DOWN)
        end
        RequestCapture()
        RequestDelayedCapture(0.3)
        return false
    end

    -- Forward → Scroll up
    if action == "boolean_forword" then
        if pressed then
            gui.InternalMouseWheeled(2)
            gui.InternalMousePressed(MOUSE_WHEEL_UP)
        end
        RequestCapture()
        RequestDelayedCapture(0.3)
        return false
    end

    -- Reload → Middle click
    if action == "boolean_reload" then
        if pressed then
            gui.InternalMousePressed(MOUSE_MIDDLE)
        else
            gui.InternalMouseReleased(MOUSE_MIDDLE)
        end
        RequestCapture()
        return false
    end
end

-- ============================================================================
-- Lifecycle: Start / Stop the mirror system
-- ============================================================================
local function Start()
    if mirrorActive then return end
    if not g_VR or not g_VR.active then return end

    if not CreateCaptureResources() then
        print("[VRMod Desktop Mirror] Failed to create resources, aborting")
        return
    end

    mirrorActive = true
    captureRequested = true -- Trigger initial capture
    screenClickerEnabled = false
    activeHand = nil

    -- V2: Mirror Mode — set flag and force desktop panel visibility (semiofficial only)
    if IsSemiofficial() then
        if cvMirrorMode:GetBool() then
            g_VR.desktopMirrorMode = true
            ForceDesktopUiMirror()
        end
        UpdateTransparentInputFlag()
    end

    -- Record initial HMD yaw for world-fixed mode
    if g_VR.tracking and g_VR.tracking.hmd then
        startYaw = g_VR.tracking.hmd.ang.y
    elseif g_VR.originAngle then
        startYaw = g_VR.originAngle.y
    else
        startYaw = 0
    end

    -- Capture hook: PostRenderVGUI fires AFTER all VGUI rendering (including DMenu/DComboBox
    -- draw-on-top panels). DrawOverlay fires BEFORE these, so DMenu was never captured.
    -- The g_VR.isVRRendering guard ensures we only capture the desktop framebuffer,
    -- not the VR eye rendering pass
    hook.Add("PostRenderVGUI", "vrmod_desktop_mirror_capture", function()
        if not mirrorActive then return end
        if g_VR and g_VR.isVRRendering then return end

        -- Phase 2: Realtime capture mode
        if cvRealtime:GetBool() then
            local now = RealTime()
            if now - lastCaptureTime >= cvInterval:GetFloat() then
                captureRequested = true
            end
        end

        if not captureRequested then return end
        DoCapture()
    end)

    -- Display hook: renders the mirror panel during VR eye rendering
    -- Must be inside PostDrawTranslucentRenderables (same as VRUtilMenuOpen)
    hook.Add("PostDrawTranslucentRenderables", "vrmod_desktop_mirror_draw",
        function(bDrawingDepth, bDrawingSkybox)
            if bDrawingSkybox then return end
            if not mirrorActive then return end
            DrawMirrorPanel()
        end
    )

    -- Input hook: forward VR controller actions to desktop mouse
    hook.Add("VRMod_Input", "vrmod_desktop_mirror_input", function(action, pressed)
        return HandleInput(action, pressed)
    end)

    -- Think hook: manage screen clicker state
    -- Disable clicker when mirror loses focus to avoid interfering with gameplay
    hook.Add("Think", "vrmod_desktop_mirror_think", function()
        if not mirrorActive then return end
        if screenClickerEnabled and not mirrorFocused then
            gui.EnableScreenClicker(false)
            screenClickerEnabled = false
        end
        -- V2 Failsafe: ensure desktopMirrorMode flag matches actual state (semiofficial only)
        if IsSemiofficial() and g_VR.desktopMirrorMode and not cvMirrorMode:GetBool() then
            g_VR.desktopMirrorMode = nil
            g_VR.desktopMirrorTransparentInput = nil
        end
    end)

    print("[VRMod Desktop Mirror] Started (" .. captureWidth .. "x" .. captureHeight .. ")")
end

local function Stop()
    if not mirrorActive then return end

    mirrorActive = false
    mirrorFocused = false
    mirrorAutoStarted = false
    captureRequested = false
    activeHand = nil
    startYaw = nil

    -- V2: Always clear flags on stop (failsafe, semiofficial only)
    if IsSemiofficial() then
        g_VR.desktopMirrorMode = nil
        g_VR.desktopMirrorTransparentInput = nil
        RestoreDesktopUiMirror()
    end

    -- Remove all hooks
    hook.Remove("PostRenderVGUI", "vrmod_desktop_mirror_capture")
    hook.Remove("PostDrawTranslucentRenderables", "vrmod_desktop_mirror_draw")
    hook.Remove("VRMod_Input", "vrmod_desktop_mirror_input")
    hook.Remove("Think", "vrmod_desktop_mirror_think")

    -- Clean up timers
    timer.Remove("vrmod_dm_delayed_0.5")
    timer.Remove("vrmod_dm_delayed_0.3")

    -- Restore screen clicker
    if screenClickerEnabled then
        gui.EnableScreenClicker(false)
        screenClickerEnabled = false
    end

    print("[VRMod Desktop Mirror] Stopped")
end

-- ============================================================================
-- VRMod lifecycle hooks
-- ============================================================================
hook.Add("VRMod_Start", "vrmod_desktop_mirror_vrstart", function(ply)
    if ply ~= LocalPlayer() then return end
    if cvEnabled:GetBool() then
        -- Delay start slightly to ensure VR systems are initialized
        timer.Simple(1, function()
            if cvEnabled:GetBool() and g_VR and g_VR.active then
                Start()
            end
        end)
    end
    -- Auto-start monitor: semiofficial only (requires g_VR.desktopPopupCount from vrmod_dermapopups.lua)
    if IsSemiofficial() then
        hook.Add("Think", "vrmod_desktop_mirror_autostart", function()
            if not g_VR or not g_VR.active then return end
            local count = g_VR.desktopPopupCount or 0
            if count > 0 and not mirrorActive then
                mirrorAutoStarted = true
                Start()
                -- If Start() failed (e.g. RT creation), don't retry every frame
                if not mirrorActive then
                    mirrorAutoStarted = false
                end
            elseif count == 0 and mirrorActive and mirrorAutoStarted then
                mirrorAutoStarted = false
                Stop()
            end
        end)
    end
end)

hook.Add("VRMod_Exit", "vrmod_desktop_mirror_vrexit", function(ply)
    if ply ~= LocalPlayer() then return end
    -- V2 flag cleanup (semiofficial only; harmless on original since flags are nil)
    if IsSemiofficial() then
        g_VR.desktopMirrorMode = nil
        g_VR.desktopMirrorTransparentInput = nil
    end
    Stop()
    -- Clean up auto-start monitor
    hook.Remove("Think", "vrmod_desktop_mirror_autostart")
    mirrorAutoStarted = false
end)

-- ConVar change callback: toggle mirror while VR is running
cvars.AddChangeCallback("vrmod_desktop_mirror", function(name, old, new)
    if not g_VR or not g_VR.active then return end
    if tonumber(new) == 1 then
        Start()
    else
        Stop()
    end
end, "vrmod_desktop_mirror_toggle")

-- V2: Mirror Mode ConVar change callback
cvars.AddChangeCallback("vrmod_desktop_mirror_mode", function(name, old, new)
    if not g_VR or not g_VR.active then return end
    if not IsSemiofficial() then return end  -- V2 requires semiofficial
    if tonumber(new) == 1 then
        -- Only set flag if mirror is actually running (Edge Case 1: prevents stuck UI)
        if mirrorActive then
            g_VR.desktopMirrorMode = true
            ForceDesktopUiMirror()
            UpdateTransparentInputFlag()
        end
    else
        g_VR.desktopMirrorMode = nil
        g_VR.desktopMirrorTransparentInput = nil
        RestoreDesktopUiMirror()
        -- Restore screenClicker state for classic mode (Edge Case 2: desync prevention)
        if g_VR.menuFocus then
            gui.EnableScreenClicker(true)
        end
    end
end, "vrmod_desktop_mirror_mode_toggle")

-- V2: Transparent Input ConVar change callback
cvars.AddChangeCallback("vrmod_desktop_mirror_transparent_input", function(name, old, new)
    if not g_VR or not g_VR.active then return end
    if not IsSemiofficial() then return end  -- V2 requires semiofficial
    UpdateTransparentInputFlag()
end, "vrmod_desktop_mirror_transparent_toggle")

-- Manual refresh command (useful for testing capture timing)
concommand.Add("vrmod_desktop_mirror_refresh", function()
    if mirrorActive then
        RequestCapture()
        print("[VRMod Desktop Mirror] Manual refresh requested")
    else
        print("[VRMod Desktop Mirror] Not active")
    end
end)

-- V2: Emergency escape — force-clear mirror mode flags if stuck
concommand.Add("vrmod_desktop_mirror_mode_reset", function()
    if g_VR then
        g_VR.desktopMirrorMode = nil
        g_VR.desktopMirrorTransparentInput = nil
    end
    print("[VRMod Desktop Mirror] Mirror mode flags forcibly cleared")
end)

-- ============================================================================
-- Quick Menu integration
-- ============================================================================
hook.Add("VRMod_OpenQuickMenu", "vrmod_desktop_mirror_quickmenu", function()
    if not vrmod or not vrmod.AddInGameMenuItem then return end
    vrmod.AddInGameMenuItem("desktop", 2, 2, function()
        local current = cvEnabled:GetInt()
        RunConsoleCommand("vrmod_desktop_mirror", current == 1 and "0" or "1")
        RunConsoleCommand("vrmod_keyboard", current == 1 and "0" or "1")
    end)
end)
