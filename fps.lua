module(..., package.seeall)
PerformanceOutput = {};
PerformanceOutput.mt = {};
PerformanceOutput.mt.__index = PerformanceOutput;
 
 
local prevTime = 0;
local maxSavedFps = 30;
 
local function createLayout(self)
        local group = display.newGroup();
 
        self.memory = display.newText("0/10",20,0, "C64 User Mono", 10);
        self.framerate = display.newText("0", 30, self.memory.height, "C64 User Mono", 10);
        local background = display.newRect(-100,0, 285, 50);
        background.anchorX = 0.05
        background.anchorY = 0.24
        background.alpha = 0.7
        
        self.memory:setFillColor(255,255,255);
        self.framerate:setFillColor(255,255,255);
        background:setFillColor(0,0,0);
        
        group:insert(background);
        group:insert(self.memory);
        group:insert(self.framerate);
       
 
        return group;
end
 
local function minElement(table)
        local min = 10000;
        for i = 1, #table do
                if(table[i] < min) then min = table[i]; end
        end
        return min;
end
 
 
local function getLabelUpdater(self)
        local lastFps = {};
        local lastFpsCounter = 1;
         
        return function(event)
                local curTime = system.getTimer();
                local dt = curTime - prevTime;
                prevTime = curTime;
                self.group:toFront()
        
                local fps = math.floor(1000/dt);
                
                lastFps[lastFpsCounter] = fps;
                lastFpsCounter = lastFpsCounter + 1;
                if(lastFpsCounter > maxSavedFps) then lastFpsCounter = 1; end
                local minLastFps = minElement(lastFps); 
                
                
                self.framerate.text = "\nFPS: "..fps.."(min: "..minLastFps..")";
                
                self.memory.text = "Mem: "..(math.floor(system.getInfo("textureMemoryUsed")/1000000)).." mb";
                local lua = tostring( math.floor( collectgarbage("count" ) / 100 ) )
                if( string.len( lua ) < 2 ) then
                    lua = "0" .. lua
                end
                self.memory.text = self.memory.text .. " " .. lua
                if( GetActiveEnemies ) then
                    if( GetActiveEnemies() ) then
                        self.framerate.text = self.framerate.text .. "\nE: " .. tostring( GetActiveEnemies() ) .. " COL: " .. tostring( mainScene.testCollisionCounter ) .. " W: " .. tostring( GetWeapons() )
                        self.framerate.text = self.framerate.text .. " CITY: " .. tostring( GetCityObjectNum() )
                    end
                end
        end
end
 
 
local instance = nil;
-- Singleton
function PerformanceOutput.new()
        if(instance ~= nil) then return instance; end
        local self = {};
        setmetatable(self, PerformanceOutput.mt);
        
        self.group = createLayout(self);
        
        Runtime:addEventListener("enterFrame", getLabelUpdater(self));
 
        instance = self;
        return self;
end