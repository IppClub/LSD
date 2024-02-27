-- [xml]: UI/LsdOS.xml
local AlignNode = require("UI.Control.Basic.AlignNode") -- 2
return function(args) -- 1
local _ENV = Dora(args) -- 1
local rightTop = AlignNode{vAlign = "Top", hAlign = "Right"} -- 3
local clipNode1 = ClipNode() -- 4
clipNode1.x = -105 -- 4
clipNode1.y = -75 -- 4
rightTop:addChild(clipNode1) -- 4
local sprite1 = Sprite("button.clip|img_1") -- 6
clipNode1.stencil = sprite1 -- 6
local node1 = Node() -- 8
clipNode1:addChild(node1) -- 8
local sprite2 = Sprite("button.clip|img_1") -- 9
sprite2.x = 180 -- 9
node1:addChild(sprite2) -- 9
local sprite3 = Sprite("button.clip|img_1") -- 10
node1:addChild(sprite3) -- 10
local move = Action(Move(5,Vec2(0,0),Vec2(-180,0))) -- 12
node1:slot("Enter",function() -- 14
node1:perform(move) -- 14
node1:slot("ActionEnd",function(_action_) if _action_ == move then node1:perform(move) end end) -- 14
end) -- 14
local label1 = Label("SourceHanSansCN-Regular",50) -- 17
label1.anchor = Vec2(0,0) -- 17
label1.x = -215 -- 17
label1.y = -124 -- 17
label1.color3 = Color3(0xffffff) -- 17
label1.alignment = "Left" -- 17
label1.text = "LSD OS" -- 17
rightTop:addChild(label1) -- 17
return rightTop -- 17
end