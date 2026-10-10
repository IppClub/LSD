local _module_0 = nil
local _ENV = Dora
local require <const> = require
local Class <const> = Class
local Group <const> = Group
local Scale <const> = Scale
local Ease <const> = Ease
local Keyboard <const> = Keyboard
local Controller <const> = Controller
local HUDMove = require("UI.View.HUDMove")
_module_0 = Class(HUDMove, {
	__init = function(self)
		local playerGroup = Group({
			"player"
		})
		local keyboardEnabled = false
		local pendingLeft, pendingRight = false, false
		local vpadLeft, vpadRight = false, false
		local lastLeft, lastRight = false, false
		local pendingVpadLeft, pendingVpadRight = false, false
		local isActive
		isActive = function()
			return true
		end
		self.keyboardEnabled = true
		self:slot("KeyDown", function(key)
			if not isActive() then
				return
			end
			if key == "A" then
				pendingLeft = true
			end
			if key == "D" then
				pendingRight = true
			end
		end)
		local updatePlayerControl
		updatePlayerControl = function(key, down, vpad)
			if keyboardEnabled and vpad then
				keyboardEnabled = false
			end
			if vpad then
				if key == "keyLeft" then
					vpadLeft = down
					if down then
						pendingVpadLeft = true
					end
				else
					vpadRight = down
					if down then
						pendingVpadRight = true
					end
				end
				return
			end
			if key == "keyLeft" then
				lastLeft = down
			else
				lastRight = down
			end
			do
				local callback = self.onMove
				if callback then
					callback(key, down)
					return
				end
			end
			local player = playerGroup:find(function(e)
				return e.player
			end)
			if player then
				player[key] = down
			end
		end
		local clearInput
		clearInput = function()
			pendingLeft, pendingRight = false, false
			pendingVpadLeft, pendingVpadRight = false, false
			vpadLeft, vpadRight = false, false
			keyboardEnabled = false
			if lastLeft then
				updatePlayerControl("keyLeft", false, false)
			end
			if lastRight then
				return updatePlayerControl("keyRight", false, false)
			end
		end
		isActive = (require("UI.InputAvailability")).bind(self, clearInput)
		self:slot("Cleanup", clearInput)
		self:gslot("HUD.DisplayMove", function(visible)
			self.visible = visible
			return self:perform(Scale(0.3, 0, 1, Ease.OutBack))
		end)
		self:schedule(function()
			if not isActive() then
				clearInput()
				return false
			end
			local keyA = pendingLeft or Keyboard:isKeyPressed("A") or Controller:isButtonPressed(0, "dpleft")
			local keyD = pendingRight or Keyboard:isKeyPressed("D") or Controller:isButtonPressed(0, "dpright")
			pendingLeft, pendingRight = false, false
			if keyA or keyD then
				keyboardEnabled = true
			end
			if not keyboardEnabled then
				keyA = vpadLeft or pendingVpadLeft
				keyD = vpadRight or pendingVpadRight
			end
			pendingVpadLeft, pendingVpadRight = false, false
			updatePlayerControl("keyLeft", keyA, false)
			updatePlayerControl("keyRight", keyD, false)
			return false
		end)
		self:slot("Left", function(down)
			if isActive() then
				return updatePlayerControl("keyLeft", down, true)
			end
		end)
		return self:slot("Right", function(down)
			if isActive() then
				return updatePlayerControl("keyRight", down, true)
			end
		end)
	end
})
return _module_0
