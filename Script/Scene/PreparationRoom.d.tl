local Platformer <const> = require("Platformer")
local Unit <const> = Platformer.Unit
local record PreparationRoom
	embed Platformer.PlatformWorld.Type
	addShadowTo: function(self: PreparationRoom, unit: Unit.Type)
	makeUnitEnter: function(self: PreparationRoom, unit: Unit.Type, delay?: number, order?: number)
	turnOnLights: function(self: PreparationRoom)
end
local record PreparationRoomClass
	type Type = PreparationRoom
	metamethod __call: function(self: PreparationRoomClass): PreparationRoom
	loadAsync: function(self: PreparationRoomClass)
end
local preparationRoomClass: PreparationRoomClass
return preparationRoomClass
