--------[vrmod_windowfocus_warning.lua]Start--------
if SERVER then return end
local isMouseCursorEnabled = false
local isWindowFocused = system.HasFocus()
local warningDisplayed = false
local function checkWindowFocus()
    if isMouseCursorEnabled and not isWindowFocused then
        if not warningDisplayed then
            -- Display warning message
            hook.Add(
                "HUDPaint",
                "VRMod_WindowFocusWarning",
                function()
                    local warningText = "Please focus the Garry's Mod window to use the mouse cursor in VR"
                    local warningWidth, warningHeight = surface.GetTextSize(warningText)
                    local x = (ScrW() - warningWidth) / 2
                    local y = ScrH() * 0.8
                    draw.SimpleText(warningText, "Trebuchet24", x, y, Color(255, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER)
                end
            )

            warningDisplayed = true
        end
    else
        if warningDisplayed then
            -- Remove warning message
            hook.Remove("HUDPaint", "VRMod_WindowFocusWarning")
            warningDisplayed = false
        end
    end
end

hook.Add(
    "VRMod_Start",
    "VRMod_WindowFocusWarningInit",
    function()
        -- Check window focus state every second
        timer.Create(
            "VRMod_WindowFocusCheck",
            1,
            0,
            function()
                isWindowFocused = system.HasFocus()
                checkWindowFocus()
            end
        )
    end
)

hook.Add(
    "VRMod_Exit",
    "VRMod_WindowFocusWarningCleanup",
    function()
        timer.Remove("VRMod_WindowFocusCheck")
        hook.Remove("HUDPaint", "VRMod_WindowFocusWarning")
    end
)

-- Track mouse cursor mode state
hook.Add(
    "VRMod_Input",
    "VRMod_MouseCursorTracker",
    function(action, pressed)
        if action == "boolean_primaryfire" then
            isMouseCursorEnabled = pressed
            checkWindowFocus()
        end
    end
)
--------[vrmod_windowfocus_warning.lua]End--------