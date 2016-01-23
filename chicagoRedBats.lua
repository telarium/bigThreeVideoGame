----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script controls the red bats behaviors and properties
-- for the Chicago endless runner level

local redBats = {
    t = 0,
    origin = {}
}

local function update(self, bats, batObject, mainScene)
	if( mainScene.bGameOver or table.getn( bats ) == 0 ) then
		timer.cancel( batObject.timer )
		batObject = nil
		return
	end

  -- Animate the bat flight path on a sin wave
	batObject.y = ( 50+math.sin(batObject.x/10)*15 ) * ( 60 / display.fps )
	batObject.x = batObject.x - ( 2 * ( 60 / display.fps ) )
	local deltaX = 0
	local deltaY = 0
	local x = batObject.x
	local y = batObject.y
	for i, bat in ipairs( bats ) do
	    if( not bat.x ) then
	       table.remove( bats, i )
	       bat = nil
	    else
			deltaX = ( x + bat.offsetX ) - bat.x - bat.randomXSpeed
			deltaY = ( y + bat.offsetY ) - bat.y
			if( deltaY < -2 ) then
			 deltaY = -2
			elseif( deltaY > 4 ) then
			 deltaY = 4
		    end
	        bat.x = bat.x + ( deltaX )
	        bat.y = bat.y + ( deltaY * bat.dampening )
	        bat.offsetY = bat.offsetY - math.random( 150 ) * 0.001
		end
	end
end

function redBats:spawn(scene)
    mainScene = scene
    
    if( not self.bSoundPlayed ) then
        self.bSoundPlayed = true
        self.voiceSound = scene.sound:loadVoice( "voice-" .. mainScene:getSelectedCharacter() .. "RedBat.wav" )
        scene.sound:playVoice( self.voiceSound, 0.5 )
        
        local function disposeSound()
            audio.dispose(self.voiceSound)
            self.voiceSound = nil
        end
        timer.performWithDelay( disposeSound, 3000 )
    end
    
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    
    local speed = mainScene.city.curSpeed
	if( speed < mainScene.city.defaultSpeed ) then
	   speed = mainScene.city.defaultSpeed
	end
	local destx = mainScene.player.avatar.x + ( 1 * math.abs( speed ) )
	local randomHeight = 300
    
    local myX,myY = mainScene.city.displayGroup:contentToLocal( mainScene.rightEdge, mainScene.foldY )
	self.origin = {x=myX,y=100}
	self.t = 0
	
	local x,y = mainScene.city.displayGroup:contentToLocal( mainScene.rightEdge, mainScene.foldY )
	local batObject = {}
	local bats = {}
	batObject.x = x + 35
	batObject.y = 30
	
	local function create()
	    local animTime = 200 + math.random( 100 )
        local redBatsheet = graphics.newImageSheet( "images/redBatAnim.png", { width=34, height=29, numFrames=4 } )
        local redbat = display.newSprite( redBatsheet, {{ name = "loop", start=1, count=4, time=animTime, loopCount=0 }} )

      	--redbat.x = batObject.x
      	--redbat.y = batObject.y
      	mainScene.city.displayGroup:insert( redbat )
      	redbat:setSequence( "loop" )
      	redbat:play()
      	
      	redbat.health = 1
        redbat.xChoke = -10
        redbat.yChoke = -10
        redbat.explosionScale = 0.4
        redbat.name = "redBat"
        redbat.x = batObject.x
        redbat.y = batObject.y
        redbat.randomXSpeed = math.random( 30 ) * 0.01
        redbat.collisionDistance = 40
      	return redbat
    end
    
	local offsetX = 0
	local offsetY = 0
	local mult = 1
	local dampening = 0.9
    local i = nil
    if( not mainScene.bSmoggy ) then
     if( self.difficulty == 1 or not self.difficulty ) then
         i = 5
     elseif( self.difficulty == 2 ) then
         i = 15
     elseif( self.difficulty == 3 ) then
         i = 3
     end
     else
      i = 3
     end
     
    if( table.getn( mainScene.enemies.activeEnemies ) >= 8 or mainScene.bSmoggy ) then
        i = 2
    end
    
    local collisionIndex = 0
    while ( i > 0 ) do
    	i = i - 1
    	local bat = create()
    	
    	if( collisionIndex == 0 ) then
    	   bat.collisionIndex = 1
    	   collisionIndex = 1
    	else
    	   bat.collisionIndex = 2
    	   collisionIndex = 0
    	end
    	offsetX = offsetX + ( math.random( 30 ) + 20 )
    	mult = math.random( 2 )
    	if( mult == 2 ) then
    		mult = -1
    	else
    		mult = 1
    	end
    	bat.offsetX = offsetX
    	bat.offsetY = offsetY + ( math.random( 30 ) * mult )
    	bat.dampening = dampening - ( math.random(500) * 0.004 )
    	table.insert( bats, bat )
    end

	batObject.update = function()
		update(self, bats, batObject, mainScene)
	end
	
	batObject.timer = timer.performWithDelay( 1000/60, batObject.update, 0 )
    
    batObject.sound = mainScene.sound:load( "redbats.wav", true )
    scene.sound:play( batObject.sound, false, true, math.random( 15 ) * .1 )

    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )

    return bats
end

return redBats
