local mainScene = nil
local prevTime = system.getTimer()
local throttleTime = 135
local spriteSheet = nil

local weaponObjects = {
    counter = 1
}

local function mySpriteListener( event )
  if ( event.phase == "ended" ) then
    event.target:removeSelf()
  end
end

local function doCookieExplosion(cookie)
    if( cookie.bDisarmed ) then
        return
    end
    cookie.bDisarmed = true
    
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    
    local explosion = display.newSprite( spriteSheet, {{ name = "sequence", start=1, count=7, time=200, loopCount=1 }} )
    local flip = math.random(2)
    if( flip == 2 ) then
        flip = -1
    end
    explosion.xScale = flip
	explosion.yScale = 1
    explosion.anchorX = 0.5
	explosion.anchorY = 0.5
	explosion.x = cookie.x + 15
	explosion.y = cookie.y + 2
	explosion:setSequence( "sequence" )
	explosion:play()
    mainScene.city.displayGroup:insert( explosion )
    explosion:toFront()
    explosion:addEventListener( "sprite", mySpriteListener )
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" ) 
end

local function doBatExplosion(bat, bBounce)
	if( bat.bDisarmed ) then
        return
    end
    bat.x = bat.x + 5
    bat.bDisarmed = true
	if( not bBounce ) then
	   bat.bForceRemove = true
	   return
	end
	--
    
    local d = 1.5
    local b = 0.4
    
    if( mainScene:getSelectedCharacter() == "don" ) then
        d = 3
        b = 0.3
    end
    
    mainScene:setPhysics( true )
    mainScene.physicsWeapons = mainScene.physicsWeapons + 1
	physics.addBody( bat, { density = d, friction = 0.3, bounce = b } )
    bat.bPhysics = true
    if( bat.applyLinearImpulse ) then
       
        bat:applyLinearImpulse( math.random(2)*-1,math.random(3), bat.x, bat.y )
        
        --bat:applyAngularImpulse( -45 )
    end
end

local function isOffScreen(weapon)
    if( weapon.bForceRemove ) then
        return true
    end
    local x,y = mainScene.city.displayGroup:contentToLocal( mainScene.rightEdge, mainScene.foldY )
    if ( weapon.x > x + weapon.width/2 ) then
        return true
    end
    x,y = mainScene.city.displayGroup:contentToLocal( mainScene.leftEdge, mainScene.foldY )
    if( weapon.x < x - weapon.width/2 ) then
        return true
    end
end

local function isCollidingWithObstacle(self, weapon)
    if( mainScene.specialPowers.bPowerActive ) then
        return
    end
    -- Only test collision against objects that are "alive." (Not already colliding with player, are tested for collision, etc)
    local activeObstacles = mainScene.obstacles:getActive(true)
    local bHit = false
    for i=1,table.getn( activeObstacles ) do
		-- When counter is 1, only check i if it's an odd number. If counter is 2, check evens.
		-- Trying to optimize all these checks if there are a lot of weapons flying around.
		--if( i <= 1 or (self.counter == 1 and math.mod(i, 2) ~= 0 ) or ( math.mod(i, 2) == 0 and self.counter == 2 ) ) then
        if( not mainScene.specialPowers.bPowerActive and activeObstacles[i].doObstacleCollisionCheck and not weapon.bDisarmed and mainScene:checkCollision(weapon, activeObstacles[i] ) ) then
            bHit = true
            
            if( not mainScene.weapons.lastSoundTime ) then
                mainScene.weapons.lastSoundTime = 0
            end
            
            if( mainScene.weapons.bounceSound1 and ( system.getTimer() - mainScene.weapons.lastSoundTime > 300 ) ) then
                local num = 0
                mainScene.weapons.lastSoundTime = system.getTimer()
                if( mainScene:getSelectedCharacter() == "perry" ) then
                    num = math.random(3)
                elseif( mainScene:getSelectedCharacter() == "mole" ) then
                    num = math.random(6)
                elseif( mainScene:getSelectedCharacter() == "don" ) then
                    num = math.random(2)
                    if( not self.bPlayingFeedback and math.random(3) == 3 ) then
                        mainScene.sound:playVoice( self.feedbackSound, 0, true )
                        self.bPlayingFeedback = true
                        local delayFunc = function()
                            self.bPlayingFeedback = false
                        end
                        
                        timer.performWithDelay( 10000, delayFunc, 1 )
                    end
                    
                end
                if( num == 1 ) then
                    mainScene.sound:playWeaponSound( mainScene.weapons.bounceSound1 )
                elseif( num == 2 ) then
                    mainScene.sound:playWeaponSound( mainScene.weapons.bounceSound2 )
                elseif( num == 3 ) then
                    mainScene.sound:playWeaponSound( mainScene.weapons.bounceSound3 )
                elseif( num == 4 ) then
                    mainScene.sound:playWeaponSound( mainScene.weapons.bounceSound4 )
                elseif( num == 5 ) then
                    mainScene.sound:playWeaponSound( mainScene.weapons.bounceSound5 )
                elseif( num == 6 ) then
                    mainScene.sound:playWeaponSound( mainScene.weapons.bounceSound6 )
                end
            end
            if( mainScene:getSelectedCharacter() == "perry" ) then
                doCookieExplosion( weapon )
            else
                doBatExplosion( weapon, true)
			end
            return

      -- end
        end
    end
    if( bHit ) then
        return
    end
    
    local activeEnemies = mainScene.enemies.activeEnemies
    for i=1,table.getn( activeEnemies ) do
        --if( i <= 1 or (self.counter == 1 and math.mod(i, 2) ~= 0 ) or ( math.mod(i, 2) == 0 and self.counter == 2 ) ) then

		if( activeEnemies[i].contentBounds.xMin < mainScene.rightEdge - 20 ) then
			if( mainScene:checkCollision(weapon, activeEnemies[i] ) and not activeEnemies[i].bImmortal ) then
				mainScene.weapons.totalHit = mainScene.weapons.totalHit+1
				mainScene.enemies:doWeaponHit( weapon, activeEnemies[i] )
				weapon.bDisarmed = true
                if( not mainScene.weapons.punchSoundTime ) then
                    mainScene.weapons.punchSoundTime = 0
                end
                mainScene.weapons:discard(weapon)
                if( system.getTimer() - mainScene.weapons.punchSoundTime > 300 ) then
                    local num = math.random(3)
                    if( num == 1 ) then
                        mainScene.sound:playWeaponSound( mainScene.weapons.punchSound1 )
                    elseif( num == 2 ) then
                        mainScene.sound:playWeaponSound( mainScene.weapons.punchSound2 )
                    else
                        mainScene.sound:playWeaponSound( mainScene.weapons.punchSound3 )
                    end
                    mainScene.weapons.punchSoundTime = system.getTimer()
                end
				return
			end
		--end
		end
    end
end

function weaponObjects:discard(weapon)
	if( mainScene:getSelectedCharacter() == "perry" ) then
		doCookieExplosion( weapon )
	else
        
        weapon.bForceDiscard = true
		--doBatExplosion( weapon )
	end
     -- Don't penalize the player for firing and hitting an obstacle.
    mainScene.weapons.totalFired = mainScene.weapons.totalFired-1
end


function weaponObjects:fire()
    if( mainScene.player.bDashing ) then
        return
    end
    if( ( system.getTimer() - prevTime ) <= throttleTime) then
        return
    end
    prevTime = system.getTimer()
    
   -- 
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
	
	local weapon = nil
	if( mainScene:getSelectedCharacter() == "mole" ) then
		local ran = math.random(3)
		
		if( ran == 3 ) then
			weapon = display.newImageRect( "images/redbat.png", 14, 40 )
		else
			weapon = display.newImageRect( "images/bluebat.png", 14, 40 )
		end
		weapon.rotateSpeed = ( math.random(10)+10 )
		weapon.speed = 24
		weapon.x = mainScene.player.avatar.x - 10
	    weapon.y = mainScene.player.avatar.y - 45
        weapon.collisionDistance = 45
	
    elseif( mainScene:getSelectedCharacter() == "perry" ) then
		weapon = display.newImageRect( "images/cookie.png", 19, 20 )
		weapon.alpha = (math.random(10)+90)*.01
		local scale = (math.random(30)+90)*.01
		weapon.xScale = scale
		weapon.yScale = scale
		weapon.rotation = math.random(25)
		weapon.speed = 20
		weapon.x = mainScene.player.avatar.x - 10
	    weapon.y = mainScene.player.avatar.y - 25
        weapon.collisionDistance = 25
	else
        weapon = display.newImageRect( "images/microphone.png", 13, 25 )
		weapon.alpha = (math.random(10)+90)*.01
		weapon.rotation = math.random(25)
		weapon.rotateSpeed = ( math.random(10)+30 )
		weapon.speed = 22
		weapon.x = mainScene.player.avatar.x - 10
	    weapon.y = mainScene.player.avatar.y - 35
	    --weapon.xChoke = -10
	    --weapon.yChoke = -10
        weapon.collisionDistance = 40
    end
    weapon.anchorX = 0.5
	weapon.anchorY = 0.5
    weapon.name = "weapon"
	
	mainScene.city.displayGroup:insert( weapon )
    
	
	
	mainScene.weapons.active[#mainScene.weapons.active+1] = weapon
    
	display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )      
    mainScene.weapons.totalFired = mainScene.weapons.totalFired+1
	local num = math.random(2)
	if( num == 1 ) then
		mainScene.sound:playWeaponSound( self.throwSound1 )
	else
		mainScene.sound:playWeaponSound( self.throwSound2 )
	end
end

function GetWeapons()
    return table.getn( mainScene.weapons.active )
end

function weaponObjects:getActive()
    return mainScene.weapons.active
end


local function updateObstacles(event)
    local self = event.source.params.myself
    if( not mainScene or mainScene.bGameOver ) then
        return
    end

    for i, weapon in ipairs( mainScene.weapons.active ) do
        if( isCollidingWithObstacle( self, weapon ) ) then
            physics.removeBody( weapon )
            table.remove( mainScene.weapons.active, i )
            weapon:removeSelf()
            break
        elseif( isOffScreen( weapon) or ( mainScene:getSelectedCharacter() == "perry" and weapon.bDisarmed ) ) then
                table.remove( mainScene.weapons.active, i )
                physics.removeBody( weapon )
                weapon:removeSelf()
        end
    end
end

function weaponObjects:update()
    --local removalIndex = nil
    self.counter = self.counter + 1
    if ( self.counter > 3 ) then
       self.counter = 1
    end

    for i, weapon in ipairs( mainScene.weapons.active ) do
    	
        if( not weapon.bDisarmed ) then
            local speed = ( (weapon.speed * 0.5 ) ) * ( 60 / display.fps )
           weapon:translate( speed, 0)
         
		      if( mainScene:getSelectedCharacter() ~= "perry" ) then
			     weapon.rotation = weapon.rotation + ( weapon.rotateSpeed * ( 60 / display.fps ) )
		       end
              end
              if( mainScene:getSelectedCharacter() == "mole" ) then
                weapon.y = ( weapon.y + 0.5 ) * ( 60 / display.fps )
              end

            if( weapon.bForceDiscard ) then
                physics.removeBody( weapon )
                table.remove( mainScene.weapons.active, i )
                weapon:removeSelf()
                break

            end

        end

    --if( removalIndex ) then
     --   if( mainScene.weapons.active[removalIndex].bPhysics ) then
     --       mainScene.physicsWeapons = mainScene.physicsWeapons - 1
    --       )
     --   end
     --   mainScene.weapons.active[removalIndex]:removeSelf()
    --    table.remove( mainScene.weapons.active, removalIndex )
    --end
end


function weaponObjects:init(scene)
    mainScene = scene
    
    mainScene.physicsWeapons = 0
    
    self.checkTimer = timer.performWithDelay( 45, updateObstacles, -1 )
    self.checkTimer.params = { myself = self }
	
	self.active = {}
    self.totalFired = 0
    self.totalHit = 0
	
    self.throwSound1 = scene.sound:loadWeaponSound( "throw1.wav" )
	self.throwSound2 = scene.sound:loadWeaponSound( "throw2.wav" )
    self.punchSound1 = scene.sound:loadWeaponSound( "punch1.wav" )
    self.punchSound2 = scene.sound:loadWeaponSound( "punch2.wav" )
    self.punchSound3 = scene.sound:loadWeaponSound( "punch3.wav" )
	
	if( mainScene:getSelectedCharacter() == "perry" ) then
        self.bounceSound1 = scene.sound:loadWeaponSound( "crunch1.wav" )
        self.bounceSound2 = scene.sound:loadWeaponSound( "crunch2.wav" )
        self.bounceSound3 = scene.sound:loadWeaponSound( "crunch3.wav" )
		spriteSheet = graphics.newImageSheet( "images/cookieExplosionAnim.png", { width=60, height=60, numFrames=7 } )
	elseif( mainScene:getSelectedCharacter() == "mole" ) then
        self.bounceSound1 = scene.sound:loadWeaponSound( "redBat1.wav" )
        self.bounceSound2 = scene.sound:loadWeaponSound( "redBat2.wav" )
        self.bounceSound3 = scene.sound:loadWeaponSound( "redBat3.wav" )
        self.bounceSound4 = scene.sound:loadWeaponSound( "redBat4.wav" )
        self.bounceSound5 = scene.sound:loadWeaponSound( "redBat5.wav" )
        self.bounceSound6 = scene.sound:loadWeaponSound( "redBat6.wav" )
    else
        self.bounceSound1 = scene.sound:loadWeaponSound( "micHit1.wav" )
        self.bounceSound2 = scene.sound:loadWeaponSound( "micHit2.wav" )
        self.feedbackSound = mainScene.sound:loadVoice( "micFeedback.wav" )
    end
end

function weaponObjects:destroy()
    timer.cancel( self.checkTimer  )
    for i=1,table.getn( mainScene.weapons.active ) do
        if( mainScene.weapons.active[i].bPhysics ) then
            physics.removeBody( mainScene.weapons.active[i] )
        end
        mainScene.weapons.active[i]:removeSelf()
        mainScene.weapons.active[i] = nil
    end
    audio.dispose( self.throwSound1 )
    audio.dispose( self.throwSound2 )
    audio.dispose( self.punchSound1 )
    audio.dispose( self.punchSound2 )
    audio.dispose( self.punchSound3 )
    audio.dispose( self.bounceSound1 )
    audio.dispose( self.bounceSound2 )
    audio.dispose( self.bounceSound3 )
    
    if( self.bounceSound6 ) then
        audio.dispose( self.bounceSound4 )
        audio.dispose( self.bounceSound5 )
        audio.dispose( self.bounceSound6 )
    end
    
    self.punchSound1 = nil
    self.punchSound2 = nil
    self.punchSound3 = nil
    self.bounceSound1 = nil
    self.bounceSound2 = nil
    self.bounceSound3 = nil
    self.bounceSound4 = nil
    self.bounceSound5 = nil
    self.bounceSound6 = nil
    self.throwSound = 1
    self.throwSound = 2
    self.throwSound = 3
    
    mainScene.weapons.active = {}
    mainScene.weapons.totalFired = 0
    mainScene.weapons.totalHit = 0
    mainScene.physicsWeapons = 0
	mainScene.weapons = nil
	mainScene = nil
	package.loaded[self] = nil
end

return weaponObjects;