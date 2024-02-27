-- [xml]: UI/GearBox.xml
local ScrollArea = require("UI.Control.Basic.ScrollArea") -- 2
local GearTabButton = require("UI.GearTabButton") -- 3
local GearButton = require("UI.GearButton") -- 4
local MovingText = require("UI.MovingText") -- 5
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 6
local node2 = Node() -- 7
node2.x = right and -520 or 520 -- 7
node1:addChild(node2) -- 7
local sprite1 = Sprite("gearBox.clip|formation_pop_bg") -- 8
sprite1.scaleX = right and 1 or -1 -- 8
node2:addChild(sprite1) -- 8
local sprite2 = Sprite("gearBox.clip|formation_pop_logo") -- 9
sprite2.x = sprite1.width*0.5 + 11.5 -- 9
sprite2.y = sprite1.height*0.5 -- 9
sprite2.scaleX = right and 1 or -1 -- 9
sprite1:addChild(sprite2) -- 9
local node3 = Node() -- 11
node3.x = right and -45 or 45 -- 11
node2:addChild(node3) -- 11
local sprite3 = Sprite("gearBox.clip|formation_pop_header") -- 12
sprite3.x = right and 57 or -57 -- 12
sprite3.y = 711 -- 12
node3:addChild(sprite3) -- 12
local item1 = MovingText{opacity = 0.2, offsetY = 0, fontSize = 100, color3 = 0xffffff, y = 711, textBG = "EQUIPMENT", x = -510 + (right and 57 or -57)} -- 13
node3:addChild(item1) -- 13
local mask = item1.mask -- 14
local sprite4 = Sprite("gearBox.clip|formation_pop_header") -- 15
sprite4.anchor = Vec2(0,sprite4.anchor.y) -- 15
mask:addChild(sprite4) -- 15
local icon = Sprite("gearBox.clip|formation_pop_icon_5") -- 18
icon.x = -340 -- 18
icon.y = 711 -- 18
node3:addChild(icon) -- 18
local label1 = Label("SourceHanSansCN-Regular",70) -- 19
label1.anchor = Vec2(0,label1.anchor.y) -- 19
label1.x = icon.x + 95 -- 19
label1.y = 711 -- 19
label1.color3 = Color3(0xffffff) -- 19
label1.alignment = "Left" -- 19
label1.spacing = 10 -- 19
label1.text = "装备库" -- 19
node3:addChild(label1) -- 19
local tab = Menu() -- 22
tab.y = 570 -- 22
tab.size = Size(844,90) -- 22
node3:addChild(tab) -- 22
local item2 = GearTabButton{selected = true, text = "热武器"} -- 23
tab:addChild(item2) -- 23
local item3 = GearTabButton{text = "冷兵器"} -- 24
tab:addChild(item3) -- 24
local item4 = GearTabButton{text = "消耗品"} -- 25
tab:addChild(item4) -- 25
local item5 = GearTabButton{text = "特殊"} -- 26
tab:addChild(item5) -- 26
tab:alignItems(0) -- 27
local scrollArea = ScrollArea{scrollBar = false, height = 700, y = 165, width = 804, paddingX = 0} -- 29
node3:addChild(scrollArea) -- 29
do -- 30
local view = scrollArea.view -- 31
local item6 = GearButton{} -- 32
view:addChild(item6) -- 32
local item7 = GearButton{equiped = true} -- 33
view:addChild(item7) -- 33
local item8 = GearButton{locked = true} -- 34
view:addChild(item8) -- 34
local item9 = GearButton{} -- 35
view:addChild(item9) -- 35
local item10 = GearButton{} -- 36
view:addChild(item10) -- 36
local item11 = GearButton{} -- 37
view:addChild(item11) -- 37
local item12 = GearButton{} -- 38
view:addChild(item12) -- 38
local item13 = GearButton{} -- 39
view:addChild(item13) -- 39
local item14 = GearButton{} -- 40
view:addChild(item14) -- 40
local item15 = GearButton{} -- 41
view:addChild(item15) -- 41
local item16 = GearButton{} -- 42
view:addChild(item16) -- 42
local item17 = GearButton{} -- 43
view:addChild(item17) -- 43
local item18 = GearButton{} -- 44
view:addChild(item18) -- 44
local item19 = GearButton{} -- 45
view:addChild(item19) -- 45
end -- 47
scrollArea:adjustSizeWithAlign("Auto", 0, Size(804, 700)) -- 48
local sprite5 = Sprite("gearBox.clip|formation_pop_sep") -- 50
sprite5.y = -240 -- 50
sprite5.scaleX = 0.74 -- 50
sprite5.scaleY = 0.74 -- 50
node3:addChild(sprite5) -- 50
local label2 = Label("SourceHanSansCN-Regular",35) -- 51
label2.anchor = Vec2(0,label2.anchor.y) -- 51
label2.x = -375 -- 51
label2.y = -240 -- 51
label2.color3 = Color3(0xffffff) -- 51
label2.alignment = "Left" -- 51
label2.text = "装备名称" -- 51
node3:addChild(label2) -- 51
local descArea = ScrollArea{scrollBar = false, height = 300, y = -450, x = 10, width = 800, paddingX = 0} -- 54
node3:addChild(descArea) -- 54
local view = descArea.view -- 55
local label3 = Label("SourceHanSansCN-Regular",35) -- 56
label3.color3 = Color3(0xffffff) -- 56
label3.alignment = "Left" -- 56
label3.textWidth = 800 -- 56
label3.text = "装备描述文字，装备描述文字，装备描述文字，装备描述文字，装备描述文字，装备描述文字，装备描述文字" -- 56
view:addChild(label3) -- 56
descArea:adjustSizeWithAlign("Auto", 0, Size(800, 300)) -- 60
local sprite6 = Sprite("button.clip|btn_middle_1") -- 62
sprite6.y = -670 -- 62
node3:addChild(sprite6) -- 62
local label4 = Label("SourceHanSansCN-Regular",40) -- 63
label4.x = sprite6.width*0.5 -- 63
label4.y = sprite6.height*0.5 -- 63
label4.color3 = Color3(0x0) -- 63
label4.alignment = "Center" -- 63
label4.spacing = 20 -- 63
label4.text = "装备" -- 63
sprite6:addChild(label4) -- 63
return node1 -- 63
end