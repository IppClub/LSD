-- [yue]: Script/Scene/PassageA.yue
local Class = Dora.Class -- 1
local _module_0 = nil -- 1
local Passage = require("Scene.Passage") -- 2
_module_0 = Class(Passage, { -- 4
	__init = function(self) -- 4
		self.__base.__init(self, "PassageA", 3, true) -- 5
		self.tag = "PassageA" -- 6
	end -- 4
}) -- 3
return _module_0 -- 6
