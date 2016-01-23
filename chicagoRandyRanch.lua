----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script controls the randy ranch behaviors and properties
-- for the Chicago endless runner level


local randyRanch = {

    bPlayedVoice = false
}

local function update(mainScene,topDrop,midDrop,bottomDrop,self)
    if( topDrop.x ) then
        local x,y = mainScene.city.displayGroup:localToContent( topDrop.x, topDrop.y )
        if( x <= mainScene.rightEdge - (math.random( 20 ) + 10) and not topDrop.bPlayedAnim ) then
            topDrop.bPlayedAnim = true
            bottomDrop.isVisible = false
            topDrop:play()
            local dropSound = mainScene.sound:loadDamageSound( "drop.wav" )
            mainScene.sound:playDamageSound( dropSound )
            
            local function mySpriteListener( event )
                if ( event.phase == "ended" ) then
                     topDrop:removeEventListener( "sprite", mySpriteListener )
                     midDrop.isVisible = true
                     midDrop.counter = 0
                end
            end
            topDrop:addEventListener( "sprite", mySpriteListener )
        end
        if( x <= mainScene.leftEdge - 20 ) then
            topDrop:removeSelf()
            if( midDrop.x ) then
                midDrop:removeSelf()
            end
        end
    end
    
    if( midDrop.isVisible ) then
        midDrop.counter = midDrop.counter + 1
        if( midDrop.counter == 2 ) then
            if( not midDrop.speed ) then
                local speed = mainScene.city.curSpeed
                if( speed < -8 ) then
                    speed = -8
                end
                midDrop.speed = 1.167 * math.abs( speed )
             end
            if( mainScene.player.bDashing ) then
                midDrop.speed = 7
            end
            midDrop.y = midDrop.y + ( midDrop.speed * ( 60 / display.fps ) )
            if( midDrop.y > bottomDrop.y - 3 ) then
                bottomDrop.isVisible = true
                
                if( not self.bPlayedVoice and mainScene:getSelectedCharacter() ~= "perry" ) then
        local voiceSound = mainScene.sound:loadVoice( "voice-" .. mainScene:getSelectedCharacter() .. "RandyRanch.wav" )
        self.bPlayedVoice = true
        mainScene.sound:playVoice( voiceSound, 0 )
             end
                
                local splatSound = mainScene.sound:loadDamageSound( "splat.wav" )
                mainScene.sound:playDamageSound( splatSound )
                midDrop:removeSelf()
                
                local frame = 0
                
                local function mySpriteListener( event )
            		if( event.phase == "next" ) then
            			frame = frame + 1
            			if ( frame >= 2 and bottomDrop ) then
            				bottomDrop.bDisableCollision = false
            				bottomDrop:removeEventListener( "sprite", mySpriteListener )
            		    end
            	  end
            	end
            	
            	bottomDrop:addEventListener( "sprite", mySpriteListener )
                bottomDrop:play()
            end
            midDrop.counter = 0
        end
    end
end

function randyRanch:spawn(scene)
    mainScene = scene

    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )

    local topSheet = graphics.newImageSheet( "images/randyRanch_topAnim.png", { width=80, height=46, numFrames=10 } )
    local topDrop = display.newSprite( topSheet, {{ name = "loop", start=1, count=10, time=600, loopCount=1 }} )
    topDrop:setSequence( "loop" )
    
    topDrop.anchorY = 0
	topDrop.anchorX = 0.5
    topDrop.y = mainScene.topEdge - 3
    topDrop.x = mainScene.city:getGroundSpawnCoordinate() + 100
    mainScene.city:setGroundSpawnCoordinate(topDrop.x+100 + math.random(200), topDrop.name)
    topDrop.alpha = 0.9
    
    mainScene.city.displayGroup:insert( topDrop )

	
    topDrop.bEnableAutoSpawn = true
    topDrop.name = "randyRanch"
    
    local midDrop = display.newImageRect( "images/randyRanch_drop.png", 8, 19 )
    midDrop.anchorY = 0.5
	midDrop.anchorX = 0.5
    midDrop.x = topDrop.x
    midDrop.y = topDrop.y + 35
    midDrop.isVisible = false
    midDrop.name = "randyRanch"
    midDrop.alpha = 0.9
    midDrop.isVisible = false
    mainScene.city.displayGroup:insert( midDrop )
    
    local bottomSheet = graphics.newImageSheet( "images/randyRanch_bottomAnim.png", { width=82, height=46, numFrames=4 } )
    local bottomDrop = display.newSprite( bottomSheet, {{ name = "loop", start=1, count=4, time=350, loopCount=1 }} )
    bottomDrop:setSequence( "loop" )
    bottomDrop.y = mainScene.groundY - 28
    bottomDrop.x = midDrop.x + 2
    bottomDrop.isVisible = false
    bottomDrop.xChoke = 30
    bottomDrop.yChoke = 24
    bottomDrop.alpha = 0.9
    bottomDrop.name = "randyRanch"
    if( mainScene:getSelectedCharacter() == "perry" ) then
        bottomDrop.bNoDamage = true
    else
        bottomDrop.bDisableCollision = true
    end
    bottomDrop.bImmortal = true
    mainScene.city.displayGroup:insert( bottomDrop )
   
	bottomDrop.update = function()
		update(mainScene,topDrop,midDrop,bottomDrop, self)
	end
    
    bottomDrop.onPlayerCollision = function()
        local voice = nil
        if( mainScene:getSelectedCharacter() == "perry" ) then
            voice = mainScene.sound:loadVoice( "voice-perryMmm.wav" )
        else
            voice = mainScene.sound:loadVoice( "voice-" .. mainScene:getSelectedCharacter() .. "Eww.wav" )
        end
        mainScene.sound:playVoice( voice )
        local dispose = function()
            audio.dispose( voice )
        end
        timer.performWithDelay( 5000, dispose, 1 )
    end
    
    bottomDrop.dispose = function()
        if ( midDrop.x ) then
            midDrop:removeSelf()
        end
        if( topDrop.x ) then
            topDrop:removeSelf()
        end
    end
    
    bottomDrop.bPerciseCollisionDetection = true
       
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
    
    return bottomDrop
end

return randyRanch
