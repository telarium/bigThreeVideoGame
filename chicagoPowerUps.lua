----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script controls the properties of various powerups
-- for the Chicago endless runner level

local mainScene = nil
local prevTime = system.getTimer()

local powerUps = {
	activePowerUps = {}
}

local function powerupDispose(powerUp)
    if( powerUp.transition1 ) then
        transition.cancel( powerUp.transition1 )
    end
    if( powerUp.transition2 ) then
        transition.cancel( powerUp.transition2 )
    end
    if( powerUp.transition3 ) then
        transition.cancel( powerUp.transition3 )
    end
    if( powerUp.transition4 ) then
        transition.cancel( powerUp.transition4 )
    end
    if( powerUp.transition5 ) then
        transition.cancel( powerUp.transition5 )
    end
    if( powerUp.transition6 ) then
        transition.cancel( powerUp.transition6 )
    end

    powerUp.transition1 = nil
    powerUp.transition2 = nil
    powerUp.transition3 = nil
    powerUp.transition4 = nil
    powerUp.transition5 = nil
    powerUp.transition6 = nil        
    powerUp.idle:removeSelf()
    powerUp.idle = nil
    powerUp:removeSelf()
    powerUp = nil
    
end

local function spawn(powerType)
    if( not powerType and mainScene.disablePowerupAutoSpawn ) then
        return
    end

    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )


	prevTime = system.getTimer()
	
	local x,y = mainScene.city.displayGroup:contentToLocal( mainScene.rightEdge + 30, mainScene.foldY )
	y = mainScene.foldY - 150 - math.random( 200 )

	if ( y < mainScene.player.maxJumpHeight - 65 ) then
	   y = mainScene.player.maxJumpHeight - 65
	end
	
	local power = nil
    if( not powerType ) then
        powerType = math.random(4)
    end

    local powerXOffset = 0
    local powerScale = 1
    
    if ( powerType == 3 and mainScene.bSmoggy and mainScene:getSelectedCharacter() == "perry" ) then
        powerType = 1
    end
	
	if ( powerType == 1 ) then
		power = display.newImageRect( "images/pill.png", 41, 24 )
		power.name = "pill"
	elseif ( powerType == 2 ) then
		power = display.newImageRect( "images/shoutout.png", 41, 24 )
		power.name = "shoutout"
	elseif ( powerType == 3 ) then
        if( mainScene:getSelectedCharacter() == "perry" ) then
            powerXOffset = 2
            power = display.newImageRect( "images/screamIcon.png", 30, 32 )
            powerScale = 0.8
        elseif( mainScene:getSelectedCharacter() == "don" ) then
        	power = display.newImageRect( "images/lightningPower.png", 27, 30 )
            powerScale = 0.8
        else
            powerScale = 0.6
            power = display.newImageRect( "images/acwt.png", 34, 31 )
        end
		power.name = "specialPower"
	else
		--display.setDefault( "magTextureFilter", "linear" )
		--display.setDefault( "minTextureFilter", "linear" )
		power = display.newImageRect( "images/sagCard.png", 41, 24 )
		power.name = "sag"
		if( mainScene.powerUps.sagVoucherSound and not mainScene.player.bDashing ) then
			mainScene.sound:playVoice( mainScene.powerUps.sagVoucherSound, 1 )
		end
		mainScene.powerUps.sagVoucherSound = nil
	end
	
	power.x = x
	power.y = y	
	local sheetInfo = require("images.powerUpIdleAnim")
	local idleImageSheet = graphics.newImageSheet( "images/powerUpIdleAnim.png", sheetInfo:getSheet() )
	power.idle = display.newSprite( idleImageSheet , {{ name = "loop", start=1, count=30, time=900, loopCount=0 }} )
	power.idle:play()
	power.idle.blendMode = "add"
	power.idle.x = x + powerXOffset
	power.idle.y = y
	power.idle.alpha = 0.4
	power.idle.collisionDistance = 40
	if( power.name == "pill" ) then
        powerScale = 0.8
	end
	if( power.name == "shoutout" ) then
       powerScale = 0.7
    end
	if( power.name == "specialPower" and mainScene:getSelectedCharacter() == "mole" ) then
		power.idle.x = power.idle.x - 7
		power.idle.y = power.idle.y - 1
		power.idle.alpha = 0.35
	end
    
    power.idle.xScale = powerScale
	power.idle.yScale = powerScale

	mainScene.city.displayGroup:insert( power.idle )
	mainScene.city.displayGroup:insert( power )
	
	--power.xChoke = -30
	--power.yChoke = 0
	power.bRemove = false
	power.bGrabbed = false
	
	if( not mainScene.powerUps.activePowerUps ) then
	    mainScene.powerUps.activePowerUps = {}
	end
	
	table.insert( mainScene.powerUps.activePowerUps, power )
	
	display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearset" )
end


function powerUps:update()
	if ( system.getTimer() - prevTime > 5000 ) then
		spawn()
	end
	
	local i = table.getn( self.activePowerUps )
	local powerUp = nil
	while ( i > 0 ) do
		powerUp = self.activePowerUps[i]
		if( powerUp.contentBounds.xMax < mainScene.leftEdge ) then
			powerUp.bRemove = true
		elseif( not powerUp.bGrabbed ) then
            if( mainScene:checkCollision( mainScene.player.avatar, powerUp.idle ) ) then
                mainScene.sound:playBonusSound( self.bonusSound )
                powerUp.bGrabbed = true
				powerUp.blendMode = "add"
				powerUp.alpha = 0.5
				powerUp:toFront()
				powerUp.transition1 = transition.to( powerUp.idle, { time=1000, delay=0, xScale=0, transition=easing.outExpo } )
				powerUp.transition2 = transition.to( powerUp.idle, { time=1000, delay=0, yScale=0, transition=easing.outExpo } )
				powerUp.transition3 = transition.to( powerUp, { time=150, delay=0, xScale=1.5, transition=easing.inExpo } )
				powerUp.transition4 = transition.to( powerUp, { time=150, delay=0, yScale=1.5, transition=easing.inExpo } )
				powerUp.transition5 = transition.to( powerUp, { time=400, delay=150, xScale=0, transition=easing.outExpo } )
				powerUp.transition6 = transition.to( powerUp, { time=400, delay=150, yScale=0, transition=easing.outExpo } )
				if( powerUp.name == "pill" ) then
				    if ( self.pillSound ) then
					   mainScene.sound:playVoice( self.pillSound, 0.3 )
					   self.pillSound = nil
					end
					mainScene.player.health = mainScene.player.health + 1
					if( mainScene.player.health > 4 ) then
					   mainScene.player.health = 4
					end
					mainScene.ui:updateHealthMeter()
				end
				if( powerUp.name == "specialPower" ) then
					mainScene.specialPowers:addToMeter()
				end
				if( powerUp.name == "shoutout" ) then
					mainScene.sound:playVoice( self.shoutoutSound )
    				mainScene:addPoints(300)
				end
				if( powerUp.name == "sag" ) then
					mainScene:addPoints(100)
				end
			end
        end
		
		if( powerUp.bRemove == true ) then
            powerupDispose( powerUp )
            
			table.remove( self.activePowerUps, i )
		end
			
		i = i - 1
	end

end

function powerUps:forceSpawn(num, delay)
    if( not delay ) then
        delay = 0
    end
    local go = function()
        spawn(num)
    end
    
    timer.performWithDelay( delay, go )
end

function powerUps:init(scene)
	mainScene = scene
	self.bonusSound = scene.sound:loadBonusSound( "bonus.wav" )
	self.shoutoutSound = scene.sound:loadVoice( "shoutout.wav" )
	self.sagVoucherSound = scene.sound:loadVoice( "voice-" .. mainScene:getSelectedCharacter() .. "SagVoucher.wav" )
	if( mainScene:getSelectedCharacter() == "perry" or mainScene:getSelectedCharacter() == "mole" ) then
        self.pillSound = scene.sound:loadVoice( "voice-" .. mainScene:getSelectedCharacter() .. "Pills.wav" )
    end
end

function powerUps:destroy()
    for i, powerUp in ipairs( self.activePowerUps ) do
        powerupDispose( powerUp )
    end
    self.activePowerUps = nil
    audio.dispose( self.pillSound )
    audio.dispose( self.shoutoutSound )
	audio.dispose( self.bonusSound )
	audio.dispose( self.sagVoucherSound )
    self.pillSound = nil
    self.shoutoutSound = nil
    self.bonusSound = nil
    self.sagVoucherSound = nil
	mainScene.powerUps = nil
	mainScene = nil
end

return powerUps
