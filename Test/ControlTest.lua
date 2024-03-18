-- [yue]: Test/ControlTest.yue
local Path = dora.Path -- 1
local Content = dora.Content -- 1
local Director = dora.Director -- 1
local thread = dora.thread -- 1
local sleep = dora.sleep -- 1
local emit = dora.emit -- 1
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
local HUDControl = require("UI.HUDControl") -- 15
Director.ui3D:addChild((function() -- 17
	local _with_0 = LsdOSBack() -- 17
	_with_0:alignLayout() -- 18
	return _with_0 -- 17
end)()) -- 17
Director.ui3D:addChild(HUDControl()) -- 20
return thread(function() -- 22
	sleep(1) -- 23
	emit("MessageBox", { -- 24
		title = "社交", -- 24
		special = false, -- 24
		text = "你借调的学员默翎获得了3个赞" -- 24
	}) -- 24
	sleep(1) -- 25
	return emit("MessageBox", { -- 26
		title = "系统", -- 26
		special = true, -- 26
		text = "你借调的学员默翎获得了3个赞" -- 26
	}) -- 26
end) -- 26
