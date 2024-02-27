-- [xml]: UI/RoleTab.xml
local MovingText = require("UI.MovingText") -- 2
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 3
node1.x = x or  0 -- 3
node1.y = y or 0 -- 3
local hide = Node() -- 4
hide.visible = false -- 4
node1:addChild(hide) -- 4
local menu = Menu() -- 5
menu.anchor = Vec2(1,1) -- 5
menu.size = Size(113,596) -- 5
node1:addChild(menu) -- 5
local lastSelected -- 7
local lastSelectedActive -- 8
local function itemSelect(item, itemActive) -- 9
lastSelected:removeFromParent(false) -- 10
lastSelected:addTo(menu) -- 11
lastSelectedActive:removeFromParent(false) -- 12
lastSelectedActive:addTo(hide) -- 13
itemActive:removeFromParent(false) -- 14
itemActive:addTo(menu) -- 15
item:removeFromParent(false) -- 16
item:addTo(hide) -- 17
lastSelected = item -- 18
lastSelectedActive = itemActive -- 19
menu:alignItems(15) -- 20
end -- 21
local upActive = Sprite("viewBox.clip|formation_tab_1") -- 23
upActive.order = 1 -- 23
menu:addChild(upActive) -- 23
local item1 = MovingText{textBG = "TEAM MEMBER", fontSize = 50, offsetY = 45, y = upActive.height, angle = 90} -- 24
upActive:addChild(item1) -- 24
do -- 25
local mask = item1.mask -- 26
local sprite1 = Sprite("viewBox.clip|formation_tab_1") -- 27
sprite1.anchor = Vec2(0,1) -- 27
sprite1.angle = -90 -- 27
mask:addChild(sprite1) -- 27
end -- 29
local label1 = Label("SourceHanSansCN-Regular",45) -- 31
label1.x = upActive.width*0.5 -- 31
label1.y = upActive.height*0.5 -- 31
label1.color3 = Color3(0x7ec0f8) -- 31
label1.alignment = "Center" -- 31
label1.textWidth = 45 -- 31
label1.lineGap = 5 -- 31
label1.text = "己方学员" -- 31
upActive:addChild(label1) -- 31
local up = Sprite("viewBox.clip|formation_tab_2") -- 36
up.order = 2 -- 36
up.touchEnabled = true -- 36
menu:addChild(up) -- 36
local label2 = Label("SourceHanSansCN-Regular",45) -- 37
label2.x = up.width*0.5 -- 37
label2.y = up.height*0.5 -- 37
label2.color3 = Color3(0xffffff) -- 37
label2.alignment = "Center" -- 37
label2.textWidth = 45 -- 37
label2.lineGap = 5 -- 37
label2.text = "己" -- 37
up:addChild(label2) -- 37
up:slot("TapBegan",function() -- 41
itemSelect(up, upActive) -- 42
end) -- 42
local middleActive = Sprite("viewBox.clip|formation_tab_5") -- 45
middleActive.order = 3 -- 45
menu:addChild(middleActive) -- 45
local item2 = MovingText{textBG = "REINFORCEMENT", fontSize = 50, offsetY = 45, y = middleActive.height, angle = 90} -- 46
middleActive:addChild(item2) -- 46
do -- 47
local mask = item2.mask -- 48
local sprite2 = Sprite("viewBox.clip|formation_tab_5") -- 49
sprite2.anchor = Vec2(0,1) -- 49
sprite2.angle = -90 -- 49
mask:addChild(sprite2) -- 49
end -- 51
local label3 = Label("SourceHanSansCN-Regular",45) -- 53
label3.x = middleActive.width*0.5 -- 53
label3.y = middleActive.height*0.5 -- 53
label3.color3 = Color3(0x7ec0f8) -- 53
label3.alignment = "Center" -- 53
label3.textWidth = 45 -- 53
label3.lineGap = 5 -- 53
label3.text = "协助队员" -- 53
middleActive:addChild(label3) -- 53
local middle = Sprite("viewBox.clip|formation_tab_3") -- 58
middle.order = 4 -- 58
middle.touchEnabled = true -- 58
menu:addChild(middle) -- 58
local label4 = Label("SourceHanSansCN-Regular",45) -- 59
label4.x = middle.width*0.5 -- 59
label4.y = middle.height*0.5 -- 59
label4.color3 = Color3(0xffffff) -- 59
label4.alignment = "Center" -- 59
label4.textWidth = 45 -- 59
label4.lineGap = 5 -- 59
label4.text = "协" -- 59
middle:addChild(label4) -- 59
middle:slot("TapBegan",function() -- 63
itemSelect(middle, middleActive) -- 64
end) -- 64
local down = Sprite("viewBox.clip|formation_tab_6") -- 67
down.order = 5 -- 67
down.touchEnabled = true -- 67
menu:addChild(down) -- 67
local item3 = MovingText{textBG = "FIND MEMBER", fontSize = 50, offsetY = 45, y = down.height, angle = 90} -- 68
down:addChild(item3) -- 68
local mask = item3.mask -- 69
local sprite3 = Sprite("viewBox.clip|formation_tab_6") -- 70
sprite3.anchor = Vec2(0,1) -- 70
sprite3.angle = -90 -- 70
mask:addChild(sprite3) -- 70
local label5 = Label("SourceHanSansCN-Regular",45) -- 73
label5.x = down.width*0.5 -- 73
label5.y = down.height*0.5 -- 73
label5.color3 = Color3(0xffffff) -- 73
label5.alignment = "Center" -- 73
label5.textWidth = 45 -- 73
label5.lineGap = 5 -- 73
label5.text = "筛选" -- 73
down:addChild(label5) -- 73
lastSelected = up -- 79
lastSelectedActive = upActive -- 80
up:removeFromParent(false) -- 81
up:addTo(hide) -- 82
middleActive:removeFromParent(false) -- 83
middleActive:addTo(hide) -- 84
menu:alignItems(15) -- 85
return node1 -- 85
end