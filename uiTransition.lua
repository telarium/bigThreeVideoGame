local displayGroup = nil
local transition = nil

local UITransition = {

}



function UITransition:execute(scene, delay)
	local sceneToLoad = scene
    
    if( not delay ) then
        delay = 0
    end
    
	local mySpriteListener = function( event )

	  if ( event.phase == "ended" ) then
		   transition:removeSelf()
		   transition = nil
		   display.remove( displayGroup )
		   displayGroup = nil
          
           if( UIEndScreen_Remove ) then
                UIEndScreen_Remove()
           end
           
           display.remove( self.view )
		   removeDisplayGroups()
		   
		   storyboard.purgeAll()
		   storyboard.removeAll()
           
		   --local newScene = storyboard.loadScene( sceneToLoad, true )
		   storyboard.gotoScene( sceneToLoad )
	  end
	end

    
    displayGroup = display.newGroup()
    addDisplayGroup( displayGroup )
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    local spriteSheet = graphics.newImageSheet( "images/transitionAnim.png", { width=240, height=135, numFrames=25 } )
    transition = display.newSprite( spriteSheet, {{ name = "sequence", start=1, count=25, time=900, loopCount=1 }} )
    transition.x = display.contentCenterX
    transition.y = display.contentCenterY
    transition.yScale = display.actualContentHeight / transition.height
    transition.xScale = transition.yScale
    transition.anchorX = 0.5
	transition.anchorY = 0.5
    transition.alpha = 0.001
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" ) 
    displayGroup:toFront()
    
    local go = function()        
        transition:setSequence( "sequence" )
        transition:play()
        transition.alpha = 1
        displayGroup:insert( transition )
        transition:addEventListener( "sprite", mySpriteListener )
    end
    timer.performWithDelay( delay, go )
end


return UITransition;