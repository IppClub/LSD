-- [yue]: Script/Academy/System.yue
local _module_0 = nil -- 1
local _ENV = Dora(Dora.Platformer) -- 1
local require <const> = require -- 2
local Data <const> = Data -- 2
local Observer <const> = Observer -- 2
local tostring <const> = tostring -- 2
local once <const> = once -- 2
local App <const> = App -- 2
local sleep <const> = sleep -- 2
local Director <const> = Director -- 2
local Entity <const> = Entity -- 2
local assert <const> = assert -- 2
local Dictionary <const> = Dictionary -- 2
local Vec2 <const> = Vec2 -- 2
local Size <const> = Size -- 2
local Array <const> = Array -- 2
local Unit <const> = Unit -- 2
local math <const> = math -- 2
local Node <const> = Node -- 2
local Color <const> = Color -- 2
local cycle <const> = cycle -- 2
local SpriteEffect <const> = SpriteEffect -- 2
local thread <const> = thread -- 2
local _anon_func_0 = function(_with_1, moveEnter, unit) -- 77
	if "center" == moveEnter then -- 78
		return unit.faceRight -- 78
	elseif "left" == moveEnter then -- 79
		return true -- 79
	elseif "right" == moveEnter then -- 80
		return false -- 80
	end -- 77
end -- 77
local _anon_func_1 = function(MaxPath, self, u) -- 148
	local _exp_0 = self.order -- 148
	if _exp_0 ~= nil then -- 148
		return _exp_0 -- 148
	else -- 148
		return math.random(-MaxPath, MaxPath) -- 148
	end -- 148
end -- 148
local _anon_func_2 = function(GrabSize, _with_1, parent) -- 151
	local _with_0 = Node() -- 151
	_with_0.size = Size(GrabSize, GrabSize) -- 152
	_with_0:addTo(parent) -- 153
	return _with_0 -- 151
end -- 151
local _anon_func_3 = function(u) -- 156
	local _val_0 = u.decisionTree -- 156
	return not ("AI:PlayerControl" == _val_0 or "AI:NPC" == _val_0) -- 156
end -- 156
_module_0 = function() -- 4
	local Interaction = require("UI.Interaction") -- 5
	local Set = require("Utils").Set -- 6
	local Map = require("Academy.Map") -- 7
	local Store -- 9
	Store = Data.store -- 9
	local Width <const>, Height <const>, GrabSize <const>, Outline <const>, MaxPath <const> = 100, 300, 400, 6, 2 -- 10
	local names <const> = { -- 13
		moling = '忍冬', -- 13
		moyu = '半夏', -- 14
		liyena = '李叶娜', -- 15
		ayan = '阿岩', -- 16
		villywan = '万薇莉', -- 17
		yuzijiang = '余子绛', -- 18
		ninilite = '妮妮莉特', -- 19
		wuyun = '乌云', -- 20
		sunborn = '林睿哲' -- 21
	} -- 12
	local moveComs <const> = { -- 25
		"unit", -- 25
		"moveFromRight", -- 26
		"moveRouteName", -- 27
		"moveEnter", -- 28
		"moveTargets" -- 29
	} -- 24
	local defaultFaceLeft = Set({ -- 32
		"liyena", -- 32
		"dataotie" -- 33
	}) -- 31
	do -- 35
		local _with_0 = Observer("Add", moveComs) -- 35
		_with_0:watch(function(self, unit, moveFromRight, moveRouteName, moveEnter, moveTargets) -- 36
			local buttons -- 43
			do -- 43
				local _accum_0 = { } -- 43
				local _len_0 = 1 -- 43
				for _index_0 = 1, #moveTargets do -- 43
					local target = moveTargets[_index_0] -- 43
					_accum_0[_len_0] = { -- 43
						Map.getName(target), -- 43
						target:upper() -- 43
					} -- 43
					_len_0 = _len_0 + 1 -- 43
				end -- 43
				buttons = _accum_0 -- 43
			end -- 43
			local fliped = not moveFromRight -- 44
			local forbidden = moveTargets.empty -- 45
			if forbidden then -- 46
				buttons[#buttons + 1] = { -- 46
					"禁行区域", -- 46
					"FORBIDDEN" -- 46
				} -- 46
			end -- 46
			local _with_1 = Interaction({ -- 47
				text = moveRouteName, -- 47
				buttons = buttons, -- 47
				fliped = fliped -- 47
			}) -- 47
			_with_1.order = unit.world.children.last.order -- 48
			_with_1.transformTarget = unit -- 49
			_with_1:show() -- 50
			if forbidden then -- 51
				_with_1.menu.enabled = false -- 52
			else -- 54
				local name = self.name -- 54
				_with_1:slot("Tapped", function(index) -- 55
					local sceneName = moveTargets[index] -- 56
					local worldClass = require("Scene." .. tostring(sceneName)) -- 57
					return _with_1:schedule(once(function() -- 58
						local startTime = App.runningTime -- 59
						worldClass:loadAsync() -- 60
						local deltaTime = App.runningTime - startTime -- 61
						if deltaTime < 0.5 then -- 62
							sleep(0.5 - deltaTime) -- 63
						end -- 62
						local oldWorld = Store.world -- 64
						local world -- 65
						do -- 65
							local _with_2 = worldClass() -- 65
							_with_2.visible = false -- 66
							_with_2.camera.position = _with_2[moveEnter] -- 67
							if "left" == moveEnter then -- 69
								_with_2:openLeftDoor() -- 69
							elseif "right" == moveEnter then -- 70
								_with_2:openRightDoor() -- 70
							elseif "center" == moveEnter then -- 71
								_with_2:openCenterDoor() -- 71
							end -- 68
							_with_2:addTo(Director.entry) -- 72
							world = _with_2 -- 65
						end -- 65
						Store.world = world -- 73
						Entity({ -- 75
							player = true, -- 75
							name = name, -- 76
							faceRight = _anon_func_0(_with_1, moveEnter, unit), -- 77
							position = assert(world[moveEnter]), -- 81
							base = true -- 82
						}) -- 74
						sleep() -- 98
						world.visible = true -- 99
						oldWorld:removeFromParent() -- 100
						return require("Academy.Navigation").attach(world) -- 101
					end)) -- 58
				end) -- 55
			end -- 51
			_with_1:addTo(unit.world) -- 102
			self.interaction = _with_1 -- 47
		end) -- 36
	end -- 35
	do -- 104
		local _with_0 = Observer("Remove", moveComs) -- 104
		_with_0:watch(function(self) -- 105
			local _with_1 = self.interaction -- 106
			if _with_1 ~= nil then -- 106
				_with_1:hide() -- 107
				self.interaction = nil -- 108
			end -- 106
			return _with_1 -- 106
		end) -- 105
	end -- 104
	local _with_0 = Observer("Add", { -- 110
		"player", -- 110
		"name", -- 110
		"position", -- 110
		"faceRight", -- 110
		"base" -- 110
	}) -- 110
	_with_0:watch(function(self, player, name, position, faceRight) -- 111
		local unitDef -- 112
		do -- 112
			local _with_1 = Dictionary() -- 112
			_with_1.linearAcceleration = Vec2(0, -15) -- 113
			_with_1.bodyType = "Dynamic" -- 114
			_with_1.scale = 1.0 -- 115
			_with_1.density = 1.0 -- 116
			_with_1.friction = 1.0 -- 117
			_with_1.restitution = 0.0 -- 118
			_with_1.playable = "spine:" .. tostring(name) -- 119
			_with_1.defaultFaceRight = not defaultFaceLeft[name] -- 120
			_with_1.size = Size(Width, Height) -- 121
			_with_1.sensity = player and 0.0 or 0.5 -- 122
			_with_1.move = 300 -- 123
			_with_1.jump = 800 -- 124
			_with_1.detectDistance = 200 -- 125
			_with_1.attackRange = Size(800, 200) -- 126
			_with_1.hp = 1.0 -- 127
			do -- 128
				local _exp_0 = self.decisionTree -- 128
				if _exp_0 ~= nil then -- 128
					_with_1.decisionTree = _exp_0 -- 128
				else -- 128
					_with_1.decisionTree = player and "AI:PlayerControl" or "AI:NPC" -- 128
				end -- 128
			end -- 128
			_with_1.usePreciseHit = false -- 129
			_with_1.actions = Array({ -- 131
				"hit", -- 131
				"pistol", -- 132
				"idle", -- 133
				"prepare", -- 134
				"turn", -- 135
				"fmove", -- 136
				"bmove", -- 137
				"jump", -- 138
				"fallOff", -- 139
				"cancel", -- 140
				"keepIdle", -- 141
				"keepMove", -- 142
				"idle1" -- 143
			}) -- 130
			unitDef = _with_1 -- 112
		end -- 112
		local world = Store.world -- 144
		local unit -- 145
		do -- 145
			local u = Unit(unitDef, world, self, position + Vec2(0, Height / 2)) -- 145
			u.group = 1 -- 146
			u.faceRight = faceRight -- 147
			u.order = player and 0 or (_anon_func_1(MaxPath, self, u)) -- 148
			do -- 149
				local _with_1 = u.playable -- 149
				local parent = _with_1.parent -- 150
				_with_1:moveToParent(_anon_func_2(GrabSize, _with_1, parent)) -- 151
				_with_1.position = Vec2(GrabSize / 2, GrabSize / 2 - Height / 2) -- 154
			end -- 149
			local isCommonAI = true -- 155
			if _anon_func_3(u) then -- 156
				isCommonAI = false -- 157
				if player then -- 158
					world.camera.followTarget = u -- 159
				end -- 158
			end -- 156
			world:addShadowTo(u) -- 160
			u:addTo(world) -- 161
			if not isCommonAI then -- 162
				return -- 162
			end -- 162
			unit = u -- 145
		end -- 145
		if player then -- 163
			unit:gslot("Skill.Began", function() -- 164
				self.keySkill = true -- 164
			end) -- 164
			unit:gslot("Skill.Ended", function() -- 165
				self.keySkill = false -- 165
			end) -- 165
			do -- 166
				local _with_1 = world.camera -- 166
				_with_1.followTarget = unit -- 167
			end -- 166
			local _with_1 = unit.playable.parent -- 168
			local sensor = unit:getSensorByTag(Unit.DetectSensorTag) -- 169
			_with_1:schedule(function() -- 170
				local target = nil -- 171
				local minDictance = nil -- 172
				if unit.entity.busy then -- 173
					return -- 173
				end -- 173
				local _list_0 = sensor.sensedBodies -- 174
				for _index_0 = 1, #_list_0 do -- 174
					local body = _list_0[_index_0] -- 174
					-- Route choices take priority while inside a door sensor.
					if unit.entity.moveTargets then goto _continue_0 end
					local entity = body.entity -- 175
					if not entity then -- 176
						goto _continue_0 -- 176
					end -- 176
					if entity.storyCompanion then -- 177
						goto _continue_0 -- 177
					end -- 177
					if body.decisionTree ~= "AI:NPC" then -- 178
						goto _continue_0 -- 178
					end -- 178
					if not (entity.player ~= nil) then -- 179
						goto _continue_0 -- 179
					end -- 179
					if body == unit then -- 180
						goto _continue_0 -- 180
					end -- 180
					if entity.busy then -- 181
						goto _continue_0 -- 181
					end -- 181
					local posA, zA = body:convertToWorldSpace(Vec2.zero, 0) -- 182
					local posB, zB = unit:convertToWorldSpace(Vec2.zero, 0) -- 183
					local dx, dy, dz = posA.x - posB.x, posA.y - posB.y, zA - zB -- 184
					local distance = dx * dx + dy * dy + dz * dz -- 185
					if not minDictance or minDictance > distance then -- 186
						minDictance = distance -- 187
						target = body -- 188
					end -- 186
					::_continue_0:: -- 175
				end -- 174
				local oldTarget = self.target -- 189
				if oldTarget ~= target then -- 190
					if oldTarget then -- 191
						do -- 192
							local _with_2 = oldTarget.entity.interaction -- 192
							if _with_2 ~= nil then -- 192
								_with_2:hide() -- 193
								oldTarget.entity.interaction = nil -- 194
							end -- 192
						end -- 192
						local playable = oldTarget.playable -- 195
						playable:schedule(once(function() -- 196
							do -- 197
								local _with_2 = playable.parent:grab() -- 197
								local color = Color(0x007ec0f8) -- 198
								_with_2.effect:get(1):set("u_linecolor", color) -- 199
								cycle(0.3, function(dt) -- 200
									color.opacity = 1.0 - dt -- 201
									return _with_2.effect:get(1):set("u_linecolor", color) -- 202
								end) -- 200
							end -- 197
							return playable.parent:grab(false) -- 203
						end)) -- 196
					end -- 191
					self.target = target -- 204
					if target then -- 205
						do -- 206
							local _with_2 = target.playable.parent:grab() -- 206
							local _with_3 = SpriteEffect("builtin:vs_sprite", "builtin:fs_spriteoutlinecolor") -- 207
							local color = Color(0x007ec0f8) -- 208
							_with_3:get(1):set("u_linecolor", color) -- 209
							target.playable:schedule(once(function() -- 210
								return cycle(0.3, function(dt) -- 211
									color.opacity = dt -- 212
									return _with_3:get(1):set("u_linecolor", color) -- 213
								end) -- 211
							end)) -- 210
							_with_3:get(1):set("u_lineoffset", Outline, Outline, 0.1) -- 214
							_with_2.effect = _with_3 -- 207
						end -- 206
						local nameText -- 215
						do -- 215
							local _exp_0 = names[target.entity.name] -- 215
							if _exp_0 ~= nil then -- 215
								nameText = _exp_0 -- 215
							else -- 215
								nameText = "人物" -- 215
							end -- 215
						end -- 215
						local ui = Interaction({ -- 216
							text = nameText, -- 216
							buttons = { -- 217
								{ -- 217
									"对话", -- 217
									"TALK" -- 217
								}, -- 217
								{ -- 218
									"个人信息", -- 218
									"INFORMATION" -- 218
								} -- 218
							}, -- 216
							fliped = target.x < unit.x -- 219
						}) -- 216
						ui.order = world.children.last.order -- 220
						ui.transformTarget = target -- 221
						ui:slot("Tapped", function(index) -- 222
							return thread(function() -- 223
								return require("Academy.Companion").openAsync(target.entity.name, world, index == 1 and "talk" or "information") -- 223
							end) -- 223
						end) -- 222
						ui:addTo(world) -- 224
						ui:show() -- 225
						target.entity.interaction = ui -- 216
					end -- 205
				end -- 190
			end) -- 170
			return _with_1 -- 168
		end -- 163
	end) -- 111
	return _with_0 -- 110
end -- 4
return _module_0 -- 1
