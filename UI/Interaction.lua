local _module_0 = nil
local _ENV = Dora
local require <const> = require
local Class <const> = Class
local Spawn <const> = Spawn
local Opacity <const> = Opacity
local Y <const> = Y
local Ease <const> = Ease
local Sequence <const> = Sequence
local Event <const> = Event
local InputButton = require("UI.InputButton")
local Interaction = require("UI.View.Interaction")
local Fit = require("UI.FitInteraction")
local _anon_func_0 = function(fadeOut, remove)
	if remove then
		return Sequence(fadeOut, Event("Remove"))
	else
		return fadeOut
	end
end
_module_0 = Class(Interaction, {
	__init = function(self, args)
		local buttons = args.buttons
		if buttons == nil then
			buttons = { }
		end
		local index = 1
		for _index_0 = 1, #buttons do
			local _des_0 = buttons[_index_0]
			local text, textBG = _des_0[1], _des_0[2]
			local buttonIndex = index
			self.menu:addChild((function()
				local _with_0 = InputButton({
					text = text,
					textBG = textBG or ""
				})
				self.menu.enabled = false
				_with_0:slot("Tapped", function()
					return self:emit("Tapped", buttonIndex)
				end)
				return _with_0
			end)())
			index = index + 1
		end
		local size = self.menu:alignItems(5)
		self.menu.size = size
		self.menu:alignItems(5)
		self:slot("Remove", function()
			return self:removeFromParent()
		end)
		local title = self.children.first
		Fit.title(title, args.fliped)
		self.screenBoundsTargets = {
			title,
			title.children.last,
			self.menu
		}
		return require("UI.KeepOnScreen")(self, self.screenBoundsTargets)
	end,
	show = function(self)
		self.menu.enabled = true
		return self:perform(Spawn(Opacity(0.2, 0, 1), Y(0.2, 220, 200, Ease.OutQuad)))
	end,
	hide = function(self, remove)
		if remove == nil then
			remove = true
		end
		self.menu.enabled = false
		local fadeOut = Spawn(Opacity(0.2, 1, 0), Y(0.2, 200, 220, Ease.InQuad))
		return self:perform(_anon_func_0(fadeOut, remove))
	end
})
return _module_0
