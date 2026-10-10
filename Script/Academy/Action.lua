local _module_0 = nil
local _ENV = Dora(Dora.Platformer)
local Data <const> = Data
local UnitAction <const> = UnitAction
local once <const> = once
local sleep <const> = sleep
local cycle <const> = cycle
local math <const> = math
local coroutine <const> = coroutine
local Vec2 <const> = Vec2
local _anon_func_0 = function(_with_0)
	local _val_0 = _with_0.lastCompleted
	return "melee" == _val_0 or "pistol" == _val_0 or "bow" == _val_0 or "gun1" == _val_0 or "gun2" == _val_0 or "gun3" == _val_0 or "throw" == _val_0 or "parry" == _val_0 or "defense" == _val_0 or "comp" == _val_0 or "comm" == _val_0 or "hit" == _val_0
end
_module_0 = function()
	local Store = Data.store
	UnitAction:add("fall", {
		priority = 10,
		reaction = 3,
		recovery = 0.1,
		queued = true,
		available = function()
			return true
		end,
		create = function(self)
			return once(function()
				local _with_0 = self.playable
				_with_0.speed = 1
				sleep(_with_0:play("fall"))
				sleep(0.1)
				_with_0.recovery = 0
				sleep(_with_0:play("standUp"))
				return _with_0
			end)
		end
	})
	UnitAction:add("evade", {
		priority = 10,
		reaction = 10,
		recovery = 0,
		queued = true,
		available = function()
			return true
		end,
		create = function(self)
			local time = 0
			do
				local _with_0 = self.playable
				_with_0.speed = 1.0
				time = _with_0:play("bstep")
			end
			return once(function(self)
				local dir = self.faceRight and -1 or 1
				cycle(math.max(time, 0.4), function()
					self.velocityX = 800 * dir
				end)
				do
					local _with_0 = self.playable
					_with_0.recovery = 0.3
					_with_0.speed = 1.0
					_with_0:play("idle")
				end
				sleep(0.3)
				return true
			end)
		end
	})
	UnitAction:add("rush", {
		priority = 10,
		reaction = 10,
		recovery = 0,
		queued = true,
		available = function()
			return true
		end,
		create = function(self)
			local time = 0
			do
				local _with_0 = self.playable
				_with_0.speed = 1.0
				time = _with_0:play("fstep")
			end
			return once(function(self)
				local dir = self.faceRight and 1 or -1
				cycle(math.max(time, 0.4), function()
					self.velocityX = 800 * dir
				end)
				do
					local _with_0 = self.playable
					_with_0.recovery = 0.3
					_with_0.speed = 1.0
					_with_0:play("idle")
				end
				sleep(0.3)
				return true
			end)
		end
	})
	UnitAction:add("hit", {
		priority = 99,
		reaction = 3,
		recovery = 0.2,
		queued = false,
		available = function()
			return true
		end,
		create = function(self)
			return once(function()
				local _with_0 = self.playable
				_with_0.speed = 1
				sleep(_with_0:play("hit"))
				return _with_0
			end)
		end
	})
	UnitAction:add("pistol", {
		priority = 3,
		reaction = 3,
		recovery = 0.2,
		queued = true,
		available = function()
			return true
		end,
		create = function(self)
			return once(function()
				local _with_0 = self.playable
				_with_0.speed = 1
				sleep(_with_0:play("pistol"))
				return _with_0
			end)
		end
	})
	UnitAction:add("test", {
		priority = 3,
		reaction = 3,
		recovery = 0.1,
		queued = true,
		available = function()
			return true
		end,
		create = function(self)
			return once(function()
				local _with_0 = self.playable
				_with_0.speed = 1
				sleep(_with_0:play(Store.testAction))
				return _with_0
			end)
		end
	})
	UnitAction:add("idle", {
		priority = 1,
		reaction = 2.0,
		recovery = 0.2,
		available = function(self)
			return self.onSurface
		end,
		create = function(self)
			self.velocityX = 0
			local _with_0 = self.playable
			_with_0.speed = 1.0
			_with_0:play("idle", true)
			local playIdleSpecial = coroutine.create(function()
				while true do
					sleep(3)
					sleep(_with_0:play("idle1"))
					_with_0:play("idle", true)
				end
			end)
			self.data.playIdleSpecial = playIdleSpecial
			return function(self)
				coroutine.resume(playIdleSpecial)
				return not self.onSurface
			end
		end
	})
	UnitAction:add("prepare", {
		priority = 1,
		reaction = 2.0,
		recovery = 0.2,
		available = function(self)
			return self.onSurface
		end,
		create = function(self)
			local _with_0 = self.playable
			_with_0.speed = 1.0
			if _anon_func_0(_with_0) then
				_with_0.recovery = 0.0
			end
			_with_0:play("prepare", true)
			return function(self)
				return not self.onSurface
			end
		end
	})
	UnitAction:add("fmove", {
		priority = 1,
		reaction = 2.0,
		recovery = 0.2,
		available = function(self)
			return self.onSurface
		end,
		create = function(self)
			local move = self.unitDef.move
			self.velocityX = (self.faceRight and move or -move)
			do
				local _with_0 = self.playable
				_with_0.speed = 1
				_with_0:play("fmove", true)
			end
			return function(self)
				move = self.unitDef.move
				self.velocityX = (self.faceRight and move or -move)
				return not self.onSurface
			end
		end
	})
	UnitAction:add("keepIdle", {
		priority = 100,
		reaction = 2.0,
		recovery = 0.2,
		available = function()
			return true
		end,
		create = function(self)
			do
				local _with_0 = self.playable
				_with_0.speed = 1
				_with_0:play("idle", true)
			end
			return function()
				return false
			end
		end
	})
	UnitAction:add("idle1", {
		priority = 1,
		reaction = 2.0,
		recovery = 0.2,
		available = function()
			return true
		end,
		queued = true,
		create = function(self)
			return once(function()
				local _with_0 = self.playable
				_with_0.speed = 1
				sleep(_with_0:play("idle1", false))
				return _with_0
			end)
		end
	})
	UnitAction:add("keepMove", {
		priority = 100,
		reaction = 2.0,
		recovery = 0.2,
		available = function()
			return true
		end,
		create = function(self)
			do
				local _with_0 = self.playable
				_with_0.speed = 1
				_with_0:play("fmove", true)
			end
			return function()
				return false
			end
		end
	})
	UnitAction:add("bmove", {
		priority = 1,
		reaction = 2.0,
		recovery = 0.2,
		available = function(self)
			return self.onSurface
		end,
		create = function(self)
			do
				local _with_0 = self.playable
				_with_0.speed = 1
				_with_0:play("bmove", true)
			end
			return function(self, action)
				local elapsedTime, recovery = action.elapsedTime, action.recovery
				local move = self.unitDef.move
				local moveSpeed
				if elapsedTime < recovery then
					moveSpeed = math.min(elapsedTime / recovery, 1.0)
				else
					moveSpeed = 1.0
				end
				self.velocityX = moveSpeed * (self.faceRight and -move or move) * 0.5
				return not self.onSurface
			end
		end
	})
	UnitAction:add("jump", {
		priority = 3,
		reaction = 2.0,
		recovery = 0.1,
		queued = true,
		available = function(self)
			return self.onSurface
		end,
		create = function(self)
			local velocityX = self.velocityX
			local jump = self.unitDef.jump
			self.velocity = Vec2(velocityX, jump)
			return once(function(self)
				local _with_0 = self.playable
				_with_0.speed = 1
				sleep(_with_0:play("jump", false))
				return _with_0
			end)
		end
	})
	return UnitAction:add("fallOff", {
		priority = 2,
		reaction = -1,
		recovery = 0.3,
		available = function(self)
			return not self.onSurface
		end,
		create = function(self)
			if self.playable.current ~= "jumping" then
				local _with_0 = self.playable
				_with_0.speed = 1
				_with_0:play("jumping", true)
			end
			return once(function(self)
				while true do
					if self.onSurface then
						do
							local _with_0 = self.playable
							_with_0.speed = 1
							sleep(_with_0:play("landing", false))
						end
						coroutine.yield(true)
					else
						coroutine.yield(false)
					end
				end
			end)
		end
	})
end
return _module_0
