-- [yue]: Script/Academy/Map.yue
local _module_0 = { } -- 1
local Data = require("Platformer").Data -- 1
local DB = require("Dora").DB -- 2
local routes = { -- 6
	LoopTowerInitial = { -- 7
		name = "开场螺旋塔", -- 7
		right = { -- 9
			name = "右边门", -- 9
			enter = "left", -- 10
			targets = { -- 11
				"PreparationRoom" -- 11
			} -- 11
		} -- 8
	}, -- 6
	PreparationRoom = { -- 14
		name = "备战室", -- 14
		left = { -- 16
			name = "左边门", -- 16
			enter = "right", -- 17
			targets = { -- 18
				"PassageA" -- 18
			} -- 18
		}, -- 15
		right = { -- 20
			name = "右边门", -- 20
			enter = "left", -- 21
			targets = { -- 22
				"PassageB" -- 22
			} -- 22
		} -- 19
	}, -- 13
	OperationRoom = { -- 25
		name = "指挥室", -- 25
		left = { -- 27
			name = "左边门", -- 27
			enter = "right", -- 28
			targets = { -- 29
				"PassageC" -- 29
			} -- 29
		}, -- 26
		right = { -- 31
			name = "右边门", -- 31
			enter = "left", -- 32
			targets = { } -- 33
		} -- 30
	}, -- 24
	RDRoom = { -- 36
		name = "研发室", -- 36
		left = { -- 38
			name = "左边门", -- 38
			enter = "right", -- 39
			targets = { -- 40
				"PassageD" -- 40
			} -- 40
		}, -- 37
		right = { -- 42
			name = "右边门", -- 42
			enter = "", -- 43
			targets = { } -- 44
		} -- 41
	}, -- 35
	RestRoom = { -- 47
		name = "休息室", -- 47
		left = { -- 49
			name = "左边门", -- 49
			enter = "", -- 50
			targets = { } -- 51
		}, -- 48
		right = { -- 53
			name = "右边门", -- 53
			enter = "left", -- 54
			targets = { -- 55
				"PassageA" -- 55
			} -- 55
		} -- 52
	}, -- 46
	TrainingRoom = { -- 58
		name = "训练室", -- 58
		left = { -- 60
			name = "左边门", -- 60
			enter = "right", -- 61
			targets = { -- 62
				"PassageB" -- 62
			} -- 62
		}, -- 59
		right = { -- 64
			name = "右边门", -- 64
			enter = "", -- 65
			targets = { } -- 66
		} -- 63
	}, -- 57
	PassageA = { -- 69
		name = "A区走廊", -- 69
		left = { -- 71
			name = "左边门", -- 71
			enter = "right", -- 72
			targets = { -- 73
				"RestRoom" -- 73
			} -- 73
		}, -- 70
		right = { -- 75
			name = "右边门", -- 75
			enter = "left", -- 76
			targets = { -- 77
				"PreparationRoom" -- 77
			} -- 77
		}, -- 74
		center = { -- 79
			name = "电梯", -- 79
			enter = "center", -- 80
			targets = { -- 81
				"PassageC" -- 81
			} -- 81
		} -- 78
	}, -- 68
	PassageB = { -- 84
		name = "B区走廊", -- 84
		left = { -- 86
			name = "左边门", -- 86
			enter = "right", -- 87
			targets = { -- 88
				"PreparationRoom" -- 88
			} -- 88
		}, -- 85
		right = { -- 90
			name = "右边门", -- 90
			enter = "left", -- 91
			targets = { -- 92
				"TrainingRoom" -- 92
			} -- 92
		}, -- 89
		center = { -- 94
			name = "电梯", -- 94
			enter = "center", -- 95
			targets = { -- 96
				"PassageA", -- 96
				"PassageC" -- 96
			} -- 96
		} -- 93
	}, -- 83
	PassageC = { -- 99
		name = "C区走廊", -- 99
		left = { -- 101
			name = "站台通道", -- 101
			enter = "right", -- 102
			targets = { -- 103
				"Station" -- 103
			} -- 103
		}, -- 100
		right = { -- 105
			name = "右边门", -- 105
			enter = "left", -- 106
			targets = { -- 107
				"OperationRoom" -- 107
			} -- 107
		}, -- 104
		center = { -- 109
			name = "电梯", -- 109
			enter = "center", -- 110
			targets = { -- 111
				"PassageA", -- 111
				"PassageD" -- 111
			} -- 111
		} -- 108
	}, -- 98
	PassageD = { -- 114
		name = "D区走廊", -- 114
		left = { -- 116
			name = "左边门", -- 116
			enter = "right", -- 117
			targets = { -- 118
				"LibraryRoom" -- 118
			} -- 118
		}, -- 115
		right = { -- 120
			name = "右边门", -- 120
			enter = "left", -- 121
			targets = { -- 122
				"RDRoom" -- 122
			} -- 122
		}, -- 119
		center = { -- 124
			name = "电梯", -- 124
			enter = "center", -- 125
			targets = { -- 126
				"PassageC" -- 126
			} -- 126
		} -- 123
	}, -- 113
	LibraryRoom = { -- 129
		name = "资料室", -- 129
		left = { -- 131
			name = "左边门", -- 131
			enter = "", -- 132
			targets = { } -- 133
		}, -- 130
		right = { -- 135
			name = "右边门", -- 135
			enter = "left", -- 136
			targets = { -- 137
				"PassageD" -- 137
			} -- 137
		} -- 134
	}, -- 128
	Station = { -- 140
		name = "地铁站台", -- 140
		right = { -- 142
			name = "学院通道", -- 142
			enter = "left", -- 143
			targets = { -- 144
				"PassageC" -- 144
			} -- 144
		} -- 141
	} -- 139
} -- 5
local states = { -- 147
	{ -- 147
		PreparationRoom = true, -- 147
		PassageA = true, -- 148
		RestRoom = true -- 149
	}, -- 147
	{ -- 151
		PassageB = true, -- 151
		TrainingRoom = true -- 152
	}, -- 151
	{ -- 154
		PassageC = true, -- 154
		OperationRoom = true -- 155
	}, -- 154
	{ -- 157
		PassageD = true, -- 157
		RDRoom = true, -- 158
		LibraryRoom = true, -- 159
		Station = true -- 160
	} -- 157
} -- 146
local isAvailable -- 162
isAvailable = function(name) -- 162
	if name == "Station" then -- 163
		if not (DB:existDB("lsd") and DB:exist("Game0StoryUnlocks", "lsd")) then -- 164
			return false -- 164
		end -- 164
		local rows = DB:query("SELECT id FROM lsd.Game0StoryUnlocks WHERE id='archive-discovered'") -- 165
		if not (rows and #rows > 0) then -- 166
			return false -- 166
		end -- 166
	end -- 163
	local level -- 167
	do -- 167
		local _exp_0 = Data.store.academyLevel -- 167
		if _exp_0 ~= nil then -- 167
			level = _exp_0 -- 167
		else -- 167
			level = #states -- 167
		end -- 167
	end -- 167
	for i = 1, level do -- 168
		if states[i][name] then -- 169
			return true -- 170
		end -- 169
	end -- 168
	return false -- 171
end -- 162
local getRoute -- 173
getRoute = function(name, route) -- 173
	do -- 174
		local _des_0 -- 174
		do -- 174
			local _obj_0 = routes[name] -- 174
			if _obj_0 ~= nil then -- 174
				_des_0 = _obj_0[route] -- 174
			end -- 174
		end -- 174
		if _des_0 then -- 174
			local enter, targets -- 174
			name, enter, targets = _des_0.name, _des_0.enter, _des_0.targets -- 174
			do -- 175
				local _accum_0 = { } -- 175
				local _len_0 = 1 -- 175
				for _index_0 = 1, #targets do -- 175
					local target = targets[_index_0] -- 175
					if isAvailable(target) then -- 175
						_accum_0[_len_0] = target -- 175
						_len_0 = _len_0 + 1 -- 175
					end -- 175
				end -- 175
				targets = _accum_0 -- 175
			end -- 175
			return name, enter, targets -- 176
		end -- 174
	end -- 174
	return nil, nil, nil -- 177
end -- 173
_module_0["getRoute"] = getRoute -- 173
local getName -- 179
getName = function(nameEN) -- 179
	local _obj_0 = routes[nameEN] -- 179
	if _obj_0 ~= nil then -- 179
		return _obj_0.name -- 179
	end -- 179
	return nil -- 179
end -- 179
_module_0["getName"] = getName -- 179
return _module_0 -- 1
