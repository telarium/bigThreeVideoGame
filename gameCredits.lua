----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script controls end credits scene.

local storyboard = require( "storyboard" )
local scene = storyboard.newScene()

local GA = require ( "GameAnalytics" )

local leftEdge = 0 - ( ( display.actualContentWidth - display.contentWidth ) / 2 )
local rightEdge = display.contentWidth + ( ( display.actualContentWidth - display.contentWidth ) / 2 )
local bottomEdge = display.contentHeight + ( ( display.actualContentHeight - display.contentHeight ) / 2 )
local topEdge = 0 -  ( ( display.actualContentHeight - display.contentHeight ) / 2 )

local displayGroup = nil
local creditsGroup = nil

local creditsText = "designed, programmed, & produced by\nANDREW LANGLEY"
creditsText = creditsText .. "\n\nbased on the comedy of\nDON BARRIS\nWALTER “MOLE” MOLINSKI\nPERRY KARAVELLO"
creditsText = creditsText .. "\n\nexecutive producer\nJOHN QUINCY ADAMS"
creditsText = creditsText .. "\n\nstarring\nDON BARRIS\nMOLE\nPERRY CARAMELLO\nMARY JANE GREENE\nJOHN QUINCY ADAMS\nVINCE FREEMAN"
creditsText = creditsText .. "\n\nart, animation, & computergraphs by\nANDREW LANGLEY\nKELLY ROBOTOSON"
creditsText = creditsText .. "\n\nsound design by\nANDREW LANGLEY \nFREESOUND.ORG"
creditsText = creditsText .. "\n\nlegal services by\nSOL STEINBERGOWITZGREENBAUM"
creditsText = creditsText .. "\n\ncatering by\nBURT WARD"
creditsText = creditsText .. "\n\nperry’s hair styled by\nSHEILA FALCONI"
creditsText = creditsText .. "\n\ntoaster appears courtesy of\nTHE TOASTER in HARDY, ARKANSAS"
creditsText = creditsText .. "\n\nspecial thanks\nDON BARRIS\nT.B.\nMARY JANE GREENE\nRUCKA RUCKA ALI\nCLETO & THE CLETONES\nJEFF SCHWEIKART\nCORONA LABS\nNICOLE PEREZ\nALEXANDRA ALQUATI\nBOBCAT GOLDTHWAIT\nJIMMY KIMMEL\n& ALL THE BIG 3 FANS!"
creditsText = creditsText .. "\n\ndedicated to\nCOOKIE, NATHANIEL & JUANDEZ"
creditsText = creditsText .. "\n\n(c)2025 LANGLEY CREATIONS \n& SIMPLY DON - THE PODCAST NETWORK"
creditsText = creditsText .. "\n\nno dogs were harmed\nduring the making of this game"
creditsText = creditsText .. "\n\n\nwww.thebig3podcast.com\n#itAintQuittin"


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

local function gameLoop()
    if( not myScene.endTime ) then
       myScene.startTime = system.getTimer()
       myScene.endTime = 0
    end
    myScene.endTime = ( system.getTimer() - myScene.startTime )
    
    myScene.perc = ( myScene.endTime / 63000 ) * 100
   
   
   creditsGroup.y = -110 + ( myScene.perc * ( myScene.height ) / 100 ) * -1
   if( myScene.perc > 100) then
        storyboard.gotoScene( "menu" )
   end
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    

    scene.comedy = audio.loadStream( "sounds/credits.mp3" )
    scene.soundChannel = audio.play( scene.comedy, { channel=2, loops=0 } )
    myScene = scene
    
    displayGroup = display.newGroup()
    creditsGroup = display.newGroup()
    
    addDisplayGroup( displayGroup )
    addDisplayGroup( creditsGroup )
    
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
    --displayGroup:insert( scene.bg )

	scene.bg:setSequence( "loop" )
	scene.bg:play()
    
    scene.creditsObject,  scene.creditsObjectShadow = makeText( creditsText, 10, display.contentCenterX, display.contentCenterY+600 )

    creditsGroup:insert( scene.creditsObjectShadow )
    creditsGroup:insert( scene.creditsObject )

    
    local curtainSheet = graphics.newImageSheet( "images/curtainsAnim2.png", { width=328, height=184, numFrames=24} )
    scene.curtain = display.newSprite( curtainSheet, {{ name = "loop", start=1, count=23, time=1300, loopCount=1 }} )
    scene.curtain.anchorX = 0.5
	scene.curtain.anchorY = 0.5
	scene.curtain.xScale = display.actualContentWidth / scene.curtain.width * 1.1
	scene.curtain.yScale = display.actualContentHeight / scene.curtain.height * 1.1
	scene.curtain.x = display.contentCenterX
	scene.curtain.y = display.contentCenterY
    displayGroup:insert( scene.curtain )
    
    local delay = function()
    
        scene.exitButton = display.newImage("images/creditsClose.png");
        scene.exitButton.x = rightEdge - 15
        scene.exitButton.y = topEdge + 15
        scene.exitButton.blendMode = "add"
        scene.exitButton.alpha = 0
        transition.to( scene.exitButton, { time=2000, delay=0, alpha=0.275, transition=easing.outExpo} )
        
        local exit = function()
            storyboard.gotoScene( "menu" )
        end
        
        scene.exitButton:addEventListener( "touch", exit )
        
        displayGroup:insert( scene.exitButton )
    end
    local myTimer = timer.performWithDelay( 2000, delay )

	scene.curtain:setSequence( "loop" )
	
        
    GA.newEvent( "design", { event_id="credits" })
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
    
        
    local oaklandLogo = display.newImageRect( "images/madeInOakland.png", 350, 313 )
    oaklandLogo.anchorY = 0
    oaklandLogo.x = display.contentCenterX
    oaklandLogo.y = creditsGroup.contentBounds.yMax + 30
    oaklandLogo.xScale = 0.35
    oaklandLogo.yScale = 0.35
    creditsGroup:insert( oaklandLogo )
    creditsGroup:toFront()
    displayGroup:toFront()
    
   
    creditsGroup.anchorY = 0
    creditsGroup.y = -110
   
    
    local startLoop = function()    
        myScene.perc = 0
        myScene.height = creditsGroup.contentBounds.yMax
        Runtime:addEventListener( "enterFrame", gameLoop )
        scene.curtain:play()
    end
    timer.performWithDelay( 800, startLoop )
end


function scene:exitScene( event )
	Runtime:removeEventListener( "enterFrame", gameLoop )
    myScene.endTime = nil
    myScene.height = nil
    myScene.perc = nil
    
    audio.stop( scene.soundChannel )
    audio.dispose( scene.comedy )
    scene.comedy = nil
    
    scene.curtain:removeSelf()
    scene.curtain = nil
    
    scene.exitButton:removeSelf()
    scene.exitButton = nil
    
    scene.bg:removeSelf()
    scene.bg = nil
    
	displayGroup:removeSelf()
    displayGroup = nil
    creditsGroup:removeSelf()
    creditsGroup = nil
    myScene = nil
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