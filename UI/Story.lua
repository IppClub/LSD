-- [yue]: UI/Story.yue
local type = _G.type -- 1
local Class = Dora.Class -- 1
local property = Dora.property -- 1
local print = _G.print -- 1
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
		elseif "Error" == action then -- 49
			print(result) -- 50
			return false -- 51
		else -- 53
			return false -- 53
		end -- 53
	end, -- 30
	__init = function(self, dialogFile) -- 55
		self._runner = YarnRunner(dialogFile, "Start", Config, Command) -- 56
		self:advance() -- 57
		self.reviewVisible = false -- 58
		self._advancing = false -- 59
		local nextSentence -- 60
		nextSentence = function() -- 60
			if self._advancing then -- 61
				return -- 61
			end -- 61
			if self._options then -- 62
				return -- 62
			end -- 62
			if self:advance() then -- 63
				return thread(function() -- 64
					return self:updateDialogAsync() -- 64
				end) -- 64
			else -- 66
				return self:hide() -- 66
			end -- 63
		end -- 60
		self:gslot("Story.Advance", function() -- 67
			self._advancing = false -- 68
			return nextSentence() -- 69
		end) -- 67
		self.confirm:slot("Tapped", nextSentence) -- 70
		self.textArea:slot("NoneScrollTapped", nextSentence) -- 71
		self.reviewButton:slot("Tapped", function() -- 72
			if self._advancing then -- 73
				return -- 73
			end -- 73
			self.reviewVisible = true -- 74
			return self:alignLayout() -- 75
		end) -- 72
		self.reviewBack:slot("Tapped", function() -- 76
			self.reviewVisible = false -- 76
		end) -- 76
		self.reviewArea:slot("NoneScrollTapped", function() -- 77
			self.reviewVisible = false -- 77
		end) -- 77
		do -- 78
			local _with_0 = Dialog() -- 78
			_with_0.__modified = function(key, value) -- 79
				if "character" == key then -- 80
					self.figure:removeAllChildren() -- 81
					if (value ~= nil) and value ~= "" then -- 82
						return self.figure:addChild(StoryFigure({ -- 83
							char = value -- 83
						})) -- 83
					end -- 82
				elseif "name" == key then -- 84
					if (value ~= nil) then -- 85
						self.name.text = value -- 85
					end -- 85
				elseif "text" == key then -- 86
					if (value ~= nil) then -- 87
						self.text.text = value -- 87
					end -- 87
				end -- 87
			end -- 79
			_with_0.__updated = function() -- 88
				return self:alignLayout() -- 88
			end -- 88
			self._dialog = _with_0 -- 78
		end -- 78
		self._reviews = { } -- 89
		self.visible = false -- 90
	end, -- 55
	updateDialogAsync = function(self) -- 92
		if self._preload then -- 93
			local _list_0 = self._preload -- 94
			for _index_0 = 1, #_list_0 do -- 94
				local item = _list_0[_index_0] -- 94
				local figureFile -- 95
				if 'char' == item then -- 96
					figureFile = "spine:" .. tostring(Config.char) .. "Figure" -- 96
				elseif 'vivi' == item then -- 97
					figureFile = "spine:vikaFigure" -- 97
				else -- 98
					figureFile = "spine:" .. tostring(item) .. "Figure" -- 98
				end -- 98
				Cache:loadAsync(figureFile) -- 99
			end -- 99
			self._preload = nil -- 100
		end -- 93
		if not self._current then -- 101
			return -- 101
		end -- 101
		if self._advancing then -- 102
			return -- 102
		end -- 102
		self._advancing = true -- 103
		local name, characterId = getCharName(self._current) -- 104
		local figureFile -- 105
		if 'char' == characterId then -- 106
			figureFile = "spine:" .. tostring(Config.char) .. "Figure" -- 106
		elseif 'vivi' == characterId then -- 107
			figureFile = "spine:vikaFigure" -- 107
		else -- 108
			figureFile = "spine:" .. tostring(characterId) .. "Figure" -- 108
		end -- 108
		if characterId and characterId ~= "" then -- 109
			Cache:loadAsync(figureFile) -- 109
		end -- 109
		local text = self._current.text -- 110
		do -- 111
			local _obj_0 = self._reviews -- 111
			_obj_0[#_obj_0 + 1] = { -- 111
				name = name, -- 111
				text = text -- 111
			} -- 111
		end -- 111
		self._dialog.character = characterId -- 112
		self._dialog.name = name -- 113
		self._dialog.text = text -- 114
		self.answerList:removeAllChildren() -- 115
		if self._options then -- 116
			self.continueIcon.visible = false -- 117
			local count = #self._options -- 118
			for i = 1, count do -- 119
				local option = self._options[i] -- 120
				name = getCharName(option) -- 121
				local optionText -- 122
				optionText = option.text -- 122
				self.answerList:addChild((function() -- 123
					local _with_0 = Answer({ -- 123
						text = optionText -- 123
					}) -- 123
					_with_0:slot("Tapped", function() -- 124
						_with_0.touchEnabled = false -- 125
						return thread(function() -- 126
							sleep(0.3) -- 127
							do -- 128
								local _obj_0 = self._reviews -- 128
								_obj_0[#_obj_0 + 1] = { -- 128
									name = name, -- 128
									text = optionText -- 128
								} -- 128
							end -- 128
							if self:advance(i) then -- 129
								return thread(function() -- 130
									return self:updateDialogAsync() -- 130
								end) -- 130
							else -- 132
								return self:hide() -- 132
							end -- 129
						end) -- 132
					end) -- 124
					return _with_0 -- 123
				end)()) -- 123
			end -- 132
			local size = self.answerList:alignItems(40) -- 133
			self.answerList.size = size -- 134
			self.answerList:alignItems(40) -- 135
		else -- 137
			self.continueIcon.visible = true -- 137
		end -- 116
		self._advancing = false -- 138
	end, -- 92
	showAsync = function(self) -- 140
		self:updateDialogAsync() -- 141
		self.visible = true -- 142
		self._viewScale = View.scale -- 143
		self._viewEffect = View.postEffect -- 144
		View.scale = 4 * self._viewScale -- 145
		local size = View.size -- 146
		local blurH -- 147
		do -- 147
			local _with_0 = Pass("builtin:vs_sprite", "builtin:fs_spriteblurh") -- 147
			_with_0.grabPass = true -- 148
			_with_0:set("u_radius", size.width) -- 149
			blurH = _with_0 -- 147
		end -- 147
		local blurV -- 150
		do -- 150
			local _with_0 = Pass("builtin:vs_sprite", "builtin:fs_spriteblurv") -- 150
			_with_0.grabPass = true -- 151
			_with_0:set("u_radius", size.height) -- 152
			blurV = _with_0 -- 150
		end -- 150
		do -- 153
			local _with_0 = SpriteEffect() -- 153
			for _ = 1, 3 do -- 154
				_with_0:add(blurH) -- 155
				_with_0:add(blurV) -- 156
			end -- 156
			View.postEffect = _with_0 -- 153
		end -- 153
		self:gslot("AppChange", function(settingName) -- 157
			if settingName == "Size" then -- 157
				local width, height -- 158
				do -- 158
					local _obj_0 = View.size -- 158
					width, height = _obj_0.width, _obj_0.height -- 158
				end -- 158
				blurH:set("u_radius", width) -- 159
				return blurV:set("u_radius", height) -- 160
			end -- 157
		end) -- 157
		return emit("Story.Display", true) -- 161
	end, -- 140
	hide = function(self) -- 163
		self:gslot("AppChange", nil) -- 164
		self:emit("Ended") -- 165
		self:removeFromParent() -- 166
		local viewScale = self._viewScale -- 167
		local viewEffect = self._viewEffect -- 168
		return thread(function() -- 169
			collectgarbage() -- 170
			Cache:removeUnused() -- 171
			emit("Story.Display", false) -- 172
			View.scale = viewScale -- 173
			sleep() -- 174
			View.postEffect = viewEffect -- 175
		end) -- 175
	end -- 163
}) -- 21
return _module_0 -- 175
