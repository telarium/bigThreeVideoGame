local trophy = {
   
}

local function addGroundImpact( obj, mainScene, self )
    -- 
   -- bottomBase.groundSound2 = mainScene.sound:load( "impact8.wav" )
       local num = math.random( 2 )
       if( not self.groundSound1 ) then
            self.groundSound1 = mainScene.sound:load( "impact7.wav" )
            self.groundSound2 = mainScene.sound:load( "impact8.wav" )
       end
      
        
    obj.onGroundImpact = function(event)
        if( event.other == mainScene.ground and event.force >= 0.1 and event.force < 3 and obj.contentBounds.xMin < mainScene.rightEdge) then
            if( num == 1 ) then
                mainScene.sound:play( self.groundSound1 )
            else
                mainScene.sound:play( self.groundSound2 )
            end
            mainScene.sound:play( obj.groundSound )
        end
    end
end

function trophy:setup(mainScene)
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    
    local linearX = math.random(3)+7
    local angle = math.random(60)+60
        

    local x = mainScene.city:getGroundSpawnCoordinate()
    
    if( x < mainScene.city:getGroundSpawnCoordinate() ) then
        x = mainScene.city:getGroundSpawnCoordinate() + 200
	end
    
    local objects = {}
    local bottomBase = display.newImageRect( "images/trophy_bottomBase.png", 55, 9 )		
	bottomBase.anchorX = 0.5
	bottomBase.anchorY = 0.5
    bottomBase.x = x + bottomBase.width/2
    bottomBase.y = mainScene.groundY - bottomBase.height/2 - 3	
   
   
   --physics.addBody( tableSprite, "dynamic",
  --{ density=.03, friction=0.2, bounce=0.3, shape={   71.5, 15.5  ,  66.5, -6.5  ,  84.5, -19.5  ,  82.5, 22.5  } },
  --{ density=.03, friction=0.2, bounce=0.3, shape={   -84.5, 21.5  ,  -86.5, -19.5  ,  -70.5, -6.5  ,  -75.5, 17.5  } },
  --{ density=.03, friction=0.2, bounce=0.3, shape={   66.5, -6.5  ,  -70.5, -6.5  ,  -86.5, -19.5  ,  84.5, -19.5  } }
--)

    bottomBase.isAwake = true
    bottomBase.bTestForCollision = true
    bottomBase.xChoke = 0
    bottomBase.yChoke = 0
    bottomBase.linearX = linearX
    bottomBase.angle = angle
    
    mainScene.city.displayGroup:insert( bottomBase )
    table.insert( objects, bottomBase )
    bottomBase.initialSound = mainScene.sound:load( "impact1.wav" )
    
    
    local bottomLeft = display.newImageRect( "images/trophy_bottomLeft.png", 10, 52 )		
    bottomLeft.anchorX = 0.5
	bottomLeft.anchorY = 0.5
    bottomLeft.x = bottomBase.x - 16
    bottomLeft.y = bottomBase .y- 31
    bottomLeft.isAwake = true
    bottomLeft.bTestForCollision = true
    bottomLeft.linearX = linearX
    bottomLeft.angle = angle
    bottomLeft.doObstacleCollisionCheck = true
    bottomLeft.bPerciseCollisionDetection = true
    mainScene.city.displayGroup:insert( bottomLeft )
    addGroundImpact( bottomLeft, mainScene, self )
    table.insert( objects, bottomLeft )
    bottomLeft.name = "bottomLeft"
    
    
    local bottomRight = display.newImageRect( "images/trophy_bottomRight.png", 10, 52 )		
    bottomRight.anchorX = 0.5
	bottomRight.anchorY = 0.5
    bottomRight.x = bottomBase.x + 17
    bottomRight.y = bottomBase .y- 31
    bottomRight.isAwake = true
    bottomRight.bTestForCollision = true
    bottomRight.linearX = linearX
    bottomRight.angle = angle
    addGroundImpact( bottomRight, mainScene, self )
    mainScene.city.displayGroup:insert( bottomRight )
    table.insert( objects, bottomRight )
    
    local middleBase = display.newImageRect( "images/trophy_middleBase.png", 56, 8 )		
    middleBase.anchorX = 0.5
	middleBase.anchorY = 0.5
    middleBase.x = bottomBase.x + 1
    middleBase.y = bottomBase .y - 61
    middleBase.isAwake = true
    middleBase.bTestForCollision = true
    middleBase.linearX = linearX
    middleBase.angle = angle
    mainScene.city.displayGroup:insert( middleBase )
    table.insert( objects, middleBase )
    
    local middleLeft = display.newImageRect( "images/trophy_middleLeft.png", 10, 56 )		
    middleLeft.anchorX = 0.5
	middleLeft.anchorY = 0.5
    middleLeft.x = bottomBase.x - 16
    middleLeft.y = bottomBase .y- 93
    middleLeft.isAwake = true
    middleLeft.bTestForCollision = true
    middleLeft.linearX = linearX
    middleLeft.angle = angle
    middleLeft.doObstacleCollisionCheck = true
    mainScene.city.displayGroup:insert( middleLeft )
    table.insert( objects, middleLeft )
    addGroundImpact( middleLeft, mainScene, self )
    
    local middleRight = display.newImageRect( "images/trophy_middleRight.png", 10, 56 )		
    middleRight.anchorX = 0.5
	middleRight.anchorY = 0.5
    middleRight.x = bottomBase.x + 17
    middleRight.y = bottomBase .y- 93
    middleRight.isAwake = true
    middleRight.bTestForCollision = true
    middleRight.linearX = linearX
    middleRight.angle = angle
    mainScene.city.displayGroup:insert( middleRight )
    addGroundImpact( middleRight, mainScene, self )
    table.insert( objects, middleRight )
    
    local middleCenter = display.newImageRect( "images/trophy_middleCenter.png", 17, 44 )		
    middleCenter.anchorX = 0.5
	middleCenter.anchorY = 0.5
    middleCenter.x = bottomBase.x +1
    middleCenter.y = bottomBase .y- 87
    middleCenter.isAwake = true
    middleCenter.bTestForCollision = true
    middleCenter.linearX = linearX
    middleCenter.angle = angle
    mainScene.city.displayGroup:insert( middleCenter )
    table.insert( objects, middleCenter )
    
    local topBase = display.newImageRect( "images/trophy_topBase.png", 50, 6 )		
    topBase.anchorX = 0.5
	topBase.anchorY = 0.5
    topBase.x = bottomBase.x
    topBase.y = bottomBase.y - 124
    topBase.isAwake = true
    topBase.bTestForCollision = true
    topBase.linearX = linearX
    topBase.angle = angle
    mainScene.city.displayGroup:insert( topBase )
    table.insert( objects, topBase )
    
    
    local topLeft = display.newImageRect( "images/trophy_topLeft.png", 9, 12 )		
    topLeft.anchorX = 0.5
	topLeft.anchorY = 0.5
    topLeft.x = bottomBase.x - 17
    topLeft.y = bottomBase.y - 133
    topLeft.isAwake = true
    topLeft.bTestForCollision = true
    topLeft.bPerciseCollisionDetection = true
    topLeft.linearX = linearX
    topLeft.angle = angle
    topLeft.doObstacleCollisionCheck = true
    mainScene.city.displayGroup:insert( topLeft )
    addGroundImpact( topLeft, mainScene, self )
    table.insert( objects, topLeft )
    
    local topRight = display.newImageRect( "images/trophy_topRight.png", 9, 12 )		
    topRight.anchorX = 0.5
	topRight.anchorY = 0.5
    topRight.x = bottomBase.x + 17
    topRight.y = bottomBase.y - 133
    topRight.isAwake = true
    topRight.bTestForCollision = true
    topRight.linearX = linearX
    topRight.angle = angle
    mainScene.city.displayGroup:insert( topRight )
    addGroundImpact( topRight, mainScene, self )
    table.insert( objects, topRight )
    
    local topCenter = display.newImageRect( "images/trophy_topCenter.png", 31, 38 )		
    topCenter.anchorX = 0.5
	topCenter.anchorY = 0.5
    topCenter.x = bottomBase.x - 1
    topCenter.y = bottomBase.y - 146
    topCenter.isAwake = true
    topCenter.bTestForCollision = true
    topCenter.bPerciseCollisionDetection = true
    topCenter.linearX = linearX
    topCenter.angle = angle
    topCenter.doObstacleCollisionCheck = true
    mainScene.city.displayGroup:insert( topCenter )
     addGroundImpact( topCenter, mainScene, self )
    table.insert( objects, topCenter )
    
    for i, piece in ipairs( objects ) do
        piece.collisionDistance = 50
    end

    bottomBase.onInitialImpact = function()
        mainScene.sound:play( bottomBase.initialSound, true )
        local d = 0.48
        local f = 0.2
        local b = 0.4
        --physics.addBody( bottomBase, { density = d, friction = f, bounce = b } )
        if( bottomLeft.x ) then
            physics.addBody( bottomLeft, { density = d, friction = f, bounce = b } )
            physics.addBody( bottomRight, { density = d, friction = f, bounce = b } )
            physics.addBody( middleBase, { density = d, friction = f, bounce = b } )
            physics.addBody( middleLeft, { density = d, friction = f, bounce = b } )
            physics.addBody( middleRight, { density = d, friction = f, bounce = b } )
            physics.addBody( middleCenter, { density = d, friction = f, bounce = b } )
            physics.addBody( topBase, { density = d, friction = f, bounce = b } )
            physics.addBody( topLeft, { density = d, friction = f, bounce = b } )
            physics.addBody( topRight, { density = d, friction = f, bounce = b } )
            physics.addBody( topCenter, { density = d, friction = f, bounce = b } )
            
            bottomLeft.name = "bottomLeft"
            bottomRight.name = "bottomRight"
            middleBase.name = "middleBase"
            middleLeft.name = "middleLeft"
            middleRight.name = "middleRight"
            middleCenter.name = "middleCenter"
            topLeft.name = "topLeft"
            topBase.name = "topBase"
            topRight.name = "topRight"
            topCenter.name = "topCenter"
       end
    end
 
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
    
    return objects
end

function trophy:spawn(mainScene)
	local obstacleGroup = {}
	obstacleGroup.name = "trophy"
    obstacleGroup.bodies = trophy:setup(mainScene)
	return obstacleGroup
end

return trophy
