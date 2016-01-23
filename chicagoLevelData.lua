
----------------------------------
-- THE BIG 3 VIDEO GAME        ---
-- andrew@langleycreations.com ---
----------------------------------

-- Script determine when things appear in the Chicago level and how difficulty ramps up

local mainScene = nil
local prevMarker = 0
local spawnOrder = {}
local firstBossMarker = nil
local secondBossMarker = nil
local offset = nil
local dist = nil

local levelData = {
	--
}

local function checkMarker( dist )
	if ( dist > prevMarker ) then
		prevMarker = dist
		return true
	else
		return false
	end
end


local function setOffset(num)
       offset = math.floor( mainScene.city.distanceTraveled * 0.1 ) - num
end

-- Beginning of the game. Enemies spawn slowly
local function phaseA()
    if( mainScene ) then
        mainScene.enemies:spawn( nil, 2000, 500 )
    end
end

-- Enemies start spawning faster.
local function phaseB()
    if( mainScene ) then
        mainScene.enemies:spawn( nil, 500, 500 )
    end
end

-- ... and faster!
local function phaseC()
    if( mainScene ) then
        mainScene.enemies:spawn( nil, 250, 500 )
    end
end

-- Hold everything while Vince is on screen and still alive.
local function waitForVince(num, myTimer, newOffset )
    if( mainScene.bVinceAlive ) then
        setOffset(num)
    else
        if( myTimer ) then
            setOffset(newOffset-1)
            if( myTimer ) then
                timer.cancel( myTimer )
            end
        end
    end
end

-- Do boring tutorial stuff.
local startTime = 800
local function doTutorial()
    startTime = 2500
    if( not mainScene.tutorialStartTime ) then
        mainScene.tutorialStartTime = system.getTimer()
        
        display.setDefault( "magTextureFilter", "nearest" )
        display.setDefault( "minTextureFilter", "nearest" )
        
        local objectiveText = display.newImageRect( "images/instructions-objectiveText.png", 161, 21)
        local objectiveStroke = display.newImageRect( "images/instructions-objectiveStroke.png", 161, 21)
        objectiveText.blendMode = "add"
        objectiveText.alpha = 0
        objectiveText.y = mainScene.topEdge + 30
        objectiveText.x = display.contentCenterX
        objectiveText.xScale = 1.25
        objectiveText.yScale = 1.25
        objectiveStroke.y = objectiveText.y
        objectiveStroke.x = display.contentCenterX
        objectiveStroke.xScale = 1.25
        objectiveStroke.yScale = 1.25
        objectiveStroke.alpha = 0
        
        local stayAliveText = display.newImageRect( "images/instructions-stayAliveText.png", 93, 15)
        local stayAliveStroke = display.newImageRect( "images/instructions-stayAliveStroke.png", 93, 15)
        stayAliveText.x = objectiveText.x
        stayAliveStroke.x = objectiveText.x
        stayAliveText.xScale = objectiveText.xScale
        stayAliveText.yScale = objectiveText.yScale
        stayAliveText.y = objectiveText.y + 20
        stayAliveStroke.y = objectiveText.y + 20
        stayAliveText.x = objectiveText.x
        stayAliveText.blendMode = "add"
        stayAliveText.alpha = 0
        stayAliveStroke.xScale = objectiveText.xScale
        stayAliveStroke.yScale = objectiveText.yScale
        stayAliveStroke.alpha = 0
        
        local powerUpText = display.newImageRect( "images/instructions-powerUpText.png", 139, 15)
        local powerUpStroke = display.newImageRect( "images/instructions-powerUpStroke.png", 139, 15)
        powerUpText.x = objectiveText.x
        powerUpStroke.x = objectiveText.x
        powerUpText.xScale = objectiveText.xScale
        powerUpText.yScale = objectiveText.yScale
        powerUpText.y = objectiveText.y + 35
        powerUpStroke.y = objectiveText.y + 35
        powerUpText.x = objectiveText.x
        powerUpText.blendMode = "add"
        powerUpText.alpha = 0
        powerUpStroke.xScale = objectiveText.xScale
        powerUpStroke.yScale = objectiveText.yScale
        powerUpStroke.alpha = 0
        
        local farText = display.newImageRect( "images/instructions-farText.png", 164, 15)
        local farStroke = display.newImageRect( "images/instructions-farStroke.png", 164, 15)
        farText.x = objectiveText.x
        farStroke.x = objectiveText.x
        farText.xScale = objectiveText.xScale
        farText.yScale = objectiveText.yScale
        farText.y = objectiveText.y + 50
        farStroke.y = objectiveText.y + 50
        farText.x = objectiveText.x
        farText.blendMode = "add"
        farText.alpha = 0
        farStroke.xScale = objectiveText.xScale
        farStroke.yScale = objectiveText.yScale
        farStroke.alpha = 0
        
        local myDelay = 2500
        local myDelay2 = 11000
        
        transition.to( objectiveText, { time=500, delay=myDelay, alpha=0.7} )
        transition.to( objectiveStroke, { time=500, delay=myDelay, alpha=1} )
        transition.to( stayAliveText, { time=500, delay=myDelay+2000, alpha=0.8} )
        transition.to( stayAliveStroke, { time=500, delay=myDelay+2000, alpha=1} )
        transition.to( powerUpText, { time=500, delay=myDelay+3500, alpha=0.8} )
        transition.to( powerUpStroke, { time=500, delay=myDelay+3500, alpha=1} )
        transition.to( farText, { time=500, delay=myDelay+5000, alpha=0.8} )
        transition.to( farStroke, { time=500, delay=myDelay+5000, alpha=1} )
        
        transition.to( objectiveText, { time=500, delay=myDelay2, alpha=0} )
        transition.to( objectiveStroke, { time=500, delay=myDelay2, alpha=0} )
        transition.to( stayAliveText, { time=500, delay=myDelay2, alpha=0} )
        transition.to( stayAliveStroke, { time=500, delay=myDelay2, alpha=0} )
        transition.to( powerUpText, { time=500, delay=myDelay2, alpha=0} )
        transition.to( powerUpStroke, { time=500, delay=myDelay2, alpha=0} )
        transition.to( farText, { time=500, delay=myDelay2, alpha=0} )
        transition.to( farStroke, { time=500, delay=myDelay2, alpha=0} )
        
        mainScene.ui.uiGroup:insert( objectiveText )
        mainScene.ui.uiGroup:insert( objectiveStroke )
        mainScene.ui.uiGroup:insert( stayAliveText )
        mainScene.ui.uiGroup:insert( stayAliveStroke )
        mainScene.ui.uiGroup:insert( powerUpText )
        mainScene.ui.uiGroup:insert( powerUpStroke )
        mainScene.ui.uiGroup:insert( farText )
        mainScene.ui.uiGroup:insert( farStroke )
    end
    if( system.getTimer() - mainScene.tutorialStartTime < 13000 ) then
        mainScene.specialPowers.powerMeter = 0
        mainScene.player.dashMeter = 0
        mainScene.obstacles.bDisableSpawn = true
        mainScene.disablePowerupAutoSpawn = true
        return
    end

    if( not mainScene.tutorialSound1 ) then
        mainScene.tutorialSound1 = mainScene.sound:loadVoice("voice-maryJaneTutorial1.wav" )
        mainScene.tutorialSound2 = mainScene.sound:loadVoice("voice-maryJaneTutorial2.wav" )
        mainScene.tutorialSound3 = mainScene.sound:loadVoice("voice-maryJaneTutorial3.wav" )
    end

    if( not mainScene.bCompletedWeaponTutorial ) then
            if( mainScene.score > 200 ) then
                mainScene.bCompletedWeaponTutorial = true
                mainScene.ui:setButtonReminder( mainScene.ui.fireButton, false )
                return
            end
            if( not mainScene.bMessagedWeaponTutorial ) then
                local message = function()
                    mainScene.sound:playVoice( mainScene.tutorialSound1  )
                    mainScene.ui:setButtonReminder( mainScene.ui.fireButton, true )
                end
                timer.performWithDelay( 750, message )
                mainScene.bMessagedWeaponTutorial = true
            end
            mainScene.obstacles.bDisableSpawn = true
            mainScene.disablePowerupAutoSpawn = true
            mainScene.specialPowers.powerMeter = 0
            mainScene.player.dashMeter = 0
            if( table.getn( mainScene.enemies.getActive() ) < 1 ) then
                mainScene.enemies:spawn( mainScene.enemies.toaster )
            end
            return
        end
        if( not mainScene.bCompletedDashTutorial ) then
            if( mainScene.score > 400 ) then
                mainScene.ui:setButtonReminder( mainScene.ui.dashButton, false )
                mainScene.bCompletedDashTutorial = true
                return
            end
            
            mainScene.specialPowers.powerMeter = 0
            if( mainScene.player.dashMeter > 0.35 and GetActiveObjects() < 1 ) then
                if( not mainScene.bMessagedDashTutorial ) then
                local message = function()
                    mainScene.sound:playVoice( mainScene.tutorialSound2  )
                    mainScene.ui:setButtonReminder( mainScene.ui.dashButton, true )
                end
                timer.performWithDelay( 500, message )
                mainScene.bMessagedDashTutorial = true
            end
                mainScene.obstacles:spawn( mainScene.obstacles.crates )
            end
            return
        end

        if( not mainScene.bCompletedPowerTutorial ) then
            if( mainScene.score > 500 ) then
                mainScene.bCompletedPowerTutorial = true
                storyboard.state.bTutorialRequired = false
            end
            if( not mainScene.player.bDashing ) then
                 mainScene.player.dashMeter = 0
            end
            if( table.getn( mainScene.powerUps.activePowerUps ) < 1 and  mainScene.specialPowers.powerMeter == 0 ) then
                
                mainScene.powerUps:forceSpawn(3)
            end
            if( mainScene.specialPowers.powerMeter > 0 ) then

                if( not mainScene.bMessagedPowerTutorial ) then
                    local message = function()
                        mainScene.ui:setButtonReminder( mainScene.ui.specialPowersButton, true )
                        mainScene.sound:playVoice( mainScene.tutorialSound3 )
                        mainScene.obstacles:spawn( mainScene.obstacles.crates )
                        mainScene.enemies:spawn( mainScene.enemies.jerkoffHands )
                        mainScene.obstacles.bDisableSpawn = false
                    end
                    timer.performWithDelay( 0, message )
                    mainScene.bMessagedPowerTutorial = true
                end
            end
            return
    end
end

local counter = 0

function levelData:update()
    counter = counter + 1
    if( counter < 5 ) then
        return
    end
    counter = 0

	dist = math.floor( mainScene.city.distanceTraveled * 0.1 ) - offset

    if( storyboard.state.bTutorialRequired ) then
        mainScene.city.distanceTraveled = 0
        dist = -1
    end
    
    if( dist == -1 ) then
        doTutorial()
        return
    end

    if( mainScene.tutorialSound3 ) then
        audio.dispose( mainScene.tutorialSound1 )
        audio.dispose( mainScene.tutorialSound2 )
        audio.dispose( mainScene.tutorialSound3 )
        mainScene.tutorialSound1 = nil
        mainScene.tutorialSound2 = nil
        mainScene.tutorialSound3 = nil
    end
    
    storyboard.state.bTutorialRequired = false

    -- Set up new stuff after the player reaches various milestones in the level.
	if( dist <= 1 and checkMarker( 1 ) ) then
		mainScene.obstacles.bDisableSpawn = true
        mainScene.enemies.jerkoffHands.bEnableAutoSpawn = true
        mainScene.enemies.toaster.bEnableAutoSpawn = true
        mainScene.disablePowerupAutoSpawn = false
        mainScene.enemies.mudSharks.bBossBattle = false
        self.timer = timer.performWithDelay( startTime, phaseA, 0 )
	elseif( dist > 8 and checkMarker( 8 ) ) then
		local enemy = table.remove( spawnOrder, 1 )
        enemy.bEnableAutoSpawn = true
        mainScene.obstacles.bDisableSpawn = true
        mainScene.disablePowerupAutoSpawn = false
        mainScene.enemies:spawn( enemy )
         mainScene.enemies.mudSharks.bBossBattle = false
    elseif( dist > 18 and checkMarker( 18 ) ) then
     if( self.timer ) then
		  timer.cancel( self.timer )
		end
		self.timer = timer.performWithDelay( 1500, phaseA, 0 )
		local enemy = table.remove( spawnOrder, 1 )
        enemy.bEnableAutoSpawn = true
        mainScene.disablePowerupAutoSpawn = false
        mainScene.obstacles.bDisableSpawn = false
        mainScene.enemies:spawn( enemy )
         mainScene.enemies.mudSharks.bBossBattle = false
    elseif( dist > 41 and checkMarker( 41 ) ) then
		local enemy = table.remove( spawnOrder, 1 )
        enemy.bEnableAutoSpawn = true
        mainScene.disablePowerupAutoSpawn = false
        mainScene.enemies:spawn( enemy )
    elseif( dist > 60 and checkMarker( 60 ) ) then
		local enemy = table.remove( spawnOrder, 1 )
		 mainScene.enemies.mudSharks.bBossBattle = false
		if( enemy ) then
             enemy.bEnableAutoSpawn = true
            mainScene.enemies:spawn( enemy )
         end
         mainScene.disablePowerupAutoSpawn = false
         mainScene.enemies.randyRanch.bEnableAutoSpawn = true
        self.timer = timer.performWithDelay( 2000, phaseB, 0 )
	elseif( dist >= firstBossMarker and checkMarker( firstBossMarker ) ) then
	    if( self.timer ) then
		  timer.cancel( self.timer )
		end
		
		local num = math.random(3)
		if ( num == 1 ) then
		  setOffset(300-1)
		  return
	    elseif( num == 2 ) then
	        mainScene.enemies:spawn( mainScene.enemies.vince)
            mainScene.obstacles.bDisableSpawn = true
            mainScene.enemies.bDisable = true
            mainScene.disablePowerupAutoSpawn = true
            local update = function()
                waitForVince( firstBossMarker, self.timer, 300 )
            end
            self.timer = timer.performWithDelay( 100, update, 0 )
    	 elseif( num == 3 ) then
	       
            mainScene.obstacles.bDisableSpawn = true
            mainScene.enemies.bDisable = true
            mainScene.disablePowerupAutoSpawn = true
            mainScene.enemies.mudSharks.bBossBattle = true
            local counter = math.random( 30 ) + 20
            local update = function()
                counter = counter - 1
                if( counter <= 0 ) then
                    setOffset(300-1)
                    timer.cancel( self.timer )
                else
                    setOffset(firstBossMarker+1)
                    mainScene.enemies:spawn( mainScene.enemies.mudSharks )
                end
            end
            if( mainScene:getSelectedCharacter() ~= "don" ) then
        local voice = mainScene.sound:loadVoice( "voice-" .. mainScene:getSelectedCharacter() .. "MudSharks.wav" )
             mainScene.sound:playVoice( voice, 0.75, false )
    end
            self.timer = timer.performWithDelay( 200, update, -1 )
            return
    	 end

	elseif( dist >= 300 and checkMarker( 300 ) ) then
         if( self.timer ) then
            timer.cancel( self.timer )
        end
        
        mainScene.enemies.mudSharks.bBossBattle = false
	    mainScene.obstacles.bDisableSpawn = false
        mainScene.enemies.bDisable = false
        mainScene.disablePowerupAutoSpawn = false
        self.timer = timer.performWithDelay( 2000, phaseA, 0 )
	elseif( dist >= 320 and checkMarker( 320 ) ) then
	   if( self.timer ) then
	    timer.cancel( self.timer )
	    end
	     mainScene.enemies.mudSharks.bBossBattle = false
	    mainScene.enemies.basketball.bEnableAutoSpawn = true
        self.timer = timer.performWithDelay( 2000, phaseB, 0 )
	elseif( dist >= 390 and checkMarker( 390 ) ) then
	    if( self.timer ) then
	       timer.cancel( self.timer )
	    end
	    mainScene.enemies.redBats.difficulty = 2
	    mainScene.enemies.basketball.bEnableAutoSpawn = true
        self.timer = timer.performWithDelay( 1500, phaseC, 0 )
	elseif( dist >= secondBossMarker and checkMarker( secondBossMarker ) ) then
	   if( self.timer ) then
	       timer.cancel( self.timer )
	    end
	   self.timer = timer.performWithDelay( 1500, phaseA, 0 )
	   setOffset( 600 )
	   mainScene.enemies.jerkoffHands.bEnableAutoSpawn = true
        mainScene.enemies.toaster.bEnableAutoSpawn = true
        mainScene.enemies.basketball.bEnableAutoSpawn = true
        mainScene.enemies.basketball.bEnableAutoSpawn = true
        mainScene.enemies.mudSharks.bEnableAutoSpawn = true
        mainScene.enemies.blackHawks.bEnableAutoSpawn = true
        mainScene.enemies.redBats.bEnableAutoSpawn = true
        mainScene.enemies.randyRanch.bEnableAutoSpawn = true
	   mainScene.obstacles:spawn( mainScene.obstacles.cutlass )
	    mainScene.enemies.redBats.difficulty = 1
	elseif( dist >= 650 and checkMarker( 650 ) ) then
	   if( self.timer ) then
	       timer.cancel( self.timer )
	    end
	    self.timer = timer.performWithDelay( 500, phaseC, 0 )
	    mainScene.enemies.redBats.difficulty = 3
	end
end


function levelData:init(scene)
	mainScene = scene
	prevMarker = mainScene.city.distanceTraveled
	self.timer = nil
    local spawnTable = { mainScene.enemies.mudSharks, mainScene.enemies.blackHawks, mainScene.enemies.redBats}
    spawnOrder = {}
    while( table.getn( spawnTable ) > 0 ) do
        local index = math.random( table.getn( spawnTable ) )
        local item = table.remove( spawnTable, index )
        table.insert( spawnOrder, item )
    end
    offset = 0
    dist = 0
    firstBossMarker = math.random( 200 ) + 70
    secondBossMarker = math.random( 200 ) + 310
    mainScene.enemies.redBats.difficulty = 1
end

function levelData:destroy()
    spawnOrder = {}
	mainScene = nil
	if( self.timer ) then
		timer.cancel( self.timer )
	end
    self.timer = nil
end

return levelData
