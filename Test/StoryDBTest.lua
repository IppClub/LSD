-- [yue]: Test/StoryDBTest.yue
local Path = dora.Path -- 1
local Content = dora.Content -- 1
local DB = dora.DB -- 1
local tostring = _G.tostring -- 1
local Director = dora.Director -- 1
local Node = dora.Node -- 1
local once = dora.once -- 1
local p = _G.p -- 1

do -- 2
	local scriptPath = Path:getScriptPath(...) -- 2
	if scriptPath then -- 2
		scriptPath = Path:getPath(scriptPath) -- 3
		local _list_0 = { -- 5
			scriptPath, -- 5
			Path(scriptPath, "Script"), -- 6
			Path(scriptPath, "Spine"), -- 7
			Path(scriptPath, "Image"), -- 8
			Path(scriptPath, "Font") -- 9
		} -- 4
		for _index_0 = 1, #_list_0 do -- 10
			local path = _list_0[_index_0] -- 4
			Content:insertSearchPath(1, path) -- 11
		end -- 11
	else -- 12
		return -- 12
	end -- 2
end -- 2
DB:exec("ATTACH DATABASE '" .. tostring(Path(Content.writablePath, "lsd.db")) .. "' AS lsd;") -- 14
Director.entry:slot("Cleanup", function() -- 15
	return DB:exec("DETACH DATABASE lsd") -- 15
end) -- 15
local StoryLoader = require("Data.StoryLoader") -- 17
return Director.entry:addChild((function() -- 19
	local _with_0 = Node() -- 19
	_with_0:schedule(once(function() -- 20
		StoryLoader() -- 21
		p(DB:query("select c.name, p.sentence from lsd.Paragraph p, lsd.Character c where p.story_id = 1 and p.conversation_id = 1 and p.character_id = c.id order by p.id", true)) -- 22
		return p(DB:query("select id, name from lsd.Character")) -- 23
	end)) -- 20
	return _with_0 -- 19
end)()) -- 23
