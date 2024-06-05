if SERVER then return end

local function printTrackedDevices()
    if not vrmod.IsPlayerInVR(LocalPlayer()) then
        print("VRMod is not active.")
        return
    end

    local devices = vrmod.GetTrackedDeviceNames()
    if #devices == 0 then
        print("No tracked devices found.")
        return
    end

    print("Connected SteamVR devices:")
    for i, deviceName in ipairs(devices) do
        print(i .. ". " .. deviceName)
    end
end

concommand.Add("vrmod_print_devices", printTrackedDevices)