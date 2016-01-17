local crates = {
    image="images/crate",
    imageHeight=50,
    imageWidth=50,
}

local function getCrateNum()
    if( math.random(2) == 2 ) then
        return math.random(6)
    else
        return 1
    end
end

function crates:doVerticalStack(mainScene, offset)
    if( not offset ) then
        offset = 0
    end
    local crates = {}
    local prevObject = nil
    local num = math.random(4) + 1
    
    if( mainScene.data.highScore < 2000 or not storyboard.state.bTutorialRequired ) then
        num = num + 2
    end

    
    while( num > 0 ) do
        num = num - 1
        local myImage = self.image .. tostring( getCrateNum() ) .. ".gif"
        local body = display.newImageRect( myImage, self.imageHeight, self.imageWidth )
		body.anchorX=0.5;body.anchorY=0.5
	    body.doObstacleCollisionCheck = true
	    
		if( not prevObject ) then
		  body.y = mainScene.groundY - body.height/2 + 3
		else
		  body.y = prevObject.y - prevObject.height  + 3
		end
		prevObject = body
		local x = mainScene.city:getGroundSpawnCoordinate() + offset
		local num = math.random(2)
		if( num == 2 ) then
		  num = -1
		end
		body.x = x + body.width/2 + (math.random(8)*num )
		table.insert( crates, body )
    end
    
    return crates
end

function crates:doHorizontalStack(mainScene)
    local crates = {}
    local prevObject = nil
    local num = math.random(3)+2
    if( mainScene.data.highScore < 2000 ) then
        num = num + 2
    end
    while( num > 0 ) do
        num = num - 1
        local myImage = self.image .. tostring( getCrateNum() ) .. ".gif"
        local body = display.newImageRect( myImage, self.imageHeight, self.imageWidth )	
        --if( num <=2 ) then
            body.doObstacleCollisionCheck = true
        --end	               
        body.anchorX=0.5;body.anchorY=0.5
		body.y = mainScene.groundY - body.height/2 + 3	
		if( not prevObject ) then
		  local x = mainScene.city:getGroundSpawnCoordinate()
		  body.x = x + body.width/2
		else
		  body.x = prevObject.x + prevObject.width + math.random(10)+3
		  
		end
		prevObject = body
		
		table.insert( crates, body )
    end
    
    return crates
end

function crates:doCastleStack(mainScene)
    local crates = {}
    local prevObject = nil
    local num = 4
    while( num > 0 ) do
        num = num - 1
        local myImage = self.image .. tostring( getCrateNum() ) .. ".gif"
        local body = display.newImageRect( myImage, self.imageHeight, self.imageWidth )
		body.anchorX=0.5;body.anchorY=0.5
		body.y = mainScene.groundY - body.height/2		
		if( not prevObject ) then
		  body.doObstacleCollisionCheck = true
		  local x = mainScene.city:getGroundSpawnCoordinate()
		  body.x = x + body.width/2
		else
		  body.x = prevObject.x + prevObject.width + 1
		  
		end
		prevObject = body
		
		table.insert( crates, body )
    end
    local num = 3
    y = prevObject.y - prevObject.height
    prevObject = nil
    while( num > 0 ) do
        num = num - 1
        local myImage = self.image .. tostring( getCrateNum() ) .. ".gif"
        local body = display.newImageRect( myImage, self.imageHeight, self.imageWidth )
        if( num == 2 ) then
            body.doObstacleCollisionCheck = true
        end
		body.anchorX=0.5;body.anchorY=0.5
		body.y = y	
		if( not prevObject ) then
		  local x = mainScene.city:getGroundSpawnCoordinate()
		  body.x = x + body.width
		else
		  body.x = prevObject.x + prevObject.width + 1
		  
		end
		prevObject = body
		
		table.insert( crates, body )
    end

    y = prevObject.y - prevObject.height
    local myImage = self.image .. tostring( getCrateNum() ) .. ".gif"
    local body = display.newImageRect( myImage, self.imageHeight, self.imageWidth )     
    body.anchorX=0.5;body.anchorY=0.5
    body.y = y
    local x = mainScene.city:getGroundSpawnCoordinate()
    body.x = x + body.width * 2
    body.doObstacleCollisionCheck = true
    table.insert( crates, body )

    
    return crates
end

function crates:spawn(mainScene)
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )

	local obstacleGroup = {}
	obstacleGroup.name = "crates"
	obstacleGroup.bodies = {}
	local type = math.random(9)
    
    if( mainScene.data.highScore < 2000 ) then
        type = math.random( 2 ) + 7
    end
    
	local crate = nil
	if( type <= 4 ) then
	   crate = crates:doHorizontalStack(mainScene)
	elseif( type <= 8 ) then
	   crate = crates:doVerticalStack(mainScene)
	   if( math.random(2)==1 and not mainScene.bSmoggy and table.getn( mainScene.enemies.activeEnemies ) < 10 ) then
	       local moreCrates = crates:doVerticalStack(mainScene, 60 )
	       for i, newCrate in pairs(moreCrates) do
	           table.insert( crate, newCrate )
	       end
	       if( math.random(3)==1 ) then
	           local moreCrates = crates:doVerticalStack(mainScene, 120 )
	           for i, newCrate in pairs(moreCrates) do
	                table.insert( crate, newCrate )
	           end
	       end
	   end
    else
        crate = crates:doCastleStack(mainScene)
    end
	for i, body in pairs(crate) do
		body.isAwake = false
        body.collisionDistance = 50
		
		mainScene.city.displayGroup:insert( body )
	
		table.insert( obstacleGroup.bodies, body )
		body.isAwake = true
		body.bTestForCollision = true
		body.xChoke = 1
		body.yChoke = 1
        body.linearX = math.random(150) + 100
        body.angle = math.random( 70 ) + 45
                
        if( math.mod(i, 2) == 0 and table.getn( mainScene.enemies.activeEnemies ) > 5) then
            body.disableEnemyCollision = true
        else
            body.collisionDistance = 50
        end
        
        if( not self.initialSound ) then 
            self.initialSound = mainScene.sound:load( "impact10.wav" )
            self.sounds = { mainScene.sound:load( "impact11.wav" ) }
        end
        body.explosionScale = 2
        body.onInitialImpact = function()
             mainScene.sound:play( self.initialSound, true )
			 for i, structure in pairs(crate) do
				if( structure.x ) then
                    local d = 1.2
                    
                    
                    if( i == 1 ) then
                        structure.y = structure.y - 15
                        structure.rotation = structure.rotation + 10
                        d = 1.8
                        structure.angle = 20 + math.random(5)
                        structure.linearX = 400
                    else
                        structure.rotation = math.random( 10 )
                        structure.y = structure.y - math.random(15) + 5
                    end
					physics.addBody( structure, { density=2, friction=0.14, bounce=0.4 } )
			    end
			 end
		end
        
        body.onGroundImpact = function(event)
        if( event.other == mainScene.ground and event.force >= 1.5 and event.force < 4 and body.contentBounds.xMin < mainScene.rightEdge + 30 ) then
            mainScene.sound:play( self.sounds[ math.random( table.getn( self.sounds ) ) ] )
        end
    end


	end
	display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
	return obstacleGroup
end

return crates