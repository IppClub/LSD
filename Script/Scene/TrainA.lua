-- [yue]: Script/Scene/TrainA.yue
local Class = Dora.Class -- 1
local _module_0 = nil -- 1
local Train = require("Scene.Train") -- 2
_module_0 = Class(Train, { -- 4
	__init = function(self) -- 4
		self.__base.__init(self, true) -- 5
		self.tag = "TrainA" -- 6
	end -- 4
}) -- 3
return _module_0 -- 6
