-- [yue]: Test/DoraTest.yue
local Path = dora.Path -- 1
local Content = dora.Content -- 1
local Director = dora.Director -- 1
local Spine = dora.Spine -- 1
local p = _G.p -- 1
local Node = dora.Node -- 1
local Size = dora.Size -- 1
local SpriteEffect = dora.SpriteEffect -- 1
local Color = dora.Color -- 1
local print = _G.print -- 1
local tostring = _G.tostring -- 1
local loop = dora.loop -- 1
local sleep = dora.sleep -- 1
local Label = dora.Label -- 1
local Sequence = dora.Sequence -- 1
local Spawn = dora.Spawn -- 1
local Scale = dora.Scale -- 1
local Ease = dora.Ease -- 1
local Delay = dora.Delay -- 1
local Opacity = dora.Opacity -- 1
local Event = dora.Event -- 1
local Vec2 = dora.Vec2 -- 1
local App = dora.App -- 1
local _module_0 = dora.ImGui -- 1
local SetNextWindowPos = _module_0.SetNextWindowPos -- 1
local SetNextWindowSize = _module_0.SetNextWindowSize -- 1
local Begin = _module_0.Begin -- 1
local TextWrapped = _module_0.TextWrapped -- 1
local Checkbox = _module_0.Checkbox -- 1

do -- 2
	local scriptPath = Path:getScriptPath(...) -- 2
	if scriptPath then -- 2
		scriptPath = Path:getPath(scriptPath) -- 3
		local _list_0 = { -- 5
			scriptPath, -- 5
			Path(scriptPath, "Script"), -- 6
			Path(scriptPath, "Spine"), -- 7
			Path(scriptPath, "Image"), -- 8
			Path(scriptPath, "Font") -- 9
		} -- 4
		for _index_0 = 1, #_list_0 do -- 10
			local path = _list_0[_index_0] -- 4
			Content:insertSearchPath(1, path) -- 11
		end -- 11
	else -- 12
		return -- 12
	end -- 2
end -- 2
local LsdOSBack = require("UI.LsdOSBack") -- 14
Director.entry:addChild((function() -- 16
	local _with_0 = LsdOSBack() -- 16
	_with_0:alignLayout() -- 17
	return _with_0 -- 16
end)()) -- 16
local spineStr = "ninilite" -- 19
local animations = Spine:getAnimations(spineStr) -- 21
local looks = Spine:getLooks(spineStr) -- 22
p(animations, looks) -- 23
local spineShadow -- 25
do -- 25
	local s = Spine(spineStr) -- 25
	s.x = 200 -- 26
	s.y = 190 -- 27
	s.scaleY = -1.0 -- 28
	s.look = looks[1] -- 29
	s:play(animations[1], true) -- 30
	spineShadow = s -- 25
end -- 25
local spine -- 32
do -- 32
	local _with_0 = Spine(spineStr) -- 32
	_with_0.y = -200 -- 33
	_with_0:addChild((function() -- 34
		local _with_1 = Node() -- 34
		_with_1.order = -1 -- 35
		_with_1.size = Size(400, 400) -- 36
		do -- 38
			local _with_2 = _with_1:grab() -- 38
			do -- 39
				local _with_3 = SpriteEffect("builtin::vs_sprite", "builtin::fs_spriteoutlinecolor") -- 39
				_with_3:get(1):set("u_linecolor", Color(0xff00ffff)) -- 40
				_with_3:get(1):set("u_lineoffset", 5 / 400, 5 / 400, 5, 0.1) -- 41
				_with_2.effect = _with_3 -- 39
			end -- 39
			_with_2:setColor(1, 2, Color(0x007ec0f8)) -- 42
			_with_2:setColor(2, 2, Color(0x007ec0f8)) -- 43
		end -- 38
		_with_1:addChild(spineShadow) -- 44
		return _with_1 -- 34
	end)()) -- 34
	_with_0.scaleX = 2.0 -- 45
	_with_0.scaleY = 2.0 -- 46
	_with_0.look = looks[1] -- 47
	_with_0:play(animations[1], true) -- 48
	_with_0:slot("AnimationEnd", function(name) -- 49
		return print(tostring(name) .. " end!") -- 49
	end) -- 49
	_with_0:schedule(loop(function() -- 50
		spineShadow:setSlot("item", (function() -- 52
			local _with_1 = Spine("coldweapon") -- 52
			_with_1.look = "grenade" -- 53
			_with_1.scaleX = 0.04 -- 54
			_with_1.scaleY = 0.04 -- 55
			return _with_1 -- 52
		end)()) -- 52
		spineShadow:play("throw") -- 56
		_with_0:setSlot("item", (function() -- 57
			local _with_1 = Spine("coldweapon") -- 57
			_with_1.look = "grenade" -- 58
			_with_1.scaleX = 0.04 -- 59
			_with_1.scaleY = 0.04 -- 60
			return _with_1 -- 57
		end)()) -- 57
		sleep(_with_0:play("throw")) -- 61
		spineShadow:setSlot("comm", (function() -- 64
			local _with_1 = Spine("coldweapon") -- 64
			_with_1.look = "comm" -- 65
			_with_1.scaleX = 0.06 -- 66
			_with_1.scaleY = 0.06 -- 67
			return _with_1 -- 64
		end)()) -- 64
		spineShadow:play("comm") -- 68
		_with_0:setSlot("comm", (function() -- 69
			local _with_1 = Spine("coldweapon") -- 69
			_with_1.look = "comm" -- 70
			_with_1.scaleX = 0.06 -- 71
			_with_1.scaleY = 0.06 -- 72
			return _with_1 -- 69
		end)()) -- 69
		sleep(_with_0:play("comm")) -- 73
		spineShadow:setSlot("comp", (function() -- 76
			local _with_1 = Spine("coldweapon") -- 76
			_with_1.look = "comp" -- 77
			_with_1.scaleX = 0.1 -- 78
			_with_1.scaleY = 0.1 -- 79
			return _with_1 -- 76
		end)()) -- 76
		spineShadow:play("comp") -- 80
		_with_0:setSlot("comp", (function() -- 81
			local _with_1 = Spine("coldweapon") -- 81
			_with_1.look = "comp" -- 82
			_with_1.scaleX = 0.1 -- 83
			_with_1.scaleY = 0.1 -- 84
			return _with_1 -- 81
		end)()) -- 81
		sleep(_with_0:play("comp")) -- 85
		spineShadow:setSlot("shield", (function() -- 88
			local _with_1 = Spine("coldweapon") -- 88
			_with_1.look = "shield" -- 89
			_with_1.scaleX = 0.2 -- 90
			_with_1.scaleY = 0.2 -- 91
			return _with_1 -- 88
		end)()) -- 88
		spineShadow:play("defence") -- 92
		_with_0:setSlot("shield", (function() -- 93
			local _with_1 = Spine("coldweapon") -- 93
			_with_1.look = "shield" -- 94
			_with_1.scaleX = 0.2 -- 95
			_with_1.scaleY = 0.2 -- 96
			return _with_1 -- 93
		end)()) -- 93
		sleep(_with_0:play("defence")) -- 97
		local _list_0 = { -- 99
			"sword", -- 99
			"shovel", -- 99
			"axe" -- 99
		} -- 99
		for _index_0 = 1, #_list_0 do -- 99
			local mname = _list_0[_index_0] -- 99
			spineShadow:setSlot("melee", (function() -- 100
				local _with_1 = Spine("coldweapon") -- 100
				_with_1.look = mname -- 101
				_with_1.scaleX = 0.2 -- 102
				_with_1.scaleY = 0.2 -- 103
				return _with_1 -- 100
			end)()) -- 100
			_with_0:setSlot("melee", (function() -- 104
				local _with_1 = Spine("coldweapon") -- 104
				_with_1.look = mname -- 105
				_with_1.scaleX = 0.2 -- 106
				_with_1.scaleY = 0.2 -- 107
				return _with_1 -- 104
			end)()) -- 104
			spineShadow:play("melee") -- 108
			sleep(_with_0:play("melee")) -- 109
			spineShadow:play("parry") -- 110
			sleep(_with_0:play("parry")) -- 111
		end -- 111
		spineShadow:setSlot("bow", (function() -- 114
			local _with_1 = Spine("coldweapon") -- 114
			_with_1.look = "bow" -- 115
			_with_1.scaleX = 0.2 -- 116
			_with_1.scaleY = 0.2 -- 117
			return _with_1 -- 114
		end)()) -- 114
		spineShadow:play("bow") -- 118
		_with_0:setSlot("bow", (function() -- 119
			local _with_1 = Spine("coldweapon") -- 119
			_with_1.look = "bow" -- 120
			_with_1.scaleX = 0.2 -- 121
			_with_1.scaleY = 0.2 -- 122
			return _with_1 -- 119
		end)()) -- 119
		sleep(_with_0:play("bow")) -- 123
		local _list_1 = { -- 125
			"kineticgun", -- 125
			"lasergun", -- 125
			"empgun" -- 125
		} -- 125
		for _index_0 = 1, #_list_1 do -- 125
			local gname = _list_1[_index_0] -- 125
			spineShadow:setSlot("pistol", (function() -- 127
				local _with_1 = Spine(gname) -- 127
				_with_1.look = "PT" -- 128
				_with_1.scaleX = 0.2 -- 129
				_with_1.scaleY = 0.2 -- 130
				return _with_1 -- 127
			end)()) -- 127
			spineShadow:play("pistol") -- 131
			_with_0:setSlot("pistol", (function() -- 132
				local _with_1 = Spine(gname) -- 132
				_with_1.look = "PT" -- 133
				_with_1.scaleX = 0.2 -- 134
				_with_1.scaleY = 0.2 -- 135
				return _with_1 -- 132
			end)()) -- 132
			sleep(_with_0:play("pistol")) -- 136
			local _list_2 = { -- 138
				"AR", -- 138
				"LMG", -- 138
				"SMG", -- 138
				"SR", -- 138
				"SCG", -- 138
				"SG" -- 138
			} -- 138
			for _index_1 = 1, #_list_2 do -- 138
				local gtype = _list_2[_index_1] -- 138
				spineShadow:setSlot("gun", (function() -- 139
					local _with_1 = Spine(gname) -- 139
					_with_1.look = gtype -- 140
					_with_1.scaleX = 0.2 -- 141
					_with_1.scaleY = 0.2 -- 142
					return _with_1 -- 139
				end)()) -- 139
				_with_0:setSlot("gun", (function() -- 143
					local _with_1 = Spine(gname) -- 143
					_with_1.look = gtype -- 144
					_with_1.scaleX = 0.2 -- 145
					_with_1.scaleY = 0.2 -- 146
					return _with_1 -- 143
				end)()) -- 143
				spineShadow:play("gun1") -- 147
				sleep(_with_0:play("gun1")) -- 148
				spineShadow:play("gun2") -- 149
				sleep(_with_0:play("gun2")) -- 150
				spineShadow:play("gun3") -- 151
				sleep(_with_0:play("gun3")) -- 152
			end -- 152
		end -- 152
	end)) -- 50
	_with_0.touchEnabled = true -- 154
	_with_0:slot("TapBegan", function(touch) -- 155
		local x, y -- 156
		do -- 156
			local _obj_0 = touch.location -- 156
			x, y = _obj_0.x, _obj_0.y -- 156
		end -- 156
		do -- 157
			local name = _with_0:containsPoint(x, y) -- 157
			if name then -- 157
				return _with_0:addChild((function() -- 158
					local _with_1 = Label("NotoSansHans-Regular", 30) -- 158
					_with_1.text = name -- 159
					_with_1.color = Color(0xff00ffff) -- 160
					_with_1:perform(Sequence(Spawn(Scale(1, 0, 2, Ease.OutQuad), Sequence(Delay(0.5), Opacity(0.5, 1, 0))), Event("Stop"))) -- 161
					_with_1.position = Vec2(x, y) -- 168
					_with_1:slot("Stop", function() -- 169
						return _with_1:removeFromParent() -- 169
					end) -- 169
					return _with_1 -- 158
				end)()) -- 169
			end -- 157
		end -- 157
	end) -- 155
	spine = _with_0 -- 32
end -- 32
Director.entry:addChild(spine) -- 171
return Director.entry:addChild((function() -- 175
	local _with_0 = Node() -- 175
	_with_0:schedule(function() -- 176
		local width, height -- 177
		do -- 177
			local _obj_0 = App.visualSize -- 177
			width, height = _obj_0.width, _obj_0.height -- 177
		end -- 177
		SetNextWindowPos(Vec2(width - 250, 10), "FirstUseEver") -- 178
		SetNextWindowSize(Vec2(240, 140), "FirstUseEver") -- 179
		return Begin("Assembling", { -- 180
			"NoResize", -- 180
			"NoSavedSettings" -- 180
		}, function() -- 180
			TextWrapped("Assembling troops example. Tap it for a hit test.") -- 181
			local _ -- 182
			_, spine.showDebug = Checkbox("BoundingBox", spine.showDebug) -- 182
		end) -- 182
	end) -- 176
	return _with_0 -- 175
end)()) -- 182