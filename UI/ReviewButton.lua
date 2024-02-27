-- [xml]: UI/ReviewButton.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 1
node1.x = x or 0 -- 1
node1.y = y or 0 -- 1
node1.size = Size(180,180) -- 1
node1.touchEnabled = true -- 1
node1.swallowTouches = true -- 1
local reviewIcon = Sprite("button.clip|prompt_chat_txt") -- 2
reviewIcon.x = node1.width*0.5 -- 2
reviewIcon.y = node1.height*0.5 -- 2
node1:addChild(reviewIcon) -- 2
local label1 = Label("SourceHanSansCN-Regular",30) -- 3
label1.x = node1.width*0.5 -- 3
label1.y = node1.height*0.5-73 -- 3
label1.color3 = Color3(0xffffff) -- 3
label1.alignment = "Center" -- 3
label1.text = "回顾" -- 3
node1:addChild(label1) -- 3
local scaleAction = Action(Sequence(Scale(0.08,1,0.8),Scale(0.3,0.8,1,Ease.OutBack))) -- 8
node1:slot("Tapped",function() -- 13
reviewIcon:perform(scaleAction) -- 13
end) -- 13
return node1 -- 13
end