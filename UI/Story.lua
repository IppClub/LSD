-- [yue]: UI/Story.yue
local type = _G.type -- 1
local Class = Dora.Class -- 1
local property = Dora.property -- 1
local thread = Dora.thread -- 1
local Cache = Dora.Cache -- 1
local tostring = _G.tostring -- 1
local sleep = Dora.sleep -- 1
local View = Dora.View -- 1
local Pass = Dora.Pass -- 1
local SpriteEffect = Dora.SpriteEffect -- 1
local emit = Dora.emit -- 1
local collectgarbage = _G.collectgarbage -- 1
local _module_0 = nil -- 1
local Story = require("UI.View.Story") -- 2
local StoryFigure = require("UI.StoryFigure") -- 3
local Answer = require("UI.Answer") -- 4
local Struct = require("Utils").Struct -- 5
local YarnRunner = require("YarnRunner") -- 6
local Config = require("Data.Config") -- 7
local Command = require("System.Command") -- 8
local Dialog = Struct.Story.Dialog("character", "name", "text") -- 10
local getCharName -- 12
getCharName = function(current) -- 12
	if current.marks then -- 13
		local _list_0 = current.marks -- 14
		for _index_0 = 1, #_list_0 do -- 14
			local mark = _list_0[_index_0] -- 14
			local _type_0 = type(mark) -- 15
			local _tab_0 = "table" == _type_0 or "userdata" == _type_0 -- 15
			if _tab_0 then -- 15
				local attr = mark.name -- 15
				local name -- 15
				do -- 15
					local _obj_0 = mark.attrs -- 15
					local _type_1 = type(_obj_0) -- 15
					if "table" == _type_1 or "userdata" == _type_1 then -- 15
						name = _obj_0.name -- 15
					end -- 18
				end -- 18
				local id -- 15
				do -- 15
					local _obj_0 = mark.attrs -- 15
					local _type_1 = type(_obj_0) -- 15
					if "table" == _type_1 or "userdata" == _type_1 then -- 15
						id = _obj_0.id -- 15
					end -- 18
				end -- 18
				if name == nil then -- 15
					name = '' -- 15
				end -- 15
				if id == nil then -- 15
					id = '' -- 15
				end -- 15
				if attr ~= nil then -- 15
					if ("char" == attr or "Character" == attr) then -- 16
						if id == "char" then -- 17
							id = Config.char -- 17
						end -- 17
						return name, id -- 18
					end -- 16
				end -- 15
			end -- 18
		end -- 18
	end -- 13
	return '', '' -- 19
end -- 12
_module_0 = Class(Story, { -- 22
	reviewVisible = property(function(self) -- 22
		return self._reviewVisible -- 22
	end, function(self, value) -- 23
		self._reviewVisible = value -- 24
		self.reviewMask.visible = value -- 25
		self.topCenter.visible = value -- 26
		self.reviewBack.visible = value -- 27
		self.reviewArea.visible = value -- 28
	end), -- 22
	advance = function(self, option) -- 30
		local action, result = self._runner:advance(option) -- 31
		if "Text" == action then -- 32
			if result.optionsFollowed then -- 33
				local _ -- 34
				_, self._options = self._runner:advance() -- 34
			else -- 36
				self._options = nil -- 36
			end -- 33
			self._current = result -- 37
			return true -- 38
		elseif "Command" == action then -- 39
			self._current = nil -- 40
			self._options = nil -- 41
			self.answerList:removeAllChildren() -- 42
			self.continueIcon.visible = true -- 43
			self._advancing = true -- 44
			do -- 45
				local _type_0 = type(result) -- 45
				local _tab_0 = "table" == _type_0 or "userdata" == _type_0 -- 45
				if _tab_0 then -- 45
					local preload = result.preload -- 45
					if preload ~= nil then -- 45
						self._preload = preload -- 46
						return self:advance() -- 47
					end -- 45
				end -- 47
			end -- 47
			return true -- 48
		else -- 50
			return false -- 50
		end -- 50
	end, -- 30
	__init = function(self, dialogFile) -- 52
		self._runner = YarnRunner(dialogFile, "Start", Config, Command) -- 53
		self:advance() -- 54
		self.reviewVisible = false -- 55
		self._advancing = false -- 56
		local nextSentence -- 57
		nextSentence = function() -- 57
			if self._advancing then -- 58
				return -- 58
			end -- 58
			if self._options then -- 59
				return -- 59
			end -- 59
			if self:advance() then -- 60
				return thread(function() -- 61
					return self:updateDialogAsync() -- 61
				end) -- 61
			else -- 63
				return self:hide() -- 63
			end -- 60
		end -- 57
		self:gslot("Story.Advance", function() -- 64
			self._advancing = false -- 65
			return nextSentence() -- 66
		end) -- 64
		self.confirm:slot("Tapped", nextSentence) -- 67
		self.textArea:slot("NoneScrollTapped", nextSentence) -- 68
		self.reviewButton:slot("Tapped", function() -- 69
			if self._advancing then -- 70
				return -- 70
			end -- 70
			self.reviewVisible = true -- 71
			return self:alignLayout() -- 72
		end) -- 69
		self.reviewBack:slot("Tapped", function() -- 73
			self.reviewVisible = false -- 73
		end) -- 73
		self.reviewArea:slot("NoneScrollTapped", function() -- 74
			self.reviewVisible = false -- 74
		end) -- 74
		do -- 75
			local _with_0 = Dialog() -- 75
			_with_0.__modified = function(key, value) -- 76
				if "character" == key then -- 77
					self.figure:removeAllChildren() -- 78
					if (value ~= nil) and value ~= "" then -- 79
						return self.figure:addChild(StoryFigure({ -- 80
							char = value -- 80
						})) -- 80
					end -- 79
				elseif "name" == key then -- 81
					if (value ~= nil) then -- 82
						self.name.text = value -- 82
					end -- 82
				elseif "text" == key then -- 83
					if (value ~= nil) then -- 84
						self.text.text = value -- 84
					end -- 84
				end -- 84
			end -- 76
			_with_0.__updated = function() -- 85
				return self:alignLayout() -- 85
			end -- 85
			self._dialog = _with_0 -- 75
		end -- 75
		self._reviews = { } -- 86
		self.visible = false -- 87
	end, -- 52
	updateDialogAsync = function(self) -- 89
		if self._preload then -- 90
			local _list_0 = self._preload -- 91
			for _index_0 = 1, #_list_0 do -- 91
				local item = _list_0[_index_0] -- 91
				Cache:loadAsync("spine:" .. tostring(item == 'char' and Config.char or item) .. "Figure") -- 92
			end -- 92
			self._preload = nil -- 93
		end -- 90
		if not self._current then -- 94
			return -- 94
		end -- 94
		if self._advancing then -- 95
			return -- 95
		end -- 95
		self._advancing = true -- 96
		local name, characterId = getCharName(self._current) -- 97
		if characterId and characterId ~= "" then -- 98
			Cache:loadAsync("spine:" .. tostring(characterId) .. "Figure") -- 98
		end -- 98
		local text = self._current.text -- 99
		do -- 100
			local _obj_0 = self._reviews -- 100
			_obj_0[#_obj_0 + 1] = { -- 100
				name = name, -- 100
				text = text -- 100
			} -- 100
		end -- 100
		self._dialog.character = characterId -- 101
		self._dialog.name = name -- 102
		self._dialog.text = text -- 103
		self.answerList:removeAllChildren() -- 104
		if self._options then -- 105
			self.continueIcon.visible = false -- 106
			local count = #self._options -- 107
			for i = 1, count do -- 108
				local option = self._options[i] -- 109
				name = getCharName(option) -- 110
				local optionText -- 111
				optionText = option.text -- 111
				self.answerList:addChild((function() -- 112
					local _with_0 = Answer({ -- 112
						text = optionText -- 112
					}) -- 112
					_with_0:slot("Tapped", function() -- 113
						_with_0.touchEnabled = false -- 114
						return thread(function() -- 115
							sleep(0.3) -- 116
							do -- 117
								local _obj_0 = self._reviews -- 117
								_obj_0[#_obj_0 + 1] = { -- 117
									name = name, -- 117
									text = optionText -- 117
								} -- 117
							end -- 117
							if self:advance(i) then -- 118
								return thread(function() -- 119
									return self:updateDialogAsync() -- 119
								end) -- 119
							else -- 121
								return self:hide() -- 121
							end -- 118
						end) -- 121
					end) -- 113
					return _with_0 -- 112
				end)()) -- 112
			end -- 121
			local size = self.answerList:alignItems(40) -- 122
			self.answerList.size = size -- 123
			self.answerList:alignItems(40) -- 124
		else -- 126
			self.continueIcon.visible = true -- 126
		end -- 105
		self._advancing = false -- 127
	end, -- 89
	showAsync = function(self) -- 129
		self:updateDialogAsync() -- 130
		self.visible = true -- 131
		self._viewScale = View.scale -- 132
		self._viewEffect = View.postEffect -- 133
		View.scale = 4 * self._viewScale -- 134
		local size = View.size -- 135
		local blurH -- 136
		do -- 136
			local _with_0 = Pass("builtin:vs_sprite", "builtin:fs_spriteblurh") -- 136
			_with_0.grabPass = true -- 137
			_with_0:set("u_radius", size.width) -- 138
			blurH = _with_0 -- 136
		end -- 136
		local blurV -- 139
		do -- 139
			local _with_0 = Pass("builtin:vs_sprite", "builtin:fs_spriteblurv") -- 139
			_with_0.grabPass = true -- 140
			_with_0:set("u_radius", size.height) -- 141
			blurV = _with_0 -- 139
		end -- 139
		do -- 142
			local _with_0 = SpriteEffect() -- 142
			for _ = 1, 3 do -- 143
				_with_0:add(blurH) -- 144
				_with_0:add(blurV) -- 145
			end -- 145
			View.postEffect = _with_0 -- 142
		end -- 142
		self:gslot("AppChange", function(settingName) -- 146
			if settingName == "Size" then -- 146
				local width, height -- 147
				do -- 147
					local _obj_0 = View.size -- 147
					width, height = _obj_0.width, _obj_0.height -- 147
				end -- 147
				blurH:set("u_radius", width) -- 148
				return blurV:set("u_radius", height) -- 149
			end -- 146
		end) -- 146
		return emit("Story.Display", true) -- 150
	end, -- 129
	hide = function(self) -- 152
		self:gslot("AppChange", nil) -- 153
		self:emit("Ended") -- 154
		self:removeFromParent() -- 155
		local viewScale = self._viewScale -- 156
		local viewEffect = self._viewEffect -- 157
		return thread(function() -- 158
			collectgarbage() -- 159
			Cache:removeUnused() -- 160
			emit("Story.Display", false) -- 161
			View.scale = viewScale -- 162
			sleep() -- 163
			View.postEffect = viewEffect -- 164
		end) -- 164
	end -- 152
}) -- 21
return _module_0 -- 164
