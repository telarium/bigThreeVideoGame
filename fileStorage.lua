
-- load the JSON library.
local json = require("json")
local filename = "gameData.json"
local storyboard = require( "storyboard" )
local GA = require ( "GameAnalytics" )

local json = require("json")
function saveTable(t)
    local path = system.pathForFile( filename, system.DocumentsDirectory)
    local file = io.open(path, "w")
    if file then
        local contents = json.encode(t)
        file:write( contents )
        io.close( file )
        return true
    else
        return false
    end
end

function loadTable()
    local path = system.pathForFile( filename, system.DocumentsDirectory)
   -- print( path )
    local contents = ""
    local myTable = {}
    local file = io.open( path, "r" )
    if file then
         -- read all contents of file into a string
         local contents = file:read( "*a" )
         myTable = json.decode(contents);
         io.close( file )
         
         storyboard.state.bPlayedPieTime = myTable.bPlayedPieTime
         storyboard.state.bPlayedJokeyTime = myTable.bPlayedJokeyTime
         storyboard.state.bPlayedWhoDatLady = myTable.bPlayedWhoDatLady
         
         storyboard.state.pieTimeRounds = myTable.pieTimeRounds
         
         return myTable 
    end
    
    return nil
end

function save(bSaveScore,data)
    if( not data ) then
     data = loadTable()
    end
    if( not data ) then
        data = {}
    end

    data.introMonth = tonumber(os.date("%m"))
    if( not data.bPlayedPerry ) then
        data.bPlayedPerry = false
        data.perryHighScore = 0
    end
    if( not data.bPlayedMole ) then
        data.bPlayedMole = false
        data.moleHighScore = 0
    end
    if( not data.bPlayedDon ) then
        data.bPlayedDon = false
        data.donHighScore = 0
    end
    
    if( not data.highScore ) then
        data.highScore = 0
    end
    
    if( not data.pieTimeRounds ) then
        data.pieTimeRounds = 0
    end
    
    if( storyboard.state.character ) then
        if( storyboard.state.character == "perry" ) then
            data.bPlayedPerry = true
            GA.newEvent( "design", { event_id="score:Perry",  area="main", value=storyboard.state.score})
            if( bSaveScore and storyboard.state.score > data.perryHighScore ) then
                data.perryHighScore = storyboard.state.score
            end
        elseif( storyboard.state.character == "mole" ) then
            data.bPlayedMole = true
            GA.newEvent( "design", { event_id="score:Mole",  area="main", value=storyboard.state.score})
            if( bSaveScore and storyboard.state.score > data.moleHighScore ) then
                data.moleHighScore = storyboard.state.score
            end
        else
            data.bPlayedDon = true
            GA.newEvent( "design", { event_id="score:Don",  area="main", value=storyboard.state.score})
            if( bSaveScore and storyboard.state.score > data.donHighScore ) then
                data.donHighScore = storyboard.state.score
            end
        end
    end

    if( bSaveScore and storyboard.state.score > data.highScore ) then
        data.highScore = storyboard.state.score
    end
    
    local myCat = "perryHighScore"
    
    if ( system.getInfo("platformName") == "Android" ) then
        myCat = "CgkIhf7UyIMOEAIQAA"
    end
    
    gameNetwork.request( "setHighScore", { localPlayerScore = { category= myCat, value=data.perryHighScore },})
    
    myCat = "donHighScore"
    
    if ( system.getInfo("platformName") == "Android" ) then
        myCat = "CgkIhf7UyIMOEAIQAg"
    end
    
    gameNetwork.request( "setHighScore", { localPlayerScore = { category= myCat, value=data.donHighScore },})
    
    myCat = "moleHighScore"
    
    if ( system.getInfo("platformName") == "Android" ) then
        myCat = "CgkIhf7UyIMOEAIQAQ"
    end
    
    gameNetwork.request( "setHighScore", { localPlayerScore = { category= myCat, value=data.moleHighScore },})
    
    saveTable(data)
    
    myCat = "overallHighScore"
    
    if ( system.getInfo("platformName") == "Android" ) then
        myCat = "CgkIhf7UyIMOEAIQAw"
    end
    
    gameNetwork.request( "setHighScore", { localPlayerScore = { category= myCat, value=data.highScore },})
    
    saveTable(data)
end
