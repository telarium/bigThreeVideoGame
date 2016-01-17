local toasters = {

}

local function doQuadraticBezierCurve(point1, point2, point3, t)
    local a = (1.0 - t) * (1.0 - t);
    local b = 2.0 * t * (1.0 - t);
    local c = t * t;
    
    local x = math.floor( a * point1.x + b * point2.x + c * point3.x )
    local y = math.floor( a * point1.y + b * point2.y + c * point3.y )
		
    return x,y
end

local function update(toaster, mainScene)
	if( not toaster.bRemove and toaster.health > 0 ) then
		toaster.t = toaster.t+ (0.0175 * mainScene.timeScale )
		if ( toaster.t > 1 ) then
			toaster.t = 1
		end
		toaster.x, toaster.y = doQuadraticBezierCurve( toaster.origin,toaster.midPoint, toaster.destination, toaster.t )
	end	
end


function toasters:spawn(scene)
	if ( not self.sound ) then
		self.sound1 = scene.sound:loadEnemyImpactSound( "toaster1.wav" )
		self.sound2 = scene.sound:loadEnemyImpactSound( "toaster2.wav" )
		self.sound3 = scene.sound:loadEnemyImpactSound( "toaster3.wav" )
	end

    mainScene = scene
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )

    local toaster = display.newImageRect( "images/toaster.png", 31, 30 )
    local hat = display.newImageRect( "images/toasterHat.png", 21, 18 )
    
    toaster.hat = hat
    
    toaster.collisionDistance = 25
    --toaster.bPerciseCollisionDetection = true
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
	
	local x = mainScene.city:getGroundSpawnCoordinate()
	
	toaster.x = x + toaster.width
	toaster.y = mainScene.groundY - 2
	toaster.anchorX=0.5;toaster.anchorY=1
	mainScene.city.displayGroup:insert( toaster )
	mainScene.city.displayGroup:insert( toaster.hat )
	
	local hatUpdate = function()
	local bRemoveHat = false

	   if( hat.x ) then
	       if( toaster.health <= 0 and not hat.bCollided ) then
				local num = math.random(3)
				if( num == 1 ) then
					mainScene.sound:playEnemyImpactSound( self.sound1 )
				elseif( num == 2 ) then
					mainScene.sound:playEnemyImpactSound( self.sound2 )
				else
					mainScene.sound:playEnemyImpactSound( self.sound3 )
				end
		   
	           hat.bCollided = true
	           local d = math.random(20)*.1+1.5
               mainScene:setPhysics( true )
	           physics.addBody( hat, { density=d, friction=0.2, bounce=0.3, shape= self.bodyShape  } )
	           local lx = 0
	           local ly = 1 - (math.random(5) )
	           
	           if( mainScene.player.bDashing ) then
	               lx = 10
	               ly = 5
	           end
	           if( hat.applyLinearImpulse ) then
                   hat:applyLinearImpulse( lx,ly, hat.x+20, hat.y )
                   hat:applyAngularImpulse( math.random(70)+70 )
               end
               hat.explosionScale = 0.2
               mainScene.obstacles:addMisc(hat,true)
	       end
	   
           if( not mainScene ) then
            hat:removeSelf()
            else
    	   if( hat.contentBounds.xMax < mainScene.leftEdge and not hat.bCollided ) then
    	       hat:removeSelf()
    	       bRemoveHat = true
    	   end
           end
       else
           bRemoveHat = true
       end
	   
	   if( bRemoveHat ) then
           timer.cancel( hat.timer )
           hat = nil
	   end
	end
	hat.timer = timer.performWithDelay( 20, hatUpdate, 0 )
	
	--toaster.t = 0
	--toaster.origin = {x=toaster.x,y=toaster.y}
	--toaster.destination = {x=destx,y=toaster.y}
	--toaster.midPoint = {x=toaster.x - ((toaster.x - destx )/2),y=50}
	
		
	toaster.update = function()
	
	
		--update(toaster, mainScene)
	end
	
	toaster.bGroundSpawn = true
	toaster.health = 1
    toaster.xChoke = -20
    toaster.yChoke = -50
    toaster.explosionScale = 1
	
	toaster.hat.x = toaster.x - 8
	toaster.hat.y = toaster.y - 33
    toaster.name = "toaster"


    return toaster
end

return toasters
