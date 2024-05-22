-- [yue]: Test/TrainingTest.yue
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
local Training = require("UI.Training") -- 14
return Director.ui3D:addChild((function() -- 16
	local _with_0 = Training() -- 16
	_with_0:alignLayout() -- 17
	return _with_0 -- 16
end)()) -- 17
