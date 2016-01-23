----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script controls Vince's boring behaviors and properties
-- for the Chicago endless runner level


local mainScene = nil

local vince = {
    maryJaneSound = nil
}

local kPlanetHealth = 11

local function showPoints(obj, i )
    if( not i ) then
        i = 1
    end
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    local bPlayedSound = false
    while ( i > 0 ) do
        i = i - 1
        
        local stroke = display.newImage("images/pieTime_pointsStroke.png");
        local points = display.newImage("images/pieTime_points.png");
        points.blendMode = "screen"
        points.x, points.y = obj:localToContent( 0, 0 )
        
        if( i > 0 ) then
            local num = math.random( 100 ) + 20
            if ( math.random(2) == 2 ) then
                num = num * 1
            end
            points.x = points.x + num
            
            local num = math.random( 80 ) + 10
            if ( math.random(2) == 2 ) then
                num = num * 1
            end
            points.y = points.y + num
        end
            
        
        stroke.x = points.x
        stroke.y = points.y
        
        points.xScale, points.yScale = 0.5, 0.5
        stroke.xScale, stroke.yScale = 0.5, 0.5
        mainScene.effectsGroup:insert( stroke )
        mainScene.effectsGroup:insert( points )
        
        if( not bPlayedSound ) then
            mainScene.sound:playBonusSound( mainScene.powerUps.bonusSound )
            bPlayedSound = true
        end
        mainScene:addPoints(100)
        
        
        
        local function removePoints()
            if( points ) then
                points:removeSelf()
                stroke:removeSelf()
                points = nil
                stroke = nil
            end
        end
        
        local animTime = 800 + math.random( 300 )
        
        transition.to( points, { time=animTime, delay=0, y=points.y-100 } )
        transition.to( stroke, { time=animTime, delay=0, y=points.y-100 } )
        transition.to( points, { time=500, delay=500, alpha = 0, transition=easing.outExpo } )
        transition.to( stroke, { time=500, delay=500, alpha = 0, transition=easing.outExpo } )
        
        timer.performWithDelay( animTime, removePoints )

    end
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
end

local function updatePos(obj, scene, dampening )
    if( not obj.x ) then
        return
    end
	local deltaX = nil
	local deltaY = nil
	if( not scene ) then
		deltaX = ( obj.x - obj.targetX )
		deltaY = ( obj.y - obj.targetY )
	else
		deltaX = obj.x - ( ( scene.player.avatar.x - obj.targetX ) ) 
		deltaY = obj.y - ( ( scene.groundY - obj.targetY ) )

        if( not obj.prevDelta ) then
            obj.prevDelta = 0
        end
        
        if( math.abs( obj.prevDelta - deltaX ) <= 0.5 ) then
            obj.targetX = ( math.random( 250 ) + 250 ) * -1
            obj.targetY = math.random( 100 ) + 100
        end
        
        obj.prevDelta = deltaX
	end
	obj.x = obj.x - ( deltaX * dampening ) * ( 60 / mainScene.fps )
	obj.y = obj.y - ( deltaY * dampening ) * ( 60 / mainScene.fps )
end

local function getPointOnCircle( obj, center)
    local radius = 100
    local x = radius * math.cos( obj.orbit * math.pi / 180 ) + center.x
    local y = radius * math.sin( obj.orbit * math.pi / 180 ) + center.y
    return x,y
end

local function update(mainScene, vinceAnim, vinceFace, planets, boredomMeterBar, boredomMeterFrame, self )

	if( system.getTimer() - vinceAnim.spawnTime < 3000 ) then

        vinceAnim.x = mainScene.rightEdge + 500
            vinceAnim.y = display.contentCenterY
            for i, planet in ipairs( planets ) do
                planet.health = kPlanetHealth
                planet.x,planet.y = getPointOnCircle( planet, vinceAnim )
                
            end
                    updatePos( vinceAnim, mainScene, 0 )
        return
    end
    if( not boredomMeterFrame.isVisible ) then
        boredomMeterFrame.isVisible = true
        local vinceTransition1 = transition.to( boredomMeterFrame, { time=800, delay=1500, xScale=1, transition=easing.outExpo} )
    local vinceTransition2 = transition.to( boredomMeterFrame, { time=800, delay=1500, yScale=1, transition=easing.outExpo} )
    end
    
    if( not vinceAnim.bPlayedVoice ) then
        vinceAnim.bPlayedVoice = true
        vinceAnim.audioChannel = audio.play( vinceAnim.voiceAudio )
        
        local hack = function()
            vinceAnim.bDisableCulling = false
            for i, planet in ipairs( planets ) do 
    
                planet.bDisableCulling = false
            end
        end
        timer.performWithDelay( 5000, hack )
    end
    
    boredomMeterFrame.x = mainScene.player.avatar.x 
    boredomMeterFrame.y = math.floor( mainScene.player.avatar.y - 80 )
    
    if( boredomMeterFrame.y < mainScene.topEdge + 30 ) then
        boredomMeterFrame.y = math.floor( mainScene.topEdge + 30 )
    end
    
    if( boredomMeterFrame.xScale < 1 ) then
        boredomMeterBar.isVisible = false
    else
        boredomMeterBar.isVisible = true
    end
    boredomMeterBar.x = boredomMeterFrame.x - ( boredomMeterBar.width / 2 )
    boredomMeterBar.y = boredomMeterFrame.y + 8
    
    boredomMeterBar.xScale =  boredomMeterBar.xScale + 0.00046 * ( 60 / mainScene.fps )
    if( boredomMeterBar.xScale >= 1 and not mainScene.bGameOver ) then
        mainScene.player.health = 0
        mainScene.player:doGenericDamage()
    end
    
    updatePos( vinceAnim, mainScene, 0.03 )
	vinceFace.x = vinceAnim.x - 5
    vinceFace.y = vinceAnim.y + 10
    
    local removalIndex = nil
    
    if( not vinceAnim.orbitSpeed ) then
        vinceAnim.orbitSpeed = 3
    end
    
    if( not vinceAnim or vinceAnim.health <= 1 or mainScene.bGameOver ) then
        vinceAnim:kill()
        vinceAnim.health = 0
        mainScene.bVinceAlive = false
        for i, planet in ipairs( planets ) do 
            planet.health = 0
            return
        end
    end
    
    if( table.getn( planets ) > 2 ) then
        vinceAnim.health = kPlanetHealth * 1.5
    else
        vinceAnim.bSpecialPowerImmunity = false
        vinceAnim.bObstacleImmunity = true
    end
    
    for i, planet in ipairs( planets ) do 
         local base = nil
        local step = 360 / table.getn( planets )
        for i, planet in ipairs( planets ) do
            if( not base ) then
                base = planet.orbit
            else
                base = base + step
                if( base > 360 ) then
                    base = 0 + ( base - 360 )
                end
                planet.orbit = base
            end
        end
    
        if( not planet.x or planet.health <= 0 ) then
            removalIndex = i
        end
    
       planet.orbit = planet.orbit + ( vinceAnim.orbitSpeed * ( 60 / display.fps ) )
       if( planet.orbit > 360 ) then
           planet.orbit = 0
       end  
       planet.targetX,planet.targetY = getPointOnCircle( planet, vinceAnim )
       if( not planet.dampening ) then
            planet.dampening = 0.05 + ( math.random( 5 ) * 0.01 ) + ( math.random( 10 ) * 0.001 )
       end
       updatePos( planet, nil, planet.dampening )
       if( planet.toFront ) then
            planet:toFront()
       end
    end
    
    if( removalIndex ) then
        table.remove( planets, removalIndex )
        vinceAnim.orbitSpeed = vinceAnim.orbitSpeed + 1.2
    end


    vinceAnim:toFront()
    vinceFace:toFront()
    boredomMeterBar:toFront()
    boredomMeterFrame:toFront()
    
end


function vince:spawn(scene)
    mainScene = scene
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    
    

    local vinceSheet = graphics.newImageSheet( "images/vinceFireballAnim.gif", { width=144, height=117, numFrames=15 } )
    local vinceAnim = display.newSprite( vinceSheet, {{ name = "loop", start=1, count=15, time=900, loopCount=0 }} )
    
    
    vinceAnim:setSequence( "loop" )
	vinceAnim:play()
    
	vinceAnim.anchorX=0.5;vinceAnim.anchorY=0.5
	mainScene.city.displayGroup:insert( vinceAnim )
    
    vinceAnim.x = scene.rightEdge + 500
    vinceAnim.y = display.contentCenterY
	vinceAnim.health = kPlanetHealth
    vinceAnim.xChoke = 80
    vinceAnim.yChoke = 80
    vinceAnim.xScale = 2
    vinceAnim.yScale = 2
    vinceAnim.explosionScale = 1.8
    vinceAnim.blendMode = "screen"
    
    vinceAnim.targetX = -300
    vinceAnim.targetY = 100
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
    
    local vinceFace = display.newImageRect( "images/vinceFace.gif", 75, 79 )
    vinceFace.blendMode = "multiply"
    vinceFace.alpha = 0.8
    vinceFace.x = vinceAnim.x - 5
    vinceFace.y = vinceAnim.y + 10
    mainScene.city.displayGroup:insert( vinceFace )
    
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    
    local boredomMeterFrame = display.newImageRect( "images/vinceBoredomMeterFrame.png", 137, 25 )
    mainScene.city.displayGroup:insert( boredomMeterFrame )
    boredomMeterFrame.xScale = 0.001
    boredomMeterFrame.yScale = 0.001
    boredomMeterFrame.isVisible = false
    
    local boredomMeterBar = display.newImageRect( "images/vinceBoredomMeterBar.gif", 133, 6 )
    --boredomMeterBar.blendMode = "add"
    boredomMeterBar.anchorY = 0.5
    boredomMeterBar.anchorX = 0
    boredomMeterBar.xScale = 0.01
    boredomMeterBar.alpha = 0.85
    mainScene.city.displayGroup:insert( boredomMeterBar )
    

    
    
    local planets = {}
    
    local mercury = display.newImageRect( "images/vinceMercury.png", 42, 43 )
    mercury.orbit = 0
    mercury.x,mercury.y = getPointOnCircle( mercury, vinceAnim )
    mercury.alpha = 0.95
    mainScene.city.displayGroup:insert( mercury )
    mainScene.enemies:add( mercury )
    table.insert( planets, mercury )
    
    local venus = display.newImageRect( "images/vinceVenus.png", 53, 54 )
    venus.orbit = 51
    venus.x,venus.y = getPointOnCircle( venus, vinceAnim )
    venus.alpha = 0.95
    mainScene.city.displayGroup:insert( venus )
    mainScene.enemies:add( venus )
    table.insert( planets, venus )
    
    local earth = display.newImageRect( "images/vinceEarth.png", 57, 59 )
    earth.orbit = 102
    earth.x,earth.y = getPointOnCircle( earth, vinceAnim )
    earth.alpha = 0.95
    mainScene.city.displayGroup:insert( earth )
    mainScene.enemies:add( earth )
    table.insert( planets, earth )
    
    local mars = display.newImageRect( "images/vinceMars.png", 52, 52 )
    mars.orbit = 153
    mars.x,mars.y = getPointOnCircle( mars, vinceAnim )
    mars.alpha = 0.95
    mainScene.city.displayGroup:insert( mars )
    mainScene.enemies:add( mars )
    table.insert( planets, mars )
    
    local saturn = display.newImageRect( "images/vinceSaturn.png", 114, 87 )
    saturn.orbit = 205
    saturn.x,saturn.y = getPointOnCircle( saturn, vinceAnim )
    saturn.alpha = 0.95
    mainScene.city.displayGroup:insert( saturn )
    mainScene.enemies:add( saturn )
    table.insert( planets, saturn )
    
    local uranus = display.newImageRect( "images/vinceUranus.png", 46, 46 )
    uranus.orbit = 257
    uranus.x,uranus.y = getPointOnCircle( uranus, vinceAnim )
    uranus.alpha = 0.95
    mainScene.city.displayGroup:insert( uranus )
    mainScene.enemies:add( uranus )
    table.insert( planets, uranus )
    
    local neptune = display.newImageRect( "images/vinceNeptune.png", 42, 43 )
    neptune.orbit = 309
    neptune.x,neptune.y = getPointOnCircle( neptune, vinceAnim )
    neptune.alpha = 0.95
    mainScene.city.displayGroup:insert( neptune )
    mainScene.enemies:add( neptune )
    table.insert( planets, neptune )
    
    for i, planet in ipairs( planets ) do
        planet.bSpecialPowerImmunity = true
        planet.bObstacleImmunity = true
        planet.bDisableCulling = true
        planet.explosionScale = 1.8
        planet.onDeath = function()
            showPoints( planet )
        end
    end
    
    local myUpdate = function()
        
            update( mainScene, vinceAnim, vinceFace, planets, boredomMeterBar, boredomMeterFrame, self )

    end
    
    Runtime:addEventListener( "enterFrame", myUpdate )
    
    mainScene.bVinceAlive = true
    
	vinceAnim.name = "vince"
    vinceAnim.bSpecialPowerImmunity = true
    vinceAnim.bObstacleImmunity = true
    vinceAnim.bDisableCulling = true
    
    vinceAnim.spawnTime = system.getTimer()
    
    vinceAnim.voiceAudio = audio.loadStream( "sounds/voice-vinceIsBoring.wav" )
    
    
    vinceAnim.explosionSound = audio.loadSound( "sounds/vinceExplosion.wav", { channel=2})
   
    vinceAnim.kill = function()
        if( planets ) then
            for i, planet in ipairs( planets ) do
                planet.health = 0
            end
        end
        planets = nil
        Runtime:removeEventListener( "enterFrame", myUpdate )
            if( not mainScene.bGameOver ) then
                showPoints( vinceAnim, 5 )
                audio.play( vinceAnim.explosionSound )
            end
            audio.stop( vinceAnim.audioChannel )
            audio.dispose( vinceAnim.voiceAudio )
            vinceAnim.voiceAudio = nil
            vinceAnim.audioChannel = nil
            mainScene:doExplosion( vinceAnim, vinceAnim.explosionScale)


            boredomMeterFrame:removeSelf()
            boredomMeterBar:removeSelf()
            vinceFace:removeSelf()
            
            viceFace = nil
            boredomMeterBar = nil
            boredomMeterFrame = nil
            
            local achievement = "CgkIhf7UyIMOEAIQCg"
            if ( system.getInfo("platformName") == "iPhone OS" ) then 
                achievement = "vince"
            end
            gameNetwork.request( "unlockAchievement", { achievement = { identifier=achievement, percentComplete=100, showsCompletionBanner=true } } )

        vinceAnim = nil
    end
    
    vinceAnim.name = "vince"
    
    if( not self.maryJaneSound ) then
        self.maryJaneSound = mainScene.sound:loadVoice("voice-maryJaneVince.wav" )
    end
    
    mainScene.sound:playVoice( self.maryJaneSound, 2, true )
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
	
    
    return vinceAnim
end

return vince