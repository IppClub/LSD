-- [yue]: Script/Unit/HeroUnit.yue
local _module_0 = dora.Platformer -- 1
local Data = _module_0.Data -- 1
local Dictionary = dora.Dictionary -- 1
local Vec2 = dora.Vec2 -- 1
local Size = dora.Size -- 1
local TargetAllow = _module_0.TargetAllow -- 1
local Array = dora.Array -- 1
local Store = Data.store -- 2
do -- 7
	local _with_0 = Dictionary() -- 7
	_with_0.linearAcceleration = Vec2(0, -15) -- 8
	_with_0.bodyType = "Dynamic" -- 9
	_with_0.scale = 1.0 -- 10
	_with_0.density = 1.0 -- 11
	_with_0.friction = 1.0 -- 12
	_with_0.restitution = 0.0 -- 13
	_with_0.playable = "spine:charF" -- 14
	_with_0.defaultFaceRight = true -- 15
	_with_0.size = Size(100, 300) -- 16
	_with_0.sensity = 0 -- 17
	_with_0.move = 400 -- 18
	_with_0.jump = 1200 -- 19
	_with_0.detectDistance = 350 -- 20
	_with_0.tag = "player" -- 21
	_with_0.hp = 100.0 -- 23
	_with_0.decisionTree = "AI:PlayerControl" -- 24
	_with_0.usePreciseHit = false -- 25
	_with_0.attackDelay = 0.08 -- 26
	_with_0.attackSpeed = 1.2 -- 27
	_with_0.attackRange = Size(260 + 84 / 2, 250) -- 28
	_with_0.attackEffectDelay = 0.10 -- 29
	_with_0.attackPower = Vec2(100, 100) -- 30
	_with_0.attackTarget = "Single" -- 31
	do -- 32
		local config -- 33
		do -- 33
			local _with_1 = TargetAllow() -- 33
			_with_1.terrainAllowed = true -- 34
			_with_1:allow("Enemy", true) -- 35
			config = _with_1 -- 33
		end -- 33
		_with_0.targetAllow = config:toValue() -- 36
	end -- 36
	_with_0.damageType = 0 -- 37
	_with_0.defenceType = 0 -- 38
	_with_0.bulletType = "Bullet_1" -- 39
	_with_0.attackEffect = "" -- 40
	_with_0.hitEffect = "Particle/bloodp.par" -- 41
	_with_0.sndAttack = "" -- 42
	_with_0.sndFallen = "" -- 43
	_with_0.actions = Array({ -- 45
		"idle", -- 45
		"turn", -- 46
		"fallOff", -- 47
		"test", -- 48
		"cancel", -- 49
		"keepIdle", -- 50
		"keepMove", -- 51
		"idle1", -- 52
		"rush", -- 53
		"evade", -- 54
		"jump", -- 55
		"fall", -- 56
		"fmove", -- 57
		"bmove", -- 58
		"hit", -- 59
		"pistol", -- 60
		"melee" -- 61
	}) -- 44
	Store["charF"] = _with_0 -- 7
end -- 7
do -- 64
	local _with_0 = Dictionary() -- 64
	_with_0.linearAcceleration = Vec2(0, -15) -- 65
	_with_0.bodyType = "Dynamic" -- 66
	_with_0.scale = 1.0 -- 67
	_with_0.density = 1.0 -- 68
	_with_0.friction = 1.0 -- 69
	_with_0.restitution = 0.0 -- 70
	_with_0.playable = "spine:charM" -- 71
	_with_0.defaultFaceRight = true -- 72
	_with_0.size = Size(100, 300) -- 73
	_with_0.sensity = 0 -- 74
	_with_0.move = 300 -- 75
	_with_0.jump = 1200 -- 76
	_with_0.detectDistance = 350 -- 77
	_with_0.tag = "player" -- 78
	_with_0.hp = 5.0 -- 80
	_with_0.decisionTree = "AI:NPC" -- 81
	_with_0.usePreciseHit = false -- 82
	_with_0.attackDelay = 0.4 -- 83
	_with_0.attackEffectDelay = 0.1 -- 84
	_with_0.attackPower = Vec2(100, 100) -- 85
	_with_0.attackTarget = "Single" -- 86
	do -- 87
		local config -- 88
		do -- 88
			local _with_1 = TargetAllow() -- 88
			_with_1.terrainAllowed = true -- 89
			_with_1:allow("Enemy", true) -- 90
			config = _with_1 -- 88
		end -- 88
		_with_0.targetAllow = config:toValue() -- 91
	end -- 91
	_with_0.damageType = 0 -- 92
	_with_0.defenceType = 0 -- 93
	_with_0.bulletType = "Bullet_1" -- 94
	_with_0.attackEffect = "" -- 95
	_with_0.hitEffect = "" -- 96
	_with_0.sndAttack = "" -- 97
	_with_0.sndFallen = "" -- 98
	_with_0.actions = Array({ -- 100
		"idle", -- 100
		"turn", -- 101
		"fallOff", -- 102
		"test", -- 103
		"cancel", -- 104
		"keepIdle", -- 105
		"keepMove", -- 106
		"idle1", -- 107
		"rush", -- 108
		"evade", -- 109
		"jump", -- 110
		"pistol", -- 111
		"fall", -- 112
		"fmove", -- 113
		"bmove" -- 114
	}) -- 99
	Store["charM"] = _with_0 -- 64
end -- 64
local _with_0 = Dictionary() -- 117
_with_0.linearAcceleration = Vec2(0, -15) -- 118
_with_0.bodyType = "Dynamic" -- 119
_with_0.scale = 1.0 -- 120
_with_0.density = 1.0 -- 121
_with_0.friction = 1.0 -- 122
_with_0.restitution = 0.0 -- 123
_with_0.playable = "spine:villywan" -- 124
_with_0.defaultFaceRight = true -- 125
_with_0.size = Size(100, 300) -- 126
_with_0.sensity = 0 -- 127
_with_0.move = 300 -- 128
_with_0.jump = 1200 -- 129
_with_0.detectDistance = 350 -- 130
_with_0.tag = "player" -- 131
_with_0.hp = 5.0 -- 133
_with_0.decisionTree = "AI:NPC" -- 134
_with_0.usePreciseHit = false -- 135
_with_0.attackDelay = 0.4 -- 136
_with_0.attackEffectDelay = 0.1 -- 137
_with_0.attackPower = Vec2(100, 100) -- 138
_with_0.attackTarget = "Single" -- 139
do -- 140
	local config -- 141
	do -- 141
		local _with_1 = TargetAllow() -- 141
		_with_1.terrainAllowed = true -- 142
		_with_1:allow("Enemy", true) -- 143
		config = _with_1 -- 141
	end -- 141
	_with_0.targetAllow = config:toValue() -- 144
end -- 144
_with_0.damageType = 0 -- 145
_with_0.defenceType = 0 -- 146
_with_0.bulletType = "Bullet_1" -- 147
_with_0.attackEffect = "" -- 148
_with_0.hitEffect = "" -- 149
_with_0.sndAttack = "" -- 150
_with_0.sndFallen = "" -- 151
_with_0.actions = Array({ -- 153
	"idle", -- 153
	"turn", -- 154
	"fallOff", -- 155
	"test", -- 156
	"cancel", -- 157
	"keepIdle", -- 158
	"keepMove", -- 159
	"idle1", -- 160
	"rush", -- 161
	"evade", -- 162
	"jump", -- 163
	"pistol", -- 164
	"fall", -- 165
	"fmove", -- 166
	"bmove" -- 167
}) -- 152
Store["villywan"] = _with_0 -- 117
