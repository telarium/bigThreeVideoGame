----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script controls the flying mudshark behaviors and properties
-- for the Chicago endless runner level


local mudSharks = {

}

-- Animate the flight path of a mudshark on a bezier curve
local function doQuadraticBezierCurve(point1, point2, point3, t)
    local a = (1.0 - t) * (1.0 - t);
    local b = 2.0 * t * (1.0 - t);
    local c = t * t;
    
    local x = math.floor( a * point1.x + b * point2.x + c * point3.x )
    local y = math.floor( a * point1.y + b * point2.y + c * point3.y )
		
    return x,y
end

local function update(shark, mainScene)
	if( not shark.bRemove and shark.health > 0 ) then
		shark.t = shark.t+ ((0.0175 * mainScene.timeScale ) * ( 60 / display.fps ) )
		if ( shark.t > 1 ) then
			shark.t = 1
		end
		shark.x, shark.y = doQuadraticBezierCurve( shark.origin,shark.midPoint, shark.destination, shark.t )
	end	
end


function mudSharks:spawn(scene)
    mainScene = scene
    
    if( mainScene.player.bDashing ) then
        return
    end
    
    if( not self.voiceSound and mainScene:getSelectedCharacter() ~= "don" ) then
        self.voiceSound = scene.sound:loadVoice( "voice-" .. mainScene:getSelectedCharacter() .. "MudSharks.wav" )
        scene.sound:playVoice( self.voiceSound, 0 )
    end
    
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )

    local mudsharkSheet = graphics.newImageSheet( "images/mudsharkAnim.png", { width=82, height=43, numFrames=6 } )
    local mudShark = display.newSprite( mudsharkSheet, {{ name = "loop", start=1, count=6, time=750, loopCount=0 }} )
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
	
	local x,y = mainScene.city.displayGroup:contentToLocal( mainScene.rightEdge, mainScene.foldY )
	
	mudShark.x = x + mudShark.width
	mudShark.y = mainScene.groundY - ( math.random( 20 ) + 4 )
	mainScene.city.displayGroup:insert( mudShark )
	mudShark:setSequence( "loop" )
	
	mudShark.bPerciseCollisionDetection = true
    mudShark.xChoke = 0
    mudShark.yChoke = 10
    
	mudShark:play()
	
	local speed = mainScene.city.curSpeed
	if( mainScene.player.bDashing or speed <-8 ) then
	   speed = -8
	end
	local destx = mainScene.player.avatar.x + ( 55 * math.abs( speed ) ) - math.random(30) - 10
	if( mainScene.enemies.mudSharks.bBossBattle ) then
	   destx = destx + math.random(60)+50
	end 
	local randomHeight =(math.random(50)+160)*-1

	mudShark.t = 0
	mudShark.origin = {x=mudShark.x,y=mudShark.y}
	mudShark.destination = {x=destx,y=mudShark.y}
	mudShark.midPoint = {x=mudShark.x - ((mudShark.x - destx )/2),y=randomHeight}
	mudShark.health = 1  
    mudShark.name = "mudShark"
	
	mudShark.update = function()
		update(mudShark, mainScene)
	end

    return mudShark
end

return mudSharks
