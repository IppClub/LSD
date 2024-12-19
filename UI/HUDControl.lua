-- [yue]: UI/HUDControl.yue
local Class = Dora.Class -- 1
local Scale = Dora.Scale -- 1
local Ease = Dora.Ease -- 1
local Keyboard = Dora.Keyboard -- 1
local Controller = Dora.Controller -- 1
local emit = Dora.emit -- 1
local _module_0 = nil -- 1
local HUDControl = require("UI.View.HUDControl") -- 2
_module_0 = Class(HUDControl, { -- 5
	__init = function(self) -- 5
		self:gslot("Story.Display", function(visible) -- 6
			self.visible = not visible -- 6
		end) -- 6
		self:gslot("Tutorial.Weapon", function() -- 7
			self.weapon:perform(Scale(0.3, 0, 1, Ease.OutBack)) -- 8
			self.weapon.visible = true -- 9
		end) -- 7
		return self.weapon:schedule(function() -- 10
			if Keyboard:isKeyDown("J") or Controller:isButtonDown(0, "a") then -- 11
				emit("Skill.Began") -- 12
			end -- 11
			if Keyboard:isKeyUp("J") or Controller:isButtonUp(0, "a") then -- 13
				return emit("Skill.Ended") -- 14
			end -- 13
		end) -- 14
	end -- 5
}) -- 4
return _module_0 -- 14
