local blackHawks = {
    
}

local function doQuadraticBezierCurve(point1, point2, point3, t)
    local a = (1.0 - t) * (1.0 - t);
    local b = 2.0 * t * (1.0 - t);
    local c = t * t;
    
    local x = math.floor( a * point1.x + b * point2.x + c * point3.x )
    local y = math.floor( a * point1.y + b * point2.y + c * point3.y )
		
    return x,y
end

local function update(hawk, mainScene)
	if( not hawk.bRemove and hawk.health > 0 ) then
		hawk.t = hawk.t+ ( (0.0175 * mainScene.timeScale ) * ( 60 / display.fps ) )
		if ( hawk.t > 1 ) then
			hawk.t = 1
		end
		hawk.x, hawk.y = doQuadraticBezierCurve( hawk.origin,hawk.midPoint, hawk.destination, hawk.t )
	end	
end


function blackHawks:spawn(scene)
    mainScene = scene
    
    if( not self.hawkSound ) then
        local dispose = function()
            audio.dispose( self.hawkSound )
            self.hawkSound = nil
        end
    
        self.hawkSound = scene.sound:loadDamageSound( "hawk.wav" )
        mainScene.sound:playDamageSound( self.hawkSound )
        
        timer.performWithDelay( 30000, dispose, 1 )
    end
    
    if( not self.voiceSound ) then
        self.voiceSound = scene.sound:loadVoice( "voice-" .. mainScene:getSelectedCharacter() .. "BlackHawk.wav" )
        scene.sound:playVoice( self.voiceSound, 0.75 )
    end
    
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )

    local blackHawksheet = graphics.newImageSheet( "images/blackHawkAnim.png", { width=82, height=54, numFrames=8 } )
    
    local animTime = 600 + math.random( 100 )
    
    local blackHawk = display.newSprite( blackHawksheet, {{ name = "loop", start=1, count=8, time=animTime, loopCount=0 }} )
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
	
	local x,y = mainScene.city.displayGroup:contentToLocal( mainScene.rightEdge, mainScene.foldY )
	
	blackHawk.x = x + blackHawk.width
	blackHawk.y = mainScene.groundY - ( math.random( 20 ) + 200 )
	mainScene.city.displayGroup:insert( blackHawk )
	blackHawk:setSequence( "loop" )
	blackHawk:play()
   --blackHawk.bPerciseCollisionDetection = true
   blackHawk.collisionDistance = 50
	
	local speed = mainScene.city.curSpeed
	if( speed < mainScene.city.defaultSpeed ) then
	   speed = mainScene.city.defaultSpeed
	end
	local destx = mainScene.player.avatar.x + ( 55 * math.abs( speed ) ) - 150
	local randomHeight = mainScene.groundY - ( math.random( 20 ) + 100 )

	blackHawk.t = 0
	blackHawk.origin = {x=blackHawk.x,y=blackHawk.y}
	blackHawk.destination = {x=destx,y=mainScene.groundY-50}
	blackHawk.midPoint = {x=blackHawk.x - ((blackHawk.x - destx )/2),y=randomHeight}
	
	blackHawk.health = 1
    blackHawk.xChoke = 15
    blackHawk.yChoke = 10
    
    local scale = 1 + ( math.random(25)*.01 )
    
    blackHawk.xScale = scale
    blackHawk.yScale = scale
    
    blackHawk.name = "blackHawk"
	
	blackHawk.update = function()
		update(blackHawk, mainScene)
	end

    return blackHawk
end

return blackHawks
