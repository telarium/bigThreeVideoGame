----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script animates an iris-out transition inbetween scenes

local storyboard   = require("storyboard")
local displayGroup = nil
local irisSprite   = nil

local UITransition = {}

function UITransition:execute(nextScene, delay)
    delay = delay or 0

    local function onIrisFrame(event)
        if event.phase == "ended" then
            irisSprite:removeSelf()
            irisSprite = nil

            display.remove(displayGroup)
            displayGroup = nil

            if UIEndScreen_Remove then
                UIEndScreen_Remove()
            end

            removeDisplayGroups()

            storyboard.purgeAll()
            storyboard.removeAll()
            storyboard.gotoScene(nextScene)
        end
    end

    -- make a new group for the wipe
    displayGroup = display.newGroup()
    addDisplayGroup(displayGroup)

    -- load your sheet
    local sheet = graphics.newImageSheet(
      "images/transitionAnim.png",
      { width=240, height=135, numFrames=25 }
    )

    -- create the sprite
    irisSprite = display.newSprite(sheet, {
      { name="sequence", start=1, count=25, time=900, loopCount=1 }
    })

    -- center it
    irisSprite.x = display.contentCenterX
    irisSprite.y = display.contentCenterY
    irisSprite.anchorX, irisSprite.anchorY = 0.5, 0.5

    -- **scale** it big enough to cover *both* width and height
    local sx = display.actualContentWidth  / irisSprite.width
    local sy = display.actualContentHeight / irisSprite.height
    local s  = math.max(sx, sy)
    irisSprite:scale(s, s)

    irisSprite.alpha = 0

    -- put it on top
    displayGroup:toFront()

    -- play it after delay
    timer.performWithDelay(delay, function()
        irisSprite.alpha = 1
        displayGroup:insert(irisSprite)
        irisSprite:addEventListener("sprite", onIrisFrame)
        irisSprite:setSequence("sequence")
        irisSprite:play()
    end)
end

return UITransition
