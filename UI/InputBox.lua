-- [yue]: UI/InputBox.yue
local Class = Dora.Class -- 1
local Vec2 = Dora.Vec2 -- 1
local Line = Dora.Line -- 1
local Color = Dora.Color -- 1
local loop = Dora.loop -- 1
local sleep = Dora.sleep -- 1
local math = _G.math -- 1
local Size = Dora.Size -- 1
local Keyboard = Dora.Keyboard -- 1
local App = Dora.App -- 1
local property = Dora.property -- 1
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
		updateIMEPos = function(next) -- 49
			return _with_0:convertToWindowSpace(Vec2(-label.x + label.width, 0), function(pos) -- 50
				Keyboard:updateIMEPosHint(pos) -- 51
				if next then -- 52
					return next() -- 52
				end -- 52
			end) -- 50
		end -- 49
		local startEditing -- 53
		startEditing = function() -- 53
			return updateIMEPos(function() -- 54
				_with_0:detachIME() -- 55
				_with_0:attachIME() -- 56
				return updateIMEPos() -- 57
			end) -- 54
		end -- 53
		_with_0.updateDisplayText = function(_, txt) -- 58
			textDisplay = txt -- 59
			label.text = txt -- 60
		end -- 58
		_with_0:slot("AttachIME", function() -- 62
			label.opacity = 1.0 -- 63
			_with_0.keyboardEnabled = true -- 64
			return updateText(textDisplay) -- 65
		end) -- 62
		_with_0:slot("DetachIME", function() -- 67
			_with_0.keyboardEnabled = false -- 68
			cursor.visible = false -- 69
			cursor:unschedule() -- 70
			textEditing = "" -- 71
			label.x = 0 -- 72
			if textDisplay == "" then -- 73
				label.opacity = 0.6 -- 74
				label.text = _with_0.hint -- 75
			end -- 73
		end) -- 67
		_with_0.touchEnabled = true -- 77
		_with_0:slot("Tapped", function(touch) -- 78
			if touch.first then -- 78
				return startEditing() -- 78
			end -- 78
		end) -- 78
		_with_0:slot("KeyPressed", function(key) -- 80
			if App.platform == "Android" and u8.len(textEditing) == 1 then -- 81
				if key == "BackSpace" then -- 82
					textEditing = "" -- 82
				end -- 82
			else -- 84
				if textEditing ~= "" then -- 84
					return -- 84
				end -- 84
			end -- 81
			if "BackSpace" == key then -- 86
				if #textDisplay > 0 then -- 87
					textDisplay = u8.sub(textDisplay, 1, -2) -- 88
					return updateText(textDisplay) -- 89
				end -- 87
			elseif "Return" == key or "Escape" == key then -- 90
				_with_0:detachIME() -- 91
				return inputBox:emit("Inputed", textDisplay) -- 92
			end -- 92
		end) -- 80
		_with_0:slot("TextInput", function(txt) -- 94
			textDisplay = u8.sub(textDisplay, 1, -1 - u8.len(textEditing)) .. txt -- 95
			textEditing = "" -- 96
			updateText(textDisplay) -- 97
			return updateIMEPos() -- 98
		end) -- 94
		_with_0:slot("TextEditing", function(txt, _start) -- 100
			textDisplay = u8.sub(textDisplay, 1, -1 - u8.len(textEditing)) .. txt -- 101
			textEditing = txt -- 102
			label.text = textDisplay -- 103
			local offsetX = math.max(label.width + 3 - width, 0) -- 104
			label.x = -offsetX -- 105
			updateText(textDisplay) -- 106
			return updateIMEPos() -- 107
		end) -- 100
	end -- 41
	inputBox:alignLayout() -- 109
	return inputBox -- 110
end), { -- 112
	text = property((function(self) -- 112
		return self.label.text -- 112
	end), function(self, value) -- 113
		if self.imeAttached then -- 114
			self:detachIME() -- 114
		end -- 114
		return self:updateDisplayText(value) -- 115
	end) -- 112
}) -- 5
_module_0 = TextInput -- 118
return _module_0 -- 118
