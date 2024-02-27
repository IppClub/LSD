-- [yue]: Script/Tutorial/AI.yue
local _module_0 = dora.Platformer -- 1
local Data = _module_0.Data -- 1
local _module_1 = dora.Platformer.Decision -- 1
local Behave = _module_1.Behave -- 1
local Spine = dora.Spine -- 1
local Sel = _module_1.Sel -- 1
local Seq = _module_1.Seq -- 1
local Con = _module_1.Con -- 1
local AI = _module_1.AI -- 1
local math = _G.math -- 1
local Act = _module_1.Act -- 1
local Group = dora.Group -- 1
local Reject = _module_1.Reject -- 1
local Accept = _module_1.Accept -- 1
local _module_0 = nil -- 1
_module_0 = function() -- 6
	local Store = Data.store -- 7
	local BT = dora.Platformer.Behavior -- 8
	Store["AI:NiniliteIntro"] = Behave("intro", BT.Seq({ -- 11
		BT.Con("raise gun", function(self) -- 11
			do -- 12
				local _with_0 = self.owner.playable -- 12
				_with_0:setSlot("pistol", (function() -- 13
					local _with_1 = Spine("empgun") -- 13
					_with_1.look = "PT" -- 14
					_with_1.scaleX = 0.2 -- 15
					_with_1.scaleY = 0.2 -- 16
					return _with_1 -- 13
				end)()) -- 13
				_with_0.speed = 0.8 -- 17
				_with_0:play("pistol") -- 18
			end -- 12
			return true -- 19
		end), -- 11
		BT.Wait(0.5), -- 20
		BT.Con("hold gun", function(self) -- 21
			self.owner.playable.speed = 0 -- 22
			return true -- 23
		end), -- 21
		BT.Repeat(BT.Con("wait", function() -- 24
			return true -- 24
		end)) -- 24
	})) -- 10
	local normalNPC = Sel({ -- 28
		Seq({ -- 29
			Con("not facing nearest player", function(self) -- 29
				local _list_0 = AI:getDetectedUnits() -- 30
				for _index_0 = 1, #_list_0 do -- 30
					local unit = _list_0[_index_0] -- 30
					if unit.entity.player then -- 31
						return math.abs(self.x - unit.x) <= 200 and (self.x > unit.x) == self.faceRight -- 32
					end -- 31
				end -- 32
				do -- 33
					local unit = AI:getNearestUnit("Any") -- 33
					if unit then -- 33
						return math.abs(self.x - unit.x) <= 200 and (self.x > unit.x) == self.faceRight -- 34
					else -- 36
						return false -- 36
					end -- 33
				end -- 33
			end), -- 29
			Act("turn") -- 37
		}), -- 28
		Act("idle") -- 39
	}) -- 27
	local gotoExit = Seq({ -- 43
		Con("leading", function(self) -- 43
			return self.entity.leading -- 43
		end), -- 43
		Sel({ -- 45
			Seq({ -- 46
				Con("reached exit", function(unit) -- 46
					if unit.x >= 6200 then -- 47
						unit.entity.leading = false -- 48
						unit:emit("ReachedExit") -- 49
						return true -- 50
					else -- 52
						return false -- 52
					end -- 47
				end), -- 46
				normalNPC -- 53
			}), -- 45
			Seq({ -- 56
				Con("player is far", function(unit) -- 56
					return Group({ -- 57
						"player", -- 57
						"unit" -- 57
					}):each(function(self) -- 57
						return self.player and unit.x - self.unit.x > 400 -- 57
					end) -- 57
				end), -- 56
				Act("idle") -- 58
			}), -- 55
			Seq({ -- 61
				Con("not facing exit", function(self) -- 61
					return not self.faceRight -- 61
				end), -- 61
				Act("turn"), -- 62
				Reject() -- 63
			}), -- 60
			Act("fmove") -- 65
		}) -- 44
	}) -- 42
	Store["AI:NPC"] = Sel({ -- 70
		Seq({ -- 71
			Con("enemy nearby", function() -- 71
				return (AI:getNearestUnit("Enemy") ~= nil) -- 71
			end), -- 71
			Sel({ -- 73
				Seq({ -- 74
					Con("not facing nearest enemy", function(self) -- 74
						do -- 75
							local unit = AI:getNearestUnit("Enemy") -- 75
							if unit then -- 75
								return (self.x > unit.x) == self.faceRight -- 76
							else -- 78
								return false -- 78
							end -- 75
						end -- 75
					end), -- 74
					Act("turn"), -- 79
					Reject() -- 80
				}), -- 73
				Seq({ -- 83
					Con("is falling", function(self) -- 83
						return not self.onSurface -- 83
					end), -- 83
					Act("fallOff") -- 84
				}), -- 82
				Seq({ -- 87
					Con("attackable", function(self) -- 87
						local units = AI:getUnitsInAttackRange() -- 88
						return units.count > 0 and units:each(function(unit) -- 89
							return (self.x <= unit.x) == self.faceRight -- 89
						end) -- 89
					end), -- 87
					Behave("attack", BT.Seq({ -- 91
						BT.Command("prepare"), -- 91
						BT.Wait(1), -- 92
						BT.Act("laser") -- 93
					})) -- 90
				}), -- 86
				Act("prepare") -- 96
			}) -- 72
		}), -- 70
		gotoExit, -- 99
		normalNPC -- 100
	}) -- 69
	Store["AI:Monster"] = Sel({ -- 104
		Seq({ -- 105
			Con("enemy dead", function(self) -- 105
				return self.entity.hp <= 0 -- 105
			end), -- 105
			Accept() -- 106
		}), -- 104
		Seq({ -- 109
			Con("enemy nearby", function() -- 109
				return (AI:getNearestUnit("Enemy") ~= nil) -- 109
			end), -- 109
			Sel({ -- 111
				Seq({ -- 112
					Con("not facing nearest enemy", function(self) -- 112
						do -- 113
							local unit = AI:getNearestUnit("Enemy") -- 113
							if unit then -- 113
								return (self.x > unit.x) == self.faceRight -- 114
							else -- 116
								return false -- 116
							end -- 113
						end -- 113
					end), -- 112
					Act("turn"), -- 117
					Reject() -- 118
				}), -- 111
				Seq({ -- 121
					Con("attackable", function(self) -- 121
						local units = AI:getUnitsInAttackRange() -- 122
						return units.count > 0 and units:each(function(unit) -- 123
							return (self.x <= unit.x) == self.faceRight -- 123
						end) -- 123
					end), -- 121
					Act("blow") -- 124
				}), -- 120
				Act("fmove") -- 126
			}) -- 110
		}), -- 108
		Act("idle") -- 129
	}) -- 103
	Store["AI:NiniliteFight"] = Store["AI:NPC"] -- 132
	local normalControl = Sel({ -- 135
		Seq({ -- 136
			Sel({ -- 137
				Seq({ -- 138
					Con("fmove key down", function(self) -- 138
						return not (self.entity.keyLeft and self.entity.keyRight) and ((self.entity.keyLeft and self.faceRight) or (self.entity.keyRight and not self.faceRight)) -- 143
					end), -- 138
					Act("turn") -- 144
				}), -- 137
				Seq({ -- 147
					Con("bmove key down", function(self) -- 147
						return not (self.entity.keyLeft or self.entity.keyRight) and not (self.entity.keyBLeft and self.entity.keyBRight) and ((self.entity.keyBLeft and not self.faceRight) or (self.entity.keyBRight and self.faceRight)) -- 153
					end), -- 147
					Act("turn") -- 154
				}) -- 146
			}), -- 136
			Reject() -- 157
		}), -- 135
		Seq({ -- 160
			Con("kinetic", function(self) -- 160
				return self.entity.keyShoot -- 160
			end), -- 160
			Act("kinetic") -- 161
		}), -- 159
		Seq({ -- 164
			Con("is falling", function(self) -- 164
				return not self.onSurface -- 164
			end), -- 164
			Act("fallOff") -- 165
		}), -- 163
		Seq({ -- 168
			Con("fmove key down", function(self) -- 168
				return self.entity.keyLeft or self.entity.keyRight -- 168
			end), -- 168
			Act("fmove") -- 169
		}), -- 167
		Seq({ -- 172
			Con("bmove key down", function(self) -- 172
				return self.entity.keyBLeft or self.entity.keyBRight -- 172
			end), -- 172
			Act("bmove") -- 173
		}), -- 171
		Act("idle") -- 175
	}) -- 134
	local battleControl = Sel({ -- 179
		Seq({ -- 180
			Con("kinetic", function(self) -- 180
				return self.entity.keyShoot -- 180
			end), -- 180
			Act("kinetic") -- 181
		}), -- 179
		Seq({ -- 184
			Con("is falling", function(self) -- 184
				return not self.onSurface -- 184
			end), -- 184
			Act("fallOff") -- 185
		}), -- 183
		Seq({ -- 188
			Con("not facing nearest enemy", function(self) -- 188
				do -- 189
					local unit = AI:getNearestUnit("Enemy") -- 189
					if unit then -- 189
						return (self.x > unit.x) == self.faceRight -- 190
					else -- 192
						return false -- 192
					end -- 189
				end -- 189
			end), -- 188
			Act("turn"), -- 193
			Reject() -- 194
		}), -- 187
		Seq({ -- 197
			Con("left key down", function(self) -- 197
				return self.entity.keyLeft -- 197
			end), -- 197
			Act(function(self) -- 198
				do -- 199
					local unit = AI:getNearestUnit("Enemy") -- 199
					if unit then -- 199
						return self.x > unit.x and "fmove" or "bmove" -- 200
					else -- 202
						return "" -- 202
					end -- 199
				end -- 199
			end) -- 198
		}), -- 196
		Seq({ -- 205
			Con("right key down", function(self) -- 205
				return self.entity.keyRight -- 205
			end), -- 205
			Act(function(self) -- 206
				do -- 207
					local unit = AI:getNearestUnit("Enemy") -- 207
					if unit then -- 207
						return self.x <= unit.x and "fmove" or "bmove" -- 208
					else -- 210
						return "" -- 210
					end -- 207
				end -- 207
			end) -- 206
		}), -- 204
		Act("prepare") -- 212
	}) -- 178
	Store["AI:PlayerControl"] = Sel({ -- 216
		Seq({ -- 217
			Con("enemy nearby", function() -- 217
				return (AI:getNearestUnit("Enemy") ~= nil) -- 217
			end), -- 217
			battleControl -- 218
		}), -- 216
		normalControl -- 220
	}) -- 215
end -- 6
return _module_0 -- 221
