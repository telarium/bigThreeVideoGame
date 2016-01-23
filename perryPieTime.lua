----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script for the Perry Pie Time minigame

local storyboard = require( "storyboard" )
local scene = storyboard.newScene()

local leftEdge = 0 - ( ( display.actualContentWidth - display.contentWidth ) / 2 )
local rightEdge = display.contentWidth + ( ( display.actualContentWidth - display.contentWidth ) / 2 )
local bottomEdge = display.contentHeight + ( ( display.actualContentHeight - display.contentHeight ) / 2 )
local topEdge = 0 -  ( ( display.actualContentHeight - display.contentHeight ) / 2 )

local displayGroup = nil
local overlayGroup = nil

function dragBody( event, params )
    if( scene.bGameOver ) then
        return
    end

	local body = event.target
	local phase = event.phase
	local stage = display.getCurrentStage()

	if "began" == phase then
		if( body.bEaten ) then
			return
		end
		stage:setFocus( body, event.id )
		body.isFocus = true

		-- Create a temporary touch joint and store it in the object for later reference
		if params and params.center then
			-- drag the body from its center point
			body.tempJoint = physics.newJoint( "touch", body, body.x, body.y )
		else
			-- drag the body from the point where it was touched
			body.tempJoint = physics.newJoint( "touch", body, event.x, event.y )
		end

		-- Apply optional joint parameters
		if params then
			local maxForce, frequency, dampingRatio

			if params.maxForce then
				-- Internal default is (1000 * mass), so set this fairly high if setting manually
				body.tempJoint.maxForce = params.maxForce
			end
			
			if params.frequency then
				-- This is the response speed of the elastic joint: higher numbers = less lag/bounce
				body.tempJoint.frequency = params.frequency
			end
			
			if params.dampingRatio then
				-- Possible values: 0 (no damping) to 1.0 (critical damping)
				body.tempJoint.dampingRatio = params.dampingRatio
			end
		end
		scene.activeObject = body
	
	elseif body.isFocus then
		if "moved" == phase then
		
			-- Update the joint to track the touch
			body.tempJoint:setTarget( event.x, event.y )

		elseif "ended" == phase or "cancelled" == phase then
			stage:setFocus( body, nil )
			body.isFocus = false
			
			-- Remove the joint when the touch ends			
			body.tempJoint:removeSelf()
			
		end
	end

	return true
end

local function newObject()
    if( scene.bGameOver ) then
        return
    end
	display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    local num = math.random(7)
    local myShape = nil
    if( num == 1 and system.getTimer() - scene.time > 8000 ) then
        j = display.newImage("images/pieTime_cheese.png");
        myShape = { 27, 14  ,  -26, 27  ,  -29, 13  ,  -29, -3  ,  -16, -22  ,  5, -28  ,  31, -19  }
        j.bDairy = true
    else
        local newNum = math.random(2)
        if ( newNum == 1 ) then
            j = display.newImage("images/pieTime_pie2.png");
        else
            j = display.newImage("images/pieTime_pie1.png");
        end
        myShape = {   44, 7  ,  26, 25  ,  -1, 27  ,  -28, 24  ,  -41, 5  ,  0, -19  }
    end
	j.x = 200 + math.random( 160 )
	j.y = -100
	j.xScale = 1
	j.yScale = 1
	physics.addBody( j, { density=0.3, friction=0.2, bounce=0.1, shape=myShape} )

	j:addEventListener( "touch", dragBody )
	display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
    if( not scene.bGameOver ) then
        scene.perryMask:toFront()
        scene.perryBlush1:toFront()
    end
    displayGroup:insert( j )
	table.insert( scene.objects, j )
end

local function gameOver()
    timer.cancel( scene.pieTimer )
    timer.cancel( scene.gameTimer )
    scene.bGameOver = true
    for i, object in ipairs( scene.objects ) do

            if( object.removeEventListener ) then
                object:removeEventListener( "touch", dragBody )
            end
        object = nil
        table.remove( scene.objects, i )
    end
    physics.stop()
    UIEndScreen_Show(scene, "pieTime" )
    GA.newEvent( "design", { event_id="bonus:piesEaten",  area="perryPieTime", value=scene.piePoints/10})
    local cat = "piesEaten"
    if ( system.getInfo("platformName") == "Android" ) then
        cat = "CgkIhf7UyIMOEAIQBQ"
    else
        cat = "perryPieTime"
    end
    
    if( gameNetwork ) then
                    gameNetwork.request( "setHighScore", 
                    {
                    localPlayerScore = { category= cat,value=scene.piePoints/10 },
                    })
    end
end

local function showTimer( text, stroke )
    text.isVisible = true
    text.alpha = 1
    text.xScale = 0.01
    text.yScale = 0.01
    transition.to( text, { time=1000, delay=0, xScale=1, transition=easing.outExpo} )
    transition.to( text, { time=1000, delay=0, yScale=1, transition=easing.outExpo} )
    
    stroke.isVisible = true
    stroke.alpha = 1
    stroke.xScale = 0.01
    stroke.yScale = 0.01
    transition.to( stroke, { time=1000, delay=0, xScale=1, transition=easing.outExpo} )
    transition.to( stroke, { time=1000, delay=0, yScale=1, transition=easing.outExpo} )
    
    transition.to( text, { time=350, delay=900, alpha=0 } )
    transition.to( stroke, { time=350, delay=900, alpha=0 } )
end

local function gameTimer()
    if( scene.bGameOver ) then
        return
    end
    scene.timeLeft = scene.timeLeft - 1
    if ( scene.timeLeft == 3 ) then
        showTimer( scene.three, scene.threeStroke )
        audio.play( scene.buzzerSound3 )
    elseif( scene.timeLeft == 2 ) then
        showTimer( scene.two, scene.twoStroke )
        audio.play( scene.buzzerSound2 )
    elseif( scene.timeLeft == 1 ) then
        audio.play( scene.buzzerSound1 )
        showTimer( scene.one, scene.oneStroke )
    elseif( scene.timeLeft == 0 ) then
        if( not scene.bPieExtension ) then
            scene.bPieExtension = true
            scene.timeLeft = 10
            audio.play( scene.pieExtensionSound )
            scene.pieExtension.y = topEdge - 50
            scene.pieExtension.isVisible = true
            scene.pieExtension.alpha = .9
            transition.to( scene.pieExtension, { time=500, delay=0, y=display.contentCenterY, transition=easing.outExpo } )
            transition.to( scene.pieExtension, { time=400, delay=1450, y=bottomEdge + 150, transition=easing.inExpo } )
        else
            scene.bGameOver = true
            audio.play( scene.toiletFlush )
            gameOver()
        end
    end
end

local function showPoints()
    local stroke = display.newImage("images/pieTime_pointsStroke.png");
    local points = display.newImage("images/pieTime_points.png");
    points.blendMode = "screen"
    points.x = scene.perryMain.x + 20 + math.random( 200 )
    points.y = scene.perryMain.y - 150 - math.random( 100 )
    stroke.x = points.x
    stroke.y = points.y
    overlayGroup:insert( stroke )
    overlayGroup:insert( points )
    scene.gradient:toFront()
    scene.pieExtension:toFront()
    
    local function removePoints()
        points:removeSelf()
        stroke:removeSelf()
        points = nil
        stroke = nil
    end
    
    local animTime = 800 + math.random( 300 )
    
    transition.to( points, { time=animTime, delay=0, y=points.y-100 } )
    transition.to( stroke, { time=animTime, delay=0, y=points.y-100 } )
    transition.to( points, { time=500, delay=500, alpha = 0, transition=easing.outExpo } )
    transition.to( stroke, { time=500, delay=500, alpha = 0, transition=easing.outExpo } )
    
    timer.performWithDelay( animTime, removePoints )
end

local function gameLoop()
	local object = nil
	for i, object in ipairs( scene.objects ) do
		if( object.y ) then
			local yDelta = object.y - scene.perryMain.y
			local xDelta = object.x - scene.perryMain.x
			if( yDelta <= -130 and yDelta >= -210 and xDelta <= 70 and xDelta >= 10 and not object.bEaten ) then
				object.bEaten = true
                if( object.bDairy ) then
                    physics.stop()
                    audio.play( scene.dairySound )
                    audio.play( scene.damageSound )
                    scene.bGameOver = true
                    timer.performWithDelay( 1000, gameOver )
                    transition.to( scene.gradient, { time=200, delay=0, alpha=0.9, transition=easing.outExpo } )
                    GA.newEvent( "design", { event_id="bonus:dairyEaten",  area="perryPieTime", value=1 })
                    --transition.to( scene.gradient, { time=500, delay=200, alpha=0 } )
                else
                    if( system.getTimer() - scene.lastSoundTime > 150 ) then
                        scene.lastSoundTime = system.getTimer()
                        audio.play( scene.bonusSound )
                    end
                    
                    scene.piePoints = scene.piePoints + 10
                    showPoints()
                    transition.to( object, { time=2000, delay=0, xScale=0 } )
				    transition.to( object, { time=2000, delay=0, yScale=0 } )
                end
				
				object.isFocus = false
				if( object.tempJoint ) then
					if( object.tempJoint.removeSelf ) then
						object.tempJoint:removeSelf()
			   	 end
			   	end
				table.remove( scene.objects, i )
				object:removeEventListener( "touch", dragBody )
			end
			
			if ( object.x < ( leftEdge - 50 ) or object.x > ( rightEdge + 50 ) or object.xScale < 0.1 ) then
					object:removeSelf()
					object:removeEventListener( "touch", dragBody )
					
		    end
		end
	end
end

local function playPerryIntro()
    audio.play( scene.perryIntroSound )
    scene.pieTimer = timer.performWithDelay( 400, newObject, 120 )
    scene.gameTimer = timer.performWithDelay( 1000, gameTimer, 0 )
end

local function playMoleIntro()
    audio.play( scene.moleIntroSound )
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    storyboard.removeAll()
    collectgarbage()
	physics.start()
        
    displayGroup = display.newGroup()
    overlayGroup = display.newGroup()
    
    addDisplayGroup( displayGroup )
    addDisplayGroup( overlayGroup )
	
	--physics.setDrawMode( "hybrid" )
	
	scene.ground = display.newRect( 0, display.actualContentHeight, display.actualContentWidth*2, 0 )
	physics.addBody( scene.ground, "static", { friction=0.5, bounce=0.3 } )
	
	display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
	
	local startburstSheet = graphics.newImageSheet( "images/pieTime_background.gif", { width=256, height=186, numFrames=24 } )
    scene.bg = display.newSprite( startburstSheet, {{ name = "loop", start=1, count=24, time=1000, loopCount=0 }} )
    scene.bg.anchorX = 0.5
	scene.bg.anchorY = 0.5
	scene.bg.xScale = display.actualContentWidth / scene.bg.width
	scene.bg.yScale = display.actualContentHeight / scene.bg.height
	scene.bg.x = display.contentCenterX
	scene.bg.y = display.contentCenterY
    displayGroup:insert( scene.bg )
	
	scene.bg:setSequence( "loop" )
	scene.bg:play()
	
	scene.perryMain = display.newImage( "images/pieTime_perryMain.png" )
	scene.perryMain.anchorX = 0
	scene.perryMain.anchorY = 1
	scene.perryMain.x = leftEdge
	scene.perryMain.y = bottomEdge
    displayGroup:insert( scene.perryMain )
	
	scene.perryMask = display.newImage( "images/pieTime_perryMask.png" )
	scene.perryMask.anchorX = 0
	scene.perryMask.anchorY = 1
	scene.perryMask.x = scene.perryMain.x
	scene.perryMask.y = scene.perryMain.y
    displayGroup:insert( scene.perryMask )
	
	scene.perryBlush1 = display.newImage( "images/pieTime_perryOverlay.png" )
	scene.perryBlush1.anchorX = 0
	scene.perryBlush1.anchorY = 1
	scene.perryBlush1.x = scene.perryMain.x
	scene.perryBlush1.y = scene.perryMain.y - 40
	scene.perryBlush1.alpha = 0.1
    displayGroup:insert( scene.perryBlush1 )
	
	scene.perryBlush2 = display.newImage( "images/pieTime_perryOverlay2.png" )
	scene.perryBlush2.anchorX = 0
	scene.perryBlush2.anchorY = 1
	scene.perryBlush2.x = scene.perryBlush1.x
	scene.perryBlush2.y = scene.perryBlush1.y
	scene.perryBlush2.alpha = 0.1
    displayGroup:insert( scene.perryBlush2 )
	
	transition.to( scene.perryBlush1, { time=15000, delay=0, alpha=1, transition=easing.inExpo } )
	transition.to( scene.perryBlush2, { time=15000, delay=0, alpha=1, transition=easing.inExpo } )
	
	scene.gradient = display.newImageRect( "images/hitOverlay.png", 200, 200 )
	scene.gradient.anchorX = 0.5
	scene.gradient.anchorY = 0.5
	scene.gradient.x = display.contentCenterX
	scene.gradient.y = display.contentCenterY
	scene.gradient.xScale = display.actualContentWidth / scene.gradient.width
	scene.gradient.yScale = display.actualContentHeight / scene.gradient.height
	scene.gradient.blendMode = "screen"
	scene.gradient.alpha = 0
    overlayGroup:insert( scene.gradient )
	
	physics.addBody( scene.perryMain, "static",
  { density=5, friction=0.2, bounce=0.3, shape = {   20.5, 150  ,  25.5, 58  ,  97.5, 110  ,  116.5, 151  } },
  { density=5, friction=0.2, bounce=0.3, shape = {   -135.5, 150  ,  -133.5, 79  ,  -72.5, 32  ,  -2.5, 47  ,  25.5, 58  ,  20.5, 150  } },
  { density=5, friction=0.2, bounce=0.3, shape = {   -2.5, 47  ,  -72.5, 32  ,  -35.5, 26  } },
  { density=5, friction=0.2, bounce=0.3, shape = {   44.5, -102  ,  36.5, -88  ,  -15.5, -59  ,  25.5, -112  ,  41.5, -114  } },
  { density=5, friction=0.2, bounce=0.3, shape = {   -133.5, -90  ,  -104.5, -104  ,  -53.5, -112  ,  -47.5, -55  ,  -133.5, -42  } },
  { density=5, friction=0.2, bounce=0.3, shape = {   38.5, -10  ,  11.5, -16  ,  -15.5, -59  ,  36.5, -88  ,  62.5, -61  ,  71.5, -4  } },
  { density=5, friction=0.2, bounce=0.3, shape = {   -7.5, -146  ,  11.5, -144  ,  25.5, -112  ,  -15.5, -59  ,  -47.5, -55  ,  -53.5, -112  ,  -43.5, -138  } },
  { density=5, friction=0.2, bounce=0.3, shape = {   -104.5, -104  ,  -133.5, -90  ,  -115.5, -107  } },
  { density=5, friction=0.2, bounce=0.3, shape = {   -53.5, -112  ,  -104.5, -104  ,  -73.5, -119  } }
  )
  
	scene.title = display.newImage( "images/pieTime_title.png" )
	scene.title.anchorX = 0.5
	scene.title.anchorY = 0.5
	scene.title.x = display.contentCenterX + 120
	scene.title.y = display.contentCenterY
	scene.title.blendMode = "screen"
    displayGroup:insert( scene.title )
	
	scene.titleStroke = display.newImage( "images/pieTime_titleStroke.png" )
	scene.titleStroke.anchorX = 0.5
	scene.titleStroke.anchorY = 0.5
	scene.titleStroke.x = scene.title.x
	scene.titleStroke.y = scene.title.y
    displayGroup:insert( scene.titleStroke )

    scene.three = display.newImage( "images/pieTime_3.png" )
	scene.three.anchorX = 0.5
	scene.three.anchorY = 0.5
	scene.three.x = display.contentCenterX + 120
	scene.three.y = display.contentCenterY
	scene.three.blendMode = "multiply"
    scene.three.isVisible = false
    displayGroup:insert( scene.three )
	
	scene.threeStroke = display.newImage( "images/pieTime_3stroke.png" )
	scene.threeStroke.anchorX = 0.5
	scene.threeStroke.anchorY = 0.5
	scene.threeStroke.x = scene.three.x
	scene.threeStroke.y = scene.three.y
    scene.threeStroke.isVisible = false
    displayGroup:insert( scene.threeStroke )
    
    scene.two = display.newImage( "images/pieTime_2.png" )
	scene.two.anchorX = 0.5
	scene.two.anchorY = 0.5
	scene.two.x = display.contentCenterX + 120
	scene.two.y = display.contentCenterY
	scene.two.blendMode = "multiply"
    scene.two.isVisible = false
    displayGroup:insert( scene.two )
	
	scene.twoStroke = display.newImage( "images/pieTime_2stroke.png" )
	scene.twoStroke.anchorX = 0.5
	scene.twoStroke.anchorY = 0.5
	scene.twoStroke.x = scene.two.x
	scene.twoStroke.y = scene.two.y
    scene.twoStroke.isVisible = false
    displayGroup:insert( scene.twoStroke )
    
    scene.one = display.newImage( "images/pieTime_1.png" )
	scene.one.anchorX = 0.5
	scene.one.anchorY = 0.5
	scene.one.x = display.contentCenterX + 120
	scene.one.y = display.contentCenterY
	scene.one.blendMode = "multiply"
    scene.one.isVisible = false
    displayGroup:insert( scene.one )
	
	scene.oneStroke = display.newImage( "images/pieTime_1stroke.png" )
	scene.oneStroke.anchorX = 0.5
	scene.oneStroke.anchorY = 0.5
	scene.oneStroke.x = scene.one.x
	scene.oneStroke.y = scene.one.y
    scene.oneStroke.isVisible = false
    displayGroup:insert( scene.oneStroke )
	
	scene.pieExtension = display.newImage( "images/pieTime_pieExtension.png" )
	scene.pieExtension.anchorX = 0.5
	scene.pieExtension.anchorY = 0.5
	scene.pieExtension.x = display.contentCenterX
	scene.pieExtension.y = display.contentCenterY
    scene.pieExtension.isVisible = false
    overlayGroup:insert( scene.pieExtension )
    
    local overlay = display.newRect(leftEdge, topEdge, display.actualContentWidth, display.actualContentHeight)
    overlay:setFillColor(0, 0, 0)
    overlay.alpha = 1
    overlay.anchorX = 0
    overlay.anchorY = 0
    overlay.blendMode = "multiply"
    overlayGroup:insert( overlay )
    transition.to( overlay, { time=350, delay=0, alpha=0, transition=easing.inOutQuad } )
    
    --
    scene.title.xScale = 0.01
    scene.title.yScale = 0.01
    transition.to( scene.title, { time=1500, delay=0, xScale=1, transition=easing.outExpo} )
    transition.to( scene.title, { time=1500, delay=0, yScale=1, transition=easing.outExpo} )
    
    scene.titleStroke.xScale = 0.01
    scene.titleStroke.yScale = 0.01
    transition.to( scene.titleStroke, { time=1500, delay=0, xScale=1, transition=easing.outExpo} )
    transition.to( scene.titleStroke, { time=1500, delay=0, yScale=1, transition=easing.outExpo} )
    
    transition.to( scene.title, { time=2000, delay=5500, alpha=0, transition=easing.inExpo} )
	transition.to( scene.titleStroke, { time=2000, delay=5500, alpha=0, transition=easing.inExpo} )
    
	scene.activeObject = nil
	
	scene.objects = {}
	
	scene.bonusSound = audio.loadSound( "sounds/bonus.wav" )
    scene.donIntroSound = audio.loadSound( "sounds/voice-donPerryPieTime.wav" )
    scene.perryIntroSound = audio.loadSound( "sounds/voice-perryAllInMyMouth.wav" )
    scene.buzzerSound1 = audio.loadSound( "sounds/buzzer.wav" )
    scene.buzzerSound2 = audio.loadSound( "sounds/buzzer.wav" )
    scene.buzzerSound3 = audio.loadSound( "sounds/buzzer.wav" )
    scene.toiletFlush = audio.loadSound( "sounds/toiletFlush.wav" )
    local num = math.random( 4 )
    if ( num == 2 ) then
        scene.moleIntroSound = audio.loadSound( "sounds/voice-jqaOhMy.wav" )
    else
        scene.moleIntroSound = audio.loadSound( "sounds/voice-moleLaugh.wav" )
    end
    scene.pieExtensionSound = audio.loadSound( "sounds/voice-perryPieExtension.wav" )
    scene.dairySound = audio.loadSound( "sounds/voice-perryCantEatDairy.wav" )
    scene.damageSound = audio.loadSound( "sounds/playerDamage.wav" )
    
    audio.play( scene.donIntroSound )
    timer.performWithDelay( 2900, playPerryIntro )
    timer.performWithDelay( 5200, playMoleIntro )
	
	Runtime:addEventListener( "enterFrame", gameLoop )
    
    scene.timeLeft = 20
    scene.piePoints = 0
	
	display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
    
    scene.time = system.getTimer()
    
    scene.lastSoundTime = system.getTimer()
    
    GA.newEvent( "design", { event_id="bonus:playedPieTime",  area="perryPieTime"})
    storyboard.state.bPlayedPieTime = true
    
    local data = loadTable()
    
    if( not data.pieTimeRounds ) then
        data.pieTimeRounds = 0
    end
    data.pieTimeRounds = data.pieTimeRounds + 1
    save( false, data )
end


function scene:exitScene( event )
	Runtime:removeEventListener( "enterFrame", gameLoop )
	physics.stop()
	displayGroup:removeSelf()
    displayGroup = nil
    overlayGroup:removeSelf()
    overlayGroup = nil
    
    audio.dispose( scene.bonusSound )
    audio.dispose( scene.donIntroSound )
    audio.dispose( scene.perryIntroSound )
    audio.dispose( scene.pieExtensionSound )
    audio.dispose( scene.dairySound )
    audio.dispose( scene.damageSound )
    audio.dispose( scene.buzzerSound1 )
    audio.dispose( scene.buzzerSound2 )
    audio.dispose( scene.buzzerSound3 )
    audio.dispose( scene.toiletFlush )
    scene.objects = nil
    if( scene.uiEndScreenDisplayGroup ) then
        scene.uiEndScreenDisplayGroup:removeSelf()
        scene.uiEndScreenDisplayGroup = nil
    end
end


function scene:destroyScene( event )
    scene = nil
end
-------------------------------------------------------------------------------

scene:addEventListener( "createScene", scene )
scene:addEventListener( "enterScene", scene )
scene:addEventListener( "exitScene", scene )
scene:addEventListener( "destroyScene", scene )

-----------------------------------------------------------------------------------------

return scene