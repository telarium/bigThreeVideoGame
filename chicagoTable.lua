----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script controls the properties of the tables of food (donuts, bananas, etc)
-- for the Chicago endless runner level

local tableSprite = nil
local pie = nil
local box = nil
local banana = nil
local donut1 = nil
local donut2 = nil
local donut3 = nil

local tableObject = {
   bPlayedSound = false
}

function tableObject:setup(mainScene)
    
    local boxes = {}

    local x = mainScene.city:getGroundSpawnCoordinate()
    
    if( x < mainScene.city:getGroundSpawnCoordinate() ) then
        x = mainScene.city:getGroundSpawnCoordinate() + 200
	end
    
    local objects = {}
    tableSprite = display.newImageRect( "images/table.png", 173, 30 )		
    tableSprite.anchorX = 0.5
	tableSprite.anchorY = 0.5
    tableSprite.x = x + tableSprite.width/2
    tableSprite.y = mainScene.groundY - tableSprite.height/2 - 5	
    

    tableSprite.isAwake = true
    tableSprite.bTestForCollision = true
    tableSprite.doObstacleCollisionCheck = true
    tableSprite.xChoke = 0
    tableSprite.yChoke = 0
    tableSprite.linearX = math.random(2)+9 * 15
    tableSprite.angle = math.random(40)-600 * -22
    tableSprite.bPerciseCollisionDetection = true
    
    mainScene.city.displayGroup:insert( tableSprite )
    table.insert( objects, tableSprite )
	if( not self.bPlayedSound ) then
		tableSprite.perrySound = mainScene.sound:loadVoice( "voice-moleTable.wav" )
		
	else
		audio.dispose( tableSprite.perrySound )
	end
    if( not self.initialSound ) then
        self.initialSound = mainScene.sound:load( "impact1.wav" )
        self.groundSound1 = mainScene.sound:load( "impact5.wav" )
        self.groundSound2 = mainScene.sound:load( "impact4.wav" )
    end
    tableSprite.explosionScale = 2

    
    tableSprite.onInitialImpact = function()
        mainScene.sound:play( self.initialSound, true )
		if( not self.bPlayedSound ) then
			self.bPlayedSound = mainScene.sound:playVoice( tableSprite.perrySound, 0.1 )
		end
        
        if( not donut1.y ) then
            return
        end

        donut1.y = donut1.y - 50
        donut2.y = donut1.y
        donut3.y = donut1.y
           
        if( banana.y ) then
            banana.y = banana.y - 100
        end
           
   
       physics.addBody( tableSprite, "dynamic",
      { density=2.4, friction=0.2, bounce=0.3, shape={   65.5, -7  ,  82.5, -13  ,  81.5, 15  } },
      { density=2.4, friction=0.2, bounce=0.3, shape={   -84.5, -13  ,  -68.5, -7  ,  -83.5, 15  } },
      { density=2.4, friction=0.2, bounce=0.3, shape={   65.5, -7  ,  -68.5, -7  ,  -84.5, -13  ,  82.5, -13  } }
    )
        
        if( pie ) then
            physics.addBody( pie, { density = 0.4, friction = 0.2, bounce = 0.1, shape = {   0, -7.5  ,  19, 2.5  ,  10, 11.5  ,  -10, 11.5  ,  -19, 2.5  } } )
        end
        
        for i, mybox in ipairs( boxes ) do
            mybox.y = mybox.y - math.random(20)
            mybox.x = mybox.x + math.random( 10 )
            mybox.rotation = math.random(20)
            mybox.doObstacleCollisionCheck = true
            physics.addBody( mybox, { density = 0.5, friction = 0.2, bounce = 0.1 } )
           -- mybox.collisionDistance = 30
            mybox.bPerciseCollisionDetection = true
        end
        
        boxes = nil
        
        physics.addBody( banana, { density = 0.8, friction = 0.2, bounce = 0.1, shape = { -1.5, -1  ,  -7.5, 0  ,  -3.5, -10 , -1.5, -1  ,  7.5, 10  ,  2.5, 10  ,  -7.5, 0  } } )
        physics.addBody( donut1, { density = 0.4, friction = 0.2, bounce = 0.2, radius = 7 } )
        physics.addBody( donut2, { density = 0.4, friction = 0.2, bounce = 0.2, radius = 7 } )
        physics.addBody( donut3, { density = 0.4, friction = 0.2, bounce = 0.2, radius = 7 } )
    
    end
    
    tableSprite.onGroundImpact = function(event)
	
        if( not tableSprite.contentBounds ) then
            return
        end

        if( event.other == mainScene.ground and event.force >= 2 and event.force < 30 and tableSprite.contentBounds.xMin < mainScene.rightEdge) then
            if( not tableSprite.soundCounter ) then
                tableSprite.soundCounter = 1
                mainScene.sound:play( self.groundSound1 )
            else
                tableSprite.soundCounter = nil
                mainScene.sound:play( self.groundSound2 )
            end
        end
    end

    
     box = display.newImageRect( "images/tableBox.png", 40, 15 )		
	box.anchorX = 0.5
	box.anchorY = 0.5
    box.x = tableSprite.x - 35
    box.y = tableSprite.y - 22
    box.doObstacleCollisionCheck = true

    box.isAwake = true
    box.bTestForCollision = true
    box.linearX = math.random(3)+1
    box.angle = math.random(40)-100
    
    mainScene.city.displayGroup:insert( box )
    table.insert( objects, box )
    table.insert( boxes, box )
        
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    
    local i = math.random(3)

    if( storyboard.state.pieTimeRounds and storyboard.state.pieTimeRounds > 3 ) then
        pie = display.newImageRect( "images/tablePie.png", 40, 23 )		
        pie.anchorX = 0.5
        pie.anchorY = 0.5
        pie.x = tableSprite.x - 50
        pie.y = tableSprite.y - 24

        pie.isAwake = true
        pie.bTestForCollision = true
        pie.linearX = math.random(3)+1
        pie.angle = math.random(40)-200
        
        mainScene.city.displayGroup:insert( pie )
        pie.collisionDistance = 35
        table.insert( objects, pie )
    else
        i = math.random( 5 ) + 2
    end
    
    mainScene.data.highScore = 100
    
    if( mainScene.data.highScore < 2000 ) then
        i = math.random(3)+3
    end
    
    local y = box.y
    while ( i > 0 ) do
            i = i - 1
            box = display.newImageRect( "images/tableBox.png", 40, 15 )		
        	box.anchorX = 0.5
        	box.anchorY = 0.5
            box.x = tableSprite.x - 35
            box.y = y - 15
            box.collisionDistance = 45
            
            y = box.y
        
            box.isAwake = true
            box.bTestForCollision = true
            box.linearX = math.random(3)+1
            box.angle = math.random(40)-100
            
            if( i > 1 ) then
                box.bTestForCollision = false
            end
            
            mainScene.city.displayGroup:insert( box )
            table.insert( objects, box )
            table.insert( boxes, box )
    end
    
    banana = display.newImageRect( "images/tableBanana.png", 15, 20 )		
    banana.anchorX = 0.5
	banana.anchorY = 0.5
    banana.x = tableSprite.x - 7
    banana.y = tableSprite.y - 21
    banana.rotation = -20
    banana.collisionDistance = 18
    
    banana.isAwake = true
    banana.bTestForCollision = true
    banana.linearX = math.random(3)+1
    banana.angle = math.random(40)-200
    
    mainScene.city.displayGroup:insert( banana )
    table.insert( objects, banana )
    
    
    donut1 = display.newImageRect( "images/tableDonut1.png", 16, 15 )		
    donut1.anchorX = 0.5
	donut1.anchorY = 0.5
    donut1.x = tableSprite.x + 20
    donut1.y = tableSprite.y - 20
    
    
    donut1.isAwake = true
    donut1.bTestForCollision = true
    donut1.linearX = math.random(3)+1
    donut1.angle = math.random(40)-300
    donut1.collisionDistance = 15
    
    mainScene.city.displayGroup:insert( donut1 )
    table.insert( objects, donut1 )
    
    donut2 = display.newImageRect( "images/tableDonut2.png", 16, 15 )		
    donut2.anchorX = 0.5
	donut2.anchorY = 0.5
    donut2.x = donut1.x + 15
    donut2.y = donut1.y
    donut2.collisionDistance = 15
    
    
    donut2.isAwake = true
    donut2.bTestForCollision = true
    donut2.linearX = math.random(3)+1
    donut2.angle = math.random(40)-300
    donut2.disableEnemyCollision = true
    
    mainScene.city.displayGroup:insert( donut2 )
    table.insert( objects, donut2 )
    
    donut3 = display.newImageRect( "images/tableDonut3.png", 16, 15 )		
    donut3.anchorX = 0.5
	donut3.anchorY = 0.5
    donut3.x = donut2.x + 15
    donut3.y = donut1.y
    donut3.collisionDistance = 15
    
    
    donut3.isAwake = true
    donut3.bTestForCollision = true
    donut3.linearX = math.random(3)+1
    donut3.angle = math.random(40)-300
    
    mainScene.city.displayGroup:insert( donut3 )
    table.insert( objects, donut3 )
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
    
    return objects
end

function tableObject:spawn(mainScene)
	local obstacleGroup = {}
	obstacleGroup.name = "table"
    obstacleGroup.bodies = tableObject:setup(mainScene)
	return obstacleGroup
end

return tableObject
