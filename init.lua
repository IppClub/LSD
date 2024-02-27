-- [yue]: init.yue
local Path = dora.Path -- 1
local Content = dora.Content -- 1
do -- 3
	local scriptPath = Path:getScriptPath(...) -- 3
	if scriptPath then -- 3
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
		return require("Start") -- 12
	end -- 3
end -- 3
