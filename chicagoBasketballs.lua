local basketballs = {
    bPlayedVoiceAudio = false,
    sounds = nil,
    voiceFile = nil
}


function basketballs:spawn(scene)
    mainScene = scene
    local balls = {}
    local basketball = nil
    local x,y = mainScene.city.displayGroup:contentToLocal( mainScene.rightEdge, mainScene.foldY )
    local spawnX = x
    
    if( not self.sound ) then
        self.sounds = { mainScene.sound:load( "basketball1.wav", true ), mainScene.sound:load( "basketball2.wav", true ), mainScene.sound:load( "basketball3.wav", true ), mainScene.sound:load( "basketball4.wav", true ) }
    end
    
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    mainScene:setPhysics( true )
    local collisionIndex = 0
    local i =math.random(2)+3
    
    if( table.getn( mainScene.enemies.activeEnemies ) > 8 ) then
        i = math.random(2)
    end 
    
    while ( i > 0 ) do
        i = i - 1

        basketball = display.newImageRect( "images/basketball.png", 28, 28 )
        
        basketball.collisionDistance = 20
        
        if( collisionIndex == 0 ) then
    	   basketball.collisionIndex = 1
    	   collisionIndex = 1
    	else
    	   basketball.collisionIndex = 2
    	   collisionIndex = 0
    	end
        
        spawnX = spawnX + (math.random(80) + 5 )
        basketball.x = spawnX
        basketball.y = mainScene.groundY - ( math.random( 300 ) + 100 )
        mainScene.city.displayGroup:insert( basketball )
        
        basketball.health = 1
        basketball.xChoke = 0
        basketball.yChoke = 0
        basketball.explosionScale = 0.4
        
        local flip = math.random( 2 )
        if ( flip == 2 ) then
            basketball.xScale = -1
        end
        
        flip = math.random( 2 )
        if ( flip == 2 ) then
            basketball.yScale = -1
        end
        
        local myBounce = ( 80 + math.random( 10 ) ) * 0.01
   
        physics.addBody( basketball, { density = 0.8, friction = 0.3, bounce = myBounce, radius = 14 } )
        if( basketball.applyLinearImpulse ) then
            basketball:applyLinearImpulse( -2,1, basketball.x, basketball.y )
        end
        basketball:toFront()
        basketball.name = "basketball"
        
        table.insert( balls, basketball )
        
        basketball.onPlayerCollision = function()
            if( not self.bPlayedVoiceAudio and self.voiceSound ) then
                self.bPlayedVoiceAudio = true
                scene.sound:playVoice( self.voiceSound, 1, true )
                
                local function removeSound()
                    audio.dispose( self.voiceSound )
                    self.voiceSound = nil
                end
                timer.performWithDelay( 3000, removeSound )
            end
        end
        
        basketball.onGroundImpact = function(event)
            if( basketball.contentBounds ) then
                if( table.getn( self.sounds ) > 0 and event.force >= 0.2 and basketball.contentBounds.xMin < scene.rightEdge + 60 ) then
                    scene.sound:play( self.sounds[ math.random( table.getn( self.sounds ) ) ], false, true )
                end
            end
        end
        
        basketball:addEventListener( "postCollision", basketball.onGroundImpact )
        
        --basketball.update = function()
            --update(basketball, mainScene)
        --end
    end
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
    
    if( not self.bPlayedVoiceAudio and mainScene:getSelectedCharacter() ~= "don" ) then
        self.voiceSound = scene.sound:loadVoice( "voice-donBasketball.wav" )

    end
    
    return balls
end

return basketballs
