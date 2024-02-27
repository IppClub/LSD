-- [xml]: UI/MissionTab.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.x = x or 0 -- 2
node1.y = y or 0 -- 2
node1.size = Size(896,63) -- 2
local sprite1 = Sprite("ar.clip|lsdar_settlement_mission_bg") -- 3
sprite1.x = node1.width*0.5 -- 3
sprite1.y = node1.height*0.5 -- 3
node1:addChild(sprite1) -- 3
if mode == "Main" then -- 4
local label1 = Label("SourceHanSansCN-Regular",40) -- 5
label1.anchor = Vec2(0,label1.anchor.y) -- 5
label1.x = 20 -- 5
label1.y = node1.height*0.5 -- 5
label1.color3 = Color3(0xe32323) -- 5
label1.alignment = "Left" -- 5
label1.text = "[主线]" -- 5
node1:addChild(label1) -- 5
elseif mode == "Side" then -- 9
local label2 = Label("SourceHanSansCN-Regular",40) -- 10
label2.anchor = Vec2(0,label2.anchor.y) -- 10
label2.x = 20 -- 10
label2.y = node1.height*0.5 -- 10
label2.color3 = Color3(0xffffff) -- 10
label2.opacity = 0.5 -- 10
label2.alignment = "Left" -- 10
label2.text = "[支线]" -- 10
node1:addChild(label2) -- 10
else -- 14
local label3 = Label("SourceHanSansCN-Regular",40) -- 15
label3.anchor = Vec2(0,label3.anchor.y) -- 15
label3.x = 20 -- 15
label3.y = node1.height*0.5 -- 15
label3.color3 = Color3(0x7396ff) -- 15
label3.alignment = "Left" -- 15
label3.text = "[地图]" -- 15
node1:addChild(label3) -- 15
end -- 19
local label4 = Label("SourceHanSansCN-Regular",40) -- 20
label4.anchor = Vec2(0,label4.anchor.y) -- 20
label4.x = 145 -- 20
label4.y = node1.height*0.5 -- 20
label4.color3 = Color3(0xffffff) -- 20
label4.alignment = "Left" -- 20
label4.text = title or '' -- 20
node1:addChild(label4) -- 20
if status == "Complete" then -- 24
local label5 = Label("SourceHanSansCN-Regular",40) -- 25
label5.anchor = Vec2(1,label5.anchor.y) -- 25
label5.x = node1.width-20 -- 25
label5.y = node1.height*0.5 -- 25
label5.color3 = Color3(0x7396ff) -- 25
label5.alignment = "Right" -- 25
label5.text = "完成" -- 25
node1:addChild(label5) -- 25
elseif status == "Failed" then -- 29
local label6 = Label("SourceHanSansCN-Regular",40) -- 30
label6.anchor = Vec2(1,label6.anchor.y) -- 30
label6.x = node1.width-20 -- 30
label6.y = node1.height*0.5 -- 30
label6.color3 = Color3(0xe32323) -- 30
label6.alignment = "Right" -- 30
label6.text = "失败" -- 30
node1:addChild(label6) -- 30
else -- 34
local label7 = Label("SourceHanSansCN-Regular",40) -- 35
label7.anchor = Vec2(1,label7.anchor.y) -- 35
label7.x = node1.width-20 -- 35
label7.y = node1.height*0.5 -- 35
label7.color3 = Color3(0xffffff) -- 35
label7.alignment = "Right" -- 35
label7.text = status or '' -- 35
node1:addChild(label7) -- 35
end -- 39
return node1 -- 39
end