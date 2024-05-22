-- [yue]: Script/Control.yue
local _module_0 = Dora.Platformer -- 1
local Data = _module_0.Data -- 1
local App = Dora.App -- 1
local Group = Dora.Group -- 1
local Menu = Dora.Menu -- 1
local math = _G.math -- 1
local Vec2 = Dora.Vec2 -- 1
local Director = Dora.Director -- 1
local Keyboard = Dora.Keyboard -- 1
local Node = Dora.Node -- 1
local AlignNode = require("UI.Control.Basic.AlignNode") -- 2
local CircleButton = require("UI.Control.Basic.CircleButton") -- 3
local Store = Data.store -- 5
local keyboardEnabled -- 7
do -- 7
	local _exp_0 = App.platform -- 7
	if "macOS" == _exp_0 or "Windows" == _exp_0 or "Linux" == _exp_0 then -- 8
		keyboardEnabled = true -- 8
	else -- 9
		keyboardEnabled = false -- 9
	end -- 9
end -- 9
Store.keyboardEnabled = keyboardEnabled -- 11
local playerGroup = Group({ -- 13
	"player" -- 13
}) -- 13
local updatePlayerControl -- 14
updatePlayerControl = function(key, flag, vpad) -- 14
	if vpad == nil then -- 14
		vpad = false -- 14
	end -- 14
	if keyboardEnabled then -- 15
		if vpad then -- 16
			Store.keyboardEnabled = not flag -- 16
		end -- 16
	end -- 15
	return playerGroup:each(function(self) -- 17
		self[key] = flag -- 17
	end) -- 17
end -- 14
local uiScale = App.devicePixelRatio -- 18
do -- 20
	local _with_0 = AlignNode({ -- 20
		isRoot = true, -- 20
		inUI = true -- 20
	}) -- 20
	_with_0.opacity = 0.5 -- 21
	_with_0:addChild((function() -- 23
		local _with_1 = AlignNode() -- 23
		_with_1.hAlign = "Left" -- 24
		_with_1.vAlign = "Bottom" -- 25
		_with_1:addChild((function() -- 26
			local _with_2 = Menu() -- 26
			_with_2:addChild((function() -- 27
				local _with_3 = CircleButton({ -- 28
					text = "左(a)", -- 28
					x = 20 * uiScale, -- 29
					y = 60 * uiScale, -- 30
					radius = 30 * uiScale, -- 31
					fontSize = math.floor(18 * uiScale) -- 32
				}) -- 27
				_with_3.anchor = Vec2.zero -- 34
				_with_3:slot("TapBegan", function() -- 35
					return updatePlayerControl("keyLeft", true, true) -- 35
				end) -- 35
				_with_3:slot("TapEnded", function() -- 36
					return updatePlayerControl("keyLeft", false, true) -- 36
				end) -- 36
				return _with_3 -- 27
			end)()) -- 27
			_with_2:addChild((function() -- 37
				local _with_3 = CircleButton({ -- 38
					text = "右(d)", -- 38
					x = 90 * uiScale, -- 39
					y = 60 * uiScale, -- 40
					radius = 30 * uiScale, -- 41
					fontSize = math.floor(18 * uiScale) -- 42
				}) -- 37
				_with_3.anchor = Vec2.zero -- 44
				_with_3:slot("TapBegan", function() -- 45
					return updatePlayerControl("keyRight", true, true) -- 45
				end) -- 45
				_with_3:slot("TapEnded", function() -- 46
					return updatePlayerControl("keyRight", false, true) -- 46
				end) -- 46
				return _with_3 -- 37
			end)()) -- 37
			_with_2:addChild((function() -- 47
				local _with_3 = CircleButton({ -- 48
					text = "左退(q)", -- 48
					x = 20 * uiScale, -- 49
					y = (60 * 2 + 10) * uiScale, -- 50
					radius = 30 * uiScale, -- 51
					fontSize = math.floor(18 * uiScale) -- 52
				}) -- 47
				_with_3.anchor = Vec2.zero -- 54
				_with_3:slot("TapBegan", function() -- 55
					return updatePlayerControl("keyBLeft", true, true) -- 55
				end) -- 55
				_with_3:slot("TapEnded", function() -- 56
					return updatePlayerControl("keyBLeft", false, true) -- 56
				end) -- 56
				return _with_3 -- 47
			end)()) -- 47
			_with_2:addChild((function() -- 57
				local _with_3 = CircleButton({ -- 58
					text = "右退(e)", -- 58
					x = 90 * uiScale, -- 59
					y = (60 * 2 + 10) * uiScale, -- 60
					radius = 30 * uiScale, -- 61
					fontSize = math.floor(18 * uiScale) -- 62
				}) -- 57
				_with_3.anchor = Vec2.zero -- 64
				_with_3:slot("TapBegan", function() -- 65
					return updatePlayerControl("keyBRight", true, true) -- 65
				end) -- 65
				_with_3:slot("TapEnded", function() -- 66
					return updatePlayerControl("keyBRight", false, true) -- 66
				end) -- 66
				return _with_3 -- 57
			end)()) -- 57
			return _with_2 -- 26
		end)()) -- 26
		return _with_1 -- 23
	end)()) -- 23
	_with_0:addChild((function() -- 67
		local _with_1 = AlignNode() -- 67
		_with_1.hAlign = "Right" -- 68
		_with_1.vAlign = "Bottom" -- 69
		_with_1:addChild((function() -- 70
			local _with_2 = Menu() -- 70
			_with_2:addChild((function() -- 71
				local _with_3 = CircleButton({ -- 72
					text = "跳(k)", -- 72
					x = -80 * uiScale, -- 73
					y = 60 * uiScale, -- 74
					radius = 30 * uiScale, -- 75
					fontSize = math.floor(18 * uiScale) -- 76
				}) -- 71
				_with_3.anchor = Vec2.zero -- 78
				_with_3:slot("TapBegan", function() -- 79
					return updatePlayerControl("keyUp", true, true) -- 79
				end) -- 79
				_with_3:slot("TapEnded", function() -- 80
					return updatePlayerControl("keyUp", false, true) -- 80
				end) -- 80
				return _with_3 -- 71
			end)()) -- 71
			_with_2:addChild((function() -- 81
				local _with_3 = CircleButton({ -- 82
					text = "手枪(j)", -- 82
					x = -150 * uiScale, -- 83
					y = 60 * uiScale, -- 84
					radius = 30 * uiScale, -- 85
					fontSize = math.floor(18 * uiScale) -- 86
				}) -- 81
				_with_3.anchor = Vec2.zero -- 88
				_with_3:slot("TapBegan", function() -- 89
					return updatePlayerControl("keyShoot", true, true) -- 89
				end) -- 89
				_with_3:slot("TapEnded", function() -- 90
					return updatePlayerControl("keyShoot", false, true) -- 90
				end) -- 90
				return _with_3 -- 81
			end)()) -- 81
			return _with_2 -- 70
		end)()) -- 70
		_with_1:addChild((function() -- 91
			local _with_2 = Menu() -- 91
			_with_2:addChild((function() -- 92
				local _with_3 = CircleButton({ -- 93
					text = "闪避(i)", -- 93
					x = -80 * uiScale, -- 94
					y = (60 * 2 + 10) * uiScale, -- 95
					radius = 30 * uiScale, -- 96
					fontSize = math.floor(18 * uiScale) -- 97
				}) -- 92
				_with_3.anchor = Vec2.zero -- 99
				_with_3:slot("TapBegan", function() -- 100
					return updatePlayerControl("keyEvade", true, true) -- 100
				end) -- 100
				_with_3:slot("TapEnded", function() -- 101
					return updatePlayerControl("keyEvade", false, true) -- 101
				end) -- 101
				return _with_3 -- 92
			end)()) -- 92
			_with_2:addChild((function() -- 102
				local _with_3 = CircleButton({ -- 103
					text = "冲刺(u)", -- 103
					x = -150 * uiScale, -- 104
					y = (60 * 2 + 10) * uiScale, -- 105
					radius = 30 * uiScale, -- 106
					fontSize = math.floor(18 * uiScale) -- 107
				}) -- 102
				_with_3.anchor = Vec2.zero -- 109
				_with_3:slot("TapBegan", function() -- 110
					return updatePlayerControl("keyRush", true, true) -- 110
				end) -- 110
				_with_3:slot("TapEnded", function() -- 111
					return updatePlayerControl("keyRush", false, true) -- 111
				end) -- 111
				return _with_3 -- 102
			end)()) -- 102
			_with_2:addChild((function() -- 112
				local _with_3 = CircleButton({ -- 113
					text = "倒地起身(o)", -- 113
					x = -150 * uiScale, -- 114
					y = (60 * 3 + 20) * uiScale, -- 115
					radius = 30 * uiScale, -- 116
					fontSize = math.floor(18 * uiScale) -- 117
				}) -- 112
				_with_3.anchor = Vec2.zero -- 119
				_with_3:slot("TapBegan", function() -- 120
					return updatePlayerControl("keyFall", true, true) -- 120
				end) -- 120
				_with_3:slot("TapEnded", function() -- 121
					return updatePlayerControl("keyFall", false, true) -- 121
				end) -- 121
				return _with_3 -- 112
			end)()) -- 112
			_with_2:addChild((function() -- 122
				local _with_3 = CircleButton({ -- 123
					text = "普攻(l)", -- 123
					x = -80 * uiScale, -- 124
					y = (60 * 3 + 20) * uiScale, -- 125
					radius = 30 * uiScale, -- 126
					fontSize = math.floor(18 * uiScale) -- 127
				}) -- 122
				_with_3.anchor = Vec2.zero -- 129
				_with_3:slot("TapBegan", function() -- 130
					return updatePlayerControl("keyMelee", true, true) -- 130
				end) -- 130
				_with_3:slot("TapEnded", function() -- 131
					return updatePlayerControl("keyMelee", false, true) -- 131
				end) -- 131
				return _with_3 -- 122
			end)()) -- 122
			return _with_2 -- 91
		end)()) -- 91
		return _with_1 -- 67
	end)()) -- 67
	_with_0:addTo((function() -- 132
		local _with_1 = Director.ui -- 132
		_with_1.renderGroup = true -- 133
		return _with_1 -- 132
	end)()) -- 132
end -- 20
local keyboardControl -- 135
keyboardControl = function() -- 135
	if not Store.keyboardEnabled then -- 136
		return -- 136
	end -- 136
	updatePlayerControl("keyLeft", Keyboard:isKeyPressed("A")) -- 137
	updatePlayerControl("keyRight", Keyboard:isKeyPressed("D")) -- 138
	updatePlayerControl("keyBLeft", Keyboard:isKeyPressed("Q")) -- 139
	updatePlayerControl("keyBRight", Keyboard:isKeyPressed("E")) -- 140
	updatePlayerControl("keyUp", Keyboard:isKeyPressed("K")) -- 141
	updatePlayerControl("keyShoot", Keyboard:isKeyPressed("J")) -- 142
	updatePlayerControl("keyRush", Keyboard:isKeyPressed("U")) -- 143
	updatePlayerControl("keyEvade", Keyboard:isKeyPressed("I")) -- 144
	updatePlayerControl("keyFall", Keyboard:isKeyPressed("O")) -- 145
	updatePlayerControl("keyMelee", Keyboard:isKeyPressed("L")) -- 146
	return updatePlayerControl("keyTest", Keyboard:isKeyPressed("T")) -- 147
end -- 135
return Director.entry:addChild((function() -- 149
	local _with_0 = Node() -- 149
	_with_0:schedule(keyboardControl) -- 150
	return _with_0 -- 149
end)()) -- 150
