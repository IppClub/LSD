-- [yue]: Script/Academy/Action.yue
local _module_0 = Dora.Platformer -- 1
local Data = _module_0.Data -- 1
local UnitAction = _module_0.UnitAction -- 1
local once = Dora.once -- 1
local sleep = Dora.sleep -- 1
local cycle = Dora.cycle -- 1
local math = _G.math -- 1
local coroutine = _G.coroutine -- 1
local Vec2 = Dora.Vec2 -- 1
local _module_0 = nil -- 1
local _anon_func_0 = function(_with_0) -- 130
	do -- 117
		local _val_0 = _with_0.lastCompleted -- 117
		return "melee" == _val_0 or "pistol" == _val_0 or "bow" == _val_0 or "gun1" == _val_0 or "gun2" == _val_0 or "gun3" == _val_0 or "throw" == _val_0 or "parry" == _val_0 or "defense" == _val_0 or "comp" == _val_0 or "comm" == _val_0 or "hit" == _val_0 -- 117
	end -- 130
end -- 117
_module_0 = function() -- 3
	local Store = Data.store -- 4
	UnitAction:add("fall", { -- 7
		priority = 10, -- 7
		reaction = 3, -- 8
		recovery = 0.1, -- 9
		queued = true, -- 10
		available = function() -- 11
			return true -- 11
		end, -- 11
		create = function(self) -- 12
			return once(function() -- 12
				local _with_0 = self.playable -- 12
				_with_0.speed = 1 -- 13
				sleep(_with_0:play("fall")) -- 14
				sleep(0.1) -- 15
				_with_0.recovery = 0 -- 16
				sleep(_with_0:play("standUp")) -- 17
				return _with_0 -- 12
			end) -- 17
		end -- 12
	}) -- 6
	UnitAction:add("evade", { -- 20
		priority = 10, -- 20
		reaction = 10, -- 21
		recovery = 0, -- 22
		queued = true, -- 23
		available = function() -- 24
			return true -- 24
		end, -- 24
		create = function(self) -- 25
			local time = 0 -- 26
			do -- 27
				local _with_0 = self.playable -- 27
				_with_0.speed = 1.0 -- 28
				time = _with_0:play("bstep") -- 29
			end -- 27
			return once(function(self) -- 30
				local dir = self.faceRight and -1 or 1 -- 31
				cycle(math.max(time, 0.4), function() -- 32
					self.velocityX = 800 * dir -- 32
				end) -- 32
				do -- 33
					local _with_0 = self.playable -- 33
					_with_0.recovery = 0.3 -- 34
					_with_0.speed = 1.0 -- 35
					_with_0:play("idle") -- 36
				end -- 33
				sleep(0.3) -- 37
				return true -- 38
			end) -- 38
		end -- 25
	}) -- 19
	UnitAction:add("rush", { -- 41
		priority = 10, -- 41
		reaction = 10, -- 42
		recovery = 0, -- 43
		queued = true, -- 44
		available = function() -- 45
			return true -- 45
		end, -- 45
		create = function(self) -- 46
			local time = 0 -- 47
			do -- 48
				local _with_0 = self.playable -- 48
				_with_0.speed = 1.0 -- 49
				time = _with_0:play("fstep") -- 50
			end -- 48
			return once(function(self) -- 51
				local dir = self.faceRight and 1 or -1 -- 52
				cycle(math.max(time, 0.4), function() -- 53
					self.velocityX = 800 * dir -- 53
				end) -- 53
				do -- 54
					local _with_0 = self.playable -- 54
					_with_0.recovery = 0.3 -- 55
					_with_0.speed = 1.0 -- 56
					_with_0:play("idle") -- 57
				end -- 54
				sleep(0.3) -- 58
				return true -- 59
			end) -- 59
		end -- 46
	}) -- 40
	UnitAction:add("hit", { -- 62
		priority = 99, -- 62
		reaction = 3, -- 63
		recovery = 0.2, -- 64
		queued = false, -- 65
		available = function() -- 66
			return true -- 66
		end, -- 66
		create = function(self) -- 67
			return once(function() -- 67
				local _with_0 = self.playable -- 68
				_with_0.speed = 1 -- 69
				sleep(_with_0:play("hit")) -- 70
				return _with_0 -- 68
			end) -- 70
		end -- 67
	}) -- 61
	UnitAction:add("pistol", { -- 73
		priority = 3, -- 73
		reaction = 3, -- 74
		recovery = 0.2, -- 75
		queued = true, -- 76
		available = function() -- 77
			return true -- 77
		end, -- 77
		create = function(self) -- 78
			return once(function() -- 78
				local _with_0 = self.playable -- 79
				_with_0.speed = 1 -- 80
				sleep(_with_0:play("pistol")) -- 81
				return _with_0 -- 79
			end) -- 81
		end -- 78
	}) -- 72
	UnitAction:add("test", { -- 84
		priority = 3, -- 84
		reaction = 3, -- 85
		recovery = 0.1, -- 86
		queued = true, -- 87
		available = function() -- 88
			return true -- 88
		end, -- 88
		create = function(self) -- 89
			return once(function() -- 89
				local _with_0 = self.playable -- 89
				_with_0.speed = 1 -- 90
				sleep(_with_0:play(Store.testAction)) -- 91
				return _with_0 -- 89
			end) -- 91
		end -- 89
	}) -- 83
	UnitAction:add("idle", { -- 94
		priority = 1, -- 94
		reaction = 2.0, -- 95
		recovery = 0.2, -- 96
		available = function(self) -- 97
			return self.onSurface -- 97
		end, -- 97
		create = function(self) -- 98
			local _with_0 = self.playable -- 98
			_with_0.speed = 1.0 -- 99
			_with_0:play("idle", true) -- 100
			local playIdleSpecial = coroutine.create(function() -- 101
				while true do -- 101
					sleep(3) -- 102
					sleep(_with_0:play("idle1")) -- 103
					_with_0:play("idle", true) -- 104
				end -- 104
			end) -- 101
			self.data.playIdleSpecial = playIdleSpecial -- 105
			do -- 106
				return function(self) -- 106
					coroutine.resume(playIdleSpecial) -- 107
					return not self.onSurface -- 108
				end -- 108
			end -- 108
		end -- 98
	}) -- 93
	UnitAction:add("prepare", { -- 111
		priority = 1, -- 111
		reaction = 2.0, -- 112
		recovery = 0.2, -- 113
		available = function(self) -- 114
			return self.onSurface -- 114
		end, -- 114
		create = function(self) -- 115
			local _with_0 = self.playable -- 115
			_with_0.speed = 1.0 -- 116
			if _anon_func_0(_with_0) then -- 117
				_with_0.recovery = 0.0 -- 131
			end -- 117
			_with_0:play("prepare", true) -- 132
			do -- 133
				return function(self) -- 133
					return not self.onSurface -- 133
				end -- 133
			end -- 133
		end -- 115
	}) -- 110
	UnitAction:add("fmove", { -- 136
		priority = 1, -- 136
		reaction = 2.0, -- 137
		recovery = 0.2, -- 138
		available = function(self) -- 139
			return self.onSurface -- 139
		end, -- 139
		create = function(self) -- 140
			do -- 141
				local _with_0 = self.playable -- 141
				_with_0.speed = 1 -- 142
				_with_0:play("fmove", true) -- 143
			end -- 141
			return function(self, action) -- 144
				local elapsedTime, recovery = action.elapsedTime, action.recovery -- 145
				local move = self.unitDef.move -- 146
				local moveSpeed -- 147
				if elapsedTime < recovery then -- 147
					moveSpeed = math.min(elapsedTime / recovery, 1.0) -- 148
				else -- 150
					moveSpeed = 1.0 -- 150
				end -- 147
				self.velocityX = moveSpeed * (self.faceRight and move or -move) -- 151
				return not self.onSurface -- 152
			end -- 152
		end -- 140
	}) -- 135
	UnitAction:add("keepIdle", { -- 155
		priority = 100, -- 155
		reaction = 2.0, -- 156
		recovery = 0.2, -- 157
		available = function() -- 158
			return true -- 158
		end, -- 158
		create = function(self) -- 159
			do -- 160
				local _with_0 = self.playable -- 160
				_with_0.speed = 1 -- 161
				_with_0:play("idle", true) -- 162
			end -- 160
			return function() -- 163
				return false -- 163
			end -- 163
		end -- 159
	}) -- 154
	UnitAction:add("idle1", { -- 166
		priority = 1, -- 166
		reaction = 2.0, -- 167
		recovery = 0.2, -- 168
		available = function() -- 169
			return true -- 169
		end, -- 169
		queued = true, -- 170
		create = function(self) -- 171
			return once(function() -- 171
				local _with_0 = self.playable -- 172
				_with_0.speed = 1 -- 173
				sleep(_with_0:play("idle1", false)) -- 174
				return _with_0 -- 172
			end) -- 174
		end -- 171
	}) -- 165
	UnitAction:add("keepMove", { -- 177
		priority = 100, -- 177
		reaction = 2.0, -- 178
		recovery = 0.2, -- 179
		available = function() -- 180
			return true -- 180
		end, -- 180
		create = function(self) -- 181
			do -- 182
				local _with_0 = self.playable -- 182
				_with_0.speed = 1 -- 183
				_with_0:play("fmove", true) -- 184
			end -- 182
			return function() -- 185
				return false -- 185
			end -- 185
		end -- 181
	}) -- 176
	UnitAction:add("bmove", { -- 188
		priority = 1, -- 188
		reaction = 2.0, -- 189
		recovery = 0.2, -- 190
		available = function(self) -- 191
			return self.onSurface -- 191
		end, -- 191
		create = function(self) -- 192
			do -- 193
				local _with_0 = self.playable -- 193
				_with_0.speed = 1 -- 194
				_with_0:play("bmove", true) -- 195
			end -- 193
			return function(self, action) -- 196
				local elapsedTime, recovery = action.elapsedTime, action.recovery -- 197
				local move = self.unitDef.move -- 198
				local moveSpeed -- 199
				if elapsedTime < recovery then -- 199
					moveSpeed = math.min(elapsedTime / recovery, 1.0) -- 200
				else -- 202
					moveSpeed = 1.0 -- 202
				end -- 199
				self.velocityX = moveSpeed * (self.faceRight and -move or move) * 0.5 -- 203
				return not self.onSurface -- 204
			end -- 204
		end -- 192
	}) -- 187
	UnitAction:add("jump", { -- 207
		priority = 3, -- 207
		reaction = 2.0, -- 208
		recovery = 0.1, -- 209
		queued = true, -- 210
		available = function(self) -- 211
			return self.onSurface -- 211
		end, -- 211
		create = function(self) -- 212
			local velocityX = self.velocityX -- 213
			local jump = self.unitDef.jump -- 214
			self.velocity = Vec2(velocityX, jump) -- 215
			return once(function(self) -- 216
				local _with_0 = self.playable -- 217
				_with_0.speed = 1 -- 218
				sleep(_with_0:play("jump", false)) -- 219
				return _with_0 -- 217
			end) -- 219
		end -- 212
	}) -- 206
	return UnitAction:add("fallOff", { -- 222
		priority = 2, -- 222
		reaction = -1, -- 223
		recovery = 0.3, -- 224
		available = function(self) -- 225
			return not self.onSurface -- 225
		end, -- 225
		create = function(self) -- 226
			if self.playable.current ~= "jumping" then -- 227
				local _with_0 = self.playable -- 228
				_with_0.speed = 1 -- 229
				_with_0:play("jumping", true) -- 230
			end -- 227
			return once(function(self) -- 231
				while true do -- 232
					if self.onSurface then -- 233
						do -- 234
							local _with_0 = self.playable -- 234
							_with_0.speed = 1 -- 235
							sleep(_with_0:play("landing", false)) -- 236
						end -- 234
						coroutine.yield(true) -- 237
					else -- 239
						coroutine.yield(false) -- 239
					end -- 233
				end -- 239
			end) -- 239
		end -- 226
	}) -- 239
end -- 3
return _module_0 -- 239
