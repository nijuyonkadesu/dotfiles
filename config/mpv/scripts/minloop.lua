
local opts = { seconds = 10 }
require("mp.options").read_options(opts, "minloop")

mp.register_event("file-loaded", function()
    mp.set_property("loop-file", "no")

    -- Let mpv handle still images.
    local image = mp.get_property_native("current-tracks/video/image")
    local audio = mp.get_property_native("current-tracks/audio")

    if image and not audio then
        return
    end

    -- Loop other media until the minimum duration is reached.
    local duration = mp.get_property_number("duration", 0)

    if duration > 0 then
        local repeats = math.max(0, math.ceil(opts.seconds / duration) - 1)
        mp.set_property_number("loop-file", repeats)
    end
end)

