-- [xml]: UI/LsdOSBack.xml
local AlignNode = require("UI.Control.Basic.AlignNode") -- 2
local H <const> = 1563 -- 3
return function(args) -- 1
local _ENV = Dora(args) -- 1
local item1 = AlignNode{isRoot = true, inUI = true} -- 4
local bg = AlignNode{vAlign = "Center", hAlign = "Center"} -- 5
item1:addChild(bg) -- 5
item1.bg = bg -- 5
local playable1 = Playable("bone:lsdOSBack") -- 6
bg:addChild(playable1) -- 6
local logo = playable1:getChildByTag("logo") -- 7
logo.visible = false -- 7
local formation_head_line = playable1:getChildByTag("formation_head_line") -- 8
formation_head_line.visible = false -- 8
item1:slot("AlignLayout",function(_w, h) -- 11
do -- 11
	local scale = h / H -- 13
	bg.scaleX = scale -- 14
	bg.scaleY = scale -- 15
end -- 15
end) -- 12
return item1 -- 12
end