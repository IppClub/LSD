-- [yue]: UI/InputBox.yue
local _module_0 = nil -- 1
local _ENV = Dora -- 1
local require <const> = require -- 2
local Class <const> = Class -- 2
local Vec2 <const> = Vec2 -- 2
local Line <const> = Line -- 2
local Color <const> = Color -- 2
local loop <const> = loop -- 2
local sleep <const> = sleep -- 2
local math <const> = math -- 2
local Size <const> = Size -- 2
local Keyboard <const> = Keyboard -- 2
local App <const> = App -- 2
local type <const> = type -- 2
local property <const> = property -- 2
local u8 = require("utf-8") -- 3
local InputBox = require("UI.View.InputBox") -- 4

local TextInput = Class((function(args) -- 6
	local hint, text = args.hint, args.text -- 7
	if hint == nil then -- 8
		hint = "" -- 8
	end -- 8
	if text == nil then -- 9
		text = "" -- 9
	end -- 9

	local inputBox = InputBox() -- 12
	local width, height -- 13
	do -- 13
		local _obj_0 = inputBox.label.parent -- 13
		width, height = _obj_0.width, _obj_0.height -- 13
	end -- 13

	local label -- 15
	do -- 15
		local _with_0 = inputBox.label -- 15
		if text == "" and hint ~= "" then -- 16
			_with_0.text = hint -- 17
			_with_0.opacity = 0.6 -- 18
		else -- 20
			_with_0.text = text -- 20
		end -- 16
		_with_0.y = height / 2 - 35 / 2 -- 21
		_with_0.anchor = Vec2.zero -- 22
		_with_0.alignment = "Left" -- 23
		label = _with_0 -- 15
	end -- 15

	local cursor = Line({ -- 25
		Vec2.zero, -- 25
		Vec2(0, 35 + 2) -- 25
	}, Color(0xffffffff)) -- 25
	local blink -- 26
	blink = function() -- 26
		return loop(function() -- 26
			cursor.visible = true -- 27
			sleep(0.5) -- 28
			cursor.visible = false -- 29
			return sleep(0.5) -- 30
		end) -- 26
	end -- 26
	cursor.y = label.y -- 32
	cursor.visible = false -- 33

	local updateText -- 35
	updateText = function(txt) -- 35
		label.text = txt -- 36
		local offsetX = math.max(label.width + 3 - width, 0) -- 37
		label.x = -offsetX -- 38
		cursor.x = label.width - offsetX - 30 -- 39
		return cursor:schedule(blink()) -- 40
	end -- 35

	do -- 42
		local _with_0 = inputBox.box -- 42
		local textEditing = "" -- 43
		local textDisplay = text -- 44

		_with_0.size = Size(width, height) -- 46
		_with_0.hint = hint -- 47
		_with_0:addChild(cursor) -- 48

		local updateIMEPos -- 50
		updateIMEPos = function(next) -- 50
			return _with_0:convertToWindowSpace(Vec2(-label.x + label.width, 0), function(pos) -- 51
				Keyboard:updateIMEPosHint(pos) -- 52
				if next then -- 53
					return next() -- 53
				end -- 53
			end) -- 51
		end -- 50
		local startEditing -- 54
		startEditing = function() -- 54
			return updateIMEPos(function() -- 55
				_with_0:detachIME() -- 56
				_with_0:attachIME() -- 57
				return updateIMEPos() -- 58
			end) -- 55
		end -- 54
		_with_0.getCommittedText = function(self) -- 59
			return u8.sub(textDisplay, 1, -1 - u8.len(textEditing)) -- 59
		end -- 59
		_with_0.updateDisplayText = function(_, txt) -- 60
			textEditing = "" -- 61
			textDisplay = txt -- 62
			label.x = 0 -- 63
			label.opacity = txt == "" and hint ~= "" and 0.6 or 1.0 -- 64
			label.text = txt == "" and hint ~= "" and hint or txt -- 65
		end -- 60

		_with_0:slot("AttachIME", function() -- 67
			label.opacity = 1.0 -- 68
			_with_0.keyboardEnabled = true -- 69
			return updateText(textDisplay) -- 70
		end) -- 67

		_with_0:slot("DetachIME", function() -- 72
			_with_0.keyboardEnabled = false -- 73
			cursor.visible = false -- 74
			cursor:unschedule() -- 75
			textDisplay = u8.sub(textDisplay, 1, -1 - u8.len(textEditing)) -- 76
			textEditing = "" -- 77
			label.text = textDisplay -- 78
			label.x = 0 -- 79
			if textDisplay == "" then -- 80
				label.opacity = 0.6 -- 81
				label.text = _with_0.hint -- 82
			end -- 80
		end) -- 72

		_with_0.touchEnabled = true -- 84
		_with_0:slot("Tapped", function(touch) -- 85
			if touch.first then -- 85
				return startEditing() -- 85
			end -- 85
		end) -- 85

		_with_0:slot("KeyPressed", function(key) -- 87
			if App.platform == "Android" and u8.len(textEditing) == 1 then -- 88
				if key == "BackSpace" then -- 89
					textEditing = "" -- 89
				end -- 89
			else -- 91
				if textEditing ~= "" then -- 91
					return -- 91
				end -- 91
			end -- 88
			-- Desktop paste is an explicit text edit, never a synthetic submit.
			local modified = Keyboard:isKeyPressed("LCtrl") or Keyboard:isKeyPressed("RCtrl") or Keyboard:isKeyPressed("LGui") or Keyboard:isKeyPressed("RGui") -- 93
			if key == "V" and modified and type(App.getClipboardText) == "function" then -- 94
				local clipboard = App:getClipboardText() -- 95
				if clipboard ~= "" then -- 96
					clipboard = clipboard:gsub("[\r\n\t]", " ") -- 97
					textDisplay = u8.sub(textDisplay .. clipboard, 1, 64) -- 98
					updateText(textDisplay) -- 99
					updateIMEPos() -- 100
				end -- 96
				return -- 101
			end -- 94
			if "BackSpace" == key then -- 103
				if #textDisplay > 0 then -- 104
					textDisplay = u8.sub(textDisplay, 1, -2) -- 105
					return updateText(textDisplay) -- 106
				end -- 104
			elseif "Return" == key or "Escape" == key then -- 107
				_with_0:detachIME() -- 108
				return inputBox:emit("Inputed", textDisplay) -- 109
			end -- 102
		end) -- 87

		_with_0:slot("TextInput", function(txt) -- 111
			textDisplay = u8.sub(textDisplay, 1, -1 - u8.len(textEditing)) .. txt -- 112
			textEditing = "" -- 113
			updateText(textDisplay) -- 114
			return updateIMEPos() -- 115
		end) -- 111

		_with_0:slot("TextEditing", function(txt, _start) -- 117
			textDisplay = u8.sub(textDisplay, 1, -1 - u8.len(textEditing)) .. txt -- 118
			textEditing = txt -- 119
			label.text = textDisplay -- 120
			local offsetX = math.max(label.width + 3 - width, 0) -- 121
			label.x = -offsetX -- 122
			updateText(textDisplay) -- 123
			return updateIMEPos() -- 124
		end) -- 117
	end -- 42

	inputBox:alignLayout() -- 126
	return inputBox -- 127
end), { -- 129
	text = property((function(self) -- 129
		return self.box:getCommittedText() -- 129
	end), function(self, value) -- 130
		if self.box.imeAttached then -- 131
			self.box:detachIME() -- 131
		end -- 131
		return self.box:updateDisplayText(value) -- 132
	end) -- 129
}) -- 6

_module_0 = TextInput -- 135
return _module_0 -- 1
