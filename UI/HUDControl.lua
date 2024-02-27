-- [yue]: UI/HUDControl.yue
local Class = dora.Class -- 1
local Scale = dora.Scale -- 1
local Ease = dora.Ease -- 1
local _module_0 = nil -- 1
local HUDControl = require("UI.View.HUDControl") -- 2
_module_0 = Class(HUDControl, { -- 5
	__init = function(self) -- 5
		self:gslot("Story.Display", function(visible) -- 6
			self.visible = not visible -- 6
		end) -- 6
		return self:gslot("Tutorial.Weapon", function() -- 7
			self.weapon:perform(Scale(0.3, 0, 1, Ease.OutBack)) -- 8
			self.weapon.visible = true -- 9
		end) -- 9
	end -- 5
}) -- 4
return _module_0 -- 9
