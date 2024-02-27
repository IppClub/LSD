-- [yue]: Test/LoopTowerTest.yue
local Path = dora.Path -- 1
local Content = dora.Content -- 1
local Director = dora.Director -- 1
local Node = dora.Node -- 1
local View = dora.View -- 1
local math = _G.math -- 1
local Sprite = dora.Sprite -- 1
local Vec2 = dora.Vec2 -- 1

do -- 3
	local scriptPath = Path:getScriptPath(...) -- 3
	if scriptPath then -- 3
		scriptPath = Path:getPath(scriptPath) -- 4
		local _list_0 = { -- 6
			scriptPath, -- 6
			Path(scriptPath, "Script"), -- 7
			Path(scriptPath, "Spine"), -- 8
			Path(scriptPath, "Image"), -- 9
			Path(scriptPath, "Font") -- 10
		} -- 5
		for _index_0 = 1, #_list_0 do -- 11
			local path = _list_0[_index_0] -- 5
			Content:insertSearchPath(1, path) -- 12
		end -- 12
	else -- 13
		return -- 13
	end -- 3
end -- 3
return Director.entry:addChild((function() -- 15
	local _with_0 = Node() -- 15
	_with_0.scaleX = 1 -- 16
	_with_0.scaleY = 1 -- 17
	_with_0.size = View.size -- 18
	_with_0.height = _with_0.height + 600 -- 19
	do -- 20
		local _with_1 = _with_0:grab(10, 1) -- 20
		for x = 1, 11 do -- 21
			for y = 1, 2 do -- 22
				local pos = _with_1:getPos(x, y) -- 23
				_with_1:setPos(x, y, pos, math.sin(math.abs(x - 6) * math.pi / 50) * math.abs(x - 6) * 200) -- 24
			end -- 24
		end -- 24
	end -- 20
	_with_0:addChild((function() -- 25
		local _with_1 = Sprite("Image/loopTower.png") -- 25
		_with_1.position = Vec2(0.5, 0.5) * View.size -- 26
		_with_1.y = _with_1.y + 350 -- 27
		local scale = View.size.height / 1563 -- 28
		_with_1.scaleX = scale -- 29
		_with_1.scaleY = scale -- 30
		return _with_1 -- 25
	end)()) -- 25
	return _with_0 -- 15
end)()) -- 30
