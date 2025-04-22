----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script for the main menu! Duh.

-- Turn off image smoothing. So that pixel art looks awesome.
display.setDefault( "magTextureFilter", "nearest" )
display.setDefault( "minTextureFilter", "nearest" )

local scene = storyboard.newScene()
local group = display.newGroup()
local menu = display.newGroup()
local overlay = display.newGroup()

addDisplayGroup( group )
addDisplayGroup( menu )
addDisplayGroup( overlay )

local bTransitioning = false
local selectedCharacter = nil
local animateTextTimer = nil

scene.data = loadTable()
scene.voice = nil

local perryText = "PERRY KARAVELLO\naka Scary Perry\naka Stone Fury\n"
perryText = perryText .. "\n\nWEAPON:\nCaravello Cookies\n\nSPECIAL POWER:\nThe Kinison Scream"

if( scene.data and scene.data.perryHighScore > 0 ) then
    perryText = perryText .. "\n\nBEST PERRY SCORE:\n" .. tostring( scene.data.perryHighScore ) .. "\n\nOVERALL HIGH SCORE:\n" .. tostring( scene.data.highScore )
end

local moleText = "WALTER \"MOLE\" MOLINSKI\naka Tony Barbieri\naka Brock\n"
moleText = moleText .. "\n\nWEAPON:\nRed Bat, Blue Bat\n\nSPECIAL POWER:\nACWT Smoke"

if( scene.data and scene.data.moleHighScore > 0 ) then
    moleText = moleText .. "\n\nBEST MOLE SCORE:\n" .. tostring( scene.data.moleHighScore ) .. "\n\nOVERALL HIGH SCORE:\n" .. tostring( scene.data.highScore )
end

local donText = "DON BARRIS\naka Dan Barney\naka Big Lou\n"
donText = donText .. "\n\nWEAPON:\nMicrophones of Death\n\nSPECIAL POWER:\nElectric Blue Eyes"

if( scene.data and scene.data.donHighScore > 0 ) then
    donText = donText .. "\n\nBEST DON SCORE:\n" .. tostring( scene.data.donHighScore ) .. "\n\nOVERALL HIGH SCORE:\n" .. tostring( scene.data.highScore )
end


local function playGame(character)
    timer.cancel( scene.attractTimer )
    if( bTransitioning ) then
        return
    end
    
    
    transition.to( scene.playButton, { time=500, delay=0, y=500} )
    
    if( scene.backButton ) then
        scene.backButton:removeSelf()
    end
    
    local char = scene.character1
    local animTime = 700
    local myX = char.x+400
    if( character == "perry" ) then
        char = scene.character1
    elseif( character == "mole" ) then
        char = scene.character3
        animTime = 800
        myX = char.x+350
    else
        char = scene.character2
        
    end
        char:setSequence("dash")
        char:play()
        transition.to( char, { time=animTime, delay=0, x=myX, transition=easing.inExpo} )

    
    transition.to( scene.bodyText, { time=200, delay=0, alpha=0} )
    
    
    bTransitioning = true
    storyboard.state.character = character
    bTransitioning = true

    local delayFunction = function()
        audio.fadeOut( { channel=1, time=500 } )
    end
    
    uiTransition:execute( "chicagoLevel", 500 )
    
    timer.performWithDelay( 600, delayFunction )

    if( not scene.data or scene.data.highScore <= 200 ) then
        storyboard.state.bTutorialRequired = true
    end
end

local function showFirstScreen(character)
    transition.to( scene.logo, { time=600, delay=0, xScale=1, transition=easing.outExpo} )
    transition.to( scene.logo, { time=600, delay=0, yScale=1, transition=easing.outExpo } )

    local perryDelay = 0
    local donDelay = 100
    local moleDelay = 200

    if( character == "perry" ) then
        transition.to( scene.character1, { time=400, delay=0, xScale=1, transition=easing.outExpo} )
        transition.to( scene.character1, { time=400, delay=0, yScale=1, transition=easing.outExpo} )
        transition.to( scene.character1.title, { time=400, delay=0, yScale=0.001, transition=easing.outExpo} )
        transition.to( scene.character1.title, { time=400, delay=0, xScale=0.001, transition=easing.outExpo} )
        donDelay = donDelay - 100
        moleDelay = moleDelay - 100
    end
    transition.to( scene.character1, { time=400, delay=perryDelay, y=185-10} )
    transition.to( scene.character1, { time=400, delay=perryDelay, x=scene.badge.x - 75, transition=easing.outExpo} )
    transition.to( scene.character1, { time=200, delay=perryDelay+430, y=185, transition=easing.outExpo} )

    if( character == "don" ) then
        transition.to( scene.character2, { time=400, delay=0, xScale=1, transition=easing.outExpo} )
        transition.to( scene.character2, { time=400, delay=0, yScale=1, transition=easing.outExpo} )
        transition.to( scene.character2.title, { time=400, delay=0, yScale=0.001, transition=easing.outExpo} )
        transition.to( scene.character2.title, { time=400, delay=0, xScale=0.001, transition=easing.outExpo} )
        perryDelay = 0
        moleDelay = moleDelay - 200
    end
    transition.to( scene.character2, { time=400, delay=donDelay, y=185-10} )
    transition.to( scene.character2, { time=400, delay=donDelay, x=scene.badge.x, transition=easing.outExpo} )
    transition.to( scene.character2, { time=200, delay=donDelay+430, y=185, transition=easing.outExpo} )
    
    if( character == "mole" ) then
        transition.to( scene.character3, { time=400, delay=0, xScale=1, transition=easing.outExpo} )
        transition.to( scene.character3, { time=400, delay=0, yScale=1, transition=easing.outExpo} )
        transition.to( scene.character3.title, { time=400, delay=0, yScale=0.001, transition=easing.outExpo} )
        transition.to( scene.character3.title, { time=400, delay=0, xScale=0.001, transition=easing.outExpo} )
        perryDelay = 0
        donDelay = 100
    end
    
    if( character ) then
        scene.backButton.blendMode = "normal"
        selectedCharacter = nil
        local offscreenX = display.screenOriginX - scene.backButton.width
        transition.to( scene.backButton, { time=250, delay=0, x=offscreenX, transition=easing.inExpo} )
        transition.to( scene.playButton, { time=250, delay=0, y=500, transition=easing.inExpo} )
        transition.to( scene.bodyText, { time=200, delay=0, alpha=0, transition=easing.outExpo} )
    else
        
    end
    
    if( not character ) then
        timer.cancel( animateTextTimer )
    end
    
    transition.to( scene.character3, { time=400, delay=moleDelay, y=185-10} )
    transition.to( scene.character3, { time=400, delay=moleDelay, x=scene.badge.x + 75, transition=easing.outExpo} )
    transition.to( scene.character3, { time=200, delay=moleDelay+430, y=185, transition=easing.outExpo} )
    scene.selectText.isVisible = true
    transition.to( scene.selectText, { time=200, delay=730, alpha=1} )
end

local frame =0
local function perrySpriteListener( event )
	if( event.phase == "next" ) then
			frame = frame + 1
			if( frame == 12 and math.random(10) > 2) then
			  frame = 8
			  scene.character1:setFrame(frame)
			end
			if( frame == 16 ) then
			 frame = 0
			end

    end
end

local function donSpriteListener( event )
    if( not scene.character2.blinkCounter ) then
        scene.character2.blinkCounter = 0
    end

	if( event.phase == "next" ) then
        if( event.target.frame == 1 ) then
            local delay = function()
                    if( scene ) then
                        local num = math.random(3)
                        if( num == 1 ) then
                            scene.character2.blinkCounter = scene.character2.blinkCounter + 1
                            if( math.random(2) == 2 ) then
                                scene.character2:setFrame(11)
                            else
                               scene.character2:setFrame(28)
                            end
                            scene.character2:play()
                            scene.character2.blinkCounter = 0
                        elseif( num == 2 ) then
                            scene.character2.blinkCounter = scene.character2.blinkCounter + 1
                            if( math.random(5) == 1 ) then
                                
                                if( scene.character2.blinkCounter > 2 ) then
                                    if( math.random(2) == 2 ) then
                                        scene.character2:setFrame(11)
                                    else
                                       scene.character2:setFrame(28)
                                    end
                                    scene.character2:play()
                                else
                                
                                    scene.character2:setFrame(2)
                                    scene.character2:play()
                                    scene.character2.blinkCounter = 0
                                end
                            end
                        else
                            scene.character2:setFrame(1)
                            scene.character2.blinkCounter = 0
                        end
                    end
            end
            timer.performWithDelay( 800, delay, 1 )
        elseif( event.target.frame == 5 and math.random(3)>1) then
            scene.character2:setFrame(5)
            counter = 0
        elseif( event.target.frame == 9 ) then
                scene.character2:setFrame(9)
                scene.character2:pause()
                local delay = function()
                    if( scene ) then
                        scene.character2:setFrame(10)
                        scene.character2:play()
                    end
                end
                timer.performWithDelay( math.random(1300), delay, 1 )

        elseif( event.target.frame == 20 ) then
            scene.character2:pause()
            scene.character2:setFrame(20)
            local delay = function()
                    if( scene ) then
                        if( math.random(5)>3 ) then
                            scene.character2:setFrame(11)
                        else
                            --if( math.random(2) == 2 ) then
                                scene.character2:setFrame(20)
                            --else
                            --    scene.character2:setFrame(2)
                           -- end
                        end
                        scene.character2:play()
                    end
            end
            timer.performWithDelay( 800, delay, 1 )
        elseif( event.target.frame > 28 ) then
            scene.character2:pause()
            scene.character2:setFrame(29)
            local delay = function()
                    if( scene ) then
                        --if( math.random(3)==3 ) then
                        --    print( "GO1" )
                        --    scene.character2:setFrame(22)
                        --    scene.character2:play()
                        --else
                           -- if( math.random(2) == 2 ) then
                                --scene.character2:setFrame(1)
                                scene.character2:play()
                            --end
                        --end
                        --end
                        
                    end
            end
            timer.performWithDelay( 800, delay, 1 )
        end
    end
end

local function showCharacterScreen(character)
    if( selectedCharacter ) then
        return
    end
    
    if( animateTextTimer ) then
        timer.cancel( animateTextTimer )
        animateTextTimer = nil
    end

    
    local aspectRatio = display.actualContentHeight / display.actualContentWidth

    local top = scene.badge.contentBounds.yMax - 225
        
    if( aspectRatio == 0.75 ) then
        top = scene.badge.contentBounds.yMax - 235
    end
    
    scene.backButton.blendMode = "multiply"
    mCharScreenTime = system.getTimer()
    scene.bodyText.x = scene.badge.x - 30
    scene.bodyText.y = top
    scene.bodyText.alpha = 1
    timer.cancel( scene.attractTimer )
    scene.attractTimer = timer.performWithDelay( 20000, AttractMode )
    transition.to( scene.logo, { time=600, delay=0, xScale=0.001, transition=easing.outExpo} )
    transition.to( scene.logo, { time=600, delay=0, yScale=0.001, transition=easing.outExpo } )
    local myDelay = 0
    
    local text = nil
    
    if( not scene.data ) then
        scene.bodyText.y = scene.bodyText.y + 45
    else
        scene.bodyText.y = scene.badge.contentBounds.yMin + 110
    end
    
    if( character ~= scene.character1 ) then
        myDelay = myDelay + 100
        transition.to( scene.character1, { time=400, delay=myDelay, y=500} )
    else
        text = perryText
        scene.voice = audio.loadSound( "sounds/voice-perryIntro.wav" )
        selectedCharacter = "perry"
    end
    if( character ~= scene.character2 ) then
        myDelay = myDelay + 100
        transition.to( scene.character2, { time=400, delay=myDelay, y=500} )
    else
        text = donText
        scene.voice = audio.loadSound( "sounds/voice-donIntro.wav" )
        selectedCharacter = "don"
    end
    if( character ~= scene.character3 ) then
        myDelay = myDelay + 100
        transition.to( scene.character3, { time=400, delay=myDelay, y=500} )
    else
        text = moleText
        scene.voice = audio.loadSound( "sounds/voice-moleIntro.wav" )
        selectedCharacter = "mole"
    end
    
    
    audio.play( scene.voice )
    character.title.isVisible = true
    character.title.y = 180
    character.title.x = 160
    character.title.xScale = 0.01
    character.title.yScale = 0.01
    
    transition.to( character, { time=500, delay=0, xScale=2, transition=easing.outExpo} )
    transition.to( character, { time=500, delay=0, yScale=2, transition=easing.outExpo} )
    transition.to( character, { time=500, delay=0, y=175, transition=easing.outExpo} )
    transition.to( character, { time=500, delay=0, x=155, transition=easing.outExpo} )
    transition.to( scene.selectText, { time=200, delay=0, alpha=0} )
    
    character:toFront()
    
    transition.to( character.title, { time=800, delay=100, y= top, transition=easing.outExpo} )
    transition.to( character.title, { time=800, delay=100, x=display.contentCenterX, transition=easing.outExpo} )
    transition.to( character.title, { time=800, delay=100, xScale=1, transition=easing.outExpo} )
    transition.to( character.title, { time=800, delay=100, yScale=1, transition=easing.outExpo} )

    scene.playButton.y = 500
    scene.playButton.isVisible = true
    
    local playY = character.title.y+70
    
    if( aspectRatio == 0.75 ) then
        playY = character.title.y+60
    end
    
    transition.to( scene.playButton, { time=800, delay=200, y=playY, transition=easing.outExpo} )
    
    scene.backButton.isVisible = true
    scene.backButton.x = 120
    transition.to( scene.backButton, { time=800, delay=200, y=display.contentCenterY + 15, transition=easing.outExpo} )
    transition.to( scene.backButton, { time=800, delay=200, x=10, transition=easing.outExpo} )
    
    local i = 0
    scene.bodyText.text = ""
    
    local function animateText()
        if( scene.bodyText ) then
            i = i + 1
            scene.bodyText.text = scene.bodyText.text .. string.sub(text, i, i)
            i = i + 1
            scene.bodyText.text = scene.bodyText.text .. string.sub(text, i, i)
            scene.selectText.isVisible = false
        end
        if ( i >= string.len(text) or not scene.bodyText ) then
            timer.cancel( animateTextTimer )
        end
    end
    
    local startAnim = function()
        animateTextTimer = timer.performWithDelay( 5, animateText, 0 )
    end
    
    timer.performWithDelay( 500, startAnim )
end


-- 'onRelease' event listener for playBtn
local function onSelectPerry()
    if( selectedCharacter ) then
        return
    end
    showCharacterScreen(scene.character1)
	return true	-- indicates successful touch
end

local function onSelectMole()
    if( selectedCharacter ) then
        return
    end
    showCharacterScreen(scene.character3)
	return true	-- indicates successful touch
end

-- 'onRelease' event listener for playBtn
local function onSelectDon()
    if( selectedCharacter ) then
        return
    end
    showCharacterScreen(scene.character2)
	return true	-- indicates successful touch
end

function AttractMode()
   if( not selectedCharacter ) then
        local num = math.random(3)
        if( num == 1 ) then
            selectedCharacter = "perry"
        elseif( num == 2 ) then
            selectedCharacter = "don"
        else
            selectedCharacter = "mole"
        end
   end
    playGame( selectedCharacter )
end


-- Called when the scene's view does not exist:
function scene:createScene( event )
    
    storyboard.removeScene( "gameCredits" )
    
    collectgarbage()
    
	local leftEdge = 0 - ( ( display.actualContentHeight - display.contentWidth ) / 2 )
    local rightEdge = display.contentWidth + ( ( display.actualContentHeight - display.contentWidth ) / 2 )
    local bottomEdge = display.contentHeight + ( ( display.actualContentWidth - display.contentHeight ) / 2 )
    local topEdge = 0 -  ( ( display.actualContentWidth - display.contentHeight ) / 2 )
	
	-- Set background color
    display.setDefault( "background", 0, 0, 0 )
    
    local background = display.newRect(leftEdge, topEdge, display.actualContentWidth, display.actualContentHeight )
	background.anchorX = 0.5
	background.anchorY = 0.5
	background.x = display.contentCenterX
	background.y = display.contentCenterY
    background:setFillColor(251, 248, 241)
    
    local background2 = display.newRect(leftEdge, topEdge, display.actualContentWidth, display.actualContentHeight )
    background2.x = background.x
    background2.y = background.y
    background2.alpha = .0001
    background2:setFillColor(255, 255, 255)
        
	local gradient = display.newImageRect( "images/titlecard_gradient.png", 200, 200 )
	gradient.anchorX = 0.5
	gradient.anchorY = 0.5
	gradient.x = display.contentCenterX
	gradient.y = display.contentCenterY
	gradient.xScale = display.actualContentWidth / gradient.width
	gradient.yScale = display.actualContentHeight / gradient.height
	
	scene.badge = display.newImageRect( "images/badge.png", 311, 248 )
	scene.badge.anchorX = 0.5
	scene.badge.anchorY = 0.5
	scene.badge.x = display.contentCenterX
	scene.badge.y = display.contentCenterY
    
    scene.logo = display.newImageRect( "images/big3logo.png", 176, 83 )
	scene.logo.anchorX = 0.5
	scene.logo.anchorY = 0.5
	scene.logo.x = display.contentCenterX
	scene.logo.y = display.contentCenterY - 45
	scene.logo.xScale = 0.01
	scene.logo.yScale = 0.01
	
    local startburstSheet = graphics.newImageSheet( "images/starburst.png", { width=240, height=135, numFrames=28 } )
    starburst = display.newSprite( startburstSheet, {{ name = "loop", start=1, count=28, time=1500, loopCount=0 }} )
    starburst.anchorX = 0.5
	starburst.anchorY = 0.5
	starburst.xScale = display.actualContentWidth / starburst.width
	starburst.yScale = display.actualContentHeight / starburst.height
	starburst.x = display.contentCenterX
	starburst.y = display.contentCenterY
	starburst:setSequence( "loop" )
	starburst:play()

    local spriteSheet = graphics.newImageSheet( "images/perryAnim.png", { width=64, height=64, numFrames=22 } )
	scene.character1 = display.newSprite( spriteSheet, {{ name = "idle", start=7, count=16, time=1800, loopCount=0 },{ name = "dash", start=5, count=2, time=150, loopCount=0 }} )
    scene.character1:setSequence( "idle" )
    scene.character1:play()
    scene.character1.anchorX = 0.5
	scene.character1.anchorY = 0.5
	scene.character1.x = scene.badge.x - 75
	scene.character1.y = 500

    spriteSheet = graphics.newImageSheet( "images/donAnim.png", { width=64, height=64, numFrames=53 } )
	scene.character2 = display.newSprite( spriteSheet, {{ name = "idle", start=1, count=29, time=2500, loopCount=0 },{ name = "dash", start=40, count=4, time=320, loopCount=0 }} )
    scene.character2:setSequence( "idle" )
    scene.character2:play()
    scene.character2.anchorX = 0.5
	scene.character2.anchorY = 0.5
	scene.character2.x = scene.badge.x
	scene.character2.y = 500
    
    spriteSheet = graphics.newImageSheet( "images/moleAnim.png", { width=64, height=64, numFrames=33 } )
    scene.character3 = display.newSprite( spriteSheet, {{ name = "idle", start=27, count=7, time=900, loopCount=0 },{ name = "dash", start=1, count=8, time=700, loopCount=0 }} )
    scene.character3:setSequence( "idle" )
    scene.character3:play()
    scene.character3.anchorX = 0.5
	scene.character3.anchorY = 0.5
	scene.character3.x = scene.badge.x + 75
	scene.character3.y = 500
    
    scene.character1.title = display.newImageRect( "images/menu-perry.png", 164, 43 )
    scene.character2.title = display.newImageRect( "images/menu-don.png", 114, 43 )
    scene.character3.title = display.newImageRect( "images/menu-mole.png", 137, 43 )
    
    scene.character1.title.isVisible = false
    scene.character1.title.x = scene.badge.contentBounds.yMax - 75
    scene.character1.title.y = 500
    scene.character2.title.isVisible = false
    scene.character2.title.x = scene.badge.contentBounds.yMax - 75
    scene.character2.title.y = 500
    scene.character3.title.isVisible = false
    scene.character3.title.x = scene.badge.contentBounds.yMax - 75
    scene.character3.title.y = 500
    
    scene.selectText = display.newText( "", 0, 0, "C64 User Mono", 9 )
    scene.selectText:setTextColor(0, 0, 0)
     
    --Change the value of scene.selectText
    scene.selectText.text = "SELECT YOUR CHARACTER"
    scene.selectText.x = scene.badge.x
    scene.selectText.y = 230
    scene.selectText.alpha = 0
    
    
    local fontSize = 8.5
    if ( system.getInfo("platformName") == "Android" ) then
        fontSize = 8.5
    end
    
    
    scene.bodyText = display.newText( "", 0, 0, 420, 0, "C64 User Mono", fontSize)
    scene.bodyText:setTextColor(0, 0, 0)
    scene.bodyText.x = scene.badge.x - 30
    scene.bodyText.y = scene.badge.y - 45
    scene.bodyText.align = "left"
    scene.bodyText.anchorY = 0
    scene.bodyText.anchorX = 0
    
    scene.backButton = display.newImageRect( "images/menu-back.png", 106, 179 )
    scene.backButton.x = display.contentCenterX
    scene.backButton.y = display.contentCenterY
    
    scene.backButton.isVisible = false
    
    scene.playButton = display.newImageRect( "images/menu-play.png", 207, 86 )
    scene.playButton.x = display.contentCenterX
    scene.playButton.y = display.contentCenterY
    scene.playButton.isVisible = false
    scene.badge:toFront()
    
    scene.character1:addEventListener("tap", onSelectPerry)
    scene.character2:addEventListener("tap", onSelectDon)
    scene.character3:addEventListener("tap", onSelectMole)
    
	group:insert( background )
	group:insert( starburst )
	group:insert( scene.badge )
    group:insert( scene.backButton )
	menu:insert( background2 )
    menu:insert( scene.logo )
	menu:insert( scene.selectText )
	menu:insert( scene.character1 )
    menu:insert( scene.character2 )
    menu:insert( scene.character3 )
    menu:insert( scene.character1.title )
    menu:insert( scene.character2.title )
    menu:insert( scene.character3.title )
    menu:insert( scene.playButton )
    
    overlay:insert( gradient )

    local scale = ( 0.95 * display.actualContentHeight ) / scene.badge.height
    local maskY = 8
    if( scale < 1.15 ) then
        scale = 1
    elseif( scale < 1.4 ) then
        scale = 1.25
        maskY = 6
    elseif( scale < 1.5 ) then
        scale = 1.5
    else
        scale = 1
    end
    scene.backButton.scale = scale
    
	menu.anchorChildren = true
    menu.xScale = scale
    menu.yScale = scale
    menu.x = display.contentCenterX
    menu.y = display.contentCenterY + 140
    scene.badge.xScale = menu.xScale
    scene.badge.yScale = menu.xScale

    scene.attractTimer = timer.performWithDelay( 250, showFirstScreen )

    scene.attractTimer = timer.performWithDelay( 20000, AttractMode )

    scene.character1:addEventListener( "sprite", perrySpriteListener )
    scene.character2:addEventListener( "sprite", donSpriteListener )
    
        storyboard.state.bHighScoreShown = false
        if( scene.data and math.random(3) > 1 and system.getInfo("environment") ~= "simulator" and not storyboard.state.bPlayedWelcomeBack ) then
            if( scene.data.highScore > 0 ) then
                local voice = audio.loadSound( "sounds/voice-maryJaneWelcomeBack.wav" )
                audio.play( voice, { channel=2 })
            end
        end
        storyboard.state.bPlayedWelcomeBack = true

	
   if( not storyboard.state.isOtherAudioPlaying ) then
        scene.music = audio.loadStream( "sounds/big3music.mp3" )
        scene.musicChannel = audio.play( scene.music, { channel=1, loops=0, fadein=100 } )
        audio.fade( { channel=1, time=100, volume=1 } )
   end
   
   local function tapPlaybutton()
            if( selectedCharacter ) then
                playGame( selectedCharacter )
            end
        end
        
        local function tapBackbutton()
            if( selectedCharacter and ( system.getTimer() - mCharScreenTime > 500 ) ) then
                showFirstScreen( selectedCharacter )
            end
        end
        
        scene.playButton:addEventListener("tap",tapPlaybutton )
        scene.backButton:addEventListener("tap",tapBackbutton )
end

-- Called when scene is about to move offscreen:
function scene:exitScene( event )
    if( animateTextTimer ) then
        timer.cancel( animateTextTimer )
        animateTextTimer = nil
    end

    storyboard.state.score = 0
    
    scene.bodyText:removeSelf()
    if( scene.playButton and scene.playButton.removeSelf ) then
        scene.playButton:removeSelf()
    end
    
    if( scene.character1.title and scene.character1.title.removeSelf ) then
      scene.character1.title:removeSelf()
      scene.character2.title:removeSelf()
      scene.character3.title:removeSelf()
    end
    
    scene.character1 = nil
    scene.character2 = nil
    scene.character3 = nil
    
    display.remove( group )
    display.remove( menu )
    display.remove( overlay )
    
    group = nil
    menu = nil
    overlay = nil
    
    save()
    
    if( scene.music ) then
        audio.stop( scene.musicChannel )
        audio.dispose( scene.music )
    end
    scene.music = nil
    scene.musicChannel = nil

    storyboard.removeScene( "splashScreen" )
    storyboard.removeScene( "perryPieTime" )
    storyboard.removeScene( "whoDatLady" )
    storyboard.removeScene( "jokeyTime" )
    
    storyboard.removeScene( "menu" )
	storyboard.purgeScene( "menu" )
end

function scene:destroyScene( event )
    scene = nil
end

scene:addEventListener( "createScene", scene )
scene:addEventListener( "enterScene", scene )
scene:addEventListener( "exitScene", scene )
scene:addEventListener( "destroyScene", scene )

return scene