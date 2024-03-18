-- [yue]: Test/ChatTest.yue
local Path = dora.Path -- 1
local Content = dora.Content -- 1
local Director = dora.Director -- 1
local print = _G.print -- 1
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
local Interaction = require("UI.Interaction") -- 15
local MessageBox = require("UI.MessageBox") -- 16
local Bubble = require("UI.Bubble") -- 17
return Director.ui3D:addChild((function() -- 19
	local _with_0 = LsdOSBack() -- 19
	_with_0.bg:addChild((function() -- 20
		local _with_1 = Interaction({ -- 20
			text = "妮妮莉特", -- 20
			buttons = { -- 21
				{ -- 21
					"对话", -- 21
					"TALK" -- 21
				}, -- 21
				{ -- 22
					"进行训练", -- 22
					"TRAINING" -- 22
				}, -- 22
				{ -- 23
					"个人信息", -- 23
					"INFORMATION" -- 23
				} -- 23
			} -- 20
		}) -- 20
		_with_1:show() -- 25
		_with_1:slot("Tapped", function(index) -- 26
			return print(index) -- 26
		end) -- 26
		return _with_1 -- 20
	end)()) -- 20
	_with_0.bg:addChild((function() -- 27
		local _with_1 = MessageBox() -- 27
		_with_1.x = -600 -- 28
		return _with_1 -- 27
	end)()) -- 27
	_with_0.bg:addChild((function() -- 29
		local _with_1 = Bubble({ -- 29
			text = "聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字，聊天文字" -- 29
		}) -- 29
		_with_1.x = 600 -- 30
		return _with_1 -- 29
	end)()) -- 29
	_with_0:alignLayout() -- 31
	return _with_0 -- 19
end)()) -- 31
