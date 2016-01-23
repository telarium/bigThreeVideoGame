----------------------------------
-- THE BIG 3 VIDEO GAME        ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script sets the properties and behaviors of hands that emerge
-- for the Chicago endless runner level


local jerkoffHands = {
    activeHand = nil,
    groundSprite = nil
}


function jerkoffHands:update(mainScene)
    if( self.activeHand ) then
        if( not self.activeHand.x ) then
            self.activeHand = nil
            return
        end
        self.activeHand.spawnCounter = self.activeHand.spawnCounter - 1
        if( self.activeHand.spawnCounter == 0 and self.activeHand.health > 0 and self.activeHand.x ) then
         self.activeHand:play()
        end
    end
end


function jerkoffHands:spawn(mainScene)
    if( self.activeHand) then
        return nil
    end
    
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )

    local jerkoffHandsheet = graphics.newImageSheet( "images/groundHandAnim.png", { width=100, height=120, numFrames=7 } )
    self.activeHand = display.newSprite( jerkoffHandsheet, {{ name = "loop", start=1, count=7, time=600, loopCount=1 }} )
    
	self.activeHand.anchorX = 0.5
	self.activeHand.anchorY = 1

    local x,y = mainScene.city.displayGroup:contentToLocal( mainScene.rightEdge, mainScene.foldY )
    x = mainScene.city:getGroundSpawnCoordinate()
    
	self.activeHand.spawnCounter = 90
	self.activeHand.x = x + ( self.activeHand.width * 2 )
	self.activeHand.y = y -26
	self.activeHand.xScale = -1
	mainScene.city.displayGroup:insert( self.activeHand )
	self.activeHand:setSequence( "loop" )
	
	mainScene.city:setGroundSpawnCoordinate(self.activeHand.x+70, "hand")

    self.groundSprite = display.newImageRect( "images/groundHandHole.png", 64, 25 )
    self.groundSprite.anchorX = 0.5
	self.groundSprite.anchorY = 0.5
    self.groundSprite.x = self.activeHand.x + 5
    self.groundSprite.y = self.activeHand.y - 17
    self.groundSprite.xScale = self.activeHand.xScale
	self.groundSprite.isVisible = false
	mainScene.city.displayGroup:insert( self.groundSprite )

    self.activeHand.health = 2
    self.activeHand.explosionScale = 0.5
    self.activeHand.bDisableCollision = true
    self.activeHand.xChoke = 23
    self.activeHand.yChoke = 3
    
    self.activeHand.bPerciseCollisionDetection = true
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
    
    local frame = 0
    
	local function mySpriteListener( event )
		if( event.phase == "next" ) then
			frame = frame + 1
			if ( frame > 3 and self.activeHand ) then
				self.activeHand.bDisableCollision = false
                self.activeHand.explosionScale = 2
		    end
	  elseif ( event.phase == "ended" and self.groundSprite ) then
	         self.groundSprite.isVisible = true
	         self.activeHand:removeEventListener( "sprite", mySpriteListener )
	  end
	end
    
    self.activeHand.onPlayerCollision = function()
        local voice = mainScene.sound:loadVoice( "voice-" .. mainScene:getSelectedCharacter() .. "DontTouchMe.wav" )
        mainScene.sound:playVoice( voice )
        local dispose = function()
            audio.dispose( voice )
        end
        timer.performWithDelay( 5000, dispose, 1 )
    end
    
    self.activeHand:addEventListener( "sprite", mySpriteListener )
    
    self.activeHand.bGroundSpawn = false
    self.activeHand.name = "jerkoffHand"
    
    mainScene.obstacles:addMisc(self.groundSprite,false)
    
    return self.activeHand
end

return jerkoffHands
