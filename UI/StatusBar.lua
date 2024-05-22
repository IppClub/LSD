-- [yue]: UI/StatusBar.yue
local Class = Dora.Class -- 1
local property = Dora.property -- 1
local Color3 = Dora.Color3 -- 1
local ScaleX = Dora.ScaleX -- 1
local Ease = Dora.Ease -- 1
local _module_0 = nil -- 1
local StatusBarView = require("UI.View.StatusBar").default -- 2
local getHPColor -- 4
getHPColor = function(isHostile) -- 4
	return isHostile and 0xffffff or 0x79f652 -- 4
end -- 4
local StatusBar = Class({ -- 7
	__partial = function(self, hp, ap, isHostile) -- 7
		local node -- 8
		node, self._hpBar, self._apBar = StatusBarView(hp, ap, getHPColor(isHostile)) -- 8
		return node -- 9
	end, -- 7
	hp = property(function(self) -- 11
		return self._hp -- 11
	end, function(self, value) -- 12
		if self._hp == value then -- 13
			return -- 13
		end -- 13
		self._hp = value -- 14
		if (value <= 0.25) ~= self._lowHp then -- 15
			local _des_0 = not self._lowHp -- 16
			if _des_0 then -- 16
				self._lowHp = _des_0 -- 16
				self._hpBar.color3 = Color3(0xff0000) -- 17
			else -- 19
				self._hpBar.color3 = Color3(getHPColor(self._isHostile)) -- 19
			end -- 16
		end -- 15
		return self._hpBar:perform(ScaleX(1, self._hpBar.scaleX, value, Ease.OutExpo)) -- 20
	end), -- 11
	ap = property(function(self) -- 22
		return self._ap -- 22
	end, function(self, value) -- 23
		if self._ap == value then -- 24
			return -- 24
		end -- 24
		self._ap = value -- 25
		return self._apBar:perform(ScaleX(1, self._apBar.scaleX, value, Ease.OutExpo)) -- 26
	end), -- 22
	__init = function(self, hp, ap, isHostile) -- 28
		self._hp = hp -- 29
		self._ap = ap -- 30
		self._isHostile = isHostile -- 31
		self._lowHp = hp <= 0.25 -- 32
		if self._lowHp then -- 33
			self._hpBar.color3 = Color3(0xff0000) -- 34
		else -- 36
			self._hpBar.color3 = Color3(getHPColor(self._isHostile)) -- 36
		end -- 33
	end -- 28
}) -- 6
_module_0 = StatusBar -- 38
return _module_0 -- 38
