--[[
    Module 17: VR Ragdoll Puppeteer — Client (v3)
    - Toggle puppet via VRMod_Input (configurable action)
    - Receive state notifications from server
    - Display HUD indicator when puppet is active
    - JSON persistence for rigging settings (data/vrmod/puppeteer_rig.json)
    - Send rigging to server on puppet activation and on change
]]

if SERVER then return end

g_VR = g_VR or {}
vrmod = vrmod or {}

-- ============================================================================
-- ConVars
-- ============================================================================

local cv_enable        -- vrmod_unoff_puppeteer_enable (replicated, lazy-fetched)

local cv_toggle_action = CreateClientConVar(
    "vrmod_unoff_puppeteer_toggle_action", "",
    true, FCVAR_ARCHIVE,
    "VR action name to toggle puppeteer (empty=disabled, e.g. boolean_left_menu)"
)

local cv_show_hud = CreateClientConVar(
    "vrmod_unoff_puppeteer_show_hud", "1",
    true, FCVAR_ARCHIVE,
    "Show puppeteer status in HUD", 0, 1
)

-- ============================================================================
-- Constants
-- ============================================================================

local SAVE_PATH = "vrmod/puppeteer_rig.json"

-- Default rigging: Head + Hands only (3 VR tracking points driven, rest physics)
local DEFAULT_RIG = { false, false, true, true, false, false, false, false, false, true, false, false, false, false, false }

-- ============================================================================
-- State
-- ============================================================================

local puppetActive = false
local puppetRagdoll = nil
local currentRig = {}  -- Current rigging state [1..15] = true/false

-- Initialize currentRig with defaults
for i = 1, 15 do
    currentRig[i] = DEFAULT_RIG[i]
end

-- ============================================================================
-- JSON Persistence
-- ============================================================================

--- Load rigging settings from JSON. Returns true if loaded successfully.
local function LoadRigFromJSON()
    local raw = file.Read(SAVE_PATH, "DATA")
    if not raw then return false end

    local tbl = util.JSONToTable(raw)
    if not tbl or not tbl.boneRig then return false end

    for i = 1, 15 do
        if tbl.boneRig[i] ~= nil then
            currentRig[i] = tbl.boneRig[i]
        else
            currentRig[i] = DEFAULT_RIG[i]
        end
    end

    return true
end

--- Save current rigging settings to JSON.
local function SaveRigToJSON()
    local tbl = { boneRig = currentRig }
    local json = util.TableToJSON(tbl, true) -- pretty print

    -- Ensure directory exists
    if not file.IsDir("vrmod", "DATA") then
        file.CreateDir("vrmod")
    end

    file.Write(SAVE_PATH, json)
end

-- Load on file init
LoadRigFromJSON()

-- ============================================================================
-- Send rigging to server
-- ============================================================================

--- Send the current 15-bool rigging state to server via net message.
local function SendRigToServer()
    net.Start("vrmod_puppeteer_rig_apply")
    for i = 1, 15 do
        net.WriteBool(currentRig[i] or false)
    end
    net.SendToServer()
end

-- ============================================================================
-- Lazy ConVar fetch
-- ============================================================================

local function GetEnableCvar()
    if not cv_enable then
        cv_enable = GetConVar("vrmod_unoff_puppeteer_enable")
    end
    return cv_enable
end

-- ============================================================================
-- Network: State notification from server
-- ============================================================================

net.Receive("vrmod_puppeteer_state", function()
    local active = net.ReadBool()
    puppetActive = active

    if active then
        print("[Puppeteer] Puppet activated — sending saved rigging to server")
        puppetRagdoll = nil  -- Will be found next frame

        -- Send saved rigging to server (overrides default)
        timer.Simple(0.1, function()
            if puppetActive then
                SendRigToServer()
            end
        end)
    else
        print("[Puppeteer] Puppet deactivated")
        puppetRagdoll = nil
    end
end)

-- ============================================================================
-- VR Input: Toggle puppet with configurable action
-- ============================================================================

hook.Add("VRMod_Input", "VRMod_Puppeteer_Input", function(action, pressed)
    if not pressed then return end
    if not g_VR.active then return end

    local ecv = GetEnableCvar()
    if ecv and not ecv:GetBool() then return end

    local toggleAction = cv_toggle_action:GetString()
    if toggleAction == "" then return end

    if action == toggleAction then
        RunConsoleCommand("vrmod_puppeteer_toggle")
    end
end)

-- ============================================================================
-- HUD Indicator
-- ============================================================================

hook.Add("HUDPaint", "VRMod_Puppeteer_HUD", function()
    if not puppetActive then return end
    if not cv_show_hud:GetBool() then return end

    local w = ScrW()
    local text = "PUPPET"
    surface.SetFont("DermaDefaultBold")
    local tw, th = surface.GetTextSize(text)

    local x = w - tw - 20
    local y = 60

    surface.SetDrawColor(20, 20, 20, 180)
    surface.DrawRect(x - 6, y - 2, tw + 12, th + 4)

    local pulse = math.sin(CurTime() * 3) * 0.3 + 0.7
    surface.SetDrawColor(80 * pulse, 255 * pulse, 80 * pulse, 220)
    surface.DrawOutlinedRect(x - 6, y - 2, tw + 12, th + 4, 1)

    surface.SetTextColor(80, 255, 80, 255)
    surface.SetTextPos(x, y)
    surface.DrawText(text)
end)

-- ============================================================================
-- 3D Indicator
-- ============================================================================

hook.Add("PostDrawTranslucentRenderables", "VRMod_Puppeteer_3DIndicator", function(depth, sky)
    if depth or sky then return end
    if not puppetActive then return end
    if not g_VR.active then return end

    local ply = LocalPlayer()
    if not IsValid(puppetRagdoll) then
        for _, ent in ipairs(ents.FindByClass("prop_ragdoll")) do
            if IsValid(ent) and ent:GetOwner() == ply then
                puppetRagdoll = ent
                break
            end
        end
    end

    if not IsValid(puppetRagdoll) then return end

    local headBone = puppetRagdoll:LookupBone("ValveBiped.Bip01_Head1")
    if not headBone then return end

    local headPos = puppetRagdoll:GetBonePosition(headBone)
    if not headPos then return end

    local mat = Material("sprites/light_glow02_add")
    render.SetMaterial(mat)
    render.DrawSprite(headPos + Vector(0, 0, 10), 6, 6, Color(80, 255, 80, 120))
end)

-- ============================================================================
-- Cleanup on VR exit
-- ============================================================================

hook.Add("VRMod_Exit", "VRMod_Puppeteer_CLExit", function()
    puppetActive = false
    puppetRagdoll = nil
end)

-- ============================================================================
-- Public Client API
-- ============================================================================

vrmod.Puppeteer = vrmod.Puppeteer or {}

function vrmod.Puppeteer.IsActive()
    return puppetActive
end

function vrmod.Puppeteer.GetRagdoll()
    return puppetRagdoll
end

--- Get current rigging state (mutable reference)
function vrmod.Puppeteer.GetCurrentRig()
    return currentRig
end

--- Set a bone's rig state, save, and send to server if active
function vrmod.Puppeteer.SetBoneRig(boneIdx, isDriven)
    if boneIdx < 1 or boneIdx > 15 then return end
    currentRig[boneIdx] = isDriven
    SaveRigToJSON()
    if puppetActive then
        SendRigToServer()
    end
end

--- Set all 15 bone rig states at once, save, and send
function vrmod.Puppeteer.SetFullRig(rigTable)
    for i = 1, 15 do
        currentRig[i] = rigTable[i] or false
    end
    SaveRigToJSON()
    if puppetActive then
        SendRigToServer()
    end
end

--- Load from JSON (called from menu)
function vrmod.Puppeteer.ReloadFromJSON()
    return LoadRigFromJSON()
end

--- Force save (called from menu if needed)
function vrmod.Puppeteer.SaveToJSON()
    SaveRigToJSON()
end

--- Force send to server
function vrmod.Puppeteer.SendToServer()
    if puppetActive then
        SendRigToServer()
    end
end

-- ============================================================================

print("[VRMod] Module 17: VR Ragdoll Puppeteer v3 loaded (CL)")
