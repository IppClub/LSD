-- [xml]: UI/MovingText.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local clipNode1 = ClipNode() -- 1
clipNode1.x = x or 0 -- 1
clipNode1.y = y or 0 -- 1
clipNode1.passColor3 = passColor == nil or passColor -- 1
clipNode1.angle = angle or 0 -- 1
local mask = Node() -- 3
clipNode1.stencil = mask -- 3
clipNode1.mask = mask -- 3
local node = Node() -- 5
node.y = offsetY or 35 -- 5
node.opacity = opacity or 0.5 -- 5
clipNode1:addChild(node) -- 5
local te1 = Label("FangZhengHeiTiJianTi",fontSize or 60) -- 6
te1.anchor = Vec2(0,0) -- 6
te1.color3 = Color3(color3 or 0x7ec0f8) -- 6
te1.alignment = "Left" -- 6
te1.text = textBG or '' -- 6
node:addChild(te1) -- 6
local te2 = Label("FangZhengHeiTiJianTi",fontSize or 60) -- 10
te2.anchor = Vec2(0,0) -- 10
te2.x = te1.width + 10 -- 10
te2.color3 = Color3(color3 or 0x7ec0f8) -- 10
te2.alignment = "Left" -- 10
te2.text = textBG or '' -- 10
node:addChild(te2) -- 10
local te3 = Label("FangZhengHeiTiJianTi",fontSize or 60) -- 14
te3.anchor = Vec2(0,0) -- 14
te3.x = te2.x + te2.width + 10 -- 14
te3.color3 = Color3(color3 or 0x7ec0f8) -- 14
te3.alignment = "Left" -- 14
te3.text = textBG or '' -- 14
node:addChild(te3) -- 14
local move = Action(Move(te1.width * 0.01,Vec2(0,offsetY or 35),Vec2(-te1.width - 10,offsetY or 35))) -- 19
node:slot("Enter",function() -- 21
node:perform(move) -- 21
node:slot("ActionEnd",function(_action_) if _action_ == move then node:perform(move) end end) -- 21
end) -- 21
return clipNode1 -- 21
end