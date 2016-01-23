----------------------------------
-- THE BIG 3 VIDEO GAME        ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script controls the behavior of the car (and resulting smog)
-- for the Chicago endless runner level

local cutlass = {
    putterSound = nil
}
local function update(mainScene, car, frontTire, frontHubcap, rearTire, rearHubcap, tailpipe, smog, mask)
    local x,y = mainScene.city.displayGroup:contentToLocal( mainScene.rightEdge, mainScene.foldY )
    local x2,y2 = mainScene.city.displayGroup:contentToLocal( mainScene.leftEdge, mainScene.foldY )
    
    if( not car.bInitialized ) then
       local x,y = mainScene.city.displayGroup:contentToLocal( mainScene.rightEdge, mainScene.foldY )
	   car.x = x + car.width
	   frontTire.x = car.x - 69
	   frontHubcap.x = frontTire.x
	   rearTire.x = car.x + 55
	   rearHubcap.x = rearTire.x
	   if( table.getn( mainScene.obstacles.activeObstacleGroups ) <= 1 ) then
	        local putterSound = mainScene.sound:load( "cutlass.wav", true )
            mainScene.sound:play( putterSound, true, true )
            
            local dispose = function()
                audio.dispose( putterSound )
                putterSound = nil
            end
    
           timer.performWithDelay( 4000, dispose )
	   
	       car.bInitialized = true
           smog.isVisible = true
	   end
	   return
	end
    
    
    local speed = ( 4 * ( 60 / display.fps ) )
    if( car.x and not car.bCollidedWithPlayer ) then
	   car.x = car.x - speed
	   tailpipe.x = car.x + 150
       tailpipe.y = car.y - 110
	end
    if( frontTire.x ) then
        if( not frontTire.bCollidedWithPlayer ) then
            frontTire.x = frontTire.x - speed
            if( frontHubcap ) then
            frontHubcap.x = frontTire.x
            frontHubcap.rotation = frontHubcap.rotation - 20
            end
        else
            if( frontHubcap ) then
            frontHubcap.x = frontTire.x
            frontHubcap.y = frontTire.y
            frontHubcap.rotation = frontTire.rotation
            end
        end
    end
    if( rearTire.x ) then
        if( not rearTire.bCollidedWithPlayer ) then
            rearTire.x = rearTire.x - speed
            if( rearHubcap ) then
            rearHubcap.x = rearTire.x
            rearHubcap.rotation = rearHubcap.rotation - 20
            end
        else
            if( rearHubcap ) then
            rearHubcap.x = rearTire.x
            rearHubcap.y = rearTire.y
            rearHubcap.rotation = rearTire.rotation
            end
        end
	end
    
    if( smog.maskX ) then
        smog.maskX = smog.maskX + speed
        if( smog.maskX > 100 ) then
          smog:setMask( nil )
          mask = nil
        end
    end
    
    if ( tailpipe.x ) then
        mainScene.bSmoggy = true
        if( tailpipe.x <= x ) then
        elseif( tailpipe.x < x2 ) then
            tailpipe:removeSelf()
            tailpipe = nil
        end
    end

    if( not smog.fadeTime ) then
        smog.fadeTime = system.getTimer() + 7000
        smog.counter = 0
    end
    if( mainScene.bRemoveSmog ) then -- If Mole is blowing the smog away
        smog.alpha = smog.alpha - ( 0.0125 * ( 60 / display.fps ) )
            if( tailpipe.x ) then -- Force removal of tailpipe
                 tailpipe.x = -1000
            end
    end
    if( system.getTimer() >= smog.fadeTime ) then
        smog.counter = smog.counter + 1
            if( smog.counter > 5 ) then
                smog.counter = 0
                smog.alpha = smog.alpha - ( 0.001 * ( 60 / display.fps ) )
            end
            if( smog.alpha <= 0.35 ) then
                mainScene.bSmoggy = false
            end
            if( smog.alpha <= 0 ) then
               smog:removeSelf()
               smog = nil
            end
    end
end


function cutlass:spawn(scene)
    mainScene = scene
    
    mainScene.bSmoggy = false
    mainScene.bRemoveSmog = false
    
    local obstacleGroup = {}
	obstacleGroup.name = "cutlass"
    obstacleGroup.bodies = {}

    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )

    local car = display.newImageRect( "images/cutlass.png", 219, 51 )
    car.bPerciseCollisionDetection = true
    car.doObstacleCollisionCheck = true
	
	local x,y = mainScene.city.displayGroup:contentToLocal( mainScene.rightEdge, mainScene.foldY )
	
	car.x = x + car.width
	car.y = mainScene.groundY - 40
	mainScene.city.displayGroup:insert( car )

    car.xChoke = 5
    car.yChoke = 5
    car.id = "cutless"
    car.isAwake = true
    car.bTestForCollision = true
    car.bEnableAutoSpawn = false
    car.explosionScale = 2
    	
	local frontTire = display.newImageRect( "images/tire.png", 30, 29 )
	mainScene.city.displayGroup:insert( frontTire )
	frontTire.x = car.x - 69
	frontTire.y = mainScene.groundY - 17
	frontTire.isAwake = true
    frontTire.bTestForCollision = true
    frontTire.linearX = 10
    frontTire.angle = 80
    
	local frontHubcap = display.newImageRect( "images/hubcap.png", 16, 16 )
	mainScene.city.displayGroup:insert( frontHubcap )
	frontHubcap.x = frontTire.x
	frontHubcap.y = frontTire.y
	
	local rearTire = display.newImageRect( "images/tire.png", 30, 29 )
	mainScene.city.displayGroup:insert( rearTire )
	rearTire.x = car.x + 55
	rearTire.y = frontTire.y
    rearTire.isAwake = true
    rearTire.bTestForCollision = true
    rearTire.linearX = 30
    rearTire.angle = 90
	
	local rearHubcap = display.newImageRect( "images/hubcap.png", 16, 16 )
	mainScene.city.displayGroup:insert( rearHubcap )
	rearHubcap.x = rearTire.x
	rearHubcap.y = rearTire.y
	
	--local tailpipeSheet = graphics.newImageSheet( "images/smogTailpipeAnim.gif", { width=100, height=185, numFrames=72 } )
    --local tailpipe = display.newSprite( tailpipeSheet, {{ name = "loop", start=1, count=72, time=2000, loopCount=0 }} )
    tailpipe = display.newImageRect( "images/basketball.png", 100, 185 )
    tailpipe.anchorX = 0.5
	tailpipe.anchorY = 0.5
	tailpipe.blendMode = "screen"
	tailpipe.xScale = 1.5
	tailpipe.yScale = 1.5
	--tailpipe.alpha = 0.95
	tailpipe.alpha = 0.001
	mainScene.city.displayGroup:insert( tailpipe )

	local smogSheet = graphics.newImageSheet( "images/smogAnim.gif", { width=240, height=135, numFrames=23 } )
    local smog = display.newSprite( smogSheet, {{ name = "loop", start=1, count=23, time=1100, loopCount=0 }} )
    
    smog.anchorX = 0.5
	smog.anchorY = 0.5
	smog.x = display.contentCenterX
	smog.y = display.contentCenterY
	smog.blendMode = "screen"
	smog.xScale = display.actualContentWidth / smog.width * -1
	smog.yScale = display.actualContentHeight / smog.height
	smog.width = smog.width + 8
	smog.height = smog.height + 8
	smog.alpha = 1
	smog:play()
    smog.isVisible = false
	mainScene.effectsGroup:insert( smog )

    local mask = graphics.newMask( "images/smogMask.png" )
    
    smog:setMask( mask )
    smog.maskX = -620
    smog.maskScaleY = 1.2
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
    
    local loop = function()
        if( not mainScene or not smog.x or mainScene.bGameOver ) then
            Runtime:removeEventListener( "enterFrame", loop )
            return
        end
		update(mainScene, car, frontTire, frontHubcap, rearTire, rearHubcap, tailpipe, smog, mask)
	end
    Runtime:addEventListener( "enterFrame", loop )
    
    car.linearX = 140 + math.random( 30 )
    car.angle = 90
    
    local impactSound = mainScene.sound:load( "carcrash.wav", true )
    
    if( mainScene:getSelectedCharacter() == "don" ) then
        local donCough = mainScene.sound:loadVoice( "voice-donCough.wav" )
        mainScene.sound:playVoice( donCough, 2 )
    end
    
    car.onInitialImpact = function()
        mainScene.sound:play( impactSound, true, true )
        
        local dispose = function()
                if( impactSound ) then
                    audio.dispose( impactSound )
                    impactSound = nil
                end
            end
    
           timer.performWithDelay( 4000, dispose )
        
        local achievement = "CgkIhf7UyIMOEAIQBw"
        if ( system.getInfo("platformName") == "iPhone OS" ) then 
            achievement = "fakeDisability"
        end
        gameNetwork.request( "unlockAchievement", { achievement = { identifier=achievement, percentComplete=100, showsCompletionBanner=true } } )
    
        local d = 1.1
        local f = 0.1
        local b = 0.2
        car.bCollided = true
        
        frontHubcap:removeSelf()
        rearHubcap:removeSelf()
        
        frontHubcap = nil
        rearHubcap = nil
        
        mainScene.obstacles:addMisc( car )
        mainScene.obstacles:addMisc( frontTire )
        mainScene.obstacles:addMisc( rearTire )

        physics.addBody( car, "dynamic",
                  { density=d, friction=f, bounce=b, shape = {   -105.5, -3.5  ,  -71.5, 8.5  ,  -85.5, 20.5  ,  -104.5, 21.5  } },
                  { density=d, friction=f, bounce=b, shape = {   71.5, 19.5  ,  54.5, 8.5  ,  29.5, -24.5  ,  100.5, -1.5  ,  108.5, 15.5  } },
                  { density=d, friction=f, bounce=b, shape = {   -36.5, -10.5  ,  -71.5, 8.5  ,  -105.5, -3.5  } },
                  { density=d, friction=f, bounce=b, shape = {   -36.5, -10.5  ,  37.5, 22.5  ,  -52.5, 22.5  ,  -71.5, 8.5  } },
                  { density=d, friction=f, bounce=b, shape = {   -14.5, -23.5  ,  29.5, -24.5  ,  54.5, 8.5  ,  37.5, 22.5  ,  -36.5, -10.5  } }
                  )
                  
        physics.addBody( rearTire, { density = 0.4, friction = 0.2, bounce = 0.9, radius = 15 } )
        physics.addBody( frontTire, { density = 0.4, friction = 0.2, bounce = 0.9, radius = 15 } )
    end
    
    table.insert( obstacleGroup.bodies, car )
    table.insert( obstacleGroup.bodies, frontTire )
    table.insert( obstacleGroup.bodies, rearTire )

    return obstacleGroup
end

return cutlass
