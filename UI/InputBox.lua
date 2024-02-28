-- [yue]: UI/InputBox.yue
local Class = dora.Class -- 1
local Vec2 = dora.Vec2 -- 1
local Line = dora.Line -- 1
local Color = dora.Color -- 1
local loop = dora.loop -- 1
local sleep = dora.sleep -- 1
local math = _G.math -- 1
local Size = dora.Size -- 1
local Keyboard = dora.Keyboard -- 1
local App = dora.App -- 1
local property = dora.property -- 1
local _module_0 = nil -- 1
local u8 = require("utf-8") -- 2
local InputBox = require("UI.View.InputBox") -- 3
local TextInput = Class((function(args) -- 5
	local hint, text = args.hint, args.text -- 6
	if hint == nil then -- 7
		hint = "" -- 7
	end -- 7
	if text == nil then -- 8
		text = "" -- 8
	end -- 8
	local inputBox = InputBox() -- 11
	local width, height -- 12
	do -- 12
		local _obj_0 = inputBox.label.parent -- 12
		width, height = _obj_0.width, _obj_0.height -- 12
	end -- 12
	local label -- 14
	do -- 14
		local _with_0 = inputBox.label -- 14
		if text == "" and hint ~= "" then -- 15
			_with_0.text = hint -- 16
			_with_0.opacity = 0.6 -- 17
		else -- 19
			_with_0.text = text -- 19
		end -- 15
		_with_0.y = height / 2 - 35 / 2 -- 20
		_with_0.anchor = Vec2.zero -- 21
		_with_0.alignment = "Left" -- 22
		label = _with_0 -- 14
	end -- 14
	local cursor = Line({ -- 24
		Vec2.zero, -- 24
		Vec2(0, 35 + 2) -- 24
	}, Color(0xffffffff)) -- 24
	local blink -- 25
	blink = function() -- 25
		return loop(function() -- 25
			cursor.visible = true -- 26
			sleep(0.5) -- 27
			cursor.visible = false -- 28
			return sleep(0.5) -- 29
		end) -- 29
	end -- 25
	cursor.y = label.y -- 31
	cursor.visible = false -- 32
	local updateText -- 34
	updateText = function(txt) -- 34
		label.text = txt -- 35
		local offsetX = math.max(label.width + 3 - width, 0) -- 36
		label.x = -offsetX -- 37
		cursor.x = label.width - offsetX - 30 -- 38
		return cursor:schedule(blink()) -- 39
	end -- 34
	do -- 41
		local _with_0 = inputBox.box -- 41
		local textEditing = "" -- 42
		local textDisplay = "" -- 43
		_with_0.size = Size(width, height) -- 45
		_with_0.hint = hint -- 46
		_with_0:addChild(cursor) -- 47
		local updateIMEPos -- 49
		updateIMEPos = function() -- 49
			return _with_0:convertToWindowSpace(Vec2(-label.x + label.width, 0), function(pos) -- 50
				return Keyboard:updateIMEPosHint(pos) -- 51
			end) -- 50
		end -- 49
		local startEditing -- 52
		startEditing = function() -- 52
			_with_0:detachIME() -- 53
			_with_0:attachIME() -- 54
			return updateIMEPos() -- 55
		end -- 52
		_with_0.updateDisplayText = function(_, txt) -- 56
			textDisplay = txt -- 57
			label.text = txt -- 58
		end -- 56
		_with_0.imeAttached = false -- 60
		_with_0:slot("AttachIME", function() -- 61
			label.opacity = 1.0 -- 62
			_with_0.imeAttached = true -- 63
			_with_0.keyboardEnabled = true -- 64
			return updateText(textDisplay) -- 65
		end) -- 61
		_with_0:slot("DetachIME", function() -- 67
			_with_0.imeAttached = false -- 68
			_with_0.keyboardEnabled = false -- 69
			cursor.visible = false -- 70
			cursor:unschedule() -- 71
			textEditing = "" -- 72
			label.x = 0 -- 73
			if textDisplay == "" then -- 74
				label.opacity = 0.6 -- 75
				label.text = _with_0.hint -- 76
			end -- 74
		end) -- 67
		_with_0.touchEnabled = true -- 78
		_with_0:slot("Tapped", function(touch) -- 79
			if touch.first then -- 79
				return startEditing() -- 79
			end -- 79
		end) -- 79
		_with_0:slot("KeyPressed", function(key) -- 81
			if App.platform == "Android" and u8.len(textEditing) == 1 then -- 82
				if key == "BackSpace" then -- 83
					textEditing = "" -- 83
				end -- 83
			else -- 85
				if textEditing ~= "" then -- 85
					return -- 85
				end -- 85
			end -- 82
			if "BackSpace" == key then -- 87
				if #textDisplay > 0 then -- 88
					textDisplay = u8.sub(textDisplay, 1, -2) -- 89
					return updateText(textDisplay) -- 90
				end -- 88
			elseif "Return" == key or "Escape" == key then -- 91
				_with_0:detachIME() -- 92
				return inputBox:emit("Inputed", textDisplay) -- 93
			end -- 93
		end) -- 81
		_with_0:slot("TextInput", function(txt) -- 95
			textDisplay = u8.sub(textDisplay, 1, -1 - u8.len(textEditing)) .. txt -- 96
			textEditing = "" -- 97
			updateText(textDisplay) -- 98
			return updateIMEPos() -- 99
		end) -- 95
		_with_0:slot("TextEditing", function(txt, _start) -- 101
			textDisplay = u8.sub(textDisplay, 1, -1 - u8.len(textEditing)) .. txt -- 102
			textEditing = txt -- 103
			label.text = textDisplay -- 104
			local offsetX = math.max(label.width + 3 - width, 0) -- 105
			label.x = -offsetX -- 106
			updateText(textDisplay) -- 107
			return updateIMEPos() -- 108
		end) -- 101
	end -- 41
	inputBox:alignLayout() -- 110
	return inputBox -- 111
end), { -- 113
	text = property((function(self) -- 113
		return self.label.text -- 113
	end), function(self, value) -- 114
		if self.imeAttached then -- 115
			self:detachIME() -- 115
		end -- 115
		return self:updateDisplayText(value) -- 116
	end) -- 113
}) -- 5
_module_0 = TextInput -- 119
return _module_0 -- 119
