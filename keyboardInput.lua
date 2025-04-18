----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script handles keyboard events for testing in the Corona SDK environment only

local keyboardInput = {}

-- On device, stub out keyboard listener methods
if system.getInfo("environment") == "device" then
  keyboardInput.init = function(...) end
  return keyboardInput
end

-- Fallback for Simulator: simple key-to-function binding
local bindings = {}

local function onKeyEvent(event)
    if event.phase == "down" then
        local fn = bindings[event.keyName]
        if fn then fn(event) end
    end
    return false  -- allow further processing
end
Runtime:addEventListener("key", onKeyEvent)

-- Public API
--- Binds a handler to a physical key (e.g. "z", "m")
function keyboardInput.bind(keyName, fn)
    bindings[keyName] = fn
end

--- Unbinds a previously bound key
function keyboardInput.unbind(keyName)
    bindings[keyName] = nil
end

--- Initializes keyboard support on display objects
---@param ... Display objects to hook
function keyboardInput.init(...)
    local args = {...}
    for i = 1, #args do
        local obj = args[i]
        --- Attach a keyboard listener: keyName like "keyboard_z"
        function obj:addKeyboardListener(keyEventName, handler)
            -- extract single key character (last char of event name)
            local keyChar = string.sub(keyEventName, -1)
            keyboardInput.bind(keyChar, handler)
        end
        --- Remove a previously attached keyboard listener
        function obj:removeKeyboardListener(keyEventName)
            local keyChar = string.sub(keyEventName, -1)
            keyboardInput.unbind(keyChar)
        end
    end
end

return keyboardInput
