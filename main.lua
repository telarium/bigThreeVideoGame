----------------------------------
--    THE BIG 3 VIDEO GAME     ---
-- andrew@langleycreations.com ---
----------------------------------

gameNetwork = require "gameNetwork"
storyboard = require( "storyboard" )
GA = require ( "GameAnalytics" )
uiEndScreen = require "uiEndScreen"
uiTransition = require( "uiTransition" )
physics = require("physics" )
require "fileStorage"

displayGroups = {}

--- Removes all references to a module.
-- Do not call unrequire on a shared library based module unless you are 100% confidant that nothing uses the module anymore.
-- @param m Name of the module you want removed.
-- @return Returns true if all references were removed, false otherwise.
-- @return If returns false, then this is an error message describing why the references weren't removed.
function unrequire(m)
    package.loaded[m] = nil
    _G[m] = nil
     
    -- Search for the shared library handle in the registry and erase it
    local registry = debug.getregistry()
    local nMatches, mKey, mt = 0, nil, registry['_LOADLIB']
     
    for key, ud in pairs(registry) do
    if type(key) == 'string' and type(ud) == 'userdata' and getmetatable(ud) == mt and string.find(key, "LOADLIB: .*" .. m) then
    nMatches = nMatches + 1
    if nMatches > 1 then
    return false, "More than one possible key for module '" .. m .. "'. Can't decide which one to erase."
    end
    mKey = key
    end
    end
     
    if mKey then
    registry[mKey] = nil
    end
     
    return true
end

function addDisplayGroup(obj)
    table.insert( displayGroups, obj )
end

function removeDisplayGroups()
    for i, object in ipairs( displayGroups ) do
        if( object and object.numChildren ) then
            for z=1,object.numChildren do
                if( z and object[z] ) then
                    object[z]:removeSelf()
                    object[z] = nil
                end
            end
            display.remove( object )
            object = nil
        end
    end
    displayGroups = {}
end

local function requestCallback( event )
    print("Got " .. #event.data .. " scores")
    print("Local player score: " .. event.localPlayerScore)
end

local function test(event)
    print( "SET A SCORE!!!!!!" )
    print( event )
    print( event.type )
    print( event.data )
end

local function gameNetworkInitialized( event )
    return true
end

local function onSystemEvent( event ) 
    if event.type == "applicationStart" then
        if ( system.getInfo("platformName") == "iPhone OS" ) then 
            gameNetwork.init( "gamecenter", gameNetworkInitialized )
        end
        if ( system.getInfo("platformName") == "Android" ) then
            gameNetwork.init( "google", gameNetworkInitialized )
        end
        return true
    end
end

Runtime:addEventListener( "system", onSystemEvent )

local loggedIntoGC = false

math.randomseed( os.time() )

-- hide the status bar
display.setStatusBar( display.HiddenStatusBar )

system.activate("multitouch")

-- include the Corona "storyboard" module
local storyboard = require "storyboard"

storyboard.state = {}
data = loadTable()

if ( not storyboard.state.bPlayedPieTime ) then
    if( math.random(2) == 1 ) then
        storyboard.state.bonusPlaylist = { "perryPieTime", "jokeyTime", "whoDatLady" }
    else
        storyboard.state.bonusPlaylist = { "perryPieTime", "whoDatLady", "jokeyTime" }
    end
elseif( not storyboard.state.bPlayedJokeyTime ) then
    storyboard.state.bonusPlaylist = { "jokeyTime", "whoDatLady", "perryPieTime" }
elseif ( not storyboard.state.bPlayedWhoDatLady ) then
    storyboard.state.bonusPlaylist = { "whoDatLady","jokeyTime","perryPieTime" }
else
    local num = math.random( 3 )
    if( num == 1 ) then
        storyboard.state.bonusPlaylist = { "perryPieTime", "jokeyTime", "perryPieTime", "whoDatLady" }
    elseif( num == 2 ) then
        storyboard.state.bonusPlaylist = { "jokeyTime", "perryPieTime", "jokeyTime", "whoDatLady" }
    else
        storyboard.state.bonusPlaylist = { "whoDatLady", "perryPieTime", "whoDatLady", "jokeyTime" }
    end
end
if( math.random( 2 ) == 2 ) then
        local num = math.random( 3 )
        if( num == 1 ) then
            table.insert( storyboard.state.bonusPlaylist, "jokeyTime" )
        else
            table.insert( storyboard.state.bonusPlaylist, "perryPieTime" )
        end
    end
    
-- Set the audio mix mode to allow sounds from the app to mix with other sounds from the device
if audio.supportsSessionProperty == true then
    audio.setSessionProperty(audio.MixMode, audio.AmbientMixMode)
end
	 
-- Store whether other audio is playing.  It's important to do this once and store the result now,
-- as referring to audio.OtherAudioIsPlaying later gives misleading results, since at that point
-- the app itself may be playing audio
storyboard.state.isOtherAudioPlaying = false
	 
if audio.supportsSessionProperty == true then
    if not(audio.getSessionProperty(audio.OtherAudioIsPlaying) == 0) then
        storyboard.state.isOtherAudioPlaying = true
    end
end

if ( system.getInfo("environment") == "simulator" ) then
    storyboard.state.isOtherAudioPlaying = true
end
    
--local fps = require("fps")
--local performance = fps.PerformanceOutput.new();
--performance.group.x, performance.group.y = display.contentWidth/2,  50;
--performance.alpha = 0.6; -- So it doesn't get in the way of the rest of the scene

-- load menu screen
local bPlayIntro = true

if( data ) then
    if( data.introMonth == tonumber(os.date("%m"))) then
       bPlayIntro = false
    end
end


if( bPlayIntro ) then
    storyboard.gotoScene( "splashScreen" )
else
    storyboard.gotoScene( "gameCredits" )
end

GA.isDebug                  = false
GA.runInSimulator           = false
GA.submitSystemInfo         = true
GA.submitAverageFps         = true
GA.submitAverageFpsInterval = 60

GA.submitCriticalFps         = true
GA.submitCriticalFpsInterval = 5     -- seconds (minimum 5)
GA.criticalFpsRange          = 15    -- frames  (minimum 10)

GA.criticalFpsBelow          = 40
GA.init ({
	game_key   = 'baf4d1562473f2bd4970f3f4bdf9924c',
    secret_key = 'a2b639b70d617e2bf77adf1038cf9a68e26c1957',
	build_name = '1.0',
})

