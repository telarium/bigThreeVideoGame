local mainScene = nil
local analogAtan2 = math.atan2;
local analog180overPi = ( 180 / math.pi );
local prevTime = system.getTimer()

local specialPowers = {
    
}


local function rotateEffect(self)
    local x,y = mainScene.city.displayGroup:localToContent( self.effect.x, self.effect.y )
    local deltaX = mainScene.rightEdge - x
    local deltaY = display.contentCenterY - y - 20
    self.effect.rotation = analogAtan2(deltaY, deltaX) * analog180overPi
end

local function updateEffectY(self)
    if( mainScene.specialPowers.effect.bDoNotAttach ) then
        return
    end
    self.effect.y = mainScene.player.avatar.y - self.effect.yOffset
    self.effect.x = mainScene.player.avatar.x - self.effect.xOffset
end


local function mySpriteListener( event )
  if ( event.phase == "ended" ) then
    event.target.isVisible = false
    event.target.frameNum = 0
    mainScene.specialPowers.bPowerActive = false
    mainScene.player.avatar.bDoNotScale = false
    
  elseif( event.phase == "next" ) then
    if( mainScene:getSelectedCharacter() == "mole" and event.target.frameNum < 2 ) then
        mainScene.specialPowers.allowRotation = true
        updateEffectY( mainScene.specialPowers )
    elseif( mainScene:getSelectedCharacter() == "mole" and event.target.frameNum < 16 ) then
     mainScene.player.bPauseJump = true
     mainScene.specialPowers.effect.bDoNotAttach = true
     mainScene.specialPowers.allowRotation = false
     
     mainScene.city:setSpeed( 0, 0.2 )
     
     local delay = function()
        if( not mainScene.player.bSetCallback ) then
            mainScene.player.bSetCallback = true
            mainScene.player.avatar:setSequence( "run" )
            
            mainScene.player.avatar:play()
        end
    end
    
    local myDelay = timer.performWithDelay( 1000, delay )

     updateEffectY( mainScene.specialPowers )
    elseif( event.target.frameNum == 16 ) then
        mainScene.specialPowers.allowRotation = false
        mainScene.player.bPauseJump = false
        mainScene.city:setSpeed(nil, 0.05)
    end
    event.target.frameNum = event.target.frameNum + 1
    --event.target.rotation = event.target.rotation + 1
  end
end

local function loadLightning(self)
    local effectSheet = graphics.newImageSheet( "images/blueLightningAnim.png", { width=480, height=50, numFrames=34 } )
    self.effect = display.newSprite( effectSheet, {{ name = "sequence", start=1, count=34, time=2300, loopCount=1 }} )
    self.effect.xScale = display.actualContentWidth / self.effect.width
	self.effect.yScale = self.effect.xScale
	self.effect.anchorX = 0
	self.effect.anchorY = 0.5
	self.effect.x = mainScene.leftEdge
	self.effect.y = mainScene.bottomEdge
    self.effect.yReference = 12
    self.effect.y = display.contentCenterY
	self.effect.blendMode = "add"
    self.effect.frameNum = 0
    self.effect.isVisible = false
    self.effect.xOffset =  21
    self.effect.yOffset = 51
	self.effect:setSequence( "sequence" )
	self.effect.sortAtTop = true
	self.allowRotation = false
	self.tauntSound1 = mainScene.sound:loadVoice("voice-donPower2.wav" )
    self.tauntSound2 = mainScene.sound:loadVoice("voice-donPower1.wav" )
    self.powerSound = mainScene.sound:loadVoice("lightning.wav")
    self.zapSound1 = mainScene.sound:loadVoice("zap1.wav")
    self.zapSound2 = mainScene.sound:loadVoice("zap2.wav")
    
    self.effect.onDestroyObject = function()
        if( not self.effect.timeSinceZapSound ) then
            self.effect.timeSinceZapSound = 0
        end
        
        if( system.getTimer() - self.effect.timeSinceZapSound < 500 ) then
            return
        end
        
        self.effect.timeSinceZapSound = system.getTimer()
        
        if( math.random(2)==2) then
             mainScene.sound:playVoice( self.zapSound1, 0, true )
        else
            mainScene.sound:playVoice( self.zapSound2, 0, true )
        end
    end
end


local function loadScream(self)
    local effectSheet = graphics.newImageSheet( "images/perryScreamAnim.jpg", { width=240, height=180, numFrames=41 } )
    self.effect = display.newSprite( effectSheet, {{ name = "sequence", start=1, count=41, time=1600, loopCount=1 }} )
    self.effect.xScale = display.actualContentWidth / self.effect.width
	self.effect.yScale = self.effect.xScale
    self.effect.anchorX = 0
	self.effect.anchorY = 0.5
	self.effect.x = mainScene.leftEdge
	self.effect.y = mainScene.bottomEdge
    self.effect.yReference = 12
    self.effect.y = display.contentCenterY
	self.effect.blendMode = "add"
    self.effect.frameNum = 0
    self.effect.isVisible = false
    self.effect.xOffset = 5
    self.effect.yOffset = 40
    self.effect.sortAtTop = false
	self.effect:setSequence( "sequence" )
	self.allowRotation = true 
    self.powerSound = mainScene.sound:loadVoice("perryScream.wav")
    self.tauntSound1 = mainScene.sound:loadVoice("voice-perryPower1.wav" )
    self.tauntSound2 = mainScene.sound:loadVoice("voice-perryPower2.wav" )
    self.coughSound = mainScene.sound:loadVoice("voice-perryCough.wav" )
    self.coughTime = system.getTimer()
end

local function loadSmoke(self)
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    local effectSheet = graphics.newImageSheet( "images/appleCherrywoodAnim.png", { width=240, height=135, numFrames=32 } )
    self.effect = display.newSprite( effectSheet, {{ name = "sequence", start=1, count=32, time=1780, loopCount=1 }} )
    self.effect.xOffset = -11
    self.effect.yOffset = 100

    self.effect.xScale = ( display.actualContentWidth - 60) / self.effect.width
	self.effect.yScale = display.actualContentHeight / self.effect.height
    self.effect.anchorX = 0
	self.effect.anchorY = 0.5
	self.effect.x = mainScene.leftEdge
	self.effect.y = mainScene.bottomEdge
	self.effect.blendMode = "screen"
    self.effect.yReference = 12
    self.effect.sortAtTop = false
	display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )      
	self.effect:setSequence( "sequence" )
	self.allowRotation = false
	self.powerSound = mainScene.sound:loadVoice("acwt.wav")
    self.tauntSound1 = mainScene.sound:loadVoice("voice-molePower.wav" )
    self.donSound = mainScene.sound:loadVoice("voice-donACWT.wav" )
end


local function doDonDamage(y, obj)
    local x = 0
    x,y = mainScene.city.displayGroup:localToContent( x,y )
    if( obj.contentBounds.yMax <= y + 100 and obj.contentBounds.yMin >= y - 100 ) then
        if( obj.contentBounds.xMin <= mainScene.rightEdge - 30 ) then
            return true
        end
    else
        return false
    end
end

local function applyDamage(self)
    if( mainScene.player.bWaitForPowerDamage ) then
        return
    end
    if( mainScene:getSelectedCharacter() == "don" ) then
        local aliveObjects = mainScene.obstacles:getActive(false)
        for i=1,table.getn( aliveObjects ) do
            if( doDonDamage( self.effect.y, aliveObjects[i] ) ) then
                mainScene.obstacles:doCollision(aliveObjects[i].group)
                self.effect.onDestroyObject()
                break;
            end
        end
        
        -- Kill all enemies past this X coordinate
        local aliveEnemies = mainScene.enemies:getActive()
        for i=1,table.getn( aliveEnemies ) do
                if( aliveEnemies[i].bSpecialPowerImmunity or aliveEnemies[i].bImmortal ) then
                    --aliveEnemies[i].health = aliveEnemies[i].health - 1
                else
                    if( doDonDamage( self.effect.y, aliveEnemies[i] ) ) then
                        aliveEnemies[i].health = 0
                        mainScene:doExplosion( aliveEnemies[i], aliveEnemies[i].explosionScale)
                        mainScene:addPoints(350)
                        self.effect.onDestroyObject()
                    end
                end
                
        end
    else
        if( mainScene:getSelectedCharacter() == "mole" ) then
          self.powerX = self.powerX + ( 10 * ( 60 / mainScene.fps ) )
        else
            self.powerX = self.powerX + ( 12 * ( 60 / mainScene.fps ) )
        end
        -- Apply damage to all obstacles past this X coorinate.
        local aliveObjects = mainScene.obstacles:getActive(true)
        for i=1,table.getn( aliveObjects ) do
            if(aliveObjects[i].x <= self.powerX ) then
                mainScene.obstacles:doCollision(aliveObjects[i].group)
                if(  self.effect.onDestroyObject ) then
                    self.effect.onDestroyObject()
                end
            end
        end
        
        -- Kill all enemies past this X coordinate
        local aliveEnemies = mainScene.enemies:getActive()
        for i=1,table.getn( aliveEnemies ) do
            if(aliveEnemies[i].x <= self.powerX ) then
                if( aliveEnemies[i].bSpecialPowerImmunity or aliveEnemies[i].bImmortal ) then
                    --aliveEnemies[i].health = aliveEnemies[i].health - 1
                else
                    aliveEnemies[i].health = 0
                    mainScene:doExplosion(aliveEnemies[i], aliveEnemies[i].explosionScale )
                    mainScene:addPoints(300)
                    if( self.effect.onDestroyObject ) then
                        self.effect.onDestroyObject()
                    end
                end
                
            end
        end
    end
    
    local weapons = mainScene.weapons:getActive()
    for i=1,table.getn( weapons ) do
        if(weapons[i].x <= self.powerX + 20 ) then
            mainScene.weapons:discard( weapons[i] )
        end
    end
end

function specialPowers:addToMeter()
	mainScene.specialPowers.powerMeter = 1
    mainScene.specialPowers.bPowerActive = false
	--if( mainScene.specialPowers.powerMeter > 1 ) then
	--   mainScene.specialPowers.powerMeter = 1
	--end
	if( mainScene.bSmoggy or mainScene.bVinceAlive ) then
	   return
	end
	mainScene.ui:setButtonReminder( mainScene.ui.specialPowersButton, true )
	
	if( not storyboard.state.bTutorialRequired ) then
        if( self.tauntSound1 ) then
           mainScene.sound:playVoice( self.tauntSound1, 0.1 )
           self.tauntSound1 = nil
        elseif( self.tauntSound2 ) then
           mainScene.sound:playVoice( self.tauntSound2, 0.1 )
           self.tauntSound2 = nil
        end
    end
end

function specialPowers:start()
    if( mainScene.specialPowers.bPowerActive ) then
        return
    end
    
    if( mainScene:getSelectedCharacter() == "perry" and mainScene.bSmoggy ) then
        if( system.getTimer() - self.coughTime >= 3000 ) then
            self.coughTime = system.getTimer()
           mainScene.sound:playVoice( self.coughSound, 0, true )
        end
        return
    elseif( mainScene:getSelectedCharacter() == "mole" and mainScene.bSmoggy ) then
        mainScene.bRemoveSmog = true
    else
        if( not mainScene.player.avatar.powerUpdate ) then
            local update = function()
                if( mainScene and not mainScene.bGameOver ) then
                    updateEffectY(self)
                else
                    timer.cancel( mainScene.player.avatar.powerUpdate )
                end
            end
        
            mainScene.player.avatar.powerUpdate = timer.performWithDelay( 1, update, -1 )
            
        end
    end
    
    mainScene.specialPowers.activateTime = system.getTimer()
    
    self.effect.isVisible = true
    mainScene.specialPowers.bPowerActive = true
    self.powerX = mainScene.player.avatar.x - self.effect.xOffset
    
    if( mainScene:getSelectedCharacter() == "mole" ) then
         mainScene.player.avatar.bDoNotScale = true
         mainScene.player.bPauseJump = true
         self.effect.isVisible = false
         self.effect.bDoNotAttach = false

        local delayFunct = function()
                mainScene.player.avatar:setSequence( "blow" )
                mainScene.player.avatar:play()
                self.effect.isVisible = true
                self.effect:play()
                mainScene.sound:playVoice( self.powerSound, 0, true )
                mainScene.player.bSetCallback = false
                mainScene.player.bWaitForPowerDamage = false
                mainScene.player.avatar:removeEventListener( "sprite", mySpriteListener )
        end

        mainScene.player.avatar:setSequence( "blowStart" )
        mainScene.player.avatar:play()
        
        if( mainScene.player.bFalling or mainScene.player.bJumping ) then
            if( mainScene.player.bJumping ) then
                mainScene.player.bFalling = true
                mainScene.player.bJumping = false
            end
            mainScene.player.avatar:setFrame( 4 )
            mainScene.player.bWaitForPowerDamage = false
            timer.performWithDelay( 200, delayFunct )
        else
            mainScene.player.bWaitForPowerDamage = true
            timer.performWithDelay( 600, delayFunct )
        end
    else
        self.effect:play()
        mainScene.sound:playVoice( self.powerSound, 0, true )
    end

	if( mainScene:getSelectedCharacter() == "perry" ) then
	   system.vibrate()
	elseif( mainScene:getSelectedCharacter() == "mole" and math.random(3) == 2 ) then
	   if( not storyboard.bPlayedDonACWT ) then
	       mainScene.sound:playVoice( self.donSound, 1.55, true )
	       storyboard.bPlayedDonACWT = true
	   end
    end
end



function specialPowers:update()
   -- if( ( system.getTimer() - prevTime ) > 200 ) then
        mainScene.ui:updatePowerMeter( self.powerMeter )
    --end
    prevTime = system.getTimer()

	
    if( mainScene.specialPowers.bPowerActive ) then
        applyDamage(self)
    
        if( mainScene.specialPowers.effect.bDoNotAttach ) then
            return
        end
        self.effect.x = mainScene.player.avatar.x - self.effect.xOffset
        if( mainScene:getSelectedCharacter() ~= "mole" ) then
             updateEffectY(self)
        end
		mainScene.specialPowers.powerMeter = mainScene.specialPowers.powerMeter - ( 0.02 * ( 60 / mainScene.fps ) )
		if( mainScene.specialPowers.powerMeter < 0 ) then
			mainScene.specialPowers.powerMeter = 0
		end
        
        if( self.allowRotation or mainScene:getSelectedCharacter() == "perry" ) then
            rotateEffect(self)
         end
    end
end

function specialPowers:init(scene)
    mainScene = scene
	
    mainScene.specialPowers.activateTime = system.getTimer()
    
	self.effect = nil
    self.allowRotation = false
    self.bPowerActive = false
    self.powerX = 0
	self.powerMeter = 1

	if( mainScene:getSelectedCharacter() == "mole" ) then
		loadSmoke(self)
	elseif( mainScene:getSelectedCharacter() == "perry" ) then
		loadScream(self)
	elseif( mainScene:getSelectedCharacter() == "don" ) then
		loadLightning(self)
	end
    
    self.effect.frameNum = 0
    self.effect.isVisible = false
    scene.city.displayGroup:insert( self.effect )
    
    self.effect:addEventListener( "sprite", mySpriteListener )
    
end

function specialPowers:checkSpawn()
    -- Temporarily disable spawning after using the player's special power
    if( mainScene:getSelectedCharacter() == "don" ) then
        if ( system.getTimer() - mainScene.specialPowers.activateTime < 200 ) then
            return true
        end
    elseif( mainScene:getSelectedCharacter() == "mole" ) then
        if ( system.getTimer() - mainScene.specialPowers.activateTime < 1600 ) then
            return true
        end
    else
        if ( system.getTimer() - mainScene.specialPowers.activateTime < 2800 ) then
            return true
        end
    end
end

function specialPowers:destroy()
    self.effect:removeSelf()
    self.effect = nil
    mainScene.specialPowers.activateTime = nil
    if( self.tauntSound1 ) then
        audio.dispose( self.tauntSound1 )
        self.tauntSound1 = nil
    end
    if( self.tauntSound2 ) then
        audio.dispose( self.tauntSound2 )
        self.tauntSound2 = nil
    end
    if( self.powerSound ) then
	   audio.dispose( self.powerSound )
	   self.powerSound = nil
	end
	if( self.donSound ) then
	   audio.dispose( self.donSound )
	   self.donSound = nil
	end
	mainScene.specialPowers = nil
	mainScene = nil
end

return specialPowers;