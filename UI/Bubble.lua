-- [yue]: UI/Bubble.yue
local Class = Dora.Class -- 1
local once = Dora.once -- 1
local math = _G.math -- 1
local utf8 = _G.utf8 -- 1
local sleep = Dora.sleep -- 1
local Opacity = Dora.Opacity -- 1
local _module_0 = nil -- 1
local Bubble = require("UI.View.Bubble") -- 3
_module_0 = Class(Bubble, { -- 6
	__init = function(self, args) -- 6
		local text = args.text -- 7
		self.tag = "bubble" -- 8
		return self:schedule(once(function() -- 9
			local time = 3 + math.max(0.15 * utf8.len(text, 1)) -- 10
			sleep(time) -- 11
			self:perform(Opacity(0.5, 1, 0)) -- 12
			return self:removeFromParent() -- 13
		end)) -- 13
	end -- 6
}) -- 5
return _module_0 -- 13
