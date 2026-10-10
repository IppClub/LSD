-- [yue]: Script/Scene/PassageB.yue
local _module_0 = nil -- 1
local _ENV = Dora -- 1
local require <const> = require -- 2
local Class <const> = Class -- 2
local Passage = require("Scene.Passage") -- 3
_module_0 = Class(Passage, { -- 5
	__init = function(self) -- 5
		self.__base.__init(self, "PassageB", 1, true) -- 6
		self.tag = "PassageB" -- 7
	end -- 5
}) -- 4
return _module_0 -- 1
