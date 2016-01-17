local lowAlpha = 0.6
local highAlpha = 0.95
local i = 10

local elvis = {
   sound = mainScene.sound:loadDamageSound( "spark.wav" )
}

local function updateFlicker( obj, parent )    
    if( not obj.x ) then
        obj = nil
        return
    end

    if( not obj.x and parent.x and obj.offsetX) then
        obj = nil
        return
    end

    if( not obj.bInitialized ) then
        obj.offsetX = parent.x - obj.x
        obj.offsetY = parent.y - obj.y
        obj.bInitialized = true
        if( not obj.bAnim ) then
            obj.alpha = lowAlpha
        else
            obj.alpha = highAlpha
        end
    end

    if( parent.x and obj.x ) then
        obj.x = parent.x + obj.offsetX
        obj.y = parent.y + obj.offsetY
        obj.rotation = parent.rotation

        if( not obj.bAnim ) then
            obj.alpha = obj.alpha + 0.08
            if( obj.alpha >= highAlpha ) then
                obj.alpha = highAlpha
                obj.bAnim = true
            end
        else
            obj.alpha = obj.alpha - 0.08
            if( obj.alpha <= lowAlpha ) then
                obj.alpha = lowAlpha
                obj.bAnim = false
            end
        end
    end
end

local function update( mainScene, letterBase1, letterLight1A, letterLight1B, letterBase2, letterLight2a, letterLight2b, letterBase3, letterLight3a, letterLight3b, letterBase4, letterBase4a, letterBase4b, letterBase5, letterBase5a, letterBase5b ) 
    updateFlicker( letterLight1A, letterBase1 )
    updateFlicker( letterLight1B, letterBase1 )
    updateFlicker( letterLight2a, letterBase2 )
    updateFlicker( letterLight2b, letterBase2 )
    updateFlicker( letterLight3a, letterBase3 )
    updateFlicker( letterLight3b, letterBase3 )
    updateFlicker( letterBase4a, letterBase4 )
    updateFlicker( letterBase4b, letterBase4 )
    updateFlicker( letterBase5a, letterBase5 )
    updateFlicker( letterBase5b, letterBase5 )
end

local function addFlickerAnim( obj )
    obj.transition1 = transition.to( obj, { time = 200, delay = 0, alpha = 0.8, iterations = 0 } )
end

local function spawnAgents(mainScene, objects, spawnX, self)
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )

    local x = mainScene.city:getGroundSpawnCoordinate()

    local letterBase1 = display.newImageRect( "images/elvisLights_e1.png", 58, 94 )		
	letterBase1.anchorX = 0.5
	letterBase1.anchorY = 0.5
    
    local linearX = 330 + math.random( 30 )
    local angle = 40
    
    if( spawnX ) then
        letterBase1.x = spawnX
    else
        letterBase1.x = x + letterBase1.width/2 + 20
        
    end
    
    letterBase1.y = mainScene.groundY - letterBase1.height/2 - 3	
   
    letterBase1.isAwake = true
    letterBase1.bTestForCollision = true
    letterBase1.xChoke = 0
    letterBase1.yChoke = 0
    letterBase1.linearX = linearX
    letterBase1.angle = angle
    letterBase1.id = "base1"
    letterBase1.explosionScale = 2
    letterBase1.collisionDistance = 55
    letterBase1.doObstacleCollisionCheck = true
    
    mainScene.city.displayGroup:insert( letterBase1 )
    table.insert( objects, letterBase1 )
    
    local letterLight1A = display.newImageRect( "images/elvisLights_e2.png", 54, 90 )		
	letterLight1A.anchorX = 0.5
	letterLight1A.anchorY = 0.5
    letterLight1A.x = letterBase1.x
    letterLight1A.y = letterBase1.y
    letterLight1A.blendMode = "add"
    letterLight1A.bAnim = true
    letterLight1A.disableEnemyCollision = true
    
    mainScene.city.displayGroup:insert( letterLight1A )
    table.insert( objects, letterLight1A )
    
    local letterLight1B = display.newImageRect( "images/elvisLights_e3.png", 54, 90 )		
	letterLight1B.anchorX = 0.5
	letterLight1B.anchorY = 0.5
    letterLight1B.x = letterLight1A.x
    letterLight1B.y = letterLight1A.y
    letterLight1B.blendMode = "add"
    letterLight1B.disableEnemyCollision = true
    mainScene.city.displayGroup:insert( letterLight1B )
    table.insert( objects, letterLight1B )
    
    
    local letterBase2 = display.newImageRect( "images/elvisLights_l1.png", 53, 94 )		
	letterBase2.anchorX = 0.5
	letterBase2.anchorY = 0.5
    letterBase2.x = letterBase1.x + 70
    letterBase2.y = letterBase1.y
    letterBase2.isAwake = true
    letterBase2.bTestForCollision = true
    letterBase2.xChoke = 0
    letterBase2.yChoke = 0
    letterBase2.linearX = linearX
    letterBase2.angle = angle
    letterBase2.id = "base2"
    letterBase2.doObstacleCollisionCheck = true
    letterBase2.disableEnemyCollision = true
    letterBase2.explosionScale = 2
    
    mainScene.city.displayGroup:insert( letterBase2 )
    table.insert( objects, letterBase2 )
    
    local letterLight2a = display.newImageRect( "images/elvisLights_l2.png", 49, 90 )		
	letterLight2a.anchorX = 0.5
	letterLight2a.anchorY = 0.5
    letterLight2a.x = letterBase2.x - 1
    letterLight2a.y = letterBase2.y
    letterLight2a.blendMode = "add"
    letterLight2a.disableEnemyCollision = true
    mainScene.city.displayGroup:insert( letterLight2a )
    table.insert( objects, letterLight2a )
    
    local letterLight2b = display.newImageRect( "images/elvisLights_l3.png", 45, 70 )		
	letterLight2b.anchorX = 0.5
	letterLight2b.anchorY = 0.5
    letterLight2b.x = letterBase2.x + 1
    letterLight2b.y = letterBase2.y - 10
    letterLight2b.blendMode = "add"
    letterLight2b.bAnim = true
    letterLight2b.disableEnemyCollision = true
    mainScene.city.displayGroup:insert( letterLight2b )
    table.insert( objects, letterLight2b )
    
    
    local letterBase3 = display.newImageRect( "images/elvisLights_v1.png", 87, 94 )		
	letterBase3.anchorX = 0.5
	letterBase3.anchorY = 0.5
    letterBase3.x = letterBase2.x + 60
    letterBase3.y = letterBase2.y
    letterBase3.isAwake = true
    letterBase3.bTestForCollision = true
    letterBase3.xChoke = 0
    letterBase3.yChoke = 0
    letterBase3.linearX = linearX
    letterBase3.angle = angle
    letterBase3.id = "base3"
    letterBase3.explosionScale = 2
    
    mainScene.city.displayGroup:insert( letterBase3 )
    table.insert( objects, letterBase3 )
    
    local letterLight3a = display.newImageRect( "images/elvisLights_v2.png", 77, 90 )		
	letterLight3a.anchorX = 0.5
	letterLight3a.anchorY = 0.5
    letterLight3a.x = letterBase3.x - 1
    letterLight3a.y = letterBase3.y
    letterLight3a.bAnim = true
    letterLight3a.blendMode = "add"
    letterLight3a.disableEnemyCollision = true

    mainScene.city.displayGroup:insert( letterLight3a )
    table.insert( objects, letterLight3a )
    
    local letterLight3b = display.newImageRect( "images/elvisLights_v3.png", 80, 90 )		
	letterLight3b.anchorX = 0.5
	letterLight3b.anchorY = 0.5
    letterLight3b.x = letterBase3.x
    letterLight3b.y = letterBase3.y
    letterLight3b.blendMode = "add"
    mainScene.city.displayGroup:insert( letterLight3b )
    table.insert( objects, letterLight3b )
    
    
    local letterBase4 = display.newImageRect( "images/elvisLights_i1.png", 30, 94 )		
	letterBase4.anchorX = 0.5
	letterBase4.anchorY = 0.5
    letterBase4.x = letterBase3.x + 65
    letterBase4.y = letterBase3.y
    letterBase4.isAwake = true
    letterBase4.bTestForCollision = true
    letterBase4.xChoke = 0
    letterBase4.yChoke = 0
    letterBase4.linearX = linearX
    letterBase4.angle = angle
    letterBase4.id = "base4"
    letterBase4.explosionScale = 2
    letterBase4.disableEnemyCollision = true
    
    mainScene.city.displayGroup:insert( letterBase4 )
    table.insert( objects, letterBase4 )
    
    local letterBase4a = display.newImageRect( "images/elvisLights_i2.png", 26, 84 )		
	letterBase4a.anchorX = 0.5
	letterBase4a.anchorY = 0.5
    letterBase4a.x = letterBase4.x
    letterBase4a.y = letterBase4.y - 4
    letterBase4a.blendMode = "add"
    letterBase4a.disableEnemyCollision = true
    letterBase4a.isVisible = true
    mainScene.city.displayGroup:insert( letterBase4a )
    table.insert( objects, letterBase4a )
    
    local letterBase4b = display.newImageRect( "images/elvisLights_i3.png", 26, 90 )		
	letterBase4b.anchorX = 0.5
	letterBase4b.anchorY = 0.5
    letterBase4b.x = letterBase4.x
    letterBase4b.y = letterBase4.y + 2
    letterBase4b.alpha = 1
    letterBase4b.blendMode = "add"
    letterBase4b.bAnim = true
    letterBase4b.isVisible = true
    letterBase4b.disableEnemyCollision = true
    mainScene.city.displayGroup:insert( letterBase4b )
    table.insert( objects, letterBase4b )
    
    
    
    local letterBase5 = display.newImageRect( "images/elvisLights_s1.png", 70, 99 )		
	letterBase5.anchorX = 0.5
	letterBase5.anchorY = 0.5
    letterBase5.x = letterBase4.x + 65
    letterBase5.y = letterBase4.y
    letterBase5.isAwake = true
    letterBase5.bTestForCollision = true
    letterBase5.xChoke = 0
    letterBase5.yChoke = 0
    letterBase5.linearX = linearX
    letterBase5.angle = angle
    letterBase5.id = "base5"
    letterBase5.explosionScale = 2
    
    mainScene.city.displayGroup:insert( letterBase5 )
    table.insert( objects, letterBase5 )
    
    local letterBase5a = display.newImageRect( "images/elvisLights_s2.png", 64, 95 )		
	letterBase5a.anchorX = 0.5
	letterBase5a.anchorY = 0.5
    letterBase5a.x = letterBase5.x
    letterBase5a.y = letterBase5.y
    letterBase5a.blendMode = "add"
    letterBase5a.bAnim = true
    letterBase5a.disableEnemyCollision = true
    mainScene.city.displayGroup:insert( letterBase5a )
    table.insert( objects, letterBase5a )
    
    local letterBase5b = display.newImageRect( "images/elvisLights_s3.png", 66, 95 )		
	letterBase5b.anchorX = 0.5
	letterBase5b.anchorY = 0.5
    letterBase5b.x = letterBase5a.x - 1
    letterBase5b.y = letterBase5a.y
    letterBase5b.alpha = 1
    letterBase5b.disableEnemyCollision = true

    letterBase5b.blendMode = "add"
    mainScene.city.displayGroup:insert( letterBase5b )
    table.insert( objects, letterBase5b )
    
    if( math.random( 3 ) > 1 ) then
        
        mainScene.sound:playDamageSound( sound )
    end
    
    local i = 10
    
    letterBase5.update = function()
        i = i - 1
        if( i > 0 ) then
            return
        end
        update( mainScene, letterBase1, letterLight1A, letterLight1B, letterBase2, letterLight2a, letterLight2b, letterBase3, letterLight3a, letterLight3b, letterBase4, letterBase4a, letterBase4b, letterBase5, letterBase5a, letterBase5b )
    end
    
    letterBase1.onInitialImpact = function()
        mainScene.sound:play( self.initialSound, true )
        local d = 1.4
        local f = 0.14
        local b = 0.2
        
        transition.blink( letterLight1A, { time=500 } )
        letterLight2b.isVisible = false
        transition.blink( letterLight3a, { time=400 } )
        transition.blink( letterBase4b, { time=600 } )
        letterBase5a.isVisible = false
        transition.blink( letterBase5b, { time=350 } )
        
        letterBase1.rotation = 30 + math.random( 20 )
        
        physics.addBody( letterBase1, { density = d, friction = f, bounce = b } )
        
        physics.addBody( letterBase2, "dynamic",
                  { density=d, friction=f, bounce=b, shape = {   -26.5, 47  ,  25.5, 23  ,  26.5, 23  ,  26.5, 47  } },
                  { density=d, friction=f, bounce=b, shape = {   3.5, -47  ,  3.5, -46  ,  -26.5, 47  ,  -26.5, -47  } },
                  { density=d, friction=f, bounce=b, shape = {   25.5, 23  ,  -26.5, 47  ,  4.5, 22  ,  25.5, 22  } },
                  { density=d, friction=f, bounce=b, shape = {   4.5, 22  ,  -26.5, 47  ,  3.5, -46  ,  4.5, -46  } }
                )
        
         physics.addBody( letterBase3, "dynamic",
                  { density=d, friction=f, bounce=b, shape = {   -11.5, 45  ,  -40.5, -46  ,  41.5, -45  } },
                  { density=d, friction=f, bounce=b, shape = {   12.5, 48  ,  -13.5, 45  ,  43.5, -46  } }
                )

        physics.addBody( letterBase4, { density = d, friction = f, bounce = b } )
        physics.addBody( letterBase5, { density = d, friction = f, bounce = b } )
    end

    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
end

function elvis:setup(mainScene)
    local objects = {}
    
    spawnAgents(mainScene, objects, nil, self )
    
    local elvis = objects[1]
    
    if( not self.initialSound ) then
        self.initialSound = mainScene.sound:load( "impact9.wav" )
        self.groundSound1 = mainScene.sound:load( "impact7.wav" )
        self.groundSound2 = mainScene.sound:load( "impact8.wav" )
    end
    
    --elvis.onInitialImpact = function()
    --    mainScene.sound:play( self.initialSound, true )
    --end

    elvis.onGroundImpact = function(event)
        if( event.other == mainScene.ground and event.force >= 0.6 and event.force < 2 and elvis.contentBounds.xMin < mainScene.rightEdge) then
            local num = math.random( 2 ) 
            if( num == 1 ) then
                mainScene.sound:play( self.groundSound1 )
            else
                mainScene.sound:play( self.groundSound2 )
            end
        end
    end
    
    return objects
end

function elvis:spawn(mainScene)
	local obstacleGroup = {}
	obstacleGroup.name = "elvis"
    obstacleGroup.bodies = elvis:setup(mainScene)
	return obstacleGroup
end

return elvis
