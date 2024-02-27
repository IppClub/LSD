-- [xml]: UI/PhoneMessageTab.xml
local Circle = require("UI.View.Shape.Circle") -- 2
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 3
node1.x = x or 0 -- 3
node1.y = y or 0 -- 3
node1.size = Size(829,142) -- 3
node1.touchEnabled = true -- 3
local sprite1 = Sprite("phone.clip|phone_tab_com") -- 4
node1:addChild(sprite1) -- 4
local item1 = Circle{borderColor = 0xff7f8c8d, radius = 60, x = -330} -- 5
node1:addChild(item1) -- 5
local sprite2 = Sprite(avatar) -- 6
sprite2.anchor = Vec2(0,0) -- 6
sprite2.x = 30 -- 6
sprite2.y = 30 -- 6
item1:addChild(sprite2) -- 6
local label1 = Label("SourceHanSansCN-Regular",40) -- 8
label1.anchor = Vec2(0,label1.anchor.y) -- 8
label1.x = -240 -- 8
label1.y = 20 -- 8
label1.color3 = Color3(0xff000000) -- 8
label1.alignment = "Left" -- 8
label1.text = username or 'Anonymous' -- 8
node1:addChild(label1) -- 8
local label2 = Label("SourceHanSansCN-Regular",30) -- 13
label2.anchor = Vec2(0,label2.anchor.y) -- 13
label2.x = -240 -- 13
label2.y = -30 -- 13
label2.color3 = Color3(0x7a7f8c8d) -- 13
label2.alignment = "Left" -- 13
label2.text = msg or '' -- 13
node1:addChild(label2) -- 13
local label3 = Label("SourceHanSansCN-Regular",30) -- 18
label3.anchor = Vec2(0,label3.anchor.y) -- 18
label3.x = 300 -- 18
label3.y = 0 -- 18
label3.color3 = Color3(0x7a7f8c8d) -- 18
label3.alignment = "Right" -- 18
label3.text = date or '' -- 18
node1:addChild(label3) -- 18
local label4 = Label("SourceHanSansCN-Regular",30) -- 23
label4.anchor = Vec2(0,label4.anchor.y) -- 23
label4.x = 300 -- 23
label4.y = -40 -- 23
label4.color3 = Color3(0x7a7f8c8d) -- 23
label4.alignment = "Right" -- 23
label4.text = time or '' -- 23
node1:addChild(label4) -- 23
return node1 -- 23
end