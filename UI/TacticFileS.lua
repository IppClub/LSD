-- [xml]: UI/TacticFileS.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.size = Size(356,458) -- 2
local sprite1 = Sprite("ai.clip|ai_small_1") -- 3
sprite1.x = node1.width*0.5 -- 3
sprite1.y = node1.height*0.5 + 100 -- 3
sprite1.visible = false -- 3
node1:addChild(sprite1) -- 3
local sprite2 = Sprite("ai.clip|ai_small_2") -- 4
sprite2.x = node1.width*0.5 -- 4
sprite2.y = node1.height*0.5 + 100 -- 4
node1:addChild(sprite2) -- 4
local node2 = Node() -- 5
node2.y = -35 -- 5
node2.scaleX = 0.6684 -- 5
sprite2:addChild(node2) -- 5
local sprite3 = Sprite("ai.clip|ai_big_slip_1") -- 6
sprite3.anchor = Vec2(0,sprite3.anchor.y) -- 6
node2:addChild(sprite3) -- 6
local sprite4 = Sprite("ai.clip|ai_big_slip_2") -- 7
sprite4.anchor = Vec2(0,sprite4.anchor.y) -- 7
sprite4.scaleX = 0.5 -- 7
node2:addChild(sprite4) -- 7
local label1 = Label("FangZhengHeiTiJianTi",35) -- 9
label1.x = 128 -- 9
label1.y = -35 -- 9
label1.color3 = Color3(0xffffff) -- 9
label1.alignment = "Center" -- 9
label1.text = "50%" -- 9
sprite2:addChild(label1) -- 9
local label2 = Label("FangZhengHeiTiJianTi",30) -- 14
label2.anchor = Vec2(1,1) -- 14
label2.x = node1.width - 65 -- 14
label2.y = node1.height + 40 -- 14
label2.color3 = Color3(0x7a95f8) -- 14
label2.alignment = "Right" -- 14
label2.text = "10,575 B" -- 14
node1:addChild(label2) -- 14
local label3 = Label("FangZhengHeiTiJianTi",30) -- 18
label3.anchor = Vec2(1,1) -- 18
label3.x = 0 + 60 -- 18
label3.y = node1.height + 10 -- 18
label3.color3 = Color3(0x7a95f8) -- 18
label3.angle = -90 -- 18
label3.alignment = "Right" -- 18
label3.text = "DATAOTIE" -- 18
node1:addChild(label3) -- 18
return node1 -- 18
end