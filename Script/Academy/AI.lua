-- [yue]: Script/Academy/AI.yue
local _module_0 = dora.Platformer -- 1
local Data = _module_0.Data -- 1
local _module_1 = dora.Platformer.Decision -- 1
local Sel = _module_1.Sel -- 1
local Seq = _module_1.Seq -- 1
local Con = _module_1.Con -- 1
local AI = _module_1.AI -- 1
local math = _G.math -- 1
local Act = _module_1.Act -- 1
local Reject = _module_1.Reject -- 1
local _module_0 = nil -- 1
_module_0 = function() -- 6
	local Store = Data.store -- 7
	Store["AI:NPC"] = Sel({ -- 10
		Seq({ -- 11
			Con("not facing nearest player", function(self) -- 11
				local _list_0 = AI:getDetectedUnits() -- 12
				for _index_0 = 1, #_list_0 do -- 12
					local unit = _list_0[_index_0] -- 12
					if unit.entity.player then -- 13
						return math.abs(self.x - unit.x) <= 200 and (self.x > unit.x) == self.faceRight -- 14
					end -- 13
				end -- 14
				do -- 15
					local unit = AI:getNearestUnit("Any") -- 15
					if unit then -- 15
						return math.abs(self.x - unit.x) <= 200 and (self.x > unit.x) == self.faceRight -- 16
					else -- 18
						return false -- 18
					end -- 15
				end -- 15
			end), -- 11
			Act("turn") -- 19
		}), -- 10
		Act("idle") -- 21
	}) -- 9
	Store["AI:PlayerControl"] = Sel({ -- 25
		Seq({ -- 26
			Sel({ -- 27
				Seq({ -- 28
					Con("fmove key down", function(self) -- 28
						return not (self.entity.keyLeft and self.entity.keyRight) and ((self.entity.keyLeft and self.faceRight) or (self.entity.keyRight and not self.faceRight)) -- 33
					end), -- 28
					Act("turn") -- 34
				}), -- 27
				Seq({ -- 37
					Con("bmove key down", function(self) -- 37
						return not (self.entity.keyLeft or self.entity.keyRight) and not (self.entity.keyBLeft and self.entity.keyBRight) and ((self.entity.keyBLeft and not self.faceRight) or (self.entity.keyBRight and self.faceRight)) -- 43
					end), -- 37
					Act("turn") -- 44
				}) -- 36
			}), -- 26
			Reject() -- 47
		}), -- 25
		Seq({ -- 50
			Con("is falling", function(self) -- 50
				return not self.onSurface -- 50
			end), -- 50
			Act("fallOff") -- 51
		}), -- 49
		Seq({ -- 54
			Con("fmove key down", function(self) -- 54
				return self.entity.keyLeft or self.entity.keyRight -- 54
			end), -- 54
			Act("fmove") -- 55
		}), -- 53
		Act("idle") -- 57
	}) -- 24
end -- 6
return _module_0 -- 58
