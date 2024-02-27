-- [yue]: Script/Academy/Map.yue
local _module_0 = { } -- 1
local Data = require("Platformer").Data -- 1
local routes = { -- 4
	LoopTowerInitial = { -- 5
		name = "开场螺旋塔", -- 5
		right = { -- 7
			name = "右边门", -- 7
			enter = "left", -- 8
			targets = { -- 9
				"PreparationRoom" -- 9
			} -- 9
		} -- 6
	}, -- 4
	PreparationRoom = { -- 12
		name = "备战室", -- 12
		left = { -- 14
			name = "左边门", -- 14
			enter = "right", -- 15
			targets = { -- 16
				"PassageA" -- 16
			} -- 16
		}, -- 13
		right = { -- 18
			name = "右边门", -- 18
			enter = "left", -- 19
			targets = { -- 20
				"PassageB" -- 20
			} -- 20
		} -- 17
	}, -- 11
	OperationRoom = { -- 23
		name = "指挥室", -- 23
		left = { -- 25
			name = "左边门", -- 25
			enter = "right", -- 26
			targets = { -- 27
				"PassageC" -- 27
			} -- 27
		}, -- 24
		right = { -- 29
			name = "右边门", -- 29
			enter = "left", -- 30
			targets = { } -- 31
		} -- 28
	}, -- 22
	RDRoom = { -- 34
		name = "研发室", -- 34
		left = { -- 36
			name = "左边门", -- 36
			enter = "right", -- 37
			targets = { -- 38
				"PassageD" -- 38
			} -- 38
		}, -- 35
		right = { -- 40
			name = "右边门", -- 40
			enter = "", -- 41
			targets = { } -- 42
		} -- 39
	}, -- 33
	RestRoom = { -- 45
		name = "休息室", -- 45
		left = { -- 47
			name = "左边门", -- 47
			enter = "", -- 48
			targets = { } -- 49
		}, -- 46
		right = { -- 51
			name = "右边门", -- 51
			enter = "left", -- 52
			targets = { -- 53
				"PassageA" -- 53
			} -- 53
		} -- 50
	}, -- 44
	TrainingRoom = { -- 56
		name = "训练室", -- 56
		left = { -- 58
			name = "左边门", -- 58
			enter = "right", -- 59
			targets = { -- 60
				"PassageB" -- 60
			} -- 60
		}, -- 57
		right = { -- 62
			name = "右边门", -- 62
			enter = "", -- 63
			targets = { } -- 64
		} -- 61
	}, -- 55
	PassageA = { -- 67
		name = "A区走廊", -- 67
		left = { -- 69
			name = "左边门", -- 69
			enter = "right", -- 70
			targets = { -- 71
				"RestRoom" -- 71
			} -- 71
		}, -- 68
		right = { -- 73
			name = "右边门", -- 73
			enter = "left", -- 74
			targets = { -- 75
				"PreparationRoom" -- 75
			} -- 75
		}, -- 72
		center = { -- 77
			name = "电梯", -- 77
			enter = "center", -- 78
			targets = { -- 79
				"PassageC" -- 79
			} -- 79
		} -- 76
	}, -- 66
	PassageB = { -- 82
		name = "B区走廊", -- 82
		left = { -- 84
			name = "左边门", -- 84
			enter = "right", -- 85
			targets = { -- 86
				"PreparationRoom" -- 86
			} -- 86
		}, -- 83
		right = { -- 88
			name = "右边门", -- 88
			enter = "left", -- 89
			targets = { -- 90
				"TrainingRoom" -- 90
			} -- 90
		}, -- 87
		center = { -- 92
			name = "电梯", -- 92
			enter = "center", -- 93
			targets = { -- 94
				"PassageA", -- 94
				"PassageC" -- 94
			} -- 94
		} -- 91
	}, -- 81
	PassageC = { -- 97
		name = "C区走廊", -- 97
		left = { -- 99
			name = "左边门", -- 99
			enter = "", -- 100
			targets = { } -- 101
		}, -- 98
		right = { -- 103
			name = "右边门", -- 103
			enter = "left", -- 104
			targets = { -- 105
				"OperationRoom" -- 105
			} -- 105
		}, -- 102
		center = { -- 107
			name = "电梯", -- 107
			enter = "center", -- 108
			targets = { -- 109
				"PassageA", -- 109
				"PassageD" -- 109
			} -- 109
		} -- 106
	}, -- 96
	PassageD = { -- 112
		name = "D区走廊", -- 112
		left = { -- 114
			name = "左边门", -- 114
			enter = "", -- 115
			targets = { } -- 116
		}, -- 113
		right = { -- 118
			name = "右边门", -- 118
			enter = "left", -- 119
			targets = { -- 120
				"RDRoom" -- 120
			} -- 120
		}, -- 117
		center = { -- 122
			name = "电梯", -- 122
			enter = "center", -- 123
			targets = { -- 124
				"PassageC" -- 124
			} -- 124
		} -- 121
	} -- 111
} -- 3
local states = { -- 127
	{ -- 127
		PreparationRoom = true, -- 127
		PassageA = true, -- 128
		RestRoom = true -- 129
	}, -- 127
	{ -- 131
		PassageB = true, -- 131
		TrainingRoom = true -- 132
	}, -- 131
	{ -- 134
		PassageC = true, -- 134
		OperationRoom = true -- 135
	}, -- 134
	{ -- 137
		PassageD = true, -- 137
		RDRoom = true -- 138
	} -- 137
} -- 126
local isAvailable -- 140
isAvailable = function(name) -- 140
	local level -- 141
	do -- 141
		local _exp_0 = Data.store.academyLevel -- 141
		if _exp_0 ~= nil then -- 141
			level = _exp_0 -- 141
		else -- 141
			level = #states -- 141
		end -- 141
	end -- 141
	for i = 1, level do -- 142
		if states[i][name] then -- 143
			return true -- 144
		end -- 143
	end -- 144
	return false -- 145
end -- 140
local getRoute -- 147
getRoute = function(name, route) -- 147
	do -- 148
		local _des_0 -- 148
		do -- 148
			local _obj_0 = routes[name] -- 148
			if _obj_0 ~= nil then -- 148
				_des_0 = _obj_0[route] -- 148
			end -- 148
		end -- 148
		if _des_0 then -- 148
			local enter, targets -- 148
			name, enter, targets = _des_0.name, _des_0.enter, _des_0.targets -- 148
			do -- 149
				local _accum_0 = { } -- 149
				local _len_0 = 1 -- 149
				for _index_0 = 1, #targets do -- 149
					local target = targets[_index_0] -- 149
					if isAvailable(target) then -- 149
						_accum_0[_len_0] = target -- 149
						_len_0 = _len_0 + 1 -- 149
					end -- 149
				end -- 149
				targets = _accum_0 -- 149
			end -- 149
			return name, enter, targets -- 150
		end -- 148
	end -- 148
	return nil, nil, nil -- 151
end -- 147
_module_0["getRoute"] = getRoute -- 151
local getName -- 153
getName = function(nameEN) -- 153
	local _obj_0 = routes[nameEN] -- 153
	if _obj_0 ~= nil then -- 153
		return _obj_0.name -- 153
	end -- 153
	return nil -- 153
end -- 153
_module_0["getName"] = getName -- 153
return _module_0 -- 153
