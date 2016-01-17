local storyboard = require( "storyboard" )
local scene = storyboard.newScene()

local GA = require ( "GameAnalytics" )
require "uiEndScreen"

local jokes = {}

table.insert( jokes, { "Who granted the fish's wish?", "His fairy codmother", "The ducktor", "Fish and ships", "John" } )
table.insert( jokes, { "John's father had three sons: Snack, Crackle, and...?", "John", "Pop", "Demetri Moreland", "Thumper" } )
table.insert( jokes, { "What makes the hairdos of bumblebees so sticky?", "Honey combs", "Moostard", "Boobees", "Dude juice" } )
table.insert( jokes, { "What did the duck say when he bought chapstick?", "Put it on my bill", "Well that tasted funny", "None of your business", "I'll take the whole thing, Randy" } )
table.insert( jokes, { "Where did the mallard go when\nhe got sick?", "The ducktor", "7722 Reseda Blvd", "Secret location in West Hollywood", "Don't worry about it" } )
table.insert( jokes, { "What game do cows like to play?", "Moosical chairs", "Moleplay", "The Big 3 Videogame", "Perry Pie Time" } )
table.insert( jokes, { "What do cows like to put on their hot dogs?", "Moostard", "Fish and ships", "Chocolate ship", "Dude juice" } )
table.insert( jokes, { "Why don't African animals\nplay cards?", "Too many cheetahs", "Fangsgiving", "It was over his head", "None of your business" } )
table.insert( jokes, { "What kind of bees give milk?", "Boobees", "Honey combs", "Moosical chairs", "Randy" } )
table.insert( jokes, { "What sports car did the\nsheep drive?", "Lamborghini", "Their mom's Cutlass", "A Toyota", "Don't worry about it" } )
table.insert( jokes, { "What did Mr. Skeleton say to\nhis dinner guests?", "Bone appetite", "Put it on my bill", "Well that tasted funny", "None of your business" } )
table.insert( jokes, { "Where does Mr. Mudshark keep\nhis money?", "The sand bank", "Honey combs", "Fake disability schemes", "Lawsuits" } )
table.insert( jokes, { "What's the problem with two witches?", "You never know which is which", "One could disagree with the other", "Too many cheetahs", "Boobees" } )
table.insert( jokes, { "What did the cannibal say after he ate The Big 3 Podcast?", "Well that tasted funny", "It was over his head", "Bone appetite", "Put it on my bill" } )
table.insert( jokes, { "What do sea monsters eat?", "Fish and ships", "Ten-tickles", "Moostard", "Honey combs" } )
table.insert( jokes, { "How do you make an octopus laugh?", "Ten-tickles", "Hand love", "Mediscare", "Wrap music" } )
table.insert( jokes, { "Why didn't the teddy bear\nhave dinner?", "He was already stuffed", "Perry Pie Time", "Frostbite", "Too many cheetahs" } )
table.insert( jokes, { "What kind of music does a\nmummy like?", "Wrap music", "Retribution", "AC/DC", "The Pledge of Allegiance" } )
table.insert( jokes, { "What kind of insurance does a ghost have?", "Mediscare", "Boobees", "Fangsgiving", "Fake disability" } )
table.insert( jokes, { "What is a vampire's favorite holiday?", "Fangsgiving", "Birthdays", "June 26th", "None. He's a Javaho" } )
table.insert( jokes, { "Why did Perry not get the\njoke about the ceiling?", "It was over his head", "It was over 20 years ago", "Don't worry about it", "None of your business" } )
table.insert( jokes, { "What do you get when you\ncross Wolfie with a snowman?", "Frostbite", "Ten-tickles", "Dicky Barrett", "Sheba" } )
table.insert( jokes, { "What was Cookie Caramellos' favorite vessel in the Navy?", "Chocolate ship", "U.S.S. Man Milk", "The sand bank", "Don't ask, don't tell" } )
table.insert( jokes, { "What did the banana do when\nhe saw the ice cream?", "Split", "Put it on my bill", "Frostbite", "Drank it like a milkshake" } )
table.insert( jokes, { "5,730 minus 1,992 equals...?", "7722", "Reseda Blvd", "#102", "91335", true } )
table.insert( jokes, { "How do you put a baby astronaut to seep?", "Rocket", "Boobees", "Sing a Javaho hymn", "Ten-tickles" } )

local leftEdge = 0 - ( ( display.actualContentWidth - display.contentWidth ) / 2 )
local rightEdge = display.contentWidth + ( ( display.actualContentWidth - display.contentWidth ) / 2 )
local bottomEdge = display.contentHeight + ( ( display.actualContentHeight - display.contentHeight ) / 2 )
local topEdge = 0 -  ( ( display.actualContentHeight - display.contentHeight ) / 2 )

local displayGroup = nil

local function selectAnswer(answer)
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    
    --scene.bg:removeEventListener( "touch", touchEvent )
    if( scene.attractTimer ) then
        timer.cancel(scene.attractTimer)
        scene.attractTimer = nil
    end
    
    if( not scene.bGameOver ) then
        scene.bGameOver = true
        scene.resultSound = nil
    
        if( answer.index == scene.correctIndex ) then
            scene.checkMark = display.newImageRect( "images/whoDatLady-checkmark.png", 29, 26 )
            
            local delayFunc = function()
                scene.resultSound = audio.loadSound( "sounds/voice-jqaCorrect.wav", { channel=1})
                audio.play( scene.resultSound )
           end
            timer.performWithDelay( 400, delayFunc )
            GA.newEvent( "design", { event_id="bonus:jokeyTimeWon",  area="jokeyTime"})
            scene.jokeyTimePoints = 200
            local sound = audio.loadSound( "sounds/ding.wav" )
            audio.play( sound, { channel=2})
        else
            local sound = audio.loadSound( "sounds/wrong.wav" )
            audio.play( sound, { channel=2})
            scene.checkMark = display.newImageRect( "images/whoDatLady-x.png", 29, 26 )
            
            local delayFunc = function()
                scene.resultSound = audio.loadSound( "sounds/voice-jqaIncorrect.wav", { channel=1})
                audio.play( scene.resultSound )
            end
            timer.performWithDelay( 400, delayFunc )
            
            
            GA.newEvent( "design", { event_id="bonus:jokeyTimeLost",  area="jokeyTime"})
            if( scene.setupText and scene.setupText ~= "" and scene.setupText ~= " " ) then
                GA.newEvent( "design", { event_id="bonus:jokeLost:" .. scene.setupText,  area="jokeyTime"})
            end
            scene.jokeyTimePoints = 0
        end
        
        audio.stop( scene.introSoundChannel )
        scene.checkMark.x = answer.xVal
        scene.checkMark.y = answer.y
        scene.checkMark.xScale = 0.1
        scene.checkMark.yScale = 0.1
        displayGroup:insert( scene.checkMark )
        transition.to( scene.checkMark, { time=150, delay=0, xScale=1.25} )
        transition.to( scene.checkMark, { time=150, delay=0, yScale=1.25} )
        transition.to( scene.checkMark, { time=50, delay=0+150, xScale=1} )
        transition.to( scene.checkMark, { time=50, delay=0+150, yScale=1} )
        local function delay()
            UIEndScreen_Show(scene, "jokeyTime" )
        end
        timer.performWithDelay( 1000, delay, 1 )
    end
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
end

local function makeText( textString, fontSize, myX, myY, bLeft, bYellow )
    local align = "center"
    if( bLeft ) then
        align = "left"
    end
    local textOptions = 
        {
            text = textString,     
            x = myX,
            y = myY,
            width = 450,     --required for multi-line and alignment
            font = "C64 User Mono",   
            fontSize = fontSize,
            align = align  --new alignment parameter
        }
    local mainText = display.newText( textOptions )
    local subText = display.newText( textOptions )
    if( bYellow ) then
        mainText:setFillColor(1,0.9,.03 )
    end
    subText:setFillColor( 0,0,0 )
    subText.x = mainText.x - 3
    subText.y = mainText.y + 2
        
    displayGroup:insert( subText )
    displayGroup:insert( mainText )
    
    return mainText, subText
end

function TimeOut()
    scene.bGameOver = true
    scene.jokeyTimePoints = 0
    UIEndScreen_Show(scene, "jokeyTime" )
end

-- Called immediately after scene has moved onscreen:
function scene:enterScene( event )
    storyboard.removeAll()
    collectgarbage()
	
    displayGroup = display.newGroup()
    
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    
    local spiralSheet = graphics.newImageSheet( "images/jokeyTime_background.gif", { width=329, height=183, numFrames=15 } )
    scene.bg = display.newSprite( spiralSheet, {{ name = "loop", start=1, count=15, time=800, loopCount=0 }} )
    scene.bg.anchorX = 0.5
	scene.bg.anchorY = 0.5
	scene.bg.xScale = display.actualContentWidth / scene.bg.width
	scene.bg.yScale = display.actualContentHeight / scene.bg.height
	scene.bg.x = display.contentCenterX
	scene.bg.y = display.contentCenterY
    displayGroup:insert( scene.bg )
    
    scene.title = display.newImageRect( "images/jokeyTime_title.png", 390, 118 )
    scene.title.x = display.contentCenterX
	scene.title.y = topEdge + ( scene.title.height / 2 ) + 20
    
    
    data = loadTable()
    
    local joke = nil

    if( not data.jokeTable or not data.jokeTable[1] or data.jokeTable[1]>table.getn( jokes ) ) then
        data.jokeTable = nil
    end
    
    if( not data.jokeTable or not data.jokeTable[1] or table.getn( data.jokeTable ) < 1 ) then
        data.jokeTable = {}
        local indexTable = {}
        local i = 1
        while( table.getn( indexTable ) < table.getn( jokes ) ) do
            table.insert( indexTable, i )
            i = i + 1
        end
        while( table.getn( indexTable ) > 0 ) do
            local item = table.remove( indexTable, math.random( table.getn( indexTable ) ) ) 
            if( item ) then
                table.insert( data.jokeTable, item )
            end
        end
    end
    
    joke = jokes[ table.remove( data.jokeTable, 1 ) ]

    scene.setupText =  table.remove( joke, 1 )

    scene.setup, scene.setupShadow = makeText( scene.setupText, 14, display.contentCenterX, scene.title.y + 76, false, true )
    local correct = joke[1]

    local answers = {}

    if( joke[2] == "Reseda Blvd" ) then

        local achievement = "CgkIhf7UyIMOEAIQCQ"
        if ( system.getInfo("platformName") == "iPhone OS" ) then 
            achievement = "resedaBlvd"
        end
        gameNetwork.request( "unlockAchievement", { achievement = { identifier=achievement, percentComplete=100, showsCompletionBanner=true } } )

        scene.correctIndex = 1
        answers[1] = joke[1]
        answers[2] = joke[2]
        answers[3] = joke[3]
        answers[4] = joke[4]
    else
        while( table.getn( joke ) > 0 ) do
            local punch = table.remove( joke, math.random( table.getn( joke ) ) )
            table.insert( answers, punch )
            if( punch == correct ) then
                scene.correctIndex = table.getn( answers )
            end
        end
    end

    scene.answer1, scene.answer1Shadow = makeText( "  " .. tostring(answers[1]), 11, display.contentCenterX, scene.title.y )
    scene.answer2, scene.answer2Shadow = makeText( "  " .. tostring( answers[2]), 11, display.contentCenterX, scene.title.y )
    scene.answer3, scene.answer3Shadow = makeText( "  " .. tostring(answers[3]), 11, display.contentCenterX, scene.setup.y )
    scene.answer4, scene.answer4Shadow = makeText( "  " .. tostring(answers[4]), 11, display.contentCenterX, scene.setup.y )

    scene.answer1.index = 1
    scene.answer2.index = 2
    scene.answer3.index = 3
    scene.answer4.index = 4
    
    scene.answer1.xVal = scene.answer1.x - ( ( string.len( scene.answer1.text ) /2 ) * 11 )
    scene.answer2.xVal = scene.answer2.x - ( ( string.len( scene.answer2.text ) /2 ) * 11 )
    scene.answer3.xVal = scene.answer3.x - ( ( string.len( scene.answer3.text ) /2 ) * 11 )
    scene.answer4.xVal = scene.answer4.x - ( ( string.len( scene.answer4.text ) /2 ) * 11 )
    

    local function touchEvent(event)
        if( math.abs( event.y - scene.answer1.y ) < 14 ) then
            selectAnswer(scene.answer1)
        elseif( math.abs( event.y - scene.answer2.y ) < 14 ) then
            selectAnswer(scene.answer2)
        elseif( math.abs( event.y - scene.answer3.y ) < 14 ) then
            selectAnswer(scene.answer3)
        elseif( math.abs( event.y - scene.answer4.y ) < 14 ) then
            selectAnswer(scene.answer4)
        end
    end
    
    local function animComplete()
        scene.bg:addEventListener( "touch", touchEvent )
    
        --scene.answer1:addEventListener( "touch", selectAnswer1 )
        --scene.answer2:addEventListener( "touch", selectAnswer2 )
        --scene.answer3:addEventListener( "touch", selectAnswer3 )
        --scene.answer4:addEventListener( "touch", selectAnswer4 )
    end
    
    local overlay = display.newRect(leftEdge, topEdge, display.actualContentWidth, display.actualContentHeight)
    overlay:setFillColor(0, 0, 0)
    overlay.alpha = 1
    overlay.anchorX = 0
    overlay.anchorY = 0
    overlay.blendMode = "multiply"
    transition.to( overlay, { time=350, delay=0, alpha=0, transition=easing.inOutQuad } )
    
	scene.bg:setSequence( "loop" )
	scene.bg:setSequence( "loop" )
	scene.bg:play()
    
    GA.newEvent( "design", { event_id="bonus:playedJokeyTime",  area="jokeyTime"} )
        
    scene.introSound = nil
    
    if( not data.bPlayedJokeyTime ) then
        scene.introSound = audio.loadSound( "sounds/voice-jqaIntro.wav" )
        data.jokeIntroNum = 2
    else
        if( math.random( 5 ) == 1 ) then
            scene.introSound = audio.loadSound( "sounds/voice-jqaIntro.wav" )
        else
            if( data.jokeIntroNum == 2 ) then
                scene.introSound = audio.loadSound( "sounds/voice-jqaIntro2.wav" )
                data.jokeIntroNum = 3
            else
                data.jokeIntroNum = 2
                scene.introSound = audio.loadSound( "sounds/voice-jqaIntro3.wav" )
            end
        end
    end
    
    scene.introSoundChannel = audio.play( scene.introSound )
    
    data.bPlayedJokeyTime = true
     
    save(false,data)
    
    scene.attractTimer = timer.performWithDelay( 15000, TimeOut )
    
    displayGroup:insert( scene.title )
    scene.title.xScale = 0.01
    scene.title.yScale = 0.01
    
    scene.setup.y = scene.title.y+10
    scene.setup.yScale = 0.001
    scene.setupShadow.y = scene.title.y+10
    scene.setupShadow.yScale = 0.001
    
    scene.answer1.yScale = 0.001
    scene.answer1Shadow.yScale = 0.001
    scene.answer2.yScale = 0.001
    scene.answer2Shadow.yScale = 0.001
    scene.answer3.yScale = 0.001
    scene.answer3Shadow.yScale = 0.001
    scene.answer4.yScale = 0.001
    scene.answer4Shadow.yScale = 0.001
    
    transition.to( scene.title, { time=1200, delay=0, xScale=1, transition=easing.outExpo } )
    transition.to( scene.title, { time=1200, delay=0, yScale=1, transition=easing.outExpo } )
    
    local delayTime = 800
    local animTime = 750
    
    transition.to( scene.setup, { time=animTime, delay=delayTime, y=scene.title.y + 76, transition=easing.outExpo } )
    transition.to( scene.setupShadow, { time=animTime, delay=delayTime, y=scene.title.y + 76, transition=easing.outExpo } )
    transition.to( scene.setup, { time=animTime, delay=delayTime, yScale = 1, transition=easing.outExpo } )
    transition.to( scene.setupShadow, { time=animTime, delay=delayTime, yScale = 1, transition=easing.outExpo } )
    
    local delayTime = delayTime + 1400
    local animTime = 750
    
    transition.to( scene.answer1, { time=animTime, delay=delayTime, y=scene.title.y + 115, transition=easing.outExpo } )
    transition.to( scene.answer1Shadow, { time=animTime, delay=delayTime, y=scene.title.y + 115, transition=easing.outExpo } )
    transition.to( scene.answer1, { time=animTime-50, delay=delayTime, yScale = 1, transition=easing.outExpo } )
    transition.to( scene.answer1Shadow, { time=animTime-50, delay=delayTime, yScale = 1, transition=easing.outExpo } )
    
    local delayTime = delayTime + 150
    local animTime = 600
    
    transition.to( scene.answer2, { time=animTime, delay=delayTime, y=scene.title.y + 145, transition=easing.outExpo } )
    transition.to( scene.answer2Shadow, { time=animTime, delay=delayTime, y=scene.title.y + 145, transition=easing.outExpo } )
    transition.to( scene.answer2, { time=animTime-50, delay=delayTime, yScale = 1, transition=easing.outExpo } )
    transition.to( scene.answer2Shadow, { time=animTime-50, delay=delayTime, yScale = 1, transition=easing.outExpo } )
    
    local delayTime = delayTime + 150
    
    transition.to( scene.answer3, { time=animTime, delay=delayTime, y=scene.title.y + 175, transition=easing.outExpo } )
    transition.to( scene.answer3Shadow, { time=animTime, delay=delayTime, y=scene.title.y + 175, transition=easing.outExpo } )
    transition.to( scene.answer3, { time=animTime-50, delay=delayTime, yScale = 1, transition=easing.outExpo } )
    transition.to( scene.answer3Shadow, { time=animTime-50, delay=delayTime, yScale = 1, transition=easing.outExpo } )
    
    local delayTime = delayTime + 150
    
    transition.to( scene.answer4, { time=animTime, delay=delayTime, y=scene.title.y + 205, transition=easing.outExpo } )
    transition.to( scene.answer4Shadow, { time=animTime, delay=delayTime, y=scene.title.y + 205, transition=easing.outExpo } )
    transition.to( scene.answer4, { time=animTime-50, delay=delayTime, yScale = 1, transition=easing.outExpo } )
    transition.to( scene.answer4Shadow, { time=animTime-50, delay=delayTime, yScale = 1, transition=easing.outExpo, onComplete=animComplete  } )
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
end


function scene:exitScene( event )
    if( scene.attractTimer ) then
         timer.cancel(scene.attractTimer)
         scene.attractTimer = nil
    end
	displayGroup:removeSelf()
    displayGroup = nil
    if( scene.resultSound ) then
        audio.dispose( scene.resultSound )
        scene.resultSound = nil
    end
    if( scene.introSound ) then
        audio.dispose( scene.introSound )
        scene.introSound = nil
        scene.introSoundChannel = nil
    end
    
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