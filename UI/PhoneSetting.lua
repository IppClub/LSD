-- [xml]: UI/PhoneSetting.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.x = x or -415 -- 2
node1.y = y or -55 -- 2
local basic = Node() -- 3
node1:addChild(basic) -- 3
local sprite1 = Sprite("phone.clip|phone_tab_set") -- 4
basic:addChild(sprite1) -- 4
local label1 = Label("SourceHanSansCN-Regular",50) -- 5
label1.x = -260 -- 5
label1.color3 = Color3(0xff000000) -- 5
label1.alignment = "Left" -- 5
label1.text = "基础设置" -- 5
basic:addChild(label1) -- 5
local label2 = Label("SourceHanSansCN-Regular",30) -- 10
label2.anchor = Vec2(0,label2.anchor.y) -- 10
label2.x = -120 -- 10
label2.color3 = Color3(0x7a7f8c8d) -- 10
label2.alignment = "Left" -- 10
label2.text = "Basic Settings" -- 10
basic:addChild(label2) -- 10
local node2 = Node() -- 15
node2.x = -370 -- 15
basic:addChild(node2) -- 15
local node3 = Node() -- 16
node3.y = -120 -- 16
node2:addChild(node3) -- 16
local label3 = Label("SourceHanSansCN-Regular",40) -- 17
label3.anchor = Vec2(0,label3.anchor.y) -- 17
label3.color3 = Color3(0xff000000) -- 17
label3.alignment = "Left" -- 17
label3.text = "帧率" -- 17
node3:addChild(label3) -- 17
local label4 = Label("SourceHanSansCN-Regular",30) -- 22
label4.anchor = Vec2(0,label4.anchor.y) -- 22
label4.x = 210 -- 22
label4.color3 = Color3(0xff000000) -- 22
label4.alignment = "Left" -- 22
label4.text = "标准" -- 22
node3:addChild(label4) -- 22
local label5 = Label("SourceHanSansCN-Regular",30) -- 27
label5.anchor = Vec2(0,label5.anchor.y) -- 27
label5.x = 420 -- 27
label5.color3 = Color3(0xff000000) -- 27
label5.alignment = "Left" -- 27
label5.text = "高" -- 27
node3:addChild(label5) -- 27
local label6 = Label("SourceHanSansCN-Regular",30) -- 32
label6.anchor = Vec2(0,label6.anchor.y) -- 32
label6.x = 630 -- 32
label6.color3 = Color3(0xff000000) -- 32
label6.alignment = "Left" -- 32
label6.text = "极致" -- 32
node3:addChild(label6) -- 32
local node4 = Node() -- 38
node4.y = -220 -- 38
node2:addChild(node4) -- 38
local label7 = Label("SourceHanSansCN-Regular",40) -- 39
label7.anchor = Vec2(0,label7.anchor.y) -- 39
label7.color3 = Color3(0xff000000) -- 39
label7.alignment = "Left" -- 39
label7.text = "伤害数字" -- 39
node4:addChild(label7) -- 39
local label8 = Label("SourceHanSansCN-Regular",30) -- 44
label8.anchor = Vec2(0,label8.anchor.y) -- 44
label8.x = 210 -- 44
label8.color3 = Color3(0xff000000) -- 44
label8.alignment = "Left" -- 44
label8.text = "关" -- 44
node4:addChild(label8) -- 44
local label9 = Label("SourceHanSansCN-Regular",30) -- 49
label9.anchor = Vec2(0,label9.anchor.y) -- 49
label9.x = 360 -- 49
label9.color3 = Color3(0xff000000) -- 49
label9.alignment = "Left" -- 49
label9.text = "小" -- 49
node4:addChild(label9) -- 49
local label10 = Label("SourceHanSansCN-Regular",30) -- 54
label10.anchor = Vec2(0,label10.anchor.y) -- 54
label10.x = 510 -- 54
label10.color3 = Color3(0xff000000) -- 54
label10.alignment = "Left" -- 54
label10.text = "中" -- 54
node4:addChild(label10) -- 54
local label11 = Label("SourceHanSansCN-Regular",30) -- 59
label11.anchor = Vec2(0,label11.anchor.y) -- 59
label11.x = 660 -- 59
label11.color3 = Color3(0xff000000) -- 59
label11.alignment = "Left" -- 59
label11.text = "大" -- 59
node4:addChild(label11) -- 59
local node5 = Node() -- 65
node5.y = -420 -- 65
node2:addChild(node5) -- 65
local label12 = Label("SourceHanSansCN-Regular",40) -- 66
label12.anchor = Vec2(0,label12.anchor.y) -- 66
label12.color3 = Color3(0xff000000) -- 66
label12.alignment = "Left" -- 66
label12.text = "游戏音乐" -- 66
node5:addChild(label12) -- 66
local node6 = Node() -- 72
node6.y = -320 -- 72
node2:addChild(node6) -- 72
local label13 = Label("SourceHanSansCN-Regular",40) -- 73
label13.anchor = Vec2(0,label13.anchor.y) -- 73
label13.color3 = Color3(0xff000000) -- 73
label13.alignment = "Left" -- 73
label13.text = "游戏音效" -- 73
node6:addChild(label13) -- 73
local operation = Node() -- 83
operation.y = -530 -- 83
node1:addChild(operation) -- 83
local sprite2 = Sprite("phone.clip|phone_tab_set") -- 84
operation:addChild(sprite2) -- 84
local label14 = Label("SourceHanSansCN-Regular",50) -- 85
label14.x = -260 -- 85
label14.color3 = Color3(0xff000000) -- 85
label14.alignment = "Left" -- 85
label14.text = "操作设置" -- 85
operation:addChild(label14) -- 85
local label15 = Label("SourceHanSansCN-Regular",30) -- 90
label15.anchor = Vec2(0,label15.anchor.y) -- 90
label15.x = -120 -- 90
label15.color3 = Color3(0x7a7f8c8d) -- 90
label15.alignment = "Left" -- 90
label15.text = "Operation Settings" -- 90
operation:addChild(label15) -- 90
local node7 = Node() -- 95
node7.x = -370 -- 95
operation:addChild(node7) -- 95
local node8 = Node() -- 96
node8.y = -120 -- 96
node7:addChild(node8) -- 96
local label16 = Label("SourceHanSansCN-Regular",40) -- 97
label16.anchor = Vec2(0,label16.anchor.y) -- 97
label16.color3 = Color3(0xff000000) -- 97
label16.alignment = "Left" -- 97
label16.text = "按键设置" -- 97
node8:addChild(label16) -- 97
local node9 = Node() -- 103
node9.y = -220 -- 103
node7:addChild(node9) -- 103
local label17 = Label("SourceHanSansCN-Regular",40) -- 104
label17.anchor = Vec2(0,label17.anchor.y) -- 104
label17.color3 = Color3(0xff000000) -- 104
label17.alignment = "Left" -- 104
label17.text = "摇杆设置" -- 104
node9:addChild(label17) -- 104
local node10 = Node() -- 110
node10.y = -320 -- 110
node7:addChild(node10) -- 110
local label18 = Label("SourceHanSansCN-Regular",40) -- 111
label18.anchor = Vec2(0,label18.anchor.y) -- 111
label18.color3 = Color3(0xff000000) -- 111
label18.alignment = "Left" -- 111
label18.text = "其他模式" -- 111
node10:addChild(label18) -- 111
return node1 -- 111
end