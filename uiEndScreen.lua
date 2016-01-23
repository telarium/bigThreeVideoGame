----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script UI for the player result (current score, high score, etc)

local myScene = nil
local bTransition = nil
require( "fileStorage" )

local leftEdge = 0 - ( ( display.actualContentHeight - display.contentWidth ) / 2 )
local rightEdge = display.contentWidth + ( ( display.actualContentHeight - display.contentWidth ) / 2 )
local bottomEdge = display.contentHeight + ( ( display.actualContentWidth - display.contentHeight ) / 2 )
local topEdge = 0 -  ( ( display.actualContentWidth - display.contentHeight ) / 2 )

local perryLeaderboard = "perryHighScore"
local moleLeaderboard = "moleHighScore"
local donLeaderboard = "donHighScore"
local overallLeaderboard = "overallHighScore"

if ( system.getInfo("platformName") == "Android" ) then
	perryLeaderboard = "CgkIhf7UyIMOEAIQAA"
	moleLeaderboard = "CgkIhf7UyIMOEAIQAQ"
	donLeaderboard = "CgkIhf7UyIMOEAIQAg"
	overallLeaderboard = "CgkIhf7UyIMOEAIQAw"
end

local function goToMenu()
    if( bTransition ) then
        return
    end
    
    bTransition = true
    save(true)
    uiTransition:execute( "menu" )
end

local function goToPieTime()
    if( bTransition ) then
        return
    end
    bTransition = true
    uiTransition:execute( "perryPieTime" )
end

local function goWhoDatLady()
    if( bTransition ) then
        return
    end
    bTransition = true
    uiTransition:execute( "whoDatLady" )
end

local function goToJokeyTime()
    if( bTransition ) then
        return
    end
    bTransition = true
    uiTransition:execute( "jokeyTime" )
end


local function viewCredits()
    if( bTransition ) then
        return
    end
    bTransition = true
    uiTransition:execute( "gameCredits" )
end

local function setCreditsButton(scene, scoreText )
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    scene.creditsButton = display.newImageRect( "images/badge-credits.png", 210, 45 )
    scene.uiEndScreenDisplayGroup:insert(scene.creditsButton )
    scene.creditsButton.x = display.contentCenterX
    scene.creditsButton.y = scene.uiEndScreenBadge.y + 70
    scene.creditsButton:addEventListener("tap", viewCredits)
    
    scene.replayButton = display.newImageRect( "images/badge-replay.png", 210, 19 )
    scene.uiEndScreenDisplayGroup:insert( scene.replayButton )
    scene.replayButton.x = scene.creditsButton.x
    scene.replayButton.y = scene.creditsButton.y - 35
    scene.replayButton:addEventListener("tap", goToMenu)


    
    local scoreTransition = transition.to( scoreText, { time=250, delay=0, y=scoreText.y - 35, transition=easing.outExpo } )
end


local function showHighScore(scene,scoreText,accuracyText,func)
    local data = loadTable()
    local timeToWait = 4000
    local bPlayBonus = false
    local bShowCredits = false

    if( data.bPlayedPerry and data.bPlayedMole and data.bPlayedDon ) then
        local achievement = "CgkIhf7UyIMOEAIQBg"
        if ( system.getInfo("platformName") == "iPhone OS" ) then 
            achievement = "big3"
        end
        gameNetwork.request( "unlockAchievement", { achievement = { identifier=achievement, percentComplete=100, showsCompletionBanner=true } } )
    end
    
    if( not accuracyText ) then
        bShowCredits = true
       local options = 
        {
            --parent = textGroup,
            text = "",     
            x = scene.uiEndScreenBadge.x,
            y = scene.uiEndScreenBadge.y + 50,
            width = 250,     --required for multi-line and alignment
            font = "C64 User Mono",   
            fontSize = 10,
            align = "center"  --new alignment parameter
        }
        accuracyText = display.newText( options )
        accuracyText:setFillColor(0, 0, 0)
        scene.uiEndScreenDisplayGroup:insert(accuracyText )
        
    else
        bPlayBonus = true
    end

    --storyboard.state.score = data.highScore + 1

    if( storyboard.state.score > data.highScore ) then
        if( not storyboard.state.bHighScoreShown ) then
            
            scoreText.y = scene.uiEndScreenBadge.y + 5
            if( gameNetwork ) then
                    gameNetwork.request( "setHighScore", 
                    {
                    localPlayerScore = { category=overallLeaderboard, value=data.highScore },
                    })
            end
            if( data.highScore > 0 ) then
                storyboard.state.bHighScoreShown = true
                data.highScore = storyboard.state.score
                accuracyText.text = "NEW HIGH SCORE!!!\n#itaintquittin"
                timeToWait = 6500
                
                display.setDefault( "magTextureFilter", "nearest" )
                display.setDefault( "minTextureFilter", "nearest" )
                
                
                local img = "images/maryJane1.png"
                if( scene:getSelectedCharacter() == "perry" ) then
                    img = "images/maryJane2.png"
                end
                
                scene.maryJane = display.newImageRect( img, 417, 320 )
                
                local playMusic = function()
                    local music = audio.loadSound( "sounds/highScore.wav" )
                    audio.play( music, { channel=2 } )
                    audio.setVolume( 1, { channel=2 } )
                end
                
                local playVoice = function()
                    local voice = nil
                    audio.setVolume( 1, { channel=3 } )
                    if( math.random(3)==1 ) then
                        voice = audio.loadSound( "sounds/voice-maryJaneScore2.wav" )
                    else
                        voice = audio.loadSound( "sounds/voice-maryJaneScore1.wav" )
                   end
                   audio.play( voice, { channel=4 } )
                end
                
                

                timer.performWithDelay( 500, playMusic )
                timer.performWithDelay( 1000+math.random(500), playVoice )
                                
                scene.maryJane.anchorX = 0.5
                scene.maryJane.anchorY = 1
                scene.maryJane.x = display.contentCenterX + 500
                scene.maryJane.y = display.contentHeight + ( ( display.actualContentHeight - display.contentHeight ) / 2 )
                
                transition.to( scene.uiEndScreenDisplayGroup, { time=750, delay=500, y=display.contentCenterY, transition=easing.outExpo } )
                transition.to( scene.uiEndScreenDisplayGroup, { time=750, delay=500, x=display.contentCenterX - 340, transition=easing.outExpo } )
                transition.to( scene.maryJane, { time=300, delay=500, x=display.contentCenterX + 140, transition=easing.outExpo } )
           
           else
                storyboard.state.bHighScoreShown = true
            end
                
            save(true,data)
        end
    else
        
        if( storyboard.state.character == "perry" ) then
            if( storyboard.state.score > data.perryHighScore ) then
                if( not storyboard.state.bHighScoreShown ) then
                    bShowCredits = false
                    storyboard.state.bHighScoreShown = true
                    if( data.perryHighScore > 0 ) then
                        accuracyText.text = "NEW PERRY HIGH SCORE!\nOLD SCORE: " .. tostring( data.perryHighScore )
                        timeToWait = 5000
                    end
                end
                data.perryHighScore = storyboard.state.score
                if( gameNetwork ) then
                    gameNetwork.request( "setHighScore", 
                    {
                    localPlayerScore = { category=perryLeaderboard, value=data.perryHighScore },
                    })
                end
                save(true,data)
            end
        elseif( storyboard.state.character == "mole" ) then
            if( storyboard.state.score > data.moleHighScore ) then
                if( not storyboard.state.bHighScoreShown ) then
                    bShowCredits = false
                    storyboard.state.bHighScoreShown = true
                    if( data.moleHighScore > 0 ) then
                        accuracyText.text = "NEW MOLE HIGH SCORE!\nOLD SCORE: " .. tostring( data.moleHighScore )
                        timeToWait = 5000
                    end
                end
                data.moleHighScore = storyboard.state.score
                if( gameNetwork ) then
                    gameNetwork.request( "setHighScore", 
                    {
                    localPlayerScore = { category=moleLeaderboard, value=data.moleHighScore },
                    })
                end
                save(true,data)
            end
        else
            if( storyboard.state.score > data.donHighScore ) then
                if( not storyboard.state.bHighScoreShown ) then
                    storyboard.state.bHighScoreShown = true
                    bShowCredits = false
                    if( data.donHighScore > 0 ) then
                        accuracyText.text = "NEW DON HIGH SCORE!\nOLD SCORE: " .. tostring( data.donHighScore )
                        timeToWait = 5000
                    end
                end
                data.donHighScore = storyboard.state.score
                if( gameNetwork ) then
                    gameNetwork.request( "setHighScore", 
                    {
                    localPlayerScore = { category= donLeaderboard, value=data.donHighScore },
                    })
                end
                save(true,data)
            end
        end

        if( bShowCredits ) then
            setCreditsButton( scene, scoreText )
            timeToWait = timeToWait + 1000
        end
    end
    
    if( bPlayBonus ) then
        local playBonusRound = function()
            audio.setVolume( 1, { channel=1 } )
            local voice = audio.loadSound( "sounds/voice-maryJaneBonus.wav" )
            if( not storyboard.state.bPlayedJokeyTime or not storyboard.state.bPlayedWhoDatLady or not storyboard.state.bPlayedPieTime ) then
            
                audio.play(voice, { channel=1 } )
            elseif( math.random(2)==1 ) then
                audio.play(voice, { channel=1 } )
            end
        end
        timer.performWithDelay( timeToWait - 2000, playBonusRound )
    end

    func(timeToWait)
end


local function showJokeyTime(scene)
        if( not storyboard.state.score ) then
            storyboard.state.score = 0
        end
        local options = 
        {
            --parent = textGroup,
            text = "JOKE BONUS\n+"..tostring( scene.jokeyTimePoints ).." points",     
            x = scene.uiEndScreenBadge.x,
            y = scene.uiEndScreenBadge.y - 45,
            width = 250,     --required for multi-line and alignment
            font = "C64 User Mono",   
            fontSize = 13,
            align = "center"  --new alignment parameter
        }

        
        local myText = display.newText( options )
        myText:setFillColor(0, 0, 0)
        scene.uiEndScreenDisplayGroup:insert(myText )
        
        local options = 
        {
            --parent = textGroup,
            text = tostring( storyboard.state.score ),     
            x = scene.uiEndScreenBadge.x,
            y = scene.uiEndScreenBadge.y + 30,
            width = 250,     --required for multi-line and alignment
            font = "C64 User Mono",   
            fontSize = 35,
            align = "center"  --new alignment parameter
        }
        local scoreText = display.newText( options )
        scoreText:setFillColor(0, 0, 0)
        scene.uiEndScreenDisplayGroup:insert(scoreText )
        local scoreTimer = nil
        
        local function finish(delay)
            timer.performWithDelay( delay, goToMenu, 1 )
        end
        
        local bPlayChaChing = false
        
         local skipScore = function()
            storyboard.state.score = storyboard.state.score + scene.jokeyTimePoints
            scene.jokeyTimePoints = 0
        end
        
        local function animateScore()
            transition.to( scene.uiEndScreenDisplayGroup, { time=300, delay=0, y=display.contentCenterY, transition=easing.outExpo } )
            if( scene.jokeyTimePoints > 0 ) then
                scene.jokeyTimePoints = scene.jokeyTimePoints - 1
                storyboard.state.score = storyboard.state.score + 1
            end
            scoreText.text = tostring( storyboard.state.score )
            myText.text = "JOKE BONUS\n+"..tostring( scene.jokeyTimePoints ).." points"
            if( scene.jokeyTimePoints <= 0 )then
                timer.cancel( scoreTimer )
                if( bPlayChaChing == true ) then
                    audio.fadeOut( { channel=2, time=300 } )
                    audio.play( scene.chaChingSound, { channel=1 } )
                end
                scene.bg:removeEventListener( "touch", skipScore )
                myText.text = "JOKE BONUS\n  "
                storyboard.state.bPlayedJokeyTime = true
                showHighScore(scene,scoreText,nil,finish)
            end
        end
        
       
        
        local function initialDelay()
            scoreTimer = timer.performWithDelay( 10, animateScore, 0 )
            scene.bg:addEventListener( "touch", skipScore )
        end
        
        if( scene.jokeyTimePoints > 0 ) then
            bPlayChaChing = true
            audio.play( scene.pointsSound, { channel=2 } )
        end
        timer.performWithDelay( 1000, initialDelay, 1 )
end


local function showPieTime(scene)
        local options = 
        {
            --parent = textGroup,
            text = "PIE TIME BONUS\n+"..tostring( scene.piePoints ).." points",     
            x = scene.uiEndScreenBadge.x,
            y = scene.uiEndScreenBadge.y - 45,
            width = 250,     --required for multi-line and alignment
            font = "C64 User Mono",   
            fontSize = 13,
            align = "center"  --new alignment parameter
        }

        
        local myText = display.newText( options )
        myText:setFillColor(0, 0, 0)
        scene.uiEndScreenDisplayGroup:insert(myText )
        
        local options = 
        {
            --parent = textGroup,
            text = tostring( storyboard.state.score ),     
            x = scene.uiEndScreenBadge.x,
            y = scene.uiEndScreenBadge.y + 30,
            width = 250,     --required for multi-line and alignment
            font = "C64 User Mono",   
            fontSize = 35,
            align = "center"  --new alignment parameter
        }
        local scoreText = display.newText( options )
        scoreText:setFillColor(0, 0, 0)
        scene.uiEndScreenDisplayGroup:insert(scoreText )
        local scoreTimer = nil
        
        local function finish(delay)
            timer.performWithDelay( delay, goToMenu, 1 )
        end
        
        local skipScore = function()
            storyboard.state.score = storyboard.state.score + scene.piePoints
            scene.piePoints = 0
        end
        
        local bPlayChaChing = false
        
        if( not storyboard.state.score ) then
            storyboard.state.score = 0
        end
        
        local function animateScore()
            transition.to( scene.uiEndScreenDisplayGroup, { time=300, delay=0, y=display.contentCenterY, transition=easing.outExpo } )
            if( scene.piePoints > 0 ) then
                scene.piePoints = scene.piePoints - 1
                storyboard.state.score = storyboard.state.score + 1
            end
            scoreText.text = tostring( storyboard.state.score )
            myText.text = "PIE TIME BONUS\n+"..tostring( scene.piePoints ).." points"
            if( scene.piePoints <= 0 )then
                audio.fadeOut( { channel=2, time=300 } )
                if( bPlayChaChing == true ) then
                    audio.fadeOut( { channel=2, time=300 } )
                    audio.play( scene.chaChingSound, { channel=1 } )
                end
                timer.cancel( scoreTimer )
                myText.text = "PIE TIME BONUS\n  "
                storyboard.state.bPlayedPieTime = true
                showHighScore(scene,scoreText,nil,finish)
                scene.bg:removeEventListener( "touch", skipScore )
            end
        end
        
        local function initialDelay()
            scoreTimer = timer.performWithDelay( 10, animateScore, 0 )
        end
        if( scene.piePoints > 0 ) then
            bPlayChaChing = true
            audio.play( scene.pointsSound, { channel=2 } )
        end
        
        scene.bg:addEventListener( "touch", skipScore )
        
        timer.performWithDelay( 1000, initialDelay, 1 )
end

local function showWhoDatLady(scene)
        local options = 
        {
            --parent = textGroup,
            text = "LADY BONUS\n+"..tostring( scene.whoDatLadyPoints ).." points",     
            x = scene.uiEndScreenBadge.x,
            y = scene.uiEndScreenBadge.y - 45,
            width = 250,     --required for multi-line and alignment
            font = "C64 User Mono",   
            fontSize = 13,
            align = "center"  --new alignment parameter
        }

        
        local myText = display.newText( options )
        myText:setFillColor(0, 0, 0)
        scene.uiEndScreenDisplayGroup:insert(myText )
        
        local options = 
        {
            --parent = textGroup,
            text = tostring( storyboard.state.score ),     
            x = scene.uiEndScreenBadge.x,
            y = scene.uiEndScreenBadge.y + 30,
            width = 250,     --required for multi-line and alignment
            font = "C64 User Mono",   
            fontSize = 35,
            align = "center"  --new alignment parameter
        }
        local scoreText = display.newText( options )
        scoreText:setFillColor(0, 0, 0)
        scene.uiEndScreenDisplayGroup:insert(scoreText )
        local scoreTimer = nil
        
        local function finish(delay)
            timer.performWithDelay( delay, goToMenu, 1 )
        end
        
        local bPlayChaChing = false
        
        if( not storyboard.state.score ) then
            storyboard.state.score = 0
        end
        
        local skipScore = function()
            storyboard.state.score = storyboard.state.score + scene.whoDatLadyPoints
            scene.whoDatLadyPoints = 0
        end
        
        local function animateScore()
            transition.to( scene.uiEndScreenDisplayGroup, { time=300, delay=0, y=display.contentCenterY, transition=easing.outExpo } )
            if( scene.whoDatLadyPoints > 0 ) then
                scene.whoDatLadyPoints = scene.whoDatLadyPoints - 1
                storyboard.state.score = storyboard.state.score + 1
            end
            scoreText.text = tostring( storyboard.state.score )
            myText.text = "LADY BONUS\n+"..tostring( scene.whoDatLadyPoints ).." points"
            if( scene.whoDatLadyPoints <= 0 )then
                audio.fadeOut( { channel=2, time=300 } )
                if( bPlayChaChing == true ) then
                    audio.fadeOut( { channel=2, time=300 } )
                    audio.play( scene.chaChingSound, { channel=1 } )
                end
                scene.bg:removeEventListener( "touch", skipScore )
                timer.cancel( scoreTimer )
                myText.text = "LADY BONUS\n  "
                storyboard.state.bPlayedWhoDatLady = true
                showHighScore(scene,scoreText,nil,finish)
            end
        end
        
        local function initialDelay()
            scoreTimer = timer.performWithDelay( 10, animateScore, 0 )
            scene.bg:addEventListener( "touch", skipScore )
        end
        
        if( scene.whoDatLadyPoints > 0 ) then
            bPlayChaChing = true
            audio.play( scene.pointsSound, { channel=2 } )
        end
        
        timer.performWithDelay( 1000, initialDelay, 1 )
end

                

local function showChicago(scene)
        local options = 
        {
            --parent = textGroup,
            text = "CITY OF BROKEN SHOULDERS\n ",     
            x = scene.uiEndScreenBadge.x,
            y = scene.uiEndScreenBadge.y - 45,
            width = 250,     --required for multi-line and alignment
            font = "C64 User Mono",   
            fontSize = 13,
            align = "center"  --new alignment parameter
        }

        
        local myText = display.newText( options )
        myText:setFillColor(0, 0, 0)
        scene.uiEndScreenDisplayGroup:insert(myText )
        
        local options = 
        {
            --parent = textGroup,
            text = tostring( storyboard.state.score ),     
            x = scene.uiEndScreenBadge.x,
            y = scene.uiEndScreenBadge.y + 5,
            width = 250,     --required for multi-line and alignment
            font = "C64 User Mono",   
            fontSize = 30,
            align = "center"  --new alignment parameter
        }
        local scoreText = display.newText( options )
        scoreText:setFillColor(0, 0, 0)
        scene.uiEndScreenDisplayGroup:insert(scoreText )
        
        local accuracy = ( scene.weapons.totalHit / scene.weapons.totalFired ) * 100
       
        if( not scene.weapons.totalFired or scene.weapons.totalFired == 0 ) then
            accuracy = 0
        end
        accuracy = math.floor( accuracy + 0.5 )
         if( accuracy > 100 ) then
        	accuracy = 100
        end

        GA.newEvent( "design", { event_id="chicago:shotAccuracy", area="main", value=accuracy})
        
        if( accuracy < 0 ) then
            accuracy = 0
        end
        
        local options = 
        {
            --parent = textGroup,
            text = tostring( accuracy ) .. "% SHOT ACCURACY BONUS",     
            x = scene.uiEndScreenBadge.x,
            y = scene.uiEndScreenBadge.y + 50,
            width = 250,     --required for multi-line and alignment
            font = "C64 User Mono",   
            fontSize = 10,
            align = "center"  --new alignment parameter
        }
        local accuracyText = display.newText( options )
        accuracyText:setFillColor(0, 0, 0)
        scene.uiEndScreenDisplayGroup:insert(accuracyText )
        accuracyText.isVisible = false
        
        local showAccuracy = function()
            accuracyText.isVisible = true
        end
        
        local wait = system.getTimer() + 3000
        
        local bonusGame = table.remove( storyboard.state.bonusPlaylist, 1 )
        table.insert( storyboard.state.bonusPlaylist, bonusGame )
        
        local animate = nil
        
        local goToBonus = function(delay)
            if( bonusGame == "perryPieTime" ) then
                    timer.performWithDelay( delay, goToPieTime, 1  )
                elseif( bonusGame == "jokeyTime" ) then
                    timer.performWithDelay( delay, goToJokeyTime, 1  )
                else
                    timer.performWithDelay( delay, goWhoDatLady, 1 )
            end
        end
        local bPlayChaChing = false
        
        local animatedAccuracy = function( event)
            transition.to( scene.uiEndScreenDisplayGroup, { time=300, delay=0, y=display.contentCenterY, transition=easing.outExpo } )
            if( system.getTimer() >= wait and accuracy > 0 ) then
                accuracy = accuracy - 1
                storyboard.state.score = storyboard.state.score + 10
                scoreText.text = tostring( storyboard.state.score )
                accuracyText.text = tostring( accuracy ) .. "% SHOT ACCURACY BONUS"
            end
            if( accuracy <= 0 ) then
                accuracyText.text = ""
                accuracyText.text = tostring( accuracy ) .. "% SHOT ACCURACY BONUS"
                timer.cancel( event.source )
                if( bPlayChaChing == true ) then
                    audio.fadeOut( { channel=2, time=300 } )
                    audio.play( scene.chaChingSound, { channel=3 } )
                end
                audio.fadeOut( { channel=2, time=300 } )
                showHighScore(scene,scoreText,accuracyText,goToBonus)
            end
        end
        
        timer.performWithDelay( 1000, showAccuracy )
        
        
        if( accuracy > 0 ) then
            bPlayChaChing = true
            local soundDelay = function()
                audio.play( scene.pointsSound, { channel=2 } )
            end
            timer.performWithDelay( 1500, soundDelay  )
        end
        
        timer.performWithDelay( 25, animatedAccuracy, -1 )
end

function UIEndScreen_Remove()
    audio.setVolume( 1, { channel=2 } )
    if( myScene ) then
        if( myScene.creditsButton ) then
            myScene.creditsButton:removeEventListener("tap", viewCredits)
        end
        
        if( myScene.replayButton ) then
            myScene.replayButton:removeEventListener("tap", goToMenu)
        end

        if( myScene.maryJane ) then
            myScene.maryJane:removeSelf()
        end
        
        myScene.maryJane = nil
        
        if( myScene.pointsSound ) then
            audio.dispose( myScene.pointsSound )
            audio.dispose( myScene.chaChingSound )
            myScene.pointsSound = nil
            myScene.chaChingSound = nil
        end
        
        display.remove( myScene.uiEndScreenDisplayGroup )
        myScene = nil
    end
    --bTransition = false
end

function UIEndScreen_Show(scene,gameType)
    if( not storyboard.state ) then
        storyboard.state = {}
        storyboard.state.score = 0
    end
    
    bTransition = false
    
    audio.stop( 2 )
    audio.setVolume( 1, { channel=2 } )
    audio.setVolume( 1, { channel=1 } ) 
    
     display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )

    scene.uiEndScreenDisplayGroup = display.newGroup()
    addDisplayGroup( scene.uiEndScreenDisplayGroup )
    scene.uiEndScreenBadge = display.newImage("images/badge-mini.png");
    scene.uiEndScreenBadge.x = display.contentCenterX
    --scene.uiEndScreenBadge.y = display.contentCenterY
    --scene.uiEndScreenDisplayGroup.y = topEdge
    
    scene.pointsSound = audio.loadSound( "sounds/points.wav" )
    scene.chaChingSound = audio.loadSound( "sounds/chaching.wav" )
    
    myScene = scene
    scene.uiEndScreenDisplayGroup:insert( scene.uiEndScreenBadge )
    transition.to( scene.uiEndScreenDisplayGroup, { time=300, delay=0, y=display.contentCenterY, transition=easing.outExpo } )
    GA.newEvent( "design", { event_id="bonus:started"})
    if( gameType == "pieTime" ) then
        showPieTime(scene)
    elseif( gameType == "whoDatLady" ) then
        showWhoDatLady(scene)
    elseif( gameType == "chicago" ) then
        showChicago(scene)
    elseif( gameType == "jokeyTime" ) then
       showJokeyTime(scene)
    end
end