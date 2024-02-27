-- [xml]: UI/PhoneMissionTab.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.x = x or 0 -- 2
node1.y = y or 0 -- 2
node1.size = Size(829,117) -- 2
node1.touchEnabled = true -- 2
local sprite1 = Sprite("phone.clip|phone_tab_mission_1") -- 3
node1:addChild(sprite1) -- 3
local label1 = Label("SourceHanSansCN-Regular",50) -- 4
label1.anchor = Vec2(0,label1.anchor.y) -- 4
label1.x = -375 -- 4
label1.color3 = Color3(0xffff0000) -- 4
label1.alignment = "Left" -- 4
label1.text = "[主线]" -- 4
node1:addChild(label1) -- 4
local label2 = Label("SourceHanSansCN-Regular",50) -- 9
label2.anchor = Vec2(0,label2.anchor.y) -- 9
label2.x = -235 -- 9
label2.color3 = Color3(0x7a000000) -- 9
label2.alignment = "Left" -- 9
label2.text = name -- 9
node1:addChild(label2) -- 9
local sprite2 = Sprite("phone.clip|phone_point_2") -- 14
sprite2.x = 380 -- 14
node1:addChild(sprite2) -- 14
return node1 -- 14
end