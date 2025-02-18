-- [yue]: UI/Story.yue
local type = _G.type -- 1
local Class = Dora.Class -- 1
local property = Dora.property -- 1
local thread = Dora.thread -- 1
local tostring = _G.tostring -- 1
local Cache = Dora.Cache -- 1
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
				local figureFile -- 92
				if 'char' == item then -- 93
					figureFile = "spine:" .. tostring(Config.char) .. "Figure" -- 93
				elseif 'vivi' == item then -- 94
					figureFile = "spine:vikaFigure" -- 94
				else -- 95
					figureFile = "spine:" .. tostring(item) .. "Figure" -- 95
				end -- 95
				Cache:loadAsync(figureFile) -- 96
			end -- 96
			self._preload = nil -- 97
		end -- 90
		if not self._current then -- 98
			return -- 98
		end -- 98
		if self._advancing then -- 99
			return -- 99
		end -- 99
		self._advancing = true -- 100
		local name, characterId = getCharName(self._current) -- 101
		local figureFile -- 102
		if 'char' == characterId then -- 103
			figureFile = "spine:" .. tostring(Config.char) .. "Figure" -- 103
		elseif 'vivi' == characterId then -- 104
			figureFile = "spine:vikaFigure" -- 104
		else -- 105
			figureFile = "spine:" .. tostring(characterId) .. "Figure" -- 105
		end -- 105
		if characterId and characterId ~= "" then -- 106
			Cache:loadAsync(figureFile) -- 106
		end -- 106
		local text = self._current.text -- 107
		do -- 108
			local _obj_0 = self._reviews -- 108
			_obj_0[#_obj_0 + 1] = { -- 108
				name = name, -- 108
				text = text -- 108
			} -- 108
		end -- 108
		self._dialog.character = characterId -- 109
		self._dialog.name = name -- 110
		self._dialog.text = text -- 111
		self.answerList:removeAllChildren() -- 112
		if self._options then -- 113
			self.continueIcon.visible = false -- 114
			local count = #self._options -- 115
			for i = 1, count do -- 116
				local option = self._options[i] -- 117
				name = getCharName(option) -- 118
				local optionText -- 119
				optionText = option.text -- 119
				self.answerList:addChild((function() -- 120
					local _with_0 = Answer({ -- 120
						text = optionText -- 120
					}) -- 120
					_with_0:slot("Tapped", function() -- 121
						_with_0.touchEnabled = false -- 122
						return thread(function() -- 123
							sleep(0.3) -- 124
							do -- 125
								local _obj_0 = self._reviews -- 125
								_obj_0[#_obj_0 + 1] = { -- 125
									name = name, -- 125
									text = optionText -- 125
								} -- 125
							end -- 125
							if self:advance(i) then -- 126
								return thread(function() -- 127
									return self:updateDialogAsync() -- 127
								end) -- 127
							else -- 129
								return self:hide() -- 129
							end -- 126
						end) -- 129
					end) -- 121
					return _with_0 -- 120
				end)()) -- 120
			end -- 129
			local size = self.answerList:alignItems(40) -- 130
			self.answerList.size = size -- 131
			self.answerList:alignItems(40) -- 132
		else -- 134
			self.continueIcon.visible = true -- 134
		end -- 113
		self._advancing = false -- 135
	end, -- 89
	showAsync = function(self) -- 137
		self:updateDialogAsync() -- 138
		self.visible = true -- 139
		self._viewScale = View.scale -- 140
		self._viewEffect = View.postEffect -- 141
		View.scale = 4 * self._viewScale -- 142
		local size = View.size -- 143
		local blurH -- 144
		do -- 144
			local _with_0 = Pass("builtin:vs_sprite", "builtin:fs_spriteblurh") -- 144
			_with_0.grabPass = true -- 145
			_with_0:set("u_radius", size.width) -- 146
			blurH = _with_0 -- 144
		end -- 144
		local blurV -- 147
		do -- 147
			local _with_0 = Pass("builtin:vs_sprite", "builtin:fs_spriteblurv") -- 147
			_with_0.grabPass = true -- 148
			_with_0:set("u_radius", size.height) -- 149
			blurV = _with_0 -- 147
		end -- 147
		do -- 150
			local _with_0 = SpriteEffect() -- 150
			for _ = 1, 3 do -- 151
				_with_0:add(blurH) -- 152
				_with_0:add(blurV) -- 153
			end -- 153
			View.postEffect = _with_0 -- 150
		end -- 150
		self:gslot("AppChange", function(settingName) -- 154
			if settingName == "Size" then -- 154
				local width, height -- 155
				do -- 155
					local _obj_0 = View.size -- 155
					width, height = _obj_0.width, _obj_0.height -- 155
				end -- 155
				blurH:set("u_radius", width) -- 156
				return blurV:set("u_radius", height) -- 157
			end -- 154
		end) -- 154
		return emit("Story.Display", true) -- 158
	end, -- 137
	hide = function(self) -- 160
		self:gslot("AppChange", nil) -- 161
		self:emit("Ended") -- 162
		self:removeFromParent() -- 163
		local viewScale = self._viewScale -- 164
		local viewEffect = self._viewEffect -- 165
		return thread(function() -- 166
			collectgarbage() -- 167
			Cache:removeUnused() -- 168
			emit("Story.Display", false) -- 169
			View.scale = viewScale -- 170
			sleep() -- 171
			View.postEffect = viewEffect -- 172
		end) -- 172
	end -- 160
}) -- 21
return _module_0 -- 172
