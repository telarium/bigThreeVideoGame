----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script controls all UI behavior
-- for the Chicago endless runner level

local mainScene = nil
local keyboard = nil
local bDisableDash = false
local bDisablePower = false
local buttonIconAlpha = 0.7
local currentScoreDisplayNum = 0
local gradient = nil
local healthBarNormalAlpha = 0.35
local highlightAlpha = 0.25

if ( system.getInfo("environment") == "simulator" ) then
    keyboard = require( "keyboardInput" )
end

local ui = {
    
}

local myListener = function( event )
        if( event.x < mainScene.ui.jumpButton.icon.x + (mainScene.ui.jumpButton.icon.width/2) ) then
            if( event.phase == "began" ) then
                mainScene.jumpEventID = event.id
                mainScene:onJumpButton(event)
                
            elseif( event.id == mainScene.jumpEventID and event.phase == "ended" ) then
                mainScene.jumpEventID = nil;
                mainScene:onJumpButton(event)
            end
        elseif( event.x > mainScene.ui.fireButton.icon.x - (mainScene.ui.fireButton.icon.width/2) ) then
            if( event.phase == "began" ) then
                mainScene.onFireEventID = event.id
                mainScene:onFireButton(event)
            end
        end
end

local function updateScore(self)
    if( not mainScene ) then
        return
    end
    
    if( not self.scoreText.counter ) then
        self.scoreText.counter = 0
    end
    
    self.scoreText.counter = self.scoreText.counter + 1
    if( self.scoreText.counter < 10 ) then
        return
    end
    self.scoreText.counter = 0
    
    if( currentScoreDisplayNum < mainScene.score ) then
        currentScoreDisplayNum = currentScoreDisplayNum + 50
    end
    if( currentScoreDisplayNum > mainScene.score ) then
        currentScoreDisplayNum = mainScene.score
    end
    local displayNum = tostring( math.floor( currentScoreDisplayNum + 0.5 ) )
    while( string.len( displayNum ) < 6 ) do
        displayNum = "0" .. displayNum
    end
   
    self.scoreText.text = displayNum
    storyboard.state.score = tonumber( displayNum )
end

local function addGamepadButtonSprites(button, self)

    local jumpButtonFillSheet = graphics.newImageSheet( "images/ui_gamepad_fillRing.png", { width=52, height=52, numFrames=31 } )

    button.fillRing = display.newSprite( jumpButtonFillSheet, {{ name = "fill", start=1, count=31, time=500, loopCount=1 }} )
    
    button.fillRing.x = button.icon.x
    button.fillRing.y = button.icon.y

     mainScene.ui.uiGroup:insert( button.fillRing )
     mainScene.ui.uiGroup:toFront()
     button.fillRing:toFront()
     button.fillRing:setSequence( "fill" )
     button.fillRing:pause()
     button.fillRing.blendMode = "screen"
     button.fillRing.alpha = 0.35
     button.fillRing:setFrame( 31 )
     button.fillRing.xScale, button.fillRing.yScale = self.uiScale, self.uiScale
     
     button.innerRing = display.newImageRect( "images/ui_gamepad_innerRing.png", 52, 52 )
     button.innerRing.x = button.icon.x
     button.innerRing.y = button.icon.y
     button.innerRing.alpha = buttonIconAlpha
     button.innerRing.xScale, button.innerRing.yScale = self.uiScale, self.uiScale
     
     mainScene.ui.uiGroup:insert( button.innerRing )
     
     button.innerCircle = display.newImageRect( "images/ui_gamepad_innerCircle.png", 100, 100 )
     button.innerCircle.x = button.icon.x
     button.innerCircle.y = button.icon.y
     button.innerCircle.alpha = 0.15
     button.innerCircle.xScale, button.innerCircle.yScale = self.uiScale, self.uiScale

     
     mainScene.ui.uiGroup:insert(  button.innerCircle )
     
        
    local sheetInfo = require("images.powerUpIdleAnim")
    local imageSheet = graphics.newImageSheet( "images/powerUpIdleAnim.png", sheetInfo:getSheet() )
    button.idle = display.newSprite( imageSheet , {{ name = "loop", start=1, count=30, time=900, loopCount=0 }} )
    --button.idle:play()    
    button.idle.blendMode = "add"
    button.idle.alpha = highlightAlpha
    button.idle.x = button.icon.x
    button.idle.y = button.icon.y
    button.idle.isVisible = false
    
    mainScene.ui.uiGroup:insert(  button.idle )

    button.reminder = display.newImageRect( "images/ui_gamepad_reminder.png", 52, 52 )
    --button.reminder.blendMode = "screen"
    button.reminder.x = button.icon.x
    button.reminder.y = button.icon.y
    button.reminder.alpha = 0.65
    button.reminder.isVisible = false
    button.reminder.xScale, button.reminder.yScale = self.uiScale, self.uiScale
    
    mainScene.ui.uiGroup:insert(  button.reminder )
     
    button.rollOverState = function(event)
        if( event.phase == "began" ) then
            button.innerRing.alpha = 1
            button.fillRing.blendMode = "add"
            button.icon.blendMode = "add"
        else
            button.innerRing.alpha = buttonIconAlpha
            button.fillRing.blendMode = "screen"
            button.icon.blendMode = "screen"
        end
    end

    button.idle:toBack()
end

function ui:setButtonReminder( button, bSet )
    if( bSet and not button.reminderBlink ) then
    
        if( mainScene.bVinceAlive or mainScene.bGameOver or mainScene.bFoggy ) then
            return
        end
        
        local originY = button.reminder.y
        button.reminder.y = button.reminder.y - 20
        
        transition.to( button.reminder, { time=600, delay=250, y= originY,transition=easing.outExpo} )
        button.reminder.alpha = 0.65
        
        self:highlightButton( button )
        
        local counter = 0
        
        local blink = function()
            if( not mainScene ) then
                return
            end
            counter = counter + 100
            if( counter > 8000 or mainScene.bVinceAlive or mainScene.bGameOver or mainScene.bFoggy ) then
               self:setButtonReminder( button, false )
               return
            else
                if( not button.reminder.isVisible ) then
                    button.reminder.isVisible = true
                else
                    button.reminder.isVisible = false
                end
            end
        end
        
        button.reminderBlink = timer.performWithDelay(100, blink, -1 )
    elseif( not bSet and button.reminderBlink ) then
        timer.cancel( button.reminderBlink )
        button.reminderBlink = nil
        transition.to( button.reminder, { time=200, delay=0, alpha = 0.01} )
        local turnOff = function()
            button.isVisible = false
        end
        timer.performWithDelay(100, turnOff, 0 )
        button.reminder.isVisible = false
    end
end

function ui:highlightButton( button )
    if( button.disabled or mainScene.bSmoggy or mainScene.bVinceAlive ) then
        return;
    end

    button.idle.isVisible = true
    button.idle.alpha = 0.01
    button.idle:play()

    local function removeMe()
        if( button.idle.pause ) then
          button.idle:pause()
          button.idle.alpha = 0.01
          button.idle.isVisible = false
        end
    end
    timer.performWithDelay( 6000, removeMe )
    local trans1 = transition.to( button.idle, { time=1000, delay=0, alpha=highlightAlpha, transition=easing.outExpo } )
    local trans2 = transition.to( button.idle, { time=2000, delay=2000, alpha=0, transition=easing.inExpo } )
end

function ui:updateHealthMeter()
    self.healthBar.xScale = mainScene.player.health / 4
    if( mainScene.player.health <= 0 ) then
        mainScene.player.health = 0
        if( self.healthBarTransition ) then
            transition.cancel(self.healthBarTransition)
            
        end
        if(self.healthBarTransition2 ) then
            transition.cancel(self.healthBarTransition2)
        end
        self.healthBar.xScale = 0.001
    elseif( mainScene.player.health == 1 ) then
        if( not self.healthBarTransition ) then
            self.healthBar.alpha = 0
            --self.healthBarTransition = transition.to( self.healthBar, { time=200, delay=0, alpha=1, iterations=100000,  } )                   
            --self.healthBarTransition2 = transition.to( self.healthBar, { time=200, delay=200, alpha=0, iterations=100000, transition=easing.outExpo } )
            self.healthBar:setFillColor(1, 0, 0)
            self.healthBar.alpha = 0.8
        end
    else
        if( self.healthBarTransition ) then
            transition.cancel(self.healthBarTransition)
        end
        if( self.healthBarTransition2 ) then
            transition.cancel(self.healthBarTransition2)
        end
            self.healthBarTransition  = nil
            self.healthBarTransition2 = nil

        self.healthBar.alpha = healthBarNormalAlpha
        self.healthBar:setFillColor(1, 1, 1)
    end
    if ( mainScene.player.health > 1 ) then
       transition.to( gradient, { time=500, delay=0, alpha=0 } )
    end
end

function ui:doDamage()
    ui:updateHealthMeter()
    gradient.isVisible = true
    transition.to( gradient, { time=500, delay=0, alpha=0.8, transition=easing.outExpo } )
    if ( mainScene.player.health > 1 ) then
       transition.to( gradient, { time=600, delay=400, alpha=0 } )
    end
    
    local post = function()
        if( not mainScene ) then
            return
        end
        if( mainScene.player.health <= 1 ) then
            gradient.alpha = 0.8
            gradient.isVisible = true
        else
            gradient.alpha = 0
            gradient.isVisible = false
        end
    end
    
    timer.performWithDelay( 901, post )
end

function ui:showDisabled()
    if( system.getTimer() - self.bDisableTime < 600 ) then
        return
    end

    self.bDisableTime = system.getTimer()
    local scale = self.specialPowersButton.disabled.xScale
    local showx1 = transition.to( self.specialPowersButton.disabled, { time=250, delay=0, xScale=scale*1.75} )
    local showy1 = transition.to( self.specialPowersButton.disabled, { time=250, delay=0, yScale=scale*1.75} )
    local showx2 = transition.to( self.specialPowersButton.disabled, { time=250, delay=250, xScale=scale} )
    local showy2 = transition.to( self.specialPowersButton.disabled, { time=250, delay=250, yScale=scale} )
end
    

function ui:update()
    updateScore(self)
    
    if( mainScene and mainScene.bSmoggy and self.specialPowersButton.disabled ) then
        if( not self.specialPowersButton.disabled.isVisible ) then
            self:showDisabled()
        end
        self.specialPowersButton.disabled.isVisible = true
        self.specialPowersButton.icon.alpha = 0.01
    elseif( mainScene and not mainScene.bSmoggy and self.specialPowersButton.disabled and self.specialPowersButton.disabled.isVisible ) then
        self.specialPowersButton.disabled.isVisible = false
    end
end

function ui:updateDashMeter( num )
    if( not mainScene ) then
        return
    end
    if( num < 0.1 or mainScene.player.bDashing ) then
        bDisableDash = true
        mainScene.ui.dashButton.idle.isVisible = false
        mainScene.ui.dashButton.icon.alpha = 0.1
        self.reminderDashCounter = 0
        self:setButtonReminder( self.dashButton, false )
    else
        if( num >= .9 ) then
            self.reminderDashCounter = self.reminderDashCounter + 1
            if( self.reminderDashCounter > ( 60 * 12 ) and not mainScene.bVinceAlive ) then
                self:setButtonReminder( self.dashButton, true )
            end
            
            if( mainScene.bVinceAlive ) then
                self.reminderDashCounter = -1000
            end
        end

        bDisableDash = false
        mainScene.ui.dashButton.icon.alpha = buttonIconAlpha
    end
    self.dashButton.fillRing:setFrame( 1 + math.floor( ( num * 30 ) + 0.5 ) )
end

function ui:updatePowerMeter( num )
    if( not mainScene ) then
        return
    end
    if( num < 1 ) then
        bDisablePower = true
        
        mainScene.ui.specialPowersButton.icon.alpha = 0.1
        mainScene.ui.specialPowersButton.idle.isVisible = false
        mainScene.ui.specialPowersButton.idle:pause()
        self.reminderPowersCounter = 0
        self:setButtonReminder( self.specialPowersButton, false )
    else
        self.reminderPowersCounter = self.reminderPowersCounter + 1
        if( self.reminderPowersCounter > ( 60 * 20 ) ) then
            self:setButtonReminder( self.specialPowersButton, true )
        end
        bDisablePower = false
        mainScene.ui.specialPowersButton.icon.alpha = buttonIconAlpha
    end
    
    self.specialPowersButton.fillRing:setFrame( 1 + math.floor( ( num * 30 ) + 0.5 ) )
end


function ui:init(scene)

    mainScene = scene

    -- keyboard bindings for simulator
    if keyboard then
        keyboard.bind("z", function(e)
            local evt = { name="keyboard_z", phase="began", id="z" }
            mainScene:onJumpButton(evt)
        end)
        keyboard.bind("x", function(e)
            local evt = { name="keyboard_x", phase="began", id="x" }
            mainScene:onDashButton(evt)
        end)
        keyboard.bind("m", function(e)
            local evt = { name="keyboard_m", phase="began", id="m" }
            mainScene:onFireButton(evt)
        end)
        keyboard.bind("n", function(e)
            local evt = { name="keyboard_n", phase="began", id="n" }
            mainScene:onSpecialPowersButton(evt)
        end)
    end

    self.reminderPowersCounter = 0
    self.reminderDashCounter = 0
    
    self.positionOffsetX = 0
    self.positionOffsetY = 0

    if( system.getInfo("model") == "iPhone" ) then
        self.uiScale = 1.25
        if( display.actualContentWidth == 568 ) then
            self.positionOffsetX = 20
        else
            self.positionOffsetX = 30
        end
        self.positionOffsetY = 5
    elseif( system.getInfo("model") == "iPad" ) then
        self.uiScale = 0.75
    end

    self.uiGroup = nil
    self.jumpButton = {}
    self.fireButton = {}
    self.specialPowersButton = {}
    self.dashButton = {}

    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )

    self.uiGroup = display.newGroup()
    addDisplayGroup( self.uiGroup )

    self.jumpButton.icon = display.newImageRect( "images/ui_gamepad_jump.png", 117, 117 )
    self.jumpButton.icon.x = scene.leftEdge + 80 - self.positionOffsetX
    self.jumpButton.icon.y = scene.foldY + 3 + self.positionOffsetY
    self.jumpButton.icon.alpha = buttonIconAlpha
    self.jumpButton.icon.xScale, self.jumpButton.icon.yScale = self.uiScale, self.uiScale

    if( system.getInfo("model") == "iPad" ) then
        self.jumpButton.icon.x = scene.leftEdge + 60
        --self.jumpButton.icon.y = scene.foldY - 50
    end

    self.uiGroup:insert( self.jumpButton.icon )
    addGamepadButtonSprites( self.jumpButton, self )
    self.jumpButton.activate = function(event)
        scene:onJumpButton(event )
        self.jumpButton.rollOverState(event)
    end
    self.jumpButton.innerCircle:addEventListener( "touch", self.jumpButton.activate )

    if( mainScene:getSelectedCharacter() == "mole" ) then
        self.fireButton.icon = display.newImageRect( "images/ui_gamepad_bat.png", 117, 117 )
    elseif( mainScene:getSelectedCharacter() == "perry" ) then
        self.fireButton.icon = display.newImageRect( "images/ui_gamepad_cookie.png", 117, 117 )
    else
        self.fireButton.icon = display.newImageRect( "images/ui_gamepad_microphone.png", 117, 117 )
    end

    self.fireButton.icon.x = scene.rightEdge - 80 + self.positionOffsetX
    self.fireButton.icon.y = scene.foldY + 3 + self.positionOffsetY
    self.fireButton.icon.alpha = buttonIconAlpha
    self.fireButton.icon.blendMode = "screen"
    self.fireButton.icon.xScale, self.fireButton.icon.yScale = self.uiScale, self.uiScale

    if( system.getInfo("model") == "iPad" ) then
        self.fireButton.icon.x = scene.rightEdge - 60
        --self.fireButton.icon.y = scene.foldY - 50
    end

    self.uiGroup:insert( self.fireButton.icon )
    addGamepadButtonSprites( self.fireButton, self )
    self.fireButton.activate = function(event)
        scene:onFireButton(event )
        self.fireButton.rollOverState(event)
    end
    self.fireButton.innerCircle:addEventListener( "touch", self.fireButton.activate )

    if( mainScene:getSelectedCharacter() == "perry" ) then
        self.specialPowersButton.icon = display.newImageRect( "images/ui_gamepad_scream.png", 117, 117 )
    elseif( mainScene:getSelectedCharacter() == "don" ) then
        self.specialPowersButton.icon = display.newImageRect( "images/ui_gamepad_lightning.png", 117, 117 )
    else
        self.specialPowersButton.icon = display.newImageRect( "images/ui_gamepad_acwt.png", 117, 117 )
    end
    self.specialPowersButton.icon.x = scene.rightEdge - 175 + self.positionOffsetX
    self.specialPowersButton.icon.y = scene.foldY + 3 + self.positionOffsetY
    self.specialPowersButton.icon.alpha = buttonIconAlpha
    self.specialPowersButton.icon.xScale, self.specialPowersButton.icon.yScale = self.uiScale, self.uiScale
    self.specialPowersButton.icon.blendMode = "screen"
    --self.specialPowersButton.timeOfActivation = system.getTimer()

    if( system.getInfo("model") == "iPad" ) then
        self.specialPowersButton.icon.x = self.fireButton.icon.x - 60
    end

    self.uiGroup:insert( self.specialPowersButton.icon )
    addGamepadButtonSprites( self.specialPowersButton, self )
    self.specialPowersButton.activate = function(event)
        if( not bDisablePower ) then
            if( mainScene and mainScene.bSmoggy and self.specialPowersButton.disabled and self.specialPowersButton.disabled.isVisible ) then
                ui:showDisabled()
            end
            --self.specialPowersButton.timeOfActivation = system.getTimer()
            scene:onSpecialPowersButton(event )
            --self.specialPowersButton.rollOverState(event)
        end
    end
    self.specialPowersButton.innerCircle:addEventListener( "touch", self.specialPowersButton.activate )

    self.dashButton.icon = display.newImageRect( "images/ui_gamepad_dash.png", 117, 117 )
    self.dashButton.icon.x = scene.leftEdge + 175 - self.positionOffsetX
    self.dashButton.icon.y = scene.foldY + 3 + self.positionOffsetY
    self.dashButton.icon.alpha = buttonIconAlpha
    self.dashButton.icon.xScale, self.dashButton.icon.yScale = self.uiScale, self.uiScale

    if( system.getInfo("model") == "iPad" ) then
        self.dashButton.icon.x = self.jumpButton.icon.x + 60
    end

    self.uiGroup:insert( self.dashButton.icon )
    addGamepadButtonSprites( self.dashButton, self )
    self.dashButton.activate = function(event)
        if( not bDisableDash ) then
            scene:onDashButton(event )
            --self.dashButton.rollOverState(event)
        end
    end
    self.dashButton.innerCircle:addEventListener( "touch", self.dashButton.activate )

    --Runtime:addEventListener( "touch", myListener )

    self.scoreText = display.newText( "000", 0, 0, "C64 User Mono", 9)
    self.scoreText:setTextColor(255, 255, 255)

    --Change the value of myText
    self.scoreText.x = display.contentWidth / 2
    self.scoreText.y = mainScene.foldY + 4
    self.scoreText.blendMode = "add"
    self.scoreText.alpha = buttonIconAlpha - .2

    self.uiGroup:insert( self.scoreText )

    self.healthMeter =  display.newImageRect( "images/ui_healthMeter.png", 58, 10)
    self.healthMeter.x = display.contentWidth / 2
    self.healthMeter.y = mainScene.foldY + 18
    self.healthMeter.blendMode = "add"
    self.healthMeter.alpha = .3

    self.healthBar = display.newRect(-6, -54, 54, 6)
    self.healthBar.x = self.healthMeter.x - ( self.healthMeter.width / 2 ) + 2
    self.healthBar.y = self.healthMeter.y
    self.healthBar:setFillColor(1, 1, 1)
    self.healthBar.anchorX = 0
    self.healthBar.anchorY = 0.5
    --self.healthBar.blendMode = "screen"
    self.healthBar.alpha = healthBarNormalAlpha

    self.uiGroup:insert( self.healthBar )
    self.uiGroup:insert( self.healthMeter )

    if( mainScene:getSelectedCharacter() == "perry" ) then
        self.specialPowersButton.disabled = display.newImageRect( "images/ui_gamepad_disabled.png", 24, 18 )
        self.specialPowersButton.disabled.x = self.specialPowersButton.icon.x
        self.specialPowersButton.disabled.y = self.specialPowersButton.icon.y
        self.specialPowersButton.disabled.xScale, self.specialPowersButton.disabled.yScale = self.uiScale, self.uiScale
        self.specialPowersButton.disabled.blendMode = "add"
        --self.specialPowersButton.disabled.alpha = 0.7
        self.specialPowersButton.disabled.isVisible = false
        self.uiGroup:insert( self.specialPowersButton.disabled )
        self.bDisableTime = 0
    end

    gradient = display.newImageRect( "images/hitOverlay.png", 200, 200 )
    gradient.anchorX = 0.5
    gradient.anchorY = 0.5
    gradient.x = display.contentCenterX
    gradient.y = display.contentCenterY
    gradient.xScale = display.actualContentWidth / gradient.width
    gradient.yScale = display.actualContentHeight / gradient.height
    gradient.blendMode = "screen"
    gradient.isVisible = false
    gradient.alpha = 0

    mainScene.ui.uiGroup:insert(  gradient )

    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
end

function ui:disable()
    Runtime:removeEventListener( "touch", myListener )

    if( mainScene ) then
        mainScene.ui.scoreText:removeSelf()
        mainScene.ui.scoreText = nil

        if( self.healthBarTransition ) then
            transition.cancel(self.healthBarTransition)
        end
        if( self.healthBarTransition2 ) then
            transition.cancel(self.healthBarTransition2)
        end
        self.healthBarTransition = nil
        self.healthBarTransition2 = nil

        mainScene.ui.jumpButton = {}
        mainScene.ui.fireButton = {}
        mainScene.ui.specialPowersButton = {}
        mainScene.ui.dashButton = {}

        gradient:removeSelf()
        gradient = nil

        display.remove( mainScene.ui.uiGroup )
        mainScene.ui.uiGroup = nil
        mainScene = nil
    end
end

return ui
