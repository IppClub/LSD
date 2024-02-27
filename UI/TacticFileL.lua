-- [xml]: UI/TacticFileL.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.x = x or 0 -- 2
node1.y = y or 0 -- 2
node1.size = Size(383,538) -- 2
local sprite1 = Sprite("ai.clip|ai_big_1") -- 3
sprite1.x = node1.width*0.5 -- 3
sprite1.y = node1.height*0.5 + 100 -- 3
node1:addChild(sprite1) -- 3
local node2 = Node() -- 4
node2.y = -45 -- 4
sprite1:addChild(node2) -- 4
local sprite2 = Sprite("ai.clip|ai_big_slip_1") -- 5
sprite2.anchor = Vec2(0,sprite2.anchor.y) -- 5
node2:addChild(sprite2) -- 5
local sprite3 = Sprite("ai.clip|ai_big_slip_2") -- 6
sprite3.anchor = Vec2(0,sprite3.anchor.y) -- 6
sprite3.scaleX = 0.5 -- 6
node2:addChild(sprite3) -- 6
local label1 = Label("FangZhengHeiTiJianTi",35) -- 8
label1.x = sprite1.width*0.5 -- 8
label1.y = -45 -- 8
label1.color3 = Color3(0xffffff) -- 8
label1.alignment = "Center" -- 8
label1.text = "50%" -- 8
sprite1:addChild(label1) -- 8
local label2 = Label("FangZhengHeiTiJianTi",40) -- 13
label2.anchor = Vec2(1,1) -- 13
label2.x = node1.width - 25 -- 13
label2.y = node1.height + 80 -- 13
label2.color3 = Color3(0x7a95f8) -- 13
label2.alignment = "Right" -- 13
label2.text = "10,575 B" -- 13
node1:addChild(label2) -- 13
local label3 = Label("FangZhengHeiTiJianTi",40) -- 17
label3.anchor = Vec2(1,1) -- 17
label3.x = 0 + 15 -- 17
label3.y = node1.height + 35 -- 17
label3.color3 = Color3(0x7a95f8) -- 17
label3.angle = -90 -- 17
label3.alignment = "Right" -- 17
label3.text = "DATAOTIE" -- 17
node1:addChild(label3) -- 17
return node1 -- 17
end