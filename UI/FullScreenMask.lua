-- [xml]: UI/FullScreenMask.xml
local SolidRect = require("UI.View.Shape.SolidRect") -- 2
local AlignNode = require("UI.Control.Basic.AlignNode") -- 3
return function(args) -- 1
local _ENV = Dora(args) -- 1
local lb = AlignNode{vAlign = "Bottom", hAlign = "Left"} -- 5
local mask = SolidRect{color = 0x66000000, height = 1563, width = 3258} -- 6
lb:addChild(mask) -- 6
lb:slot("AlignLayout",function(w, h) -- 7
do -- 7
	mask:removeFromParent() -- 10
	local _with_0 = SolidRect({ -- 11
		width = w, -- 11
		height = h, -- 11
		color = 0x66000000 -- 11
	}) -- 11
	mask = _with_0 -- 11
	_with_0.touchEnabled = true -- 12
	_with_0.swallowTouches = true -- 13
	_with_0:addTo(lb) -- 14
end -- 14
end) -- 8
do -- 16
	mask.touchEnabled = true -- 18
	mask.swallowTouches = true -- 19
end -- 19
return lb -- 17
end