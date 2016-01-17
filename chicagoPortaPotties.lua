local portaPotties = {
    image="images/portapotty",
    imageHeight=53,
    imageWidth=95,
    bodyShape = {   -26.5, 47.5  ,  -26.5, -33.5  ,  -12.5, -45.5  ,  13.5, -45.5  ,  26.5, -32.5  ,  26.5, 47.5  }
}

function portaPotties:doVerticalStack(mainScene)
    local potties = {}
    local prevObject = nil
    local num = math.random(3)
    
    if( mainScene.score < 5000 ) then
        num = num + 1
    end
    
    if( num > 3 ) then
        num = 3
    end
    
    while( num > 0 ) do
        num = num - 1
        local myImage = self.image .. tostring( math.random(2) ) .. ".png"
        local body = display.newImageRect( myImage, self.imageHeight, self.imageWidth )
		body.anchorX=0.5;body.anchorY=0.5
	    
		if( not prevObject ) then
		  body.y = mainScene.groundY - body.height/2 + 3
		else
		  body.y = prevObject.y - prevObject.height  + 3
		end
		prevObject = body
		local x = mainScene.city:getGroundSpawnCoordinate()
		body.x = x + body.width/2
		body.doObstacleCollisionCheck = true
		table.insert( potties, body )
    end
    
    return potties
end

function portaPotties:doHorizontalStack(mainScene)
    local potties = {}
    local prevObject = nil
    local num = math.random(3)+2

    if( mainScene.score < 5000 ) then
        num = 4 + math.random(2)
    end
    
    if( num > 5 ) then
        num = 5
    end
    
    while( num > 0 ) do
        num = num - 1
        local myImage = self.image .. tostring( math.random(2) ) .. ".png"
        local body = display.newImageRect( myImage, self.imageHeight, self.imageWidth )		               
        body.anchorX=0.5;body.anchorY=0.5
		body.y = mainScene.groundY - body.height/2 + 3	
		if( not prevObject ) then
		  body.doObstacleCollisionCheck = true
		  local x = mainScene.city:getGroundSpawnCoordinate()
		  body.x = x + body.width/2
		else
		  body.x = prevObject.x + prevObject.width + math.random(10)+3
		  
		end
		prevObject = body
		
		--if( num <= 3 ) then
		  body.doObstacleCollisionCheck = true
		--end

		table.insert( potties, body )
    end
    
    return potties
end

function portaPotties:doCastleStack(mainScene)
    local potties = {}
    local prevObject = nil
    local num = 4
    while( num > 0 ) do
        num = num - 1
        local myImage = self.image .. tostring( math.random(2) ) .. ".png"
        local body = display.newImageRect( myImage, self.imageHeight, self.imageWidth )
		body.anchorX=0.5;body.anchorY=0.5
		body.y = mainScene.groundY - body.height/2		
		if( not prevObject ) then
		  local x = mainScene.city:getGroundSpawnCoordinate()
		  body.x = x + body.width/2
		  body.doObstacleCollisionCheck = true
		else
		  body.x = prevObject.x + prevObject.width + 1
		  
		end
		prevObject = body
		
		table.insert( potties, body )
    end
    local num = 3
    y = prevObject.y - prevObject.height
    prevObject = nil
    while( num > 0 ) do
        
        num = num - 1
        local myImage = self.image .. tostring( math.random(2) ) .. ".png"
        local body = display.newImageRect( myImage, self.imageHeight, self.imageWidth )
		body.anchorX=0.5;body.anchorY=0.5
		body.y = y	
		if( not prevObject ) then
		  local x = mainScene.city:getGroundSpawnCoordinate()
		  body.x = x + body.width
		else
		  body.x = prevObject.x + prevObject.width + 1
		  
		end
		prevObject = body
		if( num == 2 ) then
            body.doObstacleCollisionCheck = true
        end
		
		table.insert( potties, body )
    end

    y = prevObject.y - prevObject.height
    local myImage = self.image .. tostring( math.random(2) ) .. ".png"
    local body = display.newImageRect( myImage, self.imageHeight, self.imageWidth )     
    body.anchorX=0.5;body.anchorY=0.5
    body.y = y
    local x = mainScene.city:getGroundSpawnCoordinate()
    body.x = x + body.width * 2
    body.doObstacleCollisionCheck = true
    table.insert( potties, body )

    
    return potties
end

function portaPotties:spawn(mainScene)
	local obstacleGroup = {}
	obstacleGroup.name = "portaPotties"
	obstacleGroup.bodies = {}
	local type = math.random(9)
	local potties = nil
        
    if( mainScene.data.highScore < 2000 ) then
        type = math.random( 3 ) + 7
    end
    
	if( type <= 4 ) then
        potties = portaPotties:doHorizontalStack(mainScene)
	  
	elseif( type <= 8 ) then
         potties = portaPotties:doVerticalStack(mainScene)
	   
    else
        potties = portaPotties:doCastleStack(mainScene)
    end
	for i, body in pairs(potties) do
		body.isAwake = false
		
		mainScene.city.displayGroup:insert( body )
	
		table.insert( obstacleGroup.bodies, body )
		body.isAwake = true
		body.bTestForCollision = true
		body.xChoke = -5
		body.yChoke = -10
        body.linearX = math.random(100) + 500
        body.angle = math.random( 30 ) + 45
        
        --if( math.mod(i, 2) == 0 and table.getn( mainScene.enemies.activeEnemies ) > 5 ) then
        --    body.disableEnemyCollision = true
        --end
        body.collisionDistance = 50
        
        if( not self.initialSound ) then 
            self.initialSound = mainScene.sound:load( "impact2.wav" )
            self.sounds = { mainScene.sound:load( "impact3.wav" ), mainScene.sound:load( "impact4.wav" ) }
        end
        body.explosionScale = 2
        body.onInitialImpact = function()
             mainScene.sound:play( self.initialSound, true )
			 for i, structure in pairs(potties) do
				if( structure.x ) then
					physics.addBody( structure, { density=2, friction=0.14, bounce=0.4, shape= self.bodyShape  } )
			    end
			 end
		end
        
        body.onGroundImpact = function(event)
        if( event.other == mainScene.ground and event.force >= 0.5 and event.force < 2 and body.contentBounds.xMin < mainScene.rightEdge + 30 ) then
            mainScene.sound:play( self.sounds[ math.random( table.getn( self.sounds ) ) ] )
        end
    end


	end
	return obstacleGroup
end

return portaPotties