--[[

     Licensed under GNU General Public License v2
      * (c) 2016, Luca CPZ

--]]

local helpers = require("lain.helpers")
local shell   = require("awful.util").shell
local wibox   = require("wibox")
local string  = string
local type    = type

-- PulseAudio volume
-- lain.widget.pulse

local function factory(args)
    args           = args or {}

    local pulse    = { widget = args.widget or wibox.widget.textbox(), device = "N/A" }
    local timeout  = args.timeout or 5
    local settings = args.settings or function() end

    pulse.devicetype = args.devicetype or "sink"
    pulse.cmd = args.cmd or "pactl list " .. pulse.devicetype .. "s | grep -e '^\\s*Volume:' -e 'Mute:' -e 'device.string'"

    function pulse.update()
        helpers.async({ shell, "-c", type(pulse.cmd) == "string" and pulse.cmd or pulse.cmd() },
        function(s)
            volume_now = {
                device = string.match(s, "device.string = \"(%S+)\"") or "N/A",
                mute  = string.match(s, "Mute: (%S+)") or "N/A",
                raw = s,
            }

            pulse.device = volume_now.device

            local ch = 1
            for v in string.gmatch(s, "(%d+)%%") do
                volume_now[ch] = v
                volume_now.level = v
                ch = ch + 1
            end

            volume_now.left  = volume_now[1] or "N/A"
            volume_now.right = volume_now[2] or "N/A"

            widget = pulse.widget
            settings(widget, volume_now)
        end)
    end

    helpers.newtimer("pulse", timeout, pulse.update)

    return pulse
end

return factory
