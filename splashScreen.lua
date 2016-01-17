-----------------------------------------------------------------------------------------
--
--
-----------------------------------------------------------------------------------------

-- Turn off image smoothing. So that pixel art looks awesome.
display.setDefault( "magTextureFilter", "nearest" )
display.setDefault( "minTextureFilter", "nearest" )

local scene = storyboard.newScene()
local group = display.newGroup()
addDisplayGroup( group )

local text = nil

local function finish()
    storyboard.gotoScene( "menu" )
end


function scene:createScene( event )
    local leftEdge = 0 - ( ( display.actualContentWidth - display.contentWidth ) / 2 )
    local topEdge = 0 -  ( ( display.actualContentHeight - display.contentHeight ) / 2 )

	-- Set background color
    display.setDefault( "background", 0, 0, 0 )
    
    local background = display.newRect(leftEdge, topEdge, display.actualContentWidth, display.actualContentHeight)
    background:setFillColor(0, 0, 0)
    background.alpha = 0
    background.anchorX = 0
    background.anchorY = 0
    background.blendMode = "multiply"

	local gradient = display.newImageRect( "images/splashScreen_bg.png", 480, 270 )
	gradient.x = display.contentCenterX
	gradient.y = display.contentCenterY
	
	gradient.yScale = display.actualContentHeight / gradient.height
    gradient.xScale = gradient.yScale
    
	
    local flagSheet = graphics.newImageSheet( "images/americanFlagAnim.png", { width=103, height=105, numFrames=54 } )
    local flag = display.newSprite( flagSheet, {{ name = "loop", start=1, count=54, time=3000, loopCount=0 }} )
    flag.xScale = gradient.xScale
    flag.yScale = gradient.yScale
    flag.x = 244
    flag.y = 130
	flag:setSequence( "loop" )
    flag:play() 
    
    local tim = display.newImageRect( "images/splashScreen_tim.png", 99, 99 )
	tim.x = display.contentCenterX
	tim.y = display.contentCenterY
	
	tim.yScale = gradient.xScale
    tim.xScale = gradient.xScale
    tim.x = 241
    tim.y = 134
    
    local timShadow = display.newImageRect( "images/splashScreen_timShadow.png", 99, 150 )
	timShadow.x = display.contentCenterX
	timShadow.y = display.contentCenterY
	
	timShadow.yScale = gradient.xScale
    timShadow.xScale = gradient.xScale
    timShadow.x = tim.x + 5
    timShadow.y = tim.y + 5
    timShadow.blendMode = "multiply"
    timShadow.alpha = 0.5
    
    text = display.newImageRect( "images/splashScreen_text.png", 334, 25 )
	text.x = display.contentCenterX
	text.y = display.contentCenterY
	
	text.yScale = 1
    text.xScale = 1
    text.x = display.contentWidth/2
    text.y = display.contentHeight/1.2
    text.alpha = 0
    
    copyright = display.newImageRect( "images/copyright.gif", 350, 52 )
	copyright.x = display.contentCenterX
	copyright.y = display.contentCenterY
	copyright.alpha = 0
    
    transition.to( text, { time=1500, delay=1000, alpha=1, transition=easing.inExpo } )
    transition.to( tim, { time=3500, delay=3500, alpha=0, transition=easing.inOutQuad } )
    transition.to( background, { time=2000, delay=9000, alpha=1, transition=easing.inOutQuad } )
    transition.to( copyright, { time=1000, delay=11000, alpha=1} )
    
    transition.to( copyright, { time=1000, delay=14000, alpha=0, transition=easing.inOutQuad } )
    
    group:insert( flag )
    group:insert( timShadow )
    group:insert( tim )
    group:insert( gradient )
    group:insert( text )
    group:insert( background )
    timer.performWithDelay(1/15, update, -1)
    timer.performWithDelay(16000, finish )
end


function scene:exitScene( event )
    group:removeSelf()
    group = nil
end

function scene:destroyScene( event )

end

scene:addEventListener( "createScene", scene )
scene:addEventListener( "enterScene", scene )
scene:addEventListener( "exitScene", scene )
scene:addEventListener( "destroyScene", scene )

-----------------------------------------------------------------------------------------

return scene