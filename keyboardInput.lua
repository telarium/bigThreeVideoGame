----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script handles keyboard events for testing in the Corona SDK environment only

local keyboardInput = {}

if system.getInfo("environment") == "device" then
  keyboardInput.init = function( ... )
    for a = 1, #arg do
      newObject = arg[a]
      function newObject:addKeyboardListener() end
      function newObject:removeKeyboardListener() end
    end
  end
  return keyboardInput
end
-- VARIABLES
  local var = { keys = {}, reType = ""}
  local api ={timer  = timer.performWithDelay,
              cancel = timer.cancel,
              remove = table.remove,
                 sub = string.sub,
                 fps = display.fps,
             originX = display.screenOriginX,
             originY = display.screenOriginY}

-- INIT
  keyboardInput.init = function( ... )
    local arg = arg
    -- TEXT ENTRY
    local function onTxtEntry(e)

      ---- BEGAN
      if e.phase == "began" then
        txtField.text = ""
      end


      ---- EDITTING
      if e.phase == "editing" then
        if var.rpt ~= nil then timer.cancel(var.rpt) var.rpt = nil end
        --print(e.newCharacters, var.keys[e.newCharacters])
        local obj = var.keys[e.newCharacters] or nil
        if obj == nil then return false end
        assert(obj, "key not defined")
        local object = obj.target
        local function countNumberTaps()
          local tapTimer
          obj.tapCount = obj.tapCount + 1
          if tapTimer == nil then
            tapTimer = api.timer( 350, function()
              tapTimer = nil
              obj.tapCount = 0
            end)
          end
        end
        if api.sub(obj.name,1,3) == "key" then
          countNumberTaps()
          if var.reType ~= "" and object.auto == false then
            txtField.text = var.reType
            onTxtEntry({phase = "editing", newCharacters = var.reType})
            var.reType = ""
          end
          if( not object.dispatchEvent ) then
            return
          end
          object:dispatchEvent({ name = obj.name,
                                   id = obj.id,
                               target = self,
                              numTaps = obj.tapCount,
                               params = obj.params })
          if object.auto == true then
            var.reType = object._resume == true and obj.id or ""
            var.rpt = timer.performWithDelay( api.fps, function() onTxtEntry({phase = "editing", newCharacters = txtField.text:sub(-1,-1)}) end)
          end
        end
      end


      ---- ENDED
      if e.phase == "submitted" then
        if var.rpt ~= nil then
          timer.cancel(var.rpt)
          var.rpt = nil
        end
        txtField.text = ""
      end


      ---- SUBMITTED
      if e.phase == "submitted" then
        if var.rpt ~= nil then
          timer.cancel(var.rpt)
          var.rpt = nil
        end
        txtField.text = ""
      end
    end


    ---- KEYBOARDLISTENER
    for a = 1, #arg do
      local newObject = arg[a]
      function newObject:addKeyboardListener( e_Name, e_Fnct, params )
        local params = params or {}
        self:addEventListener( e_Name, e_Fnct)
        local key = api.sub(e_Name, -1, -1)
        self.auto = params.auto or false
        self._resume= params.resume or false
        var.keys[key] = { name = e_Name, id = key, target = self, tapCount = 0, params = params }
      end
      function newObject:removeKeyboardListener( e_Name, e_Fnct )
        self:removeEventListener( e_Name, e_Fnct )
        api.remove( var.keys[api.sub(e_Name, -1, -1)] )
      end
    end


    ---- TEXT FIELD
    txtField = native.newTextField(-20+api.originX, -16+api.originY, 32, 24)
    txtField:addEventListener("userInput", onTxtEntry)
    txtField.alpha =0.1
    txtField.x = 0    
    txtField.y = 0
    var.keys["0"] = { name = "0", id = "0", target = {}, tapCount = 0, params = {} }
  end
return keyboardInput