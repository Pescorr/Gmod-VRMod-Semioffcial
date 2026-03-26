--------[vrmod_climbing_filter.lua]Start--------
-- クライミング入力フィルタ: vrmod_climbing (v0.85+) との競合防止
-- climbing中にホルスターのグリップ入力をブロックする
-- ConVar vrmod_unoff_holster_climb_filter でON/OFF切替可能
AddCSLuaFile()
if SERVER then return end

vrmod.ClimbFilter = vrmod.ClimbFilter or {}

local cvar_filter = CreateClientConVar("vrmod_unoff_holster_climb_filter", 1, true, FCVAR_ARCHIVE, "Block holster input during climbing", 0, 1)

function vrmod.ClimbFilter.IsEnabled()
    return cvar_filter:GetBool()
end

-- climbing modが存在し、左手がホールド中ならtrue（=ブロック）
function vrmod.ClimbFilter.ShouldBlockLeft()
    if not cvar_filter:GetBool() then return false end
    if not vrmod.climbing then return false end
    return vrmod.climbing.IsHoldingLeft() == true
end

-- climbing modが存在し、右手がホールド中ならtrue（=ブロック）
function vrmod.ClimbFilter.ShouldBlockRight()
    if not cvar_filter:GetBool() then return false end
    if not vrmod.climbing then return false end
    return vrmod.climbing.IsHoldingRight() == true
end

-- wallrun/slide/holding中は全ホルスターをブロック
function vrmod.ClimbFilter.ShouldBlockAll()
    if not cvar_filter:GetBool() then return false end
    if not vrmod.climbing then return false end
    local s = vrmod.climbing.GetState()
    return s.holding or s.wallrunning or s.sliding
end
--------[vrmod_climbing_filter.lua]End--------
