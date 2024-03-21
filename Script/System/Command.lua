-- [yue]: Script/System/Command.yue
local setmetatable = _G.setmetatable -- 1
local coroutine = _G.coroutine -- 1
local once = dora.once -- 1
local sleep = dora.sleep -- 1
local Director = dora.Director -- 1
local emit = dora.emit -- 1
local print = _G.print -- 1
local tostring = _G.tostring -- 1
local table = _G.table -- 1
local select = _G.select -- 1
local _module_0 = nil -- 1
local Config = require("Data.Config") -- 2
local u8 = require("utf-8") -- 3
local _anon_func_0 = function(select, tostring, ...) -- 24
	local _accum_0 = { } -- 24
	local _len_0 = 1 -- 24
	for i = 1, select('#', ...) do -- 24
		_accum_0[_len_0] = tostring(select(i, ...)) -- 24
		_len_0 = _len_0 + 1 -- 24
	end -- 24
	return _accum_0 -- 24
end -- 24
local commands = setmetatable({ -- 6
	preload = function(...) -- 6
		return coroutine.yield("Command", { -- 7
			preload = { -- 7
				... -- 7
			} -- 7
		}) -- 7
	end, -- 6
	inputName = function() -- 8
		local InputBox = require("UI.InputBox") -- 9
		local _with_0 = InputBox({ -- 10
			hint = "请输入你的姓名" -- 10
		}) -- 10
		_with_0.visible = false -- 11
		_with_0:schedule(once(function() -- 12
			sleep() -- 13
			_with_0.visible = true -- 14
		end)) -- 12
		_with_0:addTo(Director.ui3D) -- 15
		_with_0:slot("Inputed", function(name) -- 16
			if name == "" then -- 17
				name = "匿名玩家" -- 17
			end -- 17
			Config.charName = u8.sub(name, 1, 10) -- 18
			_with_0:removeFromParent() -- 19
			return emit("Story.Advance") -- 20
		end) -- 16
		coroutine.yield("Command") -- 21
		return _with_0 -- 10
	end, -- 8
	setCharId = function(charId) -- 22
		Config.char = charId -- 22
	end, -- 22
}, { -- 23
	__index = function(_self, name) -- 23
		return function(...) -- 23
			return print("[command]: " .. tostring(name) .. "(" .. tostring(table.concat(_anon_func_0(select, tostring, ...), ', ')) .. ")") -- 24
		end -- 24
	end -- 23
}) -- 5
_module_0 = commands -- 27
return _module_0 -- 27
