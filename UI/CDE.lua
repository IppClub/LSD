-- [xml]: UI/CDE.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 1
node1.tag = "CDE" -- 1
node1.size = Size(256,91) -- 1
local playable1 = Playable("model:CDE") -- 2
playable1.x = node1.width*0.5 -- 2
playable1.y = node1.height*0.5 -- 2
playable1.opacity = 0.8 -- 2
playable1.scaleX = 0.96 -- 2
playable1.scaleY = 0.96 -- 2
playable1.renderOrder = 9 -- 2
playable1.look = "normal" -- 2
node1:addChild(playable1) -- 2
local label1 = Label("SourceHanSansCN-Regular",40) -- 3
label1.x = node1.width*0.5 -- 3
label1.y = node1.height*0.5 -- 3
label1.color3 = Color3(0x0) -- 3
label1.renderOrder = 10 -- 3
label1.alignment = "Center" -- 3
label1.text = "性格缺点" -- 3
node1:addChild(label1) -- 3
return node1 -- 3
end