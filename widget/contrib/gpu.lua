--[[

     Licensed under GNU General Public License v2

--]]

local helpers  = require("lain.helpers")
local json     = require("lain.util").dkjson
local focused  = require("awful.screen").focused
local naughty  = require("naughty")
local wibox    = require("wibox")

local math, os, string, tonumber = math, os, string, tonumber

local function factory(args)
    local gpu                   = { widget = wibox.widget.textbox() }
    local args                  = args or {}
    local timeout               = args.timeout or 1
    local powerstatus_call          = args.powerstatus_call  or "cat /proc/acpi/bbswitch"
    local gpuinfo_call         = args.gpuinfo_call or "gpustat"
    local icon_on               = args.icon_on or wibox.widget.imagebox("")
    local icon_off               = args.icon_off or wibox.widget.imagebox("")

    local notification_preset   = args.notification_preset or {}
    local na_markup             = args.na_markup or " N/A "
    local followtag             = args.followtag or true
    local showpopup             = args.showpopup or "on"
    local settings              = args.settings or function() end

    function gpu.show(t_out)
        gpu.hide()

        if followtag then
            notification_preset.screen = focused()
        end

        if not gpu.notification_text then
            gpu.update()
        end

        gpu.notification = naughty.notify({
            text    = gpu.notification_text,
            icon    = "",
            timeout = t_out,
            preset  = notification_preset
        })
    end

    function gpu.hide()
        if gpu.notification then
            naughty.destroy(gpu.notification)
            gpu.notification = nil
        end
    end

    function gpu.attach(obj)
        obj:connect_signal("mouse::enter", function()
            gpu.show(0)
        end)
        obj:connect_signal("mouse::leave", function()
            gpu.hide()
        end)
    end

    function gpu.update()
        helpers.async(powerstatus_call, function(f)
            local pos, err

            if string.match(f, "ON") then
                helpers.async(gpuinfo_call, function(f2)
                    if not f2 or #f2 == 0 then
                        gpu.widget:set_markup(na_markup)
                        widget = gpu.widget
                        icon = icon_off
                        text = ""
                        settings()
                        return
                    else
                        gpu.notification_text = f2
                        if gpu.notification then
                            naughty.replace_text(gpu.notification, "", f2)
                        end
                        widget = gpu.widget
                        icon = icon_on
                        temp, perc = string.match(f2, "| (%d+)'C.-(%d+) %% |")
                        if not temp then
                            naughty.notify({text = f2})
                        end
                        text = string.format("%d°C, %d%%", temp, perc)
                        settings()
                    end
                end)
            else
                gpu.widget:set_markup(na_markup)
                widget = gpu.widget
                icon = icon_off
                text = ""
                settings()
            end

        end)
    end

    if showpopup == "on" then gpu.attach(gpu.widget) end

    gpu.timer = helpers.newtimer("gpu-timer", timeout, gpu.update, false, true)

    return gpu
end

return factory
