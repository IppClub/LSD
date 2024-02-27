local Menu <const> = require("Menu")
local Node <const> = require("Node")
local record InteractionProps
	text: string
	buttons: {{string, string}}
end
local record Interaction
	embed Node.Type
	menu: Menu.Type
	hide: function(self: Interaction)
	show: function(self: Interaction)
end
local record InteractionClass
	type Type = Interaction
	metamethod __call: function(self: InteractionClass, params: InteractionProps): Interaction
end
local interactionClass: InteractionClass
return interactionClass
