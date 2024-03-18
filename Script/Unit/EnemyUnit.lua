-- [yue]: Script/Unit/EnemyUnit.yue
local _module_0 = dora.Platformer -- 1
local Data = _module_0.Data -- 1
local Dictionary = dora.Dictionary -- 1
local Vec2 = dora.Vec2 -- 1
local Size = dora.Size -- 1
local TargetAllow = _module_0.TargetAllow -- 1
local Array = dora.Array -- 1
local Store = Data.store -- 2
do -- 4
	local _with_0 = Dictionary() -- 4
	_with_0.linearAcceleration = Vec2(0, -15) -- 5
	_with_0.bodyType = "Dynamic" -- 6
	_with_0.scale = 1.0 -- 7
	_with_0.density = 1.0 -- 8
	_with_0.friction = 1.0 -- 9
	_with_0.restitution = 0.0 -- 10
	_with_0.playable = "spine:xiaotaotie" -- 11
	_with_0.defaultFaceRight = true -- 12
	_with_0.size = Size(100, 300) -- 13
	_with_0.sensity = 0.5 -- 14
	_with_0.move = 300 -- 15
	_with_0.jump = 800 -- 16
	_with_0.detectDistance = 1200 -- 17
	_with_0.hp = 3.0 -- 18
	_with_0.decisionTree = "AI:XIAOTAOTIE" -- 19
	_with_0.usePreciseHit = false -- 20
	_with_0.attackDelay = 0.5 -- 21
	_with_0.attackSpeed = 1 -- 22
	_with_0.attackRange = Size(260 + 84 / 2, 250) -- 23
	_with_0.attackEffectDelay = 0.08 -- 24
	_with_0.attackPower = Vec2(100, 100) -- 25
	_with_0.attackTarget = "Single" -- 26
	do -- 27
		local config -- 28
		do -- 28
			local _with_1 = TargetAllow() -- 28
			_with_1.terrainAllowed = true -- 29
			_with_1:allow("Enemy", true) -- 30
			config = _with_1 -- 28
		end -- 28
		_with_0.targetAllow = config:toValue() -- 31
	end -- 31
	_with_0.actions = Array({ -- 33
		"idle", -- 33
		"turn", -- 34
		"fmove", -- 35
		"jump", -- 36
		"fallOff", -- 37
		"cancel", -- 38
		"keepIdle", -- 39
		"keepMove", -- 40
		"idle1", -- 41
		"hit", -- 42
		"lose", -- 43
		"bomb", -- 44
		"dizzy1", -- 45
		"dizzy", -- 46
		"swing", -- 47
		"butt", -- 48
		"roll", -- 49
		"rollStart", -- 50
		"rollEnd", -- 51
		"blow" -- 52
	}) -- 32
	Store["xiaotaotie"] = _with_0 -- 4
end -- 4
do -- 55
	local _with_0 = Dictionary() -- 55
	_with_0.linearAcceleration = Vec2(0, -15) -- 56
	_with_0.bodyType = "Dynamic" -- 57
	_with_0.scale = 1.0 -- 58
	_with_0.density = 1.0 -- 59
	_with_0.friction = 1.0 -- 60
	_with_0.restitution = 0.0 -- 61
	_with_0.playable = "spine:dataotie" -- 62
	_with_0.defaultFaceRight = false -- 63
	_with_0.size = Size(450, 450) -- 64
	_with_0.sensity = 0.5 -- 65
	_with_0.move = 300 -- 66
	_with_0.jump = 800 -- 67
	_with_0.detectDistance = 1200 -- 68
	_with_0.hp = 5.0 -- 69
	_with_0.decisionTree = "AI:DATAOTIE" -- 70
	_with_0.usePreciseHit = false -- 71
	_with_0.attackDelay = 0.5 -- 72
	_with_0.attackSpeed = 1 -- 73
	_with_0.attackRange = Size(260 + 84 / 2, 500) -- 74
	_with_0.attackEffectDelay = 0.08 -- 75
	_with_0.actions = Array({ -- 77
		"idle", -- 77
		"turn", -- 78
		"fmove", -- 79
		"jump", -- 80
		"fallOff", -- 81
		"cancel", -- 82
		"keepIdle", -- 83
		"keepMove", -- 84
		"idle1", -- 85
		"hit", -- 86
		"lose", -- 87
		"trample", -- 88
		"rush2", -- 89
		"shot", -- 90
		"rush3", -- 91
		"dizzy1", -- 92
		"dizzy2", -- 93
		"swing", -- 94
		"pounce", -- 95
		"rush", -- 96
		"fmove1", -- 97
		"dtdRush1" -- 98
	}) -- 76
	Store["dataotie"] = _with_0 -- 55
end -- 55
