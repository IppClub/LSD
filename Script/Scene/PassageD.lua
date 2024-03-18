-- [yue]: Script/Scene/PassageD.yue
local Class = dora.Class -- 1
local _module_0 = nil -- 1
local Passage = require("Scene.Passage") -- 2
_module_0 = Class(Passage, { -- 4
	__init = function(self) -- 4
		self.__base.__init(self, "PassageD", 1, true) -- 5
		self.tag = "PassageD" -- 6
	end -- 4
}) -- 3
return _module_0 -- 6
