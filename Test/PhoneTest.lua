-- [yue]: Test/PhoneTest.yue
local Path = Dora.Path -- 1
local Content = Dora.Content -- 1
local Director = Dora.Director -- 1
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
local LsdOSBack = require("UI.LsdOSBack") -- 14
local Phone = require("UI.Phone") -- 15
Director.ui3D:addChild((function() -- 17
	local _with_0 = LsdOSBack() -- 17
	_with_0:alignLayout() -- 18
	return _with_0 -- 17
end)()) -- 17
return Director.ui3D:addChild(Phone()) -- 19
