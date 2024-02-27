-- [xml]: UI/FilterBox.xml
local MovingText = require("UI.MovingText") -- 2
local GearTabButton = require("UI.GearTabButton") -- 3
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 4
local bg = Grid("gearBox.clip|formation_pop_bg", 2, 1) -- 5
bg.x = 335 -- 5
bg.scaleX = -1 -- 5
node1:addChild(bg) -- 5
local logo = Grid("gearBox.clip|formation_pop_logo", 2, 1) -- 6
logo.x = 11.5 - 185 -- 6
logo.scaleX = -1 -- 6
bg:addChild(logo) -- 6
do -- 6
	bg:moveUV(3, 1, Vec2(-185, 0)) -- 8
	bg:moveUV(3, 2, Vec2(-185, 0)) -- 9
	logo:moveUV(3, 1, Vec2(-185, 0)) -- 10
	logo:moveUV(3, 2, Vec2(-185, 0)) -- 11
end -- 11
local header = Grid("gearBox.clip|formation_pop_header", 2, 1) -- 14
header.x = 520 - 12 -- 14
header.y = 711 -- 14
node1:addChild(header) -- 14
do -- 14
	header:moveUV(3, 1, Vec2(-185, 0)) -- 16
	header:moveUV(3, 2, Vec2(-185, 0)) -- 17
end -- 17
local item1 = MovingText{opacity = 0.2, offsetY = 0, fontSize = 100, color3 = 0xffffff, textBG = "FIND MEMBER", y = 711} -- 20
node1:addChild(item1) -- 20
local mask = item1.mask -- 21
local sprite1 = Sprite("gearBox.clip|formation_pop_header") -- 22
sprite1.anchor = Vec2(0,sprite1.anchor.y) -- 22
sprite1.scaleX = 0.8221 -- 22
mask:addChild(sprite1) -- 22
local icon = Sprite("gearBox.clip|formation_pop_icon_4") -- 25
icon.x = 180 -- 25
icon.y = 711 -- 25
node1:addChild(icon) -- 25
local label1 = Label("SourceHanSansCN-Regular",70) -- 26
label1.anchor = Vec2(0,label1.anchor.y) -- 26
label1.x = icon.x + 95 -- 26
label1.y = 711 -- 26
label1.color3 = Color3(0xffffff) -- 26
label1.alignment = "Left" -- 26
label1.spacing = 10 -- 26
label1.text = "筛选" -- 26
node1:addChild(label1) -- 26
local item2 = GearTabButton{selected = true, text = "递增", y = 570, x = 245} -- 29
node1:addChild(item2) -- 29
local item3 = GearTabButton{selected = false, text = "递减", y = 570, x = 470} -- 30
node1:addChild(item3) -- 30
local sprite2 = Sprite("gearBox.clip|formation_pop_sep1") -- 31
sprite2.x = 470 -- 31
sprite2.y = 497 -- 31
sprite2.scaleX = 1.08 -- 31
node1:addChild(sprite2) -- 31
local item4 = GearTabButton{selected = true, text = "力量", y = 425, x = 245} -- 32
node1:addChild(item4) -- 32
local item5 = GearTabButton{selected = false, text = "体力", y = 425, x = 470} -- 33
node1:addChild(item5) -- 33
local item6 = GearTabButton{selected = false, text = "灵活", y = 425, x = 695} -- 34
node1:addChild(item6) -- 34
local item7 = GearTabButton{selected = false, text = "亲密度", y = 325, x = 245} -- 35
node1:addChild(item7) -- 35
local item8 = GearTabButton{selected = false, text = "移动", y = 325, x = 470} -- 36
node1:addChild(item8) -- 36
local item9 = GearTabButton{selected = false, text = "跳跃力", y = 325, x = 695} -- 37
node1:addChild(item9) -- 37
local item10 = GearTabButton{selected = false, text = "命中率", y = 225, x = 245} -- 38
node1:addChild(item10) -- 38
return node1 -- 38
end