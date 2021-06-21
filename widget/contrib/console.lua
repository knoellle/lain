--[[

     Licensed under GNU General Public License v2
      * (c) 2013, Luke Bonham

--]]

local awful    = require("awful")
local naughty  = require("naughty")
local helpers  = require("lain.helpers")
local focused  = require("awful.screen").focused
local wibox    = require("wibox")

local function factory(args)
    local console  = { widget = wibox.widget.textbox() }
    local args     = args or {}
    local name     = args.name
    local commands = args.commands
    local timeout  = args.timeout or 2
    local settings = args.settings or function() end
    local popup    = args.popup or false
    local notification_preset = args.notification_preset or {}
    
    local outputs  = {} 
    for c = 1, #commands do -- initialize outputs
      table.insert(outputs, "")
    end

    function console.show(t_out)
      console.hide()

      notification_preset.screen = focused()

      if not console.notification_text then
        --return
	console.notification_text = "no text here"
      end

      console.notification = naughty.notify({
        text    = console.notification_text,
        -- icon    = console.icon_path,
        timeout = t_out,
        preset  = notification_preset
      })
    end

    function console.hide()
      if console.notification then
        naughty.destroy(console.notification)
        console.notification = nil
      end
    end

    function console.attach(obj)
      obj:connect_signal("mouse::enter", function()
        console.show(0)
      end)
      obj:connect_signal("mouse::leave", function()
        console.hide()
      end)
    end

    function console.update()
      for i,command in ipairs(commands) do
        awful.spawn.easy_async_with_shell(command, function(stdout, stderr, reason, exit_code)
          outputs[i] = stdout or stderr
          widget = console.widget
          notification_text = console.notification_text
          settings(outputs)
          console.notification_text = notification_text
        end)
      end
    end

    if popup then
      console.attach(console.widget)
    end

    helpers.newtimer(name, timeout, console.update)

    return console
end

return factory
