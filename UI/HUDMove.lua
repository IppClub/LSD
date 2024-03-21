-- [yue]: UI/HUDMove.yue
local Class = dora.Class -- 1
local Group = dora.Group -- 1
local Scale = dora.Scale -- 1
local Ease = dora.Ease -- 1
local Keyboard = dora.Keyboard -- 1
local _module_0 = nil -- 1
local HUDMove = require("UI.View.HUDMove") -- 2
_module_0 = Class(HUDMove, { -- 5
	__init = function(self) -- 5
		local playerGroup = Group({ -- 6
			"player" -- 6
		}) -- 6
		local keyboardEnabled = false -- 7
		local updatePlayerControl -- 8
		updatePlayerControl = function(key, down, vpad) -- 8
			if keyboardEnabled and vpad then -- 9
				keyboardEnabled = false -- 10
			end -- 9
			local player = playerGroup:find(function(e) -- 11
				return e.player -- 11
			end) -- 11
			if player then -- 11
				player[key] = down -- 12
			end -- 11
		end -- 8
		self:gslot("HUD.DisplayMove", function(visible) -- 13
			self.visible = visible -- 14
			return self:perform(Scale(0.3, 0, 1, Ease.OutBack)) -- 15
		end) -- 13
		self:schedule(function() -- 16
			if not self.visible then -- 17
				return -- 17
			end -- 17
			local keyA = Keyboard:isKeyPressed("A") -- 18
			local keyD = Keyboard:isKeyPressed("D") -- 19
			if keyA or keyD then -- 20
				keyboardEnabled = true -- 20
			end -- 20
			if not keyboardEnabled then -- 21
				return false -- 21
			end -- 21
			updatePlayerControl("keyLeft", keyA, false) -- 22
			updatePlayerControl("keyRight", keyD, false) -- 23
			return false -- 24
		end) -- 16
		self:slot("Left", function(down) -- 25
			return updatePlayerControl("keyLeft", down, true) -- 26
		end) -- 25
		return self:slot("Right", function(down) -- 27
			return updatePlayerControl("keyRight", down, true) -- 28
		end) -- 28
	end -- 5
}) -- 4
return _module_0 -- 28
