-- togger_hardware_vid_audio.lua
local mp = require 'mp'

local SHANLING_DEVICE = "pipewire/alsa_output.usb-Shanling_Shanling_UA1_Plus_Shanling_UA1_Plus-00.analog-stereo"

local function device_present(name)
    local devices = mp.get_property_native("audio-device-list")
    if type(devices) ~= "table" then return false end
    for _, d in ipairs(devices) do
        if d.name == name then return true end
    end
    return false
end

local function toggle_audio_exclusive()
    local current = mp.get_property("audio-device")

    if current == SHANLING_DEVICE then
        mp.set_property("audio-device", "auto")
        mp.set_property_native("audio-exclusive", false)
        mp.command("ao-reload")
        mp.osd_message("audio: default pipewire device")
    elseif device_present(SHANLING_DEVICE) then
        mp.set_property("audio-device", SHANLING_DEVICE)
        mp.set_property_native("audio-exclusive", true)
        mp.command("ao-reload")
        mp.osd_message("audio: Shanling UA1 Plus (exclusive)")
    else
        mp.osd_message("Shanling UA1 Plus not connected")
    end
end

mp.add_key_binding("ctrl+h", "toggle-hw-audio-exclusive", toggle_audio_exclusive)
