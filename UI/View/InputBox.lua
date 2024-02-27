-- [xml]: UI/View/InputBox.xml
local SolidRect = require("UI.View.Shape.SolidRect") -- 3
local AlignNode = require("UI.Control.Basic.AlignNode") -- 4
local H <const> = 1563 -- 5
return function(args) -- 1
local _ENV = Dora(args) -- 1
local item1 = AlignNode{isRoot = true, inUI = true} -- 6
local box = Node() -- 7
box.size = Size(700,50) -- 7
item1:addChild(box) -- 7
item1.box = box -- 7
local item2 = SolidRect{color = 0x88000000, width = 900, y = -75, height = 200, x = -100} -- 8
box:addChild(item2) -- 8
local frame = Sprite("gearBox.clip|formation_pop_sep") -- 9
frame.x = box.width*0.5 -- 9
frame.y = box.height*0.5 -- 9
frame.scaleX = 0.74 -- 9
frame.scaleY = 0.74 -- 9
box:addChild(frame) -- 9
item1.frame = frame -- 9
local clipNode1 = ClipNode() -- 10
clipNode1.x = box.width*0.5 - 50 -- 10
clipNode1.y = box.height*0.5 -- 10
clipNode1.size = Size(650,50) -- 10
box:addChild(clipNode1) -- 10
local item3 = SolidRect{height = 50, width = 650} -- 12
clipNode1.stencil = item3 -- 12
local label = Label("SourceHanSansCN-Regular",35) -- 14
label.anchor = Vec2(0,label.anchor.y) -- 14
label.x = 0 -- 14
label.y = 25 -- 14
label.color3 = Color3(0xffffff) -- 14
label.alignment = "Left" -- 14
clipNode1:addChild(label) -- 14
item1.label = label -- 14
item1:slot("AlignLayout",function(w, h) -- 19
do -- 19
	local scale = h / H -- 21
	local ratio = math.min(w / 1000, 1.0) -- 22
	local extraScale = math.max(scale, ratio) -- 23
	box.scaleX = extraScale -- 24
	box.scaleY = extraScale -- 25
end -- 25
end) -- 20
return item1 -- 20
end