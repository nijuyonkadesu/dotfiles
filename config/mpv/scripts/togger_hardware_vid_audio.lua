-- hwdec_and_audio.lua
local mp = require 'mp'

local function toggle_hwdec_and_audio()
    local hwdec = mp.get_property("hwdec")
    local new_hwdec = (hwdec == "no" or hwdec == "auto-copy") and "auto" or "no"
    mp.set_property("hwdec", new_hwdec)

    local audio_excl = mp.get_property_native("audio-exclusive")
    local new_audio = not audio_excl
    mp.set_property_native("audio-exclusive", new_audio)

    mp.osd_message("hwdec: " .. new_hwdec .. " | audio-exclusive: " .. tostring(new_audio))
end

mp.add_key_binding("h", "toggle-hwdec-audio-exclusive", toggle_hwdec_and_audio)


