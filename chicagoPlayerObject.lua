local mainScene = nil
local invisbilityTime = 1500
local kCollisionDistance = 60
local GA = require ( "GameAnalytics" )

local playerObject = {
    
}

local function doQuadraticBezierCurve(point1, point2, point3, t)
    local a = (1.0 - t) * (1.0 - t);
    local b = 2.0 * t * (1.0 - t);
    local c = t * t;
    
    local x = math.floor( a * point1.x + b * point2.x + c * point3.x )
    local y = math.floor( a * point1.y + b * point2.y + c * point3.y )
		
    return x,y
end

local function executeJump( self )
    if( self.bJumping ) then
        self.avatar:setSequence( "jump" )
        --if( self.bDashing ) then
         self.avatar:play()
        --end
        self.bJumpDisabled = true
        self.avatar.y = self.avatar.y - ( ( self.maxHorizontalVelocity * mainScene.timeScale ) * ( 60 / display.fps ) )
        if( self.avatar.y <= self.maxJumpHeight ) then
            self.bFalling = true
            self.bJumping = false
        end
    elseif( self.bFalling ) then
        if( not self.point1 ) then
            self.point1 = {x=self.avatar.x,y=self.avatar.y}
            self.point2 = {x=self.avatar.x,y=self.avatar.y-75}
            self.point3 = {x=self.avatar.x,y=mainScene.groundY}
            self.t = 0 
        end

        if( math.abs( self.avatar.y - mainScene.groundY ) < 35 ) then
            self.bJumpDisabled = false
        end
        
        self.t = self.t + ( self.maxHorizontalVelocity * .0023 * ( 60 / display.fps ) )
        if ( self.t > 1 ) then
            if( self.bDashing ) then
            	self.avatar:setSequence("dash")
            else
            	self.avatar:setSequence("run")
            end
            self.avatar:play()
            self.bFalling = false
            self.avatar.y = mainScene.groundY - self.avatar.yOffset
        else
         self.avatar.x,self.avatar.y = doQuadraticBezierCurve( self.point1, self.point2, self.point3, self.t )
        end
    end
end

local function stopDash()
    mainScene.player.avatar:setSequence( "run" )
    mainScene.player.avatar:play()
	mainScene.player.dashTime = system.getTimer()
	mainScene.player.bDashing = false
	mainScene.player.bDashingResidual = true
	
	local delayFunc = function()
	   mainScene.player.bDashingResidual = false
	end
	
	timer.performWithDelay( 600, delayFunc, 1 )
	
	mainScene.city:setSpeed( nil,0.1 )
    if( mainScene.bSmoggy ) then
        mainScene.player.dashEffect.isVisible = false
        return
    end
    
    if( mainScene.player.dashTransition ) then
        transition.cancel( mainScene.player.dashTransition )
    end
    mainScene.player.dashTransition = nil
    local myTransition = transition.to( mainScene.player.dashEffect, { time=301, delay=0, alpha=0} )
    
    local function hide()
        --if( mainScene.player.dashEffect.alpha <= 0 ) then
            mainScene.player.dashEffect.isVisible = false
            if( mainScene.player.dashTransition ) then
                transition.cancel( mainScene.player.dashTransition )
            end
            mainScene.player.dashTransition = nil
            if( myTransition ) then
                transition.cancel( myTransition )
            end
            myTransition = nil
        --end
    end
    timer.performWithDelay( 300, hide, 1 )
end

local function doDamage(self, obj, bEnemy)
	if( not self.damageTime and not mainScene.specialPowers.bPowerActive and not self.bDashingResidual ) then
		  self.health = self.health - 1
		  mainScene.ui:doDamage()		  
		  mainScene.sound:playDamageSound( self.hitSound )
          if( obj ) then
            if ( obj.name ) then
                if( bEnemy ) then
                    table.insert( self.enemyEvents, "chicago:hitByEnemy:" .. obj.name )
                else
                    table.insert( self.obstacleEvents, "chicago:hitByObstacle:" .. obj.name )
                end
                if( self.health <= 0 ) then
                    for i, event in ipairs( self.enemyEvents ) do
                        GA.newEvent( "design", { event_id=event})
                    end
                    for i, event in ipairs( self.obstacleEvents ) do
                        GA.newEvent( "design", { event_id=event})
                    end
                    GA.newEvent( "design", { event_id="chicago:killedBy:" .. obj.name})
                    self.avatar:setSequence("death")
                    self.avatar:play()
                    if( obj.contentBounds ) then
                        if( obj.name and ( obj.name == "redBat" or obj.name == "basketball" ) ) then
                            self.avatar.x = obj.x - 10
                            self.avatar.y = obj.y + (self.avatar.height/2)
                        else
                            while ( self.avatar.contentBounds.xMax < obj.contentBounds.xMin + 20 ) do
                                self.avatar.x = self.avatar.x + 1
                            end
                            while ( self.avatar.contentBounds.yMax < obj.contentBounds.yMin + 20 ) do
                                self.avatar.y = self.avatar.y + 1
                            end
                        end
                    end
                    
              end
                   
                    if( obj.name == "redBat" or obj.name == "basketball" ) then
                        obj:toFront()
                    end
                end
            end
            
             
          local num = math.random( 3 )
          if( num < 3 ) then
            mainScene.sound:playVoice( self.ouchSound, 0.25 )
          end
		  mainScene:showDamageHit( self.avatar.x + (self.avatar.width/4), self.avatar.y - (self.avatar.height/2) )
		  self.damageTime = system.getTimer()
		  if( self.health <= 0 ) then
               if( self.gameOverDialog ) then
                    mainScene.sound:playVoice( self.gameOverDialog, 0.1, true, true  )
              end
		      mainScene:gameOver()
		  end
	end
end

local function evalDamage(self)
    if( self.damageTime ) then
        if( not self.damageCounter ) then
			
            self.damageCounter = 0
        end
		
        if( self:isInvincible() ) then
            self.damageCounter = self.damageCounter + 1
            if ( self.damageCounter > 3 ) then
                if( self.avatar.alpha == 1 ) then
                    self.avatar.alpha = 0.25
                else
                    self.avatar.alpha = 1
                end
                self.damageCounter = 0
            end
        else
            self.avatar.alpha = 1
            self.damageTime = nil
            self.damageCounter = 0
        end
    end
end

function playerObject:dash()
	if( system.getTimer() - self.dashTime < 1000 ) then
		return
	end
	if( not self.bDashing ) then
        audio.play( self.dashSound )
		self.dashTime = system.getTimer()
	    if( self.bJumping or self.bFalling ) then
			self.avatar:setSequence( "jump" )
        else
			self.avatar:setSequence( "dash" )
		end
		self.bDashing = true

		self.avatar:play()
		mainScene.city:setSpeed( -30,0.06 )
        --if( not mainScene.storyboard.state.bPlayedChicago and system.getInfo("platformName") == "Android" ) then
            self.dashEffect.isVisible = true
            self.dashEffect:play()
            self.dashEffect.alpha = 0
            self.dashTransition = transition.to( self.dashEffect, { time=1000, delay=0, alpha=0.6} )
        --end
    end
end

function playerObject:isInvincible()
    if( not self.damageTime ) then
        return false
    end
    return ( system.getTimer() - self.damageTime ) < invisbilityTime
end

function playerObject:doGenericDamage()
    doDamage( self, nil, true )
end

function playerObject:doEnemyCollision( enemy )
	if( not enemy ) then
		return
	end
	if( mainScene.specialPowers.bPowerActive ) then
        return
    end
	if( self.bDashing or self.bDashingResidual ) then
		enemy.health = 0
        mainScene:doExplosion( enemy, enemy.explosionScale)
	else
        
		doDamage( self, enemy, true )
	end
end

function playerObject:doObstacleCollision( obstacle )
    if( not obstacle ) then
        return
    end
    if( ( not self.damageTime and not self.bDashing ) ) then
        doDamage( self, obstacle )
    end
end

function playerObject:setJumping( bSet )
    if( bSet and not self.bJumping and not self.bJumpDisabled ) then
        self.bJumping = true
        self.point1 = nil
    elseif( not bSet and not self.bFalling and self.bJumpDisabled ) then
        self.bJumping = false
        self.bFalling = true
    end
    
    if( bSet and not self.bJumpDisabled and self.bFalling ) then
        self.point1 = nil
        self.bFalling = false
        self.bJumping = true
        self.avatar.y = mainScene.groundY - self.avatar.yOffset
    end
end

function playerObject:init(scene)
    mainScene = scene
	
	self.avatar = nil
    self.defaultRestPosition = nil
    self.maxJumpHeight = nil
    self.maxHorizontalVelocity = 19
    self.bJumping = false
    self.bJumpingDisabled = false
    self.bFalling = false
    self.bDashing = false
    self.damageTime = nil
    self.damageCounter = nil
    self.dashMeter = 1
    self.dashIncreaseAmt = 0.002
    self.dashDecreaseAmt = 0.015
    self.dashTime = 0
    self.health = 0
    self.obstacleEvents = {}
    self.enemyEvents = {}
    
    self.dashSound = audio.loadSound( "sounds/dash.wav" )
	
    if( mainScene:getSelectedCharacter() == "don" and math.random( 3 ) == 3 ) then
        self.gameOverDialog = mainScene.sound:loadVoice( "voice-donDeath2.wav" )
    else
        self.gameOverDialog = mainScene.sound:loadVoice( "voice-" .. mainScene:getSelectedCharacter() .. "Death.wav" )
    end
    
    self.defaultRestPosition = scene.leftEdge + 120
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    local avatarSheet = nil
	if( mainScene:getSelectedCharacter() == "perry" ) then
		avatarSheet = graphics.newImageSheet( "images/perryAnim.png", { width=64, height=64, numFrames=25 } )
		self.avatar = display.newSprite( avatarSheet, {{ name = "idle", start=7, count=16, time=1600, loopCount=0 }, { name = "run", start=1, count=4, time=400, loopCount=0 },{ name = "dash", start=5, count=2, time=300, loopCount=0 },{ name = "jump", start=23, count=2, time=100, loopCount=0 },{ name = "death", start=25, count=1, time=300, loopCount=1 }} )
		self.avatar:setSequence( "idle" )
		self.avatar:play()
        self.avatar.normalChoke = 20
        self.avatar.yOffset = 0
		elseif( mainScene:getSelectedCharacter() == "mole" ) then
		avatarSheet = graphics.newImageSheet( "images/moleAnim.png", { width=64, height=64, numFrames=36 } )
		self.avatar = display.newSprite( avatarSheet, {{ name = "idle", start=27, count=7, time=750, loopCount=1 }, { name = "run", start=1, count=8, time=700, loopCount=0 }, { name = "blowStart", start=9, count=8, time=400, loopCount=1 }, { name = "blow", start=17, count=9, time=400, loopCount=0 },{ name = "death", start=34, count=3, time=700, loopCount=1 }} )
		self.avatar.xScale = 1.15
		self.avatar.yScale = 1.15
        self.avatar.yOffset = 0
        self.avatar.normalChoke = 20
		self.avatar:setSequence( "idle" )
	self.avatar:play()
	   self.avatar.normalChoke = 10
	elseif( mainScene:getSelectedCharacter() == "don" ) then
        avatarSheet = graphics.newImageSheet( "images/donAnim.png", { width=64, height=64, numFrames=53 } )
		self.avatar = display.newSprite( avatarSheet, {{ name = "idle", start=1, count=29, time=character2, loopCount=1 }, { name = "run", start=30, count=9, time=700, loopCount=0},{ name = "dash", start=40, count=4, time=320, loopCount=0 },{ name = "jump", start=44, count=4, time=100, loopCount=0 },{ name = "death", start=48, count=6, time=300, loopCount=0 }} )
		--self.avatar.xScale = -1.15
		--self.avatar.yScale = 1.15
        self.avatar:setSequence( "idle" )
		self.avatar:pause()
		self.avatar.normalChoke = 20
        self.avatar.yOffset = 0
	end
		
    
	--self.avatar = display.newImageRect( "images/perrytest2x.png", 64, 64 )
	self.avatar.anchorX = 0.5
	self.avatar.anchorY = 1
	self.avatar.x, self.avatar.y = 200, mainScene.groundY - self.avatar.yOffset

    --self.bJumping = true
    
    self.maxJumpHeight = mainScene.groundY - 180
    		
	mainScene.city.displayGroup:insert( self.avatar )
	
	self.health = 4
    
    mainScene.effectsGroup = display.newGroup()
    
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    
    local dashSheet = graphics.newImageSheet( "images/dashAnim.gif", { width=256, height=186, numFrames=15 } )
    self.dashEffect = display.newSprite( dashSheet, {{ name = "loop", start=1, count=15, time=850, loopCount=0 }} )
    
    self.dashEffect.anchorX = 0.5
	self.dashEffect.anchorY = 0.5
	self.dashEffect.x = display.contentCenterX
	self.dashEffect.y = display.contentCenterY
	self.dashEffect.blendMode = "screen"
	self.dashEffect.xScale = display.actualContentWidth / self.dashEffect.width * -1
	self.dashEffect.yScale = display.actualContentHeight / self.dashEffect.height
	self.dashEffect.alpha = 0.5
    self.dashEffect.isVisible = false

	mainScene.effectsGroup:insert( self.dashEffect )
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
    
	
	self.hitSound = scene.sound:loadDamageSound( "playerDamage.wav" )
    self.ouchSound = scene.sound:loadVoice( "voice-" .. mainScene:getSelectedCharacter() .. "Ouch.wav" )
    
    -- Play Don's "3, 2, 1, GOOOOO" audio to freak people out.
    if( mainScene:getSelectedCharacter() == "don" ) then
        local go = scene.sound:loadVoice( "voice-donGo.wav" )
        
        local playVoice = function()
            mainScene.sound:playVoice( go, 0.25 )
        end
        
        local dispose = function()
            audio.dispose( go )
            go = nil
        end
        
        local shake = function()
            system.vibrate()
        end
        
        local delay = 1100
        local platform = system.getInfo( "platformName" )
        if( platform == "Android" ) then
            delay = 1350 + 500
        end
        
        timer.performWithDelay( 5, playVoice, 1 )
        timer.performWithDelay( delay, shake, 1 )
        timer.performWithDelay( 4000, dispose, 1 )
    end
end

function playerObject:update()
    local restPosition = self.defaultRestPosition + ( mainScene.city.displayGroup.x * -1 )
    
    if( not self.bPauseJump ) then
    -- Execute jumps, if the player is currently jumping.
        executeJump( self )
    end
    
    -- Should we be flashing the player because they received damage?
    evalDamage( self )
    
    if( self.bDashing ) then
        self.avatar.xChoke = self.avatar.normalChoke * -1.5
        self.avatar.collisionDistance = kCollisionDistance * 1.5
        self.avatar.collisionDistance = kCollisionDistance * 1.5
    	self.dashMeter = self.dashMeter - ( self.dashDecreaseAmt * ( 60 / display.fps ) )
    	if ( self.dashMeter <= 0 ) then
    		self.dashMeter = 0
    		stopDash()
    	end
    else
        self.avatar.xChoke = self.avatar.normalChoke
        self.avatar.yChoke = self.avatar.normalChoke
        self.avatar.collisionDistance = kCollisionDistance
    	if( self.dashMeter < 1 ) then
    		if( system.getTimer() - self.dashTime < 1000 ) then
    			self.dashMeter = 0
    		else
    			self.dashMeter = self.dashMeter + self.dashIncreaseAmt
    		end
    	end
    end
    
    if( not self.counter ) then
        self.counter = 0
    end
    self.counter = self.counter + 1
    
    if( self.counter > 5 ) then
        self.counter = 0
    --local frame = self.avatar.currentFrame\
    
    if( not mainScene.player.avatar.bDoNotScale ) then
        self.avatar.timeScale = math.abs( mainScene.city:getSpeed() ) / 6
        if( self.avatar.timeScale > 2 ) then
            self.avatar.timeScale = 2
        end
    end

    --self.avatar.currentFrame = frame
        end
        
    if( mainScene:getSelectedCharacter() == "don" and self.bDashing ) then
        self.avatar.timeScale = 1
    end
    if( mainScene.ui ) then
        mainScene.ui:updateDashMeter( self.dashMeter )
    end
    
    if( self.avatar.x > restPosition ) then
    	if( math.abs( self.avatar.x - restPosition ) <= math.abs( mainScene.city.curSpeed ) ) then
    	
			self.avatar:setSequence( "run" )
			self.avatar:play()
        	self.avatar.x = restPosition
     	end
    else
    	self.avatar.x = restPosition
    end
    if( mainScene.specialPowers.effect and not mainScene.specialPowers.effect.sortAtTop ) then
        mainScene.specialPowers.effect:toFront()
    end

    self.avatar:toFront()
    
    if( mainScene.specialPowers.effect and mainScene.specialPowers.effect.sortAtTop ) then
        mainScene.specialPowers.effect:toFront()
    end
end

function playerObject:destroy()
    display.remove( mainScene.effectsGroup )
    self.bJumping = nil
    self.bFalling = nil
    self.point1 = nil
    self.point2 = nil
    self.point3 = nil
    self.t = nil
    self.avatar:removeSelf()
    self.avatar = nil
    self.dashEffect:removeSelf()
    self.dashEffectg = nil
    audio.dispose( self.hitSound )
    audio.dispose( self.ouchSound )
    audio.dispose( self.dashSound )
    self.gameOverDialog = nil
	mainScene = nil
	self.damageTime = nil
    
end

return playerObject;