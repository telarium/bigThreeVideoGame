local dumpster = {
   
}

local function spawnAgents(mainScene, objects, spawnX)
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    
    local linearX = 70 + math.random( 30 )
    local angle = 120
        

    local x = mainScene.city:getGroundSpawnCoordinate()

    local dumpsterBase = display.newImageRect( "images/dumpster.png", 109, 70 )		
	dumpsterBase.anchorX = 0.75
	dumpsterBase.anchorY = 0.5
    
    if( spawnX ) then
        dumpsterBase.x = spawnX
        dumpsterBase.collisionDistance = 70
    else
        dumpsterBase.x = x + dumpsterBase.width/2 + 20
        dumpsterBase.disableEnemyCollision = true
    end
    
    dumpsterBase.y = mainScene.groundY - dumpsterBase.height/2 - 3	
   
    dumpsterBase.isAwake = true
    dumpsterBase.bTestForCollision = true
    dumpsterBase.xChoke = -10
    dumpsterBase.yChoke = 0
    dumpsterBase.linearX = linearX
    dumpsterBase.angle = angle
    dumpsterBase.id = "base"
    dumpsterBase.explosionScale = 2
    
    
    mainScene.city.displayGroup:insert( dumpsterBase )
    table.insert( objects, dumpsterBase )
    
    mainScene.city:setGroundSpawnCoordinate(dumpsterBase.x + (dumpsterBase.width/2), "dumpster")
        
    local lidLeft = display.newImageRect( "images/dumpsterLidLeft.png", 52, 13 )		
	lidLeft.anchorX = 0.5
	lidLeft.anchorY = 0.5
    lidLeft.x = dumpsterBase.x - 50
    lidLeft.y = dumpsterBase.y - 25
    lidLeft.isAwake = true
    lidLeft.linearX = 10
    lidLeft.angle = -10
    mainScene.city.displayGroup:insert( lidLeft )
    lidLeft.id = "lidLeft"
    lidLeft.collisionDistance = 30
    table.insert( objects, lidLeft )
    
    local lidRight = display.newImageRect( "images/dumpsterLidRight.png", 51, 13 )		
	lidRight.anchorX = 0.5
	lidRight.anchorY = 0.5
    lidRight.x = lidLeft.x + 50
    lidRight.y = lidLeft.y
    lidRight.linearX = 10
    --lidRight.angle = 70
    lidRight.isAwake = true
    mainScene.city.displayGroup:insert( lidRight )
    lidRight.id = "lidRight"
    lidRight.collisionDistance = 30
    table.insert( objects, lidRight )
    
    local garbage1 = display.newImageRect( "images/garbageBag.png", 33, 39 )		
	garbage1.anchorX = 0.5
	garbage1.anchorY = 0.5
    garbage1.x = dumpsterBase.x - 40
    garbage1.y = dumpsterBase.y + 10
    garbage1.linearX = 50
    garbage1.angle = 180
    garbage1.disableEnemyCollision = true
    garbage1.isAwake = true
    garbage1.id = "garbage1"

    if( math.random(3) == 1 ) then       
        local garbage2 = display.newImageRect( "images/garbageBag.png", 33, 39 )		
    	garbage2.anchorX = 0.5
    	garbage2.anchorY = 0.5
        garbage2.x = dumpsterBase.x + 10
        garbage2.y = dumpsterBase.y + 10
        --garbage2.linearX = 40
        --garbage2.angle = 20
        garbage2.disableEnemyCollision = true
        garbage2.isAwake = true
        garbage2.id = "garbage2"
        
        mainScene.city.displayGroup:insert( garbage1 )
        table.insert( objects, garbage1 )
        
        mainScene.city.displayGroup:insert( garbage2 )
        table.insert( objects, garbage2 )
   end
    
    dumpsterBase:toFront()
    dumpster.doObstacleCollisionCheck = true
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
end

function dumpster:setup(mainScene)
    local objects = {}
    
    spawnAgents(mainScene, objects, nil )
    
    local dumpster = objects[1]
    dumpster.bPerciseCollisionDetection = true
    dumpster.doObstacleCollisionCheck = true
    
    if( not self.initialSound ) then
        self.initialSound = mainScene.sound:load( "impact6.wav" )
        self.groundSound1 = mainScene.sound:load( "impact5.wav" )
        self.groundSound2 = mainScene.sound:load( "impact4.wav" )
    end
    
    dumpster.onInitialImpact = function()
        mainScene.sound:play( self.initialSound, true )
        local d = 2
        local f = 0.14
        local b = 0.2

        for i, object in ipairs( objects ) do
            if ( object.id == "base" ) then
                physics.addBody( object, "dynamic",
                  { density=d, friction=f, bounce=b, shape = {   -46, -19  ,  -46, 28  ,  -49, 35  ,  -54, 3  ,  -52, -19  } },
                  { density=d, friction=f, bounce=b, shape = {   54, 3  ,  48, 35  ,  45, 28  ,  45, -19  ,  50, -19  } },
                  { density=d, friction=f, bounce=b, shape = {   48, 35  ,  -49, 35  ,  -46, 28  ,  45, 28  } }
                  )
            end
            if( object.id == "lidLeft" ) then
                physics.addBody( object, { density = 0.3, friction = f, bounce = b } )
            end
            if( object.id == "lidRight" ) then 
                physics.addBody( object, { density = 0.3, friction = f, bounce = b } )
            end
            if( object.id == "garbage1" ) then
                physics.addBody( object, "dynamic",
                  { density=0.2, friction=0.2, bounce=0.1, shape = {   -6.5, 17.5  ,  -14.5, 13.5  ,  -11.5, -5.5  ,  -3.5, -9.5  ,  2.5, -9.5  ,  11.5, -2.5  ,  13.5, 17.5  } },
                  { density=0.2, friction=0.2, bounce=0.1, shape = {   2.5, -9.5  ,  -3.5, -9.5  ,  -7.5, -16.5  ,  3.5, -18.5  ,  8.5, -12.5  } }
                )
            end
            if( object.id == "garbage2" ) then          
                physics.addBody( object, "dynamic",
                  { density=0.1, friction=0.2, bounce=0.1, shape = {   -6.5, 17.5  ,  -14.5, 13.5  ,  -11.5, -5.5  ,  -3.5, -9.5  ,  2.5, -9.5  ,  11.5, -2.5  ,  13.5, 17.5  } },
                  { density=0.1, friction=0.2, bounce=0.1, shape = {   2.5, -9.5  ,  -3.5, -9.5  ,  -7.5, -16.5  ,  3.5, -18.5  ,  8.5, -12.5  } }
                )
            end
        end
    end

    dumpster.onGroundImpact = function(event)
        if( event.other == mainScene.ground and event.force >= 0.4 and event.force < 2 and dumpster.contentBounds.xMin < mainScene.rightEdge) then
            local num = math.random( 2 ) 
            if( num == 1 ) then
                mainScene.sound:play( self.groundSound1 )
            else
                mainScene.sound:play( self.groundSound2 )
            end
        end
    end
    
    local offset = 0
    local num = math.random( 3 )
    if(  mainScene.data.highScore ) then
        num = 3
    end
    while ( num > 0 ) do
        num = num - 1
        offset = offset + 113
        spawnAgents(mainScene, objects, dumpster.x + offset )
    end
    
    return objects
end

function dumpster:spawn(mainScene)
	local obstacleGroup = {}
	obstacleGroup.name = "dumpster"
    obstacleGroup.bodies = dumpster:setup(mainScene)
	return obstacleGroup
end

return dumpster
