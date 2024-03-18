-- [yue]: UI/Interaction.yue
local Class = dora.Class -- 1
local Spawn = dora.Spawn -- 1
local Opacity = dora.Opacity -- 1
local Y = dora.Y -- 1
local Ease = dora.Ease -- 1
local Sequence = dora.Sequence -- 1
local Event = dora.Event -- 1
local _module_0 = nil -- 1
local InputButton = require("UI.InputButton") -- 2
local Interaction = require("UI.View.Interaction") -- 3
local _anon_func_0 = function(remove, Sequence, fadeOut, Event) -- 37
	if remove then -- 37
		return Sequence(fadeOut, Event("Remove")) -- 41
	else -- 43
		return fadeOut -- 43
	end -- 37
end -- 37
_module_0 = Class(Interaction, { -- 10
	__init = function(self, args) -- 10
		local buttons = args.buttons -- 11
		if buttons == nil then -- 11
			buttons = { } -- 11
		end -- 11
		local index = 1 -- 12
		for _index_0 = 1, #buttons do -- 13
			local _des_0 = buttons[_index_0] -- 13
			local text, textBG = _des_0[1], _des_0[2] -- 13
			local buttonIndex = index -- 14
			self.menu:addChild((function() -- 15
				local _with_0 = InputButton({ -- 15
					text = text, -- 15
					textBG = textBG -- 15
				}) -- 15
				self.menu.enabled = false -- 16
				_with_0:slot("Tapped", function() -- 17
					return self:emit("Tapped", buttonIndex) -- 17
				end) -- 17
				return _with_0 -- 15
			end)()) -- 15
			index = index + 1 -- 18
		end -- 18
		local size = self.menu:alignItems(5) -- 19
		self.menu.size = size -- 20
		self.menu:alignItems(5) -- 21
		return self:slot("Remove", function() -- 22
			return self:removeFromParent() -- 22
		end) -- 22
	end, -- 10
	show = function(self) -- 24
		self.menu.enabled = true -- 25
		return self:perform(Spawn(Opacity(0.2, 0, 1), Y(0.2, 220, 200, Ease.OutQuad))) -- 29
	end, -- 24
	hide = function(self, remove) -- 31
		if remove == nil then -- 31
			remove = true -- 31
		end -- 31
		self.menu.enabled = false -- 32
		local fadeOut = Spawn(Opacity(0.2, 1, 0), Y(0.2, 200, 220, Ease.InQuad)) -- 33
		return self:perform(_anon_func_0(remove, Sequence, fadeOut, Event)) -- 43
	end -- 31
}) -- 9
return _module_0 -- 43
