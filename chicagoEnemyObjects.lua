local mainScene = nil
local prevTime = system.getTimer()

local enemyObjects = {
    activeEnemies = {}
}

local function enemyDispose(enemy,bDestroyAll)
    if ( enemy.dispose ) then
        enemy:dispose(bDestroyAll)
        enemy.dispose = nil
    end
    --if( enemy.update ) then
     --   enemy.update = nil
    --end
    --if( enemy.onPlayerCollision ) then
    --    enemy.onPlayerCollision = nil
    --end
    --if( enemy.applyLinearImpulse ) then
    --    physics.removeBody( enemy )
    --end
    if( not enemy.bDoNotDestroy ) then
        enemy:removeSelf()
    else
        enemy.isVisible = false
    end
    enemy = nil
end

local function doDamageSplash(self,enemy,bCentered)
    local xMin,yMin = mainScene.city.displayGroup:contentToLocal( enemy.contentBounds.xMin, enemy.contentBounds.yMin )
    local xMax,yMax = mainScene.city.displayGroup:contentToLocal( enemy.contentBounds.xMax, enemy.contentBounds.yMax )
    
    local x,y = xMin+((xMax-xMin)/2), yMin+((yMax-yMin)/2)
    
    if( not bCentered ) then
         mainScene:showDamageHit( x - ((enemy.width/4)), y, true )
    else
        mainScene:showDamageHit( x, y, true )
    end
end

local function checkForDiscardedObjects(self)
     for i, obj in ipairs( self.activeEnemies ) do
        
        local bDiscard = false

        if( not obj ) then
            bDiscard = true
        else
            if( obj.contentBounds.xMax < mainScene.leftEdge and not obj.bDisableCulling ) then
                bDiscard = true
            end
            if( not obj.health ) then
                obj.health = 0
                obj.health = 0
            end
            if( not bDiscard and obj.health <= 0 ) then
                bDiscard = true
                if( not obj.explosionScale ) then
                    obj.explosionScale = 1
                end
				mainScene:doExplosion( obj, obj.explosionScale)
             end
        end
        
        if( bDiscard ) then
            table.remove( self.activeEnemies, i )
            if ( obj ) then
                enemyDispose(obj)
                break
            end
        end
   end
end

function enemyObjects:doWeaponHit( weapon, enemy )
    enemy.health = enemy.health - 1
    if( enemy.health > 0 ) then
        doDamageSplash(self, enemy, false )
    else
        if( enemy.onDeath ) then
            enemy.onDeath()
        end
        doDamageSplash(self, enemy, true )
        mainScene:doExplosion(enemy, enemy.explosionScale )
        mainScene:addPoints(100)
    end
end

function enemyObjects:getActive()
    if( not mainScene.enemies.activeEnemies ) then
        mainScene.enemies.activeEnemies = {}
    end
    return mainScene.enemies.activeEnemies
end


function GetActiveEnemies()
    if( not mainScene ) then
        return nil
    end
    return table.getn( mainScene.enemies.activeEnemies )
end

function enemyObjects:add( enemy )
	    table.insert( self.activeEnemies, enemy )
	    if( enemy.bGroundSpawn ) then
	       mainScene.city:setGroundSpawnCoordinate( enemy.x + (enemy.width/2) + 50, enemy.name )
	    end
end

function enemyObjects:spawn( enemy, randomDelay, minDelay )
    if( mainScene.specialPowers:checkSpawn() ) then
        return
    end
    
    if( self.bDisable and not enemy ) then
        return
    end

	if( not randomDelay ) then
		randomDelay = 1
	end
	if( not minDelay ) then
		minDelay = 0
	end
	local obj = nil
	if ( not enemy ) then
		local candidates = {}
		for i, candidate in ipairs( mainScene.enemies.allEnemies ) do
			if(candidate.bEnableAutoSpawn ) then
				table.insert( candidates, candidate )
			end
		end
        if ( table.getn( candidates ) < 1 ) then
            return
        end
		enemy = candidates[ math.random( table.getn( candidates ) ) ]
	end
	
	if( not enemy ) then
		return
	end
	
	local function goEnemy()
        if( not mainScene or mainScene.bGameOver ) then
            return
        end
		obj = enemy:spawn(mainScene)
		
		if( obj ) then
            obj.isVisible = true
            if( table.getn( obj ) > 1 ) then
                for i, item in ipairs( obj ) do
                	if( item.x ) then
                    	enemyObjects:add( item )

                    end
                end
            else
            	if( not obj.x ) then
            		 enemyObjects:add( obj[1] )

                else
                	enemyObjects:add( obj )

                end
            end
		end
	end
	
	local delay = math.random(randomDelay)+minDelay
	
	-- If an item is spawning on the ground, build in a potential delay so two items aren't on the ground at the same time.
	if( enemy.bGroundSpawn ) then
	   if( not mainScene.groundSpawnTime ) then
	       mainScene.groundSpawnTime = 0
	   end
	   if( ( system.getTimer() + delay ) <= ( mainScene.groundSpawnTime + 500 ) ) then
	       delay = delay + 500
	   end
	end

	mainScene.groundSpawnTime = system.getTimer() + delay

	timer.performWithDelay( delay, goEnemy )
end

local function collisionCheck(event)
   local self = event.source.params.myself
   
   if( not mainScene or mainScene.bGameOver ) then
    return
  end
   
   if( not mainScene.enemies.counter ) then
    mainScene.enemies.counter = 0
   end
   
   -- Only check collisions of player and obstacle if the object is "alive"
    for i, enemy in ipairs( mainScene.enemies.activeEnemies ) do
        if( not enemy.health ) then
            enemy.health = 1
        end
        if( mainScene.enemies.counter > 3 ) then
           mainScene.enemies.counter = 0

            if( enemy.contentBounds and not enemy.bObstacleImmunity and enemy.health > 0 and mainScene:checkCollision(mainScene.player.avatar, enemy ) ) then
                if( not enemy.bNoDamage ) then
                    mainScene.player:doEnemyCollision( enemy )  
                end
                if( enemy.onPlayerCollision and not enemy.bDidCollisionCallback and ( enemy.bNoDamage or mainScene.player:isInvincible() ) ) then
                    enemy.bDidCollisionCallback = true
                    enemy:onPlayerCollision()
                end
                if( enemy.health <= 0 ) then
                    break
                end
            end
       else
        mainScene.enemies.counter = mainScene.enemies.counter + 1
       end
           -- See if the enemies are colliding with any obstacle objects that have been knocked over by the player.)
           for z, obstacle in ipairs( mainScene.obstacles.collidedObjects ) do
                if( enemy.health > 0 and not enemy.bImmortal and not enemy.bNoDamage and not enemy.bObstacleImmunity and not obstacle.disableEnemyCollision and mainScene:checkCollision( enemy, obstacle ) and enemy.contentBounds.xMin < mainScene.rightEdge - 40 ) then
                    doDamageSplash(self, enemy, true )
                    mainScene:doExplosion(enemy, enemy.explosionScale )
                    mainScene:addPoints(350)
                    enemy.health = 0
                end
            end

		
		
    end
end


function enemyObjects:update()
   mainScene.enemies.jerkoffHands:update(mainScene)
   
   if( not mainScene.enemies.sanityCheckTime ) then
     
        mainScene.enemies.sanityCheckTime = system.getTimer()
   end

   
   if( system.getTimer() - mainScene.enemies.sanityCheckTime > 7000 and not mainScene.bVinceAlive ) then
        mainScene.enemies.sanityCheckTime = system.getTimer()
    end
             
     for i, enemy in ipairs( mainScene.enemies.activeEnemies ) do
     
        if( enemy and enemy.x and mainScene.player.avatar.x ) then
            if( enemy.update ) then
			enemy:update()
		  end
		  if( not enemy.health ) then
		      enemy.health = 0
		  end
		  
		  if( enemy.bDisableCulling and enemy.health <1 ) then
		      return
		  end
        if( enemy.health < 1 or not enemy.removeSelf ) then
            if( enemy.removeSelf ) then
                enemy:removeSelf()
            end
            table.remove( mainScene.enemies.activeEnemies, i )
            enemy = nil
          
       end
   end
   end
    checkForDiscardedObjects(self)
end



function enemyObjects:init(scene)
	mainScene = scene
	self.activeEnemies = {}
	self.allEnemies = {}
    mainScene.enemies.mudSharks = require( "chicagoMudSharks" )
	table.insert( self.allEnemies, mainScene.enemies.mudSharks )
    mainScene.enemies.blackHawks = require( "chicagoBlackHawks" )
	table.insert( self.allEnemies, mainScene.enemies.blackHawks )
    mainScene.enemies.jerkoffHands = require( "chicagoJerkoffHand" )
	table.insert( self.allEnemies, mainScene.enemies.jerkoffHands )
    mainScene.enemies.redBats = require( "chicagoRedBats" )
	table.insert( self.allEnemies, mainScene.enemies.redBats )
	mainScene.enemies.toaster = require( "chicagoToaster" )
	table.insert( self.allEnemies, mainScene.enemies.toaster )
    mainScene.enemies.basketball = require( "chicagoBasketballs" )
	table.insert( self.allEnemies, mainScene.enemies.basketball )
    --mainScene.enemies.randyRanch = require( "chicagoRandyRanch" )
	--table.insert( self.allEnemies, mainScene.enemies.randyRanch )
    mainScene.enemies.vince = require( "chicagoVince" )
	table.insert( self.allEnemies, mainScene.enemies.vince )
	
	self.updateTimer = timer.performWithDelay( 21, collisionCheck, -1 )
    self.updateTimer.params = { myself = self }
end

function enemyObjects:destroy()
    for i, enemy in ipairs( enemyObjects:getActive() ) do
        enemyDispose(enemy,true)
    end
    timer.cancel( self.updateTimer )
    
    mainScene.bSmoggy = false
    mainScene.bRemoveSmog = false
    mainScene.bVinceAlive = nil
    
    mainScene.enemies.activeEnemies = {}
	mainScene.enemies.allEnemies = nil
	mainScene.enemies = nil
	
	mainScene = nil
	
end

return enemyObjects;