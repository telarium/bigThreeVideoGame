local mainScene = nil

local tileBank = {}
local tile = nil

local buildingBGOriginColor = {0.85,1,0.75}
local buildingBGDestColor = {0.9,0.9,1}
local buildingFGOriginColor = {1,1,0.5}
local buildingFGDestColor = {0.8,0.95,1}
local foregroundColor = {0.65,0.7,0.95}

local prevTime = system.getTimer() + 100

local imgMultiplication = 2

tile = {img="images/cityRedBrickStore.png",width="107",height="81",signX=120,signY=84}
table.insert( tileBank, tile )
tile = {img="images/cityGreyApartment.png",width="154",height="137"}
table.insert( tileBank, tile )
tile = {img="images/cityYellowHouse.png",width="154",height="137"}
table.insert( tileBank, tile )
tile = {img="images/cityYellowHouse2.png",width="163",height="137"}
table.insert( tileBank, tile )
tile = {img="images/cityHouse1.png",width="94",height="73"}
table.insert( tileBank, tile )
tile = {img="images/cityHouse2.png",width="97",height="81"}
table.insert( tileBank, tile )
tile = {img="images/cityHouse3.png",width="93",height="79"}
table.insert( tileBank, tile )
tile = {img="images/cityYellowHouse2.png",width="163",height="137"}
table.insert( tileBank, tile )
tile = {img="images/cityHouse1.png",width="94",height="73"}
table.insert( tileBank, tile )
tile = {img="images/cityHouse2.png",width="97",height="81"}
table.insert( tileBank, tile )
tile = {img="images/cityHouse3.png",width="93",height="79"}
table.insert( tileBank, tile )
tile = {img="images/cityParkingGarage.png",width="230",height="135"}
table.insert( tileBank, tile )
tile = {img="images/cityParkingGarage.png",width="230",height="135"}
table.insert( tileBank, tile )
tile = {img="images/cityHospital1.png",width="156",height="105",signX=218,signY=110}
table.insert( tileBank, tile )
tile = {img="images/cityHospital2.png",width="156",height="105"}
table.insert( tileBank, tile )
tile = {img="images/chicagoSchool.png",width="156",height="89"}
table.insert( tileBank, tile )
tile = {img="images/city7722.png",width="154",height="123"}
table.insert( tileBank, tile )

tile = nil

local signBank = { "citySignASM.gif", "citySignHuck.gif", "citySignMasterGraphics.gif", "citySignFunUniversity.gif", "citySignDragos.gif", "citySignJensenFarms.gif", "citySignLonghornCornOil.gif", "citySignLittleLaddys.gif", "citySignTerrifyingTim.gif", "citySignBeanTownHeat.gif", "citySignJavaho.gif", "citySignSandy.gif" }


local cityObject = {
    
}

local function getPerc( num1, num2, perc )
    
    local delta = num1 - num2
    local offset = perc * delta
    return num1 - offset
end

local function showSunset(self, perc)
    
    if( self.oldPerc == perc ) then
        return
    end

    if( perc < 0 or perc > .875 or mainScene.bSmoggy ) then
        return
    end

    local col1 = getPerc( buildingBGOriginColor[1], buildingBGDestColor[1], perc )
    local col2 = getPerc( buildingBGOriginColor[2], buildingBGDestColor[2], perc )
    local col3 = getPerc( buildingBGOriginColor[3], buildingBGDestColor[1], perc )
    
    self.skySprite3:setFillColor( col1,col2,col3,1 )
    self.skySprite4:setFillColor( col1,col2,col3,1 )
    
    col1 = getPerc( buildingFGOriginColor[1], buildingFGDestColor[1], perc )
    col2 = getPerc( buildingFGOriginColor[2], buildingFGDestColor[2], perc )
    col3 = getPerc( buildingFGOriginColor[3], buildingFGDestColor[1], perc )
    
    self.skySprite1:setFillColor( col1,col2,col3,1 )
    self.skySprite2:setFillColor( col1,col2,col3,1 )
    
    self.colorOverlay.alpha = ( perc * 0.08 )
    self.colorOverlay.isVisible = true
    col1 = getPerc( 1, foregroundColor[1], perc )
    col2 = getPerc( 1, foregroundColor[1], perc )
    col3 = getPerc( 1, foregroundColor[1], perc )
      
    self.foregroundSprite1:setFillColor( col1,col2,col3,1 )
    self.foregroundSprite2:setFillColor( col1,col2,col3,1 )
    self.sunsetSprite.isVisible = true
    
    self.sunsetSprite.alpha = perc
    
    self.oldPerc = perc
end

local function setGroundObject(self)
    local scene = mainScene
    scene.ground = display.newRect( scene.leftEdge, scene.foldY, display.actualContentHeight, 40 )
    --scene.ground:setFillColor( 55 )
    scene.ground.x = display.contentCenterX
    scene.ground.y = scene.foldY - 10
    scene.ground.isVisible = false;
	
	scene.groundShape = { -scene.ground.width*3,-scene.ground.height/2, scene.ground.width*3,-scene.ground.height/2, scene.ground.width*3,scene.ground.height/2, -scene.ground.width*3,scene.ground.height/2 }
	

    scene.groundY = scene.ground.y - ( scene.ground.height / 2 )
    scene.ground.y = scene.ground.y - 4
    
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
    
    self.groundSprite1 = display.newImageRect( "images/chicagoStreetTile.gif", 576, 40 )
    self.groundSprite1.anchorX = 1
    self.groundSprite1.anchorY = 1
    self.groundSprite1.x = scene.rightEdge	
	self.groundSprite1.y = scene.ground.y + 37
	self.groundSprite1.xScale = imgMultiplication
	self.groundSprite1.yScale = imgMultiplication
	
	self.groundSprite2 = display.newImageRect( "images/chicagoStreetTile.gif", 576, 40 )
    self.groundSprite2.anchorX = 1
    self.groundSprite2.anchorY = 1
    self.groundSprite2.x = self.groundSprite1.x + self.groundSprite1.width * imgMultiplication
	self.groundSprite2.y = self.groundSprite1.y
	self.groundSprite2.xScale = imgMultiplication
	self.groundSprite2.yScale = imgMultiplication
    
    self.foregroundSprite1 = display.newImageRect( "images/cityForegroundFile.png", 350, 43 )
    self.foregroundSprite1.anchorX = 1
    self.foregroundSprite1.anchorY = 1
    self.foregroundSprite1.x = scene.rightEdge
	self.foregroundSprite1.y = scene.ground.y + 60
	self.foregroundSprite1.xScale = imgMultiplication
	self.foregroundSprite1.yScale = imgMultiplication
    
    self.foregroundSprite2 = display.newImageRect( "images/cityForegroundFile.png", 350, 43 )
    self.foregroundSprite2.anchorX = 1
    self.foregroundSprite2.anchorY = 1
    self.foregroundSprite2.x = self.foregroundSprite1.x + self.foregroundSprite1.width * imgMultiplication
	self.foregroundSprite2.y = self.foregroundSprite1.y
	self.foregroundSprite2.xScale = imgMultiplication
	self.foregroundSprite2.yScale = imgMultiplication
	
	self.skySprite1 = display.newImageRect( "images/cityBackgroundTile.png", 720, 148 )
    self.skySprite1.anchorX = 1
    self.skySprite1.anchorY = 1
    self.skySprite1.x = scene.leftEdge + self.skySprite1.width * imgMultiplication
    self.skySprite1.y = self.groundSprite1.y - self.groundSprite1.height * imgMultiplication
	self.skySprite1.xScale = imgMultiplication
	self.skySprite1.yScale = imgMultiplication
	
	self.skySprite2 = display.newImageRect( "images/cityBackgroundTile.png", 720, 148 )
    self.skySprite2.anchorX = 1
    self.skySprite2.anchorY = 1
    self.skySprite2.x = self.skySprite1.x + self.skySprite1.width * imgMultiplication
    self.skySprite2.y = self.groundSprite1.y - self.groundSprite1.height * imgMultiplication
    self.skySprite2.xScale = imgMultiplication
	self.skySprite2.yScale = imgMultiplication
	
	self.skySprite3 = display.newImageRect( "images/cityBackgroundTile2.png", 720, 143 )
    self.skySprite3.anchorX = 1
    self.skySprite3.anchorY = 1
    self.skySprite3.x = scene.leftEdge + self.skySprite3.width * imgMultiplication
    self.skySprite3.y = self.groundSprite1.y - self.groundSprite1.height * imgMultiplication
	self.skySprite3.xScale = imgMultiplication
	self.skySprite3.yScale = imgMultiplication
	
	self.skySprite4 = display.newImageRect( "images/cityBackgroundTile2.png", 720, 143 )
    self.skySprite4.anchorX = 1
    self.skySprite4.anchorY = 1
    self.skySprite4.x = self.skySprite3.x + self.skySprite3.width * imgMultiplication
    self.skySprite4.y = self.groundSprite1.y - self.groundSprite1.height * imgMultiplication
    self.skySprite4.xScale = imgMultiplication
	self.skySprite4.yScale = imgMultiplication
    
    self.sunsetSprite = display.newImageRect( "images/cityBackgroundSunset.gif", 491, 179 )
    self.sunsetSprite.anchorX = 0.5
    self.sunsetSprite.anchorY = 0.5
    self.sunsetSprite.x = display.contentCenterX
	self.sunsetSprite.y = display.contentCenterY
    self.sunsetSprite.xScale = imgMultiplication
	self.sunsetSprite.yScale = imgMultiplication
    self.sunsetSprite.isVisible = false
    
    self.skySolidBackground = display.newRect(scene.leftEdge, scene.topEdge, display.actualContentWidth, display.actualContentHeight)
	self.skySolidBackground.anchorX = 0.5
	self.skySolidBackground.anchorY = 0.5
	self.skySolidBackground.x = display.contentCenterX
	self.skySolidBackground.y = display.contentCenterY
    self.skySolidBackground:setFillColor(.075,0.533,1)
    
    self.skySolidForeground = display.newRect(scene.leftEdge, scene.topEdge, display.actualContentHeight, display.actualContentWidth)
	self.skySolidForeground.anchorX = 0.5
	self.skySolidForeground.anchorY = 0.5
	self.skySolidForeground.x = display.contentCenterX
	self.skySolidForeground.y = display.contentCenterY
    --self.skySolidForeground:setFillColor(skyOriginColor[1],skyOriginColor[2],skyOriginColor[3],0.17)
    
    self.colorOverlay = display.newRect(scene.leftEdge, scene.topEdge, display.actualContentWidth, display.actualContentHeight)
	self.colorOverlay.anchorX = 0.5
	self.colorOverlay.anchorY = 0.5
	self.colorOverlay.x = display.contentCenterX
	self.colorOverlay.y = display.contentCenterY
    self.colorOverlay:setFillColor(0.5647,0,1)
    self.colorOverlay.alpha = 0
    self.colorOverlay.isVisible = false
    self.blendMode = "multiply"
    
    scene.city.displayGroup:insert( self.colorOverlay )
    scene.city.displayGroup:insert( self.sunsetSprite )
    scene.city.displayGroup:insert( self.skySolidBackground )
    --scene.city.displayGroup:insert( self.skySolidForeground )
	scene.city.displayGroup:insert( self.skySprite3 )
	scene.city.displayGroup:insert( self.skySprite4 )
	scene.city.displayGroup:insert( self.skySprite1 )
	scene.city.displayGroup:insert( self.skySprite2 )
	scene.city.displayGroup:insert( scene.ground )
	scene.city.displayGroup:insert( self.groundSprite1 )
	scene.city.displayGroup:insert( self.groundSprite2 )
	scene.city.displayGroup:insert( self.foregroundSprite1 )
	scene.city.displayGroup:insert( self.foregroundSprite2 )
	
	display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
end

local function shuffleSigns(self)
	local temp = {}
	for i=1,table.getn( signBank ) do
		table.insert( temp, signBank[i] )
	end
	local int = nil
	while( table.getn( temp ) ) > 0 do
		int = math.random( table.getn( temp ) );
		table.insert( self.shuffledSigns, temp[int] )
		table.remove( temp, int )
	end
end

local function addSign(self, tile)
    if( tile.signX and not tile.sign ) then
        if( table.getn( self.shuffledSigns ) <= 0 ) then
            shuffleSigns(self)
        end    
        display.setDefault( "magTextureFilter", "linear" )
        display.setDefault( "minTextureFilter", "linear" )
        local signImage = table.remove(self.shuffledSigns,1 )
        tile.sign = display.newImageRect( "images/" .. signImage, 156, 36 )
        self.displayGroup:insert( tile.sign )
        tile.sign.x = tile.x + ( tile.signX  )
        tile.sign.y = tile.y - ( tile.signY  )
        display.setDefault( "magTextureFilter", "linear" )
        display.setDefault( "minTextureFilter", "linear" )
        tile.sign:toFront()
    end
end

local function loadTileImage(self)
    display.setDefault( "magTextureFilter", "nearest" )
    display.setDefault( "minTextureFilter", "nearest" )
	local tileImage = table.remove(self.shuffledTiles,1 )
	if( not tileImage ) then
	   return
	end
	local tile = display.newImageRect( tileImage.img, tileImage.width, tileImage.height )
	tile.anchorX = 0
	tile.anchorY = 1
	tile.xScale = imgMultiplication
	tile.yScale = imgMultiplication
    tile.signX = tileImage.signX
    tile.signY = tileImage.signY
    self.displayGroup:insert( tile)
    
    tile:toBack()
    
    
    display.setDefault( "magTextureFilter", "linear" )
    display.setDefault( "minTextureFilter", "linear" )
    return tile
end

local function shuffleTiles(self)
	local temp = {}
	for i=1,table.getn(tileBank ) do
		table.insert( temp, tileBank[i] )
	end
	local int = nil
	while( table.getn( temp ) ) > 0 do
		int = math.random( table.getn( temp ) );
		table.insert( self.shuffledTiles, temp[int] )
		table.remove( temp, int )
	end
end



local function spawnNewTile(self)
	local tile = table.remove( self.activeTiles, 1 )
    if ( tile.sign ) then
        tile.sign:removeSelf()
        tile.sign = nil
    end
	tile:removeSelf()
    tile = nil
	if( table.getn( self.shuffledTiles ) <= 0 ) then
		shuffleTiles(self)
	end
	local newTile = loadTileImage(self)    
	local prevTile = self.activeTiles[table.getn(self.activeTiles)]	
	
    local tileX = prevTile.x + prevTile.width * imgMultiplication + math.random( 20 ) + 5
    newTile.x, newTile.y = tileX, self.groundSprite1.y - self.groundSprite1.height * imgMultiplication
	table.insert( self.activeTiles, newTile )
    addSign( self, newTile )
end

function cityObject:setGroundSpawnCoordinate(x,id)
    if( x > mainScene.city.groundSpawnCoordinate ) then
        mainScene.city.groundSpawnCoordinate = x

    end
end

function cityObject:getGroundSpawnCoordinate()
    local x,y = mainScene.city.displayGroup:contentToLocal( mainScene.rightEdge, mainScene.foldY )
    if( mainScene.city.groundSpawnCoordinate < x ) then
        mainScene.city.groundSpawnCoordinate = x
    end
    return mainScene.city.groundSpawnCoordinate
end


function cityObject:setTiles()
    local tileX = mainScene.leftEdge
    local tile = nil
    shuffleTiles(self)
    for i=1,table.getn( self.activeTiles ) do
        tile = loadTileImage(self)
        if( tile ) then
            tile.x, tile.y = tileX, self.groundSprite1.y - self.groundSprite1.height * imgMultiplication
            tileX = tile.x + tile.width * imgMultiplication + math.random( 20 ) + 5
            self.activeTiles[i] = tile
            addSign( self, tile )
        end
        
    end

end

function cityObject:setSpeed(speed,dampening)
    if( not speed ) then
        speed = self.defaultSpeed + self.speedRampUp

    end
    
    if( dampening ) then
    	self.speedDampening = dampening
    end
    self.desiredSpeed = speed
end

function cityObject:getSpeed()
    return self.curSpeed
end

function cityObject:init(scene)
	mainScene = scene
	self.sunsetTime = nil
    
    self.oldPerc = -1
	
    self.shuffledTiles = {}
    self.activeTiles = { "", "", "", "" }
    self.shuffledSigns = {}
    self.desiredSpeed = 0
    self.curSpeed = 0
    self.speedRampUp = 0
    self.speedDampening = 0.01
    self.defaultSpeed = -6
    self.groundSpawnCoordinate = 0
	self.distanceTraveled = 0
	
    self.displayGroup = display.newGroup()
    addDisplayGroup( self.displayGroup )

    setGroundObject(self)
    self:setTiles()
end

function GetCityObjectNum()
    if( not mainScene ) then
        return
    end
    return mainScene.city.displayGroup.numChildren
end

function cityObject:update()
    if( not self.counter ) then
        self.counter = 0
    end
    self.counter = self.counter + 1
    
    if( self.speedRampUp < 0.35 ) then
        if( mainScene:getSelectedCharacter() == "mole" ) then
            self.speedRampUp = self.speedRampUp + 0.00006
        elseif( mainScene:getSelectedCharacter() == "don" ) then
            self.speedRampUp = self.speedRampUp + 0.000052
        else
            self.speedRampUp = self.speedRampUp + 0.000045
        end
    end

    local delta = self.desiredSpeed - self.curSpeed
    if( self.desiredSpeed ~= 0 ) then
        
        self.curSpeed = self.curSpeed + (delta * self.speedDampening) - self.speedRampUp
    else
        self.curSpeed = self.curSpeed + (delta * self.speedDampening)
    end
    
    if ( math.abs( self.curSpeed - self.desiredSpeed ) <= 0.5 ) then
        self.curSpeed = self.desiredSpeed
    end
    
    local diff = ( self.curSpeed * mainScene.timeScale ) * ( 60 / display.fps )
    --diff = math.floor(diff+0.5)
    mainScene.ground.x =  mainScene.ground.x - diff
    self.skySolidBackground.x = self.skySolidBackground.x - diff
    self.sunsetSprite.x = self.skySolidBackground.x
    self.colorOverlay.x = self.skySolidBackground.x
	self.distanceTraveled = self.distanceTraveled - ( diff / 12 )
    --self.displayGroup:translate(diff, self.displayGroup.y)
    self.displayGroup.x = self.displayGroup.x + diff
    
    self.skySprite1.x = self.skySprite1.x - (diff*.868)
    self.skySprite2.x = self.skySprite2.x - (diff*.868)
    
    self.skySprite3.x = self.skySprite3.x - (diff*.909)
    self.skySprite4.x = self.skySprite4.x - (diff*.909)
    
    self.foregroundSprite1.x = self.foregroundSprite1.x + (diff/3)
    self.foregroundSprite2.x = self.foregroundSprite2.x + (diff/3)
    
    if( self.curSpeed * mainScene.timeScale and not storyboard.state.bTutorialRequired  ) then
        mainScene:addPoints( diff * -.01 )
    end

    if( self.counter > 5 ) then
        self.counter = 0
        local x,y = self.displayGroup:localToContent( self.activeTiles[1].x, self.activeTiles[1].y )
        if( ( x + self.activeTiles[1].width * imgMultiplication ) < mainScene.leftEdge ) then
            spawnNewTile(self)
        end
    end
        
        local x2,y2 = mainScene.city.displayGroup:contentToLocal( mainScene.leftEdge, mainScene.foldY )
        if( self.groundSprite1.x < x2 ) then
            self.groundSprite1.x = self.groundSprite2.x + self.groundSprite2.width * imgMultiplication
        end

    if( self.groundSprite2.x < x2 ) then
    	self.groundSprite2.x = self.groundSprite1.x + self.groundSprite1.width * imgMultiplication
    end

    if( self.skySprite1.x < x2 ) then
    	self.skySprite1.x = self.skySprite2.x + self.skySprite2.width * imgMultiplication
    end
    if( self.skySprite2.x < x2 ) then
    	self.skySprite2.x = self.skySprite1.x + self.skySprite1.width * imgMultiplication
    end
    
    if( self.skySprite3.x < x2 ) then
    	self.skySprite3.x = self.skySprite4.x + self.skySprite4.width * imgMultiplication
    end
    if( self.skySprite4.x < x2 ) then
    	self.skySprite4.x = self.skySprite3.x + self.skySprite1.width * imgMultiplication
    end
    
    if( self.foregroundSprite1.x < x2 ) then
    	self.foregroundSprite1.x = self.foregroundSprite2.x + self.foregroundSprite2.width * imgMultiplication
    end
    if( self.foregroundSprite2.x < x2 ) then
    	self.foregroundSprite2.x = self.foregroundSprite1.x + self.foregroundSprite1.width * imgMultiplication
    end

    self.foregroundSprite1:toFront()
    self.foregroundSprite2:toFront()
    
    if( ( system.getTimer() - prevTime ) < 50 ) then
        return
    end
    prevTime = system.getTimer()
    
    for i=1,table.getn(self.activeTiles ) do
        if( self.activeTiles[i].sign ) then
            self.activeTiles[i].sign:toBack()
            self.activeTiles[i]:toBack()
        end
    end
    
    self.colorOverlay:toFront()
    self.skySolidForeground:toBack()
    self.skySprite1:toBack()
    self.skySprite2:toBack()
    self.skySprite3:toBack()
    self.skySprite4:toBack()
    self.sunsetSprite:toBack()
    self.skySolidBackground:toBack()
    if( not self.sunsetTime ) then
        self.sunsetTime = ( math.random( 60 ) ) * 30
    end
     self.sunsetTime = self.sunsetTime - 1
    if( not self.sunsetPercent or ( self.sunsetTime > 0 ) ) then
        self.sunsetPercent = 0
    else
        self.sunsetPercent = self.sunsetPercent + 0.0007
    end
    
    showSunset( self, self.sunsetPercent )
end


function cityObject:destroy()
    for i, tile in ipairs( self.activeTiles ) do
        tile:removeSelf()
        tile = nil
    end
    
    self.oldPerc = nil
    self.sunsetPercent = nil
    self.sunsetTime = nil

	self.shuffledTiles = {}
    self.activeTiles = {}
    self.sunsetPercent = nil
    
    display.remove( self.displayGroup )
    self.displayGroup = nil
    
    
    
    self = nil
	if( mainScene ) then
	    display.remove( mainScene.city.displayGroup )
		mainScene.city.displayGroup = nil
		mainScene.city = nil
		
		mainScene = nil
	end
end


return cityObject;