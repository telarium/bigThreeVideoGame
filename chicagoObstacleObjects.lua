local mainScene = nil
local prevTime = system.getTimer()
local spawnTime = system.getTimer()

local obstacleObjects = {
    activeObstacleGroups = {}
}

local function objectDiscard(obj)
    if( mainScene.obstacles.collidedObjects ) then
        for i, collided in ipairs( mainScene.obstacles.collidedObjects ) do
            if( obj == collided ) then
                table.remove( mainScene.obstacles.collidedObjects, i )
            end
        end
    end

    if( obj.dispose ) then
        obj.dispose = nil
    end
    if( obj.onInitialImpact ) then
        obj.onInitialImpact = nil
    end
    if( obj.onGroundImpact ) then
        obj:removeEventListener( "postCollision", obj.onGroundImpact )
        obj.onGroundImpact = nil
    end
    if( obj.applyLinearImpulse ) then
        physics.removeBody( obj )
    end
    if( obj.removeSelf ) then
        obj:removeSelf()
    end
    obj = nil
end

local function spawn(self,obj)

    if( not obj ) then
        local num = math.random(6)
        --print( num )
        --num = 8
        if( num==1 ) then
            table.insert(self.activeObstacleGroups, mainScene.obstacles.portaPotties:spawn(mainScene))
        elseif( num == 2 ) then
            table.insert(self.activeObstacleGroups, mainScene.obstacles.tableObject:spawn(mainScene))
        elseif( num == 3 ) then
            table.insert(self.activeObstacleGroups, mainScene.obstacles.dumpster:spawn(mainScene))
        elseif( num == 4 ) then
            if ( math.random( 2 ) == 1 ) then
                table.insert(self.activeObstacleGroups, mainScene.obstacles.elvis:spawn(mainScene))
            else
                table.insert(self.activeObstacleGroups, mainScene.obstacles.portaPotties:spawn(mainScene))
            end
        elseif( num == 6 ) then
            table.insert(self.activeObstacleGroups, mainScene.obstacles.crates:spawn(mainScene))
        else
            table.insert(self.activeObstacleGroups, mainScene.obstacles.trophy:spawn(mainScene))
        end
    else
        table.insert(self.activeObstacleGroups, obj:spawn(mainScene))
    end
    mainScene.groundSpawnTime = system.getTimer()
    
    local offsetX = 0
    local debugName = ""
    
    for i=1,table.getn( mainScene.obstacles.activeObstacleGroups ) do
        for q=1, table.getn( mainScene.obstacles.activeObstacleGroups[i].bodies ) do
            obj = mainScene.obstacles.activeObstacleGroups[i].bodies[q]
            if( obj.x ) then
             mainScene.city:setGroundSpawnCoordinate( obj.x + ( obj.width/2 ) + 30 )
           end
            
        end
    end
end


local function checkForDiscardedObject(self,obj,scene)
    if( not obj ) then
        return
    end
    -- Don't evluate this too soon after the objects have been collided with.
    if( obj.bCollidedWithPlayer and obj.timeOfCollision ) then
        if( system.getTimer() - obj.timeOfCollision < 2000 ) then
            return false
        end
    end
    
    -- See if the object has moved off screen. If it has, flag it to be discarded.
    local bDiscard = false
    if( obj.contentBounds ) then
    if( obj.contentBounds.xMax <= mainScene.leftEdge - 10 or ( obj.bCollidedWithPlayer and obj.contentBounds.xMin > mainScene.rightEdge ) ) then
        bDiscard = true
    end
    if( not bDiscard ) then
        if( obj.contentBounds.yMax < mainScene.topEdge or obj.contentBounds.yMin > mainScene.bottomEdge ) then
            bDiscard = true
        end
    end
    end
    
    -- If this object has been flagged to discard, remove it from the table and destroy the object.
    if( bDiscard or obj.forceDiscard or not obj.contentBounds ) then
        
        objectDiscard(obj)
        for i=1,table.getn( self.activeObstacleGroups ) do
            if( self.activeObstacleGroups[i] ) then
             for q=1, table.getn( self.activeObstacleGroups[i].bodies ) do
                if ( obj == self.activeObstacleGroups[i].bodies[q] ) then
                    table.remove( self.activeObstacleGroups[i].bodies, q )
                end
             end
             
             if( table.getn( self.activeObstacleGroups[i].bodies ) == 0 ) then
                self.activeObstacleGroups[i].bodies = nil
                self.activeObstacleGroups[i] = nil
                table.remove( self.activeObstacleGroups, i )

             end
             end
        end
        
        for i=1,table.getn( self.miscObstacles ) do
            if( obj == self.miscObstacles[i] ) then
                table.remove( self.miscObstacles, i )
            end
        end
        
        obj = nil
    else
        -- Evaluate if the object, after collision, has been settled for too long or is getting too close to the player.
        -- If so, remove it. Via magic.
        if( not obj.timeOfCollision ) then
            obj.timeOfCollision = -100
        end
        
        local bTooClose = false
        if( obj.timeOfCollision > 0 ) then
            if( system.getTimer() - obj.timeOfCollision > 500 ) then
                bTooClose = math.abs( obj.x - scene.player.avatar.x ) < 150
            end
        end
        
        if( bTooClose or ( system.getTimer() - obj.timeOfCollision > 1000 and obj.angularVelocity ) ) then
            -- See if the item has settled.
            if( bTooClose or ( math.abs( obj.angularVelocity ) <= 2 and obj.bCollidedWithPlayer ) ) then
                if( not obj.timeSettled ) then
                    -- Remember at what time the object was flagged as having been settled.
                    obj.timeSettled = system.getTimer()
               else
                    -- If the object has been settled for too long or is getting too close, remove it.
                    if( bTooClose or system.getTimer() - obj.timeSettled > 2200 ) then
                        obj.forceDiscard = true
                        if ( not obj.explosionScale ) then
                            obj.explosionScale = 1
                        end
                        scene:doExplosion(obj,obj.explosionScale)
                    end
               end
            end
        end
    end
end


function obstacleObjects:addMisc(obj,bCollided)
    if( bCollided ) then
        obj.bCollidedWithPlayer = true;
        obj.timeOfCollision = system.getTimer() 
    end
	table.insert( self.miscObstacles, obj )
end

-- Get all active objects.
-- bAlive means the object is ready for collisions (not already colliding with player, etc)
-- Otherwise, ALL objects are returned
function obstacleObjects:getActive(bAlive)
    local active = {}
    for i=1,table.getn( mainScene.obstacles.activeObstacleGroups ) do
        for q=1, table.getn( mainScene.obstacles.activeObstacleGroups[i].bodies ) do
            obj = mainScene.obstacles.activeObstacleGroups[i].bodies[q]
            if( bAlive ) then
                if( not obj.bCollidedWithPlayer and obj.bTestForCollision ) then
                    table.insert( active, obj )
                    obj.group = mainScene.obstacles.activeObstacleGroups[i]
                end
            else
                table.insert( active, obj )
                obj.group = mainScene.obstacles.activeObstacleGroups[i]
            end
        end
    end
    return active
end


function obstacleObjects:doCollision(group)
    local obj = nil;
    mainScene:setPhysics( true )
    for i=1, table.getn( group.bodies ) do
         obj = group.bodies[i]
         if( not obj.bCollidedWithPlayer ) then
            
            if( obj.onInitialImpact and not group.bDidInitialImpact ) then
				group.bDidInitialImpact = true
				mainScene:addPoints(200)
                obj:onInitialImpact()
            end
            obj.bCollidedWithPlayer = true;
            obj.timeOfCollision = system.getTimer()
            if( not mainScene.obstacles.collidedObjects ) then
                mainScene.obstacles.collidedObjects = {}
            end
            
            table.insert( mainScene.obstacles.collidedObjects, obj )
            local linearX = nil
            local angle = nil
            if( not obj.linearX ) then
                linearX = math.random(3)+7
            else
                linearX = obj.linearX
            end
            if( not obj.angle ) then
                angle = math.random(40)+100
            else
                angle = obj.angle
            end
            if( obj.applyLinearImpulse ) then
                obj:applyLinearImpulse( linearX,3, obj.x, obj.y )
                obj:applyAngularImpulse( angle )
            end
            
            if( obj.xChoke and obj.yChoke ) then
                obj.xChoke = -10
                obj.yChoke = -10
            end
            if( obj.collisionDistance ) then
                obj.collisionDistance = obj.collisionDistance * 1.5
            end
            
            if( obj.onGroundImpact ) then
                obj:addEventListener( "postCollision", obj.onGroundImpact )
            end
        end
    end
end


-- Return all objects that were knocked over by the player.
function obstacleObjects:getCollided()
    if( not mainScene.obstacles.collidedObjects ) then
        mainScene.obstacles.collidedObjects = {}
    end
    return mainScene.obstacles.collidedObjects
end

function obstacleObjects:spawn(obstacle)
    if ( mainScene.bSmoggy and math.random(3)==3 ) then
        return
    end
    
    spawn(self,obstacle)
end

local function collisionCheck(event)
    local self = event.source.params.myself
    if( mainScene and not mainScene.bGameOver ) then
        prevTime = system.getTimer()
        -- Only check collisions of player and obstacle if the object is "alive"
        local aliveObjects = mainScene.obstacles.getActive(true)
        for i=1,table.getn( aliveObjects ) do
            if( aliveObjects[i].doObstacleCollisionCheck and  mainScene:checkCollision(mainScene.player.avatar, aliveObjects[i] ) ) then
                if( mainScene.player.bDashing or mainScene.player.bDashingResidual ) then
                    local delayFunc = function()
                        self:doCollision(aliveObjects[i].group)
                    end
                    local myTimer = timer.performWithDelay( 50, delayFunc )
                elseif( not aliveObjects[i].group.bCollidedWithPlayer and not aliveObjects[i].bCollidedWithPlayer  ) then
                    aliveObjects[i].group.bCollidedWithPlayer = true
                    mainScene.player:doObstacleCollision( aliveObjects[i].group )
                end
                --break
            end
        end
    end
end

function obstacleObjects:update()
    local obj = nil
    
    
    
    -- Check to see if object has moved off screen. If so, destroy it.
    for i, obj in ipairs( mainScene.obstacles.getActive(false) ) do
        if( obj.update ) then
            obj.update()
        end
        checkForDiscardedObject( self,obj, mainScene)
    end
end

local function discardedUpdate(event)
    local self = event.source.params.myself
    if( not mainScene or mainScene.bGameOver ) then
        return
    end
    local allObjects = mainScene.obstacles.getActive(false)
    for i=1,table.getn( mainScene.obstacles.getActive(false) ) do
        checkForDiscardedObject( self,allObjects[i], mainScene)
    end

    for i=1,table.getn( mainScene.obstacles.miscObstacles ) do
        checkForDiscardedObject( self,mainScene.obstacles.miscObstacles[i], mainScene)
    end

	if( mainScene.obstacles.bDisableSpawn or mainScene.specialPowers:checkSpawn() ) then
		return
	end

	
	if( table.getn( obstacleObjects:getActive(true) ) <= 0 and  table.getn( obstacleObjects:getCollided() ) <= 1 ) then
		if( not spawnTime ) then
			spawnTime = system.getTimer() + math.random( 1500 ) + 2000
		end
		if( system.getTimer() > spawnTime ) then
			spawnTime = nil
			local function goObject()
                if( mainScene.obstacles.bDisableSpawn ) then
                    return false
                end

                spawn(self)
            end
            
            local delay = 0	
        	-- If an item is spawning on the ground, build in a potential delay so two items aren't on the ground at the same time.
        	if( not mainScene.groundSpawnTime ) then
        	       mainScene.groundSpawnTime = 0
        	end
        	if( ( system.getTimer() + delay ) <= ( mainScene.groundSpawnTime + 500 ) ) then
        	     delay = delay + 500
        	end

        	mainScene.groundSpawnTime = system.getTimer() + delay
        
        	timer.performWithDelay( delay, goObject )
         end
	end
end

function GetActiveObjects()
    if( not mainScene ) then
        return nil
    end
    --return table.getn( mainScene.obstacles.activeObstacleGroups )
    return table.getn( mainScene.obstacles.getActive(false) )
end

function obstacleObjects:init(scene)
	self.activeObstacleGroups = {}
    self.miscObstacles = {}
    mainScene = scene
    mainScene.obstacles.crates = require( "chicagoCrates" )
    mainScene.obstacles.portaPotties = require( "chicagoPortaPotties" )
    mainScene.obstacles.tableObject = require( "chicagoTable" )
    mainScene.obstacles.trophy = require( "chicagoTrophy" )
    mainScene.obstacles.dumpster = require( "chicagoDumpster" )
    mainScene.obstacles.randyRanch = require( "chicagoRandyRanch" )
    mainScene.obstacles.elvis = require( "chicagoElvis" )
    mainScene.obstacles.cutlass = require( "chicagoCutlass" )
    mainScene.obstacles.bDisableSpawn = true
    
    self.updateTimer = timer.performWithDelay( 45, collisionCheck, -1 )
    self.updateTimer.params = { myself = self }
    self.discardTimer = timer.performWithDelay( 1000, discardedUpdate, -1 )
    self.discardTimer.params = { myself = self }
   
end


function obstacleObjects:destroy()
    timer.cancel( self.updateTimer )
    timer.cancel( self.discardTimer )

    local allObjects = mainScene.obstacles.getActive(false)
    for i=1,table.getn( allObjects ) do
        objectDiscard( allObjects[i] )
    end
    
    for i=1,table.getn( mainScene.obstacles.miscObstacles ) do
        objectDiscard( mainScene.obstacles.miscObstacles[i] )
    end
    
    
    for i=1,table.getn( mainScene.obstacles.activeObstacleGroups ) do
        if ( mainScene.obstacles.activeObstacleGroups[i].dispose ) then
            mainScene.obstacles.activeObstacleGroups[i].dispose:dispose()
        end
        for q=1, table.getn( mainScene.obstacles.activeObstacleGroups[i].bodies ) do
            obj = mainScene.obstacles.activeObstacleGroups[i].bodies[q]
            objectDiscard( obj )
        end
    end
    
    mainScene.obstacles.collidedObjects = nil

	spawnTime = nil
    mainScene.obstacles.activeObstacleGroups = {}
    mainScene.obstacles.miscObstacles = nil
	mainScene.obstacles = nil
	mainScene = nil
end

return obstacleObjects;