-- [xml]: UI/TrainingBox.xml
local ScrollArea = require("UI.Control.Basic.ScrollArea") -- 2
local GearTabButton = require("UI.GearTabButton") -- 3
local TrainingButton = require("UI.TrainingButton") -- 4
local ArrowButton = require("UI.ArrowButton") -- 5
local SolidRect = require("UI.View.Shape.SolidRect") -- 6
local MovingText = require("UI.MovingText") -- 7
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 9
node1.x = 733.5 -- 9
local sprite1 = Sprite("gearBox.clip|formation_pop_bg_4") -- 10
node1:addChild(sprite1) -- 10
local item1 = MovingText{opacity = 0.2, offsetY = 0, fontSize = 100, color3 = 0xffffff, y = 711, textBG = "ENEMY SIMULATION", x = -733.5} -- 11
node1:addChild(item1) -- 11
local mask = item1.mask -- 12
local item2 = SolidRect{height = 140, width = 1467, y = 0, x = 0} -- 13
mask:addChild(item2) -- 13
local sprite2 = Sprite("gearBox.clip|formation_pop_icon_3") -- 16
sprite2.x = -509 -- 16
sprite2.y = 711 -- 16
node1:addChild(sprite2) -- 16
local label1 = Label("SourceHanSansCN-Regular",70) -- 17
label1.anchor = Vec2(0,label1.anchor.y) -- 17
label1.x = -410 -- 17
label1.y = 711 -- 17
label1.color3 = Color3(0xffffff) -- 17
label1.alignment = "Left" -- 17
label1.spacing = 10 -- 17
label1.text = "假想敌模拟" -- 17
node1:addChild(label1) -- 17
local tab = Menu() -- 20
tab.anchor = Vec2(0,tab.anchor.y) -- 20
tab.x = -584 -- 20
tab.y = 570 -- 20
tab.size = Size(844,90) -- 20
node1:addChild(tab) -- 20
local item3 = GearTabButton{selected = true, text = "BOSS"} -- 21
tab:addChild(item3) -- 21
local item4 = GearTabButton{text = "精英怪"} -- 22
tab:addChild(item4) -- 22
local item5 = GearTabButton{text = "怪物潮"} -- 23
tab:addChild(item5) -- 23
local item6 = GearTabButton{text = "特殊"} -- 24
tab:addChild(item6) -- 24
tab:alignItems(0) -- 25
local scrollArea = ScrollArea{scrollBar = false, height = 700, y = 165, width = 804, paddingX = 0, x = -160} -- 27
node1:addChild(scrollArea) -- 27
local view = scrollArea.view -- 28
local item7 = TrainingButton{} -- 29
view:addChild(item7) -- 29
local item8 = TrainingButton{selected = true} -- 30
view:addChild(item8) -- 30
local item9 = TrainingButton{} -- 31
view:addChild(item9) -- 31
local item10 = TrainingButton{} -- 32
view:addChild(item10) -- 32
local item11 = TrainingButton{} -- 33
view:addChild(item11) -- 33
local item12 = TrainingButton{} -- 34
view:addChild(item12) -- 34
local item13 = TrainingButton{} -- 35
view:addChild(item13) -- 35
local item14 = TrainingButton{} -- 36
view:addChild(item14) -- 36
local item15 = TrainingButton{} -- 37
view:addChild(item15) -- 37
local item16 = TrainingButton{} -- 38
view:addChild(item16) -- 38
local item17 = TrainingButton{} -- 39
view:addChild(item17) -- 39
local item18 = TrainingButton{} -- 40
view:addChild(item18) -- 40
local item19 = TrainingButton{} -- 41
view:addChild(item19) -- 41
local item20 = TrainingButton{} -- 42
view:addChild(item20) -- 42
scrollArea:adjustSizeWithAlign("Auto", 0, Size(804, 700)) -- 44
local label2 = Label("SourceHanSansCN-Regular",35) -- 46
label2.anchor = Vec2(0,label2.anchor.y) -- 46
label2.x = -545 -- 46
label2.y = -240 -- 46
label2.color3 = Color3(0xffffff) -- 46
label2.alignment = "Left" -- 46
label2.text = "怪物名称" -- 46
node1:addChild(label2) -- 46
local descArea = ScrollArea{scrollBar = false, height = 300, y = -450, x = -160, width = 800, paddingX = 0} -- 49
node1:addChild(descArea) -- 49
local view = descArea.view -- 50
local label3 = Label("SourceHanSansCN-Regular",35) -- 51
label3.color3 = Color3(0xffffff) -- 51
label3.alignment = "Left" -- 51
label3.textWidth = 800 -- 51
label3.text = "怪物描述文字，怪物描述文字，怪物描述文字，怪物描述文字，怪物描述文字，怪物描述文字，怪物描述文字" -- 51
view:addChild(label3) -- 51
descArea:adjustSizeWithAlign("Auto", 0, Size(800, 300)) -- 55
local sprite3 = Sprite("button.clip|btn_middle_1") -- 57
sprite3.x = -170 -- 57
sprite3.y = -670 -- 57
node1:addChild(sprite3) -- 57
local label4 = Label("SourceHanSansCN-Regular",40) -- 58
label4.x = sprite3.width*0.5 -- 58
label4.y = sprite3.height*0.5 -- 58
label4.color3 = Color3(0x0) -- 58
label4.alignment = "Center" -- 58
label4.spacing = 20 -- 58
label4.text = "确定" -- 58
sprite3:addChild(label4) -- 58
local menu1 = Menu() -- 62
node1:addChild(menu1) -- 62
local label5 = Label("SourceHanSansCN-Regular",50) -- 63
label5.x = 490 -- 63
label5.y = 585 -- 63
label5.color3 = Color3(0xffffff) -- 63
label5.opacity = 0.5 -- 63
label5.alignment = "Center" -- 63
label5.spacing = 5 -- 63
label5.text = "难度" -- 63
menu1:addChild(label5) -- 63
local label6 = Label("SourceHanSansCN-Regular",50) -- 66
label6.x = 490 -- 66
label6.y = 510 -- 66
label6.color3 = Color3(0xffffff) -- 66
label6.alignment = "Center" -- 66
label6.spacing = 5 -- 66
label6.text = "呆滞" -- 66
menu1:addChild(label6) -- 66
local item21 = ArrowButton{y = 510, x = 355} -- 69
menu1:addChild(item21) -- 69
local item22 = ArrowButton{y = 510, right = true, x = 624} -- 70
menu1:addChild(item22) -- 70
local label7 = Label("SourceHanSansCN-Regular",50) -- 72
label7.x = 490 -- 72
label7.y = 585 - 152 -- 72
label7.color3 = Color3(0xffffff) -- 72
label7.opacity = 0.5 -- 72
label7.alignment = "Center" -- 72
label7.spacing = 5 -- 72
label7.text = "训练时长" -- 72
menu1:addChild(label7) -- 72
local label8 = Label("SourceHanSansCN-Regular",50) -- 75
label8.x = 490 -- 75
label8.y = 510 - 152 -- 75
label8.color3 = Color3(0xffffff) -- 75
label8.alignment = "Center" -- 75
label8.spacing = 5 -- 75
label8.text = "3m" -- 75
menu1:addChild(label8) -- 75
local item23 = ArrowButton{y = 510 - 152, x = 355} -- 78
menu1:addChild(item23) -- 78
local item24 = ArrowButton{y = 510 - 152, right = true, x = 624} -- 79
menu1:addChild(item24) -- 79
return node1 -- 79
end