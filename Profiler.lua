
--[[
Corona Profiler v 1.4
--Fixed Runtime Error bug
--Fixed Path name issue
Author: M.Y. Developers
Copyright (C) 2011 M.Y. Developers All Rights Reserved
Support: mydevelopergames@gmail.com
Website: http://www.mydevelopersgames.com/site
License: Many hours of genuine hard work have gone into this project and we kindly ask you not to redistribute or illegally sell this package. 
We are constantly developing this software to provide you with a better development experience and any suggestions are welcome. Thanks for you support.

The Icicle plot was adapted from the work of Nicolas Garcia Belmonte from http://thejit.org/
-- IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE 
-- FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR 
-- OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER 
-- DEALINGS IN THE SOFTWARE.
--]]
local profilerTable = {}
local localsList = {}
local globalsBlacklist = {}
local timelineHTMLTop = [[<html>
<head>
    <link rel="stylesheet" href="codemirror.css">
    <script src="codemirror.js"></script>
    <script src="runmode.js"></script>
    <script src="lua.js"></script>
    <link rel="stylesheet" href="docs.css">
<script type="text/javascript"
  src="dygraph-combined.js"></script>
<script type="text/javascript"
  src="dygraph-range-selector.js"></script>    
</head>
<body>
<div id="graphdiv" style="width:100%; height:90%;"></div>
<pre id="source" class="cm-s-default"></pre>
<script type="text/javascript">
s = document.getElementById("source");
var lines = []]

local timelineHTMLTop2= [[]
g = new Dygraph(
    document.getElementById("graphdiv"),
	[]]
local timelineHTMLMiddle = [[],
	{
        rollPeriod: 1,
        showRoller: false,
		showRangeSelector: true,
		rangeSelectorHeight: 100,
		title: "Memory Usage Timeline",
		xlabel: "Execution Step (Lines of code)",
		ylabel: "Memory Count (in kb)",	
		highlightCallback: function(e, x, pts, row) {
			CodeMirror.runMode(lines[x-1], "lua",s);		  
		
		  },
	}
  );
   g.setAnnotations([]]
local timelineHTMLEnd = [[]);  
</script>
</body>
</html>
]]

local filetimeline 
local maxFunctionsToShow = 10
local json = require "json"

local initMemory,initTime,previousFunction,previousMemory,previousLineAll,profilerTimer
local currentParams = {}
previousFunction = "main"
local functions = {}
local memoryTimeline = {} --record memory profile every time a function is called and within lines
local fileFilters = {}
local memoryTimelineIndex = 1
local files = {}
local returned
local function compare(a,b)
	if currentParams.mode== 1 then
		if(type(a[2])=="table") then
		return a[2].timeTaken > b[2].timeTaken
		else
		return a[2] > b[2] 
		end
	else
		if(type(a[2])=="table") then
		return a[2].memoryTaken > b[2].memoryTaken
		else
		return a[2] > b[2] 
		end
	end
end
local function sortTable(input)
	local sortTable = {}
	for i,v in pairs(input) do
		sortTable[#sortTable+1] = {i,v}
	end
	table.sort(sortTable, compare)
	return sortTable
end
local function trim(s)
  -- from PiL2 20.4
  if(s) then
  return (s:gsub("^%s*(.-)%s*$", "%1"))
  else
  return ""
  end
end


local function tableSizeNoCycle(tab, itr)
	if(itr==nil) then itr = 1 end --stack limit
	if(itr>20) then
		return 0
	end
	if(type(tab) == "table") then
		local size = 0;
		for i,v in pairs(tab) do
			print(itr)
			if(i~="profilerCycleDetect") then
			--	print(i,v)
				if(type(v)=="table") then
						size = size+tableSizeNoCycle(v, itr+1)+1
					end
				else
					size = size+1
				end
			
		end
		return size
	else
		return 1
	end
end
local function tableSize(tab, traversed)
	if(traversed == nil) then
		traversed = {}
	end
	local size = 0;
	if(type(tab) == "table") then
		traversed[tab] = true
		for i,v in pairs(tab) do
			if(i~="profilerCycleDetect") then
				if(type(v)=="table") then
					if(traversed[v]) then
						size = size+1
					else
						size = size+tableSize(v, traversed)+1
					end
				else
					size = size+1
				end
			end
		end
	else
		return 1
	end
	return size	
end
local function initFunction()
	local func = {}
	func.lineTime = {}
	func.lineCount = {}	
	func.lineFunc = {}
	func.lineMemory = {}
	func.functionCallers = {}
	func.functionCalled = {}
	func.timeTaken = 0
	func.memoryTaken = 0
	func.previousLine = previousLineAll
	func.stackIndex = 1
	local currentTime = system.getTimer() 
	func.initTime = currentTime 
	func.previousTime = currentTime	
	func.initMemory = collectgarbage("count")		
	return func
end
local eventTable = {"C","R","L"}
local function recordMemoryTimeline(funcKey, memory, event)
	--filetimeline:write(memoryTimelineIndex..","..memory..[[\n]])
	filetimeline:write(funcKey.."\n"..memory.."\n"..event.."\n")
	-- {series: "memory",x: "1",shortText: "L",text: "Coldest Day"},
	--if( (event==1 or event == 2 ) and string.len(funcKey) > 6) then
	--filetimelineAnnotate:write([[{series:"memory",x:"]]..memoryTimelineIndex..[[",shortText:"]]..event..[[",text:"]]..funcKey..[["},]])
	--end
--	memoryTimeline[memoryTimelineIndex] = {}
--	memoryTimeline[memoryTimelineIndex].funcKey = funcKey
--	memoryTimeline[memoryTimelineIndex].memory = memory						
--	memoryTimeline[memoryTimelineIndex].event = event --1 = called, 2 = returned, 3 = line	
--	memoryTimelineIndex = memoryTimelineIndex+1
end
local baseDir = system.pathForFile( "gameData.json", system.DocumentsDirectory)
baseDir = string.sub(baseDir, 1,-9)
local function extractFile(text)
	
	if(text == nil) then return nil end

	local start, finish = string.find(text, baseDir,0,true)

	 if(start == nil) then return nil end
	 local filename = string.sub(text, finish+1)
	 start, finish = string.find(filename, '\[^\\]+.lua')	
	local lineNum = string.sub(filename,finish+1)
	filename = string.sub(filename, 1, finish)
	
	 return filename, lineNum
end

local resolutionCounter = 0
local function returned(phase,l,err)
		debug.sethook (returned, "",0 )	
		if(phase=="error") then
			print(err)
		end
		local info = debug.getinfo(2,"Sln")
		local funcKey = info.source
		local lineKey = funcKey..info.currentline
		local isLuaFunction = currentParams.verbose or string.len(funcKey) > 6
		funcKey = funcKey..info.linedefined		

			if(functions[funcKey] == nil) then				
				functions[funcKey] = initFunction()
				--check if function is filtered
		--		local name, num = extractFile(funcKey)
			
				if(currentParams.fileFilters) then
					for j = 1, #currentParams.fileFilters do
						if(string.find(funcKey,currentParams.fileFilters[j]) ) then
							functions[funcKey].filtered = true
						end
					end
					--functions[funcKey].filtered = fileFilters
				end
			end		
				local func = functions[funcKey]	
			if(phase == "call" ) then
			
				if(isLuaFunction or currentParams.mode==1) then --we must profile all functions including the verbose ones in performance profiling b/c they are called by library functions

					local currentTime = system.getTimer() 
					func.numTimesCalled = func.numTimesCalled or 0
					func.numTimesCalled = func.numTimesCalled+1
					if(currentParams.mode==1) then
						func.previousTime = currentTime	
						func.initTime = currentTime 
					else
						if(not func.filtered) then
						collectgarbage("collect") 	
						func.initMemory = collectgarbage("count")	
						recordMemoryTimeline(funcKey, func.initMemory,1)
						end
					end
					local funcPrev = functions[previousFunction] 
					functions[previousFunction] = functions[previousFunction] or initFunction()
					if(previousFunction ~= funcKey) then
						functions[previousFunction].lineFunc[previousLineAll] = funcKey
					end
				func.functionCallers[previousFunction] = true
				end
				
			elseif(phase == "return" and (isLuaFunction or currentParams.mode==1)) then
				
				
				if(currentParams.mode == 4) then
					--func.stackIndex = 1 --so we can reset the local variable stack index
				elseif(currentParams.mode==1) then
					local currentTime = system.getTimer() 				
					func.timeTaken = func.timeTaken+currentTime - func.initTime
				else
					if(not func.filtered) then
					collectgarbage("collect") 
					local memory = collectgarbage("count")
					func.memoryTaken = func.memoryTaken+collectgarbage("count") - func.initMemory
					recordMemoryTimeline(previousFunction, collectgarbage("count"), 2)
					end
				end

		
	end
	
	if(phase == "line" and (isLuaFunction or currentParams.mode==1)) then		

		
		if(resolutionCounter == 0) then
		

		func.numTimesCalled = func.numTimesCalled or 1
		local previousLine = func.previousLine 
		local previousTime
		if(currentParams.mode==1) then
			previousTime = func.previousTime	
			local lineTimes = func.lineTime
			func.lineTime[previousLine] = func.lineTime[previousLine] or 0
			lineTimes[previousLine] = lineTimes[previousLine] + system.getTimer() - previousTime
		elseif(currentParams.mode==4) then
			local stackIndex = 1
			local key,v = debug.getlocal(2, stackIndex)
			
			while(key) do
			
				if(key:sub(1,1)~="(") then

					if(localsList[key.."|"..funcKey] == nil) then  
						localsList[key.."|"..funcKey] = {v} --linekey is line defined, funcKey is function name
					else 
						localsList[key.."|"..funcKey][1] = v 
					end
		
				end
				stackIndex = stackIndex+1
				key,v = debug.getlocal(2, stackIndex)
				
			end		
		
		else
			if(not func.filtered) then
			local lineMemory = func.lineMemory		
			func.lineMemory[previousLine] = func.lineMemory[previousLine] or 0	
			collectgarbage("collect") 
			local memory = collectgarbage("count")
					
			lineMemory[previousLine] = lineMemory[previousLine] + memory - previousMemory 
			previousMemory = memory
			recordMemoryTimeline(previousLine, memory, 3)
			end
		end
		func.lineCount[previousLine] =func.lineCount[previousLine] or 0
		func.lineCount[previousLine] = func.lineCount[previousLine] +1
		func.previousLine = lineKey
		func.previousTime = system.getTimer() 	
		resolutionCounter = currentParams.resolution			
		end
		resolutionCounter = resolutionCounter-1

		previousLineAll = lineKey
		previousFunction = funcKey	
	end
	debug.sethook (returned, "crl",0 )	
end
local function loadFile(filename)
		local lines = {}		

	
		local file = io.open( baseDir..filename, "r" )
		local contents = file:read("*a").."\n" --make sure file ends with newline
		--now get an iterator for the newline which can be LF, CR or combination
		local itr = string.gmatch(contents, "[^\r\f\n]*[\r\f\n]")
		--print("test", itr())	
		local lineIndex = 1
		for line in itr do
			lines[lineIndex] = line
			lineIndex = lineIndex+1
		end		
		return lines
end
local snapshotNum = 1
local globalsList = {}
profilerTable.fullSnapshot =  function(name)
	debug.sethook (returned, "",0 )	
	local changeList = {}--store it first so we can sort it later
	print("calculating full snapshot "..(name or snapshotNum).."...")
	for i,localv in pairs(localsList) do
		if(globalsBlacklist[localv]==nil) then

				
				local deltaM = tableSize(localv[1])
					local dividerIndex = i:find("|")
					filename,lineNum = extractFile(i:sub(dividerIndex+1))
					if(files[baseDir..filename] == nil) then
						files[baseDir..filename] = loadFile(filename)							
					end	
					if(filename~="Profiler.lua") then
						if(tonumber(lineNum)~=0) then
							local lineString = trim(files[baseDir..filename][tonumber(lineNum)])
							changeList[#changeList+1] = {deltaM, "<tr><td>"..deltaM.."</td><td>"..i:sub(1,dividerIndex-1).."</td><td>"..lineString.." in "..filename.."</td></tr>"}
						else
							changeList[#changeList+1] = {deltaM, "<tr><td>"..deltaM.."</td><td>"..i:sub(1,dividerIndex-1).."</td><td>"..filename.." (main chunk)</td></tr>"}
						end
					end
		end
	end
	---[[
	for i,globalv in pairs(_G) do
		if(globalsBlacklist[globalv]==nil) then
					local  deltaM =  tableSize(globalv)
					changeList[#changeList+1] = {deltaM, "<tr><td>"..deltaM.."</td><td>"..i.."</td><td>global</td></tr>"}			
		end
	end	
	--finally do a special case for the display objects

		local deltaM =display.getCurrentStage().numChildren
		changeList[#changeList+1] = {deltaM,  "<tr><td>"..deltaM.."</td><td>#Display Objects</td><td>global</td></tr>"}
	--]]
	--sort and print
	--changeList = sortTable(changeList)
	--also output to file snapshots.txt
		local file = io.open( system.pathForFile( "snapshot.html", system.DocumentsDirectory), "a+" )
		file:write([[<tr><td colspan="3">-------------------------full snapshot "]]..(name or snapshotNum)..[["--------------------------<td></tr>]])
		file:write([[<tr><td><strong>total size</strong></td><td><strong>var name</strong></td><td><strong>defined in</strong></td>]])
		table.sort(changeList, function(a,b) return a[1]>b[1] end)
		for i,v in ipairs(changeList) do
			file:write(v[2].."\n")
		end
		file:flush()
	snapshotNum = snapshotNum+1
	debug.sethook (returned, "crl",0 )	
end

profilerTable.diffSnapshot = function(name)
	debug.sethook (returned, "",0 )	
--[[
--]]
	local changeList = {}--store it first so we can sort it later
	print("calculating diff snapshot "..(name or snapshotNum).."...")
	for i,localv in pairs(localsList) do
		if(globalsBlacklist[localv]==nil) then
			if(localv[2]) then
				
				local deltaM = tableSize(localv[1])-localv[2]
				
				if(deltaM~=0) then --only if change
					local dividerIndex = i:find("|")					
					filename,lineNum = extractFile(i:sub(dividerIndex+1))
					if(files[baseDir..filename] == nil) then
						files[baseDir..filename] = loadFile(filename)							
					end	
					if(filename~="Profiler.lua") then
						if(tonumber(lineNum)~=0) then
							local lineString = trim(files[baseDir..filename][tonumber(lineNum)])
							changeList[#changeList+1] = {deltaM, "<tr><td>"..deltaM.."</td><td>"..i:sub(1,dividerIndex-1).."</td><td>"..lineString.." in "..filename.."</td></tr>"}
						else
							changeList[#changeList+1] = {deltaM, "<tr><td>"..deltaM.."</td><td>"..i:sub(1,dividerIndex-1).."</td><td>"..filename.." (main chunk)</td></tr>"}
							--print("varChange",deltaM,i:sub(1,dividerIndex-1),filename)
						end
					end
				end
			end
			localv[2] = tableSize(localv[1])
		end
	end
	---[[
	for i,globalv in pairs(_G) do
		if(globalsBlacklist[globalv]==nil) then
			if(globalsList[i]) then
				local  currentMem =  tableSize(globalv)
					local deltaM = currentMem-globalsList[i]
					if(deltaM~=0) then
						changeList[#changeList+1] = {deltaM, "<tr><td>"..deltaM.."</td><td>"..i.."</td><td>global</td></tr>"}
					end	
				globalsList[i] = tableSize(globalv)
			else
				globalsList[i] = tableSize(globalv)
				local deltaM = globalsList[i]
				changeList[#changeList+1] = {deltaM, "<tr><td>"..deltaM.."</td><td>"..i.."</td><td>global</td></tr>"}
			end
			
		end
	end	
	--finally do a special case for the display objects

	if(globalsList["number of objects"]) then
		local deltaM =display.getCurrentStage().numChildren-globalsList["number of objects"]
		if(deltaM~=0) then
			changeList[#changeList+1] = {deltaM,  "<tr><td>"..deltaM.."</td><td>#Display Objects</td><td>global</td></tr>"}
		end
	end
	globalsList["number of objects"] = display.getCurrentStage().numChildren
	--]]
	--sort and print
	--changeList = sortTable(changeList)
	--also output to file snapshots.txt
	if(snapshotNum>1) then
		local file = io.open( system.pathForFile( "snapshot.html", system.DocumentsDirectory), "a+" )
		file:write([[<tr><td colspan="3">-------------------------diff snapshot "]]..(name or snapshotNum)..[["--------------------------<td></tr>]])
		file:write([[<tr><td><strong>size increase</strong></td><td><strong>var name</strong></td><td><strong>defined in</strong></td>]])
		table.sort(changeList, function(a,b) return a[1]>b[1] end)
		for i,v in ipairs(changeList) do
			file:write(v[2].."\n")
		end
		file:flush()
	end
	snapshotNum = snapshotNum+1
	debug.sethook (returned, "crl",0 )		
end


local globalID = 1
local function generateObject(name,dim,color)
local obj = {}
obj.id = globalID
globalID = globalID+1
obj.name = name
obj.data = {}
obj.data["$area"] = 10
obj.data["$dim"] = dim+1
obj.data["$color"] = color
obj.children = {}
return obj
end


local objects 
local function expandNode(funcName,obj, depthLimit) --node is the profiler function, obj is the data viz. struct
local depth = depthLimit or 30
if(depth == 0) then --supress recursion
return
end
local node = functions[funcName]

local lineStatistic
if(currentParams.mode== 1) then
	lineStatistic = node.lineTime
else
	lineStatistic = node.lineMemory
end
local sortedLines = sortTable(lineStatistic)

	for i=1, math.min(maxFunctionsToShow,#sortedLines)do
		local line = sortedLines[i]
			if(line[2]>0) then
				local newChild = generateObject(line[1],line[2],"#9554ff")
			
				obj.children[#obj.children+1] = newChild
				local calledFunc = node.lineFunc[line[1]]
		

				if(calledFunc and (string.len(calledFunc) > 6 or currentParams.verbose) ) then  expandNode(calledFunc,newChild, depth-1) end
			end
	end
end

local function weighNodes(node)
	local children = node.children
	local sum = 0
	for i,child in ipairs(children) do
		sum = sum+child.data["$dim"]
	end
	for i,child in ipairs(children) do
		local fraction = math.round(child.data["$dim"]/sum*255)
		child.fraction = fraction
		weighNodes(child)
	end	

end





local function nameNodes(node)
	local children = node.children
	local filename,lineNum
	if(node) then
		filename,lineNum = extractFile(node.name)
	end
	local units = " ms/"
	if(currentParams.mode ~= 1) then
		units = " kb/"
	end
	if(filename ~= nil) then 
		if(files[baseDir..filename] == nil) then
	
			files[baseDir..filename] = loadFile(filename)
			
		end	
		local fraction = node.fraction
		node.data["$color"] = "rgb("..fraction..","..(255-fraction)..","..(50)..")"
		node.name = [[<p><b>]].."("..math.round(node.data["$dim"])..units..math.round(fraction*(100/255)).."%) "..filename.." : "..lineNum..[[</b></p><p>]]..trim(files[baseDir..filename][tonumber(lineNum)])..[[</p>]]
	else
		local fraction = node.fraction
		node.name = [[<p><b>]].."("..math.round(node.data["$dim"])..units..math.round(fraction*(100/255)).."%) "..node.name..[[</b></p>]]
		node.data["$color"] = "rgb("..(100+math.round(fraction*.1))..","..(100+math.round((255-fraction)*.1))..","..(100)..")"
	end
	
		for i,child in ipairs(children) do
			nameNodes(child)
		end		
end
local function generateReport()
	collectgarbage("collect")
	deltaMem = collectgarbage("count") - initMemory
	collectgarbage("restart")
	deltaT = system.getTimer()- initTime
	if currentParams.mode== 1 then	
		objects = generateObject("All Functions",deltaT,"#9554ff")
	else
		objects = generateObject("All Functions",deltaMem,"#9554ff")
	end
	objects.fraction = 255
	print("profiler stopped, change in memory is: "..deltaMem.." KB (large positive numbers may indicate a memory leak")
	local sortedFunctions = sortTable(functions)
	for i=1, math.min(maxFunctionsToShow,#sortedFunctions) do 
		local v = sortedFunctions[i]
	if(string.len(v[1]) > 6 or currentParams.verbose) then
		local newObj 
		if currentParams.mode== 1 then
		newObj = generateObject(v[1],v[2].timeTaken,"#9554ff")
		else
		newObj = generateObject(v[1],v[2].memoryTaken,"#9554ff")
		end
		objects.children[#objects.children+1] = newObj		
		expandNode(v[1],newObj)
			end
	end
weighNodes(objects)
nameNodes(objects)
	local path = system.pathForFile( currentParams.name..".profile"..currentParams.mode, system.DocumentsDirectory)
	local file = io.open( path, "w" ) 
	if file then
			file:write( "var json = "..json.encode(objects) ) 
			io.close( file )
	end	



end
local function stringToJavascript(lineString)
	lineString = string.gsub(lineString, [[\]],[[\\]])
	lineString = string.gsub(lineString, [["]],[[\"]])
	return lineString
end
profilerTable.viewProfilerResult = function(name, mode, maxLines)
		name = name or "default"
		maxLines = maxLines or math.huge
		currentParams.mode = mode or currentParams.mode
		local lines = {}		
		local path 
		
		if(mode== 1 or mode== 2) then
			path = system.pathForFile(  name..".profile"..mode, system.DocumentsDirectory )
			
			local filer = io.open( path, "r" )
			path = system.pathForFile( "jsonData.js", system.DocumentsDirectory)
			local filew = io.open( path, "w" ) 		
			if(filer and filew) then
				local lineIndex = 1
					for line in filer:lines() do 
						filew:write( line ) 
					end		
				io.close(filer)
				io.close( filew )
			end
			path = system.pathForFile( "profileTime.html", system.DocumentsDirectory)
		else

		

		--generate the timeline report as an inline HTML data	
		path = system.pathForFile( "profileTimeline.html", system.DocumentsDirectory)
		local filew = io.open( path, "w" ) 		
		if(filew) then
		if(filetimeline) then
		io.close(filetimeline)
		end

	
			--local filetimeline = io.open( system.pathForFile( "profileTimeline.txt", system.DocumentsDirectory), "r" ) 	
			--generate the timeline data structure
 
		local filetimeline = io.open( system.pathForFile( name..".timeline", system.DocumentsDirectory), "r" ) 	
		
		local itr = filetimeline:lines()
			--filetimeline:write(funcKey.."\n"..memory.."\n"..event.."\n")
			local timelineStruct = {}
			local index = 1
			for line in itr do
				timelineStruct[index] = {}
				timelineStruct[index].funcKey = line
				timelineStruct[index].memory = itr()
				timelineStruct[index].event = itr()
				index = index+1
				if(index >= maxLines) then
					io.close(filetimeline)
					break
				end
			end
			--local filetimelineAnnotation = io.open( system.pathForFile( "profileTimelineAnnotations.txt", system.DocumentsDirectory), "r" ) 	
			--write header
			filew:write(timelineHTMLTop)
			--line variable definition goes here
			local event,filename,lineNum,currentFunction
			currentFunction = ""
			for i = 1, #timelineStruct do
				item = timelineStruct[i]
				event = tonumber(item.event)	
					if( string.len(item.funcKey) > 6 ) then
						filename,lineNum = extractFile(item.funcKey)
						if(files[baseDir..filename] == nil) then
							files[baseDir..filename] = loadFile(filename)							
						end	
						local lineString = trim(files[baseDir..filename][tonumber(lineNum)])		
						if(tonumber(item.event) == 1) then
							currentFunction = lineString
							
						end
						filew:write([["]]..stringToJavascript(currentFunction)..[[\n(]]..filename.." line# "..lineNum..") -> "..stringToJavascript(lineString)..[[",]])					
					else
						filew:write([["]]..item.funcKey..[[",]])					
					end			
			end
			filew:write(timelineHTMLTop2)
			--timeline data goes here has to be in the format
			local item
			local subIndex = 1 --different from i b/c we skip C and R events b/c these interfere
			local series1 = true --alternate series for different colors
			local consecutive = false
			for i = 1, #timelineStruct do
				item = timelineStruct[i]
				event = tonumber(item.event)
				
				if(series1) then
					filew:write("["..i..","..item.memory..",null],")
				else
					filew:write("["..i..",null,"..item.memory.."],")
				end
				if(tonumber(item.event) == 1) then
					series1 = not series1
				end
				subIndex = subIndex+1
			end
		
			--	filew:write(filetimeline:read("*a"))

			
			--write middle
			filew:write(timelineHTMLMiddle)
			--annotations go here
			
		
		--	filew:write(filetimelineAnnotation:read("*a"))
			
			filew:write(timelineHTMLEnd)
			io.close( filew )
		end
		end
        print( "Big3 path: " .. path )
		system.openURL(path)
end
profilerTable.stopDebugger = function()
if(profilerTimer) then timer.cancel(profilerTimer) end
debug.sethook (returned, "", 0 )
generateReport()

profilerTable.viewProfilerResult (currentParams.name,currentParams.mode )
files = {}
end

profilerTable.startProfiler = function(params)
collectgarbage("collect")
initMemory = collectgarbage("count")
collectgarbage("stop")
if(params == nil) then params = {} end
params.name = params.name  or "default"
params.time = params.time  or 5000
params.verbose = params.verbose or false
params.mode = params.mode or 1
params.fileFilters =  params.fileFilters or nil
params.resolution = params.resolution or 1

-- prevent infinite delay cycle
if(params.delay) then
	timer.performWithDelay(params.delay, function() params.delay = nil ;profilerTable.startProfiler(params) end)
	return
end

functions = {["main"] = initFunction()}
currentParams = params
if(params.mode ~= 1) then
	filetimeline = io.open( system.pathForFile( currentParams.name..".timeline", system.DocumentsDirectory), "w" ) 	 
end
if(params.mode==4) then
	for i,v in pairs(_G) do
		globalsBlacklist[v] = true --dont profile corona stuff
	end
	local path =  system.pathForFile( "snapshot.html", system.DocumentsDirectory)
	local file = io.open( path, "w" ) --clear the file
	file:write([[<head><meta http-equiv="refresh" content="1"/></head><table border="1">]])
--	system.openURL(path)
else
	profilerTimer = timer.performWithDelay(params.time or 1000, profilerTable.stopDebugger)
end
print("profiler started", currentParams.name, params.mode)

initTime = system.getTimer()
previousFunction = "main"
previousMemory = 0
previousLineAll = 0
debug.sethook (returned, "crl",0 )

end



-----------------------------------------------------------------EMBEDDED FILES

local function createResourceFile(data, filename)
	local path = system.pathForFile( filename, system.DocumentsDirectory)
	local file = io.open( path, "w" ) 
	if file then
			file:write( data ) 
			io.close( file )
	end	
end
local resourceFile
if(io.open( system.pathForFile( "codemirror.js", system.DocumentsDirectory), "r" ) == nil) then 
resourceFile = [[html, body {
    margin:0;
    padding:0;
    font-family: "Lucida Grande", Verdana;
    font-size: 0.9em;
    text-align: center;
    background-color:#F2F2F2;
}

input, select {
    font-size:0.9em;
}

table {
    margin-top:-10px;
    margin-left:7px;
}

h4 {
    font-size:1.1em;
    text-decoration:none;
    font-weight:normal;
    color:#23A4FF;
}

a {
    color:#23A4FF;
}

#container {
    width: 100%;
    height: 100%;
    margin:0 auto;
    position:relative;
}

#left-container, 
#right-container, 
#center-container {
    height:700px;
    position:absolute;
    top:0;
}

#left-container, #right-container {
    width:18%;
    color:#686c70;
    text-align: left;
    overflow: auto;
    background-color:#fff;
    background-repeat:no-repeat;
    border-bottom:1px solid #ddd;
}

#left-container {
    left:0;
    background-image:url('col2.png');
    background-position:center right;
    border-left:1px solid #ddd;
    
}

#right-container {
    right:0;
    background-image:url('col1.png');
    background-position:center left;
    border-right:1px solid #ddd;
}

#right-container h4{
    text-indent:8px;
}

#center-container {
    width:600px;
    left:18%;
    background-color:#1a1a1a;
    color:#ccc;
}

.text {
    margin: 7px;
}

#inner-details {
    font-size:0.8em;
    list-style:none;
    margin:7px;
}

#log {
    position:absolute;
    top:10px;
    font-size:1.0em;
    font-weight:bold;
    color:#23A4FF;
}


#infovis {
    position:relative;
    width:600px;
    height:100%;
    margin:auto;
    overflow:hidden;
}

/*TOOLTIPS*/
.tip {
    color: #111;
    width: 139px;
    background-color: white;
    border:1px solid #ccc;
    -moz-box-shadow:#555 2px 2px 8px;
    -webkit-box-shadow:#555 2px 2px 8px;
    -o-box-shadow:#555 2px 2px 8px;
    box-shadow:#555 2px 2px 8px;
    opacity:0.9;
    filter:alpha(opacity=90);
    font-size:10px;
    font-family:Verdana, Geneva, Arial, Helvetica, sans-serif;
    padding:7px;
}]]

createResourceFile(resourceFile,"base.css")
	
resourceFile = [[#update {
  margin:10px 40px;
}

.button {
  display: inline-block;
  outline: none;
  cursor: pointer;
  text-align: center;
  text-decoration: none;
  font: 14px / 100% Arial, Helvetica, sans-serif;
  padding: 0.5em 1em 0.55em;
  text-shadow: 0px 1px 1px rgba(0, 0, 0, 0.3);
  -webkit-border-radius: 0.5em;
  -moz-border-radius: 0.5em;
  border-radius: 0.5em;
  -webkit-box-shadow: 0px 1px 2px rgba(0, 0, 0, 0.2);
  -moz-box-shadow: 0px 1px 2px rgba(0, 0, 0, 0.2);
  box-shadow: 0px 1px 2px rgba(0, 0, 0, 0.2);
}

.button:hover {
  text-decoration: none;
}

.button:active {
  position: relative;
  top: 1px;
}

/* white */
.white {
  color: #606060;
  border: solid 1px #b7b7b7;
  background: #fff;
  background: -webkit-gradient(linear, left top, left bottom, from(#fff), to(#ededed));
  background: -moz-linear-gradient(top,  #fff,  #ededed);
  filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#ffffff', endColorstr='#ededed');
}

.white:hover {
  background: #ededed;
  background: -webkit-gradient(linear, left top, left bottom, from(#fff), to(#dcdcdc));
  background: -moz-linear-gradient(top,  #fff,  #dcdcdc);
  filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#ffffff', endColorstr='#dcdcdc');
}

.white:active {
  color: #999;
  background: -webkit-gradient(linear, left top, left bottom, from(#ededed), to(#fff));
  background: -moz-linear-gradient(top,  #ededed,  #fff);
  filter:  progid:DXImageTransform.Microsoft.gradient(startColorstr='#ededed', endColorstr='#ffffff');
}


.tip {
   text-align: left;
   width:auto;
   max-width:500px;
}

.tip-title {
  font-size: 11px;
  text-align:center;
  margin-bottom:2px;
}

#right-container {
  display: none;
}

#center-container {
  width:80%;
}

#infovis {
  width:100%;
}

]]

createResourceFile(resourceFile,"Icicle.css")

resourceFile = 
[[ (function(){window.$jit=function(a){var a=a||window,b;for(b in $jit)$jit[b].$extend&&(a[b]=$jit[b])};$jit.version="2.0.1";var g=function(a){return document.getElementById(a)};g.empty=function(){};g.extend=function(a,b){for(var c in b||{})a[c]=b[c];return a};g.lambda=function(a){return"function"==typeof a?a:function(){return a}};g.time=Date.now||function(){return+new Date};g.splat=function(a){var b=g.type(a);return b?"array"!=b?[a]:a:[]};g.type=function(a){var b=g.type.s.call(a).match(/^\[object\s(.*)\]$/)[1].toLowerCase();
return"object"!=b?b:a&&a.$$family?a.$$family:a&&a.nodeName&&1==a.nodeType?"element":b};g.type.s=Object.prototype.toString;g.each=function(a,b){if("object"==g.type(a))for(var c in a)b(a[c],c);else{c=0;for(var d=a.length;c<d;c++)b(a[c],c)}};g.indexOf=function(a,b){if(Array.indexOf)return a.indexOf(b);for(var c=0,d=a.length;c<d;c++)if(a[c]===b)return c;return-1};g.map=function(a,b){var c=[];g.each(a,function(a,e){c.push(b(a,e))});return c};g.reduce=function(a,b,c){var d=a.length;if(0==d)return c;for(var e=
3==arguments.length?c:a[--d];d--;)e=b(e,a[d]);return e};g.merge=function(){for(var a={},b=0,c=arguments.length;b<c;b++){var d=arguments[b];if("object"==g.type(d))for(var e in d){var f=d[e],h=a[e];a[e]=h&&"object"==g.type(f)&&"object"==g.type(h)?g.merge(h,f):g.unlink(f)}}return a};g.unlink=function(a){var b;switch(g.type(a)){case "object":b={};for(var c in a)b[c]=g.unlink(a[c]);break;case "array":b=[];c=0;for(var d=a.length;c<d;c++)b[c]=g.unlink(a[c]);break;default:return a}return b};g.zip=function(){if(0===
arguments.length)return[];for(var a=0,b=[],c=arguments.length,d=arguments[0].length;a<d;a++){for(var e=0,f=[];e<c;e++)f.push(arguments[e][a]);b.push(f)}return b};g.rgbToHex=function(a,b){if(3>a.length)return null;if(4==a.length&&0==a[3]&&!b)return"transparent";for(var c=[],d=0;3>d;d++){var e=(a[d]-0).toString(16);c.push(1==e.length?"0"+e:e)}return b?c:"#"+c.join("")};g.hexToRgb=function(a){if(7!=a.length){a=a.match(/^#?(\w{1,2})(\w{1,2})(\w{1,2})$/);a.shift();if(3!=a.length)return null;for(var b=
[],c=0;3>c;c++){var d=a[c];1==d.length&&(d+=d);b.push(parseInt(d,16))}return b}a=parseInt(a.slice(1),16);return[a>>16,a>>8&255,a&255]};g.destroy=function(a){g.clean(a);a.parentNode&&a.parentNode.removeChild(a);a.clearAttributes&&a.clearAttributes()};g.clean=function(a){for(var a=a.childNodes,b=0,c=a.length;b<c;b++)g.destroy(a[b])};g.addEvent=function(a,b,c){a.addEventListener?a.addEventListener(b,c,!1):a.attachEvent("on"+b,c)};g.addEvents=function(a,b){for(var c in b)g.addEvent(a,c,b[c])};g.hasClass=
function(a,b){return-1<(" "+a.className+" ").indexOf(" "+b+" ")};g.addClass=function(a,b){if(!g.hasClass(a,b))a.className=a.className+" "+b};g.removeClass=function(a,b){a.className=a.className.replace(RegExp("(^|\\s)"+b+"(?:\\s|$)"),"$1")};g.getPos=function(a){var b=function(a){for(var b={x:0,y:0};a&&!/^(?:body|html)$/i.test(a.tagName);)b.x+=a.offsetLeft,b.y+=a.offsetTop,a=a.offsetParent;return b}(a),a=function(a){for(var b={x:0,y:0};a&&!/^(?:body|html)$/i.test(a.tagName);)b.x+=a.scrollLeft,b.y+=
a.scrollTop,a=a.parentNode;return b}(a);return{x:b.x-a.x,y:b.y-a.y}};g.event={get:function(a,b){return a||(b||window).event},getWheel:function(a){return a.wheelDelta?a.wheelDelta/120:-(a.detail||0)/3},isRightClick:function(a){return 3==a.which||2==a.button},getPos:function(a,b){var b=b||window,a=a||b.event,c=b.document,c=c.documentElement||c.body;a.touches&&a.touches.length&&(a=a.touches[0]);return{x:a.pageX||a.clientX+c.scrollLeft,y:a.pageY||a.clientY+c.scrollTop}},stop:function(a){a.stopPropagation&&
a.stopPropagation();a.cancelBubble=!0;a.preventDefault?a.preventDefault():a.returnValue=!1}};$jit.util=$jit.id=g;var k=function(a){var a=a||{},b=function(){for(var a in this)"function"!=typeof this[a]&&(this[a]=g.unlink(this[a]));this.constructor=b;if(k.prototyping)return this;a=this.initialize?this.initialize.apply(this,arguments):this;this.$$family="class";return a},c;for(c in k.Mutators)a[c]&&(a=k.Mutators[c](a,a[c]),delete a[c]);g.extend(b,this);b.constructor=k;b.prototype=a;return b};k.Mutators=
{Implements:function(a,b){g.each(g.splat(b),function(b){k.prototyping=b;var b="function"==typeof b?new b:b,d;for(d in b)d in a||(a[d]=b[d]);delete k.prototyping});return a}};g.extend(k,{inherit:function(a,b){for(var c in b){var d=b[c],e=a[c],f=g.type(d);e&&"function"==f?d!=e&&k.override(a,c,d):a[c]="object"==f?g.merge(e,d):d}return a},override:function(a,b,c){var d=k.prototyping;d&&a[b]!=d[b]&&(d=null);a[b]=function(){var e=this.parent;this.parent=d?d[b]:a[b];var f=c.apply(this,arguments);this.parent=
e;return f}}});k.prototype.implement=function(){var a=this.prototype;g.each(Array.prototype.slice.call(arguments||[]),function(b){k.inherit(a,b)});return this};$jit.Class=k;$jit.json={prune:function(a,b){this.each(a,function(a,d){if(d==b&&a.children)delete a.children,a.children=[]})},getParent:function(a,b){if(a.id==b)return!1;var c=a.children;if(c&&0<c.length)for(var d=0;d<c.length;d++){if(c[d].id==b)return a;var e=this.getParent(c[d],b);if(e)return e}return!1},getSubtree:function(a,b){if(a.id==
b)return a;for(var c=0,d=a.children;d&&c<d.length;c++){var e=this.getSubtree(d[c],b);if(null!=e)return e}return null},eachLevel:function(a,b,c,d){if(b<=c&&(d(a,b),a.children))for(var e=0,a=a.children;e<a.length;e++)this.eachLevel(a[e],b+1,c,d)},each:function(a,b){this.eachLevel(a,0,Number.MAX_VALUE,b)}};$jit.Trans={$extend:!0,linear:function(a){return a}};var x=$jit.Trans;(function(){var a=function(a,c){c=g.splat(c);return g.extend(a,{easeIn:function(d){return a(d,c)},easeOut:function(d){return 1-
a(1-d,c)},easeInOut:function(d){return 0.5>=d?a(2*d,c)/2:(2-a(2*(1-d),c))/2}})};g.each({Pow:function(a,c){return Math.pow(a,c[0]||6)},Expo:function(a){return Math.pow(2,8*(a-1))},Circ:function(a){return 1-Math.sin(Math.acos(a))},Sine:function(a){return 1-Math.sin((1-a)*Math.PI/2)},Back:function(a,c){c=c[0]||1.618;return Math.pow(a,2)*((c+1)*a-c)},Bounce:function(a){for(var c,d=0,e=1;;d+=e,e/=2)if(a>=(7-4*d)/11){c=e*e-Math.pow((11-6*d-11*a)/4,2);break}return c},Elastic:function(a,c){return Math.pow(2,
10*--a)*Math.cos(20*a*Math.PI*(c[0]||1)/3)}},function(b,c){x[c]=a(b)});g.each(["Quad","Cubic","Quart","Quint"],function(b,c){x[b]=a(function(a){return Math.pow(a,[c+2])})})})();var B=new k({initialize:function(a){this.setOptions(a)},setOptions:function(a){this.opt=g.merge({duration:2500,fps:40,transition:x.Quart.easeInOut,compute:g.empty,complete:g.empty,link:"ignore"},a||{});return this},step:function(){var a=g.time(),b=this.opt;a<this.time+b.duration?(a=b.transition((a-this.time)/b.duration),b.compute(a)):
(this.timer=clearInterval(this.timer),b.compute(1),b.complete())},start:function(){if(!this.check())return this;this.time=0;this.startTimer();return this},startTimer:function(){var a=this,b=this.opt.fps;if(this.timer)return!1;this.time=g.time()-this.time;this.timer=setInterval(function(){a.step()},Math.round(1E3/b));return!0},pause:function(){this.stopTimer();return this},resume:function(){this.startTimer();return this},stopTimer:function(){if(!this.timer)return!1;this.time=g.time()-this.time;this.timer=
clearInterval(this.timer);return!0},check:function(){if(!this.timer)return!0;return"cancel"==this.opt.link?(this.stopTimer(),!0):!1}}),q=function(){for(var a=arguments,b=0,c=a.length,d={};b<c;b++){var e=q[a[b]].."]]"..[[;e.$extend?g.extend(d,e):d[a[b]].."]]"..[[=e}return d};q.Canvas={$extend:!0,injectInto:"id",type:"2D",width:!1,height:!1,useCanvas:!1,withLabels:!0,background:!1,Scene:{Lighting:{enable:!1,ambient:[1,1,1],directional:{direction:{x:-100,y:-100,z:-100},color:[0.5,0.3,0.1]}}}};q.Tree={$extend:!0,orientation:"left",
subtreeOffset:8,siblingOffset:5,indent:10,multitree:!1,align:"center"};q.Node={$extend:!1,overridable:!1,type:"circle",color:"#ccb",alpha:1,dim:3,height:20,width:90,autoHeight:!1,autoWidth:!1,lineWidth:1,transform:!0,align:"center",angularWidth:1,span:1,CanvasStyles:{}};q.Edge={$extend:!1,overridable:!1,type:"line",color:"#ccb",lineWidth:1,dim:15,alpha:1,epsilon:7,CanvasStyles:{}};q.Fx={$extend:!0,fps:40,duration:2500,transition:$jit.Trans.Quart.easeInOut,clearCanvas:!0};q.Label={$extend:!1,overridable:!1,
type:"HTML",style:" ",size:10,family:"sans-serif",textAlign:"center",textBaseline:"alphabetic",color:"#fff"};q.Tips={$extend:!1,enable:!1,type:"auto",offsetX:20,offsetY:20,force:!1,onShow:g.empty,onHide:g.empty};q.Navigation={$extend:!1,enable:!1,type:"auto",panning:!1,zooming:!1};q.NodeStyles={$extend:!1,enable:!1,type:"auto",stylesHover:!1,stylesClick:!1};q.Events={$extend:!1,enable:!1,enableForEdges:!1,type:"auto",onClick:g.empty,onRightClick:g.empty,onMouseMove:g.empty,onMouseEnter:g.empty,onMouseLeave:g.empty,
onDragStart:g.empty,onDragMove:g.empty,onDragCancel:g.empty,onDragEnd:g.empty,onTouchStart:g.empty,onTouchMove:g.empty,onTouchEnd:g.empty,onMouseWheel:g.empty};q.Controller={$extend:!0,onBeforeCompute:g.empty,onAfterCompute:g.empty,onCreateLabel:g.empty,onPlaceLabel:g.empty,onComplete:g.empty,onBeforePlotLine:g.empty,onAfterPlotLine:g.empty,onBeforePlotNode:g.empty,onAfterPlotNode:g.empty,request:!1};var s={initialize:function(a,b){this.viz=b;this.canvas=b.canvas;this.config=b.config[a];this.nodeTypes=
b.fx.nodeTypes;var c=this.config.type;this.labelContainer=(this.dom="auto"==c?"Native"!=b.config.Label.type:"Native"!=c)&&b.labels.getLabelContainer();this.isEnabled()&&this.initializePost()},initializePost:g.empty,setAsProperty:g.lambda(!1),isEnabled:function(){return this.config.enable},isLabel:function(a,b,c){var a=g.event.get(a,b),b=this.labelContainer,d=a.target||a.srcElement,a=a.relatedTarget;return c?a&&a==this.viz.canvas.getCtx().canvas&&!!d&&this.isDescendantOf(d,b):this.isDescendantOf(d,
b)},isDescendantOf:function(a,b){for(;a&&a.parentNode;){if(a.parentNode==b)return a;a=a.parentNode}return!1}},y={onMouseUp:g.empty,onMouseDown:g.empty,onMouseMove:g.empty,onMouseOver:g.empty,onMouseOut:g.empty,onMouseWheel:g.empty,onTouchStart:g.empty,onTouchMove:g.empty,onTouchEnd:g.empty,onTouchCancel:g.empty},D=new k({initialize:function(a){this.viz=a;this.canvas=a.canvas;this.edge=this.node=!1;this.registeredObjects=[];this.attachEvents()},attachEvents:function(){var a=this.canvas.getElement(),
b=this;a.oncontextmenu=g.lambda(!1);g.addEvents(a,{mouseup:function(a,c){var f=g.event.get(a,c);b.handleEvent("MouseUp",a,c,b.makeEventObject(a,c),g.event.isRightClick(f))},mousedown:function(a,c){var f=g.event.get(a,c);b.handleEvent("MouseDown",a,c,b.makeEventObject(a,c),g.event.isRightClick(f))},mousemove:function(a,c){b.handleEvent("MouseMove",a,c,b.makeEventObject(a,c))},mouseover:function(a,c){b.handleEvent("MouseOver",a,c,b.makeEventObject(a,c))},mouseout:function(a,c){b.handleEvent("MouseOut",
a,c,b.makeEventObject(a,c))},touchstart:function(a,c){b.handleEvent("TouchStart",a,c,b.makeEventObject(a,c))},touchmove:function(a,c){b.handleEvent("TouchMove",a,c,b.makeEventObject(a,c))},touchend:function(a,c){b.handleEvent("TouchEnd",a,c,b.makeEventObject(a,c))}});var c=function(a,c){var f=g.event.get(a,c),f=g.event.getWheel(f);b.handleEvent("MouseWheel",a,c,f)};!document.getBoxObjectFor&&null==window.mozInnerScreenX?g.addEvent(a,"mousewheel",c):a.addEventListener("DOMMouseScroll",c,!1)},register:function(a){this.registeredObjects.push(a)},
handleEvent:function(){for(var a=Array.prototype.slice.call(arguments),b=a.shift(),c=0,d=this.registeredObjects,e=d.length;c<e;c++)d[c]["on"+b].apply(d[c],a)},makeEventObject:function(a,b){var c=this,d=this.viz.graph,e=this.viz.fx,f=e.nodeTypes,h=e.edgeTypes;return{pos:!1,node:!1,edge:!1,contains:!1,getNodeCalled:!1,getEdgeCalled:!1,getPos:function(){var d=c.viz.canvas,e=d.getSize(),f=d.getPos(),h=d.translateOffsetX,p=d.translateOffsetY,w=d.scaleOffsetX,d=d.scaleOffsetY,k=g.event.getPos(a,b);return this.pos=
{x:1*(k.x-f.x-e.width/2-h)/w,y:1*(k.y-f.y-e.height/2-p)/d}},getNode:function(){if(this.getNodeCalled)return this.node;this.getNodeCalled=!0;for(var a in d.nodes){var b=d.nodes[a],h=b&&f[b.getData("type")];if(h=h&&h.contains&&h.contains.call(e,b,this.getPos()))return this.contains=h,c.node=this.node=b}return c.node=this.node=!1},getEdge:function(){if(this.getEdgeCalled)return this.edge;this.getEdgeCalled=!0;var a={},b;for(b in d.edges){var f=d.edges[b];a[b]=!0;for(var g in f)if(!(g in a)){var p=f[g],
w=p&&h[p.getData("type")];if(w=w&&w.contains&&w.contains.call(e,p,this.getPos()))return this.contains=w,c.edge=this.edge=p}}return c.edge=this.edge=!1},getContains:function(){if(this.getNodeCalled)return this.contains;this.getNode();return this.contains}}}}),u={initializeExtras:function(){var a=new D(this),b=this;g.each(["NodeStyles","Tips","Navigation","Events"],function(c){var d=new u.Classes[c](c,b);d.isEnabled()&&a.register(d);d.setAsProperty()&&(b[c.toLowerCase()]=d)})},Classes:{}};u.Classes.Events=
new k({Implements:[s,y],initializePost:function(){this.fx=this.viz.fx;this.ntypes=this.viz.fx.nodeTypes;this.etypes=this.viz.fx.edgeTypes;this.moved=this.touchMoved=this.touched=this.pressed=this.hovered=!1},setAsProperty:g.lambda(!0),onMouseUp:function(a,b,c,d){a=g.event.get(a,b);if(!this.moved)if(d)this.config.onRightClick(this.hovered,c,a);else this.config.onClick(this.pressed,c,a);if(this.pressed){if(this.moved)this.config.onDragEnd(this.pressed,c,a);else this.config.onDragCancel(this.pressed,
c,a);this.pressed=this.moved=!1}},onMouseOut:function(a,b,c){var d=g.event.get(a,b),e;if(this.dom&&(e=this.isLabel(a,b,!0)))this.config.onMouseLeave(this.viz.graph.getNode(e.id),c,d),this.hovered=!1;else{a=d.relatedTarget;for(b=this.canvas.getElement();a&&a.parentNode;){if(b==a.parentNode)return;a=a.parentNode}if(this.hovered)this.config.onMouseLeave(this.hovered,c,d),this.hovered=!1}},onMouseOver:function(a,b,c){var d=g.event.get(a,b),e;if(this.dom&&(e=this.isLabel(a,b,!0)))this.hovered=this.viz.graph.getNode(e.id),
this.config.onMouseEnter(this.hovered,c,d)},onMouseMove:function(a,b,c){a=g.event.get(a,b);if(this.pressed)this.moved=!0,this.config.onDragMove(this.pressed,c,a);else if(this.dom)this.config.onMouseMove(this.hovered,c,a);else{if(this.hovered){var b=this.hovered,d=b.nodeFrom?this.etypes[b.getData("type")]:this.ntypes[b.getData("type")];if(d&&d.contains&&d.contains.call(this.fx,b,c.getPos())){this.config.onMouseMove(b,c,a);return}this.config.onMouseLeave(b,c,a);this.hovered=!1}if(this.hovered=c.getNode()||
this.config.enableForEdges&&c.getEdge())this.config.onMouseEnter(this.hovered,c,a);else this.config.onMouseMove(!1,c,a)}},onMouseWheel:function(a,b,c){this.config.onMouseWheel(c,g.event.get(a,b))},onMouseDown:function(a,b,c){var d=g.event.get(a,b);if(this.dom){if(a=this.isLabel(a,b))this.pressed=this.viz.graph.getNode(a.id)}else this.pressed=c.getNode()||this.config.enableForEdges&&c.getEdge();this.pressed&&this.config.onDragStart(this.pressed,c,d)},onTouchStart:function(a,b,c){var d=g.event.get(a,
b),e;(this.touched=this.dom&&(e=this.isLabel(a,b))?this.viz.graph.getNode(e.id):c.getNode()||this.config.enableForEdges&&c.getEdge())&&this.config.onTouchStart(this.touched,c,d)},onTouchMove:function(a,b,c){a=g.event.get(a,b);if(this.touched)this.touchMoved=!0,this.config.onTouchMove(this.touched,c,a)},onTouchEnd:function(a,b,c){a=g.event.get(a,b);if(this.touched){if(this.touchMoved)this.config.onTouchEnd(this.touched,c,a);else this.config.onTouchCancel(this.touched,c,a);this.touched=this.touchMoved=
!1}}});u.Classes.Tips=new k({Implements:[s,y],initializePost:function(){if(document.body){var a=g("_tooltip")||document.createElement("div");a.id="_tooltip";a.className="tip";g.extend(a.style,{position:"absolute",display:"none",zIndex:13E3});document.body.appendChild(a);this.tip=a;this.node=!1}},setAsProperty:g.lambda(!0),onMouseOut:function(a,b){g.event.get(a,b);if(this.dom&&this.isLabel(a,b,!0))this.hide(!0);else{for(var c=a.relatedTarget,d=this.canvas.getElement();c&&c.parentNode;){if(d==c.parentNode)return;
c=c.parentNode}this.hide(!1)}},onMouseOver:function(a,b){var c;if(this.dom&&(c=this.isLabel(a,b,!1)))this.node=this.viz.graph.getNode(c.id),this.config.onShow(this.tip,this.node,c)},onMouseMove:function(a,b,c){this.dom&&this.isLabel(a,b)&&this.setTooltipPosition(g.event.getPos(a,b));if(!this.dom){var d=c.getNode();if(d){if(this.config.force||!this.node||this.node.id!=d.id)this.node=d,this.config.onShow(this.tip,d,c.getContains());this.setTooltipPosition(g.event.getPos(a,b))}else this.hide(!0)}},setTooltipPosition:function(a){var b=
this.tip,c=b.style,d=this.config;c.display="";var e=document.body.clientWidth,f=b.offsetWidth,b=b.offsetHeight,h=d.offsetX,d=d.offsetY;c.top=(a.y+d+b>document.body.clientHeight?a.y-b-d:a.y+d)+"px";c.left=(a.x+f+h>e?a.x-f-h:a.x+h)+"px"},hide:function(a){this.tip.style.display="none";a&&this.config.onHide()}});u.Classes.NodeStyles=new k({Implements:[s,y],initializePost:function(){this.fx=this.viz.fx;this.types=this.viz.fx.nodeTypes;this.nStyles=this.config;this.nodeStylesOnHover=this.nStyles.stylesHover;
this.nodeStylesOnClick=this.nStyles.stylesClick;this.hoveredNode=!1;this.fx.nodeFxAnimation=new B;this.move=this.down=!1},onMouseOut:function(a,b){this.down=this.move=!1;if(this.hoveredNode){this.dom&&this.isLabel(a,b,!0)&&this.toggleStylesOnHover(this.hoveredNode,!1);for(var c=a.relatedTarget,d=this.canvas.getElement();c&&c.parentNode;){if(d==c.parentNode)return;c=c.parentNode}this.toggleStylesOnHover(this.hoveredNode,!1);this.hoveredNode=!1}},onMouseOver:function(a,b){var c;if(this.dom&&(c=this.isLabel(a,
b,!0)))if(c=this.viz.graph.getNode(c.id),!c.selected)this.hoveredNode=c,this.toggleStylesOnHover(this.hoveredNode,!0)},onMouseDown:function(a,b,c,d){if(!d){var e;if(this.dom&&(e=this.isLabel(a,b)))this.down=this.viz.graph.getNode(e.id);else if(!this.dom)this.down=c.getNode();this.move=!1}},onMouseUp:function(a,b,c,d){if(!d){if(!this.move)this.onClick(c.getNode());this.down=this.move=!1}},getRestoredStyles:function(a,b){var c={},d=this["nodeStylesOn"+b],e;for(e in d)c[e]=a.styles["$"+e];return c},
toggleStylesOnHover:function(a,b){this.nodeStylesOnHover&&this.toggleStylesOn("Hover",a,b)},toggleStylesOnClick:function(a,b){this.nodeStylesOnClick&&this.toggleStylesOn("Click",a,b)},toggleStylesOn:function(a,b,c){var d=this.viz;if(c){if(!b.styles)b.styles=g.merge(b.data,{});for(var e in this["nodeStylesOn"+a])c="$"+e,c in b.styles||(b.styles[c]=b.getData(e));d.fx.nodeFx(g.extend({elements:{id:b.id,properties:this["nodeStylesOn"+a]},transition:x.Quart.easeOut,duration:300,fps:40},this.config))}else a=
this.getRestoredStyles(b,a),d.fx.nodeFx(g.extend({elements:{id:b.id,properties:a},transition:x.Quart.easeOut,duration:300,fps:40},this.config))},onClick:function(a){if(a){var b=this.nodeStylesOnClick;if(b)a.selected?(this.toggleStylesOnClick(a,!1),delete a.selected):(this.viz.graph.eachNode(function(a){if(a.selected){for(var d in b)a.setData(d,a.styles["$"+d],"end");delete a.selected}}),this.toggleStylesOnClick(a,!0),a.selected=!0,delete a.hovered,this.hoveredNode=!1)}},onMouseMove:function(a,b,c){if(this.down)this.move=
!0;if(!this.dom||!this.isLabel(a,b)){var d=this.nodeStylesOnHover;if(d&&!this.dom){if(this.hoveredNode&&(a=this.types[this.hoveredNode.getData("type")])&&a.contains&&a.contains.call(this.fx,this.hoveredNode,c.getPos()))return;c=c.getNode();if((this.hoveredNode||c)&&!c.hovered)if(c&&!c.selected)this.fx.nodeFxAnimation.stopTimer(),this.viz.graph.eachNode(function(a){if(a.hovered&&!a.selected){for(var b in d)a.setData(b,a.styles["$"+b],"end");delete a.hovered}}),c.hovered=!0,this.hoveredNode=c,this.toggleStylesOnHover(c,
!0);else if(this.hoveredNode&&!this.hoveredNode.selected)this.fx.nodeFxAnimation.stopTimer(),this.toggleStylesOnHover(this.hoveredNode,!1),delete this.hoveredNode.hovered,this.hoveredNode=!1}}}});u.Classes.Navigation=new k({Implements:[s,y],initializePost:function(){this.pressed=this.pos=!1},onMouseWheel:function(a,b,c){this.config.zooming&&(g.event.stop(g.event.get(a,b)),a=1+c*(this.config.zooming/1E3),this.canvas.scale(a,a))},onMouseDown:function(a,b,c){if(this.config.panning&&!("avoid nodes"==
this.config.panning&&(this.dom?this.isLabel(a,b):c.getNode()))){this.pressed=!0;this.pos=c.getPos();var a=this.canvas,b=a.translateOffsetX,c=a.translateOffsetY,d=a.scaleOffsetY;this.pos.x*=a.scaleOffsetX;this.pos.x+=b;this.pos.y*=d;this.pos.y+=c}},onMouseMove:function(a,b,c){if(this.config.panning&&this.pressed&&!("avoid nodes"==this.config.panning&&(this.dom?this.isLabel(a,b):c.getNode()))){var a=this.pos,c=c.getPos(),d=this.canvas,e=d.translateOffsetX,f=d.translateOffsetY,b=d.scaleOffsetX,d=d.scaleOffsetY;
c.x*=b;c.y*=d;c.x+=e;c.y+=f;e=c.x-a.x;a=c.y-a.y;this.pos=c;this.canvas.translate(1*e/b,1*a/d)}},onMouseUp:function(){if(this.config.panning)this.pressed=!1}});var v;(function(){function a(a,b){var f=document.createElement(a),h;for(h in b)"object"==typeof b[h]?g.extend(f[h],b[h]):f[h]=b[h];"canvas"==a&&!c&&G_vmlCanvasManager&&(f=G_vmlCanvasManager.initElement(document.body.appendChild(f)));return f}var b=typeof HTMLCanvasElement,c="object"==b||"function"==b;$jit.Canvas=v=new k({canvases:[],pos:!1,
element:!1,labelContainer:!1,translateOffsetX:0,translateOffsetY:0,scaleOffsetX:1,scaleOffsetY:1,initialize:function(b,c){this.viz=b;this.opt=this.config=c;var f="string"==g.type(c.injectInto)?c.injectInto:c.injectInto.id,h=c.type,i=f+"-label",j=g(f),m=c.width||j.offsetWidth,n=c.height||j.offsetHeight;this.id=f;var p={injectInto:f,width:m,height:n};this.element=a("div",{id:f+"-canvaswidget",style:{position:"relative",width:m+"px",height:n+"px"}});this.labelContainer=this.createLabelContainer(c.Label.type,
i,p);this.canvases.push(new v.Base[h]({config:g.extend({idSuffix:"-canvas"},p),plot:function(){b.fx.plot()},resize:function(){b.refresh()}}));if(f=c.background)p=new v.Background[f.type](b,g.extend(f,p)),this.canvases.push(new v.Base[h](p));for(h=this.canvases.length;h--;)this.element.appendChild(this.canvases[h].canvas),0<h&&this.canvases[h].plot();this.element.appendChild(this.labelContainer);j.appendChild(this.element);var w=null,k=this;g.addEvent(window,"scroll",function(){clearTimeout(w);w=setTimeout(function(){k.getPos(!0)},
500)})},getCtx:function(a){return this.canvases[a||0].getCtx()},getConfig:function(){return this.opt},getElement:function(){return this.element},getSize:function(a){return this.canvases[a||0].getSize()},resize:function(a,b){this.getPos(!0);this.translateOffsetX=this.translateOffsetY=0;this.scaleOffsetX=this.scaleOffsetY=1;for(var c=0,h=this.canvases.length;c<h;c++)this.canvases[c].resize(a,b);c=this.element.style;c.width=a+"px";c.height=b+"px";if(this.labelContainer)this.labelContainer.style.width=
a+"px"},translate:function(a,b,c){this.translateOffsetX+=a*this.scaleOffsetX;this.translateOffsetY+=b*this.scaleOffsetY;for(var h=0,g=this.canvases.length;h<g;h++)this.canvases[h].translate(a,b,c)},scale:function(a,b){var c=this.scaleOffsetX*a,h=this.scaleOffsetY*b,g=this.translateOffsetX*(a-1)/c,j=this.translateOffsetY*(b-1)/h;this.scaleOffsetX=c;this.scaleOffsetY=h;c=0;for(h=this.canvases.length;c<h;c++)this.canvases[c].scale(a,b,!0);this.translate(g,j,!1)},getPos:function(a){return a||!this.pos?
this.pos=g.getPos(this.getElement()):this.pos},clear:function(a){this.canvases[a||0].clear()},path:function(a,b){var c=this.canvases[0].getCtx();c.beginPath();b(c);c[a]();c.closePath()},createLabelContainer:function(b,c,f){if("HTML"==b||"Native"==b)return a("div",{id:c,style:{overflow:"visible",position:"absolute",top:0,left:0,width:f.width+"px",height:0}});if("SVG"==b){b=document.createElementNS("http://www.w3.org/2000/svg","svg:svg");b.setAttribute("width",f.width);b.setAttribute("height",f.height);
var h=b.style;h.position="absolute";h.left=h.top="0px";h=document.createElementNS("http://www.w3.org/2000/svg","svg:g");h.setAttribute("width",f.width);h.setAttribute("height",f.height);h.setAttribute("x",0);h.setAttribute("y",0);h.setAttribute("id",c);b.appendChild(h);return b}}});v.Base={};v.Base["2D"]=new k({translateOffsetX:0,translateOffsetY:0,scaleOffsetX:1,scaleOffsetY:1,initialize:function(a){this.viz=a;this.opt=a.config;this.size=!1;this.createCanvas();this.translateToCenter()},createCanvas:function(){var b=
this.opt,c=b.width,f=b.height;this.canvas=a("canvas",{id:b.injectInto+b.idSuffix,width:c,height:f,style:{position:"absolute",top:0,left:0,width:c+"px",height:f+"px"}})},getCtx:function(){return!this.ctx?this.ctx=this.canvas.getContext("2d"):this.ctx},getSize:function(){if(this.size)return this.size;var a=this.canvas;return this.size={width:a.width,height:a.height}},translateToCenter:function(a){var b=this.getSize(),c=a?b.width-a.width-2*this.translateOffsetX:b.width;height=a?b.height-a.height-2*this.translateOffsetY:
b.height;b=this.getCtx();a&&b.scale(1/this.scaleOffsetX,1/this.scaleOffsetY);b.translate(c/2,height/2)},resize:function(a,b){var f=this.getSize(),h=this.canvas,g=h.style;this.size=!1;h.width=a;h.height=b;g.width=a+"px";g.height=b+"px";c?this.translateToCenter():this.translateToCenter(f);this.translateOffsetX=this.translateOffsetY=0;this.scaleOffsetX=this.scaleOffsetY=1;this.clear();this.viz.resize(a,b,this)},translate:function(a,b,c){var h=this.scaleOffsetY;this.translateOffsetX+=a*this.scaleOffsetX;
this.translateOffsetY+=b*h;this.getCtx().translate(a,b);!c&&this.plot()},scale:function(a,b,c){this.scaleOffsetX*=a;this.scaleOffsetY*=b;this.getCtx().scale(a,b);!c&&this.plot()},clear:function(){var a=this.getSize(),b=this.translateOffsetX,c=this.translateOffsetY,h=this.scaleOffsetX,g=this.scaleOffsetY;this.getCtx().clearRect(1*(-a.width/2-b)/h,1*(-a.height/2-c)/g,1*a.width/h,1*a.height/g)},plot:function(){this.clear();this.viz.plot(this)}});v.Background={};v.Background.Circles=new k({initialize:function(a,
b){this.viz=a;this.config=g.merge({idSuffix:"-bkcanvas",levelDistance:100,numberOfCircles:6,CanvasStyles:{},offset:0},b)},resize:function(a,b,c){this.plot(c)},plot:function(a){var a=a.getCtx(),b=this.config,c=b.CanvasStyles,h;for(h in c)a[h]=c[h];h=b.numberOfCircles;b=b.levelDistance;for(c=1;c<=h;c++)a.beginPath(),a.arc(0,0,b*c,0,2*Math.PI,!1),a.stroke(),a.closePath()}})})();var t=function(a,b){this.theta=a||0;this.rho=b||0};$jit.Polar=t;t.prototype={getc:function(a){return this.toComplex(a)},getp:function(){return this},
set:function(a){a=a.getp();this.theta=a.theta;this.rho=a.rho},setc:function(a,b){this.rho=Math.sqrt(a*a+b*b);this.theta=Math.atan2(b,a);0>this.theta&&(this.theta+=2*Math.PI)},setp:function(a,b){this.theta=a;this.rho=b},clone:function(){return new t(this.theta,this.rho)},toComplex:function(a){var b=Math.cos(this.theta)*this.rho,c=Math.sin(this.theta)*this.rho;return a?{x:b,y:c}:new o(b,c)},add:function(a){return new t(this.theta+a.theta,this.rho+a.rho)},scale:function(a){return new t(this.theta,this.rho*
a)},equals:function(a){return this.theta==a.theta&&this.rho==a.rho},$add:function(a){this.theta+=a.theta;this.rho+=a.rho;return this},$madd:function(a){this.theta=(this.theta+a.theta)%(2*Math.PI);this.rho+=a.rho;return this},$scale:function(a){this.rho*=a;return this},isZero:function(){var a=Math.abs;return 1.0E-4>a(this.theta)&&1.0E-4>a(this.rho)},interpolate:function(a,b){var c=Math.PI,d=2*c,e=function(a){return 0>a?a%d+d:a%d},f=this.theta,h=a.theta,g=Math.abs(f-h);return{theta:g==c?f>h?e(h+(f-
d-h)*b):e(h-d+(f-h)*b):g>=c?f>h?e(h+(f-d-h)*b):e(h-d+(f-(h-d))*b):e(h+(f-h)*b),rho:(this.rho-a.rho)*b+a.rho}}};t.KER=new t(0,0);var o=function(a,b){this.x=a||0;this.y=b||0};$jit.Complex=o;o.prototype={getc:function(){return this},getp:function(a){return this.toPolar(a)},set:function(a){a=a.getc(!0);this.x=a.x;this.y=a.y},setc:function(a,b){this.x=a;this.y=b},setp:function(a,b){this.x=Math.cos(a)*b;this.y=Math.sin(a)*b},clone:function(){return new o(this.x,this.y)},toPolar:function(a){var b=this.norm(),
c=Math.atan2(this.y,this.x);0>c&&(c+=2*Math.PI);return a?{theta:c,rho:b}:new t(c,b)},norm:function(){return Math.sqrt(this.squaredNorm())},squaredNorm:function(){return this.x*this.x+this.y*this.y},add:function(a){return new o(this.x+a.x,this.y+a.y)},prod:function(a){return new o(this.x*a.x-this.y*a.y,this.y*a.x+this.x*a.y)},conjugate:function(){return new o(this.x,-this.y)},scale:function(a){return new o(this.x*a,this.y*a)},equals:function(a){return this.x==a.x&&this.y==a.y},$add:function(a){this.x+=
a.x;this.y+=a.y;return this},$prod:function(a){var b=this.x,c=this.y;this.x=b*a.x-c*a.y;this.y=c*a.x+b*a.y;return this},$conjugate:function(){this.y=-this.y;return this},$scale:function(a){this.x*=a;this.y*=a;return this},$div:function(a){var b=this.x,c=this.y,d=a.squaredNorm();this.x=b*a.x+c*a.y;this.y=c*a.x-b*a.y;return this.$scale(1/d)},isZero:function(){var a=Math.abs;return 1.0E-4>a(this.x)&&1.0E-4>a(this.y)}};o.KER=new o(0,0);$jit.Graph=new k({initialize:function(a,b,c,d){var e={klass:o,Node:{}};
this.Node=b;this.Edge=c;this.Label=d;this.opt=g.merge(e,a||{});this.nodes={};this.edges={};var f=this;this.nodeList={};for(var h in z)f.nodeList[h]=function(a){return function(){var b=Array.prototype.slice.call(arguments);f.eachNode(function(c){c[a].apply(c,b)})}}(h)},getNode:function(a){return this.hasNode(a)?this.nodes[a]:!1},get:function(a){return this.getNode(a)},getByName:function(a){for(var b in this.nodes){var c=this.nodes[b];if(c.name==a)return c}return!1},getAdjacence:function(a,b){return a in
this.edges?this.edges[a][b]:!1},addNode:function(a){if(!this.nodes[a.id]){var b=this.edges[a.id]={};this.nodes[a.id]=new l.Node(g.extend({id:a.id,name:a.name,data:g.merge(a.data||{},{}),adjacencies:b},this.opt.Node),this.opt.klass,this.Node,this.Edge,this.Label)}return this.nodes[a.id]},addAdjacence:function(a,b,c){this.hasNode(a.id)||this.addNode(a);this.hasNode(b.id)||this.addNode(b);a=this.nodes[a.id];b=this.nodes[b.id];if(!a.adjacentTo(b)){var d=this.edges[a.id]=this.edges[a.id]||{},e=this.edges[b.id]=
this.edges[b.id]||{};d[b.id]=e[a.id]=new l.Adjacence(a,b,c,this.Edge,this.Label);return d[b.id]}return this.edges[a.id][b.id]},removeNode:function(a){if(this.hasNode(a)){delete this.nodes[a];var b=this.edges[a],c;for(c in b)delete this.edges[c][a];delete this.edges[a]}},removeAdjacence:function(a,b){delete this.edges[a][b];delete this.edges[b][a]},hasNode:function(a){return a in this.nodes},empty:function(){this.nodes={};this.edges={}}});var l=$jit.Graph,z;(function(){var a=function(a,b,c,h,g){var j,
c=c||"current";if("current"==c)j=this.data;else if("start"==c)j=this.startData;else if("end"==c)j=this.endData;a="$"+(a?a+"-":"")+b;return h?j[a]:!this.Config.overridable?g[b]||0:a in j?j[a]:a in this.data?this.data[a]:g[b]||0},b=function(a,b,c,h){var h=h||"current",g;if("current"==h)g=this.data;else if("start"==h)g=this.startData;else if("end"==h)g=this.endData;g["$"+(a?a+"-":"")+b]=c},c=function(a,b){var a="$"+(a?a+"-":""),c=this;g.each(b,function(b){b=a+b;delete c.data[b];delete c.endData[b];delete c.startData[b]})};
z={getData:function(b,c,f){return a.call(this,"",b,c,f,this.Config)},setData:function(a,c,f){b.call(this,"",a,c,f)},setDataset:function(a,b){var a=g.splat(a),c;for(c in b)for(var h=0,i=g.splat(b[c]),j=a.length;h<j;h++)this.setData(c,i[h],a[h])},removeData:function(){c.call(this,"",Array.prototype.slice.call(arguments))},getCanvasStyle:function(b,c,f){return a.call(this,"canvas",b,c,f,this.Config.CanvasStyles)},setCanvasStyle:function(a,c,f){b.call(this,"canvas",a,c,f)},setCanvasStyles:function(a,
b){var a=g.splat(a),c;for(c in b)for(var h=0,i=g.splat(b[c]),j=a.length;h<j;h++)this.setCanvasStyle(c,i[h],a[h])},removeCanvasStyle:function(){c.call(this,"canvas",Array.prototype.slice.call(arguments))},getLabelData:function(b,c,f){return a.call(this,"label",b,c,f,this.Label)},setLabelData:function(a,c,f){b.call(this,"label",a,c,f)},setLabelDataset:function(a,b){var a=g.splat(a),c;for(c in b)for(var h=0,i=g.splat(b[c]),j=a.length;h<j;h++)this.setLabelData(c,i[h],a[h])},removeLabelData:function(){c.call(this,
"label",Array.prototype.slice.call(arguments))}}})();l.Node=new k({initialize:function(a,b,c,d,e){b={id:"",name:"",data:{},startData:{},endData:{},adjacencies:{},selected:!1,drawn:!1,exist:!1,angleSpan:{begin:0,end:0},pos:new b,startPos:new b,endPos:new b};g.extend(this,g.extend(b,a));this.Config=this.Node=c;this.Edge=d;this.Label=e},adjacentTo:function(a){return a.id in this.adjacencies},getAdjacency:function(a){return this.adjacencies[a]},getPos:function(a){a=a||"current";if("current"==a)return this.pos;
if("end"==a)return this.endPos;if("start"==a)return this.startPos},setPos:function(a,b){var b=b||"current",c;if("current"==b)c=this.pos;else if("end"==b)c=this.endPos;else if("start"==b)c=this.startPos;c.set(a)}});l.Node.implement(z);l.Adjacence=new k({initialize:function(a,b,c,d,e){this.nodeFrom=a;this.nodeTo=b;this.data=c||{};this.startData={};this.endData={};this.Config=this.Edge=d;this.Label=e}});l.Adjacence.implement(z);l.Util={filter:function(a){if(!a||"string"!=g.type(a))return function(){return!0};
var b=a.split(" ");return function(a){for(var d=0;d<b.length;d++)if(a[b[d]].."]]"..[[)return!1;return!0}},getNode:function(a,b){return a.nodes[b]},eachNode:function(a,b,c){var c=this.filter(c),d;for(d in a.nodes)c(a.nodes[d])&&b(a.nodes[d])},each:function(a,b,c){this.eachNode(a,b,c)},eachAdjacency:function(a,b,c){var d=a.adjacencies,c=this.filter(c),e;for(e in d){var f=d[e];if(c(f)){if(f.nodeFrom!=a){var h=f.nodeFrom;f.nodeFrom=f.nodeTo;f.nodeTo=h}b(f,e)}}},computeLevels:function(a,b,c,d){var c=c||0,e=this.filter(d);
this.eachNode(a,function(a){a._flag=!1;a._depth=-1},d);a=a.getNode(b);a._depth=c;for(var f=[a];0!=f.length;){var h=f.pop();h._flag=!0;this.eachAdjacency(h,function(a){a=a.nodeTo;if(!1==a._flag&&e(a)){if(0>a._depth)a._depth=h._depth+1+c;f.unshift(a)}},d)}},eachBFS:function(a,b,c,d){var e=this.filter(d);this.clean(a);for(var f=[a.getNode(b)];0!=f.length;)a=f.pop(),a._flag=!0,c(a,a._depth),this.eachAdjacency(a,function(a){a=a.nodeTo;if(!1==a._flag&&e(a))a._flag=!0,f.unshift(a)},d)},eachLevel:function(a,
b,c,d,e){var f=a._depth,h=this.filter(e),g=this,c=!1===c?Number.MAX_VALUE-f:c;(function m(a,b,c){var e=a._depth;e>=b&&e<=c&&h(a)&&d(a,e);e<c&&g.eachAdjacency(a,function(a){a=a.nodeTo;a._depth>e&&m(a,b,c)})})(a,b+f,c+f)},eachSubgraph:function(a,b,c){this.eachLevel(a,0,!1,b,c)},eachSubnode:function(a,b,c){this.eachLevel(a,1,1,b,c)},anySubnode:function(a,b,c){var d=!1,b=b||g.lambda(!0),e="string"==g.type(b)?function(a){return a[b]}:b;this.eachSubnode(a,function(a){e(a)&&(d=!0)},c);return d},getSubnodes:function(a,
b,c){var d=[],b=b||0,e;"array"==g.type(b)?(e=b[0],b=b[1]):(e=b,b=Number.MAX_VALUE-a._depth);this.eachLevel(a,e,b,function(a){d.push(a)},c);return d},getParents:function(a){var b=[];this.eachAdjacency(a,function(c){c=c.nodeTo;c._depth<a._depth&&b.push(c)});return b},isDescendantOf:function(a,b){if(a.id==b)return!0;for(var c=this.getParents(a),d=!1,e=0;!d&&e<c.length;e++)d=d||this.isDescendantOf(c[e],b);return d},clean:function(a){this.eachNode(a,function(a){a._flag=!1})},getClosestNodeToOrigin:function(a,
b,c){return this.getClosestNodeToPos(a,t.KER,b,c)},getClosestNodeToPos:function(a,b,c,d){var e=null,c=c||"current",b=b&&b.getc(!0)||o.KER,f=function(a,b){var c=a.x-b.x,d=a.y-b.y;return c*c+d*d};this.eachNode(a,function(a){e=null==e||f(a.getPos(c).getc(!0),b)<f(e.getPos(c).getc(!0),b)?a:e},d);return e}};g.each("get,getNode,each,eachNode,computeLevels,eachBFS,clean,getClosestNodeToPos,getClosestNodeToOrigin".split(","),function(a){l.prototype[a]=function(){return l.Util[a].apply(l.Util,[this].concat(Array.prototype.slice.call(arguments)))}});
g.each("eachAdjacency,eachLevel,eachSubgraph,eachSubnode,anySubnode,getSubnodes,getParents,isDescendantOf".split(","),function(a){l.Node.prototype[a]=function(){return l.Util[a].apply(l.Util,[this].concat(Array.prototype.slice.call(arguments)))}});l.Op={options:{type:"nothing",duration:2E3,hideLabels:!0,fps:30},initialize:function(a){this.viz=a},removeNode:function(a,b){var c=this.viz,d=g.merge(this.options,c.controller,b),e=g.splat(a),f,h,i;switch(d.type){case "nothing":for(f=0;f<e.length;f++)c.graph.removeNode(e[f]);
break;case "replot":this.removeNode(e,{type:"nothing"});c.labels.clearLabels();c.refresh(!0);break;case "fade:seq":case "fade":h=this;for(f=0;f<e.length;f++)i=c.graph.getNode(e[f]),i.setData("alpha",0,"end");c.fx.animate(g.merge(d,{modes:["node-property:alpha"],onComplete:function(){h.removeNode(e,{type:"nothing"});c.labels.clearLabels();c.reposition();c.fx.animate(g.merge(d,{modes:["linear"]}))}}));break;case "fade:con":h=this;for(f=0;f<e.length;f++)i=c.graph.getNode(e[f]),i.setData("alpha",0,"end"),
i.ignore=!0;c.reposition();c.fx.animate(g.merge(d,{modes:["node-property:alpha","linear"],onComplete:function(){h.removeNode(e,{type:"nothing"});d.onComplete&&d.onComplete()}}));break;case "iter":h=this;c.fx.sequence({condition:function(){return 0!=e.length},step:function(){h.removeNode(e.shift(),{type:"nothing"});c.labels.clearLabels()},onComplete:function(){d.onComplete&&d.onComplete()},duration:Math.ceil(d.duration/e.length)});break;default:this.doError()}},removeEdge:function(a,b){var c=this.viz,
d=g.merge(this.options,c.controller,b),e="string"==g.type(a[0])?[a]:a,f,h,i;switch(d.type){case "nothing":for(f=0;f<e.length;f++)c.graph.removeAdjacence(e[f][0],e[f][1]);break;case "replot":this.removeEdge(e,{type:"nothing"});c.refresh(!0);break;case "fade:seq":case "fade":h=this;for(f=0;f<e.length;f++)(i=c.graph.getAdjacence(e[f][0],e[f][1]))&&i.setData("alpha",0,"end");c.fx.animate(g.merge(d,{modes:["edge-property:alpha"],onComplete:function(){h.removeEdge(e,{type:"nothing"});c.reposition();c.fx.animate(g.merge(d,
{modes:["linear"]}))}}));break;case "fade:con":h=this;for(f=0;f<e.length;f++)if(i=c.graph.getAdjacence(e[f][0],e[f][1]))i.setData("alpha",0,"end"),i.ignore=!0;c.reposition();c.fx.animate(g.merge(d,{modes:["edge-property:alpha","linear"],onComplete:function(){h.removeEdge(e,{type:"nothing"});d.onComplete&&d.onComplete()}}));break;case "iter":h=this;c.fx.sequence({condition:function(){return 0!=e.length},step:function(){h.removeEdge(e.shift(),{type:"nothing"});c.labels.clearLabels()},onComplete:function(){d.onComplete()},
duration:Math.ceil(d.duration/e.length)});break;default:this.doError()}},sum:function(a,b){var c=this.viz,d=g.merge(this.options,c.controller,b),e=c.root,f;c.root=b.id||c.root;switch(d.type){case "nothing":f=c.construct(a);f.eachNode(function(a){a.eachAdjacency(function(a){c.graph.addAdjacence(a.nodeFrom,a.nodeTo,a.data)})});break;case "replot":c.refresh(!0);this.sum(a,{type:"nothing"});c.refresh(!0);break;case "fade:seq":case "fade":case "fade:con":that=this;f=c.construct(a);var h=!this.preprocessSum(f)?
["node-property:alpha"]:["node-property:alpha","edge-property:alpha"];c.reposition();"fade:con"!=d.type?c.fx.animate(g.merge(d,{modes:["linear"],onComplete:function(){c.fx.animate(g.merge(d,{modes:h,onComplete:function(){d.onComplete()}}))}})):(c.graph.eachNode(function(a){a.id!=e&&a.pos.isZero()&&(a.pos.set(a.endPos),a.startPos.set(a.endPos))}),c.fx.animate(g.merge(d,{modes:["linear"].concat(h)})));break;default:this.doError()}},morph:function(a,b,c){var c=c||{},d=this.viz,e=g.merge(this.options,
d.controller,b),f=d.root,h;d.root=b.id||d.root;switch(e.type){case "nothing":h=d.construct(a);h.eachNode(function(a){var b=d.graph.hasNode(a.id);a.eachAdjacency(function(a){var b=!!d.graph.getAdjacence(a.nodeFrom.id,a.nodeTo.id);d.graph.addAdjacence(a.nodeFrom,a.nodeTo,a.data);if(b){var b=d.graph.getAdjacence(a.nodeFrom.id,a.nodeTo.id),c;for(c in a.data||{})b.data[c]=a.data[c]}});if(b){var b=d.graph.getNode(a.id),c;for(c in a.data||{})b.data[c]=a.data[c]}});d.graph.eachNode(function(a){a.eachAdjacency(function(a){h.getAdjacence(a.nodeFrom.id,
a.nodeTo.id)||d.graph.removeAdjacence(a.nodeFrom.id,a.nodeTo.id)});h.hasNode(a.id)||d.graph.removeNode(a.id)});break;case "replot":d.labels.clearLabels(!0);this.morph(a,{type:"nothing"});d.refresh(!0);d.refresh(!0);break;case "fade:seq":case "fade":case "fade:con":that=this;h=d.construct(a);var i="node-property"in c&&g.map(g.splat(c["node-property"]),function(a){return"$"+a});d.graph.eachNode(function(a){var b=h.getNode(a.id);if(b){var b=b.data,c;for(c in b)i&&-1<g.indexOf(i,c)?a.endData[c]=b[c]:
a.data[c]=b[c]}else a.setData("alpha",1),a.setData("alpha",1,"start"),a.setData("alpha",0,"end"),a.ignore=!0});d.graph.eachNode(function(a){a.ignore||a.eachAdjacency(function(a){if(!a.nodeFrom.ignore&&!a.nodeTo.ignore){var b=h.getNode(a.nodeFrom.id),a=h.getNode(a.nodeTo.id);b.adjacentTo(a)||(a=d.graph.getAdjacence(b.id,a.id),j=!0,a.setData("alpha",1),a.setData("alpha",1,"start"),a.setData("alpha",0,"end"))}})});var j=this.preprocessSum(h),a=!j?["node-property:alpha"]:["node-property:alpha","edge-property:alpha"];
a[0]+="node-property"in c?":"+g.splat(c["node-property"]).join(":"):"";a[1]=(a[1]||"edge-property:alpha")+("edge-property"in c?":"+g.splat(c["edge-property"]).join(":"):"");"label-property"in c&&a.push("label-property:"+g.splat(c["label-property"]).join(":"));d.reposition?d.reposition():d.compute("end");d.graph.eachNode(function(a){a.id!=f&&a.pos.getp().equals(t.KER)&&(a.pos.set(a.endPos),a.startPos.set(a.endPos))});d.fx.animate(g.merge(e,{modes:[c.position||"polar"].concat(a),onComplete:function(){d.graph.eachNode(function(a){a.ignore&&
d.graph.removeNode(a.id)});d.graph.eachNode(function(a){a.eachAdjacency(function(a){a.ignore&&d.graph.removeAdjacence(a.nodeFrom.id,a.nodeTo.id)})});e.onComplete()}}))}},contract:function(a,b){var c=this.viz;if(!a.collapsed&&a.anySubnode(g.lambda(!0)))b=g.merge(this.options,c.config,b||{},{modes:["node-property:alpha:span","linear"]}),a.collapsed=!0,function e(a){a.eachSubnode(function(a){a.ignore=!0;a.setData("alpha",0,"animate"==b.type?"end":"current");e(a)})}(a),"animate"==b.type?(c.compute("end"),
c.rotated&&c.rotate(c.rotated,"none",{property:"end"}),function f(b){b.eachSubnode(function(b){b.setPos(a.getPos("end"),"end");f(b)})}(a),c.fx.animate(b)):"replot"==b.type&&c.refresh()},expand:function(a,b){if("collapsed"in a){var c=this.viz,b=g.merge(this.options,c.config,b||{},{modes:["node-property:alpha:span","linear"]});delete a.collapsed;(function e(a){a.eachSubnode(function(a){delete a.ignore;a.setData("alpha",1,"animate"==b.type?"end":"current");e(a)})})(a);"animate"==b.type?(c.compute("end"),
c.rotated&&c.rotate(c.rotated,"none",{property:"end"}),c.fx.animate(b)):"replot"==b.type&&c.refresh()}},preprocessSum:function(a){var b=this.viz;a.eachNode(function(a){b.graph.hasNode(a.id)||(b.graph.addNode(a),a=b.graph.getNode(a.id),a.setData("alpha",0),a.setData("alpha",0,"start"),a.setData("alpha",1,"end"))});var c=!1;a.eachNode(function(a){a.eachAdjacency(function(a){var d=b.graph.getNode(a.nodeFrom.id),h=b.graph.getNode(a.nodeTo.id);d.adjacentTo(h)||(a=b.graph.addAdjacence(d,h,a.data),d.startAlpha==
d.endAlpha&&h.startAlpha==h.endAlpha&&(c=!0,a.setData("alpha",0),a.setData("alpha",0,"start"),a.setData("alpha",1,"end")))})});return c}};var A={none:{render:g.empty,contains:g.lambda(!1)},circle:{render:function(a,b,c,d){d=d.getCtx();d.beginPath();d.arc(b.x,b.y,c,0,2*Math.PI,!0);d.closePath();d[a]()},contains:function(a,b,c){var d=a.x-b.x,a=a.y-b.y;return d*d+a*a<=c*c}},ellipse:{render:function(a,b,c,d,e){var e=e.getCtx(),f=1,h=1,g=1,j=1,m=0;c>d?(m=c/2,h=d/c,j=c/d):(m=d/2,f=c/d,g=d/c);e.save();e.scale(f,
h);e.beginPath();e.arc(b.x*g,b.y*j,m,0,2*Math.PI,!0);e.closePath();e[a]();e.restore()},contains:function(a,b,c,d){var e=0,f=1,h=1,g=0,j=0,e=0;c>d?(e=c/2,h=d/c):(e=d/2,f=c/d);g=(a.x-b.x)*(1/f);j=(a.y-b.y)*(1/h);return g*g+j*j<=e*e}},square:{render:function(a,b,c,d){d.getCtx()[a+"Rect"](b.x-c,b.y-c,2*c,2*c)},contains:function(a,b,c){return Math.abs(b.x-a.x)<=c&&Math.abs(b.y-a.y)<=c}},rectangle:{render:function(a,b,c,d,e){e.getCtx()[a+"Rect"](b.x-c/2,b.y-d/2,c,d)},contains:function(a,b,c,d){return Math.abs(b.x-
a.x)<=c/2&&Math.abs(b.y-a.y)<=d/2}},triangle:{render:function(a,b,c,d){var d=d.getCtx(),e=b.x,f=b.y-c,h=e-c,b=b.y+c,c=e+c;d.beginPath();d.moveTo(e,f);d.lineTo(h,b);d.lineTo(c,b);d.closePath();d[a]()},contains:function(a,b,c){return A.circle.contains(a,b,c)}},star:{render:function(a,b,c,d){var d=d.getCtx(),e=Math.PI/5;d.save();d.translate(b.x,b.y);d.beginPath();d.moveTo(c,0);for(b=0;9>b;b++)d.rotate(e),0==b%2?d.lineTo(0.200811*(c/0.525731),0):d.lineTo(c,0);d.closePath();d[a]();d.restore()},contains:function(a,
b,c){return A.circle.contains(a,b,c)}}},C={line:{render:function(a,b,c){c=c.getCtx();c.beginPath();c.moveTo(a.x,a.y);c.lineTo(b.x,b.y);c.stroke()},contains:function(a,b,c,d){var e=Math.min,f=Math.max,h=e(a.x,b.x),g=f(a.x,b.x),e=e(a.y,b.y),f=f(a.y,b.y);return c.x>=h&&c.x<=g&&c.y>=e&&c.y<=f?Math.abs(b.x-a.x)<=d?!0:Math.abs((b.y-a.y)/(b.x-a.x)*(c.x-a.x)+a.y-c.y)<=d:!1}},arrow:{render:function(a,b,c,d,e){e=e.getCtx();d&&(d=a,a=b,b=d);d=new o(b.x-a.x,b.y-a.y);d.$scale(c/d.norm());var c=new o(b.x-d.x,b.y-
d.y),f=new o(-d.y/2,d.x/2),d=c.add(f),c=c.$add(f.$scale(-1));e.beginPath();e.moveTo(a.x,a.y);e.lineTo(b.x,b.y);e.stroke();e.beginPath();e.moveTo(d.x,d.y);e.lineTo(c.x,c.y);e.lineTo(b.x,b.y);e.closePath();e.fill()},contains:function(a,b,c,d){return C.line.contains(a,b,c,d)}},hyperline:{render:function(a,b,c,d){function e(a,b){return a<b?a+Math.PI>b?!1:!0:b+Math.PI>a?!0:!1}var d=d.getCtx(),f=function(a,b){var c=a.x*b.y-a.y*b.x,d=a.squaredNorm(),e=b.squaredNorm();if(0==c)return{x:0,y:0,ratio:-1};var f=
(a.y*e-b.y*d+a.y-b.y)/c,c=(b.x*d-a.x*e+b.x-a.x)/c,d=-f/2,e=-c/2,g=(f*f+c*c)/4-1;if(0>g)return{x:0,y:0,ratio:-1};g=Math.sqrt(g);return{x:d,y:e,ratio:1E3<g?-1:g,a:f,b:c}}(a,b);1E3<f.a||1E3<f.b||0>f.ratio?(d.beginPath(),d.moveTo(a.x*c,a.y*c),d.lineTo(b.x*c,b.y*c)):(b=Math.atan2(b.y-f.y,b.x-f.x),a=Math.atan2(a.y-f.y,a.x-f.x),e=e(b,a),d.beginPath(),d.arc(f.x*c,f.y*c,f.ratio*c,b,a,e));d.stroke()},contains:g.lambda(!1)}};l.Plot={initialize:function(a,b){this.viz=a;this.config=a.config;this.node=a.config.Node;
this.edge=a.config.Edge;this.animation=new B;this.nodeTypes=new b.Plot.NodeTypes;this.edgeTypes=new b.Plot.EdgeTypes;this.labels=a.labels},nodeHelper:A,edgeHelper:C,Interpolator:{map:{border:"color",color:"color",width:"number",height:"number",dim:"number",alpha:"number",lineWidth:"number",angularWidth:"number",span:"number",valueArray:"array-number",dimArray:"array-number"},canvas:{globalAlpha:"number",fillStyle:"color",strokeStyle:"color",lineWidth:"number",shadowBlur:"number",shadowColor:"color",
shadowOffsetX:"number",shadowOffsetY:"number",miterLimit:"number"},label:{size:"number",color:"color"},compute:function(a,b,c){return a+(b-a)*c},moebius:function(a,b,c,d){b=d.scale(-c);if(1>b.norm()){var c=b.x,d=b.y,e=a.startPos.getc().moebiusTransformation(b);a.pos.setc(e.x,e.y);b.x=c;b.y=d}},linear:function(a,b,c){var b=a.startPos.getc(!0),d=a.endPos.getc(!0);a.pos.setc(this.compute(b.x,d.x,c),this.compute(b.y,d.y,c))},polar:function(a,b,c){b=a.startPos.getp(!0);c=a.endPos.getp().interpolate(b,
c);a.pos.setp(c.theta,c.rho)},number:function(a,b,c,d,e){var f=a[d](b,"start"),d=a[d](b,"end");a[e](b,this.compute(f,d,c))},color:function(a,b,c,d,e){var f=g.hexToRgb(a[d](b,"start")),d=g.hexToRgb(a[d](b,"end")),h=this.compute,c=g.rgbToHex([parseInt(h(f[0],d[0],c)),parseInt(h(f[1],d[1],c)),parseInt(h(f[2],d[2],c))]);a[e](b,c)},"array-number":function(a,b,c,d,e){for(var f=a[d](b,"start"),d=a[d](b,"end"),h=[],g=0,j=f.length;g<j;g++){var m=f[g],n=d[g];if(m.length){for(var p=0,k=m.length,l=[];p<k;p++)l.push(this.compute(m[p],
n[p],c));h.push(l)}else h.push(this.compute(m,n,c))}a[e](b,h)},node:function(a,b,c,d,e,f){d=this[d];if(b)for(var h=b.length,g=0;g<h;g++){var j=b[g];this[d[j]].."]]"..[[(a,j,c,e,f)}else for(j in d)this[d[j]].."]]"..[[(a,j,c,e,f)},edge:function(a,b,c,d,e,f){var a=a.adjacencies,h;for(h in a)this.node(a[h],b,c,d,e,f)},"node-property":function(a,b,c){this.node(a,b,c,"map","getData","setData")},"edge-property":function(a,b,c){this.edge(a,b,c,"map","getData","setData")},"label-property":function(a,b,c){this.node(a,b,c,"label",
"getLabelData","setLabelData")},"node-style":function(a,b,c){this.node(a,b,c,"canvas","getCanvasStyle","setCanvasStyle")},"edge-style":function(a,b,c){this.edge(a,b,c,"canvas","getCanvasStyle","setCanvasStyle")}},sequence:function(a){var b=this,a=g.merge({condition:g.lambda(!1),step:g.empty,onComplete:g.empty,duration:200},a||{}),c=setInterval(function(){a.condition()?a.step():(clearInterval(c),a.onComplete());b.viz.refresh(!0)},a.duration)},prepare:function(a){var b=this.viz.graph,c={"node-property":{getter:"getData",
setter:"setData"},"edge-property":{getter:"getData",setter:"setData"},"node-style":{getter:"getCanvasStyle",setter:"setCanvasStyle"},"edge-style":{getter:"getCanvasStyle",setter:"setCanvasStyle"}},d={};if("array"==g.type(a))for(var e=0,f=a.length;e<f;e++){var h=a[e].split(":");d[h.shift()]=h}else for(e in a)"position"==e?d[a.position]=[]:d[e]=g.splat(a[e]);b.eachNode(function(a){a.startPos.set(a.pos);g.each(["node-property","node-style"],function(b){if(b in d)for(var e=d[b],f=0,h=e.length;f<h;f++)a[c[b].setter](e[f],
a[c[b].getter](e[f]),"start")});g.each(["edge-property","edge-style"],function(b){if(b in d){var e=d[b];a.eachAdjacency(function(a){for(var d=0,f=e.length;d<f;d++)a[c[b].setter](e[d],a[c[b].getter](e[d]),"start")})}})});return d},animate:function(a,b){var a=g.merge(this.viz.config,a||{}),c=this,d=this.viz.graph,e=this.Interpolator,f="nodefx"===a.type?this.nodeFxAnimation:this.animation,h=this.prepare(a.modes);a.hideLabels&&this.labels.hideLabels(!0);f.setOptions(g.extend(a,{$animating:!1,compute:function(f){d.eachNode(function(a){for(var c in h)e[c](a,
h[c],f,b)});c.plot(a,this.$animating,f);this.$animating=!0},complete:function(){a.hideLabels&&c.labels.hideLabels(!1);c.plot(a);a.onComplete()}})).start()},nodeFx:function(a){var b=this.viz,c=b.graph,d=this.nodeFxAnimation,e=g.merge(this.viz.config,{elements:{id:!1,properties:{}},reposition:!1}),a=g.merge(e,a||{},{onBeforeCompute:g.empty,onAfterCompute:g.empty});d.stopTimer();var f=a.elements.properties;a.elements.id?(d=g.splat(a.elements.id),g.each(d,function(a){if(a=c.getNode(a))for(var b in f)a.setData(b,
f[b],"end")})):c.eachNode(function(a){for(var b in f)a.setData(b,f[b],"end")});var d=[],h;for(h in f)d.push(h);h=["node-property:"+d.join(":")];a.reposition&&(h.push("linear"),b.compute("end"));this.animate(g.merge(a,{modes:h,type:"nodefx"}))},plot:function(a,b){var c=this.viz,d=c.graph,e=c.canvas,c=c.root,f=this;e.getCtx();a=a||this.viz.controller;a.clearCanvas&&e.clear();if(c=d.getNode(c)){var h=!!c.visited;d.eachNode(function(c){var d=c.getData("alpha");c.eachAdjacency(function(d){var g=d.nodeTo;
!!g.visited===h&&c.drawn&&g.drawn&&(!b&&a.onBeforePlotLine(d),f.plotLine(d,e,b),!b&&a.onAfterPlotLine(d))});c.drawn&&(!b&&a.onBeforePlotNode(c),f.plotNode(c,e,b),!b&&a.onAfterPlotNode(c));!f.labelsHidden&&a.withLabels&&(c.drawn&&0.95<=d?f.labels.plotLabel(e,c,a):f.labels.hideLabel(c,!1));c.visited=!h})}},plotTree:function(a,b,c){var d=this,e=this.viz.canvas;e.getCtx();var f=a.getData("alpha");a.eachSubnode(function(f){if(b.plotSubtree(a,f)&&f.exist&&f.drawn){var g=a.getAdjacency(f.id);!c&&b.onBeforePlotLine(g);
d.plotLine(g,e,c);!c&&b.onAfterPlotLine(g);d.plotTree(f,b,c)}});a.drawn?(!c&&b.onBeforePlotNode(a),this.plotNode(a,e,c),!c&&b.onAfterPlotNode(a),!b.hideLabels&&b.withLabels&&0.95<=f?this.labels.plotLabel(e,a,b):this.labels.hideLabel(a,!1)):this.labels.hideLabel(a,!0)},plotNode:function(a,b,c){var d=a.getData("type"),e=this.node.CanvasStyles;if("none"!=d){var f=a.getData("lineWidth"),g=a.getData("color"),i=a.getData("alpha"),j=b.getCtx();j.save();j.lineWidth=f;j.fillStyle=j.strokeStyle=g;j.globalAlpha=
i;for(var m in e)j[m]=a.getCanvasStyle(m);this.nodeTypes[d].render.call(this,a,b,c);j.restore()}},plotLine:function(a,b,c){var d=a.getData("type"),e=this.edge.CanvasStyles;if("none"!=d){var f=a.getData("lineWidth"),g=a.getData("color"),i=b.getCtx(),j=a.nodeFrom,m=a.nodeTo;i.save();i.lineWidth=f;i.fillStyle=i.strokeStyle=g;i.globalAlpha=Math.min(j.getData("alpha"),m.getData("alpha"),a.getData("alpha"));for(var n in e)i[n]=a.getCanvasStyle(n);this.edgeTypes[d].render.call(this,a,b,c);i.restore()}}};
l.Plot3D=g.merge(l.Plot,{Interpolator:{linear:function(a,b,c){var b=a.startPos.getc(!0),d=a.endPos.getc(!0);a.pos.setc(this.compute(b.x,d.x,c),this.compute(b.y,d.y,c),this.compute(b.z,d.z,c))}},plotNode:function(a,b){"none"!=a.getData("type")&&this.plotElement(a,b,{getAlpha:function(){return a.getData("alpha")}})},plotLine:function(a,b){"none"!=a.getData("type")&&this.plotElement(a,b,{getAlpha:function(){return Math.min(a.nodeFrom.getData("alpha"),a.nodeTo.getData("alpha"),a.getData("alpha"))}})},
plotElement:function(a,b,c){var d=b.getCtx(),e=new Matrix4,f=b.config.Scene.Lighting,h=b.canvases[0],b=h.program,h=h.camera;if(!a.geometry)a.geometry=new (O3D[a.getData("type")]);a.geometry.update(a);if(!a.webGLVertexBuffer){for(var i=[],j=[],m=[],n=0,k=a.geometry,l=0,o=k.vertices,k=k.faces,s=k.length;l<s;l++){var r=k[l],q=o[r.a],t=o[r.b],v=o[r.c],u=r.d?o[r.d]:!1,r=r.normal;i.push(q.x,q.y,q.z);i.push(t.x,t.y,t.z);i.push(v.x,v.y,v.z);u&&i.push(u.x,u.y,u.z);m.push(r.x,r.y,r.z);m.push(r.x,r.y,r.z);m.push(r.x,
r.y,r.z);u&&m.push(r.x,r.y,r.z);j.push(n,n+1,n+2);u?(j.push(n,n+2,n+3),n+=4):n+=3}a.webGLVertexBuffer=d.createBuffer();d.bindBuffer(d.ARRAY_BUFFER,a.webGLVertexBuffer);d.bufferData(d.ARRAY_BUFFER,new Float32Array(i),d.STATIC_DRAW);a.webGLFaceBuffer=d.createBuffer();d.bindBuffer(d.ELEMENT_ARRAY_BUFFER,a.webGLFaceBuffer);d.bufferData(d.ELEMENT_ARRAY_BUFFER,new Uint16Array(j),d.STATIC_DRAW);a.webGLFaceCount=j.length;a.webGLNormalBuffer=d.createBuffer();d.bindBuffer(d.ARRAY_BUFFER,a.webGLNormalBuffer);
d.bufferData(d.ARRAY_BUFFER,new Float32Array(m),d.STATIC_DRAW)}e.multiply(h.matrix,a.geometry.matrix);d.uniformMatrix4fv(b.viewMatrix,!1,e.flatten());d.uniformMatrix4fv(b.projectionMatrix,!1,h.projectionMatrix.flatten());e=Matrix4.makeInvert(e);e.$transpose();d.uniformMatrix4fv(b.normalMatrix,!1,e.flatten());e=g.hexToRgb(a.getData("color"));e.push(c.getAlpha());d.uniform4f(b.color,e[0]/255,e[1]/255,e[2]/255,e[3]);d.uniform1i(b.enableLighting,f.enable);if(f.enable){if(f.ambient)c=f.ambient,d.uniform3f(b.ambientColor,
c[0],c[1],c[2]);if(f.directional)f=f.directional,e=f.color,f=f.direction,f=(new Vector3(f.x,f.y,f.z)).normalize().$scale(-1),d.uniform3f(b.lightingDirection,f.x,f.y,f.z),d.uniform3f(b.directionalColor,e[0],e[1],e[2])}d.bindBuffer(d.ARRAY_BUFFER,a.webGLVertexBuffer);d.vertexAttribPointer(b.position,3,d.FLOAT,!1,0,0);d.bindBuffer(d.ARRAY_BUFFER,a.webGLNormalBuffer);d.vertexAttribPointer(b.normal,3,d.FLOAT,!1,0,0);d.bindBuffer(d.ELEMENT_ARRAY_BUFFER,a.webGLFaceBuffer);d.drawElements(d.TRIANGLES,a.webGLFaceCount,
d.UNSIGNED_SHORT,0)}});l.Label={};l.Label.Native=new k({initialize:function(a){this.viz=a},plotLabel:function(a,b,c){var d=a.getCtx();b.pos.getc(!0);d.font=b.getLabelData("style")+" "+b.getLabelData("size")+"px "+b.getLabelData("family");d.textAlign=b.getLabelData("textAlign");d.fillStyle=d.strokeStyle=b.getLabelData("color");d.textBaseline=b.getLabelData("textBaseline");this.renderLabel(a,b,c)},renderLabel:function(a,b){var c=a.getCtx(),d=b.pos.getc(!0);c.fillText(b.name,d.x,d.y+b.getData("height")/
2)},hideLabel:g.empty,hideLabels:g.empty});l.Label.DOM=new k({labelsHidden:!1,labelContainer:!1,labels:{},getLabelContainer:function(){return this.labelContainer?this.labelContainer:this.labelContainer=document.getElementById(this.viz.config.labelContainer)},getLabel:function(a){return a in this.labels&&null!=this.labels[a]?this.labels[a]:this.labels[a]=document.getElementById(a)},hideLabels:function(a){this.getLabelContainer().style.display=a?"none":"";this.labelsHidden=a},clearLabels:function(a){for(var b in this.labels)if(a||
!this.viz.graph.hasNode(b))this.disposeLabel(b),delete this.labels[b]},disposeLabel:function(a){(a=this.getLabel(a))&&a.parentNode&&a.parentNode.removeChild(a)},hideLabel:function(a,b){var a=g.splat(a),c=b?"":"none",d=this;g.each(a,function(a){if(a=d.getLabel(a.id))a.style.display=c})},fitsInCanvas:function(a,b){var c=b.getSize();return a.x>=c.width||0>a.x||a.y>=c.height||0>a.y?!1:!0}});l.Label.HTML=new k({Implements:l.Label.DOM,plotLabel:function(a,b,c){var a=b.id,d=this.getLabel(a);if(!d&&!(d=document.getElementById(a))){var d=
document.createElement("div"),e=this.getLabelContainer();d.id=a;d.className="node";d.style.position="absolute";c.onCreateLabel(d,b);e.appendChild(d);this.labels[b.id]=d}this.placeLabel(d,b,c)}});l.Label.SVG=new k({Implements:l.Label.DOM,plotLabel:function(a,b,c){var a=b.id,d=this.getLabel(a);if(!d&&!(d=document.getElementById(a))){var d=document.createElementNS("http://www.w3.org/2000/svg","svg:text"),e=document.createElementNS("http://www.w3.org/2000/svg","svg:tspan");d.appendChild(e);e=this.getLabelContainer();
d.setAttribute("id",a);d.setAttribute("class","node");e.appendChild(d);c.onCreateLabel(d,b);this.labels[b.id]=d}this.placeLabel(d,b,c)}});s=$jit.Layouts={};s.TM={};s.TM.SliceAndDice=new k({compute:function(a){var b=this.graph.getNode(this.clickedNode&&this.clickedNode.id||this.root);this.controller.onBeforeCompute(b);var c=this.canvas.getSize(),d=this.config,e=c.width,c=c.height;this.graph.computeLevels(this.root,0,"ignore");b.getPos(a).setc(-e/2,-c/2);b.setData("width",e,a);b.setData("height",c+
d.titleHeight,a);this.computePositions(b,b,this.layout.orientation,a);this.controller.onAfterCompute(b)},computePositions:function(a,b,c,d){var e=0;a.eachSubnode(function(a){e+=a.getData("area",d)});var f=this.config,g=a.getData("width",d),i=Math.max(a.getData("height",d)-f.titleHeight,0),a=a==b?1:b.getData("area",d)/e,j,m,n,k,l;"h"==c?(c="v",g*=a,j="height",m="y",n="x",k=f.titleHeight,l=0):(c="h",i*=a,j="width",m="x",n="y",k=0,l=f.titleHeight);var o=b.getPos(d);b.setData("width",g,d);b.setData("height",
i,d);var q=0,r=this;b.eachSubnode(function(a){var e=a.getPos(d);e[m]=q+o[m]+k;e[n]=o[n]+l;r.computePositions(b,a,c,d);q+=a.getData(j,d)})}});s.TM.Area={compute:function(a){var a=a||"current",b=this.graph.getNode(this.clickedNode&&this.clickedNode.id||this.root);this.controller.onBeforeCompute(b);var c=this.config,d=this.canvas.getSize(),e=d.width,d=d.height,f=c.offset,g=e-f,f=d-f;this.graph.computeLevels(this.root,0,"ignore");b.getPos(a).setc(-e/2,-d/2);b.setData("width",e,a);b.setData("height",d,
a);this.computePositions(b,{top:-d/2+c.titleHeight,left:-e/2,width:g,height:f-c.titleHeight},a);this.controller.onAfterCompute(b)},computeDim:function(a,b,c,d,e,f){if(1==a.length+b.length)this.layoutLast(1==a.length?a:b,c,d,f);else if(2<=a.length&&0==b.length&&(b=[a.shift()]),0==a.length)0<b.length&&this.layoutRow(b,c,d,f);else{var g=a[0];e(b,c)>=e([g].concat(b),c)?this.computeDim(a.slice(1),b.concat([g]),c,d,e,f):(b=this.layoutRow(b,c,d,f),this.computeDim(a,[],b.dim,b,e,f))}},worstAspectRatio:function(a,
b){if(!a||0==a.length)return Number.MAX_VALUE;for(var c=0,d=0,e=Number.MAX_VALUE,f=0,g=a.length;f<g;f++)var i=a[f]._area,c=c+i,e=e<i?e:i,d=d>i?d:i;f=b*b;c*=c;return Math.max(f*d/c,c/(f*e))},avgAspectRatio:function(a,b){if(!a||0==a.length)return Number.MAX_VALUE;for(var c=0,d=0,e=a.length;d<e;d++)var f=a[d]._area/b,c=c+(b>f?b/f:f/b);return c/e},layoutLast:function(a,b,c,d){a=a[0];a.getPos(d).setc(c.left,c.top);a.setData("width",c.width,d);a.setData("height",c.height,d)}};s.TM.Squarified=new k({Implements:s.TM.Area,
computePositions:function(a,b,c){var d=this.config,e=Math.max;this.layout.orientation=b.width>=b.height?"h":"v";var f=a.getSubnodes([1,1],"ignore");if(0<f.length){this.processChildrenLayout(a,f,b,c);for(var a=0,g=f.length;a<g;a++){var i=f[a],j=d.offset,b=e(i.getData("height",c)-j-d.titleHeight,0),j=e(i.getData("width",c)-j,0),m=i.getPos(c),b={width:j,height:b,top:m.y+d.titleHeight,left:m.x};this.computePositions(i,b,c)}}},processChildrenLayout:function(a,b,c,d){var a=c.width*c.height,e,f=b.length,
g=0,i=[];for(e=0;e<f;e++)i[e]=parseFloat(b[e].getData("area",d)),g+=i[e];for(e=0;e<f;e++)b[e]._area=a*i[e]/g;a=this.layout.horizontal()?c.height:c.width;b.sort(function(a,b){var c=b._area-a._area;return c?c:b.id==a.id?0:b.id<a.id?1:-1});e=[b[0]].."]]"..[[;this.squarify(b.slice(1),e,a,c,d)},squarify:function(a,b,c,d,e){this.computeDim(a,b,c,d,this.worstAspectRatio,e)},layoutRow:function(a,b,c,d){return this.layout.horizontal()?this.layoutV(a,b,c,d):this.layoutH(a,b,c,d)},layoutV:function(a,b,c,d){var e=0;g.each(a,
function(a){e+=a._area});for(var b=e/b,f=0,h=0,i=a.length;h<i;h++){var j=a[h]._area/b,m=a[h];m.getPos(d).setc(c.left,c.top+f);m.setData("width",b,d);m.setData("height",j,d);f+=j}a={height:c.height,width:c.width-b,top:c.top,left:c.left+b};a.dim=Math.min(a.width,a.height);a.dim!=a.height&&this.layout.change();return a},layoutH:function(a,b,c,d){var e=0;g.each(a,function(a){e+=a._area});for(var f=e/b,h=c.top,i=0,j=0,m=a.length;j<m;j++){var k=a[j],b=k._area/f;k.getPos(d).setc(c.left+i,h);k.setData("width",
b,d);k.setData("height",f,d);i+=b}a={height:c.height-f,width:c.width,top:c.top+f,left:c.left};a.dim=Math.min(a.width,a.height);a.dim!=a.width&&this.layout.change();return a}});s.TM.Strip=new k({Implements:s.TM.Area,computePositions:function(a,b,c){var d=a.getSubnodes([1,1],"ignore"),e=this.config,f=Math.max;if(0<d.length){this.processChildrenLayout(a,d,b,c);for(var a=0,g=d.length;a<g;a++){var i=d[a],j=e.offset,b=f(i.getData("height",c)-j-e.titleHeight,0),j=f(i.getData("width",c)-j,0),m=i.getPos(c),
b={width:j,height:b,top:m.y+e.titleHeight,left:m.x};this.computePositions(i,b,c)}}},processChildrenLayout:function(a,b,c,d){var a=c.width*c.height,e,f=b.length,g=0,i=[];for(e=0;e<f;e++)i[e]=+b[e].getData("area",d),g+=i[e];for(e=0;e<f;e++)b[e]._area=a*i[e]/g;a=this.layout.horizontal()?c.width:c.height;e=[b[0]].."]]"..[[;this.stripify(b.slice(1),e,a,c,d)},stripify:function(a,b,c,d,e){this.computeDim(a,b,c,d,this.avgAspectRatio,e)},layoutRow:function(a,b,c,d){return this.layout.horizontal()?this.layoutH(a,b,c,
d):this.layoutV(a,b,c,d)},layoutV:function(a,b,c,d){var e=0;g.each(a,function(a){e+=a._area});for(var f=e/b,h=0,i=0,j=a.length;i<j;i++){var m=a[i],k=m._area/f;m.getPos(d).setc(c.left,c.top+(b-k-h));m.setData("width",f,d);m.setData("height",k,d);h+=k}return{height:c.height,width:c.width-f,top:c.top,left:c.left+f,dim:b}},layoutH:function(a,b,c,d){var e=0;g.each(a,function(a){e+=a._area});for(var f=e/b,h=c.height-f,i=0,j=0,m=a.length;j<m;j++){var k=a[j],l=k._area/f;k.getPos(d).setc(c.left+i,c.top+h);
k.setData("width",l,d);k.setData("height",f,d);i+=l}return{height:c.height-f,width:c.width,top:c.top,left:c.left,dim:b}}});s.Icicle=new k({compute:function(a){var a=a||"current",b=this.graph.getNode(this.root),c=this.config,d=this.canvas.getSize(),e=d.width,d=d.height,c=c.constrained?c.levelsToShow:Number.MAX_VALUE;this.controller.onBeforeCompute(b);l.Util.computeLevels(this.graph,b.id,0,"ignore");var f=0;l.Util.eachLevel(b,0,!1,function(a,b){b>f&&(f=b)});var b=this.graph.getNode(this.clickedNode&&
this.clickedNode.id||b.id),c=Math.min(f,c-1),g=b._depth;this.layout.horizontal()?this.computeSubtree(b,-e/2,-d/2,e/(c+1),d,g,c,a):this.computeSubtree(b,-e/2,-d/2,e,d/(c+1),g,c,a)},computeSubtree:function(a,b,c,d,e,f,h,i){a.getPos(i).setc(b,c);a.setData("width",d,i);a.setData("height",e,i);var j=0,k=l.Util.getSubnodes(a,[1,1],"ignore");if(k.length){g.each(k,function(a){j+=a.getData("dim")});for(var n=0,p=k.length;n<p;n++)this.layout.horizontal()?(a=e*k[n].getData("dim")/j,this.computeSubtree(k[n],
b+d,c,d,a,f,h,i),c+=a):(a=d*k[n].getData("dim")/j,this.computeSubtree(k[n],b,c+e,a,e,f,h,i),b+=a)}}});$jit.Icicle=new k({Implements:[{construct:function(a){var b="array"==g.type(a),c=new l(this.graphOptions,this.config.Node,this.config.Edge,this.config.Label);b?function(a,b){for(var c=function(c){for(var f=0,g=b.length;f<g;f++)if(b[f].id==c)return b[f];return a.addNode({id:c,name:c})},h=0,i=b.length;h<i;h++){a.addNode(b[h]);var j=b[h].adjacencies;if(j)for(var k=0,l=j.length;k<l;k++){var p=j[k],o=
{};if("string"!=typeof j[k])o=g.merge(p.data,{}),p=p.nodeTo;a.addAdjacence(b[h],c(p),o)}}}(c,a):function(a,b){a.addNode(b);if(b.children)for(var c=0,g=b.children;c<g.length;c++)a.addAdjacence(b,g[c]),arguments.callee(a,g[c])}(c,a);return c},loadJSON:function(a,b){this.json=a;this.labels&&this.labels.clearLabels&&this.labels.clearLabels(!0);this.graph=this.construct(a);this.root="array"!=g.type(a)?a.id:a[b?b:0].id},toJSON:function(a){if("tree"==(a||"tree"))var b={},b=function e(a){var b={};b.id=a.id;
b.name=a.name;b.data=a.data;var c=[];a.eachSubnode(function(a){c.push(e(a))});b.children=c;return b}(this.graph.getNode(this.root));else{var b=[],c=!!this.graph.getNode(this.root).visited;this.graph.eachNode(function(a){var f={};f.id=a.id;f.name=a.name;f.data=a.data;var g=[];a.eachAdjacency(function(a){var b=a.nodeTo;if(!!b.visited===c){var e={};e.nodeTo=b.id;e.data=a.data;g.push(e)}});f.adjacencies=g;b.push(f);a.visited=!c})}return b}},u,s.Icicle],layout:{orientation:"h",vertical:function(){return"v"==
this.orientation},horizontal:function(){return"h"==this.orientation},change:function(){this.orientation=this.vertical()?"h":"v"}},initialize:function(a){var b={animate:!1,orientation:"h",offset:2,levelsToShow:Number.MAX_VALUE,constrained:!1,Node:{type:"rectangle",overridable:!0},Edge:{type:"none"},Label:{type:"Native"},duration:700,fps:45},c=q("Canvas","Node","Edge","Fx","Tips","NodeStyles","Events","Navigation","Controller","Label");this.controller=this.config=g.merge(c,b,a);this.layout.orientation=
this.config.orientation;a=this.config;a.useCanvas?(this.canvas=a.useCanvas,this.config.labelContainer=this.canvas.id+"-label"):(this.canvas=new v(this,a),this.config.labelContainer=("string"==typeof a.injectInto?a.injectInto:a.injectInto.id)+"-label");this.graphOptions={klass:o,Node:{selected:!1,exist:!0,drawn:!0}};this.graph=new l(this.graphOptions,this.config.Node,this.config.Edge,this.config.Label);this.labels=new $jit.Icicle.Label[this.config.Label.type](this);this.fx=new $jit.Icicle.Plot(this,
$jit.Icicle);this.op=new $jit.Icicle.Op(this);this.group=new $jit.Icicle.Group(this);this.clickedNode=null;this.initializeExtras()},refresh:function(){if("Native"!=this.config.Label.type){var a=this;this.graph.eachNode(function(b){a.labels.hideLabel(b,!1)})}this.compute();this.plot()},plot:function(){this.fx.plot(this.config)},enter:function(a){if(!this.busy){this.busy=!0;var b=this,c=this.config,d={onComplete:function(){c.request&&b.compute();c.animate?(b.graph.nodeList.setDataset(["current","end"],
{alpha:[1,0]}),l.Util.eachSubgraph(a,function(a){a.setData("alpha",1,"end")},"ignore"),b.fx.animate({duration:100,modes:["node-property:alpha"],onComplete:function(){b.clickedNode=a;b.compute("end");b.fx.animate({modes:["linear","node-property:width:height"],duration:400,onComplete:function(){b.busy=!1;b.clickedNode=a}})}})):(b.clickedNode=a,b.busy=!1,b.refresh())}};if(c.request)this.requestNodes(clickedNode,d);else d.onComplete()}},out:function(){if(!this.busy){var a=this,b=l.Util,c=this.config,
d=this.graph,e=b.getParents(d.getNode(this.clickedNode&&this.clickedNode.id||this.root))[0],f=this.clickedNode;this.busy=!0;this.events.hoveredNode=!1;if(e)if(callback={onComplete:function(){a.clickedNode=e;c.request?a.requestNodes(e,{onComplete:function(){a.compute();a.plot();a.busy=!1}}):(a.compute(),a.plot(),a.busy=!1)}},c.animate)this.clickedNode=e,this.compute("end"),this.clickedNode=f,this.fx.animate({modes:["linear","node-property:width:height"],duration:400,onComplete:function(){a.clickedNode=
e;d.nodeList.setDataset(["current","end"],{alpha:[0,1]});b.eachSubgraph(f,function(a){a.setData("alpha",1)},"ignore");a.fx.animate({duration:100,modes:["node-property:alpha"],onComplete:function(){callback.onComplete()}})}});else callback.onComplete();else this.busy=!1}},requestNodes:function(a,b){var c=g.merge(this.controller,b),d=this.config.constrained?this.config.levelsToShow:Number.MAX_VALUE;if(c.request){var e=[],f=a._depth;l.Util.eachLevel(a,0,d,function(a){if(a.drawn&&!l.Util.anySubnode(a)&&
(e.push(a),a._level=a._depth-f,this.config.constrained))a._level=d-a._level});this.group.requestNodes(e,c)}else c.onComplete()}});$jit.Icicle.Op=new k({Implements:l.Op});$jit.Icicle.Group=new k({initialize:function(a){this.viz=a;this.canvas=a.canvas;this.config=a.config},requestNodes:function(a,b){var c=0,d=a.length,e=this.viz;if(0==d)b.onComplete();for(var f=0;f<d;f++)b.request(a[f].id,a[f]._level,{onComplete:function(a,f){if(f&&f.children)f.id=a,e.op.sum(f,{type:"nothing"});++c==d&&(l.Util.computeLevels(e.graph,
e.root,0),b.onComplete())}})}});$jit.Icicle.Plot=new k({Implements:l.Plot,plot:function(a,b){var a=a||this.viz.controller,c=this.viz,d=c.graph.getNode(c.clickedNode&&c.clickedNode.id||c.root),e=d._depth;c.canvas.clear();this.plotTree(d,g.merge(a,{withLabels:!0,hideLabels:!1,plotSubtree:function(a,b){return!c.config.constrained||b._depth-e<c.config.levelsToShow}}),b)}});$jit.Icicle.Label={};$jit.Icicle.Label.Native=new k({Implements:l.Label.Native,renderLabel:function(a,b){var c=a.getCtx(),d=b.getData("width"),
e=b.getData("height"),f=b.getLabelData("size"),g=c.measureText(b.name);e<1.5*f||d<g.width||(f=b.pos.getc(!0),c.fillText(b.name,f.x+d/2,f.y+e/2))}});$jit.Icicle.Label.SVG=new k({Implements:l.Label.SVG,initialize:function(a){this.viz=a},placeLabel:function(a,b,c){var d=b.pos.getc(!0),e=this.viz.canvas.getSize(),f=Math.round(d.x+e.width/2),d=Math.round(d.y+e.height/2);a.setAttribute("x",f);a.setAttribute("y",d);c.onPlaceLabel(a,b)}});$jit.Icicle.Label.HTML=new k({Implements:l.Label.HTML,initialize:function(a){this.viz=
a},placeLabel:function(a,b,c){var d=b.pos.getc(!0),e=this.viz.canvas.getSize(),f=Math.round(d.x+e.width/2),d=Math.round(d.y+e.height/2),e=a.style;e.left=f+"px";e.top=d+"px";e.display="";c.onPlaceLabel(a,b)}});$jit.Icicle.Plot.NodeTypes=new k({none:{render:g.empty},rectangle:{render:function(a,b){var c=this.viz.config,d=c.offset,e=a.getData("width"),f=a.getData("height"),h=a.getData("border"),i=a.pos.getc(!0),j=i.x+d/2,k=i.y+d/2,l=b.getCtx();if(!(2>e-d||2>f-d)){if(c.cushion){var c=a.getData("color"),
p=l.createRadialGradient(j+(e-d)/2,k+(f-d)/2,1,j+(e-d)/2,k+(f-d)/2,e<f?f:e),o=g.rgbToHex(g.map(g.hexToRgb(c),function(a){return 0.3*a>>0}));p.addColorStop(0,c);p.addColorStop(1,o);l.fillStyle=p}if(h)l.strokeStyle=h,l.lineWidth=3;l.fillRect(j,k,Math.max(0,e-d),Math.max(0,f-d));h&&l.strokeRect(i.x,i.y,e,f)}},contains:function(a,b){if(this.viz.clickedNode&&!$jit.Graph.Util.isDescendantOf(a,this.viz.clickedNode.id))return!1;var c=a.pos.getc(!0),d=a.getData("width"),e=a.getData("height");return this.nodeHelper.rectangle.contains({x:c.x+
d/2,y:c.y+e/2},b,d,e)}}});$jit.Icicle.Plot.EdgeTypes=new k({none:g.empty})})();]]


createResourceFile(resourceFile,"jit.js")
resourceFile = [[var labelType, useGradients, nativeTextSupport, animate;

(function() {
  var ua = navigator.userAgent,
      iStuff = ua.match(/iPhone/i) || ua.match(/iPad/i),
      typeOfCanvas = typeof HTMLCanvasElement,
      nativeCanvasSupport = (typeOfCanvas == 'object' || typeOfCanvas == 'function'),
      textSupport = nativeCanvasSupport 
        && (typeof document.createElement('canvas').getContext('2d').fillText == 'function');
  //I'm setting this based on the fact that ExCanvas provides text support for IE
  //and that as of today iPhone/iPad current text support is lame
  labelType = (!nativeCanvasSupport || (textSupport && !iStuff))? 'Native' : 'HTML';
  nativeTextSupport = labelType == 'Native';
  useGradients = nativeCanvasSupport;
  animate = !(iStuff || !nativeCanvasSupport);
})();

var Log = {
  elem: false,
  write: function(text){
    if (!this.elem) 
      this.elem = document.getElementById('log');
    this.elem.innerHTML = text;
    this.elem.style.left = (500 - this.elem.offsetWidth / 2) + 'px';
  }
};


var icicle;

function init(){
  //left panel controls
  controls();

  // init Icicle
  icicle = new $jit.Icicle({
    // id of the visualization container
    injectInto: 'infovis',
    // whether to add transition animations
    animate: animate,
    // nodes offset
    offset: 1,
	duration: 100,
    // whether to add cushion type nodes
    cushion: false,
    //show only three levels at a time
    constrained: true,
    levelsToShow: 3,
    // enable tips
    Tips: {
      enable: true,
      type: 'Native',
      // add positioning offsets
      offsetX: 20,
      offsetY: 20,
      // implement the onShow method to
      // add content to the tooltip when a node
      // is hovered
      onShow: function(tip, node){
        // count children
        var count = 0;
        node.eachSubnode(function(){
          count++;
        });
        // add tooltip info
        tip.innerHTML = "<div class=\"tip-text\">" +  node.name  + "</div>";
      }
    },
    // Add events to nodes
    Events: {
      enable: true,
      onMouseEnter: function(node) {
        //add border and replot node
        node.setData('border', '#33dddd');
        icicle.fx.plotNode(node, icicle.canvas);
        icicle.labels.plotLabel(icicle.canvas, node, icicle.controller);
      },
      onMouseLeave: function(node) {
        node.removeData('border');
        icicle.fx.plot();
      },
      onClick: function(node){
        if (node) {
          //hide tips and selections
          icicle.tips.hide();
          if(icicle.events.hovered)
            this.onMouseLeave(icicle.events.hovered);
          //perform the enter animation
          icicle.enter(node);
        }
      },
      onRightClick: function(){
        //hide tips and selections
        icicle.tips.hide();
        if(icicle.events.hovered)
          this.onMouseLeave(icicle.events.hovered);
        //perform the out animation
        icicle.out();
      }
    },
    // Add canvas label styling
    Label: {
      type: "HTML", // "Native" or "HTML"
	  size: 12
    },
    // Add the name of the node in the corresponding label
    // This method is called once, on label creation and only for DOM and not
    // Native labels.
    onCreateLabel: function(domElement, node){
      domElement.innerHTML = node.name;
      var style = domElement.style;
      style.fontSize = '0.9em';
      style.display = '';
      style.cursor = 'pointer';
      style.color = '#333';
      style.overflow = 'hidden';
    },
    // Change some label dom properties.
    // This method is called each time a label is plotted.
    onPlaceLabel: function(domElement, node){
      var style = domElement.style,
          width = node.getData('width'),
          height = node.getData('height');
      if(width < 7 || height < 7) {
        style.display = 'none';
      } else {
        style.display = '';
        style.width = width + 'px';
        style.height = height + 'px';
      }
    }
  });
  // load data
  icicle.loadJSON(json);
  // compute positions and plot
  icicle.refresh();
}

//init controls
function controls() {
  var jit = $jit;
  var gotoparent = jit.id('update');
  jit.util.addEvent(gotoparent, 'click', function() {
    icicle.out();
  });
  var select = jit.id('s-orientation');
  jit.util.addEvent(select, 'change', function () {
    icicle.layout.orientation = select[select.selectedIndex].value;
    icicle.refresh();
  });
  var levelsToShowSelect = jit.id('i-levels-to-show');
  jit.util.addEvent(levelsToShowSelect, 'change', function () {
    var index = levelsToShowSelect.selectedIndex;
    if(index == 0) {
      icicle.config.constrained = false;
    } else {
      icicle.config.constrained = true;
      icicle.config.levelsToShow = index;
    }
    icicle.refresh();
  });
}
//end
]]

createResourceFile(resourceFile,"profiler.js")

resourceFile = [[// LUA mode. Ported to CodeMirror 2 from Franciszek Wawrzak's
// CodeMirror 1 mode.
// highlights keywords, strings, comments (no leveling supported! ("[==[")), tokens, basic indenting
 
CodeMirror.defineMode("lua", function(config, parserConfig) {
  var indentUnit = config.indentUnit;

  function prefixRE(words) {
    return new RegExp("^(?:" + words.join("|") + ")", "i");
  }
  function wordRE(words) {
    return new RegExp("^(?:" + words.join("|") + ")$", "i");
  }
  var specials = wordRE(parserConfig.specials || []);
 
  // long list of standard functions from lua manual
  var builtins = wordRE([
    "_G","_VERSION","assert","collectgarbage","dofile","error","getfenv","getmetatable","ipairs","load",
    "loadfile","loadstring","module","next","pairs","pcall","print","rawequal","rawget","rawset","require",
    "select","setfenv","setmetatable","tonumber","tostring","type","unpack","xpcall",

    "coroutine.create","coroutine.resume","coroutine.running","coroutine.status","coroutine.wrap","coroutine.yield",

    "debug.debug","debug.getfenv","debug.gethook","debug.getinfo","debug.getlocal","debug.getmetatable",
    "debug.getregistry","debug.getupvalue","debug.setfenv","debug.sethook","debug.setlocal","debug.setmetatable",
    "debug.setupvalue","debug.traceback",

    "close","flush","lines","read","seek","setvbuf","write",

    "io.close","io.flush","io.input","io.lines","io.open","io.output","io.popen","io.read","io.stderr","io.stdin",
    "io.stdout","io.tmpfile","io.type","io.write",

    "math.abs","math.acos","math.asin","math.atan","math.atan2","math.ceil","math.cos","math.cosh","math.deg",
    "math.exp","math.floor","math.fmod","math.frexp","math.huge","math.ldexp","math.log","math.log10","math.max",
    "math.min","math.modf","math.pi","math.pow","math.rad","math.random","math.randomseed","math.sin","math.sinh",
    "math.sqrt","math.tan","math.tanh",

    "os.clock","os.date","os.difftime","os.execute","os.exit","os.getenv","os.remove","os.rename","os.setlocale",
    "os.time","os.tmpname",

    "package.cpath","package.loaded","package.loaders","package.loadlib","package.path","package.preload",
    "package.seeall",

    "string.byte","string.char","string.dump","string.find","string.format","string.gmatch","string.gsub",
    "string.len","string.lower","string.match","string.rep","string.reverse","string.sub","string.upper",

    "table.concat","table.insert","table.maxn","table.remove","table.sort"
  ]);
  var keywords = wordRE(["and","break","elseif","false","nil","not","or","return",
			 "true","function", "end", "if", "then", "else", "do", 
			 "while", "repeat", "until", "for", "in", "local" ]);

  var indentTokens = wordRE(["function", "if","repeat","do", "\\(", "{"]);
  var dedentTokens = wordRE(["end", "until", "\\)", "}"]);
  var dedentPartial = prefixRE(["end", "until", "\\)", "}", "else", "elseif"]);

  function readBracket(stream) {
    var level = 0;
    while (stream.eat("=")) ++level;
    stream.eat("[");
    return level;
  }

  function normal(stream, state) {
    var ch = stream.next();
    if (ch == "-" && stream.eat("-")) {
      if (stream.eat("["))
        return (state.cur = bracketed(readBracket(stream), "comment"))(stream, state);
      stream.skipToEnd();
      return "comment";
    } 
    if (ch == "\"" || ch == "'")
      return (state.cur = string(ch))(stream, state);
    if (ch == "[" && /[\[=]/.test(stream.peek()))
      return (state.cur = bracketed(readBracket(stream), "string"))(stream, state);
    if (/\d/.test(ch)) {
      stream.eatWhile(/[\w.%]/);
      return "number";
    }
    if (/[\w_]/.test(ch)) {
      stream.eatWhile(/[\w\\\-_.]/);
      return "variable";
    }
    return null;
  }

  function bracketed(level, style) {
    return function(stream, state) {
      var curlev = null, ch;
      while ((ch = stream.next()) != null) {
        if (curlev == null) {if (ch == "]") curlev = 0;}
        else if (ch == "=") ++curlev;
        else if (ch == "]" && curlev == level) { state.cur = normal; break; }
        else curlev = null;
      }
      return style;
    };
  }

  function string(quote) {
    return function(stream, state) {
      var escaped = false, ch;
      while ((ch = stream.next()) != null) {
        if (ch == quote && !escaped) break;
        escaped = !escaped && ch == "\\";
      }
      if (!escaped) state.cur = normal;
      return "string";
    };
  }
    
  return {
    startState: function(basecol) {
      return {basecol: basecol || 0, indentDepth: 0, cur: normal};
    },

    token: function(stream, state) {
      if (stream.eatSpace()) return null;
      var style = state.cur(stream, state);
      var word = stream.current();
      if (style == "variable") {
        if (keywords.test(word)) style = "keyword";
        else if (builtins.test(word)) style = "builtin";
	else if (specials.test(word)) style = "variable-2";
      }
      if ((style != "comment") && (style != "string")){
        if (indentTokens.test(word)) ++state.indentDepth;
        else if (dedentTokens.test(word)) --state.indentDepth;
      }
      return style;
    },

    indent: function(state, textAfter) {
      var closing = dedentPartial.test(textAfter);
      return state.basecol + indentUnit * (state.indentDepth - (closing ? 1 : 0));
    }
  };
});

CodeMirror.defineMIME("text/x-lua", "lua");

]]
createResourceFile(resourceFile,"lua.js")
resourceFile = [[// CodeMirror version 2.2
//
// All functions that need access to the editor's state live inside
// the CodeMirror function. Below that, at the bottom of the file,
// some utilities are defined.

// CodeMirror is the only global var we claim
var CodeMirror = (function() {
  // This is the function that produces an editor instance. It's
  // closure is used to store the editor state.
  function CodeMirror(place, givenOptions) {
    // Determine effective options based on given values and defaults.
    var options = {}, defaults = CodeMirror.defaults;
    for (var opt in defaults)
      if (defaults.hasOwnProperty(opt))
        options[opt] = (givenOptions && givenOptions.hasOwnProperty(opt) ? givenOptions : defaults)[opt];

    var targetDocument = options["document"];
    // The element in which the editor lives.
    var wrapper = targetDocument.createElement("div");
    wrapper.className = "CodeMirror" + (options.lineWrapping ? " CodeMirror-wrap" : "");
    // This mess creates the base DOM structure for the editor.
    wrapper.innerHTML =
      '<div style="overflow: hidden; position: relative; width: 3px; height: 0px;">' + // Wraps and hides input textarea
        '<textarea style="position: absolute; padding: 0; width: 1px;" wrap="off" ' +
          'autocorrect="off" autocapitalize="off"></textarea></div>' +
      '<div class="CodeMirror-scroll" tabindex="-1">' +
        '<div style="position: relative">' + // Set to the height of the text, causes scrolling
          '<div style="position: relative">' + // Moved around its parent to cover visible view
            '<div class="CodeMirror-gutter"><div class="CodeMirror-gutter-text"></div></div>' +
            // Provides positioning relative to (visible) text origin
            '<div class="CodeMirror-lines"><div style="position: relative">' +
              '<div style="position: absolute; width: 100%; height: 0; overflow: hidden; visibility: hidden"></div>' +
              '<pre class="CodeMirror-cursor">&#160;</pre>' + // Absolutely positioned blinky cursor
              '<div></div>' + // This DIV contains the actual code
            '</div></div></div></div></div>';
    if (place.appendChild) place.appendChild(wrapper); else place(wrapper);
    // I've never seen more elegant code in my life.
    var inputDiv = wrapper.firstChild, input = inputDiv.firstChild,
        scroller = wrapper.lastChild, code = scroller.firstChild,
        mover = code.firstChild, gutter = mover.firstChild, gutterText = gutter.firstChild,
        lineSpace = gutter.nextSibling.firstChild, measure = lineSpace.firstChild,
        cursor = measure.nextSibling, lineDiv = cursor.nextSibling;
    themeChanged();
    // Needed to hide big blue blinking cursor on Mobile Safari
    if (/AppleWebKit/.test(navigator.userAgent) && /Mobile\/\w+/.test(navigator.userAgent)) input.style.width = "0px";
    if (!webkit) lineSpace.draggable = true;
    if (options.tabindex != null) input.tabIndex = options.tabindex;
    if (!options.gutter && !options.lineNumbers) gutter.style.display = "none";

    // Check for problem with IE innerHTML not working when we have a
    // P (or similar) parent node.
    try { stringWidth("x"); }
    catch (e) {
      if (e.message.match(/runtime/i))
        e = new Error("A CodeMirror inside a P-style element does not work in Internet Explorer. (innerHTML bug)");
      throw e;
    }

    // Delayed object wrap timeouts, making sure only one is active. blinker holds an interval.
    var poll = new Delayed(), highlight = new Delayed(), blinker;

    // mode holds a mode API object. doc is the tree of Line objects,
    // work an array of lines that should be parsed, and history the
    // undo history (instance of History constructor).
    var mode, doc = new BranchChunk([new LeafChunk([new Line("")])]), work, focused;
    loadMode();
    // The selection. These are always maintained to point at valid
    // positions. Inverted is used to remember that the user is
    // selecting bottom-to-top.
    var sel = {from: {line: 0, ch: 0}, to: {line: 0, ch: 0}, inverted: false};
    // Selection-related flags. shiftSelecting obviously tracks
    // whether the user is holding shift.
    var shiftSelecting, lastClick, lastDoubleClick, draggingText, overwrite = false;
    // Variables used by startOperation/endOperation to track what
    // happened during the operation.
    var updateInput, userSelChange, changes, textChanged, selectionChanged, leaveInputAlone,
        gutterDirty, callbacks;
    // Current visible range (may be bigger than the view window).
    var displayOffset = 0, showingFrom = 0, showingTo = 0, lastSizeC = 0;
    // bracketHighlighted is used to remember that a backet has been
    // marked.
    var bracketHighlighted;
    // Tracks the maximum line length so that the horizontal scrollbar
    // can be kept static when scrolling.
    var maxLine = "", maxWidth, tabText = computeTabText();

    // Initialize the content.
    operation(function(){setValue(options.value || ""); updateInput = false;})();
    var history = new History();

    // Register our event handlers.
    connect(scroller, "mousedown", operation(onMouseDown));
    connect(scroller, "dblclick", operation(onDoubleClick));
    connect(lineSpace, "dragstart", onDragStart);
    connect(lineSpace, "selectstart", e_preventDefault);
    // Gecko browsers fire contextmenu *after* opening the menu, at
    // which point we can't mess with it anymore. Context menu is
    // handled in onMouseDown for Gecko.
    if (!gecko) connect(scroller, "contextmenu", onContextMenu);
    connect(scroller, "scroll", function() {
      updateDisplay([]);
      if (options.fixedGutter) gutter.style.left = scroller.scrollLeft + "px";
      if (options.onScroll) options.onScroll(instance);
    });
    connect(window, "resize", function() {updateDisplay(true);});
    connect(input, "keyup", operation(onKeyUp));
    connect(input, "input", fastPoll);
    connect(input, "keydown", operation(onKeyDown));
    connect(input, "keypress", operation(onKeyPress));
    connect(input, "focus", onFocus);
    connect(input, "blur", onBlur);

    connect(scroller, "dragenter", e_stop);
    connect(scroller, "dragover", e_stop);
    connect(scroller, "drop", operation(onDrop));
    connect(scroller, "paste", function(){focusInput(); fastPoll();});
    connect(input, "paste", fastPoll);
    connect(input, "cut", operation(function(){replaceSelection("");}));

    // IE throws unspecified error in certain cases, when
    // trying to access activeElement before onload
    var hasFocus; try { hasFocus = (targetDocument.activeElement == input); } catch(e) { }
    if (hasFocus) setTimeout(onFocus, 20);
    else onBlur();

    function isLine(l) {return l >= 0 && l < doc.size;}
    // The instance object that we'll return. Mostly calls out to
    // local functions in the CodeMirror function. Some do some extra
    // range checking and/or clipping. operation is used to wrap the
    // call so that changes it makes are tracked, and the display is
    // updated afterwards.
    var instance = wrapper.CodeMirror = {
      getValue: getValue,
      setValue: operation(setValue),
      getSelection: getSelection,
      replaceSelection: operation(replaceSelection),
      focus: function(){focusInput(); onFocus(); fastPoll();},
      setOption: function(option, value) {
        var oldVal = options[option];
        options[option] = value;
        if (option == "mode" || option == "indentUnit") loadMode();
        else if (option == "readOnly" && value) {onBlur(); input.blur();}
        else if (option == "theme") themeChanged();
        else if (option == "lineWrapping" && oldVal != value) operation(wrappingChanged)();
        else if (option == "tabSize") operation(tabsChanged)();
        if (option == "lineNumbers" || option == "gutter" || option == "firstLineNumber" || option == "theme")
          operation(gutterChanged)();
      },
      getOption: function(option) {return options[option];},
      undo: operation(undo),
      redo: operation(redo),
      indentLine: operation(function(n, dir) {
        if (isLine(n)) indentLine(n, dir == null ? "smart" : dir ? "add" : "subtract");
      }),
      indentSelection: operation(indentSelected),
      historySize: function() {return {undo: history.done.length, redo: history.undone.length};},
      clearHistory: function() {history = new History();},
      matchBrackets: operation(function(){matchBrackets(true);}),
      getTokenAt: operation(function(pos) {
        pos = clipPos(pos);
        return getLine(pos.line).getTokenAt(mode, getStateBefore(pos.line), pos.ch);
      }),
      getStateAfter: function(line) {
        line = clipLine(line == null ? doc.size - 1: line);
        return getStateBefore(line + 1);
      },
      cursorCoords: function(start){
        if (start == null) start = sel.inverted;
        return pageCoords(start ? sel.from : sel.to);
      },
      charCoords: function(pos){return pageCoords(clipPos(pos));},
      coordsChar: function(coords) {
        var off = eltOffset(lineSpace);
        return coordsChar(coords.x - off.left, coords.y - off.top);
      },
      markText: operation(markText),
      setBookmark: setBookmark,
      setMarker: operation(addGutterMarker),
      clearMarker: operation(removeGutterMarker),
      setLineClass: operation(setLineClass),
      hideLine: operation(function(h) {return setLineHidden(h, true);}),
      showLine: operation(function(h) {return setLineHidden(h, false);}),
      onDeleteLine: function(line, f) {
        if (typeof line == "number") {
          if (!isLine(line)) return null;
          line = getLine(line);
        }
        (line.handlers || (line.handlers = [])).push(f);
        return line;
      },
      lineInfo: lineInfo,
      addWidget: function(pos, node, scroll, vert, horiz) {
        pos = localCoords(clipPos(pos));
        var top = pos.yBot, left = pos.x;
        node.style.position = "absolute";
        code.appendChild(node);
        if (vert == "over") top = pos.y;
        else if (vert == "near") {
          var vspace = Math.max(scroller.offsetHeight, doc.height * textHeight()),
              hspace = Math.max(code.clientWidth, lineSpace.clientWidth) - paddingLeft();
          if (pos.yBot + node.offsetHeight > vspace && pos.y > node.offsetHeight)
            top = pos.y - node.offsetHeight;
          if (left + node.offsetWidth > hspace)
            left = hspace - node.offsetWidth;
        }
        node.style.top = (top + paddingTop()) + "px";
        node.style.left = node.style.right = "";
        if (horiz == "right") {
          left = code.clientWidth - node.offsetWidth;
          node.style.right = "0px";
        } else {
          if (horiz == "left") left = 0;
          else if (horiz == "middle") left = (code.clientWidth - node.offsetWidth) / 2;
          node.style.left = (left + paddingLeft()) + "px";
        }
        if (scroll)
          scrollIntoView(left, top, left + node.offsetWidth, top + node.offsetHeight);
      },

      lineCount: function() {return doc.size;},
      clipPos: clipPos,
      getCursor: function(start) {
        if (start == null) start = sel.inverted;
        return copyPos(start ? sel.from : sel.to);
      },
      somethingSelected: function() {return !posEq(sel.from, sel.to);},
      setCursor: operation(function(line, ch, user) {
        if (ch == null && typeof line.line == "number") setCursor(line.line, line.ch, user);
        else setCursor(line, ch, user);
      }),
      setSelection: operation(function(from, to, user) {
        (user ? setSelectionUser : setSelection)(clipPos(from), clipPos(to || from));
      }),
      getLine: function(line) {if (isLine(line)) return getLine(line).text;},
      getLineHandle: function(line) {if (isLine(line)) return getLine(line);},
      setLine: operation(function(line, text) {
        if (isLine(line)) replaceRange(text, {line: line, ch: 0}, {line: line, ch: getLine(line).text.length});
      }),
      removeLine: operation(function(line) {
        if (isLine(line)) replaceRange("", {line: line, ch: 0}, clipPos({line: line+1, ch: 0}));
      }),
      replaceRange: operation(replaceRange),
      getRange: function(from, to) {return getRange(clipPos(from), clipPos(to));},

      execCommand: function(cmd) {return commands[cmd](instance);},
      // Stuff used by commands, probably not much use to outside code.
      moveH: operation(moveH),
      deleteH: operation(deleteH),
      moveV: operation(moveV),
      toggleOverwrite: function() {overwrite = !overwrite;},

      posFromIndex: function(off) {
        var lineNo = 0, ch;
        doc.iter(0, doc.size, function(line) {
          var sz = line.text.length + 1;
          if (sz > off) { ch = off; return true; }
          off -= sz;
          ++lineNo;
        });
        return clipPos({line: lineNo, ch: ch});
      },
      indexFromPos: function (coords) {
        if (coords.line < 0 || coords.ch < 0) return 0;
        var index = coords.ch;
        doc.iter(0, coords.line, function (line) {
          index += line.text.length + 1;
        });
        return index;
      },

      operation: function(f){return operation(f)();},
      refresh: function(){updateDisplay(true);},
      getInputField: function(){return input;},
      getWrapperElement: function(){return wrapper;},
      getScrollerElement: function(){return scroller;},
      getGutterElement: function(){return gutter;}
    };

    function getLine(n) { return getLineAt(doc, n); }
    function updateLineHeight(line, height) {
      gutterDirty = true;
      var diff = height - line.height;
      for (var n = line; n; n = n.parent) n.height += diff;
    }

    function setValue(code) {
      var top = {line: 0, ch: 0};
      updateLines(top, {line: doc.size - 1, ch: getLine(doc.size-1).text.length},
                  splitLines(code), top, top);
      updateInput = true;
    }
    function getValue(code) {
      var text = [];
      doc.iter(0, doc.size, function(line) { text.push(line.text); });
      return text.join("\n");
    }

    function onMouseDown(e) {
      setShift(e.shiftKey);
      // Check whether this is a click in a widget
      for (var n = e_target(e); n != wrapper; n = n.parentNode)
        if (n.parentNode == code && n != mover) return;

      // See if this is a click in the gutter
      for (var n = e_target(e); n != wrapper; n = n.parentNode)
        if (n.parentNode == gutterText) {
          if (options.onGutterClick)
            options.onGutterClick(instance, indexOf(gutterText.childNodes, n) + showingFrom, e);
          return e_preventDefault(e);
        }

      var start = posFromMouse(e);

      switch (e_button(e)) {
      case 3:
        if (gecko && !mac) onContextMenu(e);
        return;
      case 2:
        if (start) setCursor(start.line, start.ch, true);
        return;
      }
      // For button 1, if it was clicked inside the editor
      // (posFromMouse returning non-null), we have to adjust the
      // selection.
      if (!start) {if (e_target(e) == scroller) e_preventDefault(e); return;}

      if (!focused) onFocus();

      var now = +new Date;
      if (lastDoubleClick && lastDoubleClick.time > now - 400 && posEq(lastDoubleClick.pos, start)) {
        e_preventDefault(e);
        setTimeout(focusInput, 20);
        return selectLine(start.line);
      } else if (lastClick && lastClick.time > now - 400 && posEq(lastClick.pos, start)) {
        lastDoubleClick = {time: now, pos: start};
        e_preventDefault(e);
        return selectWordAt(start);
      } else { lastClick = {time: now, pos: start}; }

      var last = start, going;
      if (dragAndDrop && !posEq(sel.from, sel.to) &&
          !posLess(start, sel.from) && !posLess(sel.to, start)) {
        // Let the drag handler handle this.
        if (webkit) lineSpace.draggable = true;
        var up = connect(targetDocument, "mouseup", operation(function(e2) {
          if (webkit) lineSpace.draggable = false;
          draggingText = false;
          up();
          if (Math.abs(e.clientX - e2.clientX) + Math.abs(e.clientY - e2.clientY) < 10) {
            e_preventDefault(e2);
            setCursor(start.line, start.ch, true);
            focusInput();
          }
        }), true);
        draggingText = true;
        return;
      }
      e_preventDefault(e);
      setCursor(start.line, start.ch, true);

      function extend(e) {
        var cur = posFromMouse(e, true);
        if (cur && !posEq(cur, last)) {
          if (!focused) onFocus();
          last = cur;
          setSelectionUser(start, cur);
          updateInput = false;
          var visible = visibleLines();
          if (cur.line >= visible.to || cur.line < visible.from)
            going = setTimeout(operation(function(){extend(e);}), 150);
        }
      }

      var move = connect(targetDocument, "mousemove", operation(function(e) {
        clearTimeout(going);
        e_preventDefault(e);
        extend(e);
      }), true);
      var up = connect(targetDocument, "mouseup", operation(function(e) {
        clearTimeout(going);
        var cur = posFromMouse(e);
        if (cur) setSelectionUser(start, cur);
        e_preventDefault(e);
        focusInput();
        updateInput = true;
        move(); up();
      }), true);
    }
    function onDoubleClick(e) {
      for (var n = e_target(e); n != wrapper; n = n.parentNode)
        if (n.parentNode == gutterText) return e_preventDefault(e);
      var start = posFromMouse(e);
      if (!start) return;
      lastDoubleClick = {time: +new Date, pos: start};
      e_preventDefault(e);
      selectWordAt(start);
    }
    function onDrop(e) {
      e.preventDefault();
      var pos = posFromMouse(e, true), files = e.dataTransfer.files;
      if (!pos || options.readOnly) return;
      if (files && files.length && window.FileReader && window.File) {
        function loadFile(file, i) {
          var reader = new FileReader;
          reader.onload = function() {
            text[i] = reader.result;
            if (++read == n) {
	      pos = clipPos(pos);
	      operation(function() {
                var end = replaceRange(text.join(""), pos, pos);
                setSelectionUser(pos, end);
              })();
	    }
          };
          reader.readAsText(file);
        }
        var n = files.length, text = Array(n), read = 0;
        for (var i = 0; i < n; ++i) loadFile(files[i], i);
      }
      else {
        try {
          var text = e.dataTransfer.getData("Text");
          if (text) {
	    var end = replaceRange(text, pos, pos);
	    var curFrom = sel.from, curTo = sel.to;
	    setSelectionUser(pos, end);
            if (draggingText) replaceRange("", curFrom, curTo);
	    focusInput();
	  }
        }
        catch(e){}
      }
    }
    function onDragStart(e) {
      var txt = getSelection();
      // This will reset escapeElement
      htmlEscape(txt);
      e.dataTransfer.setDragImage(escapeElement, 0, 0);
      e.dataTransfer.setData("Text", txt);
    }
    function handleKeyBinding(e) {
      var name = keyNames[e.keyCode], next = keyMap[options.keyMap].auto, bound, dropShift;
      if (name == null || e.altGraphKey) {
        if (next) options.keyMap = next;
        return null;
      }
      if (e.altKey) name = "Alt-" + name;
      if (e.ctrlKey) name = "Ctrl-" + name;
      if (e.metaKey) name = "Cmd-" + name;
      if (e.shiftKey && (bound = lookupKey("Shift-" + name, options.extraKeys, options.keyMap))) {
        dropShift = true;
      } else {
        bound = lookupKey(name, options.extraKeys, options.keyMap);
      }
      if (typeof bound == "string") {
        if (commands.propertyIsEnumerable(bound)) bound = commands[bound];
        else bound = null;
      }
      if (next && (bound || !isModifierKey(e))) options.keyMap = next;
      if (!bound) return false;
      if (dropShift) {
        var prevShift = shiftSelecting;
        shiftSelecting = null;
        bound(instance);
        shiftSelecting = prevShift;
      } else bound(instance);
      e_preventDefault(e);
      return true;
    }
    var lastStoppedKey = null;
    function onKeyDown(e) {
      if (!focused) onFocus();
      var code = e.keyCode;
      // IE does strange things with escape.
      if (ie && code == 27) { e.returnValue = false; }
      setShift(code == 16 || e.shiftKey);
      // First give onKeyEvent option a chance to handle this.
      if (options.onKeyEvent && options.onKeyEvent(instance, addStop(e))) return;
      var handled = handleKeyBinding(e);
      if (window.opera) {
        lastStoppedKey = handled ? e.keyCode : null;
        // Opera has no cut event... we try to at least catch the key combo
        if (!handled && (mac ? e.metaKey : e.ctrlKey) && e.keyCode == 88)
          replaceSelection("");
      }
    }
    function onKeyPress(e) {
      if (window.opera && e.keyCode == lastStoppedKey) {lastStoppedKey = null; e_preventDefault(e); return;}
      if (options.onKeyEvent && options.onKeyEvent(instance, addStop(e))) return;
      if (window.opera && !e.which && handleKeyBinding(e)) return;
      if (options.electricChars && mode.electricChars) {
        var ch = String.fromCharCode(e.charCode == null ? e.keyCode : e.charCode);
        if (mode.electricChars.indexOf(ch) > -1)
          setTimeout(operation(function() {indentLine(sel.to.line, "smart");}), 75);
      }
      fastPoll();
    }
    function onKeyUp(e) {
      if (options.onKeyEvent && options.onKeyEvent(instance, addStop(e))) return;
      if (e.keyCode == 16) shiftSelecting = null;
    }

    function onFocus() {
      if (options.readOnly) return;
      if (!focused) {
        if (options.onFocus) options.onFocus(instance);
        focused = true;
        if (wrapper.className.search(/\bCodeMirror-focused\b/) == -1)
          wrapper.className += " CodeMirror-focused";
        if (!leaveInputAlone) resetInput(true);
      }
      slowPoll();
      restartBlink();
    }
    function onBlur() {
      if (focused) {
        if (options.onBlur) options.onBlur(instance);
        focused = false;
        wrapper.className = wrapper.className.replace(" CodeMirror-focused", "");
      }
      clearInterval(blinker);
      setTimeout(function() {if (!focused) shiftSelecting = null;}, 150);
    }

    // Replace the range from from to to by the strings in newText.
    // Afterwards, set the selection to selFrom, selTo.
    function updateLines(from, to, newText, selFrom, selTo) {
      if (history) {
        var old = [];
        doc.iter(from.line, to.line + 1, function(line) { old.push(line.text); });
        history.addChange(from.line, newText.length, old);
        while (history.done.length > options.undoDepth) history.done.shift();
      }
      updateLinesNoUndo(from, to, newText, selFrom, selTo);
    }
    function unredoHelper(from, to) {
      var change = from.pop();
      if (change) {
        var replaced = [], end = change.start + change.added;
        doc.iter(change.start, end, function(line) { replaced.push(line.text); });
        to.push({start: change.start, added: change.old.length, old: replaced});
        var pos = clipPos({line: change.start + change.old.length - 1,
                           ch: editEnd(replaced[replaced.length-1], change.old[change.old.length-1])});
        updateLinesNoUndo({line: change.start, ch: 0}, {line: end - 1, ch: getLine(end-1).text.length}, change.old, pos, pos);
        updateInput = true;
      }
    }
    function undo() {unredoHelper(history.done, history.undone);}
    function redo() {unredoHelper(history.undone, history.done);}

    function updateLinesNoUndo(from, to, newText, selFrom, selTo) {
      var recomputeMaxLength = false, maxLineLength = maxLine.length;
      if (!options.lineWrapping)
        doc.iter(from.line, to.line, function(line) {
          if (line.text.length == maxLineLength) {recomputeMaxLength = true; return true;}
        });
      if (from.line != to.line || newText.length > 1) gutterDirty = true;

      var nlines = to.line - from.line, firstLine = getLine(from.line), lastLine = getLine(to.line);
      // First adjust the line structure, taking some care to leave highlighting intact.
      if (from.ch == 0 && to.ch == 0 && newText[newText.length - 1] == "") {
        // This is a whole-line replace. Treated specially to make
        // sure line objects move the way they are supposed to.
        var added = [], prevLine = null;
        if (from.line) {
          prevLine = getLine(from.line - 1);
          prevLine.fixMarkEnds(lastLine);
        } else lastLine.fixMarkStarts();
        for (var i = 0, e = newText.length - 1; i < e; ++i)
          added.push(Line.inheritMarks(newText[i], prevLine));
        if (nlines) doc.remove(from.line, nlines, callbacks);
        if (added.length) doc.insert(from.line, added);
      } else if (firstLine == lastLine) {
        if (newText.length == 1)
          firstLine.replace(from.ch, to.ch, newText[0]);
        else {
          lastLine = firstLine.split(to.ch, newText[newText.length-1]);
          firstLine.replace(from.ch, null, newText[0]);
          firstLine.fixMarkEnds(lastLine);
          var added = [];
          for (var i = 1, e = newText.length - 1; i < e; ++i)
            added.push(Line.inheritMarks(newText[i], firstLine));
          added.push(lastLine);
          doc.insert(from.line + 1, added);
        }
      } else if (newText.length == 1) {
        firstLine.replace(from.ch, null, newText[0]);
        lastLine.replace(null, to.ch, "");
        firstLine.append(lastLine);
        doc.remove(from.line + 1, nlines, callbacks);
      } else {
        var added = [];
        firstLine.replace(from.ch, null, newText[0]);
        lastLine.replace(null, to.ch, newText[newText.length-1]);
        firstLine.fixMarkEnds(lastLine);
        for (var i = 1, e = newText.length - 1; i < e; ++i)
          added.push(Line.inheritMarks(newText[i], firstLine));
        if (nlines > 1) doc.remove(from.line + 1, nlines - 1, callbacks);
        doc.insert(from.line + 1, added);
      }
      if (options.lineWrapping) {
        var perLine = scroller.clientWidth / charWidth() - 3;
        doc.iter(from.line, from.line + newText.length, function(line) {
          if (line.hidden) return;
          var guess = Math.ceil(line.text.length / perLine) || 1;
          if (guess != line.height) updateLineHeight(line, guess);
        });
      } else {
        doc.iter(from.line, i + newText.length, function(line) {
          var l = line.text;
          if (l.length > maxLineLength) {
            maxLine = l; maxLineLength = l.length; maxWidth = null;
            recomputeMaxLength = false;
          }
        });
        if (recomputeMaxLength) {
          maxLineLength = 0; maxLine = ""; maxWidth = null;
          doc.iter(0, doc.size, function(line) {
            var l = line.text;
            if (l.length > maxLineLength) {
              maxLineLength = l.length; maxLine = l;
            }
          });
        }
      }

      // Add these lines to the work array, so that they will be
      // highlighted. Adjust work lines if lines were added/removed.
      var newWork = [], lendiff = newText.length - nlines - 1;
      for (var i = 0, l = work.length; i < l; ++i) {
        var task = work[i];
        if (task < from.line) newWork.push(task);
        else if (task > to.line) newWork.push(task + lendiff);
      }
      var hlEnd = from.line + Math.min(newText.length, 500);
      highlightLines(from.line, hlEnd);
      newWork.push(hlEnd);
      work = newWork;
      startWorker(100);
      // Remember that these lines changed, for updating the display
      changes.push({from: from.line, to: to.line + 1, diff: lendiff});
      var changeObj = {from: from, to: to, text: newText};
      if (textChanged) {
        for (var cur = textChanged; cur.next; cur = cur.next) {}
        cur.next = changeObj;
      } else textChanged = changeObj;

      // Update the selection
      function updateLine(n) {return n <= Math.min(to.line, to.line + lendiff) ? n : n + lendiff;}
      setSelection(selFrom, selTo, updateLine(sel.from.line), updateLine(sel.to.line));

      // Make sure the scroll-size div has the correct height.
      code.style.height = (doc.height * textHeight() + 2 * paddingTop()) + "px";
    }

    function replaceRange(code, from, to) {
      from = clipPos(from);
      if (!to) to = from; else to = clipPos(to);
      code = splitLines(code);
      function adjustPos(pos) {
        if (posLess(pos, from)) return pos;
        if (!posLess(to, pos)) return end;
        var line = pos.line + code.length - (to.line - from.line) - 1;
        var ch = pos.ch;
        if (pos.line == to.line)
          ch += code[code.length-1].length - (to.ch - (to.line == from.line ? from.ch : 0));
        return {line: line, ch: ch};
      }
      var end;
      replaceRange1(code, from, to, function(end1) {
        end = end1;
        return {from: adjustPos(sel.from), to: adjustPos(sel.to)};
      });
      return end;
    }
    function replaceSelection(code, collapse) {
      replaceRange1(splitLines(code), sel.from, sel.to, function(end) {
        if (collapse == "end") return {from: end, to: end};
        else if (collapse == "start") return {from: sel.from, to: sel.from};
        else return {from: sel.from, to: end};
      });
    }
    function replaceRange1(code, from, to, computeSel) {
      var endch = code.length == 1 ? code[0].length + from.ch : code[code.length-1].length;
      var newSel = computeSel({line: from.line + code.length - 1, ch: endch});
      updateLines(from, to, code, newSel.from, newSel.to);
    }

    function getRange(from, to) {
      var l1 = from.line, l2 = to.line;
      if (l1 == l2) return getLine(l1).text.slice(from.ch, to.ch);
      var code = [getLine(l1).text.slice(from.ch)];
      doc.iter(l1 + 1, l2, function(line) { code.push(line.text); });
      code.push(getLine(l2).text.slice(0, to.ch));
      return code.join("\n");
    }
    function getSelection() {
      return getRange(sel.from, sel.to);
    }

    var pollingFast = false; // Ensures slowPoll doesn't cancel fastPoll
    function slowPoll() {
      if (pollingFast) return;
      poll.set(options.pollInterval, function() {
        startOperation();
        readInput();
        if (focused) slowPoll();
        endOperation();
      });
    }
    function fastPoll() {
      var missed = false;
      pollingFast = true;
      function p() {
        startOperation();
        var changed = readInput();
        if (!changed && !missed) {missed = true; poll.set(60, p);}
        else {pollingFast = false; slowPoll();}
        endOperation();
      }
      poll.set(20, p);
    }

    // Previnput is a hack to work with IME. If we reset the textarea
    // on every change, that breaks IME. So we look for changes
    // compared to the previous content instead. (Modern browsers have
    // events that indicate IME taking place, but these are not widely
    // supported or compatible enough yet to rely on.)
    var prevInput = "";
    function readInput() {
      if (leaveInputAlone || !focused || hasSelection(input)) return false;
      var text = input.value;
      if (text == prevInput) return false;
      shiftSelecting = null;
      var same = 0, l = Math.min(prevInput.length, text.length);
      while (same < l && prevInput[same] == text[same]) ++same;
      if (same < prevInput.length)
        sel.from = {line: sel.from.line, ch: sel.from.ch - (prevInput.length - same)};
      else if (overwrite && posEq(sel.from, sel.to))
        sel.to = {line: sel.to.line, ch: Math.min(getLine(sel.to.line).text.length, sel.to.ch + (text.length - same))};
      replaceSelection(text.slice(same), "end");
      prevInput = text;
      return true;
    }
    function resetInput(user) {
      if (!posEq(sel.from, sel.to)) {
        prevInput = "";
        input.value = getSelection();
        input.select();
      } else if (user) prevInput = input.value = "";
    }

    function focusInput() {
      if (!options.readOnly) input.focus();
    }

    function scrollEditorIntoView() {
      if (!cursor.getBoundingClientRect) return;
      var rect = cursor.getBoundingClientRect();
      // IE returns bogus coordinates when the instance sits inside of an iframe and the cursor is hidden
      if (ie && rect.top == rect.bottom) return;
      var winH = window.innerHeight || Math.max(document.body.offsetHeight, document.documentElement.offsetHeight);
      if (rect.top < 0 || rect.bottom > winH) cursor.scrollIntoView();
    }
    function scrollCursorIntoView() {
      var cursor = localCoords(sel.inverted ? sel.from : sel.to);
      var x = options.lineWrapping ? Math.min(cursor.x, lineSpace.offsetWidth) : cursor.x;
      return scrollIntoView(x, cursor.y, x, cursor.yBot);
    }
    function scrollIntoView(x1, y1, x2, y2) {
      var pl = paddingLeft(), pt = paddingTop(), lh = textHeight();
      y1 += pt; y2 += pt; x1 += pl; x2 += pl;
      var screen = scroller.clientHeight, screentop = scroller.scrollTop, scrolled = false, result = true;
      if (y1 < screentop) {scroller.scrollTop = Math.max(0, y1 - 2*lh); scrolled = true;}
      else if (y2 > screentop + screen) {scroller.scrollTop = y2 + lh - screen; scrolled = true;}

      var screenw = scroller.clientWidth, screenleft = scroller.scrollLeft;
      var gutterw = options.fixedGutter ? gutter.clientWidth : 0;
      if (x1 < screenleft + gutterw) {
        if (x1 < 50) x1 = 0;
        scroller.scrollLeft = Math.max(0, x1 - 10 - gutterw);
        scrolled = true;
      }
      else if (x2 > screenw + screenleft - 3) {
        scroller.scrollLeft = x2 + 10 - screenw;
        scrolled = true;
        if (x2 > code.clientWidth) result = false;
      }
      if (scrolled && options.onScroll) options.onScroll(instance);
      return result;
    }

    function visibleLines() {
      var lh = textHeight(), top = scroller.scrollTop - paddingTop();
      var from_height = Math.max(0, Math.floor(top / lh));
      var to_height = Math.ceil((top + scroller.clientHeight) / lh);
      return {from: lineAtHeight(doc, from_height),
              to: lineAtHeight(doc, to_height)};
    }
    // Uses a set of changes plus the current scroll position to
    // determine which DOM updates have to be made, and makes the
    // updates.
    function updateDisplay(changes, suppressCallback) {
      if (!scroller.clientWidth) {
        showingFrom = showingTo = displayOffset = 0;
        return;
      }
      // Compute the new visible window
      var visible = visibleLines();
      // Bail out if the visible area is already rendered and nothing changed.
      if (changes !== true && changes.length == 0 && visible.from >= showingFrom && visible.to <= showingTo) return;
      var from = Math.max(visible.from - 100, 0), to = Math.min(doc.size, visible.to + 100);
      if (showingFrom < from && from - showingFrom < 20) from = showingFrom;
      if (showingTo > to && showingTo - to < 20) to = Math.min(doc.size, showingTo);

      // Create a range of theoretically intact lines, and punch holes
      // in that using the change info.
      var intact = changes === true ? [] :
        computeIntact([{from: showingFrom, to: showingTo, domStart: 0}], changes);
      // Clip off the parts that won't be visible
      var intactLines = 0;
      for (var i = 0; i < intact.length; ++i) {
        var range = intact[i];
        if (range.from < from) {range.domStart += (from - range.from); range.from = from;}
        if (range.to > to) range.to = to;
        if (range.from >= range.to) intact.splice(i--, 1);
        else intactLines += range.to - range.from;
      }
      if (intactLines == to - from) return;
      intact.sort(function(a, b) {return a.domStart - b.domStart;});

      var th = textHeight(), gutterDisplay = gutter.style.display;
      lineDiv.style.display = gutter.style.display = "none";
      patchDisplay(from, to, intact);
      lineDiv.style.display = "";

      // Position the mover div to align with the lines it's supposed
      // to be showing (which will cover the visible display)
      var different = from != showingFrom || to != showingTo || lastSizeC != scroller.clientHeight + th;
      // This is just a bogus formula that detects when the editor is
      // resized or the font size changes.
      if (different) lastSizeC = scroller.clientHeight + th;
      showingFrom = from; showingTo = to;
      displayOffset = heightAtLine(doc, from);
      mover.style.top = (displayOffset * th) + "px";
      code.style.height = (doc.height * th + 2 * paddingTop()) + "px";

      // Since this is all rather error prone, it is honoured with the
      // only assertion in the whole file.
      if (lineDiv.childNodes.length != showingTo - showingFrom)
        throw new Error("BAD PATCH! " + JSON.stringify(intact) + " size=" + (showingTo - showingFrom) +
                        " nodes=" + lineDiv.childNodes.length);

      if (options.lineWrapping) {
        maxWidth = scroller.clientWidth;
        var curNode = lineDiv.firstChild;
        doc.iter(showingFrom, showingTo, function(line) {
          if (!line.hidden) {
            var height = Math.round(curNode.offsetHeight / th) || 1;
            if (line.height != height) {updateLineHeight(line, height); gutterDirty = true;}
          }
          curNode = curNode.nextSibling;
        });
      } else {
        if (maxWidth == null) maxWidth = stringWidth(maxLine);
        if (maxWidth > scroller.clientWidth) {
          lineSpace.style.width = maxWidth + "px";
          // Needed to prevent odd wrapping/hiding of widgets placed in here.
          code.style.width = "";
          code.style.width = scroller.scrollWidth + "px";
        } else {
          lineSpace.style.width = code.style.width = "";
        }
      }
      gutter.style.display = gutterDisplay;
      if (different || gutterDirty) updateGutter();
      updateCursor();
      if (!suppressCallback && options.onUpdate) options.onUpdate(instance);
      return true;
    }

    function computeIntact(intact, changes) {
      for (var i = 0, l = changes.length || 0; i < l; ++i) {
        var change = changes[i], intact2 = [], diff = change.diff || 0;
        for (var j = 0, l2 = intact.length; j < l2; ++j) {
          var range = intact[j];
          if (change.to <= range.from && change.diff)
            intact2.push({from: range.from + diff, to: range.to + diff,
                          domStart: range.domStart});
          else if (change.to <= range.from || change.from >= range.to)
            intact2.push(range);
          else {
            if (change.from > range.from)
              intact2.push({from: range.from, to: change.from, domStart: range.domStart});
            if (change.to < range.to)
              intact2.push({from: change.to + diff, to: range.to + diff,
                            domStart: range.domStart + (change.to - range.from)});
          }
        }
        intact = intact2;
      }
      return intact;
    }

    function patchDisplay(from, to, intact) {
      // The first pass removes the DOM nodes that aren't intact.
      if (!intact.length) lineDiv.innerHTML = "";
      else {
        function killNode(node) {
          var tmp = node.nextSibling;
          node.parentNode.removeChild(node);
          return tmp;
        }
        var domPos = 0, curNode = lineDiv.firstChild, n;
        for (var i = 0; i < intact.length; ++i) {
          var cur = intact[i];
          while (cur.domStart > domPos) {curNode = killNode(curNode); domPos++;}
          for (var j = 0, e = cur.to - cur.from; j < e; ++j) {curNode = curNode.nextSibling; domPos++;}
        }
        while (curNode) curNode = killNode(curNode);
      }
      // This pass fills in the lines that actually changed.
      var nextIntact = intact.shift(), curNode = lineDiv.firstChild, j = from;
      var sfrom = sel.from.line, sto = sel.to.line, inSel = sfrom < from && sto >= from;
      var scratch = targetDocument.createElement("div"), newElt;
      doc.iter(from, to, function(line) {
        var ch1 = null, ch2 = null;
        if (inSel) {
          ch1 = 0;
          if (sto == j) {inSel = false; ch2 = sel.to.ch;}
        } else if (sfrom == j) {
          if (sto == j) {ch1 = sel.from.ch; ch2 = sel.to.ch;}
          else {inSel = true; ch1 = sel.from.ch;}
        }
        if (nextIntact && nextIntact.to == j) nextIntact = intact.shift();
        if (!nextIntact || nextIntact.from > j) {
          if (line.hidden) scratch.innerHTML = "<pre></pre>";
          else scratch.innerHTML = line.getHTML(ch1, ch2, true, tabText);
          lineDiv.insertBefore(scratch.firstChild, curNode);
        } else {
          curNode = curNode.nextSibling;
        }
        ++j;
      });
    }

    function updateGutter() {
      if (!options.gutter && !options.lineNumbers) return;
      var hText = mover.offsetHeight, hEditor = scroller.clientHeight;
      gutter.style.height = (hText - hEditor < 2 ? hEditor : hText) + "px";
      var html = [], i = showingFrom;
      doc.iter(showingFrom, Math.max(showingTo, showingFrom + 1), function(line) {
        if (line.hidden) {
          html.push("<pre></pre>");
        } else {
          var marker = line.gutterMarker;
          var text = options.lineNumbers ? i + options.firstLineNumber : null;
          if (marker && marker.text)
            text = marker.text.replace("%N%", text != null ? text : "");
          else if (text == null)
            text = "\u00a0";
          html.push((marker && marker.style ? '<pre class="' + marker.style + '">' : "<pre>"), text);
          for (var j = 1; j < line.height; ++j) html.push("<br/>&#160;");
          html.push("</pre>");
        }
        ++i;
      });
      gutter.style.display = "none";
      gutterText.innerHTML = html.join("");
      var minwidth = String(doc.size).length, firstNode = gutterText.firstChild, val = eltText(firstNode), pad = "";
      while (val.length + pad.length < minwidth) pad += "\u00a0";
      if (pad) firstNode.insertBefore(targetDocument.createTextNode(pad), firstNode.firstChild);
      gutter.style.display = "";
      lineSpace.style.marginLeft = gutter.offsetWidth + "px";
      gutterDirty = false;
    }
    function updateCursor() {
      var head = sel.inverted ? sel.from : sel.to, lh = textHeight();
      var pos = localCoords(head, true);
      var wrapOff = eltOffset(wrapper), lineOff = eltOffset(lineDiv);
      inputDiv.style.top = (pos.y + lineOff.top - wrapOff.top) + "px";
      inputDiv.style.left = (pos.x + lineOff.left - wrapOff.left) + "px";
      if (posEq(sel.from, sel.to)) {
        cursor.style.top = pos.y + "px";
        cursor.style.left = (options.lineWrapping ? Math.min(pos.x, lineSpace.offsetWidth) : pos.x) + "px";
        cursor.style.display = "";
      }
      else cursor.style.display = "none";
    }

    function setShift(val) {
      if (val) shiftSelecting = shiftSelecting || (sel.inverted ? sel.to : sel.from);
      else shiftSelecting = null;
    }
    function setSelectionUser(from, to) {
      var sh = shiftSelecting && clipPos(shiftSelecting);
      if (sh) {
        if (posLess(sh, from)) from = sh;
        else if (posLess(to, sh)) to = sh;
      }
      setSelection(from, to);
      userSelChange = true;
    }
    // Update the selection. Last two args are only used by
    // updateLines, since they have to be expressed in the line
    // numbers before the update.
    function setSelection(from, to, oldFrom, oldTo) {
      goalColumn = null;
      if (oldFrom == null) {oldFrom = sel.from.line; oldTo = sel.to.line;}
      if (posEq(sel.from, from) && posEq(sel.to, to)) return;
      if (posLess(to, from)) {var tmp = to; to = from; from = tmp;}

      // Skip over hidden lines.
      if (from.line != oldFrom) from = skipHidden(from, oldFrom, sel.from.ch);
      if (to.line != oldTo) to = skipHidden(to, oldTo, sel.to.ch);

      if (posEq(from, to)) sel.inverted = false;
      else if (posEq(from, sel.to)) sel.inverted = false;
      else if (posEq(to, sel.from)) sel.inverted = true;

      // Some ugly logic used to only mark the lines that actually did
      // see a change in selection as changed, rather than the whole
      // selected range.
      if (posEq(from, to)) {
        if (!posEq(sel.from, sel.to))
          changes.push({from: oldFrom, to: oldTo + 1});
      }
      else if (posEq(sel.from, sel.to)) {
        changes.push({from: from.line, to: to.line + 1});
      }
      else {
        if (!posEq(from, sel.from)) {
          if (from.line < oldFrom)
            changes.push({from: from.line, to: Math.min(to.line, oldFrom) + 1});
          else
            changes.push({from: oldFrom, to: Math.min(oldTo, from.line) + 1});
        }
        if (!posEq(to, sel.to)) {
          if (to.line < oldTo)
            changes.push({from: Math.max(oldFrom, from.line), to: oldTo + 1});
          else
            changes.push({from: Math.max(from.line, oldTo), to: to.line + 1});
        }
      }
      sel.from = from; sel.to = to;
      selectionChanged = true;
    }
    function skipHidden(pos, oldLine, oldCh) {
      function getNonHidden(dir) {
        var lNo = pos.line + dir, end = dir == 1 ? doc.size : -1;
        while (lNo != end) {
          var line = getLine(lNo);
          if (!line.hidden) {
            var ch = pos.ch;
            if (ch > oldCh || ch > line.text.length) ch = line.text.length;
            return {line: lNo, ch: ch};
          }
          lNo += dir;
        }
      }
      var line = getLine(pos.line);
      if (!line.hidden) return pos;
      if (pos.line >= oldLine) return getNonHidden(1) || getNonHidden(-1);
      else return getNonHidden(-1) || getNonHidden(1);
    }
    function setCursor(line, ch, user) {
      var pos = clipPos({line: line, ch: ch || 0});
      (user ? setSelectionUser : setSelection)(pos, pos);
    }

    function clipLine(n) {return Math.max(0, Math.min(n, doc.size-1));}
    function clipPos(pos) {
      if (pos.line < 0) return {line: 0, ch: 0};
      if (pos.line >= doc.size) return {line: doc.size-1, ch: getLine(doc.size-1).text.length};
      var ch = pos.ch, linelen = getLine(pos.line).text.length;
      if (ch == null || ch > linelen) return {line: pos.line, ch: linelen};
      else if (ch < 0) return {line: pos.line, ch: 0};
      else return pos;
    }

    function findPosH(dir, unit) {
      var end = sel.inverted ? sel.from : sel.to, line = end.line, ch = end.ch;
      var lineObj = getLine(line);
      function findNextLine() {
        for (var l = line + dir, e = dir < 0 ? -1 : doc.size; l != e; l += dir) {
          var lo = getLine(l);
          if (!lo.hidden) { line = l; lineObj = lo; return true; }
        }
      }
      function moveOnce(boundToLine) {
        if (ch == (dir < 0 ? 0 : lineObj.text.length)) {
          if (!boundToLine && findNextLine()) ch = dir < 0 ? lineObj.text.length : 0;
          else return false;
        } else ch += dir;
        return true;
      }
      if (unit == "char") moveOnce();
      else if (unit == "column") moveOnce(true);
      else if (unit == "word") {
        var sawWord = false;
        for (;;) {
          if (dir < 0) if (!moveOnce()) break;
          if (isWordChar(lineObj.text.charAt(ch))) sawWord = true;
          else if (sawWord) {if (dir < 0) {dir = 1; moveOnce();} break;}
          if (dir > 0) if (!moveOnce()) break;
        }
      }
      return {line: line, ch: ch};
    }
    function moveH(dir, unit) {
      var pos = dir < 0 ? sel.from : sel.to;
      if (shiftSelecting || posEq(sel.from, sel.to)) pos = findPosH(dir, unit);
      setCursor(pos.line, pos.ch, true);
    }
    function deleteH(dir, unit) {
      if (!posEq(sel.from, sel.to)) replaceRange("", sel.from, sel.to);
      else if (dir < 0) replaceRange("", findPosH(dir, unit), sel.to);
      else replaceRange("", sel.from, findPosH(dir, unit));
      userSelChange = true;
    }
    var goalColumn = null;
    function moveV(dir, unit) {
      var dist = 0, pos = localCoords(sel.inverted ? sel.from : sel.to, true);
      if (goalColumn != null) pos.x = goalColumn;
      if (unit == "page") dist = scroller.clientHeight;
      else if (unit == "line") dist = textHeight();
      var target = coordsChar(pos.x, pos.y + dist * dir + 2);
      setCursor(target.line, target.ch, true);
      goalColumn = pos.x;
    }

    function selectWordAt(pos) {
      var line = getLine(pos.line).text;
      var start = pos.ch, end = pos.ch;
      while (start > 0 && isWordChar(line.charAt(start - 1))) --start;
      while (end < line.length && isWordChar(line.charAt(end))) ++end;
      setSelectionUser({line: pos.line, ch: start}, {line: pos.line, ch: end});
    }
    function selectLine(line) {
      setSelectionUser({line: line, ch: 0}, {line: line, ch: getLine(line).text.length});
    }
    function indentSelected(mode) {
      if (posEq(sel.from, sel.to)) return indentLine(sel.from.line, mode);
      var e = sel.to.line - (sel.to.ch ? 0 : 1);
      for (var i = sel.from.line; i <= e; ++i) indentLine(i, mode);
    }

    function indentLine(n, how) {
      if (!how) how = "add";
      if (how == "smart") {
        if (!mode.indent) how = "prev";
        else var state = getStateBefore(n);
      }

      var line = getLine(n), curSpace = line.indentation(options.tabSize),
          curSpaceString = line.text.match(/^\s*/)[0], indentation;
      if (how == "prev") {
        if (n) indentation = getLine(n-1).indentation(options.tabSize);
        else indentation = 0;
      }
      else if (how == "smart") indentation = mode.indent(state, line.text.slice(curSpaceString.length), line.text);
      else if (how == "add") indentation = curSpace + options.indentUnit;
      else if (how == "subtract") indentation = curSpace - options.indentUnit;
      indentation = Math.max(0, indentation);
      var diff = indentation - curSpace;

      if (!diff) {
        if (sel.from.line != n && sel.to.line != n) return;
        var indentString = curSpaceString;
      }
      else {
        var indentString = "", pos = 0;
        if (options.indentWithTabs)
          for (var i = Math.floor(indentation / options.tabSize); i; --i) {pos += options.tabSize; indentString += "\t";}
        while (pos < indentation) {++pos; indentString += " ";}
      }

      replaceRange(indentString, {line: n, ch: 0}, {line: n, ch: curSpaceString.length});
    }

    function loadMode() {
      mode = CodeMirror.getMode(options, options.mode);
      doc.iter(0, doc.size, function(line) { line.stateAfter = null; });
      work = [0];
      startWorker();
    }
    function gutterChanged() {
      var visible = options.gutter || options.lineNumbers;
      gutter.style.display = visible ? "" : "none";
      if (visible) gutterDirty = true;
      else lineDiv.parentNode.style.marginLeft = 0;
    }
    function wrappingChanged(from, to) {
      if (options.lineWrapping) {
        wrapper.className += " CodeMirror-wrap";
        var perLine = scroller.clientWidth / charWidth() - 3;
        doc.iter(0, doc.size, function(line) {
          if (line.hidden) return;
          var guess = Math.ceil(line.text.length / perLine) || 1;
          if (guess != 1) updateLineHeight(line, guess);
        });
        lineSpace.style.width = code.style.width = "";
      } else {
        wrapper.className = wrapper.className.replace(" CodeMirror-wrap", "");
        maxWidth = null; maxLine = "";
        doc.iter(0, doc.size, function(line) {
          if (line.height != 1 && !line.hidden) updateLineHeight(line, 1);
          if (line.text.length > maxLine.length) maxLine = line.text;
        });
      }
      changes.push({from: 0, to: doc.size});
    }
    function computeTabText() {
      for (var str = '<span class="cm-tab">', i = 0; i < options.tabSize; ++i) str += " ";
      return str + "</span>";
    }
    function tabsChanged() {
      tabText = computeTabText();
      updateDisplay(true);
    }
    function themeChanged() {
      scroller.className = scroller.className.replace(/\s*cm-s-\w+/g, "") +
        options.theme.replace(/(^|\s)\s*/g, " cm-s-");
    }

    function TextMarker() { this.set = []; }
    TextMarker.prototype.clear = operation(function() {
      var min = Infinity, max = -Infinity;
      for (var i = 0, e = this.set.length; i < e; ++i) {
        var line = this.set[i], mk = line.marked;
        if (!mk || !line.parent) continue;
        var lineN = lineNo(line);
        min = Math.min(min, lineN); max = Math.max(max, lineN);
        for (var j = 0; j < mk.length; ++j)
          if (mk[j].set == this.set) mk.splice(j--, 1);
      }
      if (min != Infinity)
        changes.push({from: min, to: max + 1});
    });
    TextMarker.prototype.find = function() {
      var from, to;
      for (var i = 0, e = this.set.length; i < e; ++i) {
        var line = this.set[i], mk = line.marked;
        for (var j = 0; j < mk.length; ++j) {
          var mark = mk[j];
          if (mark.set == this.set) {
            if (mark.from != null || mark.to != null) {
              var found = lineNo(line);
              if (found != null) {
                if (mark.from != null) from = {line: found, ch: mark.from};
                if (mark.to != null) to = {line: found, ch: mark.to};
              }
            }
          }
        }
      }
      return {from: from, to: to};
    };

    function markText(from, to, className) {
      from = clipPos(from); to = clipPos(to);
      var tm = new TextMarker();
      function add(line, from, to, className) {
        getLine(line).addMark(new MarkedText(from, to, className, tm.set));
      }
      if (from.line == to.line) add(from.line, from.ch, to.ch, className);
      else {
        add(from.line, from.ch, null, className);
        for (var i = from.line + 1, e = to.line; i < e; ++i)
          add(i, null, null, className);
        add(to.line, null, to.ch, className);
      }
      changes.push({from: from.line, to: to.line + 1});
      return tm;
    }

    function setBookmark(pos) {
      pos = clipPos(pos);
      var bm = new Bookmark(pos.ch);
      getLine(pos.line).addMark(bm);
      return bm;
    }

    function addGutterMarker(line, text, className) {
      if (typeof line == "number") line = getLine(clipLine(line));
      line.gutterMarker = {text: text, style: className};
      gutterDirty = true;
      return line;
    }
    function removeGutterMarker(line) {
      if (typeof line == "number") line = getLine(clipLine(line));
      line.gutterMarker = null;
      gutterDirty = true;
    }

    function changeLine(handle, op) {
      var no = handle, line = handle;
      if (typeof handle == "number") line = getLine(clipLine(handle));
      else no = lineNo(handle);
      if (no == null) return null;
      if (op(line, no)) changes.push({from: no, to: no + 1});
      else return null;
      return line;
    }
    function setLineClass(handle, className) {
      return changeLine(handle, function(line) {
        if (line.className != className) {
          line.className = className;
          return true;
        }
      });
    }
    function setLineHidden(handle, hidden) {
      return changeLine(handle, function(line, no) {
        if (line.hidden != hidden) {
          line.hidden = hidden;
          updateLineHeight(line, hidden ? 0 : 1);
          if (hidden && (sel.from.line == no || sel.to.line == no))
            setSelection(skipHidden(sel.from, sel.from.line, sel.from.ch),
                         skipHidden(sel.to, sel.to.line, sel.to.ch));
          return (gutterDirty = true);
        }
      });
    }

    function lineInfo(line) {
      if (typeof line == "number") {
        if (!isLine(line)) return null;
        var n = line;
        line = getLine(line);
        if (!line) return null;
      }
      else {
        var n = lineNo(line);
        if (n == null) return null;
      }
      var marker = line.gutterMarker;
      return {line: n, handle: line, text: line.text, markerText: marker && marker.text,
              markerClass: marker && marker.style, lineClass: line.className};
    }

    function stringWidth(str) {
      measure.innerHTML = "<pre><span>x</span></pre>";
      measure.firstChild.firstChild.firstChild.nodeValue = str;
      return measure.firstChild.firstChild.offsetWidth || 10;
    }
    // These are used to go from pixel positions to character
    // positions, taking varying character widths into account.
    function charFromX(line, x) {
      if (x <= 0) return 0;
      var lineObj = getLine(line), text = lineObj.text;
      function getX(len) {
        measure.innerHTML = "<pre><span>" + lineObj.getHTML(null, null, false, tabText, len) + "</span></pre>";
        return measure.firstChild.firstChild.offsetWidth;
      }
      var from = 0, fromX = 0, to = text.length, toX;
      // Guess a suitable upper bound for our search.
      var estimated = Math.min(to, Math.ceil(x / charWidth()));
      for (;;) {
        var estX = getX(estimated);
        if (estX <= x && estimated < to) estimated = Math.min(to, Math.ceil(estimated * 1.2));
        else {toX = estX; to = estimated; break;}
      }
      if (x > toX) return to;
      // Try to guess a suitable lower bound as well.
      estimated = Math.floor(to * 0.8); estX = getX(estimated);
      if (estX < x) {from = estimated; fromX = estX;}
      // Do a binary search between these bounds.
      for (;;) {
        if (to - from <= 1) return (toX - x > x - fromX) ? from : to;
        var middle = Math.ceil((from + to) / 2), middleX = getX(middle);
        if (middleX > x) {to = middle; toX = middleX;}
        else {from = middle; fromX = middleX;}
      }
    }

    var tempId = Math.floor(Math.random() * 0xffffff).toString(16);
    function measureLine(line, ch) {
      var extra = "";
      // Include extra text at the end to make sure the measured line is wrapped in the right way.
      if (options.lineWrapping) {
        var end = line.text.indexOf(" ", ch + 2);
        extra = htmlEscape(line.text.slice(ch + 1, end < 0 ? line.text.length : end + (ie ? 5 : 0)));
      }
      measure.innerHTML = "<pre>" + line.getHTML(null, null, false, tabText, ch) +
        '<span id="CodeMirror-temp-' + tempId + '">' + htmlEscape(line.text.charAt(ch) || " ") + "</span>" +
        extra + "</pre>";
      var elt = document.getElementById("CodeMirror-temp-" + tempId);
      var top = elt.offsetTop, left = elt.offsetLeft;
      // Older IEs report zero offsets for spans directly after a wrap
      if (ie && ch && top == 0 && left == 0) {
        var backup = document.createElement("span");
        backup.innerHTML = "x";
        elt.parentNode.insertBefore(backup, elt.nextSibling);
        top = backup.offsetTop;
      }
      return {top: top, left: left};
    }
    function localCoords(pos, inLineWrap) {
      var x, lh = textHeight(), y = lh * (heightAtLine(doc, pos.line) - (inLineWrap ? displayOffset : 0));
      if (pos.ch == 0) x = 0;
      else {
        var sp = measureLine(getLine(pos.line), pos.ch);
        x = sp.left;
        if (options.lineWrapping) y += Math.max(0, sp.top);
      }
      return {x: x, y: y, yBot: y + lh};
    }
    // Coords must be lineSpace-local
    function coordsChar(x, y) {
      if (y < 0) y = 0;
      var th = textHeight(), cw = charWidth(), heightPos = displayOffset + Math.floor(y / th);
      var lineNo = lineAtHeight(doc, heightPos);
      if (lineNo >= doc.size) return {line: doc.size - 1, ch: getLine(doc.size - 1).text.length};
      var lineObj = getLine(lineNo), text = lineObj.text;
      var tw = options.lineWrapping, innerOff = tw ? heightPos - heightAtLine(doc, lineNo) : 0;
      if (x <= 0 && innerOff == 0) return {line: lineNo, ch: 0};
      function getX(len) {
        var sp = measureLine(lineObj, len);
        if (tw) {
          var off = Math.round(sp.top / th);
          return Math.max(0, sp.left + (off - innerOff) * scroller.clientWidth);
        }
        return sp.left;
      }
      var from = 0, fromX = 0, to = text.length, toX;
      // Guess a suitable upper bound for our search.
      var estimated = Math.min(to, Math.ceil((x + innerOff * scroller.clientWidth * .9) / cw));
      for (;;) {
        var estX = getX(estimated);
        if (estX <= x && estimated < to) estimated = Math.min(to, Math.ceil(estimated * 1.2));
        else {toX = estX; to = estimated; break;}
      }
      if (x > toX) return {line: lineNo, ch: to};
      // Try to guess a suitable lower bound as well.
      estimated = Math.floor(to * 0.8); estX = getX(estimated);
      if (estX < x) {from = estimated; fromX = estX;}
      // Do a binary search between these bounds.
      for (;;) {
        if (to - from <= 1) return {line: lineNo, ch: (toX - x > x - fromX) ? from : to};
        var middle = Math.ceil((from + to) / 2), middleX = getX(middle);
        if (middleX > x) {to = middle; toX = middleX;}
        else {from = middle; fromX = middleX;}
      }
    }
    function pageCoords(pos) {
      var local = localCoords(pos, true), off = eltOffset(lineSpace);
      return {x: off.left + local.x, y: off.top + local.y, yBot: off.top + local.yBot};
    }

    var cachedHeight, cachedHeightFor, measureText;
    function textHeight() {
      if (measureText == null) {
        measureText = "<pre>";
        for (var i = 0; i < 49; ++i) measureText += "x<br/>";
        measureText += "x</pre>";
      }
      var offsetHeight = lineDiv.clientHeight;
      if (offsetHeight == cachedHeightFor) return cachedHeight;
      cachedHeightFor = offsetHeight;
      measure.innerHTML = measureText;
      cachedHeight = measure.firstChild.offsetHeight / 50 || 1;
      measure.innerHTML = "";
      return cachedHeight;
    }
    var cachedWidth, cachedWidthFor = 0;
    function charWidth() {
      if (scroller.clientWidth == cachedWidthFor) return cachedWidth;
      cachedWidthFor = scroller.clientWidth;
      return (cachedWidth = stringWidth("x"));
    }
    function paddingTop() {return lineSpace.offsetTop;}
    function paddingLeft() {return lineSpace.offsetLeft;}

    function posFromMouse(e, liberal) {
      var offW = eltOffset(scroller, true), x, y;
      // Fails unpredictably on IE[67] when mouse is dragged around quickly.
      try { x = e.clientX; y = e.clientY; } catch (e) { return null; }
      // This is a mess of a heuristic to try and determine whether a
      // scroll-bar was clicked or not, and to return null if one was
      // (and !liberal).
      if (!liberal && (x - offW.left > scroller.clientWidth || y - offW.top > scroller.clientHeight))
        return null;
      var offL = eltOffset(lineSpace, true);
      return coordsChar(x - offL.left, y - offL.top);
    }
    function onContextMenu(e) {
      var pos = posFromMouse(e);
      if (!pos || window.opera) return; // Opera is difficult.
      if (posEq(sel.from, sel.to) || posLess(pos, sel.from) || !posLess(pos, sel.to))
        operation(setCursor)(pos.line, pos.ch);

      var oldCSS = input.style.cssText;
      inputDiv.style.position = "absolute";
      input.style.cssText = "position: fixed; width: 30px; height: 30px; top: " + (e.clientY - 5) +
        "px; left: " + (e.clientX - 5) + "px; z-index: 1000; background: white; " +
        "border-width: 0; outline: none; overflow: hidden; opacity: .05; filter: alpha(opacity=5);";
      leaveInputAlone = true;
      var val = input.value = getSelection();
      focusInput();
      input.select();
      function rehide() {
        var newVal = splitLines(input.value).join("\n");
        if (newVal != val) operation(replaceSelection)(newVal, "end");
        inputDiv.style.position = "relative";
        input.style.cssText = oldCSS;
        leaveInputAlone = false;
        resetInput(true);
        slowPoll();
      }

      if (gecko) {
        e_stop(e);
        var mouseup = connect(window, "mouseup", function() {
          mouseup();
          setTimeout(rehide, 20);
        }, true);
      }
      else {
        setTimeout(rehide, 50);
      }
    }

    // Cursor-blinking
    function restartBlink() {
      clearInterval(blinker);
      var on = true;
      cursor.style.visibility = "";
      blinker = setInterval(function() {
        cursor.style.visibility = (on = !on) ? "" : "hidden";
      }, 650);
    }

    var matching = {"(": ")>", ")": "(<", "[": "]>", "]": "[<", "{": "}>", "}": "{<"};
    function matchBrackets(autoclear) {
      var head = sel.inverted ? sel.from : sel.to, line = getLine(head.line), pos = head.ch - 1;
      var match = (pos >= 0 && matching[line.text.charAt(pos)]) || matching[line.text.charAt(++pos)];
      if (!match) return;
      var ch = match.charAt(0), forward = match.charAt(1) == ">", d = forward ? 1 : -1, st = line.styles;
      for (var off = pos + 1, i = 0, e = st.length; i < e; i+=2)
        if ((off -= st[i].length) <= 0) {var style = st[i+1]; break;}

      var stack = [line.text.charAt(pos)], re = /[(){}[\]].."]]"..[[/;
      function scan(line, from, to) {
        if (!line.text) return;
        var st = line.styles, pos = forward ? 0 : line.text.length - 1, cur;
        for (var i = forward ? 0 : st.length - 2, e = forward ? st.length : -2; i != e; i += 2*d) {
          var text = st[i];
          if (st[i+1] != null && st[i+1] != style) {pos += d * text.length; continue;}
          for (var j = forward ? 0 : text.length - 1, te = forward ? text.length : -1; j != te; j += d, pos+=d) {
            if (pos >= from && pos < to && re.test(cur = text.charAt(j))) {
              var match = matching[cur];
              if (match.charAt(1) == ">" == forward) stack.push(cur);
              else if (stack.pop() != match.charAt(0)) return {pos: pos, match: false};
              else if (!stack.length) return {pos: pos, match: true};
            }
          }
        }
      }
      for (var i = head.line, e = forward ? Math.min(i + 100, doc.size) : Math.max(-1, i - 100); i != e; i+=d) {
        var line = getLine(i), first = i == head.line;
        var found = scan(line, first && forward ? pos + 1 : 0, first && !forward ? pos : line.text.length);
        if (found) break;
      }
      if (!found) found = {pos: null, match: false};
      var style = found.match ? "CodeMirror-matchingbracket" : "CodeMirror-nonmatchingbracket";
      var one = markText({line: head.line, ch: pos}, {line: head.line, ch: pos+1}, style),
          two = found.pos != null && markText({line: i, ch: found.pos}, {line: i, ch: found.pos + 1}, style);
      var clear = operation(function(){one.clear(); two && two.clear();});
      if (autoclear) setTimeout(clear, 800);
      else bracketHighlighted = clear;
    }

    // Finds the line to start with when starting a parse. Tries to
    // find a line with a stateAfter, so that it can start with a
    // valid state. If that fails, it returns the line with the
    // smallest indentation, which tends to need the least context to
    // parse correctly.
    function findStartLine(n) {
      var minindent, minline;
      for (var search = n, lim = n - 40; search > lim; --search) {
        if (search == 0) return 0;
        var line = getLine(search-1);
        if (line.stateAfter) return search;
        var indented = line.indentation(options.tabSize);
        if (minline == null || minindent > indented) {
          minline = search - 1;
          minindent = indented;
        }
      }
      return minline;
    }
    function getStateBefore(n) {
      var start = findStartLine(n), state = start && getLine(start-1).stateAfter;
      if (!state) state = startState(mode);
      else state = copyState(mode, state);
      doc.iter(start, n, function(line) {
        line.highlight(mode, state, options.tabSize);
        line.stateAfter = copyState(mode, state);
      });
      if (start < n) changes.push({from: start, to: n});
      if (n < doc.size && !getLine(n).stateAfter) work.push(n);
      return state;
    }
    function highlightLines(start, end) {
      var state = getStateBefore(start);
      doc.iter(start, end, function(line) {
        line.highlight(mode, state, options.tabSize);
        line.stateAfter = copyState(mode, state);
      });
    }
    function highlightWorker() {
      var end = +new Date + options.workTime;
      var foundWork = work.length;
      while (work.length) {
        if (!getLine(showingFrom).stateAfter) var task = showingFrom;
        else var task = work.pop();
        if (task >= doc.size) continue;
        var start = findStartLine(task), state = start && getLine(start-1).stateAfter;
        if (state) state = copyState(mode, state);
        else state = startState(mode);

        var unchanged = 0, compare = mode.compareStates, realChange = false,
            i = start, bail = false;
        doc.iter(i, doc.size, function(line) {
          var hadState = line.stateAfter;
          if (+new Date > end) {
            work.push(i);
            startWorker(options.workDelay);
            if (realChange) changes.push({from: task, to: i + 1});
            return (bail = true);
          }
          var changed = line.highlight(mode, state, options.tabSize);
          if (changed) realChange = true;
          line.stateAfter = copyState(mode, state);
          if (compare) {
            if (hadState && compare(hadState, state)) return true;
          } else {
            if (changed !== false || !hadState) unchanged = 0;
            else if (++unchanged > 3 && (!mode.indent || mode.indent(hadState, "") == mode.indent(state, "")))
              return true;
          }
          ++i;
        });
        if (bail) return;
        if (realChange) changes.push({from: task, to: i + 1});
      }
      if (foundWork && options.onHighlightComplete)
        options.onHighlightComplete(instance);
    }
    function startWorker(time) {
      if (!work.length) return;
      highlight.set(time, operation(highlightWorker));
    }

    // Operations are used to wrap changes in such a way that each
    // change won't have to update the cursor and display (which would
    // be awkward, slow, and error-prone), but instead updates are
    // batched and then all combined and executed at once.
    function startOperation() {
      updateInput = userSelChange = textChanged = null;
      changes = []; selectionChanged = false; callbacks = [];
    }
    function endOperation() {
      var reScroll = false, updated;
      if (selectionChanged) reScroll = !scrollCursorIntoView();
      if (changes.length) updated = updateDisplay(changes, true);
      else {
        if (selectionChanged) updateCursor();
        if (gutterDirty) updateGutter();
      }
      if (reScroll) scrollCursorIntoView();
      if (selectionChanged) {scrollEditorIntoView(); restartBlink();}

      if (focused && !leaveInputAlone &&
          (updateInput === true || (updateInput !== false && selectionChanged)))
        resetInput(userSelChange);

      if (selectionChanged && options.matchBrackets)
        setTimeout(operation(function() {
          if (bracketHighlighted) {bracketHighlighted(); bracketHighlighted = null;}
          if (posEq(sel.from, sel.to)) matchBrackets(false);
        }), 20);
      var tc = textChanged, cbs = callbacks; // these can be reset by callbacks
      if (selectionChanged && options.onCursorActivity)
        options.onCursorActivity(instance);
      if (tc && options.onChange && instance)
        options.onChange(instance, tc);
      for (var i = 0; i < cbs.length; ++i) cbs[i](instance);
      if (updated && options.onUpdate) options.onUpdate(instance);
    }
    var nestedOperation = 0;
    function operation(f) {
      return function() {
        if (!nestedOperation++) startOperation();
        try {var result = f.apply(this, arguments);}
        finally {if (!--nestedOperation) endOperation();}
        return result;
      };
    }

    for (var ext in extensions)
      if (extensions.propertyIsEnumerable(ext) &&
          !instance.propertyIsEnumerable(ext))
        instance[ext] = extensions[ext];
    return instance;
  } // (end of function CodeMirror)

  // The default configuration options.
  CodeMirror.defaults = {
    value: "",
    mode: null,
    theme: "default",
    indentUnit: 2,
    indentWithTabs: false,
    tabSize: 4,
    keyMap: "default",
    extraKeys: null,
    electricChars: true,
    onKeyEvent: null,
    lineWrapping: false,
    lineNumbers: false,
    gutter: false,
    fixedGutter: false,
    firstLineNumber: 1,
    readOnly: false,
    onChange: null,
    onCursorActivity: null,
    onGutterClick: null,
    onHighlightComplete: null,
    onUpdate: null,
    onFocus: null, onBlur: null, onScroll: null,
    matchBrackets: false,
    workTime: 100,
    workDelay: 200,
    pollInterval: 100,
    undoDepth: 40,
    tabindex: null,
    document: window.document
  };

  var mac = /Mac/.test(navigator.platform);
  var win = /Win/.test(navigator.platform);

  // Known modes, by name and by MIME
  var modes = {}, mimeModes = {};
  CodeMirror.defineMode = function(name, mode) {
    if (!CodeMirror.defaults.mode && name != "null") CodeMirror.defaults.mode = name;
    modes[name] = mode;
  };
  CodeMirror.defineMIME = function(mime, spec) {
    mimeModes[mime] = spec;
  };
  CodeMirror.getMode = function(options, spec) {
    if (typeof spec == "string" && mimeModes.hasOwnProperty(spec))
      spec = mimeModes[spec];
    if (typeof spec == "string")
      var mname = spec, config = {};
    else if (spec != null)
      var mname = spec.name, config = spec;
    var mfactory = modes[mname];
    if (!mfactory) {
      if (window.console) console.warn("No mode " + mname + " found, falling back to plain text.");
      return CodeMirror.getMode(options, "text/plain");
    }
    return mfactory(options, config || {});
  };
  CodeMirror.listModes = function() {
    var list = [];
    for (var m in modes)
      if (modes.propertyIsEnumerable(m)) list.push(m);
    return list;
  };
  CodeMirror.listMIMEs = function() {
    var list = [];
    for (var m in mimeModes)
      if (mimeModes.propertyIsEnumerable(m)) list.push({mime: m, mode: mimeModes[m]});
    return list;
  };

  var extensions = CodeMirror.extensions = {};
  CodeMirror.defineExtension = function(name, func) {
    extensions[name] = func;
  };

  var commands = CodeMirror.commands = {
    selectAll: function(cm) {cm.setSelection({line: 0, ch: 0}, {line: cm.lineCount() - 1});},
    killLine: function(cm) {
      var from = cm.getCursor(true), to = cm.getCursor(false), sel = !posEq(from, to);
      if (!sel && cm.getLine(from.line).length == from.ch) cm.replaceRange("", from, {line: from.line + 1, ch: 0});
      else cm.replaceRange("", from, sel ? to : {line: from.line});
    },
    deleteLine: function(cm) {var l = cm.getCursor().line; cm.replaceRange("", {line: l, ch: 0}, {line: l});},
    undo: function(cm) {cm.undo();},
    redo: function(cm) {cm.redo();},
    goDocStart: function(cm) {cm.setCursor(0, 0, true);},
    goDocEnd: function(cm) {cm.setSelection({line: cm.lineCount() - 1}, null, true);},
    goLineStart: function(cm) {cm.setCursor(cm.getCursor().line, 0, true);},
    goLineStartSmart: function(cm) {
      var cur = cm.getCursor();
      var text = cm.getLine(cur.line), firstNonWS = Math.max(0, text.search(/\S/));
      cm.setCursor(cur.line, cur.ch <= firstNonWS && cur.ch ? 0 : firstNonWS, true);
    },
    goLineEnd: function(cm) {cm.setSelection({line: cm.getCursor().line}, null, true);},
    goLineUp: function(cm) {cm.moveV(-1, "line");},
    goLineDown: function(cm) {cm.moveV(1, "line");},
    goPageUp: function(cm) {cm.moveV(-1, "page");},
    goPageDown: function(cm) {cm.moveV(1, "page");},
    goCharLeft: function(cm) {cm.moveH(-1, "char");},
    goCharRight: function(cm) {cm.moveH(1, "char");},
    goColumnLeft: function(cm) {cm.moveH(-1, "column");},
    goColumnRight: function(cm) {cm.moveH(1, "column");},
    goWordLeft: function(cm) {cm.moveH(-1, "word");},
    goWordRight: function(cm) {cm.moveH(1, "word");},
    delCharLeft: function(cm) {cm.deleteH(-1, "char");},
    delCharRight: function(cm) {cm.deleteH(1, "char");},
    delWordLeft: function(cm) {cm.deleteH(-1, "word");},
    delWordRight: function(cm) {cm.deleteH(1, "word");},
    indentAuto: function(cm) {cm.indentSelection("smart");},
    indentMore: function(cm) {cm.indentSelection("add");},
    indentLess: function(cm) {cm.indentSelection("subtract");},
    insertTab: function(cm) {cm.replaceSelection("\t", "end");},
    transposeChars: function(cm) {
      var cur = cm.getCursor(), line = cm.getLine(cur.line);
      if (cur.ch > 0 && cur.ch < line.length - 1)
        cm.replaceRange(line.charAt(cur.ch) + line.charAt(cur.ch - 1),
                        {line: cur.line, ch: cur.ch - 1}, {line: cur.line, ch: cur.ch + 1});
    },
    newlineAndIndent: function(cm) {
      cm.replaceSelection("\n", "end");
      cm.indentLine(cm.getCursor().line);
    },
    toggleOverwrite: function(cm) {cm.toggleOverwrite();}
  };

  var keyMap = CodeMirror.keyMap = {};
  keyMap.basic = {
    "Left": "goCharLeft", "Right": "goCharRight", "Up": "goLineUp", "Down": "goLineDown",
    "End": "goLineEnd", "Home": "goLineStartSmart", "PageUp": "goPageUp", "PageDown": "goPageDown",
    "Delete": "delCharRight", "Backspace": "delCharLeft", "Tab": "indentMore", "Shift-Tab": "indentLess",
    "Enter": "newlineAndIndent", "Insert": "toggleOverwrite"
  };
  // Note that the save and find-related commands aren't defined by
  // default. Unknown commands are simply ignored.
  keyMap.pcDefault = {
    "Ctrl-A": "selectAll", "Ctrl-D": "deleteLine", "Ctrl-Z": "undo", "Shift-Ctrl-Z": "redo", "Ctrl-Y": "redo",
    "Ctrl-Home": "goDocStart", "Alt-Up": "goDocStart", "Ctrl-End": "goDocEnd", "Ctrl-Down": "goDocEnd",
    "Ctrl-Left": "goWordLeft", "Ctrl-Right": "goWordRight", "Alt-Left": "goLineStart", "Alt-Right": "goLineEnd",
    "Ctrl-Backspace": "delWordLeft", "Ctrl-Delete": "delWordRight", "Ctrl-S": "save", "Ctrl-F": "find",
    "Ctrl-G": "findNext", "Shift-Ctrl-G": "findPrev", "Shift-Ctrl-F": "replace", "Shift-Ctrl-R": "replaceAll",
    fallthrough: "basic"
  };
  keyMap.macDefault = {
    "Cmd-A": "selectAll", "Cmd-D": "deleteLine", "Cmd-Z": "undo", "Shift-Cmd-Z": "redo", "Cmd-Y": "redo",
    "Cmd-Up": "goDocStart", "Cmd-End": "goDocEnd", "Cmd-Down": "goDocEnd", "Alt-Left": "goWordLeft",
    "Alt-Right": "goWordRight", "Cmd-Left": "goLineStart", "Cmd-Right": "goLineEnd", "Alt-Backspace": "delWordLeft",
    "Ctrl-Alt-Backspace": "delWordRight", "Alt-Delete": "delWordRight", "Cmd-S": "save", "Cmd-F": "find",
    "Cmd-G": "findNext", "Shift-Cmd-G": "findPrev", "Cmd-Alt-F": "replace", "Shift-Cmd-Alt-F": "replaceAll",
    fallthrough: ["basic", "emacsy"]
  };
  keyMap["default"] = mac ? keyMap.macDefault : keyMap.pcDefault;
  keyMap.emacsy = {
    "Ctrl-F": "goCharRight", "Ctrl-B": "goCharLeft", "Ctrl-P": "goLineUp", "Ctrl-N": "goLineDown",
    "Alt-F": "goWordRight", "Alt-B": "goWordLeft", "Ctrl-A": "goLineStart", "Ctrl-E": "goLineEnd",
    "Ctrl-V": "goPageUp", "Shift-Ctrl-V": "goPageDown", "Ctrl-D": "delCharRight", "Ctrl-H": "delCharLeft",
    "Alt-D": "delWordRight", "Alt-Backspace": "delWordLeft", "Ctrl-K": "killLine", "Ctrl-T": "transposeChars"
  };

  function lookupKey(name, extraMap, map) {
    function lookup(name, map, ft) {
      var found = map[name];
      if (found != null) return found;
      if (ft == null) ft = map.fallthrough;
      if (ft == null) return map.catchall;
      if (typeof ft == "string") return lookup(name, keyMap[ft]);
      for (var i = 0, e = ft.length; i < e; ++i) {
        found = lookup(name, keyMap[ft[i]].."]]"..[[);
        if (found != null) return found;
      }
      return null;
    }
    return extraMap ? lookup(name, extraMap, map) : lookup(name, keyMap[map]);
  }
  function isModifierKey(event) {
    var name = keyNames[event.keyCode];
    return name == "Ctrl" || name == "Alt" || name == "Shift" || name == "Mod";
  }

  CodeMirror.fromTextArea = function(textarea, options) {
    if (!options) options = {};
    options.value = textarea.value;
    if (!options.tabindex && textarea.tabindex)
      options.tabindex = textarea.tabindex;

    function save() {textarea.value = instance.getValue();}
    if (textarea.form) {
      // Deplorable hack to make the submit method do the right thing.
      var rmSubmit = connect(textarea.form, "submit", save, true);
      if (typeof textarea.form.submit == "function") {
        var realSubmit = textarea.form.submit;
        function wrappedSubmit() {
          save();
          textarea.form.submit = realSubmit;
          textarea.form.submit();
          textarea.form.submit = wrappedSubmit;
        }
        textarea.form.submit = wrappedSubmit;
      }
    }

    textarea.style.display = "none";
    var instance = CodeMirror(function(node) {
      textarea.parentNode.insertBefore(node, textarea.nextSibling);
    }, options);
    instance.save = save;
    instance.getTextArea = function() { return textarea; };
    instance.toTextArea = function() {
      save();
      textarea.parentNode.removeChild(instance.getWrapperElement());
      textarea.style.display = "";
      if (textarea.form) {
        rmSubmit();
        if (typeof textarea.form.submit == "function")
          textarea.form.submit = realSubmit;
      }
    };
    return instance;
  };

  // Utility functions for working with state. Exported because modes
  // sometimes need to do this.
  function copyState(mode, state) {
    if (state === true) return state;
    if (mode.copyState) return mode.copyState(state);
    var nstate = {};
    for (var n in state) {
      var val = state[n];
      if (val instanceof Array) val = val.concat([]);
      nstate[n] = val;
    }
    return nstate;
  }
  CodeMirror.copyState = copyState;
  function startState(mode, a1, a2) {
    return mode.startState ? mode.startState(a1, a2) : true;
  }
  CodeMirror.startState = startState;

  // The character stream used by a mode's parser.
  function StringStream(string, tabSize) {
    this.pos = this.start = 0;
    this.string = string;
    this.tabSize = tabSize || 8;
  }
  StringStream.prototype = {
    eol: function() {return this.pos >= this.string.length;},
    sol: function() {return this.pos == 0;},
    peek: function() {return this.string.charAt(this.pos);},
    next: function() {
      if (this.pos < this.string.length)
        return this.string.charAt(this.pos++);
    },
    eat: function(match) {
      var ch = this.string.charAt(this.pos);
      if (typeof match == "string") var ok = ch == match;
      else var ok = ch && (match.test ? match.test(ch) : match(ch));
      if (ok) {++this.pos; return ch;}
    },
    eatWhile: function(match) {
      var start = this.pos;
      while (this.eat(match)){}
      return this.pos > start;
    },
    eatSpace: function() {
      var start = this.pos;
      while (/[\s\u00a0]/.test(this.string.charAt(this.pos))) ++this.pos;
      return this.pos > start;
    },
    skipToEnd: function() {this.pos = this.string.length;},
    skipTo: function(ch) {
      var found = this.string.indexOf(ch, this.pos);
      if (found > -1) {this.pos = found; return true;}
    },
    backUp: function(n) {this.pos -= n;},
    column: function() {return countColumn(this.string, this.start, this.tabSize);},
    indentation: function() {return countColumn(this.string, null, this.tabSize);},
    match: function(pattern, consume, caseInsensitive) {
      if (typeof pattern == "string") {
        function cased(str) {return caseInsensitive ? str.toLowerCase() : str;}
        if (cased(this.string).indexOf(cased(pattern), this.pos) == this.pos) {
          if (consume !== false) this.pos += pattern.length;
          return true;
        }
      }
      else {
        var match = this.string.slice(this.pos).match(pattern);
        if (match && consume !== false) this.pos += match[0].length;
        return match;
      }
    },
    current: function(){return this.string.slice(this.start, this.pos);}
  };
  CodeMirror.StringStream = StringStream;

  function MarkedText(from, to, className, set) {
    this.from = from; this.to = to; this.style = className; this.set = set;
  }
  MarkedText.prototype = {
    attach: function(line) { this.set.push(line); },
    detach: function(line) {
      var ix = indexOf(this.set, line);
      if (ix > -1) this.set.splice(ix, 1);
    },
    split: function(pos, lenBefore) {
      if (this.to <= pos && this.to != null) return null;
      var from = this.from < pos || this.from == null ? null : this.from - pos + lenBefore;
      var to = this.to == null ? null : this.to - pos + lenBefore;
      return new MarkedText(from, to, this.style, this.set);
    },
    dup: function() { return new MarkedText(null, null, this.style, this.set); },
    clipTo: function(fromOpen, from, toOpen, to, diff) {
      if (this.from != null && this.from >= from)
        this.from = Math.max(to, this.from) + diff;
      if (this.to != null && this.to > from)
        this.to = to < this.to ? this.to + diff : from;
      if (fromOpen && to > this.from && (to < this.to || this.to == null))
        this.from = null;
      if (toOpen && (from < this.to || this.to == null) && (from > this.from || this.from == null))
        this.to = null;
    },
    isDead: function() { return this.from != null && this.to != null && this.from >= this.to; },
    sameSet: function(x) { return this.set == x.set; }
  };

  function Bookmark(pos) {
    this.from = pos; this.to = pos; this.line = null;
  }
  Bookmark.prototype = {
    attach: function(line) { this.line = line; },
    detach: function(line) { if (this.line == line) this.line = null; },
    split: function(pos, lenBefore) {
      if (pos < this.from) {
        this.from = this.to = (this.from - pos) + lenBefore;
        return this;
      }
    },
    isDead: function() { return this.from > this.to; },
    clipTo: function(fromOpen, from, toOpen, to, diff) {
      if ((fromOpen || from < this.from) && (toOpen || to > this.to)) {
        this.from = 0; this.to = -1;
      } else if (this.from > from) {
        this.from = this.to = Math.max(to, this.from) + diff;
      }
    },
    sameSet: function(x) { return false; },
    find: function() {
      if (!this.line || !this.line.parent) return null;
      return {line: lineNo(this.line), ch: this.from};
    },
    clear: function() {
      if (this.line) {
        var found = indexOf(this.line.marked, this);
        if (found != -1) this.line.marked.splice(found, 1);
        this.line = null;
      }
    }
  };

  // Line objects. These hold state related to a line, including
  // highlighting info (the styles array).
  function Line(text, styles) {
    this.styles = styles || [text, null];
    this.text = text;
    this.height = 1;
    this.marked = this.gutterMarker = this.className = this.handlers = null;
    this.stateAfter = this.parent = this.hidden = null;
  }
  Line.inheritMarks = function(text, orig) {
    var ln = new Line(text), mk = orig && orig.marked;
    if (mk) {
      for (var i = 0; i < mk.length; ++i) {
        if (mk[i].to == null && mk[i].style) {
          var newmk = ln.marked || (ln.marked = []), mark = mk[i];
          var nmark = mark.dup(); newmk.push(nmark); nmark.attach(ln);
        }
      }
    }
    return ln;
  }
  Line.prototype = {
    // Replace a piece of a line, keeping the styles around it intact.
    replace: function(from, to_, text) {
      var st = [], mk = this.marked, to = to_ == null ? this.text.length : to_;
      copyStyles(0, from, this.styles, st);
      if (text) st.push(text, null);
      copyStyles(to, this.text.length, this.styles, st);
      this.styles = st;
      this.text = this.text.slice(0, from) + text + this.text.slice(to);
      this.stateAfter = null;
      if (mk) {
        var diff = text.length - (to - from);
        for (var i = 0, mark = mk[i]; i < mk.length; ++i) {
          mark.clipTo(from == null, from || 0, to_ == null, to, diff);
          if (mark.isDead()) {mark.detach(this); mk.splice(i--, 1);}
        }
      }
    },
    // Split a part off a line, keeping styles and markers intact.
    split: function(pos, textBefore) {
      var st = [textBefore, null], mk = this.marked;
      copyStyles(pos, this.text.length, this.styles, st);
      var taken = new Line(textBefore + this.text.slice(pos), st);
      if (mk) {
        for (var i = 0; i < mk.length; ++i) {
          var mark = mk[i];
          var newmark = mark.split(pos, textBefore.length);
          if (newmark) {
            if (!taken.marked) taken.marked = [];
            taken.marked.push(newmark); newmark.attach(taken);
          }
        }
      }
      return taken;
    },
    append: function(line) {
      var mylen = this.text.length, mk = line.marked, mymk = this.marked;
      this.text += line.text;
      copyStyles(0, line.text.length, line.styles, this.styles);
      if (mymk) {
        for (var i = 0; i < mymk.length; ++i)
          if (mymk[i].to == null) mymk[i].to = mylen;
      }
      if (mk && mk.length) {
        if (!mymk) this.marked = mymk = [];
        outer: for (var i = 0; i < mk.length; ++i) {
          var mark = mk[i];
          if (!mark.from) {
            for (var j = 0; j < mymk.length; ++j) {
              var mymark = mymk[j];
              if (mymark.to == mylen && mymark.sameSet(mark)) {
                mymark.to = mark.to == null ? null : mark.to + mylen;
                if (mymark.isDead()) {
                  mymark.detach(this);
                  mk.splice(i--, 1);
                }
                continue outer;
              }
            }
          }
          mymk.push(mark);
          mark.attach(this);
          mark.from += mylen;
          if (mark.to != null) mark.to += mylen;
        }
      }
    },
    fixMarkEnds: function(other) {
      var mk = this.marked, omk = other.marked;
      if (!mk) return;
      for (var i = 0; i < mk.length; ++i) {
        var mark = mk[i], close = mark.to == null;
        if (close && omk) {
          for (var j = 0; j < omk.length; ++j)
            if (omk[j].sameSet(mark)) {close = false; break;}
        }
        if (close) mark.to = this.text.length;
      }
    },
    fixMarkStarts: function() {
      var mk = this.marked;
      if (!mk) return;
      for (var i = 0; i < mk.length; ++i)
        if (mk[i].from == null) mk[i].from = 0;
    },
    addMark: function(mark) {
      mark.attach(this);
      if (this.marked == null) this.marked = [];
      this.marked.push(mark);
      this.marked.sort(function(a, b){return (a.from || 0) - (b.from || 0);});
    },
    // Run the given mode's parser over a line, update the styles
    // array, which contains alternating fragments of text and CSS
    // classes.
    highlight: function(mode, state, tabSize) {
      var stream = new StringStream(this.text, tabSize), st = this.styles, pos = 0;
      var changed = false, curWord = st[0], prevWord;
      if (this.text == "" && mode.blankLine) mode.blankLine(state);
      while (!stream.eol()) {
        var style = mode.token(stream, state);
        var substr = this.text.slice(stream.start, stream.pos);
        stream.start = stream.pos;
        if (pos && st[pos-1] == style)
          st[pos-2] += substr;
        else if (substr) {
          if (!changed && (st[pos+1] != style || (pos && st[pos-2] != prevWord))) changed = true;
          st[pos++] = substr; st[pos++] = style;
          prevWord = curWord; curWord = st[pos];
        }
        // Give up when line is ridiculously long
        if (stream.pos > 5000) {
          st[pos++] = this.text.slice(stream.pos); st[pos++] = null;
          break;
        }
      }
      if (st.length != pos) {st.length = pos; changed = true;}
      if (pos && st[pos-2] != prevWord) changed = true;
      // Short lines with simple highlights return null, and are
      // counted as changed by the driver because they are likely to
      // highlight the same way in various contexts.
      return changed || (st.length < 5 && this.text.length < 10 ? null : false);
    },
    // Fetch the parser token for a given character. Useful for hacks
    // that want to inspect the mode state (say, for completion).
    getTokenAt: function(mode, state, ch) {
      var txt = this.text, stream = new StringStream(txt);
      while (stream.pos < ch && !stream.eol()) {
        stream.start = stream.pos;
        var style = mode.token(stream, state);
      }
      return {start: stream.start,
              end: stream.pos,
              string: stream.current(),
              className: style || null,
              state: state};
    },
    indentation: function(tabSize) {return countColumn(this.text, null, tabSize);},
    // Produces an HTML fragment for the line, taking selection,
    // marking, and highlighting into account.
    getHTML: function(sfrom, sto, includePre, tabText, endAt) {
      var html = [], first = true;
      if (includePre)
        html.push(this.className ? '<pre class="' + this.className + '">': "<pre>");
      function span(text, style) {
        if (!text) return;
        // Work around a bug where, in some compat modes, IE ignores leading spaces
        if (first && ie && text.charAt(0) == " ") text = "\u00a0" + text.slice(1);
        first = false;
        if (style) html.push('<span class="', style, '">', htmlEscape(text).replace(/\t/g, tabText), "</span>");
        else html.push(htmlEscape(text).replace(/\t/g, tabText));
      }
      var st = this.styles, allText = this.text, marked = this.marked;
      if (sfrom == sto) sfrom = null;
      var len = allText.length;
      if (endAt != null) len = Math.min(endAt, len);

      if (!allText && endAt == null)
        span(" ", sfrom != null && sto == null ? "CodeMirror-selected" : null);
      else if (!marked && sfrom == null)
        for (var i = 0, ch = 0; ch < len; i+=2) {
          var str = st[i], style = st[i+1], l = str.length;
          if (ch + l > len) str = str.slice(0, len - ch);
          ch += l;
          span(str, style && "cm-" + style);
        }
      else {
        var pos = 0, i = 0, text = "", style, sg = 0;
        var markpos = -1, mark = null;
        function nextMark() {
          if (marked) {
            markpos += 1;
            mark = (markpos < marked.length) ? marked[markpos] : null;
          }
        }
        nextMark();
        while (pos < len) {
          var upto = len;
          var extraStyle = "";
          if (sfrom != null) {
            if (sfrom > pos) upto = sfrom;
            else if (sto == null || sto > pos) {
              extraStyle = " CodeMirror-selected";
              if (sto != null) upto = Math.min(upto, sto);
            }
          }
          while (mark && mark.to != null && mark.to <= pos) nextMark();
          if (mark) {
            if (mark.from > pos) upto = Math.min(upto, mark.from);
            else {
              extraStyle += " " + mark.style;
              if (mark.to != null) upto = Math.min(upto, mark.to);
            }
          }
          for (;;) {
            var end = pos + text.length;
            var appliedStyle = style;
            if (extraStyle) appliedStyle = style ? style + extraStyle : extraStyle;
            span(end > upto ? text.slice(0, upto - pos) : text, appliedStyle);
            if (end >= upto) {text = text.slice(upto - pos); pos = upto; break;}
            pos = end;
            text = st[i++]; style = "cm-" + st[i++];
          }
        }
        if (sfrom != null && sto == null) span(" ", "CodeMirror-selected");
      }
      if (includePre) html.push("</pre>");
      return html.join("");
    },
    cleanUp: function() {
      this.parent = null;
      if (this.marked)
        for (var i = 0, e = this.marked.length; i < e; ++i) this.marked[i].detach(this);
    }
  };
  // Utility used by replace and split above
  function copyStyles(from, to, source, dest) {
    for (var i = 0, pos = 0, state = 0; pos < to; i+=2) {
      var part = source[i], end = pos + part.length;
      if (state == 0) {
        if (end > from) dest.push(part.slice(from - pos, Math.min(part.length, to - pos)), source[i+1]);
        if (end >= from) state = 1;
      }
      else if (state == 1) {
        if (end > to) dest.push(part.slice(0, to - pos), source[i+1]);
        else dest.push(part, source[i+1]);
      }
      pos = end;
    }
  }

  // Data structure that holds the sequence of lines.
  function LeafChunk(lines) {
    this.lines = lines;
    this.parent = null;
    for (var i = 0, e = lines.length, height = 0; i < e; ++i) {
      lines[i].parent = this;
      height += lines[i].height;
    }
    this.height = height;
  }
  LeafChunk.prototype = {
    chunkSize: function() { return this.lines.length; },
    remove: function(at, n, callbacks) {
      for (var i = at, e = at + n; i < e; ++i) {
        var line = this.lines[i];
        this.height -= line.height;
        line.cleanUp();
        if (line.handlers)
          for (var j = 0; j < line.handlers.length; ++j) callbacks.push(line.handlers[j]);
      }
      this.lines.splice(at, n);
    },
    collapse: function(lines) {
      lines.splice.apply(lines, [lines.length, 0].concat(this.lines));
    },
    insertHeight: function(at, lines, height) {
      this.height += height;
      this.lines.splice.apply(this.lines, [at, 0].concat(lines));
      for (var i = 0, e = lines.length; i < e; ++i) lines[i].parent = this;
    },
    iterN: function(at, n, op) {
      for (var e = at + n; at < e; ++at)
        if (op(this.lines[at])) return true;
    }
  };
  function BranchChunk(children) {
    this.children = children;
    var size = 0, height = 0;
    for (var i = 0, e = children.length; i < e; ++i) {
      var ch = children[i];
      size += ch.chunkSize(); height += ch.height;
      ch.parent = this;
    }
    this.size = size;
    this.height = height;
    this.parent = null;
  }
  BranchChunk.prototype = {
    chunkSize: function() { return this.size; },
    remove: function(at, n, callbacks) {
      this.size -= n;
      for (var i = 0; i < this.children.length; ++i) {
        var child = this.children[i], sz = child.chunkSize();
        if (at < sz) {
          var rm = Math.min(n, sz - at), oldHeight = child.height;
          child.remove(at, rm, callbacks);
          this.height -= oldHeight - child.height;
          if (sz == rm) { this.children.splice(i--, 1); child.parent = null; }
          if ((n -= rm) == 0) break;
          at = 0;
        } else at -= sz;
      }
      if (this.size - n < 25) {
        var lines = [];
        this.collapse(lines);
        this.children = [new LeafChunk(lines)];
      }
    },
    collapse: function(lines) {
      for (var i = 0, e = this.children.length; i < e; ++i) this.children[i].collapse(lines);
    },
    insert: function(at, lines) {
      var height = 0;
      for (var i = 0, e = lines.length; i < e; ++i) height += lines[i].height;
      this.insertHeight(at, lines, height);
    },
    insertHeight: function(at, lines, height) {
      this.size += lines.length;
      this.height += height;
      for (var i = 0, e = this.children.length; i < e; ++i) {
        var child = this.children[i], sz = child.chunkSize();
        if (at <= sz) {
          child.insertHeight(at, lines, height);
          if (child.lines && child.lines.length > 50) {
            while (child.lines.length > 50) {
              var spilled = child.lines.splice(child.lines.length - 25, 25);
              var newleaf = new LeafChunk(spilled);
              child.height -= newleaf.height;
              this.children.splice(i + 1, 0, newleaf);
              newleaf.parent = this;
            }
            this.maybeSpill();
          }
          break;
        }
        at -= sz;
      }
    },
    maybeSpill: function() {
      if (this.children.length <= 10) return;
      var me = this;
      do {
        var spilled = me.children.splice(me.children.length - 5, 5);
        var sibling = new BranchChunk(spilled);
        if (!me.parent) { // Become the parent node
          var copy = new BranchChunk(me.children);
          copy.parent = me;
          me.children = [copy, sibling];
          me = copy;
        } else {
          me.size -= sibling.size;
          me.height -= sibling.height;
          var myIndex = indexOf(me.parent.children, me);
          me.parent.children.splice(myIndex + 1, 0, sibling);
        }
        sibling.parent = me.parent;
      } while (me.children.length > 10);
      me.parent.maybeSpill();
    },
    iter: function(from, to, op) { this.iterN(from, to - from, op); },
    iterN: function(at, n, op) {
      for (var i = 0, e = this.children.length; i < e; ++i) {
        var child = this.children[i], sz = child.chunkSize();
        if (at < sz) {
          var used = Math.min(n, sz - at);
          if (child.iterN(at, used, op)) return true;
          if ((n -= used) == 0) break;
          at = 0;
        } else at -= sz;
      }
    }
  };

  function getLineAt(chunk, n) {
    while (!chunk.lines) {
      for (var i = 0;; ++i) {
        var child = chunk.children[i], sz = child.chunkSize();
        if (n < sz) { chunk = child; break; }
        n -= sz;
      }
    }
    return chunk.lines[n];
  }
  function lineNo(line) {
    if (line.parent == null) return null;
    var cur = line.parent, no = indexOf(cur.lines, line);
    for (var chunk = cur.parent; chunk; cur = chunk, chunk = chunk.parent) {
      for (var i = 0, e = chunk.children.length; ; ++i) {
        if (chunk.children[i] == cur) break;
        no += chunk.children[i].chunkSize();
      }
    }
    return no;
  }
  function lineAtHeight(chunk, h) {
    var n = 0;
    outer: do {
      for (var i = 0, e = chunk.children.length; i < e; ++i) {
        var child = chunk.children[i], ch = child.height;
        if (h < ch) { chunk = child; continue outer; }
        h -= ch;
        n += child.chunkSize();
      }
      return n;
    } while (!chunk.lines);
    for (var i = 0, e = chunk.lines.length; i < e; ++i) {
      var line = chunk.lines[i], lh = line.height;
      if (h < lh) break;
      h -= lh;
    }
    return n + i;
  }
  function heightAtLine(chunk, n) {
    var h = 0;
    outer: do {
      for (var i = 0, e = chunk.children.length; i < e; ++i) {
        var child = chunk.children[i], sz = child.chunkSize();
        if (n < sz) { chunk = child; continue outer; }
        n -= sz;
        h += child.height;
      }
      return h;
    } while (!chunk.lines);
    for (var i = 0; i < n; ++i) h += chunk.lines[i].height;
    return h;
  }

  // The history object 'chunks' changes that are made close together
  // and at almost the same time into bigger undoable units.
  function History() {
    this.time = 0;
    this.done = []; this.undone = [];
  }
  History.prototype = {
    addChange: function(start, added, old) {
      this.undone.length = 0;
      var time = +new Date, last = this.done[this.done.length - 1];
      if (time - this.time > 400 || !last ||
          last.start > start + added || last.start + last.added < start - last.added + last.old.length)
        this.done.push({start: start, added: added, old: old});
      else {
        var oldoff = 0;
        if (start < last.start) {
          for (var i = last.start - start - 1; i >= 0; --i)
            last.old.unshift(old[i]);
          last.added += last.start - start;
          last.start = start;
        }
        else if (last.start < start) {
          oldoff = start - last.start;
          added += oldoff;
        }
        for (var i = last.added - oldoff, e = old.length; i < e; ++i)
          last.old.push(old[i]);
        if (last.added < added) last.added = added;
      }
      this.time = time;
    }
  };

  function stopMethod() {e_stop(this);}
  // Ensure an event has a stop method.
  function addStop(event) {
    if (!event.stop) event.stop = stopMethod;
    return event;
  }

  function e_preventDefault(e) {
    if (e.preventDefault) e.preventDefault();
    else e.returnValue = false;
  }
  function e_stopPropagation(e) {
    if (e.stopPropagation) e.stopPropagation();
    else e.cancelBubble = true;
  }
  function e_stop(e) {e_preventDefault(e); e_stopPropagation(e);}
  CodeMirror.e_stop = e_stop;
  CodeMirror.e_preventDefault = e_preventDefault;
  CodeMirror.e_stopPropagation = e_stopPropagation;

  function e_target(e) {return e.target || e.srcElement;}
  function e_button(e) {
    if (e.which) return e.which;
    else if (e.button & 1) return 1;
    else if (e.button & 2) return 3;
    else if (e.button & 4) return 2;
  }

  // Event handler registration. If disconnect is true, it'll return a
  // function that unregisters the handler.
  function connect(node, type, handler, disconnect) {
    if (typeof node.addEventListener == "function") {
      node.addEventListener(type, handler, false);
      if (disconnect) return function() {node.removeEventListener(type, handler, false);};
    }
    else {
      var wrapHandler = function(event) {handler(event || window.event);};
      node.attachEvent("on" + type, wrapHandler);
      if (disconnect) return function() {node.detachEvent("on" + type, wrapHandler);};
    }
  }
  CodeMirror.connect = connect;

  function Delayed() {this.id = null;}
  Delayed.prototype = {set: function(ms, f) {clearTimeout(this.id); this.id = setTimeout(f, ms);}};

  // Detect drag-and-drop
  var dragAndDrop = function() {
    // IE8 has ondragstart and ondrop properties, but doesn't seem to
    // actually support ondragstart the way it's supposed to work.
    if (/MSIE [1-8]\b/.test(navigator.userAgent)) return false;
    var div = document.createElement('div');
    return "draggable" in div;
  }();

  var gecko = /gecko\/\d{7}/i.test(navigator.userAgent);
  var ie = /MSIE \d/.test(navigator.userAgent);
  var webkit = /WebKit\//.test(navigator.userAgent);

  var lineSep = "\n";
  // Feature-detect whether newlines in textareas are converted to \r\n
  (function () {
    var te = document.createElement("textarea");
    te.value = "foo\nbar";
    if (te.value.indexOf("\r") > -1) lineSep = "\r\n";
  }());

  // Counts the column offset in a string, taking tabs into account.
  // Used mostly to find indentation.
  function countColumn(string, end, tabSize) {
    if (end == null) {
      end = string.search(/[^\s\u00a0]/);
      if (end == -1) end = string.length;
    }
    for (var i = 0, n = 0; i < end; ++i) {
      if (string.charAt(i) == "\t") n += tabSize - (n % tabSize);
      else ++n;
    }
    return n;
  }

  function computedStyle(elt) {
    if (elt.currentStyle) return elt.currentStyle;
    return window.getComputedStyle(elt, null);
  }

  // Find the position of an element by following the offsetParent chain.
  // If screen==true, it returns screen (rather than page) coordinates.
  function eltOffset(node, screen) {
    var bod = node.ownerDocument.body;
    var x = 0, y = 0, skipBody = false;
    for (var n = node; n; n = n.offsetParent) {
      var ol = n.offsetLeft, ot = n.offsetTop;
      // Firefox reports weird inverted offsets when the body has a border.
      if (n == bod) { x += Math.abs(ol); y += Math.abs(ot); }
      else { x += ol, y += ot; }
      if (screen && computedStyle(n).position == "fixed")
        skipBody = true;
    }
    var e = screen && !skipBody ? null : bod;
    for (var n = node.parentNode; n != e; n = n.parentNode)
      if (n.scrollLeft != null) { x -= n.scrollLeft; y -= n.scrollTop;}
    return {left: x, top: y};
  }
  // Use the faster and saner getBoundingClientRect method when possible.
  if (document.documentElement.getBoundingClientRect != null) eltOffset = function(node, screen) {
    // Take the parts of bounding client rect that we are interested in so we are able to edit if need be,
    // since the returned value cannot be changed externally (they are kept in sync as the element moves within the page)
    try { var box = node.getBoundingClientRect(); box = { top: box.top, left: box.left }; }
    catch(e) { box = {top: 0, left: 0}; }
    if (!screen) {
      // Get the toplevel scroll, working around browser differences.
      if (window.pageYOffset == null) {
        var t = document.documentElement || document.body.parentNode;
        if (t.scrollTop == null) t = document.body;
        box.top += t.scrollTop; box.left += t.scrollLeft;
      } else {
        box.top += window.pageYOffset; box.left += window.pageXOffset;
      }
    }
    return box;
  };

  // Get a node's text content.
  function eltText(node) {
    return node.textContent || node.innerText || node.nodeValue || "";
  }

  // Operations on {line, ch} objects.
  function posEq(a, b) {return a.line == b.line && a.ch == b.ch;}
  function posLess(a, b) {return a.line < b.line || (a.line == b.line && a.ch < b.ch);}
  function copyPos(x) {return {line: x.line, ch: x.ch};}

  var escapeElement = document.createElement("pre");
  function htmlEscape(str) {
    escapeElement.textContent = str;
    return escapeElement.innerHTML;
  }
  // Recent (late 2011) Opera betas insert bogus newlines at the start
  // of the textContent, so we strip those.
  if (htmlEscape("a") == "\na")
    htmlEscape = function(str) {
      escapeElement.textContent = str;
      return escapeElement.innerHTML.slice(1);
    };
  // Some IEs don't preserve tabs through innerHTML
  else if (htmlEscape("\t") != "\t")
    htmlEscape = function(str) {
      escapeElement.innerHTML = "";
      escapeElement.appendChild(document.createTextNode(str));
      return escapeElement.innerHTML;
    };
  CodeMirror.htmlEscape = htmlEscape;

  // Used to position the cursor after an undo/redo by finding the
  // last edited character.
  function editEnd(from, to) {
    if (!to) return from ? from.length : 0;
    if (!from) return to.length;
    for (var i = from.length, j = to.length; i >= 0 && j >= 0; --i, --j)
      if (from.charAt(i) != to.charAt(j)) break;
    return j + 1;
  }

  function indexOf(collection, elt) {
    if (collection.indexOf) return collection.indexOf(elt);
    for (var i = 0, e = collection.length; i < e; ++i)
      if (collection[i] == elt) return i;
    return -1;
  }
  function isWordChar(ch) {
    return /\w/.test(ch) || ch.toUpperCase() != ch.toLowerCase();
  }

  // See if "".split is the broken IE version, if so, provide an
  // alternative way to split lines.
  var splitLines = "\n\nb".split(/\n/).length != 3 ? function(string) {
    var pos = 0, nl, result = [];
    while ((nl = string.indexOf("\n", pos)) > -1) {
      result.push(string.slice(pos, string.charAt(nl-1) == "\r" ? nl - 1 : nl));
      pos = nl + 1;
    }
    result.push(string.slice(pos));
    return result;
  } : function(string){return string.split(/\r?\n/);};
  CodeMirror.splitLines = splitLines;

  var hasSelection = window.getSelection ? function(te) {
    try { return te.selectionStart != te.selectionEnd; }
    catch(e) { return false; }
  } : function(te) {
    try {var range = te.ownerDocument.selection.createRange();}
    catch(e) {}
    if (!range || range.parentElement() != te) return false;
    return range.compareEndPoints("StartToEnd", range) != 0;
  };

  CodeMirror.defineMode("null", function() {
    return {token: function(stream) {stream.skipToEnd();}};
  });
  CodeMirror.defineMIME("text/plain", "null");

  var keyNames = {3: "Enter", 8: "Backspace", 9: "Tab", 13: "Enter", 16: "Shift", 17: "Ctrl", 18: "Alt",
                  19: "Pause", 20: "CapsLock", 27: "Esc", 32: "Space", 33: "PageUp", 34: "PageDown", 35: "End",
                  36: "Home", 37: "Left", 38: "Up", 39: "Right", 40: "Down", 44: "PrintScrn", 45: "Insert",
                  46: "Delete", 59: ";", 91: "Mod", 92: "Mod", 93: "Mod", 186: ";", 187: "=", 188: ",",
                  189: "-", 190: ".", 191: "/", 192: "`", 219: "[", 220: "\\", 221: "]", 222: "'", 63276: "PageUp",
                  63277: "PageDown", 63275: "End", 63273: "Home", 63234: "Left", 63232: "Up", 63235: "Right",
                  63233: "Down", 63302: "Insert", 63272: "Delete"};
  CodeMirror.keyNames = keyNames;
  (function() {
    // Number keys
    for (var i = 0; i < 10; i++) keyNames[i + 48] = String(i);
    // Alphabetic keys
    for (var i = 65; i <= 90; i++) keyNames[i] = String.fromCharCode(i);
    // Function keys
    for (var i = 1; i <= 12; i++) keyNames[i + 111] = keyNames[i + 63235] = "F" + i;
  })();

  return CodeMirror;
})();
]]
createResourceFile(resourceFile,"codemirror.js")

resourceFile = [[CodeMirror.runMode = function(string, modespec, callback) {
  var mode = CodeMirror.getMode({indentUnit: 2}, modespec);
  var isNode = callback.nodeType == 1;
  if (isNode) {
    var node = callback, accum = [];
    callback = function(string, style) {
      if (string == "\n")
        accum.push("<br>");
      else if (style)
        accum.push("<span class=\"cm-" + CodeMirror.htmlEscape(style) + "\">" + CodeMirror.htmlEscape(string) + "</span>");
      else
        accum.push(CodeMirror.htmlEscape(string));
    }
  }
  var lines = CodeMirror.splitLines(string), state = CodeMirror.startState(mode);
  for (var i = 0, e = lines.length; i < e; ++i) {
    if (i) callback("\n");
    var stream = new CodeMirror.StringStream(lines[i]);
    while (!stream.eol()) {
      var style = mode.token(stream, state);
      callback(stream.current(), style, i, stream.start);
      stream.start = stream.pos;
    }
  }
  if (isNode)
    node.innerHTML = accum.join("");
};
]]
createResourceFile(resourceFile,"runmode.js")

resourceFile = [[.CodeMirror {
  line-height: 1em;
  font-family: monospace;
}

.CodeMirror-scroll {
  overflow: auto;
  height: 300px;
  /* This is needed to prevent an IE[67] bug where the scrolled content
     is visible outside of the scrolling box. */
  position: relative;
}

.CodeMirror-gutter {
  position: absolute; left: 0; top: 0;
  z-index: 10;
  background-color: #f7f7f7;
  border-right: 1px solid #eee;
  min-width: 2em;
  height: 100%;
}
.CodeMirror-gutter-text {
  color: #aaa;
  text-align: right;
  padding: .4em .2em .4em .4em;
  white-space: pre !important;
}
.CodeMirror-lines {
  padding: .4em;
}

.CodeMirror pre {
  -moz-border-radius: 0;
  -webkit-border-radius: 0;
  -o-border-radius: 0;
  border-radius: 0;
  border-width: 0; margin: 0; padding: 0; background: transparent;
  font-family: inherit;
  font-size: inherit;
  padding: 0; margin: 0;
  white-space: pre;
  word-wrap: normal;
}

.CodeMirror-wrap pre {
  word-wrap: break-word;
  white-space: pre-wrap;
}
.CodeMirror-wrap .CodeMirror-scroll {
  overflow-x: hidden;
}

.CodeMirror textarea {
  outline: none !important;
}

.CodeMirror pre.CodeMirror-cursor {
  z-index: 10;
  position: absolute;
  visibility: hidden;
  border-left: 1px solid black;
}
.CodeMirror-focused pre.CodeMirror-cursor {
  visibility: visible;
}

span.CodeMirror-selected { background: #d9d9d9; }
.CodeMirror-focused span.CodeMirror-selected { background: #d2dcf8; }

.CodeMirror-searching {background: #ffa;}

/* Default theme */

.cm-s-default span.cm-keyword {color: #708;}
.cm-s-default span.cm-atom {color: #219;}
.cm-s-default span.cm-number {color: #164;}
.cm-s-default span.cm-def {color: #00f;}
.cm-s-default span.cm-variable {color: black;}
.cm-s-default span.cm-variable-2 {color: #05a;}
.cm-s-default span.cm-variable-3 {color: #085;}
.cm-s-default span.cm-property {color: black;}
.cm-s-default span.cm-operator {color: black;}
.cm-s-default span.cm-comment {color: #a50;}
.cm-s-default span.cm-string {color: #a11;}
.cm-s-default span.cm-string-2 {color: #f50;}
.cm-s-default span.cm-meta {color: #555;}
.cm-s-default span.cm-error {color: #f00;}
.cm-s-default span.cm-qualifier {color: #555;}
.cm-s-default span.cm-builtin {color: #30a;}
.cm-s-default span.cm-bracket {color: #cc7;}
.cm-s-default span.cm-tag {color: #170;}
.cm-s-default span.cm-attribute {color: #00c;}
.cm-s-default span.cm-header {color: #a0a;}
.cm-s-default span.cm-quote {color: #090;}
.cm-s-default span.cm-hr {color: #999;}
.cm-s-default span.cm-link {color: #00c;}

span.cm-header, span.cm-strong {font-weight: bold;}
span.cm-em {font-style: italic;}
span.cm-emstrong {font-style: italic; font-weight: bold;}
span.cm-link {text-decoration: underline;}

div.CodeMirror span.CodeMirror-matchingbracket {color: #0f0;}
div.CodeMirror span.CodeMirror-nonmatchingbracket {color: #f22;}
]]
createResourceFile(resourceFile,"codemirror.css")

resourceFile = [[body {
  font-family: Droid Sans, Arial, sans-serif;
  line-height: 1.5;
  max-width: 64.3em;
  margin: 3em auto;
  padding: 0 1em;
}

h1 {
  letter-spacing: -3px;
  font-size: 3.23em;
  font-weight: bold;
  margin: 0;
}

h2 {
  font-size: 1.23em;
  font-weight: bold;
  margin: .5em 0;
  letter-spacing: -1px;
}

h3 {
  font-size: 1em;
  font-weight: bold;
  margin: .4em 0;
}

pre {
  background-color: #eee;
  -moz-border-radius: 6px;
  -webkit-border-radius: 6px;
  border-radius: 6px;
  padding: 1em;
}

pre.code {
  margin: 0 1em;
}

.grey {
  font-size: 2.2em;
  padding: .5em 1em;
  line-height: 1.2em;
  margin-top: .5em;
  position: relative;
}

img.logo {
  position: absolute;
  right: -25px;
  bottom: 4px;
}

a:link, a:visited, .quasilink {
  color: #df0019;
  cursor: pointer;
  text-decoration: none;
}

a:hover, .quasilink:hover {
  color: #800004;
}

h1 a:link, h1 a:visited, h1 a:hover {
  color: black;
}

ul {
  margin: 0;
  padding-left: 1.2em;
}

a.download {
  color: white;
  background-color: #df0019;
  width: 100%;
  display: block;
  text-align: center;
  font-size: 1.23em;
  font-weight: bold;
  text-decoration: none;
  -moz-border-radius: 6px;
  -webkit-border-radius: 6px;
  border-radius: 6px;
  padding: .5em 0;
  margin-bottom: 1em;
}

a.download:hover {
  background-color: #bb0010;
}

.rel {
  margin-bottom: 0;
}

.rel-note {
  color: #777;
  font-size: .9em;
  margin-top: .1em;
}

.logo-braces {
  color: #df0019;
  position: relative;
  top: -4px;
}

.blk {
  float: left;
}

.left {
  width: 37em;
  padding-right: 6.53em;
  padding-bottom: 1em;
}

.left1 {
  width: 15.24em;
  padding-right: 6.45em;
}

.left2 {
  width: 15.24em;
}

.right {
  width: 20.68em;
}

.leftbig {
  width: 42.44em;
  padding-right: 6.53em;
}

.rightsmall {
  width: 15.24em;
}

.clear:after {
  visibility: hidden;
  display: block;
  font-size: 0;
  content: " ";
  clear: both;
  height: 0;
}
.clear { display: inline-block; }
/* start commented backslash hack \*/
* html .clear { height: 1%; }
.clear { display: block; }
/* close commented backslash hack */
]]
createResourceFile(resourceFile,"docs.css")

resourceFile = [[DygraphLayout=function(a){this.dygraph_=a;this.datasets=new Array();this.annotations=new Array();this.yAxes_=null;this.xTicks_=null;this.yTicks_=null};DygraphLayout.prototype.attr_=function(a){return this.dygraph_.attr_(a)};DygraphLayout.prototype.addDataset=function(a,b){this.datasets[a]=b};DygraphLayout.prototype.getPlotArea=function(){return this.computePlotArea_()};DygraphLayout.prototype.computePlotArea_=function(){var a={x:0,y:0};if(this.attr_("drawYAxis")){a.x=this.attr_("yAxisLabelWidth")+2*this.attr_("axisTickSize")}a.w=this.dygraph_.width_-a.x-this.attr_("rightGap");a.h=this.dygraph_.height_;if(this.attr_("drawXAxis")){if(this.attr_("xAxisHeight")){a.h-=this.attr_("xAxisHeight")}else{a.h-=this.attr_("axisLabelFontSize")+2*this.attr_("axisTickSize")}}if(this.dygraph_.numAxes()==2){a.w-=(this.attr_("yAxisLabelWidth")+2*this.attr_("axisTickSize"))}else{if(this.dygraph_.numAxes()>2){this.dygraph_.error("Only two y-axes are supported at this time. (Trying to use "+this.dygraph_.numAxes()+")")}}if(this.attr_("title")){a.h-=this.attr_("titleHeight");a.y+=this.attr_("titleHeight")}if(this.attr_("xlabel")){a.h-=this.attr_("xLabelHeight")}if(this.attr_("ylabel")){}if(this.attr_("showRangeSelector")){a.h-=this.attr_("rangeSelectorHeight")+4}return a};DygraphLayout.prototype.setAnnotations=function(d){this.annotations=[];var e=this.attr_("xValueParser")||function(a){return a};for(var c=0;c<d.length;c++){var b={};if(!d[c].xval&&!d[c].x){this.dygraph_.error("Annotations must have an 'x' property");return}if(d[c].icon&&!(d[c].hasOwnProperty("width")&&d[c].hasOwnProperty("height"))){this.dygraph_.error("Must set width and height when setting annotation.icon property");return}Dygraph.update(b,d[c]);if(!b.xval){b.xval=e(b.x)}this.annotations.push(b)}};DygraphLayout.prototype.setXTicks=function(a){this.xTicks_=a};DygraphLayout.prototype.setYAxes=function(a){this.yAxes_=a};DygraphLayout.prototype.setDateWindow=function(a){this.dateWindow_=a};DygraphLayout.prototype.evaluate=function(){this._evaluateLimits();this._evaluateLineCharts();this._evaluateLineTicks();this._evaluateAnnotations()};DygraphLayout.prototype._evaluateLimits=function(){this.minxval=this.maxxval=null;if(this.dateWindow_){this.minxval=this.dateWindow_[0];this.maxxval=this.dateWindow_[1]}else{for(var c in this.datasets){if(!this.datasets.hasOwnProperty(c)){continue}var e=this.datasets[c];if(e.length>1){var b=e[0][0];if(!this.minxval||b<this.minxval){this.minxval=b}var a=e[e.length-1][0];if(!this.maxxval||a>this.maxxval){this.maxxval=a}}}}this.xrange=this.maxxval-this.minxval;this.xscale=(this.xrange!=0?1/this.xrange:1);for(var d=0;d<this.yAxes_.length;d++){var f=this.yAxes_[d];f.minyval=f.computedValueRange[0];f.maxyval=f.computedValueRange[1];f.yrange=f.maxyval-f.minyval;f.yscale=(f.yrange!=0?1/f.yrange:1);if(f.g.attr_("logscale")){f.ylogrange=Dygraph.log10(f.maxyval)-Dygraph.log10(f.minyval);f.ylogscale=(f.ylogrange!=0?1/f.ylogrange:1);if(!isFinite(f.ylogrange)||isNaN(f.ylogrange)){f.g.error("axis "+d+" of graph at "+f.g+" can't be displayed in log scale for range ["+f.minyval+" - "+f.maxyval+"]")}}}};DygraphLayout._calcYNormal=function(a,b){if(a.logscale){return 1-((Dygraph.log10(b)-Dygraph.log10(a.minyval))*a.ylogscale)}else{return 1-((b-a.minyval)*a.yscale)}};DygraphLayout.prototype._evaluateLineCharts=function(){this.points=new Array();this.setPointsLengths=new Array();for(var f in this.datasets){if(!this.datasets.hasOwnProperty(f)){continue}var b=this.datasets[f];var a=this.dygraph_.axisPropertiesForSeries(f);var g=0;for(var d=0;d<b.length;d++){var l=b[d];var c=parseFloat(b[d][0]);var h=parseFloat(b[d][1]);var k=(c-this.minxval)*this.xscale;var e=DygraphLayout._calcYNormal(a,h);var i={x:k,y:e,xval:c,yval:h,name:f};this.points.push(i);g+=1}this.setPointsLengths.push(g)}};DygraphLayout.prototype._evaluateLineTicks=function(){this.xticks=new Array();for(var d=0;d<this.xTicks_.length;d++){var c=this.xTicks_[d];var b=c.label;var f=this.xscale*(c.v-this.minxval);if((f>=0)&&(f<=1)){this.xticks.push([f,b])}}this.yticks=new Array();for(var d=0;d<this.yAxes_.length;d++){var e=this.yAxes_[d];for(var a=0;a<e.ticks.length;a++){var c=e.ticks[a];var b=c.label;var f=this.dygraph_.toPercentYCoord(c.v,d);if((f>=0)&&(f<=1)){this.yticks.push([d,f,b])}}}};DygraphLayout.prototype.evaluateWithError=function(){this.evaluate();if(!(this.attr_("errorBars")||this.attr_("customBars"))){return}var g=0;for(var k in this.datasets){if(!this.datasets.hasOwnProperty(k)){continue}var f=0;var e=this.datasets[k];var d=this.dygraph_.axisPropertiesForSeries(k);for(var f=0;f<e.length;f++,g++){var n=e[f];var b=parseFloat(n[0]);var l=parseFloat(n[1]);if(b==this.points[g].xval&&l==this.points[g].yval){var h=parseFloat(n[2]);var c=parseFloat(n[3]);var m=l-h;var a=l+c;this.points[g].y_top=DygraphLayout._calcYNormal(d,m);this.points[g].y_bottom=DygraphLayout._calcYNormal(d,a)}}}};DygraphLayout.prototype._evaluateAnnotations=function(){var f={};for(var d=0;d<this.annotations.length;d++){var b=this.annotations[d];f[b.xval+","+b.series]=b}this.annotated_points=[];if(!this.annotations||!this.annotations.length){return}for(var d=0;d<this.points.length;d++){var e=this.points[d];var c=e.xval+","+e.name;if(c in f){e.annotation=f[c];this.annotated_points.push(e)}}};DygraphLayout.prototype.removeAllDatasets=function(){delete this.datasets;this.datasets=new Array()};DygraphLayout.prototype.unstackPointAtIndex=function(b){var a=this.points[b];var d={};for(var c in a){d[c]=a[c]}if(!this.attr_("stackedGraph")){return d}for(var c=b+1;c<this.points.length;c++){if(this.points[c].xval==a.xval){d.yval-=this.points[c].yval;break}}return d};DygraphCanvasRenderer=function(d,c,b,e){this.dygraph_=d;this.layout=e;this.element=c;this.elementContext=b;this.container=this.element.parentNode;this.height=this.element.height;this.width=this.element.width;if(!this.isIE&&!(DygraphCanvasRenderer.isSupported(this.element))){throw"Canvas is not supported."}this.xlabels=new Array();this.ylabels=new Array();this.annotations=new Array();this.chartLabels={};this.area=e.getPlotArea();this.container.style.position="relative";this.container.style.width=this.width+"px";if(this.dygraph_.isUsingExcanvas_){this._createIEClipArea()}else{var a=this.dygraph_.canvas_ctx_;a.beginPath();a.rect(this.area.x,this.area.y,this.area.w,this.area.h);a.clip();a=this.dygraph_.hidden_ctx_;a.beginPath();a.rect(this.area.x,this.area.y,this.area.w,this.area.h);a.clip()}};DygraphCanvasRenderer.prototype.attr_=function(a){return this.dygraph_.attr_(a)};DygraphCanvasRenderer.prototype.clear=function(){if(this.isIE){try{if(this.clearDelay){this.clearDelay.cancel();this.clearDelay=null}var c=this.elementContext}catch(f){this.clearDelay=MochiKit.Async.wait(this.IEDelay);this.clearDelay.addCallback(bind(this.clear,this));return}}var c=this.elementContext;c.clearRect(0,0,this.width,this.height);for(var b=0;b<this.xlabels.length;b++){var d=this.xlabels[b];if(d.parentNode){d.parentNode.removeChild(d)}}for(var b=0;b<this.ylabels.length;b++){var d=this.ylabels[b];if(d.parentNode){d.parentNode.removeChild(d)}}for(var b=0;b<this.annotations.length;b++){var d=this.annotations[b];if(d.parentNode){d.parentNode.removeChild(d)}}for(var a in this.chartLabels){if(!this.chartLabels.hasOwnProperty(a)){continue}var d=this.chartLabels[a];if(d.parentNode){d.parentNode.removeChild(d)}}this.xlabels=new Array();this.ylabels=new Array();this.annotations=new Array();this.chartLabels={}};DygraphCanvasRenderer.isSupported=function(g){var b=null;try{if(typeof(g)=="undefined"||g==null){b=document.createElement("canvas")}else{b=g}var c=b.getContext("2d")}catch(d){var f=navigator.appVersion.match(/MSIE (\d\.\d)/);var a=(navigator.userAgent.toLowerCase().indexOf("opera")!=-1);if((!f)||(f[1]<6)||(a)){return false}return true}return true};DygraphCanvasRenderer.prototype.setColors=function(a){this.colorScheme_=a};DygraphCanvasRenderer.prototype.render=function(){var b=this.elementContext;function c(h){return Math.round(h)+0.5}function g(h){return Math.round(h)-0.5}if(this.attr_("underlayCallback")){this.attr_("underlayCallback")(b,this.area,this.dygraph_,this.dygraph_)}if(this.attr_("drawYGrid")){var e=this.layout.yticks;b.save();b.strokeStyle=this.attr_("gridLineColor");b.lineWidth=this.attr_("gridLineWidth");for(var d=0;d<e.length;d++){if(e[d][0]!=0){continue}var a=c(this.area.x);var f=g(this.area.y+e[d][1]*this.area.h);b.beginPath();b.moveTo(a,f);b.lineTo(a+this.area.w,f);b.closePath();b.stroke()}}if(this.attr_("drawXGrid")){var e=this.layout.xticks;b.save();b.strokeStyle=this.attr_("gridLineColor");b.lineWidth=this.attr_("gridLineWidth");for(var d=0;d<e.length;d++){var a=c(this.area.x+e[d][0]*this.area.w);var f=g(this.area.y+this.area.h);b.beginPath();b.moveTo(a,f);b.lineTo(a,this.area.y);b.closePath();b.stroke()}}this._renderLineChart();this._renderAxis();this._renderChartLabels();this._renderAnnotations()};DygraphCanvasRenderer.prototype._createIEClipArea=function(){var g="dygraph-clip-div";var f=this.dygraph_.graphDiv;for(var e=f.childNodes.length-1;e>=0;e--){if(f.childNodes[e].className==g){f.removeChild(f.childNodes[e])}}var c=document.bgColor;var d=this.dygraph_.graphDiv;while(d!=document){var a=d.currentStyle.backgroundColor;if(a&&a!="transparent"){c=a;break}d=d.parentNode}function b(j){if(j.w==0||j.h==0){return}var i=document.createElement("div");i.className=g;i.style.backgroundColor=c;i.style.position="absolute";i.style.left=j.x+"px";i.style.top=j.y+"px";i.style.width=j.w+"px";i.style.height=j.h+"px";f.appendChild(i)}var h=this.area;b({x:0,y:0,w:h.x,h:this.height});b({x:h.x,y:0,w:this.width-h.x,h:h.y});b({x:h.x+h.w,y:0,w:this.width-h.x-h.w,h:this.height});b({x:h.x,y:h.y+h.h,w:this.width-h.x,h:this.height-h.h-h.y})};DygraphCanvasRenderer.prototype._renderAxis=function(){if(!this.attr_("drawXAxis")&&!this.attr_("drawYAxis")){return}function q(i){return Math.round(i)+0.5}function p(i){return Math.round(i)-0.5}var d=this.elementContext;var a={position:"absolute",fontSize:this.attr_("axisLabelFontSize")+"px",zIndex:10,color:this.attr_("axisLabelColor"),width:this.attr_("axisLabelWidth")+"px",lineHeight:"normal",overflow:"hidden"};var g=function(i,v,w){var x=document.createElement("div");for(var u in a){if(a.hasOwnProperty(u)){x.style[u]=a[u]}}var t=document.createElement("div");t.className="dygraph-axis-label dygraph-axis-label-"+v+(w?" dygraph-axis-label-"+w:"");t.appendChild(document.createTextNode(i));x.appendChild(t);return x};d.save();d.strokeStyle=this.attr_("axisLineColor");d.lineWidth=this.attr_("axisLineWidth");if(this.attr_("drawYAxis")){if(this.layout.yticks&&this.layout.yticks.length>0){var b=this.dygraph_.numAxes();for(var r=0;r<this.layout.yticks.length;r++){var s=this.layout.yticks[r];if(typeof(s)=="function"){return}var n=this.area.x;var j=1;var c="y1";if(s[0]==1){n=this.area.x+this.area.w;j=-1;c="y2"}var m=this.area.y+s[1]*this.area.h;var l=g(s[2],"y",b==2?c:null);var o=(m-this.attr_("axisLabelFontSize")/2);if(o<0){o=0}if(o+this.attr_("axisLabelFontSize")+3>this.height){l.style.bottom="0px"}else{l.style.top=o+"px"}if(s[0]==0){l.style.left=(this.area.x-this.attr_("yAxisLabelWidth")-this.attr_("axisTickSize"))+"px";l.style.textAlign="right"}else{if(s[0]==1){l.style.left=(this.area.x+this.area.w+this.attr_("axisTickSize"))+"px";l.style.textAlign="left"}}l.style.width=this.attr_("yAxisLabelWidth")+"px";this.container.appendChild(l);this.ylabels.push(l)}var h=this.ylabels[0];var e=this.attr_("axisLabelFontSize");var k=parseInt(h.style.top)+e;if(k>this.height-e){h.style.top=(parseInt(h.style.top)-e/2)+"px"}}d.beginPath();d.moveTo(q(this.area.x),p(this.area.y));d.lineTo(q(this.area.x),p(this.area.y+this.area.h));d.closePath();d.stroke();if(this.dygraph_.numAxes()==2){d.beginPath();d.moveTo(p(this.area.x+this.area.w),p(this.area.y));d.lineTo(p(this.area.x+this.area.w),p(this.area.y+this.area.h));d.closePath();d.stroke()}}if(this.attr_("drawXAxis")){if(this.layout.xticks){for(var r=0;r<this.layout.xticks.length;r++){var s=this.layout.xticks[r];if(typeof(dataset)=="function"){return}var n=this.area.x+s[0]*this.area.w;var m=this.area.y+this.area.h;var l=g(s[1],"x");l.style.textAlign="center";l.style.top=(m+this.attr_("axisTickSize"))+"px";var f=(n-this.attr_("axisLabelWidth")/2);if(f+this.attr_("axisLabelWidth")>this.width){f=this.width-this.attr_("xAxisLabelWidth");l.style.textAlign="right"}if(f<0){f=0;l.style.textAlign="left"}l.style.left=f+"px";l.style.width=this.attr_("xAxisLabelWidth")+"px";this.container.appendChild(l);this.xlabels.push(l)}}d.beginPath();d.moveTo(q(this.area.x),p(this.area.y+this.area.h));d.lineTo(q(this.area.x+this.area.w),p(this.area.y+this.area.h));d.closePath();d.stroke()}d.restore()};DygraphCanvasRenderer.prototype._renderChartLabels=function(){if(this.attr_("title")){var d=document.createElement("div");d.style.position="absolute";d.style.top="0px";d.style.left=this.area.x+"px";d.style.width=this.area.w+"px";d.style.height=this.attr_("titleHeight")+"px";d.style.textAlign="center";d.style.fontSize=(this.attr_("titleHeight")-8)+"px";d.style.fontWeight="bold";var b=document.createElement("div");b.className="dygraph-label dygraph-title";b.innerHTML=this.attr_("title");d.appendChild(b);this.container.appendChild(d);this.chartLabels.title=d}if(this.attr_("xlabel")){var d=document.createElement("div");d.style.position="absolute";d.style.bottom=0;d.style.left=this.area.x+"px";d.style.width=this.area.w+"px";d.style.height=this.attr_("xLabelHeight")+"px";d.style.textAlign="center";d.style.fontSize=(this.attr_("xLabelHeight")-2)+"px";var b=document.createElement("div");b.className="dygraph-label dygraph-xlabel";b.innerHTML=this.attr_("xlabel");d.appendChild(b);this.container.appendChild(d);this.chartLabels.xlabel=d}if(this.attr_("ylabel")){var c={left:0,top:this.area.y,width:this.attr_("yLabelWidth"),height:this.area.h};var d=document.createElement("div");d.style.position="absolute";d.style.left=c.left;d.style.top=c.top+"px";d.style.width=c.width+"px";d.style.height=c.height+"px";d.style.fontSize=(this.attr_("yLabelWidth")-2)+"px";var a=document.createElement("div");a.style.position="absolute";a.style.width=c.height+"px";a.style.height=c.width+"px";a.style.top=(c.height/2-c.width/2)+"px";a.style.left=(c.width/2-c.height/2)+"px";a.style.textAlign="center";a.style.transform="rotate(-90deg)";a.style.WebkitTransform="rotate(-90deg)";a.style.MozTransform="rotate(-90deg)";a.style.OTransform="rotate(-90deg)";a.style.msTransform="rotate(-90deg)";if(typeof(document.documentMode)!=="undefined"&&document.documentMode<9){a.style.filter="progid:DXImageTransform.Microsoft.BasicImage(rotation=3)";a.style.left="0px";a.style.top="0px"}var b=document.createElement("div");b.className="dygraph-label dygraph-ylabel";b.innerHTML=this.attr_("ylabel");a.appendChild(b);d.appendChild(a);this.container.appendChild(d);this.chartLabels.ylabel=d}};DygraphCanvasRenderer.prototype._renderAnnotations=function(){var h={position:"absolute",fontSize:this.attr_("axisLabelFontSize")+"px",zIndex:10,overflow:"hidden"};var j=function(i,q,r,a){return function(s){var p=r.annotation;if(p.hasOwnProperty(i)){p[i](p,r,a.dygraph_,s)}else{if(a.dygraph_.attr_(q)){a.dygraph_.attr_(q)(p,r,a.dygraph_,s)}}}};var m=this.layout.annotated_points;for(var g=0;g<m.length;g++){var e=m[g];if(e.canvasx<this.area.x||e.canvasx>this.area.x+this.area.w){continue}var k=e.annotation;var l=6;if(k.hasOwnProperty("tickHeight")){l=k.tickHeight}var c=document.createElement("div");for(var b in h){if(h.hasOwnProperty(b)){c.style[b]=h[b]}}if(!k.hasOwnProperty("icon")){c.className="dygraphDefaultAnnotation"}if(k.hasOwnProperty("cssClass")){c.className+=" "+k.cssClass}var d=k.hasOwnProperty("width")?k.width:16;var n=k.hasOwnProperty("height")?k.height:16;if(k.hasOwnProperty("icon")){var f=document.createElement("img");f.src=k.icon;f.width=d;f.height=n;c.appendChild(f)}else{if(e.annotation.hasOwnProperty("shortText")){c.appendChild(document.createTextNode(e.annotation.shortText))}}c.style.left=(e.canvasx-d/2)+"px";if(k.attachAtBottom){c.style.top=(this.area.h-n-l)+"px"}else{c.style.top=(e.canvasy-n-l)+"px"}c.style.width=d+"px";c.style.height=n+"px";c.title=e.annotation.text;c.style.color=this.colors[e.name];c.style.borderColor=this.colors[e.name];k.div=c;Dygraph.addEvent(c,"click",j("clickHandler","annotationClickHandler",e,this));Dygraph.addEvent(c,"mouseover",j("mouseOverHandler","annotationMouseOverHandler",e,this));Dygraph.addEvent(c,"mouseout",j("mouseOutHandler","annotationMouseOutHandler",e,this));Dygraph.addEvent(c,"dblclick",j("dblClickHandler","annotationDblClickHandler",e,this));this.container.appendChild(c);this.annotations.push(c);var o=this.elementContext;o.strokeStyle=this.colors[e.name];o.beginPath();if(!k.attachAtBottom){o.moveTo(e.canvasx,e.canvasy);o.lineTo(e.canvasx,e.canvasy-2-l)}else{o.moveTo(e.canvasx,this.area.h);o.lineTo(e.canvasx,this.area.h-2-l)}o.closePath();o.stroke()}};DygraphCanvasRenderer.prototype._renderLineChart=function(){var u=function(i){return(i===null||isNaN(i))};var e=this.elementContext;var A=this.attr_("fillAlpha");var G=this.attr_("errorBars")||this.attr_("customBars");var t=this.attr_("fillGraph");var f=this.attr_("stackedGraph");var m=this.attr_("stepPlot");var C=this.layout.points;var p=C.length;var I=[];for(var K in this.layout.datasets){if(this.layout.datasets.hasOwnProperty(K)){I.push(K)}}var B=I.length;this.colors={};for(var D=0;D<B;D++){this.colors[I[D]].."]]"..[[=this.colorScheme_[D%this.colorScheme_.length]}for(var D=p;D--;){var w=C[D];w.canvasx=this.area.w*w.x+this.area.x;w.canvasy=this.area.h*w.y+this.area.y}var v=e;if(G){if(t){this.dygraph_.warn("Can't use fillGraph option with error bars")}for(var D=0;D<B;D++){var l=I[D];var d=this.dygraph_.axisPropertiesForSeries(l);var y=this.colors[l];v.save();var k=NaN;var g=NaN;var h=[-1,-1];var F=d.yscale;var a=new RGBColor(y);var H="rgba("+a.r+","+a.g+","+a.b+","+A+")";v.fillStyle=H;v.beginPath();for(var z=0;z<p;z++){var w=C[z];if(w.name==l){if(!Dygraph.isOK(w.y)){k=NaN;continue}if(m){var r=[w.y_bottom,w.y_top];g=w.y}else{var r=[w.y_bottom,w.y_top]}r[0]=this.area.h*r[0]+this.area.y;r[1]=this.area.h*r[1]+this.area.y;if(!isNaN(k)){if(m){v.moveTo(k,r[0])}else{v.moveTo(k,h[0])}v.lineTo(w.canvasx,r[0]);v.lineTo(w.canvasx,r[1]);if(m){v.lineTo(k,r[1])}else{v.lineTo(k,h[1])}v.closePath()}h=r;k=w.canvasx}}v.fill()}}else{if(t){var q=[];for(var D=B-1;D>=0;D--){var l=I[D];var y=this.colors[l];var d=this.dygraph_.axisPropertiesForSeries(l);var b=1+d.minyval*d.yscale;if(b<0){b=0}else{if(b>1){b=1}}b=this.area.h*b+this.area.y;v.save();var k=NaN;var h=[-1,-1];var F=d.yscale;var a=new RGBColor(y);var H="rgba("+a.r+","+a.g+","+a.b+","+A+")";v.fillStyle=H;v.beginPath();for(var z=0;z<p;z++){var w=C[z];if(w.name==l){if(!Dygraph.isOK(w.y)){k=NaN;continue}var r;if(f){lastY=q[w.canvasx];if(lastY===undefined){lastY=b}q[w.canvasx]=w.canvasy;r=[w.canvasy,lastY]}else{r=[w.canvasy,b]}if(!isNaN(k)){v.moveTo(k,h[0]);if(m){v.lineTo(w.canvasx,h[0])}else{v.lineTo(w.canvasx,r[0])}v.lineTo(w.canvasx,r[1]);v.lineTo(k,h[1]);v.closePath()}h=r;k=w.canvasx}}v.fill()}}}var J=0;var c=0;var E=0;for(var D=0;D<B;D+=1){E=this.layout.setPointsLengths[D];c+=E;var l=I[D];var y=this.colors[l];var s=this.dygraph_.attr_("strokeWidth",l);e.save();var n=this.dygraph_.attr_("pointSize",l);var k=null,g=null;var x=this.dygraph_.attr_("drawPoints",l);for(var z=J;z<c;z++){var w=C[z];if(u(w.canvasy)){if(m&&k!=null){v.beginPath();v.strokeStyle=y;v.lineWidth=this.attr_("strokeWidth");v.moveTo(k,g);v.lineTo(w.canvasx,g);v.stroke()}k=g=null}else{var o=(!k&&(z==C.length-1||u(C[z+1].canvasy)));if(k===null){k=w.canvasx;g=w.canvasy}else{if(Math.round(k)==Math.round(w.canvasx)&&Math.round(g)==Math.round(w.canvasy)){continue}if(s){v.beginPath();v.strokeStyle=y;v.lineWidth=s;v.moveTo(k,g);if(m){v.lineTo(w.canvasx,g)}k=w.canvasx;g=w.canvasy;v.lineTo(k,g);v.stroke()}}if(x||o){v.beginPath();v.fillStyle=y;v.arc(w.canvasx,w.canvasy,n,0,2*Math.PI,false);v.fill()}}}J=c}e.restore()};Dygraph=function(c,b,a){if(arguments.length>0){if(arguments.length==4){this.warn("Using deprecated four-argument dygraph constructor");this.__old_init__(c,b,arguments[2],arguments[3])}else{this.__init__(c,b,a)}}};Dygraph.NAME="Dygraph";Dygraph.VERSION="1.2";Dygraph.__repr__=function(){return"["+this.NAME+" "+this.VERSION+"]"};Dygraph.toString=function(){return this.__repr__()};Dygraph.DEFAULT_ROLL_PERIOD=1;Dygraph.DEFAULT_WIDTH=480;Dygraph.DEFAULT_HEIGHT=320;Dygraph.ANIMATION_STEPS=10;Dygraph.ANIMATION_DURATION=200;Dygraph.numberValueFormatter=function(a,e,h,d){var b=e("sigFigs");if(b!==null){return Dygraph.floatFormat(a,b)}var f=e("digitsAfterDecimal");var c=e("maxNumberWidth");if(a!==0&&(Math.abs(a)>=Math.pow(10,c)||Math.abs(a)<Math.pow(10,-f))){return a.toExponential(f)}else{return""+Dygraph.round_(a,f)}};Dygraph.numberAxisLabelFormatter=function(a,d,c,b){return Dygraph.numberValueFormatter(a,c,b)};Dygraph.dateString_=function(e){var i=Dygraph.zeropad;var h=new Date(e);var f=""+h.getFullYear();var g=i(h.getMonth()+1);var a=i(h.getDate());var c="";var b=h.getHours()*3600+h.getMinutes()*60+h.getSeconds();if(b){c=" "+Dygraph.hmsString_(e)}return f+"/"+g+"/"+a+c};Dygraph.dateAxisFormatter=function(b,c){if(c>=Dygraph.DECADAL){return b.strftime("%Y")}else{if(c>=Dygraph.MONTHLY){return b.strftime("%b %y")}else{var a=b.getHours()*3600+b.getMinutes()*60+b.getSeconds()+b.getMilliseconds();if(a==0||c>=Dygraph.DAILY){return new Date(b.getTime()+3600*1000).strftime("%d%b")}else{return Dygraph.hmsString_(b.getTime())}}}};Dygraph.DEFAULT_ATTRS={highlightCircleSize:3,labelsDivWidth:250,labelsDivStyles:{},labelsSeparateLines:false,labelsShowZeroValues:true,labelsKMB:false,labelsKMG2:false,showLabelsOnHighlight:true,digitsAfterDecimal:2,maxNumberWidth:6,sigFigs:null,strokeWidth:1,axisTickSize:3,axisLabelFontSize:14,xAxisLabelWidth:50,yAxisLabelWidth:50,rightGap:5,showRoller:false,xValueParser:Dygraph.dateParser,delimiter:",",sigma:2,errorBars:false,fractions:false,wilsonInterval:true,customBars:false,fillGraph:false,fillAlpha:0.15,connectSeparatedPoints:false,stackedGraph:false,hideOverlayOnMouseOut:true,legend:"onmouseover",stepPlot:false,avoidMinZero:false,titleHeight:28,xLabelHeight:18,yLabelWidth:18,drawXAxis:true,drawYAxis:true,axisLineColor:"black",axisLineWidth:0.3,gridLineWidth:0.3,axisLabelColor:"black",axisLabelFont:"Arial",axisLabelWidth:50,drawYGrid:true,drawXGrid:true,gridLineColor:"rgb(128,128,128)",interactionModel:null,animatedZooms:false,showRangeSelector:false,rangeSelectorHeight:40,rangeSelectorPlotStrokeColor:"#808FAB",rangeSelectorPlotFillColor:"#A7B1C4",axes:{x:{pixelsPerLabel:60,axisLabelFormatter:Dygraph.dateAxisFormatter,valueFormatter:Dygraph.dateString_,ticker:null},y:{pixelsPerLabel:30,valueFormatter:Dygraph.numberValueFormatter,axisLabelFormatter:Dygraph.numberAxisLabelFormatter,ticker:null},y2:{pixelsPerLabel:30,valueFormatter:Dygraph.numberValueFormatter,axisLabelFormatter:Dygraph.numberAxisLabelFormatter,ticker:null}}};Dygraph.HORIZONTAL=1;Dygraph.VERTICAL=2;Dygraph.addedAnnotationCSS=false;Dygraph.prototype.__old_init__=function(f,d,e,b){if(e!=null){var a=["Date"];for(var c=0;c<e.length;c++){a.push(e[c])}Dygraph.update(b,{labels:a})}this.__init__(f,d,b)};Dygraph.prototype.__init__=function(d,c,b){if(/MSIE/.test(navigator.userAgent)&&!window.opera&&typeof(G_vmlCanvasManager)!="undefined"&&document.readyState!="complete"){var a=this;setTimeout(function(){a.__init__(d,c,b)},100);return}if(b==null){b={}}b=Dygraph.mapLegacyOptions_(b);if(!d){Dygraph.error("Constructing dygraph with a non-existent div!");return}this.isUsingExcanvas_=typeof(G_vmlCanvasManager)!="undefined";this.maindiv_=d;this.file_=c;this.rollPeriod_=b.rollPeriod||Dygraph.DEFAULT_ROLL_PERIOD;this.previousVerticalX_=-1;this.fractions_=b.fractions||false;this.dateWindow_=b.dateWindow||null;this.wilsonInterval_=b.wilsonInterval||true;this.is_initial_draw_=true;this.annotations_=[];this.zoomed_x_=false;this.zoomed_y_=false;d.innerHTML="";if(d.style.width==""&&b.width){d.style.width=b.width+"px"}if(d.style.height==""&&b.height){d.style.height=b.height+"px"}if(d.style.height==""&&d.clientHeight==0){d.style.height=Dygraph.DEFAULT_HEIGHT+"px";if(d.style.width==""){d.style.width=Dygraph.DEFAULT_WIDTH+"px"}}this.width_=d.clientWidth;this.height_=d.clientHeight;if(b.stackedGraph){b.fillGraph=true}this.user_attrs_={};Dygraph.update(this.user_attrs_,b);this.attrs_={};Dygraph.updateDeep(this.attrs_,Dygraph.DEFAULT_ATTRS);this.boundaryIds_=[];this.createInterface_();this.start_()};Dygraph.prototype.isZoomed=function(a){if(a==null){return this.zoomed_x_||this.zoomed_y_}if(a=="x"){return this.zoomed_x_}if(a=="y"){return this.zoomed_y_}throw"axis parameter to Dygraph.isZoomed must be missing, 'x' or 'y'."};Dygraph.prototype.toString=function(){var a=this.maindiv_;var b=(a&&a.id)?a.id:a;return"[Dygraph "+b+"]"};Dygraph.prototype.attr_=function(b,a){if(a&&typeof(this.user_attrs_[a])!="undefined"&&this.user_attrs_[a]!=null&&typeof(this.user_attrs_[a][b])!="undefined"){return this.user_attrs_[a][b]}else{if(typeof(this.user_attrs_[b])!="undefined"){return this.user_attrs_[b]}else{if(typeof(this.attrs_[b])!="undefined"){return this.attrs_[b]}else{return null}}}};Dygraph.prototype.optionsViewForAxis_=function(b){var a=this;return function(c){var d=a.user_attrs_.axes;if(d&&d[b]&&d[b][c]){return d[b][c]}if(typeof(a.user_attrs_[c])!="undefined"){return a.user_attrs_[c]}d=a.attrs_.axes;if(d&&d[b]&&d[b][c]){return d[b][c]}if(b=="y"&&a.axes_[0].hasOwnProperty(c)){return a.axes_[0][c]}else{if(b=="y2"&&a.axes_[1].hasOwnProperty(c)){return a.axes_[1][c]}}return a.attr_(c)}};Dygraph.prototype.rollPeriod=function(){return this.rollPeriod_};Dygraph.prototype.xAxisRange=function(){return this.dateWindow_?this.dateWindow_:this.xAxisExtremes()};Dygraph.prototype.xAxisExtremes=function(){var b=this.rawData_[0][0];var a=this.rawData_[this.rawData_.length-1][0];return[b,a]};Dygraph.prototype.yAxisRange=function(a){if(typeof(a)=="undefined"){a=0}if(a<0||a>=this.axes_.length){return null}var b=this.axes_[a];return[b.computedValueRange[0],b.computedValueRange[1]].."]]"..[[};Dygraph.prototype.yAxisRanges=function(){var a=[];for(var b=0;b<this.axes_.length;b++){a.push(this.yAxisRange(b))}return a};Dygraph.prototype.toDomCoords=function(a,c,b){return[this.toDomXCoord(a),this.toDomYCoord(c,b)]};Dygraph.prototype.toDomXCoord=function(b){if(b==null){return null}var c=this.plotter_.area;var a=this.xAxisRange();return c.x+(b-a[0])/(a[1]-a[0])*c.w};Dygraph.prototype.toDomYCoord=function(d,a){var c=this.toPercentYCoord(d,a);if(c==null){return null}var b=this.plotter_.area;return b.y+c*b.h};Dygraph.prototype.toDataCoords=function(a,c,b){return[this.toDataXCoord(a),this.toDataYCoord(c,b)]};Dygraph.prototype.toDataXCoord=function(b){if(b==null){return null}var c=this.plotter_.area;var a=this.xAxisRange();return a[0]+(b-c.x)/c.w*(a[1]-a[0])};Dygraph.prototype.toDataYCoord=function(h,b){if(h==null){return null}var c=this.plotter_.area;var g=this.yAxisRange(b);if(typeof(b)=="undefined"){b=0}if(!this.axes_[b].logscale){return g[0]+(c.y+c.h-h)/c.h*(g[1]-g[0])}else{var f=(h-c.y)/c.h;var a=Dygraph.log10(g[1]);var e=a-(f*(a-Dygraph.log10(g[0])));var d=Math.pow(Dygraph.LOG_SCALE,e);return d}};Dygraph.prototype.toPercentYCoord=function(f,b){if(f==null){return null}if(typeof(b)=="undefined"){b=0}var c=this.plotter_.area;var e=this.yAxisRange(b);var d;if(!this.axes_[b].logscale){d=(e[1]-f)/(e[1]-e[0])}else{var a=Dygraph.log10(e[1]);d=(a-Dygraph.log10(f))/(a-Dygraph.log10(e[0]))}return d};Dygraph.prototype.toPercentXCoord=function(b){if(b==null){return null}var a=this.xAxisRange();return(b-a[0])/(a[1]-a[0])};Dygraph.prototype.numColumns=function(){return this.rawData_[0].length};Dygraph.prototype.numRows=function(){return this.rawData_.length};Dygraph.prototype.getValue=function(b,a){if(b<0||b>this.rawData_.length){return null}if(a<0||a>this.rawData_[b].length){return null}return this.rawData_[b][a]};Dygraph.prototype.createInterface_=function(){var a=this.maindiv_;this.graphDiv=document.createElement("div");this.graphDiv.style.width=this.width_+"px";this.graphDiv.style.height=this.height_+"px";a.appendChild(this.graphDiv);this.canvas_=Dygraph.createCanvas();this.canvas_.style.position="absolute";this.canvas_.width=this.width_;this.canvas_.height=this.height_;this.canvas_.style.width=this.width_+"px";this.canvas_.style.height=this.height_+"px";this.canvas_ctx_=Dygraph.getContext(this.canvas_);this.hidden_=this.createPlotKitCanvas_(this.canvas_);this.hidden_ctx_=Dygraph.getContext(this.hidden_);if(this.attr_("showRangeSelector")){this.rangeSelector_=new DygraphRangeSelector(this)}this.graphDiv.appendChild(this.hidden_);this.graphDiv.appendChild(this.canvas_);this.mouseEventElement_=this.createMouseEventElement_();this.layout_=new DygraphLayout(this);if(this.rangeSelector_){this.rangeSelector_.addToGraph(this.graphDiv,this.layout_)}this.layout_=new DygraphLayout(this);if(this.rangeSelector_){this.rangeSelector_.addToGraph(this.graphDiv,this.layout_)}var b=this;Dygraph.addEvent(this.mouseEventElement_,"mousemove",function(c){b.mouseMove_(c)});Dygraph.addEvent(this.mouseEventElement_,"mouseout",function(c){b.mouseOut_(c)});this.createStatusMessage_();this.createDragInterface_();Dygraph.addEvent(window,"resize",function(c){b.resize()})};Dygraph.prototype.destroy=function(){var a=function(c){while(c.hasChildNodes()){a(c.firstChild);c.removeChild(c.firstChild)}};a(this.maindiv_);var b=function(c){for(var d in c){if(typeof(c[d])==="object"){c[d]=null}}};b(this.layout_);b(this.plotter_);b(this)};Dygraph.prototype.createPlotKitCanvas_=function(a){var b=Dygraph.createCanvas();b.style.position="absolute";b.style.top=a.style.top;b.style.left=a.style.left;b.width=this.width_;b.height=this.height_;b.style.width=this.width_+"px";b.style.height=this.height_+"px";return b};Dygraph.prototype.createMouseEventElement_=function(){if(this.isUsingExcanvas_){var a=document.createElement("div");a.style.position="absolute";a.style.backgroundColor="white";a.style.filter="alpha(opacity=0)";a.style.width=this.width_+"px";a.style.height=this.height_+"px";this.graphDiv.appendChild(a);return a}else{return this.canvas_}};Dygraph.prototype.setColors_=function(){var e=this.attr_("labels").length-1;this.colors_=[];var a=this.attr_("colors");if(!a){var c=this.attr_("colorSaturation")||1;var b=this.attr_("colorValue")||0.5;var j=Math.ceil(e/2);for(var d=1;d<=e;d++){if(!this.visibility()[d-1]){continue}var g=d%2?Math.ceil(d/2):(j+d/2);var f=(1*g/(1+e));this.colors_.push(Dygraph.hsvToRGB(f,c,b))}}else{for(var d=0;d<e;d++){if(!this.visibility()[d]){continue}var h=a[d%a.length];this.colors_.push(h)}}this.plotter_.setColors(this.colors_)};Dygraph.prototype.getColors=function(){return this.colors_};Dygraph.prototype.createStatusMessage_=function(){var d=this.user_attrs_.labelsDiv;if(d&&null!=d&&(typeof(d)=="string"||d instanceof String)){this.user_attrs_.labelsDiv=document.getElementById(d)}if(!this.attr_("labelsDiv")){var a=this.attr_("labelsDivWidth");var c={position:"absolute",fontSize:"14px",zIndex:10,width:a+"px",top:"0px",left:(this.width_-a-2)+"px",background:"white",textAlign:"left",overflow:"hidden"};Dygraph.update(c,this.attr_("labelsDivStyles"));var e=document.createElement("div");e.className="dygraph-legend";for(var b in c){if(c.hasOwnProperty(b)){e.style[b]=c[b]}}this.graphDiv.appendChild(e);this.attrs_.labelsDiv=e}};Dygraph.prototype.positionLabelsDiv_=function(){if(this.user_attrs_.hasOwnProperty("labelsDiv")){return}var a=this.plotter_.area;var b=this.attr_("labelsDiv");b.style.left=a.x+a.w-this.attr_("labelsDivWidth")-1+"px";b.style.top=a.y+"px"};Dygraph.prototype.createRollInterface_=function(){if(!this.roller_){this.roller_=document.createElement("input");this.roller_.type="text";this.roller_.style.display="none";this.graphDiv.appendChild(this.roller_)}var e=this.attr_("showRoller")?"block":"none";var d=this.plotter_.area;var b={position:"absolute",zIndex:10,top:(d.y+d.h-25)+"px",left:(d.x+1)+"px",display:e};this.roller_.size="2";this.roller_.value=this.rollPeriod_;for(var a in b){if(b.hasOwnProperty(a)){this.roller_.style[a]=b[a]}}var c=this;this.roller_.onchange=function(){c.adjustRoll(c.roller_.value)}};Dygraph.prototype.dragGetX_=function(b,a){return Dygraph.pageX(b)-a.px};Dygraph.prototype.dragGetY_=function(b,a){return Dygraph.pageY(b)-a.py};Dygraph.prototype.createDragInterface_=function(){var c={isZooming:false,isPanning:false,is2DPan:false,dragStartX:null,dragStartY:null,dragEndX:null,dragEndY:null,dragDirection:null,prevEndX:null,prevEndY:null,prevDragDirection:null,initialLeftmostDate:null,xUnitsPerPixel:null,dateRange:null,px:0,py:0,boundedDates:null,boundedValues:null,initializeMouseDown:function(i,h,f){if(i.preventDefault){i.preventDefault()}else{i.returnValue=false;i.cancelBubble=true}f.px=Dygraph.findPosX(h.canvas_);f.py=Dygraph.findPosY(h.canvas_);f.dragStartX=h.dragGetX_(i,f);f.dragStartY=h.dragGetY_(i,f)}};var e=this.attr_("interactionModel");var b=this;var d=function(f){return function(g){f(g,b,c)}};for(var a in e){if(!e.hasOwnProperty(a)){continue}Dygraph.addEvent(this.mouseEventElement_,a,d(e[a]))}Dygraph.addEvent(document,"mouseup",function(g){if(c.isZooming||c.isPanning){c.isZooming=false;c.dragStartX=null;c.dragStartY=null}if(c.isPanning){c.isPanning=false;c.draggingDate=null;c.dateRange=null;for(var f=0;f<b.axes_.length;f++){delete b.axes_[f].draggingValue;delete b.axes_[f].dragValueRange}}})};Dygraph.prototype.drawZoomRect_=function(e,c,i,b,g,a,f,d){var h=this.canvas_ctx_;if(a==Dygraph.HORIZONTAL){h.clearRect(Math.min(c,f),this.layout_.getPlotArea().y,Math.abs(c-f),this.layout_.getPlotArea().h)}else{if(a==Dygraph.VERTICAL){h.clearRect(this.layout_.getPlotArea().x,Math.min(b,d),this.layout_.getPlotArea().w,Math.abs(b-d))}}if(e==Dygraph.HORIZONTAL){if(i&&c){h.fillStyle="rgba(128,128,128,0.33)";h.fillRect(Math.min(c,i),this.layout_.getPlotArea().y,Math.abs(i-c),this.layout_.getPlotArea().h)}}else{if(e==Dygraph.VERTICAL){if(g&&b){h.fillStyle="rgba(128,128,128,0.33)";h.fillRect(this.layout_.getPlotArea().x,Math.min(b,g),this.layout_.getPlotArea().w,Math.abs(g-b))}}}if(this.isUsingExcanvas_){this.currentZoomRectArgs_=[e,c,i,b,g,0,0,0]}};Dygraph.prototype.clearZoomRect_=function(){this.currentZoomRectArgs_=null;this.canvas_ctx_.clearRect(0,0,this.canvas_.width,this.canvas_.height)};Dygraph.prototype.doZoomX_=function(c,a){this.currentZoomRectArgs_=null;var b=this.toDataXCoord(c);var d=this.toDataXCoord(a);this.doZoomXDates_(b,d)};Dygraph.zoomAnimationFunction=function(c,b){var a=1.5;return(1-Math.pow(a,-c))/(1-Math.pow(a,-b))};Dygraph.prototype.doZoomXDates_=function(c,e){var a=this.xAxisRange();var d=[c,e];this.zoomed_x_=true;var b=this;this.doAnimatedZoom(a,d,null,null,function(){if(b.attr_("zoomCallback")){b.attr_("zoomCallback")(c,e,b.yAxisRanges())}})};Dygraph.prototype.doZoomY_=function(h,f){this.currentZoomRectArgs_=null;var c=this.yAxisRanges();var b=[];for(var e=0;e<this.axes_.length;e++){var d=this.toDataYCoord(h,e);var a=this.toDataYCoord(f,e);b.push([a,d])}this.zoomed_y_=true;var g=this;this.doAnimatedZoom(null,null,c,b,function(){if(g.attr_("zoomCallback")){var i=g.xAxisRange();var j=g.yAxisRange();g.attr_("zoomCallback")(i[0],i[1],g.yAxisRanges())}})};Dygraph.prototype.doUnzoom_=function(){var c=false,d=false,a=false;if(this.dateWindow_!=null){c=true;d=true}for(var f=0;f<this.axes_.length;f++){if(this.axes_[f].valueWindow!=null){c=true;a=true}}this.clearSelection();if(c){this.zoomed_x_=false;this.zoomed_y_=false;var e=this.rawData_[0][0];var b=this.rawData_[this.rawData_.length-1][0];if(!this.attr_("animatedZooms")){this.dateWindow_=null;for(var f=0;f<this.axes_.length;f++){if(this.axes_[f].valueWindow!=null){delete this.axes_[f].valueWindow}}this.drawGraph_();if(this.attr_("zoomCallback")){this.attr_("zoomCallback")(e,b,this.yAxisRanges())}return}var k=null,l=null,j=null,g=null;if(d){k=this.xAxisRange();l=[e,b]}if(a){j=this.yAxisRanges();var m=this.gatherDatasets_(this.rolledSeries_,null);var n=m[1];this.computeYAxisRanges_(n);g=[];for(var f=0;f<this.axes_.length;f++){g.push(this.axes_[f].extremeRange)}}var h=this;this.doAnimatedZoom(k,l,j,g,function(){h.dateWindow_=null;for(var o=0;o<h.axes_.length;o++){if(h.axes_[o].valueWindow!=null){delete h.axes_[o].valueWindow}}if(h.attr_("zoomCallback")){h.attr_("zoomCallback")(e,b,h.yAxisRanges())}})}};Dygraph.prototype.doAnimatedZoom=function(a,e,b,c,m){var i=this.attr_("animatedZooms")?Dygraph.ANIMATION_STEPS:1;var l=[];var k=[];if(a!=null&&e!=null){for(var f=1;f<=i;f++){var d=Dygraph.zoomAnimationFunction(f,i);l[f-1]=[a[0]*(1-d)+d*e[0],a[1]*(1-d)+d*e[1]].."]]"..[[}}if(b!=null&&c!=null){for(var f=1;f<=i;f++){var d=Dygraph.zoomAnimationFunction(f,i);var n=[];for(var g=0;g<this.axes_.length;g++){n.push([b[g][0]*(1-d)+d*c[g][0],b[g][1]*(1-d)+d*c[g][1]].."]]"..[[)}k[f-1]=n}}var h=this;Dygraph.repeatAndCleanup(function(p){if(k.length){for(var o=0;o<h.axes_.length;o++){var j=k[p][o];h.axes_[o].valueWindow=[j[0],j[1]].."]]"..[[}}if(l.length){h.dateWindow_=l[p]}h.drawGraph_()},i,Dygraph.ANIMATION_DURATION/i,m)};Dygraph.prototype.mouseMove_=function(b){var s=this.layout_.points;if(s===undefined){return}var a=Dygraph.pageX(b)-Dygraph.findPosX(this.mouseEventElement_);var m=-1;var j=-1;var q=1e+100;var r=-1;for(var f=0;f<s.length;f++){var o=s[f];if(o==null){continue}var h=Math.abs(o.canvasx-a);if(h>q){continue}q=h;r=f}if(r>=0){m=s[r].xval}this.selPoints_=[];var d=s.length;if(!this.attr_("stackedGraph")){for(var f=0;f<d;f++){if(s[f].xval==m){this.selPoints_.push(s[f])}}}else{var g=0;for(var f=d-1;f>=0;f--){if(s[f].xval==m){var c={};for(var e in s[f]){c[e]=s[f][e]}c.yval-=g;g+=c.yval;this.selPoints_.push(c)}}this.selPoints_.reverse()}if(this.attr_("highlightCallback")){var n=this.lastx_;if(n!==null&&m!=n){this.attr_("highlightCallback")(b,m,this.selPoints_,this.idxToRow_(r))}}this.lastx_=m;this.updateSelection_()};Dygraph.prototype.idxToRow_=function(a){if(a<0){return -1}for(var b in this.layout_.datasets){if(a<this.layout_.datasets[b].length){return this.boundaryIds_[0][0]+a}a-=this.layout_.datasets[b].length}return -1};Dygraph.prototype.generateLegendHTML_=function(o,p){if(typeof(o)==="undefined"){if(this.attr_("legend")!="always"){return""}var b=this.attr_("labelsSeparateLines");var h=this.attr_("labels");var f="";for(var e=1;e<h.length;e++){if(!this.visibility()[e-1]){continue}var n=this.plotter_.colors[h[e]].."]]"..[[;if(f!=""){f+=(b?"<br/>":" ")}f+="<b><span style='color: "+n+";'>&mdash;"+h[e]+"</span></b>"}return f}var m=this.optionsViewForAxis_("x");var j=m("valueFormatter");var f=j(o,m,this.attr_("labels")[0],this)+":";var d=[];var l=this.numAxes();for(var e=0;e<l;e++){d[e]=this.optionsViewForAxis_("y"+(e?1+e:""))}var q=this.attr_("labelsShowZeroValues");var b=this.attr_("labelsSeparateLines");for(var e=0;e<this.selPoints_.length;e++){var r=this.selPoints_[e];if(r.yval==0&&!q){continue}if(!Dygraph.isOK(r.canvasy)){continue}if(b){f+="<br/>"}var g=d[this.seriesToAxisMap_[r.name]].."]]"..[[;var a=g("valueFormatter");var n=this.plotter_.colors[r.name];var k=a(r.yval,g,r.name,this);f+=" <b><span style='color: "+n+";'>"+r.name+"</span></b>:"+k}return f};Dygraph.prototype.setLegendHTML_=function(a,d){var c=this.generateLegendHTML_(a,d);var b=this.attr_("labelsDiv");if(b!==null){b.innerHTML=c}else{if(typeof(this.shown_legend_error_)=="undefined"){this.error("labelsDiv is set to something nonexistent; legend will not be shown.");this.shown_legend_error_=true}}};Dygraph.prototype.updateSelection_=function(){var h=this.canvas_ctx_;if(this.previousVerticalX_>=0){var e=0;var f=this.attr_("labels");for(var d=1;d<f.length;d++){var b=this.attr_("highlightCircleSize",f[d]);if(b>e){e=b}}var g=this.previousVerticalX_;h.clearRect(g-e-1,0,2*e+2,this.height_)}if(this.isUsingExcanvas_&&this.currentZoomRectArgs_){Dygraph.prototype.drawZoomRect_.apply(this,this.currentZoomRectArgs_)}if(this.selPoints_.length>0){if(this.attr_("showLabelsOnHighlight")){this.setLegendHTML_(this.lastx_,this.selPoints_)}var c=this.selPoints_[0].canvasx;h.save();for(var d=0;d<this.selPoints_.length;d++){var j=this.selPoints_[d];if(!Dygraph.isOK(j.canvasy)){continue}var a=this.attr_("highlightCircleSize",j.name);h.beginPath();h.fillStyle=this.plotter_.colors[j.name];h.arc(c,j.canvasy,a,0,2*Math.PI,false);h.fill()}h.restore();this.previousVerticalX_=c}};Dygraph.prototype.setSelection=function(c){this.selPoints_=[];var d=0;if(c!==false){c=c-this.boundaryIds_[0][0]}if(c!==false&&c>=0){for(var b in this.layout_.datasets){if(c<this.layout_.datasets[b].length){var a=this.layout_.points[d+c];if(this.attr_("stackedGraph")){a=this.layout_.unstackPointAtIndex(d+c)}this.selPoints_.push(a)}d+=this.layout_.datasets[b].length}}if(this.selPoints_.length){this.lastx_=this.selPoints_[0].xval;this.updateSelection_()}else{this.clearSelection()}};Dygraph.prototype.mouseOut_=function(a){if(this.attr_("unhighlightCallback")){this.attr_("unhighlightCallback")(a)}if(this.attr_("hideOverlayOnMouseOut")){this.clearSelection()}};Dygraph.prototype.clearSelection=function(){this.canvas_ctx_.clearRect(0,0,this.width_,this.height_);this.setLegendHTML_();this.selPoints_=[];this.lastx_=-1};Dygraph.prototype.getSelection=function(){if(!this.selPoints_||this.selPoints_.length<1){return -1}for(var a=0;a<this.layout_.points.length;a++){if(this.layout_.points[a].x==this.selPoints_[0].x){return a+this.boundaryIds_[0][0]}}return -1};Dygraph.prototype.loadedEvent_=function(a){this.rawData_=this.parseCSV_(a);this.predraw_()};Dygraph.prototype.addXTicks_=function(){var a;if(this.dateWindow_){a=[this.dateWindow_[0],this.dateWindow_[1]].."]]"..[[}else{a=[this.rawData_[0][0],this.rawData_[this.rawData_.length-1][0]].."]]"..[[}var c=this.optionsViewForAxis_("x");var b=c("ticker")(a[0],a[1],this.width_,c,this);this.layout_.setXTicks(b)};Dygraph.prototype.extremeValues_=function(d){var h=null,f=null;var b=this.attr_("errorBars")||this.attr_("customBars");if(b){for(var c=0;c<d.length;c++){var g=d[c][1][0];if(!g){continue}var a=g-d[c][1][1];var e=g+d[c][1][2];if(a>g){a=g}if(e<g){e=g}if(f==null||e>f){f=e}if(h==null||a<h){h=a}}}else{for(var c=0;c<d.length;c++){var g=d[c][1];if(g===null||isNaN(g)){continue}if(f==null||g>f){f=g}if(h==null||g<h){h=g}}}return[h,f]};Dygraph.prototype.predraw_=function(){var f=new Date();this.computeYAxes_();if(this.plotter_){this.plotter_.clear()}this.plotter_=new DygraphCanvasRenderer(this,this.hidden_,this.hidden_ctx_,this.layout_);this.createRollInterface_();this.positionLabelsDiv_();if(this.rangeSelector_){this.rangeSelector_.renderStaticLayer()}this.rolledSeries_=[null];for(var c=1;c<this.rawData_[0].length;c++){var e=this.attr_("connectSeparatedPoints",c);var d=this.attr_("logscale",c);var b=this.extractSeries_(this.rawData_,c,d,e);b=this.rollingAverage(b,this.rollPeriod_);this.rolledSeries_.push(b)}this.drawGraph_();var a=new Date();this.drawingTimeMs_=(a-f)};Dygraph.prototype.gatherDatasets_=function(w,c){var s=[];var b=[];var e=[];var a={};var m=w.length-1;for(var u=m;u>=1;u--){if(!this.visibility()[u-1]){continue}var h=[];for(var t=0;t<w[u].length;t++){h.push(w[u][t])}var o=this.attr_("errorBars")||this.attr_("customBars");if(c){var A=c[0];var f=c[1];var p=[];var d=null,z=null;for(var r=0;r<h.length;r++){if(h[r][0]>=A&&d===null){d=r}if(h[r][0]<=f){z=r}}if(d===null){d=0}if(d>0){d--}if(z===null){z=h.length-1}if(z<h.length-1){z++}s[u-1]=[d,z];for(var r=d;r<=z;r++){p.push(h[r])}h=p}else{s[u-1]=[0,h.length-1]}var n=this.extremeValues_(h);if(o){for(var t=0;t<h.length;t++){val=[h[t][0],h[t][1][0],h[t][1][1],h[t][1][2]].."]]"..[[;h[t]=val}}else{if(this.attr_("stackedGraph")){var q=h.length;var y;for(var t=0;t<q;t++){var g=h[t][0];if(b[g]===undefined){b[g]=0}y=h[t][1];b[g]+=y;h[t]=[g,b[g]].."]]"..[[;if(b[g]>n[1]){n[1]=b[g]}if(b[g]<n[0]){n[0]=b[g]}}}}var v=this.attr_("labels")[u];a[v]=n;e[u]=h}return[e,a,s]};Dygraph.prototype.drawGraph_=function(l){var b=new Date();if(typeof(l)==="undefined"){l=true}var g=this.is_initial_draw_;this.is_initial_draw_=false;var d=null,a=null;this.layout_.removeAllDatasets();this.setColors_();this.attrs_.pointSize=0.5*this.attr_("highlightCircleSize");var j=this.gatherDatasets_(this.rolledSeries_,this.dateWindow_);var f=j[0];var k=j[1];this.boundaryIds_=j[2];for(var h=1;h<f.length;h++){if(!this.visibility()[h-1]){continue}this.layout_.addDataset(this.attr_("labels")[h],f[h])}this.computeYAxisRanges_(k);this.layout_.setYAxes(this.axes_);this.addXTicks_();var c=this.zoomed_x_;this.layout_.setDateWindow(this.dateWindow_);this.zoomed_x_=c;this.layout_.evaluateWithError();this.renderGraph_(g,false);if(this.attr_("timingName")){var e=new Date();if(console){console.log(this.attr_("timingName")+" - drawGraph: "+(e-b)+"ms")}}};Dygraph.prototype.renderGraph_=function(a,b){this.plotter_.clear();this.plotter_.render();this.canvas_.getContext("2d").clearRect(0,0,this.canvas_.width,this.canvas_.height);if(a){this.setLegendHTML_()}else{if(b){if(typeof(this.selPoints_)!=="undefined"&&this.selPoints_.length){this.clearSelection()}else{this.clearSelection()}}}if(this.rangeSelector_){this.rangeSelector_.renderInteractiveLayer()}if(this.attr_("drawCallback")!==null){this.attr_("drawCallback")(this,a)}};Dygraph.prototype.computeYAxes_=function(){var d;if(this.axes_!=undefined&&this.user_attrs_.hasOwnProperty("valueRange")==false){d=[];for(var l=0;l<this.axes_.length;l++){d.push(this.axes_[l].valueWindow)}}this.axes_=[{yAxisId:0,g:this}];this.seriesToAxisMap_={};var j=this.attr_("labels");var g={};for(var h=1;h<j.length;h++){g[j[h]].."]]"..[[=(h-1)}var f=["includeZero","valueRange","labelsKMB","labelsKMG2","pixelsPerYLabel","yAxisLabelWidth","axisLabelFontSize","axisTickSize","logscale"];for(var h=0;h<f.length;h++){var e=f[h];var q=this.attr_(e);if(q){this.axes_[0][e]=q}}for(var m in g){if(!g.hasOwnProperty(m)){continue}var c=this.attr_("axis",m);if(c==null){this.seriesToAxisMap_[m]=0;continue}if(typeof(c)=="object"){var a={};Dygraph.update(a,this.axes_[0]);Dygraph.update(a,{valueRange:null});var p=this.axes_.length;a.yAxisId=p;a.g=this;Dygraph.update(a,c);this.axes_.push(a);this.seriesToAxisMap_[m]=p}}for(var m in g){if(!g.hasOwnProperty(m)){continue}var c=this.attr_("axis",m);if(typeof(c)=="string"){if(!this.seriesToAxisMap_.hasOwnProperty(c)){this.error("Series "+m+" wants to share a y-axis with series "+c+", which does not define its own axis.");return null}var n=this.seriesToAxisMap_[c];this.seriesToAxisMap_[m]=n}}var o={};var b=this.visibility();for(var h=1;h<j.length;h++){var r=j[h];if(b[h-1]){o[r]=this.seriesToAxisMap_[r]}}this.seriesToAxisMap_=o;if(d!=undefined){for(var l=0;l<d.length;l++){this.axes_[l].valueWindow=d[l]}}};Dygraph.prototype.numAxes=function(){var c=0;for(var b in this.seriesToAxisMap_){if(!this.seriesToAxisMap_.hasOwnProperty(b)){continue}var a=this.seriesToAxisMap_[b];if(a>c){c=a}}return 1+c};Dygraph.prototype.axisPropertiesForSeries=function(a){return this.axes_[this.seriesToAxisMap_[a]].."]]"..[[};Dygraph.prototype.computeYAxisRanges_=function(a){var g=[];for(var h in this.seriesToAxisMap_){if(!this.seriesToAxisMap_.hasOwnProperty(h)){continue}var p=this.seriesToAxisMap_[h];while(g.length<=p){g.push([])}g[p].push(h)}for(var u=0;u<this.axes_.length;u++){var b=this.axes_[u];if(!g[u]){b.extremeRange=[0,1]}else{var h=g[u];var x=Infinity;var w=-Infinity;var o,m;for(var s=0;s<h.length;s++){o=a[h[s]].."]]"..[[[0];if(o!=null){x=Math.min(o,x)}m=a[h[s]].."]]"..[[[1];if(m!=null){w=Math.max(m,w)}}if(b.includeZero&&x>0){x=0}if(x==Infinity){x=0}if(w==-Infinity){w=0}var t=w-x;if(t==0){t=w}var d;var z;if(b.logscale){var d=w+0.1*t;var z=x}else{var d=w+0.1*t;var z=x-0.1*t;if(!this.attr_("avoidMinZero")){if(z<0&&x>=0){z=0}if(d>0&&w<=0){d=0}}if(this.attr_("includeZero")){if(w<0){d=0}if(x>0){z=0}}}b.extremeRange=[z,d]}if(b.valueWindow){b.computedValueRange=[b.valueWindow[0],b.valueWindow[1]].."]]"..[[}else{if(b.valueRange){b.computedValueRange=[b.valueRange[0],b.valueRange[1]].."]]"..[[}else{b.computedValueRange=b.extremeRange}}var n=this.optionsViewForAxis_("y"+(u?"2":""));var y=n("ticker");if(u==0||b.independentTicks){b.ticks=y(b.computedValueRange[0],b.computedValueRange[1],this.height_,n,this)}else{var l=this.axes_[0];var e=l.ticks;var f=l.computedValueRange[1]-l.computedValueRange[0];var A=b.computedValueRange[1]-b.computedValueRange[0];var c=[];for(var r=0;r<e.length;r++){var q=(e[r].v-l.computedValueRange[0])/f;var v=b.computedValueRange[0]+q*A;c.push(v)}b.ticks=y(b.computedValueRange[0],b.computedValueRange[1],this.height_,n,this,c)}}};Dygraph.prototype.extractSeries_=function(h,e,g,f){var d=[];for(var c=0;c<h.length;c++){var b=h[c][0];var a=h[c][e];if(g){if(a<=0){a=null}d.push([b,a])}else{if(a!=null||!f){d.push([b,a])}}}return d};Dygraph.prototype.rollingAverage=function(m,d){if(m.length<2){return m}var d=Math.min(d,m.length);var b=[];var s=this.attr_("sigma");if(this.fractions_){var k=0;var h=0;var e=100;for(var x=0;x<m.length;x++){k+=m[x][1][0];h+=m[x][1][1];if(x-d>=0){k-=m[x-d][1][0];h-=m[x-d][1][1]}var B=m[x][0];var v=h?k/h:0;if(this.attr_("errorBars")){if(this.wilsonInterval_){if(h){var t=v<0?0:v,u=h;var A=s*Math.sqrt(t*(1-t)/u+s*s/(4*u*u));var a=1+s*s/h;var F=(t+s*s/(2*h)-A)/a;var o=(t+s*s/(2*h)+A)/a;b[x]=[B,[t*e,(t-F)*e,(o-t)*e]].."]]"..[[}else{b[x]=[B,[0,0,0]].."]]"..[[}}else{var z=h?s*Math.sqrt(v*(1-v)/h):1;b[x]=[B,[e*v,e*z,e*z]].."]]"..[[}}else{b[x]=[B,e*v]}}}else{if(this.attr_("customBars")){var F=0;var C=0;var o=0;var g=0;for(var x=0;x<m.length;x++){var E=m[x][1];var l=E[1];b[x]=[m[x][0],[l,l-E[0],E[2]-l]].."]]"..[[;if(l!=null&&!isNaN(l)){F+=E[0];C+=l;o+=E[2];g+=1}if(x-d>=0){var r=m[x-d];if(r[1][1]!=null&&!isNaN(r[1][1])){F-=r[1][0];C-=r[1][1];o-=r[1][2];g-=1}}if(g){b[x]=[m[x][0],[1*C/g,1*(C-F)/g,1*(o-C)/g]].."]]"..[[}else{b[x]=[m[x][0],[null,null,null]].."]]"..[[}}}else{var q=Math.min(d-1,m.length-2);if(!this.attr_("errorBars")){if(d==1){return m}for(var x=0;x<m.length;x++){var c=0;var D=0;for(var w=Math.max(0,x-d+1);w<x+1;w++){var l=m[w][1];if(l==null||isNaN(l)){continue}D++;c+=m[w][1]}if(D){b[x]=[m[x][0],c/D]}else{b[x]=[m[x][0],null]}}}else{for(var x=0;x<m.length;x++){var c=0;var f=0;var D=0;for(var w=Math.max(0,x-d+1);w<x+1;w++){var l=m[w][1][0];if(l==null||isNaN(l)){continue}D++;c+=m[w][1][0];f+=Math.pow(m[w][1][1],2)}if(D){var z=Math.sqrt(f)/D;b[x]=[m[x][0],[c/D,s*z,s*z]].."]]"..[[}else{b[x]=[m[x][0],[null,null,null]].."]]"..[[}}}}}return b};Dygraph.prototype.detectTypeFromString_=function(b){var a=false;var c=b.indexOf("-");if((c>0&&(b[c-1]!="e"&&b[c-1]!="E"))||b.indexOf("/")>=0||isNaN(parseFloat(b))){a=true}else{if(b.length==8&&b>"19700101"&&b<"20371231"){a=true}}if(a){this.attrs_.xValueParser=Dygraph.dateParser;this.attrs_.axes.x.valueFormatter=Dygraph.dateString_;this.attrs_.axes.x.ticker=Dygraph.dateTicker;this.attrs_.axes.x.axisLabelFormatter=Dygraph.dateAxisFormatter}else{this.attrs_.xValueParser=function(d){return parseFloat(d)};this.attrs_.axes.x.valueFormatter=function(d){return d};this.attrs_.axes.x.ticker=Dygraph.numericTicks;this.attrs_.axes.x.axisLabelFormatter=this.attrs_.axes.x.valueFormatter}};Dygraph.prototype.parseFloat_=function(a,c,b){var e=parseFloat(a);if(!isNaN(e)){return e}if(/^ *$/.test(a)){return null}if(/^ *nan *$/i.test(a)){return NaN}var d="Unable to parse '"+a+"' as a number";if(b!==null&&c!==null){d+=" on line "+(1+c)+" ('"+b+"') of CSV."}this.error(d);return null};Dygraph.prototype.parseCSV_=function(s){var r=[];var a=s.split("\n");var p=this.attr_("delimiter");if(a[0].indexOf(p)==-1&&a[0].indexOf("\t")>=0){p="\t"}var b=0;if(!("labels" in this.user_attrs_)){b=1;this.attrs_.labels=a[0].split(p)}var o=0;var m;var q=false;var c=this.attr_("labels").length;var f=false;for(var l=b;l<a.length;l++){var e=a[l];o=l;if(e.length==0){continue}if(e[0]=="#"){continue}var d=e.split(p);if(d.length<2){continue}var h=[];if(!q){this.detectTypeFromString_(d[0]);m=this.attr_("xValueParser");q=true}h[0]=m(d[0],this);if(this.fractions_){for(var k=1;k<d.length;k++){var g=d[k].split("/");if(g.length!=2){this.error('Expected fractional "num/den" values in CSV data but found a value \''+d[k]+"' on line "+(1+l)+" ('"+e+"') which is not of this form.");h[k]=[0,0]}else{h[k]=[this.parseFloat_(g[0],l,e),this.parseFloat_(g[1],l,e)]}}}else{if(this.attr_("errorBars")){if(d.length%2!=1){this.error("Expected alternating (value, stdev.) pairs in CSV data but line "+(1+l)+" has an odd number of values ("+(d.length-1)+"): '"+e+"'")}for(var k=1;k<d.length;k+=2){h[(k+1)/2]=[this.parseFloat_(d[k],l,e),this.parseFloat_(d[k+1],l,e)]}}else{if(this.attr_("customBars")){for(var k=1;k<d.length;k++){var t=d[k];if(/^ *$/.test(t)){h[k]=[null,null,null]}else{var g=t.split(";");if(g.length==3){h[k]=[this.parseFloat_(g[0],l,e),this.parseFloat_(g[1],l,e),this.parseFloat_(g[2],l,e)]}else{this.warning('When using customBars, values must be either blank or "low;center;high" tuples (got "'+t+'" on line '+(1+l))}}}}else{for(var k=1;k<d.length;k++){h[k]=this.parseFloat_(d[k],l,e)}}}}if(r.length>0&&h[0]<r[r.length-1][0]){f=true}if(h.length!=c){this.error("Number of columns in line "+l+" ("+h.length+") does not agree with number of labels ("+c+") "+e)}if(l==0&&this.attr_("labels")){var n=true;for(var k=0;n&&k<h.length;k++){if(h[k]){n=false}}if(n){this.warn("The dygraphs 'labels' option is set, but the first row of CSV data ('"+e+"') appears to also contain labels. Will drop the CSV labels and use the option labels.");continue}}r.push(h)}if(f){this.warn("CSV is out of order; order it correctly to speed loading.");r.sort(function(j,i){return j[0]-i[0]})}return r};Dygraph.prototype.parseArray_=function(b){if(b.length==0){this.error("Can't plot empty data set");return null}if(b[0].length==0){this.error("Data set cannot contain an empty row");return null}if(this.attr_("labels")==null){this.warn("Using default labels. Set labels explicitly via 'labels' in the options parameter");this.attrs_.labels=["X"];for(var a=1;a<b[0].length;a++){this.attrs_.labels.push("Y"+a)}}if(Dygraph.isDateLike(b[0][0])){this.attrs_.axes.x.valueFormatter=Dygraph.dateString_;this.attrs_.axes.x.axisLabelFormatter=Dygraph.dateAxisFormatter;this.attrs_.axes.x.ticker=Dygraph.dateTicker;var c=Dygraph.clone(b);for(var a=0;a<b.length;a++){if(c[a].length==0){this.error("Row "+(1+a)+" of data is empty");return null}if(c[a][0]==null||typeof(c[a][0].getTime)!="function"||isNaN(c[a][0].getTime())){this.error("x value in row "+(1+a)+" is not a Date");return null}c[a][0]=c[a][0].getTime()}return c}else{this.attrs_.axes.x.valueFormatter=function(d){return d};this.attrs_.axes.x.axisLabelFormatter=Dygraph.numberAxisLabelFormatter;this.attrs_.axes.x.ticker=Dygraph.numericTicks;return b}};Dygraph.prototype.parseDataTable_=function(v){var g=v.getNumberOfColumns();var f=v.getNumberOfRows();var e=v.getColumnType(0);if(e=="date"||e=="datetime"){this.attrs_.xValueParser=Dygraph.dateParser;this.attrs_.axes.x.valueFormatter=Dygraph.dateString_;this.attrs_.axes.x.ticker=Dygraph.dateTicker;this.attrs_.axes.x.axisLabelFormatter=Dygraph.dateAxisFormatter}else{if(e=="number"){this.attrs_.xValueParser=function(i){return parseFloat(i)};this.attrs_.axes.x.valueFormatter=function(i){return i};this.attrs_.axes.x.ticker=Dygraph.numericTicks;this.attrs_.axes.x.axisLabelFormatter=this.attrs_.axes.x.valueFormatter}else{this.error("only 'date', 'datetime' and 'number' types are supported for column 1 of DataTable input (Got '"+e+"')");return null}}var l=[];var s={};var r=false;for(var p=1;p<g;p++){var b=v.getColumnType(p);if(b=="number"){l.push(p)}else{if(b=="string"&&this.attr_("displayAnnotations")){var q=l[l.length-1];if(!s.hasOwnProperty(q)){s[q]=[p]}else{s[q].push(p)}r=true}else{this.error("Only 'number' is supported as a dependent type with Gviz. 'string' is only supported if displayAnnotations is true")}}}var t=[v.getColumnLabel(0)];for(var p=0;p<l.length;p++){t.push(v.getColumnLabel(l[p]));if(this.attr_("errorBars")){p+=1}}this.attrs_.labels=t;g=t.length;var u=[];var h=false;var a=[];for(var p=0;p<f;p++){var d=[];if(typeof(v.getValue(p,0))==="undefined"||v.getValue(p,0)===null){this.warn("Ignoring row "+p+" of DataTable because of undefined or null first column.");continue}if(e=="date"||e=="datetime"){d.push(v.getValue(p,0).getTime())}else{d.push(v.getValue(p,0))}if(!this.attr_("errorBars")){for(var n=0;n<l.length;n++){var c=l[n];d.push(v.getValue(p,c));if(r&&s.hasOwnProperty(c)&&v.getValue(p,s[c][0])!=null){var o={};o.series=v.getColumnLabel(c);o.xval=d[0];o.shortText=String.fromCharCode(65+a.length);o.text="";for(var m=0;m<s[c].length;m++){if(m){o.text+="\n"}o.text+=v.getValue(p,s[c][m])}a.push(o)}}for(var n=0;n<d.length;n++){if(!isFinite(d[n])){d[n]=null}}}else{for(var n=0;n<g-1;n++){d.push([v.getValue(p,1+2*n),v.getValue(p,2+2*n)])}}if(u.length>0&&d[0]<u[u.length-1][0]){h=true}u.push(d)}if(h){this.warn("DataTable is out of order; order it correctly to speed loading.");u.sort(function(j,i){return j[0]-i[0]})}this.rawData_=u;if(a.length>0){this.setAnnotations(a,true)}};Dygraph.prototype.start_=function(){if(typeof this.file_=="function"){this.loadedEvent_(this.file_())}else{if(Dygraph.isArrayLike(this.file_)){this.rawData_=this.parseArray_(this.file_);this.predraw_()}else{if(typeof this.file_=="object"&&typeof this.file_.getColumnRange=="function"){this.parseDataTable_(this.file_);this.predraw_()}else{if(typeof this.file_=="string"){if(this.file_.indexOf("\n")>=0){this.loadedEvent_(this.file_)}else{var b=new XMLHttpRequest();var a=this;b.onreadystatechange=function(){if(b.readyState==4){if(b.status==200||b.status==0){a.loadedEvent_(b.responseText)}}};b.open("GET",this.file_,true);b.send(null)}}else{this.error("Unknown data format: "+(typeof this.file_))}}}}};Dygraph.prototype.updateOptions=function(e,b){if(typeof(b)=="undefined"){b=false}var d=e.file;var c=Dygraph.mapLegacyOptions_(e);if("rollPeriod" in c){this.rollPeriod_=c.rollPeriod}if("dateWindow" in c){this.dateWindow_=c.dateWindow;if(!("isZoomedIgnoreProgrammaticZoom" in c)){this.zoomed_x_=c.dateWindow!=null}}if("valueRange" in c&&!("isZoomedIgnoreProgrammaticZoom" in c)){this.zoomed_y_=c.valueRange!=null}var a=Dygraph.isPixelChangingOptionList(this.attr_("labels"),c);Dygraph.updateDeep(this.user_attrs_,c);if(d){this.file_=d;if(!b){this.start_()}}else{if(!b){if(a){this.predraw_()}else{this.renderGraph_(false,false)}}}};Dygraph.mapLegacyOptions_=function(c){var a={};for(var b in c){if(b=="file"){continue}if(c.hasOwnProperty(b)){a[b]=c[b]}}var e=function(g,f,h){if(!a.axes){a.axes={}}if(!a.axes[g]){a.axes[g]={}}a.axes[g][f]=h};var d=function(f,g,h){if(typeof(c[f])!="undefined"){e(g,h,c[f]);delete a[f]}};d("xValueFormatter","x","valueFormatter");d("pixelsPerXLabel","x","pixelsPerLabel");d("xAxisLabelFormatter","x","axisLabelFormatter");d("xTicker","x","ticker");d("yValueFormatter","y","valueFormatter");d("pixelsPerYLabel","y","pixelsPerLabel");d("yAxisLabelFormatter","y","axisLabelFormatter");d("yTicker","y","ticker");return a};Dygraph.prototype.resize=function(d,b){if(this.resize_lock){return}this.resize_lock=true;if((d===null)!=(b===null)){this.warn("Dygraph.resize() should be called with zero parameters or two non-NULL parameters. Pretending it was zero.");d=b=null}var a=this.width_;var c=this.height_;if(d){this.maindiv_.style.width=d+"px";this.maindiv_.style.height=b+"px";this.width_=d;this.height_=b}else{this.width_=this.maindiv_.clientWidth;this.height_=this.maindiv_.clientHeight}if(a!=this.width_||c!=this.height_){this.maindiv_.innerHTML="";this.roller_=null;this.attrs_.labelsDiv=null;this.createInterface_();if(this.annotations_.length){this.layout_.setAnnotations(this.annotations_)}this.predraw_()}this.resize_lock=false};Dygraph.prototype.adjustRoll=function(a){this.rollPeriod_=a;this.predraw_()};Dygraph.prototype.visibility=function(){if(!this.attr_("visibility")){this.attrs_.visibility=[]}while(this.attr_("visibility").length<this.rawData_[0].length-1){this.attr_("visibility").push(true)}return this.attr_("visibility")};Dygraph.prototype.setVisibility=function(b,c){var a=this.visibility();if(b<0||b>=a.length){this.warn("invalid series number in setVisibility: "+b)}else{a[b]=c;this.predraw_()}};Dygraph.prototype.size=function(){return{width:this.width_,height:this.height_}};Dygraph.prototype.setAnnotations=function(b,a){Dygraph.addAnnotationRule();this.annotations_=b;this.layout_.setAnnotations(this.annotations_);if(!a){this.predraw_()}};Dygraph.prototype.annotations=function(){return this.annotations_};Dygraph.prototype.indexFromSetName=function(a){var c=this.attr_("labels");for(var b=0;b<c.length;b++){if(c[b]==a){return b}}return null};Dygraph.addAnnotationRule=function(){if(Dygraph.addedAnnotationCSS){return}var f="border: 1px solid black; background-color: white; text-align: center;";var e=document.createElement("style");e.type="text/css";document.getElementsByTagName("head")[0].appendChild(e);for(var b=0;b<document.styleSheets.length;b++){if(document.styleSheets[b].disabled){continue}var d=document.styleSheets[b];try{if(d.insertRule){var a=d.cssRules?d.cssRules.length:0;d.insertRule(".dygraphDefaultAnnotation { "+f+" }",a)}else{if(d.addRule){d.addRule(".dygraphDefaultAnnotation",f)}}Dygraph.addedAnnotationCSS=true;return}catch(c){}}this.warn("Unable to add default annotation CSS rule; display may be off.")};DateGraph=Dygraph;Dygraph.LOG_SCALE=10;Dygraph.LN_TEN=Math.log(Dygraph.LOG_SCALE);Dygraph.log10=function(a){return Math.log(a)/Dygraph.LN_TEN};Dygraph.DEBUG=1;Dygraph.INFO=2;Dygraph.WARNING=3;Dygraph.ERROR=3;Dygraph.LOG_STACK_TRACES=false;Dygraph.log=function(b,d){var a;if(typeof(printStackTrace)!="undefined"){var a=printStackTrace({guess:false});while(a[0].indexOf("Function.log")!=0){a.splice(0,1)}a.splice(0,2);for(var c=0;c<a.length;c++){a[c]=a[c].replace(/\([^)]*\/(.*)\)/,"($1)").replace(/\@.*\/([^\/]*)/,"@$1").replace("[object Object].","")}d+=" ("+a.splice(0,1)+")"}if(typeof(console)!="undefined"){switch(b){case Dygraph.DEBUG:console.debug("dygraphs: "+d);break;case Dygraph.INFO:console.info("dygraphs: "+d);break;case Dygraph.WARNING:console.warn("dygraphs: "+d);break;case Dygraph.ERROR:console.error("dygraphs: "+d);break}}if(Dygraph.LOG_STACK_TRACES){console.log(a.join("\n"))}};Dygraph.info=function(a){Dygraph.log(Dygraph.INFO,a)};Dygraph.prototype.info=Dygraph.info;Dygraph.warn=function(a){Dygraph.log(Dygraph.WARNING,a)};Dygraph.prototype.warn=Dygraph.warn;Dygraph.error=function(a){Dygraph.log(Dygraph.ERROR,a)};Dygraph.prototype.error=Dygraph.error;Dygraph.getContext=function(a){return a.getContext("2d")};Dygraph.addEvent=function addEvent(c,b,a){if(c.addEventListener){c.addEventListener(b,a,false)}else{c[b+a]=function(){a(window.event)};c.attachEvent("on"+b,c[b+a])}};Dygraph.removeEvent=function addEvent(c,b,a){if(c.removeEventListener){c.removeEventListener(b,a,false)}else{c.detachEvent("on"+b,c[b+a]);c[b+a]=null}};Dygraph.cancelEvent=function(a){a=a?a:window.event;if(a.stopPropagation){a.stopPropagation()}if(a.preventDefault){a.preventDefault()}a.cancelBubble=true;a.cancel=true;a.returnValue=false;return false};Dygraph.hsvToRGB=function(h,g,k){var c;var d;var l;if(g===0){c=k;d=k;l=k}else{var e=Math.floor(h*6);var j=(h*6)-e;var b=k*(1-g);var a=k*(1-(g*j));var m=k*(1-(g*(1-j)));switch(e){case 1:c=a;d=k;l=b;break;case 2:c=b;d=k;l=m;break;case 3:c=b;d=a;l=k;break;case 4:c=m;d=b;l=k;break;case 5:c=k;d=b;l=a;break;case 6:case 0:c=k;d=m;l=b;break}}c=Math.floor(255*c+0.5);d=Math.floor(255*d+0.5);l=Math.floor(255*l+0.5);return"rgb("+c+","+d+","+l+")"};Dygraph.findPosX=function(b){var c=0;if(b.offsetParent){var a=b;while(1){c+=a.offsetLeft;if(!a.offsetParent){break}a=a.offsetParent}}else{if(b.x){c+=b.x}}while(b&&b!=document.body){c-=b.scrollLeft;b=b.parentNode}return c};Dygraph.findPosY=function(c){var b=0;if(c.offsetParent){var a=c;while(1){b+=a.offsetTop;if(!a.offsetParent){break}a=a.offsetParent}}else{if(c.y){b+=c.y}}while(c&&c!=document.body){b-=c.scrollTop;c=c.parentNode}return b};Dygraph.pageX=function(c){if(c.pageX){return(!c.pageX||c.pageX<0)?0:c.pageX}else{var d=document;var a=document.body;return c.clientX+(d.scrollLeft||a.scrollLeft)-(d.clientLeft||0)}};Dygraph.pageY=function(c){if(c.pageY){return(!c.pageY||c.pageY<0)?0:c.pageY}else{var d=document;var a=document.body;return c.clientY+(d.scrollTop||a.scrollTop)-(d.clientTop||0)}};Dygraph.isOK=function(a){return a&&!isNaN(a)};Dygraph.floatFormat=function(a,b){var c=Math.min(Math.max(1,b||2),21);return(Math.abs(a)<0.001&&a!=0)?a.toExponential(c-1):a.toPrecision(c)};Dygraph.zeropad=function(a){if(a<10){return"0"+a}else{return""+a}};Dygraph.hmsString_=function(a){var c=Dygraph.zeropad;var b=new Date(a);if(b.getSeconds()){return c(b.getHours())+":"+c(b.getMinutes())+":"+c(b.getSeconds())}else{return c(b.getHours())+":"+c(b.getMinutes())}};Dygraph.round_=function(c,b){var a=Math.pow(10,b);return Math.round(c*a)/a};Dygraph.binarySearch=function(a,d,i,e,b){if(e==null||b==null){e=0;b=d.length-1}if(e>b){return -1}if(i==null){i=0}var h=function(j){return j>=0&&j<d.length};var g=parseInt((e+b)/2);var c=d[g];if(c==a){return g}if(c>a){if(i>0){var f=g-1;if(h(f)&&d[f]<a){return g}}return Dygraph.binarySearch(a,d,i,e,g-1)}if(c<a){if(i<0){var f=g+1;if(h(f)&&d[f]>a){return g}}return Dygraph.binarySearch(a,d,i,g+1,b)}};Dygraph.dateParser=function(a){var b;var c;if(a.search("-")!=-1){b=a.replace("-","/","g");while(b.search("-")!=-1){b=b.replace("-","/")}c=Dygraph.dateStrToMillis(b)}else{if(a.length==8){b=a.substr(0,4)+"/"+a.substr(4,2)+"/"+a.substr(6,2);c=Dygraph.dateStrToMillis(b)}else{c=Dygraph.dateStrToMillis(a)}}if(!c||isNaN(c)){Dygraph.error("Couldn't parse "+a+" as a date")}return c};Dygraph.dateStrToMillis=function(a){return new Date(a).getTime()};Dygraph.update=function(b,c){if(typeof(c)!="undefined"&&c!==null){for(var a in c){if(c.hasOwnProperty(a)){b[a]=c[a]}}}return b};Dygraph.updateDeep=function(b,d){function c(e){return(typeof Node==="object"?e instanceof Node:typeof e==="object"&&typeof e.nodeType==="number"&&typeof e.nodeName==="string")}if(typeof(d)!="undefined"&&d!==null){for(var a in d){if(d.hasOwnProperty(a)){if(d[a]==null){b[a]=null}else{if(Dygraph.isArrayLike(d[a])){b[a]=d[a].slice()}else{if(c(d[a])){b[a]=d[a]}else{if(typeof(d[a])=="object"){if(typeof(b[a])!="object"){b[a]={}}Dygraph.updateDeep(b[a],d[a])}else{b[a]=d[a]}}}}}}}return b};Dygraph.isArrayLike=function(b){var a=typeof(b);if((a!="object"&&!(a=="function"&&typeof(b.item)=="function"))||b===null||typeof(b.length)!="number"||b.nodeType===3){return false}return true};Dygraph.isDateLike=function(a){if(typeof(a)!="object"||a===null||typeof(a.getTime)!="function"){return false}return true};Dygraph.clone=function(c){var b=[];for(var a=0;a<c.length;a++){if(Dygraph.isArrayLike(c[a])){b.push(Dygraph.clone(c[a]))}else{b.push(c[a])}}return b};Dygraph.createCanvas=function(){var a=document.createElement("canvas");isIE=(/MSIE/.test(navigator.userAgent)&&!window.opera);if(isIE&&(typeof(G_vmlCanvasManager)!="undefined")){a=G_vmlCanvasManager.initElement(a)}return a};Dygraph.repeatAndCleanup=function(b,g,f,c){var e=0;var d=new Date().getTime();b(e);if(g==1){c();return}(function a(){if(e>=g){return}var h=d+(1+e)*f;setTimeout(function(){e++;b(e);if(e>=g-1){c()}else{a()}},h-new Date().getTime())})()};Dygraph.isPixelChangingOptionList=function(f,d){var c={annotationClickHandler:true,annotationDblClickHandler:true,annotationMouseOutHandler:true,annotationMouseOverHandler:true,axisLabelColor:true,axisLineColor:true,axisLineWidth:true,clickCallback:true,digitsAfterDecimal:true,drawCallback:true,drawPoints:true,drawXGrid:true,drawYGrid:true,fillAlpha:true,gridLineColor:true,gridLineWidth:true,hideOverlayOnMouseOut:true,highlightCallback:true,highlightCircleSize:true,interactionModel:true,isZoomedIgnoreProgrammaticZoom:true,labelsDiv:true,labelsDivStyles:true,labelsDivWidth:true,labelsKMB:true,labelsKMG2:true,labelsSeparateLines:true,labelsShowZeroValues:true,legend:true,maxNumberWidth:true,panEdgeFraction:true,pixelsPerYLabel:true,pointClickCallback:true,pointSize:true,rangeSelectorPlotFillColor:true,rangeSelectorPlotStrokeColor:true,showLabelsOnHighlight:true,showRoller:true,sigFigs:true,strokeWidth:true,underlayCallback:true,unhighlightCallback:true,xAxisLabelFormatter:true,xTicker:true,xValueFormatter:true,yAxisLabelFormatter:true,yValueFormatter:true,zoomCallback:true};var a=false;var b={};if(f){for(var e=1;e<f.length;e++){b[f[e]].."]]"..[[=true}}for(property in d){if(a){break}if(d.hasOwnProperty(property)){if(b[property]){for(subProperty in d[property]){if(a){break}if(d[property].hasOwnProperty(subProperty)&&!c[subProperty]){a=true}}}else{if(!c[property]){a=true}}}}return a};Dygraph.GVizChart=function(a){this.container=a};Dygraph.GVizChart.prototype.draw=function(b,a){this.container.innerHTML="";if(typeof(this.date_graph)!="undefined"){this.date_graph.destroy()}this.date_graph=new Dygraph(this.container,b,a)};Dygraph.GVizChart.prototype.setSelection=function(b){var a=false;if(b.length){a=b[0].row}this.date_graph.setSelection(a)};Dygraph.GVizChart.prototype.getSelection=function(){var b=[];var c=this.date_graph.getSelection();if(c<0){return b}col=1;for(var a in this.date_graph.layout_.datasets){b.push({row:c,column:col});col++}return b};Dygraph.Interaction={};Dygraph.Interaction.startPan=function(n,s,c){c.isPanning=true;var j=s.xAxisRange();c.dateRange=j[1]-j[0];c.initialLeftmostDate=j[0];c.xUnitsPerPixel=c.dateRange/(s.plotter_.area.w-1);if(s.attr_("panEdgeFraction")){var v=s.width_*s.attr_("panEdgeFraction");var d=s.xAxisExtremes();var h=s.toDomXCoord(d[0])-v;var k=s.toDomXCoord(d[1])+v;var t=s.toDataXCoord(h);var u=s.toDataXCoord(k);c.boundedDates=[t,u];var f=[];var a=s.height_*s.attr_("panEdgeFraction");for(var q=0;q<s.axes_.length;q++){var b=s.axes_[q];var o=b.extremeRange;var p=s.toDomYCoord(o[0],q)+a;var r=s.toDomYCoord(o[1],q)-a;var m=s.toDataYCoord(p);var e=s.toDataYCoord(r);f[q]=[m,e]}c.boundedValues=f}c.is2DPan=false;for(var q=0;q<s.axes_.length;q++){var b=s.axes_[q];var l=s.yAxisRange(q);if(b.logscale){b.initialTopValue=Dygraph.log10(l[1]);b.dragValueRange=Dygraph.log10(l[1])-Dygraph.log10(l[0])}else{b.initialTopValue=l[1];b.dragValueRange=l[1]-l[0]}b.unitsPerPixel=b.dragValueRange/(s.plotter_.area.h-1);if(b.valueWindow||b.valueRange){c.is2DPan=true}}};Dygraph.Interaction.movePan=function(b,k,c){c.dragEndX=k.dragGetX_(b,c);c.dragEndY=k.dragGetY_(b,c);var h=c.initialLeftmostDate-(c.dragEndX-c.dragStartX)*c.xUnitsPerPixel;if(c.boundedDates){h=Math.max(h,c.boundedDates[0])}var a=h+c.dateRange;if(c.boundedDates){if(a>c.boundedDates[1]){h=h-(a-c.boundedDates[1]);a=h+c.dateRange}}k.dateWindow_=[h,a];if(c.is2DPan){for(var j=0;j<k.axes_.length;j++){var e=k.axes_[j];var d=c.dragEndY-c.dragStartY;var n=d*e.unitsPerPixel;var f=c.boundedValues?c.boundedValues[j]:null;var l=e.initialTopValue+n;if(f){l=Math.min(l,f[1])}var m=l-e.dragValueRange;if(f){if(m<f[0]){l=l-(m-f[0]);m=l-e.dragValueRange}}if(e.logscale){e.valueWindow=[Math.pow(Dygraph.LOG_SCALE,m),Math.pow(Dygraph.LOG_SCALE,l)]}else{e.valueWindow=[m,l]}}}k.drawGraph_(false)};Dygraph.Interaction.endPan=function(c,b,a){a.dragEndX=b.dragGetX_(c,a);a.dragEndY=b.dragGetY_(c,a);var e=Math.abs(a.dragEndX-a.dragStartX);var d=Math.abs(a.dragEndY-a.dragStartY);if(e<2&&d<2&&b.lastx_!=undefined&&b.lastx_!=-1){Dygraph.Interaction.treatMouseOpAsClick(b,c,a)}a.isPanning=false;a.is2DPan=false;a.initialLeftmostDate=null;a.dateRange=null;a.valueRange=null;a.boundedDates=null;a.boundedValues=null};Dygraph.Interaction.startZoom=function(c,b,a){a.isZooming=true};Dygraph.Interaction.moveZoom=function(c,b,a){a.dragEndX=b.dragGetX_(c,a);a.dragEndY=b.dragGetY_(c,a);var e=Math.abs(a.dragStartX-a.dragEndX);var d=Math.abs(a.dragStartY-a.dragEndY);a.dragDirection=(e<d/2)?Dygraph.VERTICAL:Dygraph.HORIZONTAL;b.drawZoomRect_(a.dragDirection,a.dragStartX,a.dragEndX,a.dragStartY,a.dragEndY,a.prevDragDirection,a.prevEndX,a.prevEndY);a.prevEndX=a.dragEndX;a.prevEndY=a.dragEndY;a.prevDragDirection=a.dragDirection};Dygraph.Interaction.treatMouseOpAsClick=function(f,b,d){var k=f.attr_("clickCallback");var n=f.attr_("pointClickCallback");var j=null;if(n){var l=-1;var m=Number.MAX_VALUE;for(var e=0;e<f.selPoints_.length;e++){var c=f.selPoints_[e];var a=Math.pow(c.canvasx-d.dragEndX,2)+Math.pow(c.canvasy-d.dragEndY,2);if(!isNaN(a)&&(l==-1||a<m)){m=a;l=e}}var h=f.attr_("highlightCircleSize")+2;if(m<=h*h){j=f.selPoints_[l]}}if(j){n(b,j)}if(k){k(b,f.lastx_,f.selPoints_)}};Dygraph.Interaction.endZoom=function(c,b,a){a.isZooming=false;a.dragEndX=b.dragGetX_(c,a);a.dragEndY=b.dragGetY_(c,a);var e=Math.abs(a.dragEndX-a.dragStartX);var d=Math.abs(a.dragEndY-a.dragStartY);if(e<2&&d<2&&b.lastx_!=undefined&&b.lastx_!=-1){Dygraph.Interaction.treatMouseOpAsClick(b,c,a)}if(e>=10&&a.dragDirection==Dygraph.HORIZONTAL){b.doZoomX_(Math.min(a.dragStartX,a.dragEndX),Math.max(a.dragStartX,a.dragEndX))}else{if(d>=10&&a.dragDirection==Dygraph.VERTICAL){b.doZoomY_(Math.min(a.dragStartY,a.dragEndY),Math.max(a.dragStartY,a.dragEndY))}else{b.clearZoomRect_()}}a.dragStartX=null;a.dragStartY=null};Dygraph.Interaction.defaultModel={mousedown:function(c,b,a){a.initializeMouseDown(c,b,a);if(c.altKey||c.shiftKey){Dygraph.startPan(c,b,a)}else{Dygraph.startZoom(c,b,a)}},mousemove:function(c,b,a){if(a.isZooming){Dygraph.moveZoom(c,b,a)}else{if(a.isPanning){Dygraph.movePan(c,b,a)}}},mouseup:function(c,b,a){if(a.isZooming){Dygraph.endZoom(c,b,a)}else{if(a.isPanning){Dygraph.endPan(c,b,a)}}},mouseout:function(c,b,a){if(a.isZooming){a.dragEndX=null;a.dragEndY=null}},dblclick:function(c,b,a){if(c.altKey||c.shiftKey){return}b.doUnzoom_()}};Dygraph.DEFAULT_ATTRS.interactionModel=Dygraph.Interaction.defaultModel;Dygraph.defaultInteractionModel=Dygraph.Interaction.defaultModel;Dygraph.endZoom=Dygraph.Interaction.endZoom;Dygraph.moveZoom=Dygraph.Interaction.moveZoom;Dygraph.startZoom=Dygraph.Interaction.startZoom;Dygraph.endPan=Dygraph.Interaction.endPan;Dygraph.movePan=Dygraph.Interaction.movePan;Dygraph.startPan=Dygraph.Interaction.startPan;Dygraph.Interaction.nonInteractiveModel_={mousedown:function(c,b,a){a.initializeMouseDown(c,b,a)},mouseup:function(c,b,a){a.dragEndX=b.dragGetX_(c,a);a.dragEndY=b.dragGetY_(c,a);var e=Math.abs(a.dragEndX-a.dragStartX);var d=Math.abs(a.dragEndY-a.dragStartY);if(e<2&&d<2&&b.lastx_!=undefined&&b.lastx_!=-1){Dygraph.Interaction.treatMouseOpAsClick(b,c,a)}}};DygraphRangeSelector=function(a){this.isIE_=/MSIE/.test(navigator.userAgent)&&!window.opera;this.isUsingExcanvas_=a.isUsingExcanvas_;this.dygraph_=a;this.createCanvases_();if(this.isUsingExcanvas_){this.createIEPanOverlay_()}this.createZoomHandles_();this.initInteraction_()};DygraphRangeSelector.prototype.addToGraph=function(a,b){this.layout_=b;this.resize_();a.appendChild(this.bgcanvas_);a.appendChild(this.fgcanvas_);a.appendChild(this.leftZoomHandle_);a.appendChild(this.rightZoomHandle_)};DygraphRangeSelector.prototype.renderStaticLayer=function(){this.resize_();this.drawStaticLayer_()};DygraphRangeSelector.prototype.renderInteractiveLayer=function(){if(this.isChangingRange_){return}this.placeZoomHandles_();this.drawInteractiveLayer_()};DygraphRangeSelector.prototype.resize_=function(){function c(d,e){d.style.top=e.y+"px";d.style.left=e.x+"px";d.width=e.w;d.height=e.h;d.style.width=d.width+"px";d.style.height=d.height+"px"}var b=this.layout_.getPlotArea();var a=this.attr_("axisLabelFontSize")+2*this.attr_("axisTickSize");this.canvasRect_={x:b.x,y:b.y+b.h+a+4,w:b.w,h:this.attr_("rangeSelectorHeight")};c(this.bgcanvas_,this.canvasRect_);c(this.fgcanvas_,this.canvasRect_)};DygraphRangeSelector.prototype.attr_=function(a){return this.dygraph_.attr_(a)};DygraphRangeSelector.prototype.createCanvases_=function(){this.bgcanvas_=Dygraph.createCanvas();this.bgcanvas_.className="dygraph-rangesel-bgcanvas";this.bgcanvas_.style.position="absolute";this.bgcanvas_.style.zIndex=9;this.bgcanvas_ctx_=Dygraph.getContext(this.bgcanvas_);this.fgcanvas_=Dygraph.createCanvas();this.fgcanvas_.className="dygraph-rangesel-fgcanvas";this.fgcanvas_.style.position="absolute";this.fgcanvas_.style.zIndex=9;this.fgcanvas_.style.cursor="default";this.fgcanvas_ctx_=Dygraph.getContext(this.fgcanvas_)};DygraphRangeSelector.prototype.createIEPanOverlay_=function(){this.iePanOverlay_=document.createElement("div");this.iePanOverlay_.style.position="absolute";this.iePanOverlay_.style.backgroundColor="white";this.iePanOverlay_.style.filter="alpha(opacity=0)";this.iePanOverlay_.style.display="none";this.iePanOverlay_.style.cursor="move";this.fgcanvas_.appendChild(this.iePanOverlay_)};DygraphRangeSelector.prototype.createZoomHandles_=function(){var a=new Image();a.className="dygraph-rangesel-zoomhandle";a.style.position="absolute";a.style.zIndex=10;a.style.visibility="hidden";a.style.cursor="col-resize";if(/MSIE 7/.test(navigator.userAgent)){a.width=7;a.height=14;a.style.backgroundColor="white";a.style.border="1px solid #333333"}else{a.width=9;a.height=16;a.src="data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAkAAAAQCAYAAADESFVDAAAAAXNSR0IArs4c6QAAAAZiS0dEANAAzwDP4Z7KegAAAAlwSFlzAAAOxAAADsQBlSsOGwAAAAd0SU1FB9sHGw0cMqdt1UwAAAAZdEVYdENvbW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAaElEQVQoz+3SsRFAQBCF4Z9WJM8KCDVwownl6YXsTmCUsyKGkZzcl7zkz3YLkypgAnreFmDEpHkIwVOMfpdi9CEEN2nGpFdwD03yEqDtOgCaun7sqSTDH32I1pQA2Pb9sZecAxc5r3IAb21d6878xsAAAAAASUVORK5CYII="}this.leftZoomHandle_=a;this.rightZoomHandle_=a.cloneNode(false)};DygraphRangeSelector.prototype.initInteraction_=function(){var i=this;var f=this.isIE_?document:window;var k=0;var p=null;var n=false;var c=false;function j(x){var w=i.dygraph_.xAxisExtremes();var u=(w[1]-w[0])/i.canvasRect_.w;var v=w[0]+(x.leftHandlePos-i.canvasRect_.x)*u;var t=w[0]+(x.rightHandlePos-i.canvasRect_.x)*u;return[v,t]}function d(t){Dygraph.cancelEvent(t);n=true;k=t.screenX;p=t.target?t.target:t.srcElement;Dygraph.addEvent(f,"mousemove",m);Dygraph.addEvent(f,"mouseup",g);i.fgcanvas_.style.cursor="col-resize"}function m(x){if(!n){return}var u=x.screenX-k;if(Math.abs(u)<4){return}k=x.screenX;var w=i.getZoomHandleStatus_();if(p==i.leftZoomHandle_){var t=w.leftHandlePos+u;t=Math.min(t,w.rightHandlePos-p.width-3);t=Math.max(t,i.canvasRect_.x)}else{var t=w.rightHandlePos+u;t=Math.min(t,i.canvasRect_.x+i.canvasRect_.w);t=Math.max(t,w.leftHandlePos+p.width+3)}var v=p.width/2;p.style.left=(t-v)+"px";i.drawInteractiveLayer_();if(!i.isUsingExcanvas_){r()}}function g(t){if(!n){return}n=false;Dygraph.removeEvent(f,"mousemove",m);Dygraph.removeEvent(f,"mouseup",g);i.fgcanvas_.style.cursor="default";if(i.isUsingExcanvas_){r()}}function r(){try{var u=i.getZoomHandleStatus_();i.isChangingRange_=true;if(!u.isZoomed){i.dygraph_.doUnzoom_()}else{var t=j(u);i.dygraph_.doZoomXDates_(t[0],t[1])}}finally{i.isChangingRange_=false}}function e(v){if(i.isUsingExcanvas_){return v.srcElement==i.iePanOverlay_}else{var t=i.canvasRect_.x+(v.layerX!=undefined?v.layerX:v.offsetX);var u=i.getZoomHandleStatus_();return(t>u.leftHandlePos&&t<u.rightHandlePos)}}function s(t){if(!c&&e(t)&&i.getZoomHandleStatus_().isZoomed){Dygraph.cancelEvent(t);c=true;k=t.screenX;Dygraph.addEvent(f,"mousemove",o);Dygraph.addEvent(f,"mouseup",l)}}function o(x){if(!c){return}Dygraph.cancelEvent(x);var u=x.screenX-k;if(Math.abs(u)<4){return}k=x.screenX;var w=i.getZoomHandleStatus_();var z=w.leftHandlePos;var t=w.rightHandlePos;var y=t-z;if(z+u<=i.canvasRect_.x){z=i.canvasRect_.x;t=z+y}else{if(t+u>=i.canvasRect_.x+i.canvasRect_.w){t=i.canvasRect_.x+i.canvasRect_.w;z=t-y}else{z+=u;t+=u}}var v=i.leftZoomHandle_.width/2;i.leftZoomHandle_.style.left=(z-v)+"px";i.rightZoomHandle_.style.left=(t-v)+"px";i.drawInteractiveLayer_();if(!i.isUsingExcanvas_){b()}}function l(t){if(!c){return}c=false;Dygraph.removeEvent(f,"mousemove",o);Dygraph.removeEvent(f,"mouseup",l);if(i.isUsingExcanvas_){b()}}function b(){try{i.isChangingRange_=true;i.dygraph_.dateWindow_=j(i.getZoomHandleStatus_());i.dygraph_.drawGraph_(false)}finally{i.isChangingRange_=false}}function h(t){if(n||c){return}var u=e(t)?"move":"default";if(u!=i.fgcanvas_.style.cursor){i.fgcanvas_.style.cursor=u}}var q={mousedown:function(v,u,t){t.initializeMouseDown(v,u,t);Dygraph.startPan(v,u,t)},mousemove:function(v,u,t){if(t.isPanning){Dygraph.movePan(v,u,t)}},mouseup:function(v,u,t){if(t.isPanning){Dygraph.endPan(v,u,t)}}};this.dygraph_.attrs_.interactionModel=q;this.dygraph_.attrs_.panEdgeFraction=0.0001;var a=window.opera?"mousedown":"dragstart";Dygraph.addEvent(this.leftZoomHandle_,a,d);Dygraph.addEvent(this.rightZoomHandle_,a,d);if(this.isUsingExcanvas_){Dygraph.addEvent(this.iePanOverlay_,"mousedown",s)}else{Dygraph.addEvent(this.fgcanvas_,"mousedown",s);Dygraph.addEvent(this.fgcanvas_,"mousemove",h)}};DygraphRangeSelector.prototype.drawStaticLayer_=function(){var a=this.bgcanvas_ctx_;a.clearRect(0,0,this.canvasRect_.w,this.canvasRect_.h);try{this.drawMiniPlot_()}catch(b){}var c=0.5;this.bgcanvas_ctx_.lineWidth=1;a.strokeStyle="gray";a.beginPath();a.moveTo(c,c);a.lineTo(c,this.canvasRect_.h-c);a.lineTo(this.canvasRect_.w-c,this.canvasRect_.h-c);a.lineTo(this.canvasRect_.w-c,c);a.stroke()};DygraphRangeSelector.prototype.drawMiniPlot_=function(){var p=this.attr_("rangeSelectorPlotFillColor");var l=this.attr_("rangeSelectorPlotStrokeColor");if(!p&&!l){return}var m=this.computeCombinedSeriesAndLimits_();var e=m.yMax-m.yMin;var r=this.bgcanvas_ctx_;var f=0.5;var j=this.dygraph_.xAxisExtremes();var b=Math.max(j[1]-j[0],1e-30);var q=(this.canvasRect_.w-f)/b;var o=(this.canvasRect_.h-f)/e;var d=this.canvasRect_.w-f;var h=this.canvasRect_.h-f;r.beginPath();r.moveTo(f,h);for(var g=0;g<m.data.length;g++){var a=m.data[g];var n=(a[0]-j[0])*q;var k=h-(a[1]-m.yMin)*o;if(isFinite(n)&&isFinite(k)){r.lineTo(n,k)}}r.lineTo(d,h);r.closePath();if(p){var c=this.bgcanvas_ctx_.createLinearGradient(0,0,0,h);c.addColorStop(0,"white");c.addColorStop(1,p);this.bgcanvas_ctx_.fillStyle=c;r.fill()}if(l){this.bgcanvas_ctx_.strokeStyle=l;this.bgcanvas_ctx_.lineWidth=1.5;r.stroke()}};DygraphRangeSelector.prototype.computeCombinedSeriesAndLimits_=function(){var f=this.dygraph_.rawData_;var n=this.attr_("logscale");var r=[];var m;var l;var g=typeof f[0][1]!="number";if(g){m=[];l=[];for(var d=0;d<f[0][1].length;d++){m.push(0);l.push(0)}g=true}for(var h=0;h<f.length;h++){var a=f[h];var t=a[0];var o;if(g){for(var d=0;d<m.length;d++){m[d]=l[d]=0}}else{m=l=0}for(var e=1;e<a.length;e++){if(this.dygraph_.visibility()[e-1]){if(g){for(var d=0;d<m.length;d++){var p=a[e][d];if(p==null||isNaN(p)){continue}m[d]+=p;l[d]++}}else{var p=a[e];if(p==null||isNaN(p)){continue}m+=p;l++}}}if(g){for(var d=0;d<m.length;d++){m[d]/=l[d]}o=m.slice(0)}else{o=m/l}r.push([t,o])}r=this.dygraph_.rollingAverage(r,this.dygraph_.rollPeriod_);if(typeof r[0][1]!="number"){for(var h=0;h<r.length;h++){var o=r[h][1];r[h][1]=o[0]}}var q=Number.MAX_VALUE;var c=-Number.MAX_VALUE;for(var h=0;h<r.length;h++){var o=r[h][1];if(o!=null&&isFinite(o)&&(!n||o>0)){q=Math.min(q,o);c=Math.max(c,o)}}var s=0.25;if(n){c=Dygraph.log10(c);c+=c*s;q=Dygraph.log10(q);for(var h=0;h<r.length;h++){r[h][1]=Dygraph.log10(r[h][1])}}else{var b;yRange=c-q;if(yRange<=Number.MIN_VALUE){b=c*s}else{b=yRange*s}c+=b;q-=b}return{data:r,yMin:q,yMax:c}};DygraphRangeSelector.prototype.placeZoomHandles_=function(){var g=this.dygraph_.xAxisExtremes();var a=this.dygraph_.xAxisRange();var b=g[1]-g[0];var i=Math.max(0,(a[0]-g[0])/b);var e=Math.max(0,(g[1]-a[1])/b);var h=this.canvasRect_.x+this.canvasRect_.w*i;var d=this.canvasRect_.x+this.canvasRect_.w*(1-e);var c=Math.max(this.canvasRect_.y,this.canvasRect_.y+(this.canvasRect_.h-this.leftZoomHandle_.height)/2);var f=this.leftZoomHandle_.width/2;this.leftZoomHandle_.style.left=(h-f)+"px";this.leftZoomHandle_.style.top=c+"px";this.rightZoomHandle_.style.left=(d-f)+"px";this.rightZoomHandle_.style.top=this.leftZoomHandle_.style.top;this.leftZoomHandle_.style.visibility="visible";this.rightZoomHandle_.style.visibility="visible"};DygraphRangeSelector.prototype.drawInteractiveLayer_=function(){var b=this.fgcanvas_ctx_;b.clearRect(0,0,this.canvasRect_.w,this.canvasRect_.h);var d=1;var c=this.canvasRect_.w-d;var a=this.canvasRect_.h-d;var e=this.getZoomHandleStatus_();b.strokeStyle="black";if(!e.isZoomed){b.beginPath();b.moveTo(d,d);b.lineTo(d,a);b.lineTo(c,a);b.lineTo(c,d);b.stroke();if(this.iePanOverlay_){this.iePanOverlay_.style.display="none"}}else{leftHandleCanvasPos=Math.max(d,e.leftHandlePos-this.canvasRect_.x);rightHandleCanvasPos=Math.min(c,e.rightHandlePos-this.canvasRect_.x);b.fillStyle="rgba(240, 240, 240, 0.6)";b.fillRect(0,0,leftHandleCanvasPos,this.canvasRect_.h);b.fillRect(rightHandleCanvasPos,0,this.canvasRect_.w-rightHandleCanvasPos,this.canvasRect_.h);b.beginPath();b.moveTo(d,d);b.lineTo(leftHandleCanvasPos,d);b.lineTo(leftHandleCanvasPos,a);b.lineTo(rightHandleCanvasPos,a);b.lineTo(rightHandleCanvasPos,d);b.lineTo(c,d);b.stroke();if(this.isUsingExcanvas_){this.iePanOverlay_.style.width=(rightHandleCanvasPos-leftHandleCanvasPos)+"px";this.iePanOverlay_.style.left=leftHandleCanvasPos+"px";this.iePanOverlay_.style.height=a+"px";this.iePanOverlay_.style.display="inline"}}};DygraphRangeSelector.prototype.getZoomHandleStatus_=function(){var b=this.leftZoomHandle_.width/2;var c=parseInt(this.leftZoomHandle_.style.left)+b;var a=parseInt(this.rightZoomHandle_.style.left)+b;return{leftHandlePos:c,rightHandlePos:a,isZoomed:(c-1>this.canvasRect_.x||a+1<this.canvasRect_.x+this.canvasRect_.w)}};Dygraph.numericTicks=function(I,H,w,r,d,s){var C=r("pixelsPerLabel");var J=[];if(s){for(var F=0;F<s.length;F++){J.push({v:s[F]})}}else{if(r("logscale")){var A=Math.floor(w/C);var o=Dygraph.binarySearch(I,Dygraph.PREFERRED_LOG_TICK_VALUES,1);var K=Dygraph.binarySearch(H,Dygraph.PREFERRED_LOG_TICK_VALUES,-1);if(o==-1){o=0}if(K==-1){K=Dygraph.PREFERRED_LOG_TICK_VALUES.length-1}var v=null;if(K-o>=A/4){for(var u=K;u>=o;u--){var p=Dygraph.PREFERRED_LOG_TICK_VALUES[u];var m=Math.log(p/I)/Math.log(H/I)*w;var G={v:p};if(v==null){v={tickValue:p,pixel_coord:m}}else{if(Math.abs(m-v.pixel_coord)>=C){v={tickValue:p,pixel_coord:m}}else{G.label=""}}J.push(G)}J.reverse()}}if(J.length==0){var h=r("labelsKMG2");if(h){var q=[1,2,4,8]}else{var q=[1,2,5]}var L,z,c,A;for(var F=-10;F<50;F++){if(h){var g=Math.pow(16,F)}else{var g=Math.pow(10,F)}for(var D=0;D<q.length;D++){L=g*q[D];z=Math.floor(I/L)*L;c=Math.ceil(H/L)*L;A=Math.abs(c-z)/L;var f=w/A;if(f>C){break}}if(f>C){break}}if(z>c){L*=-1}for(var F=0;F<A;F++){var t=z+F*L;J.push({v:t})}}}var B;var y=[];if(r("labelsKMB")){B=1000;y=["K","M","B","T"]}if(r("labelsKMG2")){if(B){self.warn("Setting both labelsKMB and labelsKMG2. Pick one!")}B=1024;y=["k","M","G","T"]}var E=r("axisLabelFormatter");for(var F=0;F<J.length;F++){if(J[F].label!==undefined){continue}var t=J[F].v;var e=Math.abs(t);var l=E(t,0,r,d);if(y.length>0){var x=B*B*B*B;for(var D=3;D>=0;D--,x/=B){if(e>=x){l=Dygraph.round_(t/x,r("digitsAfterDecimal"))+y[D];break}}}J[F].label=l}return J};Dygraph.dateTicker=function(m,l,f,c,e,k){var d=c("pixelsPerLabel");var h=-1;for(var g=0;g<Dygraph.NUM_GRANULARITIES;g++){var j=Dygraph.numDateTicks(m,l,g);if(f/j>=d){h=g;break}}if(h>=0){return Dygraph.getDateAxis(m,l,h,c,e)}else{return[]}};Dygraph.SECONDLY=0;Dygraph.TWO_SECONDLY=1;Dygraph.FIVE_SECONDLY=2;Dygraph.TEN_SECONDLY=3;Dygraph.THIRTY_SECONDLY=4;Dygraph.MINUTELY=5;Dygraph.TWO_MINUTELY=6;Dygraph.FIVE_MINUTELY=7;Dygraph.TEN_MINUTELY=8;Dygraph.THIRTY_MINUTELY=9;Dygraph.HOURLY=10;Dygraph.TWO_HOURLY=11;Dygraph.SIX_HOURLY=12;Dygraph.DAILY=13;Dygraph.WEEKLY=14;Dygraph.MONTHLY=15;Dygraph.QUARTERLY=16;Dygraph.BIANNUAL=17;Dygraph.ANNUAL=18;Dygraph.DECADAL=19;Dygraph.CENTENNIAL=20;Dygraph.NUM_GRANULARITIES=21;Dygraph.SHORT_SPACINGS=[];Dygraph.SHORT_SPACINGS[Dygraph.SECONDLY]=1000*1;Dygraph.SHORT_SPACINGS[Dygraph.TWO_SECONDLY]=1000*2;Dygraph.SHORT_SPACINGS[Dygraph.FIVE_SECONDLY]=1000*5;Dygraph.SHORT_SPACINGS[Dygraph.TEN_SECONDLY]=1000*10;Dygraph.SHORT_SPACINGS[Dygraph.THIRTY_SECONDLY]=1000*30;Dygraph.SHORT_SPACINGS[Dygraph.MINUTELY]=1000*60;Dygraph.SHORT_SPACINGS[Dygraph.TWO_MINUTELY]=1000*60*2;Dygraph.SHORT_SPACINGS[Dygraph.FIVE_MINUTELY]=1000*60*5;Dygraph.SHORT_SPACINGS[Dygraph.TEN_MINUTELY]=1000*60*10;Dygraph.SHORT_SPACINGS[Dygraph.THIRTY_MINUTELY]=1000*60*30;Dygraph.SHORT_SPACINGS[Dygraph.HOURLY]=1000*3600;Dygraph.SHORT_SPACINGS[Dygraph.TWO_HOURLY]=1000*3600*2;Dygraph.SHORT_SPACINGS[Dygraph.SIX_HOURLY]=1000*3600*6;Dygraph.SHORT_SPACINGS[Dygraph.DAILY]=1000*86400;Dygraph.SHORT_SPACINGS[Dygraph.WEEKLY]=1000*604800;Dygraph.PREFERRED_LOG_TICK_VALUES=function(){var c=[];for(var b=-39;b<=39;b++){var a=Math.pow(10,b);for(var d=1;d<=9;d++){var e=a*d;c.push(e)}}return c}();Dygraph.numDateTicks=function(e,b,g){if(g<Dygraph.MONTHLY){var h=Dygraph.SHORT_SPACINGS[g];return Math.floor(0.5+1*(b-e)/h)}else{var f=1;var d=12;if(g==Dygraph.QUARTERLY){d=3}if(g==Dygraph.BIANNUAL){d=2}if(g==Dygraph.ANNUAL){d=1}if(g==Dygraph.DECADAL){d=1;f=10}if(g==Dygraph.CENTENNIAL){d=1;f=100}var c=365.2524*24*3600*1000;var a=1*(b-e)/c;return Math.floor(0.5+1*a*d/f)}};Dygraph.getDateAxis=function(n,h,a,l,y){var u=l("axisLabelFormatter");var A=[];if(a<Dygraph.MONTHLY){var c=Dygraph.SHORT_SPACINGS[a];var v="%d%b";var w=c/1000;var z=new Date(n);if(w<=60){var f=z.getSeconds();z.setSeconds(f-f%w)}else{z.setSeconds(0);w/=60;if(w<=60){var f=z.getMinutes();z.setMinutes(f-f%w)}else{z.setMinutes(0);w/=60;if(w<=24){var f=z.getHours();z.setHours(f-f%w)}else{z.setHours(0);w/=24;if(w==7){z.setDate(z.getDate()-z.getDay())}}}}n=z.getTime();for(var k=n;k<=h;k+=c){A.push({v:k,label:u(new Date(k),a,l,y)})}}else{var e;var o=1;if(a==Dygraph.MONTHLY){e=[0,1,2,3,4,5,6,7,8,9,10,11]}else{if(a==Dygraph.QUARTERLY){e=[0,3,6,9]}else{if(a==Dygraph.BIANNUAL){e=[0,6]}else{if(a==Dygraph.ANNUAL){e=[0]}else{if(a==Dygraph.DECADAL){e=[0];o=10}else{if(a==Dygraph.CENTENNIAL){e=[0];o=100}else{Dygraph.warn("Span of dates is too long")}}}}}}var s=new Date(n).getFullYear();var p=new Date(h).getFullYear();var b=Dygraph.zeropad;for(var r=s;r<=p;r++){if(r%o!=0){continue}for(var q=0;q<e.length;q++){var m=r+"/"+b(1+e[q])+"/01";var k=Dygraph.dateStrToMillis(m);if(k<n||k>h){continue}A.push({v:k,label:u(new Date(k),a,l,y)})}}}return A};Dygraph.DEFAULT_ATTRS.axes.x.ticker=Dygraph.dateTicker;Dygraph.DEFAULT_ATTRS.axes.y.ticker=Dygraph.numericTicks;Dygraph.DEFAULT_ATTRS.axes.y2.ticker=Dygraph.numericTicks;function RGBColor(g){this.ok=false;if(g.charAt(0)=="#"){g=g.substr(1,6)}g=g.replace(/ /g,"");g=g.toLowerCase();var a={aliceblue:"f0f8ff",antiquewhite:"faebd7",aqua:"00ffff",aquamarine:"7fffd4",azure:"f0ffff",beige:"f5f5dc",bisque:"ffe4c4",black:"000000",blanchedalmond:"ffebcd",blue:"0000ff",blueviolet:"8a2be2",brown:"a52a2a",burlywood:"deb887",cadetblue:"5f9ea0",chartreuse:"7fff00",chocolate:"d2691e",coral:"ff7f50",cornflowerblue:"6495ed",cornsilk:"fff8dc",crimson:"dc143c",cyan:"00ffff",darkblue:"00008b",darkcyan:"008b8b",darkgoldenrod:"b8860b",darkgray:"a9a9a9",darkgreen:"006400",darkkhaki:"bdb76b",darkmagenta:"8b008b",darkolivegreen:"556b2f",darkorange:"ff8c00",darkorchid:"9932cc",darkred:"8b0000",darksalmon:"e9967a",darkseagreen:"8fbc8f",darkslateblue:"483d8b",darkslategray:"2f4f4f",darkturquoise:"00ced1",darkviolet:"9400d3",deeppink:"ff1493",deepskyblue:"00bfff",dimgray:"696969",dodgerblue:"1e90ff",feldspar:"d19275",firebrick:"b22222",floralwhite:"fffaf0",forestgreen:"228b22",fuchsia:"ff00ff",gainsboro:"dcdcdc",ghostwhite:"f8f8ff",gold:"ffd700",goldenrod:"daa520",gray:"808080",green:"008000",greenyellow:"adff2f",honeydew:"f0fff0",hotpink:"ff69b4",indianred:"cd5c5c",indigo:"4b0082",ivory:"fffff0",khaki:"f0e68c",lavender:"e6e6fa",lavenderblush:"fff0f5",lawngreen:"7cfc00",lemonchiffon:"fffacd",lightblue:"add8e6",lightcoral:"f08080",lightcyan:"e0ffff",lightgoldenrodyellow:"fafad2",lightgrey:"d3d3d3",lightgreen:"90ee90",lightpink:"ffb6c1",lightsalmon:"ffa07a",lightseagreen:"20b2aa",lightskyblue:"87cefa",lightslateblue:"8470ff",lightslategray:"778899",lightsteelblue:"b0c4de",lightyellow:"ffffe0",lime:"00ff00",limegreen:"32cd32",linen:"faf0e6",magenta:"ff00ff",maroon:"800000",mediumaquamarine:"66cdaa",mediumblue:"0000cd",mediumorchid:"ba55d3",mediumpurple:"9370d8",mediumseagreen:"3cb371",mediumslateblue:"7b68ee",mediumspringgreen:"00fa9a",mediumturquoise:"48d1cc",mediumvioletred:"c71585",midnightblue:"191970",mintcream:"f5fffa",mistyrose:"ffe4e1",moccasin:"ffe4b5",navajowhite:"ffdead",navy:"000080",oldlace:"fdf5e6",olive:"808000",olivedrab:"6b8e23",orange:"ffa500",orangered:"ff4500",orchid:"da70d6",palegoldenrod:"eee8aa",palegreen:"98fb98",paleturquoise:"afeeee",palevioletred:"d87093",papayawhip:"ffefd5",peachpuff:"ffdab9",peru:"cd853f",pink:"ffc0cb",plum:"dda0dd",powderblue:"b0e0e6",purple:"800080",red:"ff0000",rosybrown:"bc8f8f",royalblue:"4169e1",saddlebrown:"8b4513",salmon:"fa8072",sandybrown:"f4a460",seagreen:"2e8b57",seashell:"fff5ee",sienna:"a0522d",silver:"c0c0c0",skyblue:"87ceeb",slateblue:"6a5acd",slategray:"708090",snow:"fffafa",springgreen:"00ff7f",steelblue:"4682b4",tan:"d2b48c",teal:"008080",thistle:"d8bfd8",tomato:"ff6347",turquoise:"40e0d0",violet:"ee82ee",violetred:"d02090",wheat:"f5deb3",white:"ffffff",whitesmoke:"f5f5f5",yellow:"ffff00",yellowgreen:"9acd32"};for(var c in a){if(g==c){g=a[c]}}var h=[{re:/^rgb\((\d{1,3}),\s*(\d{1,3}),\s*(\d{1,3})\)$/,example:["rgb(123, 234, 45)","rgb(255,234,245)"],process:function(i){return[parseInt(i[1]),parseInt(i[2]),parseInt(i[3])]}},{re:/^(\w{2})(\w{2})(\w{2})$/,example:["#00ff00","336699"],process:function(i){return[parseInt(i[1],16),parseInt(i[2],16),parseInt(i[3],16)]}},{re:/^(\w{1})(\w{1})(\w{1})$/,example:["#fb0","f0f"],process:function(i){return[parseInt(i[1]+i[1],16),parseInt(i[2]+i[2],16),parseInt(i[3]+i[3],16)]}}];for(var b=0;b<h.length;b++){var e=h[b].re;var d=h[b].process;var f=e.exec(g);if(f){channels=d(f);this.r=channels[0];this.g=channels[1];this.b=channels[2];this.ok=true}}this.r=(this.r<0||isNaN(this.r))?0:((this.r>255)?255:this.r);this.g=(this.g<0||isNaN(this.g))?0:((this.g>255)?255:this.g);this.b=(this.b<0||isNaN(this.b))?0:((this.b>255)?255:this.b);this.toRGB=function(){return"rgb("+this.r+", "+this.g+", "+this.b+")"};this.toHex=function(){var k=this.r.toString(16);var j=this.g.toString(16);var i=this.b.toString(16);if(k.length==1){k="0"+k}if(j.length==1){j="0"+j}if(i.length==1){i="0"+i}return"#"+k+j+i}}Date.ext={};Date.ext.util={};Date.ext.util.xPad=function(a,c,b){if(typeof(b)=="undefined"){b=10}for(;parseInt(a,10)<b&&b>1;b/=10){a=c.toString()+a}return a.toString()};Date.prototype.locale="en-GB";if(document.getElementsByTagName("html")&&document.getElementsByTagName("html")[0].lang){Date.prototype.locale=document.getElementsByTagName("html")[0].lang}Date.ext.locales={};Date.ext.locales.en={a:["Sun","Mon","Tue","Wed","Thu","Fri","Sat"],A:["Sunday","Monday","Tuesday","Wednesday","Thursday","Friday","Saturday"],b:["Jan","Feb","Mar","Apr","May","Jun","Jul","Aug","Sep","Oct","Nov","Dec"],B:["January","February","March","April","May","June","July","August","September","October","November","December"],c:"%a %d %b %Y %T %Z",p:["AM","PM"],P:["am","pm"],x:"%d/%m/%y",X:"%T"};Date.ext.locales["en-US"]=Date.ext.locales.en;Date.ext.locales["en-US"].c="%a %d %b %Y %r %Z";Date.ext.locales["en-US"].x="%D";Date.ext.locales["en-US"].X="%r";Date.ext.locales["en-GB"]=Date.ext.locales.en;Date.ext.locales["en-AU"]=Date.ext.locales["en-GB"];Date.ext.formats={a:function(a){return Date.ext.locales[a.locale].a[a.getDay()]},A:function(a){return Date.ext.locales[a.locale].A[a.getDay()]},b:function(a){return Date.ext.locales[a.locale].b[a.getMonth()]},B:function(a){return Date.ext.locales[a.locale].B[a.getMonth()]},c:"toLocaleString",C:function(a){return Date.ext.util.xPad(parseInt(a.getFullYear()/100,10),0)},d:["getDate","0"],e:["getDate"," "],g:function(a){return Date.ext.util.xPad(parseInt(Date.ext.util.G(a)/100,10),0)},G:function(c){var e=c.getFullYear();var b=parseInt(Date.ext.formats.V(c),10);var a=parseInt(Date.ext.formats.W(c),10);if(a>b){e++}else{if(a===0&&b>=52){e--}}return e},H:["getHours","0"],I:function(b){var a=b.getHours()%12;return Date.ext.util.xPad(a===0?12:a,0)},j:function(c){var a=c-new Date(""+c.getFullYear()+"/1/1 GMT");a+=c.getTimezoneOffset()*60000;var b=parseInt(a/60000/60/24,10)+1;return Date.ext.util.xPad(b,0,100)},m:function(a){return Date.ext.util.xPad(a.getMonth()+1,0)},M:["getMinutes","0"],p:function(a){return Date.ext.locales[a.locale].p[a.getHours()>=12?1:0]},P:function(a){return Date.ext.locales[a.locale].P[a.getHours()>=12?1:0]},S:["getSeconds","0"],u:function(a){var b=a.getDay();return b===0?7:b},U:function(e){var a=parseInt(Date.ext.formats.j(e),10);var c=6-e.getDay();var b=parseInt((a+c)/7,10);return Date.ext.util.xPad(b,0)},V:function(e){var c=parseInt(Date.ext.formats.W(e),10);var a=(new Date(""+e.getFullYear()+"/1/1")).getDay();var b=c+(a>4||a<=1?0:1);if(b==53&&(new Date(""+e.getFullYear()+"/12/31")).getDay()<4){b=1}else{if(b===0){b=Date.ext.formats.V(new Date(""+(e.getFullYear()-1)+"/12/31"))}}return Date.ext.util.xPad(b,0)},w:"getDay",W:function(e){var a=parseInt(Date.ext.formats.j(e),10);var c=7-Date.ext.formats.u(e);var b=parseInt((a+c)/7,10);return Date.ext.util.xPad(b,0,10)},y:function(a){return Date.ext.util.xPad(a.getFullYear()%100,0)},Y:"getFullYear",z:function(c){var b=c.getTimezoneOffset();var a=Date.ext.util.xPad(parseInt(Math.abs(b/60),10),0);var e=Date.ext.util.xPad(b%60,0);return(b>0?"-":"+")+a+e},Z:function(a){return a.toString().replace(/^.*\(([^)]+)\)$/,"$1")},"%":function(a){return"%"}};Date.ext.aggregates={c:"locale",D:"%m/%d/%y",h:"%b",n:"\n",r:"%I:%M:%S %p",R:"%H:%M",t:"\t",T:"%H:%M:%S",x:"locale",X:"locale"};Date.ext.aggregates.z=Date.ext.formats.z(new Date());Date.ext.aggregates.Z=Date.ext.formats.Z(new Date());Date.ext.unsupported={};Date.prototype.strftime=function(a){if(!(this.locale in Date.ext.locales)){if(this.locale.replace(/-[a-zA-Z]+$/,"") in Date.ext.locales){this.locale=this.locale.replace(/-[a-zA-Z]+$/,"")}else{this.locale="en-GB"}}var c=this;while(a.match(/%[cDhnrRtTxXzZ]/)){a=a.replace(/%([cDhnrRtTxXzZ])/g,function(e,d){var g=Date.ext.aggregates[d];return(g=="locale"?Date.ext.locales[c.locale][d]:g)})}var b=a.replace(/%([aAbBCdegGHIjmMpPSuUVwWyY%])/g,function(e,d){var g=Date.ext.formats[d];if(typeof(g)=="string"){return c[g]()}else{if(typeof(g)=="function"){return g.call(c,c)}else{if(typeof(g)=="object"&&typeof(g[0])=="string"){return Date.ext.util.xPad(c[g[0]].."]]"..[[(),g[1])}else{return d}}}});c=null;return b};]]
createResourceFile(resourceFile,"dygraph-combined.js")


resourceFile = [[
// Copyright 2011 Paul Felix (paul.eric.felix@gmail.com)
// All Rights Reserved.

/**
 * @fileoverview This file contains the DygraphRangeSelector class used to provide
 * a timeline range selector widget for dygraphs.
 */

"use strict";

/**
 * The DygraphRangeSelector class provides a timeline range selector widget.
 * @param {Dygraph} dygraph The dygraph object
 * @constructor
 */
var DygraphRangeSelector = function(dygraph) {
  this.isIE_ = /MSIE/.test(navigator.userAgent) && !window.opera;
  this.isUsingExcanvas_ = dygraph.isUsingExcanvas_;
  this.dygraph_ = dygraph;
  this.createCanvases_();
  if (this.isUsingExcanvas_) {
    this.createIEPanOverlay_();
  }
  this.createZoomHandles_();
  this.initInteraction_();
};

/**
 * Adds the range selector to the dygraph.
 * @param {Object} graphDiv The container div for the range selector.
 * @param {DygraphLayout} layout The DygraphLayout object for this graph.
 */
DygraphRangeSelector.prototype.addToGraph = function(graphDiv, layout) {
  this.layout_ = layout;
  this.resize_();
  graphDiv.appendChild(this.bgcanvas_);
  graphDiv.appendChild(this.fgcanvas_);
  graphDiv.appendChild(this.leftZoomHandle_);
  graphDiv.appendChild(this.rightZoomHandle_);
};

/**
 * Renders the static background portion of the range selector.
 */
DygraphRangeSelector.prototype.renderStaticLayer = function() {
  this.resize_();
  this.drawStaticLayer_();
};

/**
 * Renders the interactive foreground portion of the range selector.
 */
DygraphRangeSelector.prototype.renderInteractiveLayer = function() {
  if (this.isChangingRange_) {
    return;
  }
  this.placeZoomHandles_();
  this.drawInteractiveLayer_();
};

/**
 * @private
 * Resizes the range selector.
 */
DygraphRangeSelector.prototype.resize_ = function() {
  function setElementRect(canvas, rect) {
    canvas.style.top = rect.y + 'px';
    canvas.style.left = rect.x + 'px';
    canvas.width = rect.w;
    canvas.height = rect.h;
    canvas.style.width = canvas.width + 'px';    // for IE
    canvas.style.height = canvas.height + 'px';  // for IE
  };

  var plotArea = this.layout_.getPlotArea();
  var xAxisLabelHeight = this.attr_('axisLabelFontSize') + 2 * this.attr_('axisTickSize');
  this.canvasRect_ = {
    x: plotArea.x,
    y: plotArea.y + plotArea.h + xAxisLabelHeight + 4,
    w: plotArea.w,
    h: this.attr_('rangeSelectorHeight')
  };

  setElementRect(this.bgcanvas_, this.canvasRect_);
  setElementRect(this.fgcanvas_, this.canvasRect_);
};

DygraphRangeSelector.prototype.attr_ = function(name) {
  return this.dygraph_.attr_(name);
};

/**
 * @private
 * Creates the background and foreground canvases.
 */
DygraphRangeSelector.prototype.createCanvases_ = function() {
  this.bgcanvas_ = Dygraph.createCanvas();
  this.bgcanvas_.className = 'dygraph-rangesel-bgcanvas';
  this.bgcanvas_.style.position = 'absolute';
  this.bgcanvas_.style.zIndex = 9;
  this.bgcanvas_ctx_ = Dygraph.getContext(this.bgcanvas_);

  this.fgcanvas_ = Dygraph.createCanvas();
  this.fgcanvas_.className = 'dygraph-rangesel-fgcanvas';
  this.fgcanvas_.style.position = 'absolute';
  this.fgcanvas_.style.zIndex = 9;
  this.fgcanvas_.style.cursor = 'default';
  this.fgcanvas_ctx_ = Dygraph.getContext(this.fgcanvas_);
};

/**
 * @private
 * Creates overlay divs for IE/Excanvas so that mouse events are handled properly.
 */
DygraphRangeSelector.prototype.createIEPanOverlay_ = function() {
  this.iePanOverlay_ = document.createElement("div");
  this.iePanOverlay_.style.position = 'absolute';
  this.iePanOverlay_.style.backgroundColor = 'white';
  this.iePanOverlay_.style.filter = 'alpha(opacity=0)';
  this.iePanOverlay_.style.display = 'none';
  this.iePanOverlay_.style.cursor = 'move';
  this.fgcanvas_.appendChild(this.iePanOverlay_);
};

/**
 * @private
 * Creates the zoom handle elements.
 */
DygraphRangeSelector.prototype.createZoomHandles_ = function() {
  var img = new Image();
  img.className = 'dygraph-rangesel-zoomhandle';
  img.style.position = 'absolute';
  img.style.zIndex = 10;
  img.style.visibility = 'hidden'; // Initially hidden so they don't show up in the wrong place.
  img.style.cursor = 'col-resize';
  if (/MSIE 7/.test(navigator.userAgent)) { // IE7 doesn't support embedded src data.
      img.width = 7;
      img.height = 14;
      img.style.backgroundColor = 'white';
      img.style.border = '1px solid #333333'; // Just show box in IE7.
  } else {
      img.width = 9;
      img.height = 16;
      img.src = 'data:image/png;base64,\
iVBORw0KGgoAAAANSUhEUgAAAAkAAAAQCAYAAADESFVDAAAAAXNSR0IArs4c6QAAAAZiS0dEANAA\
zwDP4Z7KegAAAAlwSFlzAAAOxAAADsQBlSsOGwAAAAd0SU1FB9sHGw0cMqdt1UwAAAAZdEVYdENv\
bW1lbnQAQ3JlYXRlZCB3aXRoIEdJTVBXgQ4XAAAAaElEQVQoz+3SsRFAQBCF4Z9WJM8KCDVwownl\
6YXsTmCUsyKGkZzcl7zkz3YLkypgAnreFmDEpHkIwVOMfpdi9CEEN2nGpFdwD03yEqDtOgCaun7s\
qSTDH32I1pQA2Pb9sZecAxc5r3IAb21d6878xsAAAAAASUVORK5CYII=';
  }

  this.leftZoomHandle_ = img;
  this.rightZoomHandle_ = img.cloneNode(false);
};

/**
 * @private
 * Sets up the interaction for the range selector.
 */
DygraphRangeSelector.prototype.initInteraction_ = function() {
  var self = this;
  var topElem = this.isIE_ ? document : window;
  var xLast = 0;
  var handle = null;
  var isZooming = false;
  var isPanning = false;

  function toXDataWindow(zoomHandleStatus) {
    var xDataLimits = self.dygraph_.xAxisExtremes();
    var fact = (xDataLimits[1] - xDataLimits[0])/self.canvasRect_.w;
    var xDataMin = xDataLimits[0] + (zoomHandleStatus.leftHandlePos - self.canvasRect_.x)*fact;
    var xDataMax = xDataLimits[0] + (zoomHandleStatus.rightHandlePos - self.canvasRect_.x)*fact;
    return [xDataMin, xDataMax];
  };

  function onZoomStart(e) {
    Dygraph.cancelEvent(e);
    isZooming = true;
    xLast = e.screenX;
    handle = e.target ? e.target : e.srcElement;
    Dygraph.addEvent(topElem, 'mousemove', onZoom);
    Dygraph.addEvent(topElem, 'mouseup', onZoomEnd);
    self.fgcanvas_.style.cursor = 'col-resize';
  };

  function onZoom(e) {
    if (!isZooming) {
      return;
    }
    var delX = e.screenX - xLast;
    if (Math.abs(delX) < 4) {
      return;
    }
    xLast = e.screenX;
    var zoomHandleStatus = self.getZoomHandleStatus_();
    if (handle == self.leftZoomHandle_) {
      var newPos = zoomHandleStatus.leftHandlePos + delX;
      newPos = Math.min(newPos, zoomHandleStatus.rightHandlePos - handle.width - 3);
      newPos = Math.max(newPos, self.canvasRect_.x);
    } else {
      var newPos = zoomHandleStatus.rightHandlePos + delX;
      newPos = Math.min(newPos, self.canvasRect_.x + self.canvasRect_.w);
      newPos = Math.max(newPos, zoomHandleStatus.leftHandlePos + handle.width + 3);
    }
    var halfHandleWidth = handle.width/2;
    handle.style.left = (newPos - halfHandleWidth) + 'px';
    self.drawInteractiveLayer_();

    // Zoom on the fly (if not using excanvas).
    if (!self.isUsingExcanvas_) {
      doZoom();
    }
  };

  function onZoomEnd(e) {
    if (!isZooming) {
      return;
    }
    isZooming = false;
    Dygraph.removeEvent(topElem, 'mousemove', onZoom);
    Dygraph.removeEvent(topElem, 'mouseup', onZoomEnd);
    self.fgcanvas_.style.cursor = 'default';

    // If using excanvas, Zoom now.
    if (self.isUsingExcanvas_) {
      doZoom();
    }
  };

  function doZoom() {
    try {
      var zoomHandleStatus = self.getZoomHandleStatus_();
      self.isChangingRange_ = true;
      if (!zoomHandleStatus.isZoomed) {
        self.dygraph_.doUnzoom_();
      } else {
        var xDataWindow = toXDataWindow(zoomHandleStatus);
        self.dygraph_.doZoomXDates_(xDataWindow[0], xDataWindow[1]);
      }
    } finally {
      self.isChangingRange_ = false;
    }
  };

  function isMouseInPanZone(e) {
    if (self.isUsingExcanvas_) {
        return e.srcElement == self.iePanOverlay_;
    } else {
      // Getting clientX directly from the event is not accurate enough :(
      var clientX = self.canvasRect_.x + (e.layerX != undefined ? e.layerX : e.offsetX);
      var zoomHandleStatus = self.getZoomHandleStatus_();
      return (clientX > zoomHandleStatus.leftHandlePos && clientX < zoomHandleStatus.rightHandlePos);
    }
  };

  function onPanStart(e) {
    if (!isPanning && isMouseInPanZone(e) && self.getZoomHandleStatus_().isZoomed) {
      Dygraph.cancelEvent(e);
      isPanning = true;
      xLast = e.screenX;
      Dygraph.addEvent(topElem, 'mousemove', onPan);
      Dygraph.addEvent(topElem, 'mouseup', onPanEnd);
    }
  };

  function onPan(e) {
    if (!isPanning) {
      return;
    }
    Dygraph.cancelEvent(e);

    var delX = e.screenX - xLast;
    if (Math.abs(delX) < 4) {
      return;
    }
    xLast = e.screenX;

    // Move range view
    var zoomHandleStatus = self.getZoomHandleStatus_();
    var leftHandlePos = zoomHandleStatus.leftHandlePos;
    var rightHandlePos = zoomHandleStatus.rightHandlePos;
    var rangeSize = rightHandlePos - leftHandlePos;
    if (leftHandlePos + delX <= self.canvasRect_.x) {
      leftHandlePos = self.canvasRect_.x;
      rightHandlePos = leftHandlePos + rangeSize;
    } else if (rightHandlePos + delX >= self.canvasRect_.x + self.canvasRect_.w) {
      rightHandlePos = self.canvasRect_.x + self.canvasRect_.w;
      leftHandlePos = rightHandlePos - rangeSize;
    } else {
      leftHandlePos += delX;
      rightHandlePos += delX;
    }
    var halfHandleWidth = self.leftZoomHandle_.width/2;
    self.leftZoomHandle_.style.left = (leftHandlePos - halfHandleWidth) + 'px';
    self.rightZoomHandle_.style.left = (rightHandlePos - halfHandleWidth) + 'px';
    self.drawInteractiveLayer_();

    // Do pan on the fly (if not using excanvas).
    if (!self.isUsingExcanvas_) {
      doPan();
    }
  };

  function onPanEnd(e) {
    if (!isPanning) {
      return;
    }
    isPanning = false;
    Dygraph.removeEvent(topElem, 'mousemove', onPan);
    Dygraph.removeEvent(topElem, 'mouseup', onPanEnd);
    // If using excanvas, do pan now.
    if (self.isUsingExcanvas_) {
      doPan();
    }
  };

  function doPan() {
    try {
      self.isChangingRange_ = true;
      self.dygraph_.dateWindow_ = toXDataWindow(self.getZoomHandleStatus_());
      self.dygraph_.drawGraph_(false);
    } finally {
      self.isChangingRange_ = false;
    }
  };

  function onCanvasMouseMove(e) {
    if (isZooming || isPanning) {
      return;
    }
    var cursor = isMouseInPanZone(e) ? 'move' : 'default';
    if (cursor != self.fgcanvas_.style.cursor) {
      self.fgcanvas_.style.cursor = cursor;
    }
  };

  var interactionModel = {
    mousedown: function(event, g, context) {
      context.initializeMouseDown(event, g, context);
      Dygraph.startPan(event, g, context);
    },
    mousemove: function(event, g, context) {
      if (context.isPanning) {
        Dygraph.movePan(event, g, context);
      }
    },
    mouseup: function(event, g, context) {
      if (context.isPanning) {
        Dygraph.endPan(event, g, context);
      }
    }
  };

  this.dygraph_.attrs_.interactionModel = interactionModel;
  this.dygraph_.attrs_.panEdgeFraction = .0001;

  var dragStartEvent = window.opera ? 'mousedown' : 'dragstart';
  Dygraph.addEvent(this.leftZoomHandle_, dragStartEvent, onZoomStart);
  Dygraph.addEvent(this.rightZoomHandle_, dragStartEvent, onZoomStart);

  if (this.isUsingExcanvas_) {
    Dygraph.addEvent(this.iePanOverlay_, 'mousedown', onPanStart);
  } else {
    Dygraph.addEvent(this.fgcanvas_, 'mousedown', onPanStart);
    Dygraph.addEvent(this.fgcanvas_, 'mousemove', onCanvasMouseMove);
  }
};

/**
 * @private
 * Draws the static layer in the background canvas.
 */
DygraphRangeSelector.prototype.drawStaticLayer_ = function() {
  var ctx = this.bgcanvas_ctx_;
  ctx.clearRect(0, 0, this.canvasRect_.w, this.canvasRect_.h);
  try {
    this.drawMiniPlot_();
  } catch(ex) {
    Dygraph.warn(ex);
  }

  var margin = .5;
  this.bgcanvas_ctx_.lineWidth = 1;
  ctx.strokeStyle = 'gray';
  ctx.beginPath();
  ctx.moveTo(margin, margin);
  ctx.lineTo(margin, this.canvasRect_.h-margin);
  ctx.lineTo(this.canvasRect_.w-margin, this.canvasRect_.h-margin);
  ctx.lineTo(this.canvasRect_.w-margin, margin);
  ctx.stroke();
};


/**
 * @private
 * Draws the mini plot in the background canvas.
 */
DygraphRangeSelector.prototype.drawMiniPlot_ = function() {
  var fillStyle = this.attr_('rangeSelectorPlotFillColor');
  var strokeStyle = this.attr_('rangeSelectorPlotStrokeColor');
  if (!fillStyle && !strokeStyle) {
    return;
  }

  var combinedSeriesData = this.computeCombinedSeriesAndLimits_();
  var yRange = combinedSeriesData.yMax - combinedSeriesData.yMin;

  // Draw the mini plot.
  var ctx = this.bgcanvas_ctx_;
  var margin = .5;

  var xExtremes = this.dygraph_.xAxisExtremes();
  var xRange = Math.max(xExtremes[1] - xExtremes[0], 1.e-30);
  var xFact = (this.canvasRect_.w - margin)/xRange;
  var yFact = (this.canvasRect_.h - margin)/yRange;
  var canvasWidth = this.canvasRect_.w - margin;
  var canvasHeight = this.canvasRect_.h - margin;

  ctx.beginPath();
  ctx.moveTo(margin, canvasHeight);
  for (var i = 0; i < combinedSeriesData.data.length; i++) {
    var dataPoint = combinedSeriesData.data[i];
    var x = (dataPoint[0] - xExtremes[0])*xFact;
    var y = canvasHeight - (dataPoint[1] - combinedSeriesData.yMin)*yFact;
    if (isFinite(x) && isFinite(y)) {
      ctx.lineTo(x, y);
    }
  }
  ctx.lineTo(canvasWidth, canvasHeight);
  ctx.closePath();

  if (fillStyle) {
    var lingrad = this.bgcanvas_ctx_.createLinearGradient(0, 0, 0, canvasHeight);
    lingrad.addColorStop(0, 'white');
    lingrad.addColorStop(1, fillStyle);
    this.bgcanvas_ctx_.fillStyle = lingrad;
    ctx.fill();
  }

  if (strokeStyle) {
    this.bgcanvas_ctx_.strokeStyle = strokeStyle;
    this.bgcanvas_ctx_.lineWidth = 1.5;
    ctx.stroke();
  }
};

/**
 * @private
 * Computes and returns the combinded series data along with min/max for the mini plot.
 * @return {Object} An object containing combinded series array, ymin, ymax.
 */
DygraphRangeSelector.prototype.computeCombinedSeriesAndLimits_ = function() {
  var data = this.dygraph_.rawData_;
  var logscale = this.attr_('logscale');

  // Create a combined series (average of all series values).
  var combinedSeries = [];
  var sum;
  var count;
  var mutipleValues = typeof data[0][1] != 'number';

  if (mutipleValues) {
    sum = [];
    count = [];
    for (var k = 0; k < data[0][1].length; k++) {
      sum.push(0);
      count.push(0);
    }
    mutipleValues = true;
  }

  for (var i = 0; i < data.length; i++) {
    var dataPoint = data[i];
    var xVal = dataPoint[0];
    var yVal;

    if (mutipleValues) {
      for (var k = 0; k < sum.length; k++) {
        sum[k] = count[k] = 0;
      }
    } else {
      sum = count = 0;
    }

    for (var j = 1; j < dataPoint.length; j++) {
      if (this.dygraph_.visibility()[j-1]) {
        if (mutipleValues) {
          for (var k = 0; k < sum.length; k++) {
            var y = dataPoint[j][k];
            if (y == null || isNaN(y)) continue;
            sum[k] += y;
            count[k]++;
          }
        } else {
          var y = dataPoint[j];
          if (y == null || isNaN(y)) continue;
          sum += y;
          count++;
        }
      }
    }

    if (mutipleValues) {
      for (var k = 0; k < sum.length; k++) {
        sum[k] /= count[k];
      }
      yVal = sum.slice(0);
    } else {
      yVal = sum/count;
    }

    combinedSeries.push([xVal, yVal]);
  }

  // Account for roll period, fractions.
  combinedSeries = this.dygraph_.rollingAverage(combinedSeries, this.dygraph_.rollPeriod_);

  if (typeof combinedSeries[0][1] != 'number') {
    for (var i = 0; i < combinedSeries.length; i++) {
      var yVal = combinedSeries[i][1];
      combinedSeries[i][1] = yVal[0];
    }
  }

  // Compute the y range.
  var yMin = Number.MAX_VALUE;
  var yMax = -Number.MAX_VALUE;
  for (var i = 0; i < combinedSeries.length; i++) {
    var yVal = combinedSeries[i][1];
    if (yVal != null && isFinite(yVal) && (!logscale || yVal > 0)) {
      yMin = Math.min(yMin, yVal);
      yMax = Math.max(yMax, yVal);
    }
  }

  // Convert Y data to log scale if needed.
  // Also, expand the Y range to compress the mini plot a little.
  var extraPercent = .25;
  if (logscale) {
    yMax = Dygraph.log10(yMax);
    yMax += yMax*extraPercent;
    yMin = Dygraph.log10(yMin);
    for (var i = 0; i < combinedSeries.length; i++) {
      combinedSeries[i][1] = Dygraph.log10(combinedSeries[i][1]);
    }
  } else {
    var yExtra;
    var yRange = yMax - yMin;
    if (yRange <= Number.MIN_VALUE) {
      yExtra = yMax*extraPercent;
    } else {
      yExtra = yRange*extraPercent;
    }
    yMax += yExtra;
    yMin -= yExtra;
  }

  return {data: combinedSeries, yMin: yMin, yMax: yMax};
};

/**
 * @private
 * Places the zoom handles in the proper position based on the current X data window.
 */
DygraphRangeSelector.prototype.placeZoomHandles_ = function() {
  var xExtremes = this.dygraph_.xAxisExtremes();
  var xWindowLimits = this.dygraph_.xAxisRange();
  var xRange = xExtremes[1] - xExtremes[0];
  var leftPercent = Math.max(0, (xWindowLimits[0] - xExtremes[0])/xRange);
  var rightPercent = Math.max(0, (xExtremes[1] - xWindowLimits[1])/xRange);
  var leftCoord = this.canvasRect_.x + this.canvasRect_.w*leftPercent;
  var rightCoord = this.canvasRect_.x + this.canvasRect_.w*(1 - rightPercent);
  var handleTop = Math.max(this.canvasRect_.y, this.canvasRect_.y + (this.canvasRect_.h - this.leftZoomHandle_.height)/2);
  var halfHandleWidth = this.leftZoomHandle_.width/2;
  this.leftZoomHandle_.style.left = (leftCoord - halfHandleWidth) + 'px';
  this.leftZoomHandle_.style.top = handleTop + 'px';
  this.rightZoomHandle_.style.left = (rightCoord - halfHandleWidth) + 'px';
  this.rightZoomHandle_.style.top = this.leftZoomHandle_.style.top;

  this.leftZoomHandle_.style.visibility = 'visible';
  this.rightZoomHandle_.style.visibility = 'visible';
};

/**
 * @private
 * Draws the interactive layer in the foreground canvas.
 */
DygraphRangeSelector.prototype.drawInteractiveLayer_ = function() {
  var ctx = this.fgcanvas_ctx_;
  ctx.clearRect(0, 0, this.canvasRect_.w, this.canvasRect_.h);
  var margin = 1;
  var width = this.canvasRect_.w - margin;
  var height = this.canvasRect_.h - margin;
  var zoomHandleStatus = this.getZoomHandleStatus_();

  ctx.strokeStyle = 'black';
  if (!zoomHandleStatus.isZoomed) {
    ctx.beginPath();
    ctx.moveTo(margin, margin);
    ctx.lineTo(margin, height);
    ctx.lineTo(width, height);
    ctx.lineTo(width, margin);
    ctx.stroke();
    if (this.iePanOverlay_) {
      this.iePanOverlay_.style.display = 'none';
    }
  } else {
    var leftHandleCanvasPos = Math.max(margin, zoomHandleStatus.leftHandlePos - this.canvasRect_.x);
    var rightHandleCanvasPos = Math.min(width, zoomHandleStatus.rightHandlePos - this.canvasRect_.x);

    ctx.fillStyle = 'rgba(240, 240, 240, 0.6)';
    ctx.fillRect(0, 0, leftHandleCanvasPos, this.canvasRect_.h);
    ctx.fillRect(rightHandleCanvasPos, 0, this.canvasRect_.w - rightHandleCanvasPos, this.canvasRect_.h);

    ctx.beginPath();
    ctx.moveTo(margin, margin);
    ctx.lineTo(leftHandleCanvasPos, margin);
    ctx.lineTo(leftHandleCanvasPos, height);
    ctx.lineTo(rightHandleCanvasPos, height);
    ctx.lineTo(rightHandleCanvasPos, margin);
    ctx.lineTo(width, margin);
    ctx.stroke();

    if (this.isUsingExcanvas_) {
      this.iePanOverlay_.style.width = (rightHandleCanvasPos - leftHandleCanvasPos) + 'px';
      this.iePanOverlay_.style.left = leftHandleCanvasPos + 'px';
      this.iePanOverlay_.style.height = height + 'px';
      this.iePanOverlay_.style.display = 'inline';
    }
  }
};

/**
 * @private
 * Returns the current zoom handle position information.
 * @return {Object} The zoom handle status.
 */
DygraphRangeSelector.prototype.getZoomHandleStatus_ = function() {
  var halfHandleWidth = this.leftZoomHandle_.width/2;
  var leftHandlePos = parseInt(this.leftZoomHandle_.style.left) + halfHandleWidth;
  var rightHandlePos = parseInt(this.rightZoomHandle_.style.left) + halfHandleWidth;
  return {
      leftHandlePos: leftHandlePos,
      rightHandlePos: rightHandlePos,
      isZoomed: (leftHandlePos - 1 > this.canvasRect_.x || rightHandlePos + 1 < this.canvasRect_.x+this.canvasRect_.w)
  };
};
]]
createResourceFile(resourceFile,"dygraph-dygraph-range-selector.js")

resourceFile = [[<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Transitional//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-transitional.dtd">
<html xmlns="http://www.w3.org/1999/xhtml" xml:lang="en" lang="en">
<head>

<meta http-equiv="Content-Type" content="text/html; charset=UTF-8" />
<title>Icicle - Icicle Tree with static JSON data</title>

<!-- CSS Files -->
<link type="text/css" href="base.css" rel="stylesheet" />
<link type="text/css" href="Icicle.css" rel="stylesheet" />

<!--[if IE]><script language="javascript" type="text/javascript" src="../../Extras/excanvas.js"></script><![endif]-->

<!-- JIT Library File -->
<script language="javascript" type="text/javascript" src="jit.js"></script>
<script language="javascript" type="text/javascript" src="jsonData.js"></script>

<!-- Example File -->
<script language="javascript" type="text/javascript" src="profiler.js"></script>

</head>

<body onload="init();">

<div id="container">

<div id="left-container">

<div class="text">

  <h4>
    Icicle Plot of Your Program
  </h4>
  
            <p>Your program profile is shown here.</p>
            <p>
              <b>Left click</b> to zoom in on a particular function.
            </p>
            <p>
              <b>Right click</b> to zoom out.
            </p>
            

  <div>
    <label for="s-orientation">Orientation: </label>
    <select name="s-orientation" id="s-orientation">
      <option value="h" selected>horizontal</option>
      <option value="v">vertical</option>
    </select>
    <br>
    <div id="max-levels">
    <label for="i-levels-to-show">Max levels: </label>
    <select  id="i-levels-to-show" name="i-levels-to-show" style="width: 50px">
      <option>all</option>
      <option>1</option>
      <option>2</option>
      <option selected="selected">3</option>
      <option>4</option>
      <option>5</option>
    </select>
    </div>
  </div>
</div>

<a id="update" href="#" class="theme button white">Go to Parent</a>
 
<div id="id-list"></div>


          
</div>

<div id="center-container">
    <div id="infovis"></div>    
</div>

<div id="right-container">

<div id="inner-details"></div>

</div>

<div id="log"></div>
</div>

</body>
</html>
]]
createResourceFile(resourceFile,"profileTime.html")
resourceFile = nil
end

return profilerTable