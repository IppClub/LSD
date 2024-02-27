local Node <const> = require("Node")
local record StatusBar
	embed Node.Type
	hp: number
	ap: number
end
local StatusBarCreate: function(hp: number, ap: number, isHostile?: boolean): StatusBar
return StatusBarCreate
