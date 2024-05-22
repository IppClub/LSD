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
			_with_0.__notify = function(event, key, value) -- 76
				if event == "Modified" then -- 77
					if "character" == key then -- 79
						self.figure:removeAllChildren() -- 80
						if (value ~= nil) and value ~= "" then -- 81
							return self.figure:addChild(StoryFigure({ -- 82
								char = value -- 82
							})) -- 82
						end -- 81
					elseif "name" == key then -- 83
						if (value ~= nil) then -- 84
							self.name.text = value -- 84
						end -- 84
					elseif "text" == key then -- 85
						if (value ~= nil) then -- 86
							self.text.text = value -- 86
						end -- 86
					end -- 86
				elseif event == "Updated" then -- 87
					return self:alignLayout() -- 88
				end -- 77
			end -- 76
			self._dialog = _with_0 -- 75
		end -- 75
		self._reviews = { } -- 89
		self.visible = false -- 90
	end, -- 52
	updateDialogAsync = function(self) -- 92
		if self._preload then -- 93
			local _list_0 = self._preload -- 94
			for _index_0 = 1, #_list_0 do -- 94
				local item = _list_0[_index_0] -- 94
				Cache:loadAsync("spine:" .. tostring(item == 'char' and Config.char or item) .. "Figure") -- 95
			end -- 95
			self._preload = nil -- 96
		end -- 93
		if not self._current then -- 97
			return -- 97
		end -- 97
		if self._advancing then -- 98
			return -- 98
		end -- 98
		self._advancing = true -- 99
		local name, characterId = getCharName(self._current) -- 100
		if characterId and characterId ~= "" then -- 101
			Cache:loadAsync("spine:" .. tostring(characterId) .. "Figure") -- 101
		end -- 101
		local text = self._current.text -- 102
		do -- 103
			local _obj_0 = self._reviews -- 103
			_obj_0[#_obj_0 + 1] = { -- 103
				name = name, -- 103
				text = text -- 103
			} -- 103
		end -- 103
		self._dialog.character = characterId -- 104
		self._dialog.name = name -- 105
		self._dialog.text = text -- 106
		self.answerList:removeAllChildren() -- 107
		if self._options then -- 108
			self.continueIcon.visible = false -- 109
			local count = #self._options -- 110
			for i = 1, count do -- 111
				local option = self._options[i] -- 112
				name = getCharName(option) -- 113
				local optionText -- 114
				optionText = option.text -- 114
				self.answerList:addChild((function() -- 115
					local _with_0 = Answer({ -- 115
						text = optionText -- 115
					}) -- 115
					_with_0:slot("Tapped", function() -- 116
						_with_0.touchEnabled = false -- 117
						return thread(function() -- 118
							sleep(0.3) -- 119
							do -- 120
								local _obj_0 = self._reviews -- 120
								_obj_0[#_obj_0 + 1] = { -- 120
									name = name, -- 120
									text = optionText -- 120
								} -- 120
							end -- 120
							if self:advance(i) then -- 121
								return thread(function() -- 122
									return self:updateDialogAsync() -- 122
								end) -- 122
							else -- 124
								return self:hide() -- 124
							end -- 121
						end) -- 124
					end) -- 116
					return _with_0 -- 115
				end)()) -- 115
			end -- 124
			local size = self.answerList:alignItems(40) -- 125
			self.answerList.size = size -- 126
			self.answerList:alignItems(40) -- 127
		else -- 129
			self.continueIcon.visible = true -- 129
		end -- 108
		self._advancing = false -- 130
	end, -- 92
	showAsync = function(self) -- 132
		self:updateDialogAsync() -- 133
		self.visible = true -- 134
		self._viewScale = View.scale -- 135
		self._viewEffect = View.postEffect -- 136
		View.scale = 4 * self._viewScale -- 137
		local size = View.size -- 138
		local blurH -- 139
		do -- 139
			local _with_0 = Pass("builtin:vs_sprite", "builtin:fs_spriteblurh") -- 139
			_with_0.grabPass = true -- 140
			_with_0:set("u_radius", size.width) -- 141
			blurH = _with_0 -- 139
		end -- 139
		local blurV -- 142
		do -- 142
			local _with_0 = Pass("builtin:vs_sprite", "builtin:fs_spriteblurv") -- 142
			_with_0.grabPass = true -- 143
			_with_0:set("u_radius", size.height) -- 144
			blurV = _with_0 -- 142
		end -- 142
		do -- 145
			local _with_0 = SpriteEffect() -- 145
			for _ = 1, 3 do -- 146
				_with_0:add(blurH) -- 147
				_with_0:add(blurV) -- 148
			end -- 148
			View.postEffect = _with_0 -- 145
		end -- 145
		self:gslot("AppSizeChanged", function() -- 149
			local width, height -- 150
			do -- 150
				local _obj_0 = View.size -- 150
				width, height = _obj_0.width, _obj_0.height -- 150
			end -- 150
			blurH:set("u_radius", width) -- 151
			return blurV:set("u_radius", height) -- 152
		end) -- 149
		return emit("Story.Display", true) -- 153
	end, -- 132
	hide = function(self) -- 155
		self:gslot("AppSizeChanged", nil) -- 156
		self:emit("Ended") -- 157
		self:removeFromParent() -- 158
		local viewScale = self._viewScale -- 159
		local viewEffect = self._viewEffect -- 160
		return thread(function() -- 161
			collectgarbage() -- 162
			Cache:removeUnused() -- 163
			emit("Story.Display", false) -- 164
			View.scale = viewScale -- 165
			sleep() -- 166
			View.postEffect = viewEffect -- 167
		end) -- 167
	end -- 155
}) -- 21
return _module_0 -- 167
