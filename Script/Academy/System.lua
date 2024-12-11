-- [yue]: Script/Academy/System.yue
local _module_0 = Dora.Platformer -- 1
local Data = _module_0.Data -- 1
local Observer = Dora.Observer -- 1
local tostring = _G.tostring -- 1
local once = Dora.once -- 1
local App = Dora.App -- 1
local sleep = Dora.sleep -- 1
local Director = Dora.Director -- 1
local Entity = Dora.Entity -- 1
local assert = _G.assert -- 1
local Dictionary = Dora.Dictionary -- 1
local Vec2 = Dora.Vec2 -- 1
local Size = Dora.Size -- 1
local Array = Dora.Array -- 1
local Unit = _module_0.Unit -- 1
local math = _G.math -- 1
local Node = Dora.Node -- 1
local Color = Dora.Color -- 1
local cycle = Dora.cycle -- 1
local SpriteEffect = Dora.SpriteEffect -- 1
local _module_0 = nil -- 1
local _anon_func_0 = function(_with_1, moveEnter, unit) -- 79
	if "center" == moveEnter then -- 77
		return unit.faceRight -- 77
	elseif "left" == moveEnter then -- 78
		return true -- 78
	elseif "right" == moveEnter then -- 79
		return false -- 79
	end -- 79
end -- 76
local _anon_func_1 = function(MaxPath, math, self, u) -- 146
	local _exp_0 = self.order -- 146
	if _exp_0 ~= nil then -- 146
		return _exp_0 -- 146
	else -- 146
		return math.random(-MaxPath, MaxPath) -- 146
	end -- 146
end -- 146
local _anon_func_2 = function(GrabSize, Node, Size, _with_1, parent) -- 151
	local _with_0 = Node() -- 149
	_with_0.size = Size(GrabSize, GrabSize) -- 150
	_with_0:addTo(parent) -- 151
	return _with_0 -- 149
end -- 149
local _anon_func_3 = function(u) -- 154
	local _val_0 = u.decisionTree -- 154
	return not ("AI:PlayerControl" == _val_0 or "AI:NPC" == _val_0) -- 154
end -- 154
_module_0 = function() -- 3
	local Interaction = require("UI.Interaction") -- 4
	local Set = require("Utils").Set -- 5
	local Map = require("Academy.Map") -- 6
	local Store -- 8
	Store = Data.store -- 8
	local Width <const>, Height <const>, GrabSize <const>, Outline <const>, MaxPath <const> = 100, 300, 400, 6, 2 -- 9
	local names <const> = { -- 12
		moling = '默翎', -- 12
		moyu = '默羽', -- 13
		liyena = '李叶那', -- 14
		ayan = '阿岩', -- 15
		villywan = '万薇莉', -- 16
		yuzijiang = '余梓绛', -- 17
		ninilite = '妮妮莉特', -- 18
		wuyun = '乌云', -- 19
		sunborn = '向阳珄' -- 20
	} -- 11
	local moveComs <const> = { -- 24
		"unit", -- 24
		"moveFromRight", -- 25
		"moveRouteName", -- 26
		"moveEnter", -- 27
		"moveTargets" -- 28
	} -- 23
	local defaultFaceLeft = Set({ -- 31
		"liyena", -- 31
		"dataotie" -- 32
	}) -- 30
	do -- 34
		local _with_0 = Observer("Add", moveComs) -- 34
		_with_0:watch(function(self, unit, moveFromRight, moveRouteName, moveEnter, moveTargets) -- 41
			local buttons -- 42
			do -- 42
				local _accum_0 = { } -- 42
				local _len_0 = 1 -- 42
				for _index_0 = 1, #moveTargets do -- 42
					local target = moveTargets[_index_0] -- 42
					_accum_0[_len_0] = { -- 42
						Map.getName(target), -- 42
						target:upper() -- 42
					} -- 42
					_len_0 = _len_0 + 1 -- 42
				end -- 42
				buttons = _accum_0 -- 42
			end -- 42
			local fliped = not moveFromRight -- 43
			local forbidden = moveTargets.empty -- 44
			if forbidden then -- 45
				buttons[#buttons + 1] = { -- 45
					"禁行区域", -- 45
					"FORBIDDEN" -- 45
				} -- 45
			end -- 45
			local _with_1 = Interaction({ -- 46
				text = moveRouteName, -- 46
				buttons = buttons, -- 46
				fliped = fliped -- 46
			}) -- 46
			_with_1.order = unit.world.children.last.order -- 47
			_with_1.transformTarget = unit -- 48
			_with_1:show() -- 49
			if forbidden then -- 50
				_with_1.menu.enabled = false -- 51
			else -- 53
				local name = self.name -- 53
				_with_1:slot("Tapped", function(index) -- 54
					local sceneName = moveTargets[index] -- 55
					local worldClass = require("Scene." .. tostring(sceneName)) -- 56
					return _with_1:schedule(once(function() -- 57
						local startTime = App.runningTime -- 58
						worldClass:loadAsync() -- 59
						local deltaTime = App.runningTime - startTime -- 60
						if deltaTime < 0.5 then -- 61
							sleep(0.5 - deltaTime) -- 62
						end -- 61
						local oldWorld = Store.world -- 63
						local world -- 64
						do -- 64
							local _with_2 = worldClass() -- 64
							_with_2.visible = false -- 65
							_with_2.camera.position = _with_2[moveEnter] -- 66
							if "left" == moveEnter then -- 68
								_with_2:openLeftDoor() -- 68
							elseif "right" == moveEnter then -- 69
								_with_2:openRightDoor() -- 69
							elseif "center" == moveEnter then -- 70
								_with_2:openCenterDoor() -- 70
							end -- 70
							_with_2:addTo(Director.entry) -- 71
							world = _with_2 -- 64
						end -- 64
						Store.world = world -- 72
						Entity({ -- 74
							player = true, -- 74
							name = name, -- 75
							faceRight = _anon_func_0(_with_1, moveEnter, unit), -- 76
							position = assert(world[moveEnter]), -- 80
							base = true -- 81
						}) -- 73
						sleep() -- 97
						world.visible = true -- 98
						return oldWorld:removeFromParent() -- 99
					end)) -- 99
				end) -- 54
			end -- 50
			_with_1:addTo(unit.world) -- 100
			self.interaction = _with_1 -- 46
		end) -- 35
	end -- 34
	do -- 102
		local _with_0 = Observer("Remove", moveComs) -- 102
		_with_0:watch(function(self) -- 103
			local _with_1 = self.interaction -- 104
			if _with_1 ~= nil then -- 104
				_with_1:hide() -- 105
				self.interaction = nil -- 106
			end -- 104
			return _with_1 -- 104
		end) -- 103
	end -- 102
	local _with_0 = Observer("Add", { -- 108
		"player", -- 108
		"name", -- 108
		"position", -- 108
		"faceRight", -- 108
		"base" -- 108
	}) -- 108
	_with_0:watch(function(self, player, name, position, faceRight) -- 109
		local unitDef -- 110
		do -- 110
			local _with_1 = Dictionary() -- 110
			_with_1.linearAcceleration = Vec2(0, -15) -- 111
			_with_1.bodyType = "Dynamic" -- 112
			_with_1.scale = 1.0 -- 113
			_with_1.density = 1.0 -- 114
			_with_1.friction = 1.0 -- 115
			_with_1.restitution = 0.0 -- 116
			_with_1.playable = "spine:" .. tostring(name) -- 117
			_with_1.defaultFaceRight = not defaultFaceLeft[name] -- 118
			_with_1.size = Size(Width, Height) -- 119
			_with_1.sensity = player and 0.0 or 0.5 -- 120
			_with_1.move = 300 -- 121
			_with_1.jump = 800 -- 122
			_with_1.detectDistance = 200 -- 123
			_with_1.attackRange = Size(800, 200) -- 124
			_with_1.hp = 1.0 -- 125
			do -- 126
				local _exp_0 = self.decisionTree -- 126
				if _exp_0 ~= nil then -- 126
					_with_1.decisionTree = _exp_0 -- 126
				else -- 126
					_with_1.decisionTree = player and "AI:PlayerControl" or "AI:NPC" -- 126
				end -- 126
			end -- 126
			_with_1.usePreciseHit = false -- 127
			_with_1.actions = Array({ -- 129
				"hit", -- 129
				"pistol", -- 130
				"idle", -- 131
				"prepare", -- 132
				"turn", -- 133
				"fmove", -- 134
				"bmove", -- 135
				"jump", -- 136
				"fallOff", -- 137
				"cancel", -- 138
				"keepIdle", -- 139
				"keepMove", -- 140
				"idle1" -- 141
			}) -- 128
			unitDef = _with_1 -- 110
		end -- 110
		local world = Store.world -- 142
		local unit -- 143
		do -- 143
			local u = Unit(unitDef, world, self, position + Vec2(0, Height / 2)) -- 143
			u.group = 1 -- 144
			u.faceRight = faceRight -- 145
			u.order = player and 0 or (_anon_func_1(MaxPath, math, self, u)) -- 146
			do -- 147
				local _with_1 = u.playable -- 147
				local parent = _with_1.parent -- 148
				_with_1:moveToParent(_anon_func_2(GrabSize, Node, Size, _with_1, parent)) -- 149
				_with_1.position = Vec2(GrabSize / 2, GrabSize / 2 - Height / 2) -- 152
			end -- 147
			local isCommonAI = true -- 153
			if _anon_func_3(u) then -- 154
				isCommonAI = false -- 155
				if player then -- 156
					world.camera.followTarget = unit -- 157
				end -- 156
			end -- 154
			world:addShadowTo(u) -- 158
			u:addTo(world) -- 159
			if not isCommonAI then -- 160
				return -- 160
			end -- 160
			unit = u -- 143
		end -- 143
		if player then -- 161
			unit:gslot("Skill.Began", function() -- 162
				self.keySkill = true -- 162
			end) -- 162
			unit:gslot("Skill.Ended", function() -- 163
				self.keySkill = false -- 163
			end) -- 163
			do -- 164
				local _with_1 = world.camera -- 164
				_with_1.followTarget = unit -- 165
			end -- 164
			local _with_1 = unit.playable.parent -- 166
			local sensor = unit:getSensorByTag(Unit.DetectSensorTag) -- 167
			_with_1:schedule(function() -- 168
				local target = nil -- 169
				local minDictance = nil -- 170
				if unit.entity.busy then -- 171
					return -- 171
				end -- 171
				local _list_0 = sensor.sensedBodies -- 172
				for _index_0 = 1, #_list_0 do -- 172
					local body = _list_0[_index_0] -- 172
					local entity = body.entity -- 173
					if not entity then -- 174
						goto _continue_0 -- 174
					end -- 174
					if body.decisionTree ~= "AI:NPC" then -- 175
						goto _continue_0 -- 175
					end -- 175
					if not (entity.player ~= nil) then -- 176
						goto _continue_0 -- 176
					end -- 176
					if body == unit then -- 177
						goto _continue_0 -- 177
					end -- 177
					if entity.busy then -- 178
						goto _continue_0 -- 178
					end -- 178
					local posA, zA = body:convertToWorldSpace(Vec2.zero, 0) -- 179
					local posB, zB = unit:convertToWorldSpace(Vec2.zero, 0) -- 180
					local dx, dy, dz = posA.x - posB.x, posA.y - posB.y, zA - zB -- 181
					local distance = dx * dx + dy * dy + dz * dz -- 182
					if not minDictance or minDictance > distance then -- 183
						minDictance = distance -- 184
						target = body -- 185
					end -- 183
					::_continue_0:: -- 173
				end -- 185
				local oldTarget = self.target -- 186
				if oldTarget ~= target then -- 187
					if oldTarget then -- 188
						do -- 189
							local _with_2 = oldTarget.entity.interaction -- 189
							if _with_2 ~= nil then -- 189
								_with_2:hide() -- 190
								oldTarget.entity.interaction = nil -- 191
							end -- 189
						end -- 189
						local playable = oldTarget.playable -- 192
						playable:schedule(once(function() -- 193
							do -- 194
								local _with_2 = playable.parent:grab() -- 194
								local color = Color(0x007ec0f8) -- 195
								_with_2.effect:get(1):set("u_linecolor", color) -- 196
								cycle(0.3, function(dt) -- 197
									color.opacity = 1.0 - dt -- 198
									return _with_2.effect:get(1):set("u_linecolor", color) -- 199
								end) -- 197
							end -- 194
							return playable.parent:grab(false) -- 200
						end)) -- 193
					end -- 188
					self.target = target -- 201
					if target then -- 202
						do -- 203
							local _with_2 = target.playable.parent:grab() -- 203
							local _with_3 = SpriteEffect("builtin:vs_sprite", "builtin:fs_spriteoutlinecolor") -- 204
							local color = Color(0x007ec0f8) -- 205
							_with_3:get(1):set("u_linecolor", color) -- 206
							target.playable:schedule(once(function() -- 207
								return cycle(0.3, function(dt) -- 208
									color.opacity = dt -- 209
									return _with_3:get(1):set("u_linecolor", color) -- 210
								end) -- 210
							end)) -- 207
							_with_3:get(1):set("u_lineoffset", Outline, Outline, 0.1) -- 211
							_with_2.effect = _with_3 -- 204
						end -- 203
						local nameText -- 212
						do -- 212
							local _exp_0 = names[target.entity.name] -- 212
							if _exp_0 ~= nil then -- 212
								nameText = _exp_0 -- 212
							else -- 212
								nameText = "人物" -- 212
							end -- 212
						end -- 212
						local ui = Interaction({ -- 213
							text = nameText, -- 213
							buttons = { -- 214
								{ -- 214
									"对话", -- 214
									"TALK" -- 214
								}, -- 214
								{ -- 215
									"进行训练", -- 215
									"TRAINING" -- 215
								}, -- 215
								{ -- 216
									"个人信息", -- 216
									"INFORMATION" -- 216
								} -- 216
							}, -- 213
							fliped = target.x < unit.x -- 217
						}) -- 213
						ui.order = world.children.last.order -- 218
						ui.transformTarget = target -- 219
						ui:slot("Tapped", function(index) -- 220
							if 1 == index then -- 222
								return ui:schedule(once(function() -- 222
									local startTime = App.runningTime -- 223
									local deltaTime = App.runningTime - startTime -- 224
									if deltaTime < 0.5 then -- 225
										sleep(0.5 - deltaTime) -- 226
									end -- 225
									ui:hide(false) -- 227
									local Story = require("UI.Story") -- 228
									return Director.ui:addChild((function() -- 229
										local _with_2 = Story() -- 229
										_with_2:slot("Hide", function() -- 230
											return ui:show() -- 230
										end) -- 230
										return _with_2 -- 229
									end)()) -- 230
								end)) -- 230
							end -- 230
						end) -- 220
						ui:addTo(world) -- 231
						ui:show() -- 232
						target.entity.interaction = ui -- 213
					end -- 202
				end -- 187
			end) -- 168
			return _with_1 -- 166
		end -- 161
	end) -- 109
	return _with_0 -- 108
end -- 3
return _module_0 -- 232
