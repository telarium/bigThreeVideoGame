local scene = storyboard.newScene()

display.setDefault( "magTextureFilter", "linear" )
display.setDefault( "minTextureFilter", "linear" )




local hitSound1 = nil
local cityChannel = nil

mainScene = scene


--------------------------------------------

scene.timeScale = 0.5

scene.leftEdge = 0 - ( ( display.actualContentWidth - display.contentWidth ) / 2 )
scene.rightEdge = display.contentWidth + ( ( display.actualContentWidth - display.contentWidth ) / 2 )
scene.bottomEdge = display.contentHeight + ( ( display.actualContentHeight - display.contentHeight ) / 2 )
scene.topEdge = 0 -  ( ( display.actualContentHeight - display.contentHeight ) / 2 )
scene.groundY = 0
scene.foldY = scene.bottomEdge - 35

scene.jumpEventID = nil
scene.specialPowerEventID = nil;
scene.score = 0
scene.bGameOver = false

scene.data = loadTable()

function scene:onJumpButton(event)
    if( event.params ) then
        scene.player:setJumping(true)
        return
    end
    local phase = event.phase 
    if "ended" == phase then
        scene.player:setJumping(false)
    elseif "began" == phase then
        scene.player:setJumping(true)
    end
end

function scene:onFireButton(event)
    if( scene.specialPowers.bPowerActive ) then
        return
    end
    if( event.params ) then
        scene.weapons:fire()
        return
    end
    local phase = event.phase 

    if "began" == phase then
        scene.weapons:fire()
   end
end

function scene:onSpecialPowersButton(event)
    if( event.params ) then
        scene.specialPowers:start()
        return
    end
    local phase = event.phase 

   if "began" == phase then
        scene.specialPowers:start()
   end
end

function scene:onDashButton(event)
    if( event.params ) then
        scene.player:dash()
        return
    end
   local phase = event.phase 
   if "began" == phase then
        scene.player:dash()
   end
end


function scene:setPhysics( bSet )
    if( bSet and not scene.bPhysicsSet ) then
        scene.bPhysicsSet = true
        physics.setPositionIterations( 1 )
        physics.setVelocityIterations( 2 )
        physics.start(false)
        --physics.setAverageCollisionPositions( true )
        --physics.setTimeStep( 1/70 )
        --physics.setDrawMode( "hybrid" )
        physics.addBody( scene.ground, "static", { friction=0.3, shape=scene.groundShape } )
    elseif( not bSet and scene.bPhysicsSet ) then
        physics.removeBody( scene.ground )
        physics.stop()
        scene.bPhysicsSet = false
    end
end

function scene:gameOver()
   if( not scene.bGameOver ) then
        scene.bGameOver = true
        
        mainScene:setPhysics( false )
        
        if( scene.ui ) then
            scene.ui:disable()
        end

        for i=1,scene.city.displayGroup.numChildren do
            if( scene.city.displayGroup[i].pause and scene.city.displayGroup[i] ~= mainScene.player.avatar ) then
                scene.city.displayGroup[i]:pause()
            end
        end
        
        if( scene.startTime >= 60000 and mainScene:getSelectedCharacter() == "perry" ) then
            local achievement = "CgkIhf7UyIMOEAIQCA"
            if ( system.getInfo("platformName") == "iPhone OS" ) then 
                achievement = "sixtySeconds"
            end
            gameNetwork.request( "unlockAchievement", { achievement = { identifier=achievement, percentComplete=100, showsCompletionBanner=true } } )
        end
        
        audio.fadeOut( { channel=1, time=500 } )
        
        local totalTime = ( system.getTimer() - scene.startTime ) * .001
        GA.newEvent( "design", { event_id="chicago:levelPlaytime",  area="main", value=totalTime})
        
        
        Runtime:removeEventListener( "enterFrame", gameLoop )
        transition.cancel()
        UIEndScreen_Show(scene, "chicago" )
   end
end


local counter = 0
local function gameLoop(event)
    mainScene.collisionCounter = mainScene.collisionCounter + 1
    local curTime = system.getTimer();
    local dt = curTime - scene.prevTime;
    scene.prevTime = curTime;
    scene.fps = math.floor(1000/dt);

    if( scene.bGameOver ) then
        return
    end

    counter = counter + 1

    scene.player:update()
    scene.city:update()
    scene.enemies:update()
    scene.obstacles:update()
	scene.powerUps:update()
    scene.weapons:update()
    scene.specialPowers:update()
    scene.ui:update()
	scene.levelData:update()
	
	if( mainScene.collisionCounter == 2 ) then
	   mainScene.collisionCounter = 0
	end
    
    --if( mainScene.testCollisionCounter > 5 ) then
    --    print( mainScene.testCollisionCounter )
    --end
    mainScene.testCollisionCounter = 0
    
    if( counter > 3 ) then
    
        counter = 0
        if( scene.physicsWeapons > 0 ) then
            scene:setPhysics( true )
            return
        end
    
        if( table.getn( scene.obstacles:getCollided() ) > 0 ) then
            scene:setPhysics( true )
            return
        end

        for _, obj in ipairs( scene.enemies:getActive() ) do
            if( obj.applyLinearImpulse ) then
                scene:setPhysics( true )
                return
            end
        end
        if( not bShowPhysics ) then
            if ( table.getn( scene.obstacles.miscObstacles ) > 0 ) then
                scene:setPhysics( true )
                return
            end
        end
        if( not bShowPhysics ) then
            for _, obj in ipairs( scene.weapons:getActive() ) do
                if( obj.applyLinearImpulse ) then
                    self:setPhysics( true )
                    return
                end
            end
        end
    
        scene:setPhysics( false )
    end
end



function scene:getSelectedCharacter()
	return storyboard.state.character
end

function scene:addPoints(points)
    scene.score = scene.score + ( points * 0.5 )
end

function scene:showDamageHit( x,y, bInCityGroup )
    if( not bInCityGroup ) then
        x,y = scene.city.displayGroup:localToContent( x,y )
    end
    
    
    local damageSprite = table.remove( mainScene.damageSpritePool, 1 )
    damageSprite.isVisible = true

    
    if( bInCityGroup ) then
        scene.city.displayGroup:insert( damageSprite )
    else
        scene.ui.uiGroup:insert( damageSprite )
    end
    
    local flip = math.random(2)
    if( flip ~= 1 ) then
        flip = -1
    end
    damageSprite.xScale = 0.5
    damageSprite.yScale = 0.5
    
    damageSprite.xScale = damageSprite.xScale * flip
    
    flip = math.random(2)
    if( flip ~= 1 ) then
        flip = -1
    end
    
    damageSprite.yScale = damageSprite.xScale * flip
    damageSprite.alpha = 0.75
	damageSprite.anchorX = 0.5
	damageSprite.anchorY = 0.5
    damageSprite.x = x
    damageSprite.y = y
    damageSprite.blendMode = "add"

    
    
    transition.to( damageSprite, { time=100, delay=0, xScale=1} )
    transition.to( damageSprite, { time=100, delay=0, yScale=1} )
    
    damageSprite:toFront()
    
    local complete = function()
        table.insert( mainScene.damageSpritePool, damageSprite )
        damageSprite.isVisible = false
        damageSprite = nil
    end
    
    timer.performWithDelay(200, complete )
end

function scene:doExplosion( obj, scale )
    if( not scale ) then
        scale = 1
    end
    local yFlip = 1
    local smokeSheet = nil
    local smoke = nil
    local poolNum = 0
    if( scale >= 2 ) then
        scale = 1
        smoke = table.remove( mainScene.explosionPool3, 1 )
        smoke.x = obj.x
        smoke.y = scene.groundY
        poolNum = 3
    elseif( scale >= 1.6 ) then
        yFlip = math.random(2)
        smoke = table.remove( mainScene.explosionPool1, 1 )
        smoke.x = obj.x
        smoke.y = obj.y
        poolNum = 1
    else
        if( scale > 0.5 ) then
            yFlip = math.random(2)
            local ran = math.random(2)
            if( ran == 1 ) then
                scale = 1
                smoke = table.remove( mainScene.explosionPool2, 1 )
                poolNum = 2
            else
                scale = scale * 0.75
                smoke = table.remove( mainScene.explosionPool1, 1 )
                poolNum = 1
            end
        else
            smoke = table.remove( mainScene.explosionPool1, 1 )
            poolNum = 1
        end
        smoke.x = obj.x
        smoke.y = obj.y
    end

    local flip = math.random(2)
    if( flip ~= 1 ) then
        flip = -1
    end
            
    smoke.xScale = scale * flip
  
    if( yFlip ~= 1 ) then
        yFlip = -1
    end
            
    smoke.yScale = scale * yFlip      
    smoke.alpha = (math.random(20)+70)*.01 
    smoke.isVisible = true
    smoke:setSequence( "sequence" )
    smoke:play()
    
    smoke:toFront()
    
    if( not scene.hitSoundTime ) then
        scene.hitSoundTime = 0
    end
    
    local function mySpriteListener( event )
        if ( event.phase == "ended" ) then
            smoke.isVisible = false
            if( poolNum == 1 ) then
                table.insert( mainScene.explosionPool1, smoke )
            elseif( poolNum == 2 ) then
                table.insert( mainScene.explosionPool2, smoke )
            else
                table.insert( mainScene.explosionPool3, smoke )
            end
            mySpriteListener = nil
        end
    end
    
    smoke:addEventListener( "sprite", mySpriteListener )
    if ( ( system.getTimer() - scene.hitSoundTime ) > 250 ) then
        scene.sound:playEnemyImpactSound( hitSound1 )
        scene.hitSoundTime = system.getTimer()
    end
end

local square = math.sqrt;
local left = nil
local right = nil
local xMin1 = nil
local xMax1 = nil
local yMin1 = nil
local yMin1 = nil
local xMin2 = nil
local xMax2 = nil
local yMin2 = nil
local yMin2 = nil
local bCollideLeft = nil
local bCollideRight = nil
local bCollideUp = nil
local bCollideDown = nil
local distValue = nil
local testX, testY = nil, nil
local numEnemies = 0
local width1 = nil
local width2 = nil
local dist = nil
local square = math.sqrt;
local left = nil
local right = nil
local xMin1 = nil
local xMax1 = nil
local yMin1 = nil
local yMin1 = nil
local xMin2 = nil
local xMax2 = nil
local yMin2 = nil
local yMin2 = nil
local bCollideLeft = nil
local bCollideRight = nil
local bCollideUp = nil
local bCollideDown = nil
local distValue = nil
local testX, testY = nil, nil
local numEnemies = 0
local testCounter = 0
function scene:checkCollision( obj1, obj2 )
    distvalue = 1000
    --if( obj1.name ) then
        --print( obj1.name )
    --end
    --if( obj2.name ) then
        --print( obj2.name )
    --end

   --if( not obj1 or not obj2 ) then
   --   return false;
   --end
   
   --if( obj1 ) then
   -- return false
   --end

   --if( not obj1.contentBounds or not obj2.contentBounds ) then
   --   return false;
   --end
   
   if( obj1.bDisableCollision or obj2.bDisableCollision ) then
   	  return false;
   end
   
   --if( not obj1.isVisible or not obj2.isVisible ) then
    --  return false;
   --end
   
   if( obj1 ~= mainScene.player.avatar and obj2 ~= mainScene.player.avatar ) then
    --if( obj1.collisionIndex and obj1.collisionIndex ~= mainScene.collisionCounter ) then
    -- return false
    --end
    
    --if( obj2.collisionIndex and obj2.collisionIndex ~= mainScene.collisionCounter ) then
    -- return false
    --end
   elseif( obj1 == mainScene.player.avatar and ( obj2.x - obj2.width/2 ) > mainScene.player.avatar.x + 50 ) then
   return
   end
   
   if( obj1.name == "weapon" and (obj2.x - obj2.width/2 ) > obj1.x + 50 ) then
      return
   end
    
    
    --numEnemies = table.getn( mainScene.enemies.activeEnemies )
    
    --if( numEnemies and numEnemies > 5 ) then
      --  if( numEnemies < 10 and distValue < 200 ) then
     --       distValue = 200
     --   end
    --end
   
   testX, testY = obj1.x-obj2.x, obj1.y-obj2.y
   
   if( obj1.collisionDistance and obj2.collisionDistance ) then
        if( obj1.collisionDistance > obj2.collisionDistance ) then
            distValue = obj1.collisionDistance
        else
            distValue = obj2.collisionDistance
        end
        
        mainScene.testCollisionCounter = mainScene.testCollisionCounter + 1
        if( math.abs( testX ) <= distValue and math.abs( testY ) <= distValue ) then
            return true
        else
            return false
        end
       
        --if( square(testX* testX + testY* testY) <= distValue ) then
        --    return true
        --else
          --  return false
       --end
    end
    
    --if( obj1 == mainScene.player.avatar or obj2 == mainScene.player.avatar ) then
       -- distValue = 200
    if( obj1.bPerciseCollisionDetection or obj2.bPerciseCollisionDetection ) then
        distValue = 300
    else
        distValue = 50
    end
    
    
   
   if( not obj1.bPerciseCollisionDetection and not obj2.bPerciseCollisionDetection ) then
       distValue = 50
       mainScene.testCollisionCounter = mainScene.testCollisionCounter + 1
       if( square(testX* testX + testY* testY) < distValue ) then
            return true
       else
            return false
       end
   end

   xMin1 = obj1.contentBounds.xMin
   xMax1 = obj1.contentBounds.xMax
   yMin1 = obj1.contentBounds.yMin
   yMax1 = obj1.contentBounds.yMax
   if( obj1.xChoke ) then
   	xMin1 = xMin1 + obj1.xChoke
   	xMax1 = xMax1 - obj1.xChoke
   end
   if( obj1.yChoke ) then
   	yMin1 = yMin1 + obj1.yChoke
   	yMax1 = yMax1 - obj1.yChoke
   end

   xMin2 = obj2.contentBounds.xMin
   xMax2 = obj2.contentBounds.xMax
   yMin2 = obj2.contentBounds.yMin
   yMax2 = obj2.contentBounds.yMax
   
   if( obj2.xChoke ) then
   	xMin2 = xMin2 + obj2.xChoke
   	xMax2 = xMax2 - obj2.xChoke
   end
   if( obj2.yChoke ) then
   	yMin2 = yMin2 + obj2.yChoke
   	yMax2 = yMax2 - obj2.yChoke
   end
   
   bCollideLeft = xMin1 <= xMin2 and xMax1 >= xMin2
   bCollideRight = xMin1 >= xMin2 and xMin1 <= xMax2
   bCollideUp = yMin1 <= yMin2 and yMax1 >= yMin2
   bCollideDown = yMin1 >= yMin2 and yMin1 <= yMax2
   
   
   
   mainScene.testCollisionCounter = mainScene.testCollisionCounter + 1

    return (bCollideLeft or bCollideRight) and (bCollideUp or bCollideDown)
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    mainScene.testCollisionCounter = 0 -- For use in the FPS debug output only
    mainScene.collisionCounter = 0
    
    scene.storyboard = storyboard

    scene.prevTime = system.getTimer()
	local group = self.view
	scene.bGameOver = false

	scene.levelData = require("chicagoLevelData");
    scene.city = require("chicagoCityObject");
    scene.player = require("chicagoPlayerObject");
    scene.enemies = require("chicagoEnemyObjects")
    scene.obstacles = require("chicagoObstacleObjects");
    scene.weapons = require("chicagoWeaponObjects")
    scene.specialPowers = require("chicagoSpecialPowers")
    scene.powerUps = require( "chicagoPowerUps" )
    scene.ui = require("chicagoUI")
    scene.sound = require( "chicagoSound" )
	
    scene.city:init(scene)
    scene.player:init(scene)
    scene.enemies:init(scene)
    scene.obstacles:init(scene)
    scene.weapons:init(scene)
	scene.powerUps:init(scene)
    scene.specialPowers:init(scene)
    scene.sound:init(scene)
    scene.ui:init(scene)
	scene.levelData:init(scene)
    
    scene.city:setSpeed()
    
    scene.startTime = system.getTimer()
    
    audio.setVolume( 0, { channel=1 } ) -- set the volume on channel 1
    scene.citySound = audio.loadStream( "sounds/cityAmbient.mp3" )
    cityChannel = audio.play( scene.citySound, { channel=1, loops=-1 } )
    audio.fade( { channel=1, time=3000, volume=1 } )

    hitSound1 = scene.sound:loadEnemyImpactSound( "hit1.wav" )

    Runtime:addEventListener( "enterFrame", gameLoop )
    
    GA.newEvent( "design", { event_id="chicago:playedAs:" .. scene:getSelectedCharacter()})
    
    mainScene.damageSpritePool = {}
    mainScene.explosionPool1 = {}
    mainScene.explosionPool2 = {}
    mainScene.explosionPool3 = {}
    local damageSprite = nil
    local smoke = nil
    local smokeSheet = nil
    local i = 30
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    while ( i > 0 ) do
        i = i - 1
        damageSprite = display.newImageRect( "images/damage.png", 33, 27)
        damageSprite.isVisible = false
        table.insert( mainScene.damageSpritePool, damageSprite )
        
        smokeSheet = graphics.newImageSheet( "images/smoke1anim.png", { width=84, height=67, numFrames=11 } )
        smoke = display.newSprite( smokeSheet, {{ name = "sequence", start=1, count=11, time=math.random(400)+500, loopCount=1 }} )
        smoke.isVisible = false
        smoke.anchorX = 0.5
        smoke.anchorY = 0.5
        scene.city.displayGroup:insert( smoke )
        table.insert( mainScene.explosionPool1, smoke )
        
        smokeSheet = graphics.newImageSheet( "images/smoke2anim.png", { width=39, height=32, numFrames=5 } )
        smoke = display.newSprite( smokeSheet, {{ name = "sequence", start=1, count=5, time=math.random(200)+300, loopCount=1 }} )
        smoke.isVisible = false
        smoke.anchorX = 0.5
        smoke.anchorY = 0.5
        scene.city.displayGroup:insert( smoke )
        table.insert( mainScene.explosionPool2, smoke )
        
        smokeSheet = graphics.newImageSheet( "images/smoke3anim.png", { width=115, height=85, numFrames=8 } )
        smoke = display.newSprite( smokeSheet, {{ name = "sequence", start=1, count=8, time=600, loopCount=1 }} )
        smoke.isVisible = false
        smoke.anchorX = 0.5
        smoke.anchorY = 1
        scene.city.displayGroup:insert( smoke )
        table.insert( mainScene.explosionPool3, smoke )
        
    end
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
    
    storyboard.removeAll()
    collectgarbage()
    
    scene.fadeOverlay = display.newRect(scene.leftEdge, scene.topEdge, display.actualContentWidth, display.actualContentHeight)
    scene.fadeOverlay:setFillColor(0, 0, 0)
    scene.fadeOverlay.alpha = 1
    scene.fadeOverlay.anchorX = 0
    scene.fadeOverlay.anchorY = 0
    scene.fadeOverlay.blendMode = "multiply"
    scene.ui.uiGroup:insert( scene.fadeOverlay )
    local fadeIn = transition.to( scene.fadeOverlay, { time=350, delay=100, alpha=0, transition=easing.inOutQuad } )
    
    local delay = function()
        scene.fadeOverlay:removeSelf()
        fadeIn = nil
    end
    timer.performWithDelay( 500, delay )
end

function scene:exitScene( event )
	Runtime:removeEventListener( "enterFrame", gameLoop )
    storyboard.state.bPlayedChicago = true
	scene:setPhysics( false )

    mainScene.damageSpritePool = nil
    mainScene.explosionPool1 = nil
    mainScene.explosionPool2 = nil
    mainScene.explosionPool3 = nil
	
	audio.dispose( hitSound1 )

	scene.city:destroy()
	if( scene.ui ) then
	   scene.ui:disable()
    end
	scene.enemies:destroy()
	scene.obstacles:destroy()
	scene.powerUps:destroy()
	scene.weapons:destroy()
	scene.specialPowers:destroy()
	scene.player:destroy()
	scene.sound:destroy()
	scene.levelData:destroy()
    
    if( scene.uiEndScreenDisplayGroup ) then
        scene.uiEndScreenDisplayGroup:removeSelf()
        scene.uiEndScreenDisplayGroup = nil
    end
    
    audio.stop( cityChannel )
    audio.dispose( scene.citySound )
    cityChannel = nil
    scene.citySound = nil
    
    scene.city = nil
    scene.enemies = nil
    scene.obstacles = nil
    scene.powerUps = nil
    scene.weapons = nil
    scene.specialPowers = nil
    scene.player = nil
    scene.sound = nil
    scene.levelData = nil
    
            
        unrequire("chicagoLevelData");
        unrequire("chicagoCityObject");
        unrequire("chicagoPlayerObject");
        unrequire("chicagoEnemyObjects")
        unrequire("chicagoObstacleObjects");
        unrequire("chicagoWeaponObjects")
        unrequire("chicagoSpecialPowers")
        unrequire("chicagoPowerUps" )
        unrequire("chicagoUI")
        unrequire("chicagoSound" )
    
    mainScene = nil
end

function scene:destroyScene( event )
    scene.effectsGroup:removeSelf()
    local group = self.view
    group:removeSelf()
	scene = nil
	collectgarbage()
end

scene:addEventListener( "createScene", scene )
scene:addEventListener( "enterScene", scene )
scene:addEventListener( "exitScene", scene )
scene:addEventListener( "destroyScene", scene )

-----------------------------------------------------------------------------------------

return scene