-- [yue]: Script/System/PlayBubbleChat.yue
local type = _G.type -- 1
local Group = Dora.Group -- 1
local thread = Dora.thread -- 1
local emit = Dora.emit -- 1
local tostring = _G.tostring -- 1
local sleep = Dora.sleep -- 1
local math = _G.math -- 1
local _module_0 = nil -- 1
local Bubble = require("UI.Bubble") -- 3
local YarnRunner = require("YarnRunner") -- 4
local Config = require("Data.Config") -- 5
local Command = require("System.Command") -- 6
local u8 = require("utf-8") -- 7
local getCharName -- 9
getCharName = function(current) -- 9
	if current.marks then -- 10
		local _list_0 = current.marks -- 11
		for _index_0 = 1, #_list_0 do -- 11
			local mark = _list_0[_index_0] -- 11
			local _type_0 = type(mark) -- 12
			local _tab_0 = "table" == _type_0 or "userdata" == _type_0 -- 12
			if _tab_0 then -- 12
				local attr = mark.name -- 12
				local name -- 12
				do -- 12
					local _obj_0 = mark.attrs -- 12
					local _type_1 = type(_obj_0) -- 12
					if "table" == _type_1 or "userdata" == _type_1 then -- 12
						name = _obj_0.name -- 12
					end -- 15
				end -- 15
				local id -- 12
				do -- 12
					local _obj_0 = mark.attrs -- 12
					local _type_1 = type(_obj_0) -- 12
					if "table" == _type_1 or "userdata" == _type_1 then -- 12
						id = _obj_0.id -- 12
					end -- 15
				end -- 15
				if name == nil then -- 12
					name = '' -- 12
				end -- 12
				if id == nil then -- 12
					id = '' -- 12
				end -- 12
				if attr ~= nil then -- 12
					if ("char" == attr or "Character" == attr) then -- 13
						if id == "char" then -- 14
							id = Config.char -- 14
						end -- 14
						return name, id -- 15
					end -- 13
				end -- 12
			end -- 15
		end -- 15
	end -- 10
	return '', '' -- 16
end -- 9
_module_0 = function(file) -- 18
	local runner = YarnRunner(file, "Start", Config, Command) -- 19
	local unitGroup = Group({ -- 20
		"unit", -- 20
		"name" -- 20
	}) -- 20
	return thread(function() -- 21
		repeat -- 21
			local itemType, result = runner:advance() -- 22
			if "Text" == itemType then -- 23
				local name, characterId = getCharName(result) -- 24
				local text = result.text -- 25
				local entity = unitGroup:find(function(self) -- 26
					return self.name == characterId -- 26
				end) -- 26
				if entity then -- 26
					local unit = entity.unit -- 27
					do -- 28
						local bubble = unit:getChildByTag("bubble") -- 28
						if bubble then -- 28
							bubble:removeFromParent() -- 29
						end -- 28
					end -- 28
					unit:addChild(Bubble({ -- 30
						text = text -- 30
					})) -- 30
					emit("MessageBox.Add", { -- 31
						title = "对话", -- 31
						special = false, -- 31
						text = tostring(name) .. "：" .. tostring(text) -- 31
					}) -- 31
					sleep(math.max(1, 0.15 * u8.len(text))) -- 32
				end -- 26
			else -- 34
				return -- 34
			end -- 34
		until false -- 35
	end) -- 35
end -- 18
return _module_0 -- 35
