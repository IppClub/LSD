local _module_0 = nil
local _ENV = Dora
local require <const> = require
local Class <const> = Class
local Scale <const> = Scale
local Ease <const> = Ease
local emit <const> = emit
local Keyboard <const> = Keyboard
local Controller <const> = Controller
local HUDControl = require("UI.View.HUDControl")
_module_0 = Class(HUDControl, {
	__init = function(self)
		self:gslot("Story.Display", function(visible)
			self.visible = not visible
		end)
		self:gslot("Tutorial.Weapon", function()
			self.weapon:perform(Scale(0.3, 0, 1, Ease.OutBack))
			self.weapon.visible = true
		end)
		local pendingShot, pendingRelease = false, false
		local clearInput
		clearInput = function()
			pendingShot, pendingRelease = false, false
			return emit("Skill.Ended", true)
		end
		local isActive = (require("UI.InputAvailability")).bind(self, clearInput)
		local wasActive = true
		self:slot("Cleanup", clearInput)
		self.keyboardEnabled = true
		self:slot("KeyDown", function(key)
			if key == "J" and isActive() and self.weapon.visible then
				pendingShot = true
			end
		end)
		self:slot("KeyUp", function(key)
			if key == "J" and isActive() and self.weapon.visible then
				pendingRelease = true
			end
		end)
		return self.weapon:schedule(function()
			if not (isActive() and self.weapon.visible) then
				if wasActive then
					clearInput()
				end
				wasActive = false
				return false
			end
			wasActive = true
			if pendingShot or Keyboard:isKeyDown("J") or Controller:isButtonDown(0, "a") then
				emit("Skill.Began")
			end
			if pendingRelease or Keyboard:isKeyUp("J") or Controller:isButtonUp(0, "a") then
				emit("Skill.Ended")
			end
			pendingShot, pendingRelease = false, false
			return false
		end)
	end
})
return _module_0
