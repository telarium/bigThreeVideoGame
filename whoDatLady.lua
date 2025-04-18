----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script for the "Who Dat Lady" minigame

storyboard.state.bPlayedWhoDatLady = true
local scene = storyboard.newScene()

local ladies = {}
table.insert( ladies, "Shelly Long" )
table.insert( ladies, "Martin Balsam" )
table.insert( ladies, "David Janssen" )
table.insert( ladies, "Lee Meriwether" )
table.insert( ladies, "Dyan Cannon" )
table.insert( ladies, "Reese Witherspoon" )
table.insert( ladies, "Susan B. Anthony" )
table.insert( ladies, "Bernadette Peters" )
table.insert( ladies, "Morgan Fairchild" )
table.insert( ladies, "Marilu Henner" )
table.insert( ladies, "Faye Dunaway" )
table.insert( ladies, "Jaclyn Smith" )
table.insert( ladies, "Catherine Deneuve" )
table.insert( ladies, "Lindsay Wagner" )
table.insert( ladies, "Jacqueline Bisset" )
table.insert( ladies, "Rebecca De Mornay" )
table.insert( ladies, "Margot Kidder" )
table.insert( ladies, "Jennifer Beals" )
table.insert( ladies, "Stephanie Powers" )
table.insert( ladies, "Nastassja Kinski" )
table.insert( ladies, "Debra Winger" )
table.insert( ladies, "Kelly McGillis" )
table.insert( ladies, "Dianne Wiest" )
table.insert( ladies, "Markie Post" )
table.insert( ladies, "Sheba" )
table.insert( ladies, "Frances Farmer" )
table.insert( ladies, "Shirley MacLaine" )
table.insert( ladies, "Mary Badham" )
table.insert( ladies, "Natalie Wood" )
table.insert( ladies, "Daphina" )
table.insert( ladies, "Mike Judge" )

local leftEdge = 0 - ( ( display.actualContentWidth - display.contentWidth ) / 2 )
local rightEdge = display.contentWidth + ( ( display.actualContentWidth - display.contentWidth ) / 2 )
local bottomEdge = display.contentHeight + ( ( display.actualContentHeight - display.contentHeight ) / 2 )
local topEdge = 0 -  ( ( display.actualContentHeight - display.contentHeight ) / 2 )

local displayGroup = nil
local overlayGroup = nil


local function makeText( textString, fontSize, myX, myY, bLeft )
    local align = "center"
    if( bLeft ) then
        align = "left"
    end
    local textOptions = 
        {
            text = textString,     
            x = myX,
            y = myY,
            width = 400,     --required for multi-line and alignment
            font = "C64 User Mono",   
            fontSize = fontSize,
            align = align  --new alignment parameter
        }
    local mainText = display.newText( textOptions )
    local subText = display.newText( textOptions )
    subText:setFillColor( 0,0,0 )
    subText.x = mainText.x - 4
    subText.y = mainText.y + 3
        
    displayGroup:insert( subText )
    displayGroup:insert( mainText )
    
    return mainText, subText
end

local function showTextAnswers()
    local text = table.remove( ladies, math.random( table.getn( ladies ) ) )
    scene.answer1, scene.answer1Shadow = makeText( text, 10, scene.checkBox1.x + 220, scene.checkBox1.y, true )
    text = table.remove( ladies, math.random( table.getn( ladies ) ) )
    scene.answer2, scene.answer2Shadow = makeText( text, 10, scene.checkBox2.x + 220, scene.checkBox2.y, true )
    text = table.remove( ladies, math.random( table.getn( ladies ) ) )
    scene.answer3, scene.answer3Shadow = makeText( text, 10, scene.checkBox3.x + 220, scene.checkBox3.y, true )
    text = table.remove( ladies, math.random( table.getn( ladies ) ) )
    scene.answer4, scene.answer4Shadow = makeText( text, 10, scene.checkBox4.x + 220, scene.checkBox4.y, true )
    
    scene.answer1.alpha = 0
    scene.answer1Shadow.alpha = 0
    scene.answer2.alpha = 0
    scene.answer2Shadow.alpha = 0
    scene.answer3.alpha = 0
    scene.answer3Shadow.alpha = 0
    scene.answer4.alpha = 0
    scene.answer4Shadow.alpha = 0
    
    local checkboxHotspot1 = display.newRect(-30, -200, 200, 30)
	checkboxHotspot1.x = display.contentCenterX
	checkboxHotspot1.y = display.contentCenterY
    checkboxHotspot1:setFillColor(1, 1, 1, 0)
    checkboxHotspot1.isHitTestable = true
    checkboxHotspot1.x,checkboxHotspot1.y = scene.checkBox1.x+85,scene.checkBox1.y
    
    local checkboxHotspot2 = display.newRect(-30, -200, 200, 30)
	checkboxHotspot2.x = display.contentCenterX
	checkboxHotspot2.y = display.contentCenterY
    checkboxHotspot2:setFillColor(1, 1, 1, 0)
    checkboxHotspot2.isHitTestable = true
    checkboxHotspot2.x,checkboxHotspot2.y = scene.checkBox2.x+85,scene.checkBox2.y
    
    local checkboxHotspot3 = display.newRect(-30, -200, 200, 30)
	checkboxHotspot3.x = display.contentCenterX
	checkboxHotspot3.y = display.contentCenterY
    checkboxHotspot3:setFillColor(1, 1, 1, 0)
    checkboxHotspot3.isHitTestable = true
    checkboxHotspot3.x,checkboxHotspot3.y = scene.checkBox3.x+85,scene.checkBox3.y
    
    local checkboxHotspot4 = display.newRect(-30, -200, 200, 30)
	checkboxHotspot4.x = display.contentCenterX
	checkboxHotspot4.y = display.contentCenterY
    checkboxHotspot4:setFillColor(1, 1, 1, 0)
    checkboxHotspot4.isHitTestable = true
    checkboxHotspot4.x,checkboxHotspot4.y = scene.checkBox4.x+85,scene.checkBox4.y
    
    transition.to( scene.answer1, { time=500, delay=0, alpha=1} )
    transition.to( scene.answer1Shadow, { time=500, delay=0, alpha=1} )
    transition.to( scene.answer2, { time=500, delay=0, alpha=1} )
    transition.to( scene.answer2Shadow, { time=500, delay=0, alpha=1} )
    transition.to( scene.answer3, { time=500, delay=0, alpha=1} )
    transition.to( scene.answer3Shadow, { time=500, delay=0, alpha=1} )
    transition.to( scene.answer4, { time=500, delay=0, alpha=1} )
    transition.to( scene.answer4Shadow, { time=500, delay=0, alpha=1} )
    
    local function selectAnswer(num)
        if( not scene ) then
            return
        end
        timer.cancel(scene.attractTimer)
        scene.attractTimer = nil
        checkboxHotspot1:removeSelf()
        checkboxHotspot2:removeSelf()
        checkboxHotspot3:removeSelf()
        checkboxHotspot4:removeSelf()
        transition.to( scene.checkMark, { time=150, delay=0, xScale=1.25} )
        transition.to( scene.checkMark, { time=150, delay=0, yScale=1.25} )
        transition.to( scene.checkMark, { time=50, delay=0+150, xScale=1} )
        transition.to( scene.checkMark, { time=50, delay=0+150, yScale=1} )
        if( scene.correctNum == num ) then
            local sound = audio.loadSound( "sounds/ding.wav" )
            audio.play( sound )
            GA.newEvent( "design", { event_id="bonus:whoDatLadyWon",  area="whoDatLady"})
            scene.whoDatLadyPoints = 200
            audio.play( scene.voiceSweet )
        else
            local sound = audio.loadSound( "sounds/wrong.wav" )
            audio.play( sound )
            GA.newEvent( "design", { event_id="bonus:whoDatLadyLost",  area="whoDatLady"})
            scene.whoDatLadyPoints = 0
            display.setDefault( "magTextureFilter", "nearest" )
            display.setDefault( "minTextureFilter", "nearest" )
            scene.badMark = display.newImageRect( "images/whoDatLady-x.png", 29, 26 )
            if( num == 1 ) then
                scene.badMark.x = scene.checkBox1.x
                scene.badMark.y = scene.checkBox1.y
            end
            if( num == 2 ) then
                scene.badMark.x = scene.checkBox2.x
                scene.badMark.y = scene.checkBox2.y
            end
            if( num == 3 ) then
                scene.badMark.x = scene.checkBox3.x
                scene.badMark.y = scene.checkBox3.y
            end
            if( num == 4 ) then
                scene.badMark.x = scene.checkBox4.x
                scene.badMark.y = scene.checkBox4.y
            end
            scene.badMark.x = scene.badMark.x + 2
            scene.badMark.y = scene.badMark.y - 1
        end
        local delayFunction = function()
            UIEndScreen_Show(scene, "whoDatLady" )
        end
        timer.performWithDelay( 1000, delayFunction )
    end
    
    local function selectAnswer1(self)
        selectAnswer(1)
    end
    local function selectAnswer2(self)
        selectAnswer(2)
    end
    local function selectAnswer3(self)
        selectAnswer(3)
    end
    local function selectAnswer4(self)
        selectAnswer(4)
    end
    
    checkboxHotspot1:addEventListener( "touch", selectAnswer1 )
    checkboxHotspot2:addEventListener( "touch", selectAnswer2 )
    checkboxHotspot3:addEventListener( "touch", selectAnswer3 )
    checkboxHotspot4:addEventListener( "touch", selectAnswer4 )
end

function TimeOut()
    scene.whoDatLadyPoints = 0
    UIEndScreen_Show(scene, "whoDatLady" )
end

local function showAnswers()
    local order = {}
    local current = {scene.checkBox1,scene.checkBox2,scene.checkBox3,scene.checkBox4}
    while ( table.getn( current ) > 0 ) do
        local candidate = nil
        local lesserX = 1000
        for i, obj in ipairs( current ) do
            if( obj.x < lesserX ) then
                candidate = i
                lesserX = obj.x
            end
        end
        table.insert( order, table.remove( current, candidate ) )
    end
    
    local speed = 800
    for i, obj in ipairs( order ) do
        
        if( i == 1 ) then
            transition.to( obj, { time=speed, delay=0, x=display.contentCenterX - 180,transition=easing.outExpo} )
            transition.to( obj, { time=speed, delay=0, y=scene.title.y + 60,transition=easing.outExpo} )
        end
        if( i == 2 ) then
            transition.to( obj, { time=speed, delay=0, x=display.contentCenterX - 180,transition=easing.outExpo} )
            transition.to( obj, { time=speed, delay=0, y=scene.title.y + 115,transition=easing.outExpo} )
        end
        if( i == 3 ) then
            transition.to( obj, { time=speed, delay=0, x=display.contentCenterX +30,transition=easing.outExpo} )
            transition.to( obj, { time=speed, delay=0, y=scene.title.y + 60,transition=easing.outExpo} )
        end
        if( i == 4 ) then
            transition.to( obj, { time=speed, delay=0, x=display.contentCenterX +30,transition=easing.outExpo} )
            transition.to( obj, { time=speed, delay=0, y=scene.title.y + 115,transition=easing.outExpo} )
        end
        
        
    end
    timer.performWithDelay( speed, showTextAnswers )
end

local function doShuffle()
    local speed = 135
    local function shuffle()
        local num = math.random(2)
        if( num == 1 ) then
            if ( system.getInfo("platformName") == "Android" ) then
                media.playEventSound( scene.throwSound1 )
            else
                audio.play( scene.throwSound1 )
            end
        else
            if ( system.getInfo("platformName") == "Android" ) then
                media.playEventSound( scene.throwSound2 )
            else
                audio.play( scene.throwSound2 )
            end
        end
    
        speed = speed - 5
        local box1 = math.random( 4 )
        local box2 = math.random( 4 )
        if ( box1 == box2 ) then
            box2 = box2 + 1
            if( box2 == 5 ) then
                box2 = 1
            end
        end
        
        if( box1 == 1 ) then
            box1 = scene.checkBox1
        elseif( box1 == 2 ) then
            box1 = scene.checkBox2
        elseif( box1 == 3 ) then
            box1 = scene.checkBox3
        else
            box1 = scene.checkBox4
        end
        
        if( box2 == 1 ) then
            box2 = scene.checkBox1
        elseif( box2 == 2 ) then
            box2 = scene.checkBox2
        elseif( box2 == 3 ) then
            box2 = scene.checkBox3
        else
            box2 = scene.checkBox4
        end
        
        local yPoint = box1.y
        
        local box1Midpoint = 0
        local box1EndPoint = box2.x
        local box2Midpoint = 0
        local box2EndPoint = box1.x
        local dir = math.random( 2 )
        if ( dir == 2 ) then
            dir = -1
        end
        
        if( box2.x > box1.x ) then
            box1Midpoint = box1.x + ( box2.x - box1.x ) / 2
            box2Midpoint = box1.x + ( box2.x - box1.x ) / 2
        else
            box1Midpoint = box2.x + ( box1.x - box2.x ) / 2
            box2Midpoint = box2.x + ( box1.x - box2.x ) / 2
        end
        
        transition.to( box1, { time=speed, delay=0, x=box1Midpoint} )
        transition.to( box1, { time=speed, delay=0, y=yPoint+30*dir, transition=easing.outExpo} )
        transition.to( box2, { time=speed, delay=0, x=box2Midpoint} )
        transition.to( box2, { time=speed, delay=0, y=yPoint+40*dir, transition=easing.outExpo} )
        
        transition.to( box1, { time=speed, delay=speed, x=box1EndPoint} )
        transition.to( box1, { time=speed, delay=speed, y=yPoint} )
        transition.to( box2, { time=speed, delay=speed, x=box2EndPoint} )
        transition.to( box2, { time=speed, delay=speed, y=yPoint} )
    end
    transition.to( scene.checkMark, { time=200, delay=300, xScale=0.0001} )
    transition.to( scene.checkMark, { time=200, delay=300, yScale=0.0001} )
    
    local total = math.random( 7 ) + 7
    local myDel = speed*-2+50
    local inc = speed*2+50
    
    while ( total > 0 ) do
        total = total - 1
        myDel = myDel + inc
        timer.performWithDelay( myDel, shuffle )
    end
    
    timer.performWithDelay( myDel+750, showAnswers )
end

local function gameLoop()
    if ( scene.correctNum == 1 ) then
        scene.checkMark.x = scene.checkBox1.x
        scene.checkMark.y = scene.checkBox1.y
    elseif ( scene.correctNum == 2 ) then
        scene.checkMark.x = scene.checkBox2.x
        scene.checkMark.y = scene.checkBox2.y
    elseif ( scene.correctNum == 3 ) then
        scene.checkMark.x = scene.checkBox3.x
        scene.checkMark.y = scene.checkBox3.y
    else
        scene.checkMark.x = scene.checkBox4.x
        scene.checkMark.y = scene.checkBox4.y
    end
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    storyboard.removeAll()
    collectgarbage()
	physics.stop()
    
    if ( system.getInfo("platformName") == "Android" ) then
		scene.popSound = media.newEventSound( "sounds/pop.wav" )
        scene.throwSound1 = media.newEventSound( "sounds/throw1.wav" )
        scene.throwSound2 = media.newEventSound( "sounds/throw2.wav" )
	else
		scene.popSound = audio.loadSound( "sounds/pop.wav" )
        scene.throwSound1 = audio.loadSound( "sounds/throw1.wav" )
        scene.throwSound2 = audio.loadSound( "sounds/throw2.wav" )
	end
    
    displayGroup = display.newGroup()
    addDisplayGroup( displayGroup )
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    
        
    local startburstSheet = graphics.newImageSheet( "images/whoDatLady-bgAnim.png", { width=256, height=186, numFrames=18 } )
    scene.bg = display.newSprite( startburstSheet, {{ name = "loop", start=1, count=18, time=1000, loopCount=0 }} )
    scene.bg.anchorX = 0.5
	scene.bg.anchorY = 0.5
	scene.bg.xScale = display.actualContentWidth / scene.bg.width
	scene.bg.yScale = display.actualContentHeight / scene.bg.height
	scene.bg.x = display.contentCenterX
	scene.bg.y = display.contentCenterY
    displayGroup:insert( scene.bg )
	
	scene.bg:setSequence( "loop" )
	scene.bg:play()
    
    scene.title = display.newImageRect( "images/whoDatLady-title.png", 307, 70 )
    scene.title.x = display.contentCenterX
	scene.title.y = display.contentCenterY
    displayGroup:insert( scene.title )
    
    
    scene.instructions, scene.instructionsDropShadow = makeText( "(keep your eye on the checked box)", 11, display.contentCenterX, scene.title.y + 45 )
    scene.instructions.alpha = 0
    scene.instructionsDropShadow.alpha = 0

    scene.checkBox1 = display.newImageRect( "images/whoDatLady-checkbox.png", 28, 27 )
    scene.checkBox1.x = display.contentCenterX - 75
	scene.checkBox1.y = scene.title.y + 80
    displayGroup:insert( scene.checkBox1 )
    
    scene.checkBox2 = display.newImageRect( "images/whoDatLady-checkbox.png", 28, 27 )
    scene.checkBox2.x = scene.checkBox1.x + 50
	scene.checkBox2.y = scene.checkBox1.y
    displayGroup:insert( scene.checkBox2 )
    
    scene.checkBox3 = display.newImageRect( "images/whoDatLady-checkbox.png", 28, 27 )
    scene.checkBox3.x = scene.checkBox2.x + 50
	scene.checkBox3.y = scene.checkBox1.y
    displayGroup:insert( scene.checkBox3 )
    
    scene.checkBox4 = display.newImageRect( "images/whoDatLady-checkbox.png", 28, 27 )
    scene.checkBox4.x = scene.checkBox3.x + 50
	scene.checkBox4.y = scene.checkBox1.y
    displayGroup:insert( scene.checkBox4 )
    
    scene.checkMark = display.newImageRect( "images/whoDatLady-checkmark.png", 29, 26 )
    scene.checkMark.x = scene.checkBox3.x + 52
	scene.checkMark.y = scene.checkBox1.y - 4
    displayGroup:insert( scene.checkMark )

    local curtainSheet = graphics.newImageSheet( "images/curtainsAnim.png", { width=328, height=184, numFrames=24} )
    scene.curtain = display.newSprite( curtainSheet, {{ name = "loop", start=1, count=23, time=1300, loopCount=1 }} )
    scene.curtain.anchorX = 0.5
	scene.curtain.anchorY = 0.5
	scene.curtain.xScale = display.actualContentWidth / scene.curtain.width * 1.1
	scene.curtain.yScale = display.actualContentHeight / scene.curtain.height * 1.1
	scene.curtain.x = display.contentCenterX
	scene.curtain.y = display.contentCenterY
    displayGroup:insert( scene.curtain )
    
    scene.introSound = audio.loadSound( "sounds/voice-moleWhoDatLady.wav" )
    scene.curtainSound = audio.loadSound( "sounds/curtains.wav" )
    scene.voiceSweet = audio.loadSound( "sounds/voice-moleSweet.wav" )

	scene.curtain:setSequence( "loop" )
    local curtainDelay = function()
        scene.curtain:play()
        audio.play( scene.introSound )
        audio.play( scene.curtainSound )
    end
    timer.performWithDelay( 600, curtainDelay )
    
    local overlay = display.newRect(leftEdge, topEdge, display.actualContentWidth, display.actualContentHeight)
    overlay:setFillColor(0, 0, 0)
    overlay.alpha = 1
    overlay.anchorX = 0
    overlay.anchorY = 0
    overlay.blendMode = "multiply"
    displayGroup:insert( overlay )
    transition.to( overlay, { time=350, delay=0, alpha=0, transition=easing.inOutQuad } )
    
    
    scene.checkBox1.xScale,scene.checkBox1.yScale = 0.0001, 0.0001
    scene.checkBox2.xScale,scene.checkBox2.yScale = 0.0001, 0.0001
    scene.checkBox3.xScale,scene.checkBox3.yScale = 0.0001, 0.0001
    scene.checkBox4.xScale,scene.checkBox4.yScale = 0.0001, 0.0001
    scene.checkMark.xScale,scene.checkMark.yScale = 0.0001, 0.0001
    
    scene.correctNum = math.random(4)
    
    
    local function showCheckbox( obj, myDelay )
        local moreDelay = function()
            if ( system.getInfo("platformName") == "Android" ) then
                media.playEventSound( scene.popSound )
            else
                audio.play( scene.popSound )
            end
        end
        timer.performWithDelay( myDelay, moreDelay )
        transition.to( obj, { time=150, delay=myDelay, xScale=1.25} )
        transition.to( obj, { time=150, delay=myDelay, yScale=1.25} )
        transition.to( obj, { time=50, delay=myDelay+150, xScale=1} )
        transition.to( obj, { time=50, delay=myDelay+150, yScale=1} )
    end
    
    local delayStart = 1500
    showCheckbox( scene.checkBox1, delayStart )
    showCheckbox( scene.checkBox2, delayStart+100 )
    showCheckbox( scene.checkBox3, delayStart+200 )
    showCheckbox( scene.checkBox4, delayStart+300 )
    
    showCheckbox( scene.checkMark, delayStart+800 )
    
    transition.to( scene.instructions, { time=1000, delay=3000, alpha=1} )
    transition.to( scene.instructionsDropShadow, { time=1000, delay=3000, alpha=1} )
    transition.to( scene.instructions, { time=1000, delay=6000, alpha=0} )
    transition.to( scene.instructionsDropShadow, { time=1000, delay=6000, alpha=0} )
    
    timer.performWithDelay( 6200, doShuffle )
    
    
    
    scene.time = system.getTimer()
    
    GA.newEvent( "design", { event_id="bonus:playedWhoDatLady",  area="whoDatLady"})
    
    scene.attractTimer = timer.performWithDelay( 25000, TimeOut )
    
    data = loadTable()
    data.bPlayedWhoDatLady = true
    save(false,data)
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
    Runtime:addEventListener( "enterFrame", gameLoop )
end


function scene:exitScene( event )
    if( scene.attractTimer ) then
        timer.cancel(scene.attractTimer)
        scene.attractTimer = nil
    end
    
    if( scene.badMark ) then
        scene.badMark:removeSelf()
    end

	Runtime:removeEventListener( "enterFrame", gameLoop )
	audio.dispose( scene.introSound )
    audio.dispose( scene.curtainSound )
    audio.dispose( scene.voiceSweet )
    
    scene.bg:removeSelf()
    scene.bg = nil
    
    scene.curtain:removeSelf()
    scene.curtain = nil
    
	displayGroup:removeSelf()
    displayGroup = nil
    
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