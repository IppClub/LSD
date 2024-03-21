-- [xml]: UI/Training.xml
local AlignNode = require("UI.Control.Basic.AlignNode") -- 2
local FormationRole = require("UI.FormationRole") -- 3
local LsdOS = require("UI.LsdOS") -- 5
local Button = require("UI.Button") -- 6
local BackButton = require("UI.BackButton") -- 7
local Skill = require("UI.Skill") -- 8
local H <const> = 1563 -- 11
return function(args) -- 1
local _ENV = Dora(args) -- 1
local item1 = AlignNode{isRoot = true, inUI = true} -- 12
local item2 = AlignNode{alignHeight = "h", alignWidth = "3258 * math.min(h / 1563, w / 3258)", vAlign = "Center", hAlign = "Center"} -- 13
item1:addChild(item2) -- 13
local bg = AlignNode{vAlign = "Center", hAlign = "Center"} -- 15
item2:addChild(bg) -- 15
local playable1 = Playable("bone:lsdOSBack") -- 16
bg:addChild(playable1) -- 16
local logo = playable1:getChildByTag("logo") -- 17
logo.visible = false -- 17
local formation_head_line = playable1:getChildByTag("formation_head_line") -- 18
local title = Label("SourceHanSansCN-Regular",50) -- 19
title.anchor = Vec2(title.anchor.x,0) -- 19
title.x = 1333 -- 19
title.y = -8 -- 19
title.color3 = Color3(0xffffff) -- 19
title.alignment = "Center" -- 19
title.spacing = 20 -- 19
title.text = "专项训练" -- 19
formation_head_line:addChild(title) -- 19
local figure = AlignNode{vAlign = "Center", hAlign = "Center"} -- 26
item2:addChild(figure) -- 26
local p1 = FormationRole{cap = true, editing = false, role = "moyu", y = 100, x = -1077} -- 27
figure:addChild(p1) -- 27
local label1 = Label("SourceHanSansCN-Regular",80) -- 28
label1.anchor = Vec2(0,1) -- 28
label1.x = -672 -- 28
label1.y = 600 -- 28
label1.color3 = Color3(0x0) -- 28
label1.alignment = "Left" -- 28
label1.spacing = 20 -- 28
label1.text = "默羽" -- 28
figure:addChild(label1) -- 28
local sprite1 = Sprite("button.clip|article_tab_bg") -- 31
sprite1.anchor = Vec2(0,sprite1.anchor.y) -- 31
sprite1.x = -700 -- 31
sprite1.y = 445 -- 31
figure:addChild(sprite1) -- 31
local label2 = Label("SourceHanSansCN-Regular",40) -- 32
label2.x = -314 -- 32
label2.y = 445 -- 32
label2.color3 = Color3(0xffffff) -- 32
label2.alignment = "Center" -- 32
label2.spacing = 5 -- 32
label2.text = "基础属性" -- 32
figure:addChild(label2) -- 32
local label3 = Label("SourceHanSansCN-Regular",40) -- 35
label3.anchor = Vec2(0,label3.anchor.y) -- 35
label3.x = -677 -- 35
label3.y = 360 -- 35
label3.color3 = Color3(0x0) -- 35
label3.alignment = "Left" -- 35
label3.spacing = 5 -- 35
label3.text = "生命" -- 35
figure:addChild(label3) -- 35
local label4 = Label("SourceHanSansCN-Regular",40) -- 38
label4.anchor = Vec2(1,label4.anchor.y) -- 38
label4.x = -465 -- 38
label4.y = 360 -- 38
label4.color3 = Color3(0x538eff) -- 38
label4.alignment = "Right" -- 38
label4.text = "80" -- 38
figure:addChild(label4) -- 38
local label5 = Label("SourceHanSansCN-Regular",40) -- 41
label5.anchor = Vec2(0,label5.anchor.y) -- 41
label5.x = -677 -- 41
label5.y = 360 - 70 -- 41
label5.color3 = Color3(0x0) -- 41
label5.alignment = "Left" -- 41
label5.spacing = 5 -- 41
label5.text = "力量" -- 41
figure:addChild(label5) -- 41
local label6 = Label("SourceHanSansCN-Regular",40) -- 44
label6.anchor = Vec2(1,label6.anchor.y) -- 44
label6.x = -465 -- 44
label6.y = 360 - 70 -- 44
label6.color3 = Color3(0x538eff) -- 44
label6.alignment = "Right" -- 44
label6.text = "20" -- 44
figure:addChild(label6) -- 44
local label7 = Label("SourceHanSansCN-Regular",40) -- 47
label7.anchor = Vec2(0,label7.anchor.y) -- 47
label7.x = -677 -- 47
label7.y = 360 - 70 * 2 -- 47
label7.color3 = Color3(0x0) -- 47
label7.alignment = "Left" -- 47
label7.spacing = 5 -- 47
label7.text = "体能" -- 47
figure:addChild(label7) -- 47
local label8 = Label("SourceHanSansCN-Regular",40) -- 50
label8.anchor = Vec2(1,label8.anchor.y) -- 50
label8.x = -465 -- 50
label8.y = 360 - 70 * 2 -- 50
label8.color3 = Color3(0x0) -- 50
label8.alignment = "Right" -- 50
label8.text = "60" -- 50
figure:addChild(label8) -- 50
local label9 = Label("SourceHanSansCN-Regular",40) -- 53
label9.anchor = Vec2(0,label9.anchor.y) -- 53
label9.x = -677 -- 53
label9.y = 360 - 70 * 3 -- 53
label9.color3 = Color3(0x0) -- 53
label9.alignment = "Left" -- 53
label9.spacing = 5 -- 53
label9.text = "灵活" -- 53
figure:addChild(label9) -- 53
local label10 = Label("SourceHanSansCN-Regular",40) -- 56
label10.anchor = Vec2(1,label10.anchor.y) -- 56
label10.x = -465 -- 56
label10.y = 360 - 70 * 3 -- 56
label10.color3 = Color3(0x0) -- 56
label10.alignment = "Right" -- 56
label10.text = "2.3" -- 56
figure:addChild(label10) -- 56
local label11 = Label("SourceHanSansCN-Regular",40) -- 60
label11.anchor = Vec2(0,label11.anchor.y) -- 60
label11.x = -330 -- 60
label11.y = 360 -- 60
label11.color3 = Color3(0x0) -- 60
label11.alignment = "Left" -- 60
label11.spacing = 5 -- 60
label11.text = "移动速度" -- 60
figure:addChild(label11) -- 60
local label12 = Label("SourceHanSansCN-Regular",40) -- 63
label12.anchor = Vec2(1,label12.anchor.y) -- 63
label12.x = 60 -- 63
label12.y = 360 -- 63
label12.color3 = Color3(0x538eff) -- 63
label12.alignment = "Right" -- 63
label12.text = "200" -- 63
figure:addChild(label12) -- 63
local label13 = Label("SourceHanSansCN-Regular",40) -- 66
label13.anchor = Vec2(0,label13.anchor.y) -- 66
label13.x = -330 -- 66
label13.y = 360 - 70 -- 66
label13.color3 = Color3(0x0) -- 66
label13.alignment = "Left" -- 66
label13.spacing = 5 -- 66
label13.text = "跳跃能力" -- 66
figure:addChild(label13) -- 66
local label14 = Label("SourceHanSansCN-Regular",40) -- 69
label14.anchor = Vec2(1,label14.anchor.y) -- 69
label14.x = 60 -- 69
label14.y = 360 - 70 -- 69
label14.color3 = Color3(0x538eff) -- 69
label14.alignment = "Right" -- 69
label14.text = "100" -- 69
figure:addChild(label14) -- 69
local label15 = Label("SourceHanSansCN-Regular",40) -- 72
label15.anchor = Vec2(0,label15.anchor.y) -- 72
label15.x = -330 -- 72
label15.y = 360 - 70 * 2 -- 72
label15.color3 = Color3(0x0) -- 72
label15.alignment = "Left" -- 72
label15.spacing = 5 -- 72
label15.text = "近战命中率" -- 72
figure:addChild(label15) -- 72
local label16 = Label("SourceHanSansCN-Regular",40) -- 75
label16.anchor = Vec2(1,label16.anchor.y) -- 75
label16.x = 60 -- 75
label16.y = 360 - 70 * 2 -- 75
label16.color3 = Color3(0x0) -- 75
label16.alignment = "Right" -- 75
label16.text = "60%" -- 75
figure:addChild(label16) -- 75
local label17 = Label("SourceHanSansCN-Regular",40) -- 78
label17.anchor = Vec2(0,label17.anchor.y) -- 78
label17.x = -330 -- 78
label17.y = 360 - 70 * 3 -- 78
label17.color3 = Color3(0x0) -- 78
label17.alignment = "Left" -- 78
label17.spacing = 5 -- 78
label17.text = "射击命中率" -- 78
figure:addChild(label17) -- 78
local label18 = Label("SourceHanSansCN-Regular",40) -- 81
label18.anchor = Vec2(1,label18.anchor.y) -- 81
label18.x = 60 -- 81
label18.y = 360 - 70 * 3 -- 81
label18.color3 = Color3(0x0) -- 81
label18.alignment = "Right" -- 81
label18.text = "83%" -- 81
figure:addChild(label18) -- 81
local label19 = Label("SourceHanSansCN-Regular",40) -- 84
label19.anchor = Vec2(0,label19.anchor.y) -- 84
label19.x = -330 -- 84
label19.y = 360 - 70 * 4 -- 84
label19.color3 = Color3(0x0) -- 84
label19.alignment = "Left" -- 84
label19.spacing = 5 -- 84
label19.text = "技能命中率" -- 84
figure:addChild(label19) -- 84
local label20 = Label("SourceHanSansCN-Regular",40) -- 87
label20.anchor = Vec2(1,label20.anchor.y) -- 87
label20.x = 60 -- 87
label20.y = 360 - 70 * 4 -- 87
label20.color3 = Color3(0x0) -- 87
label20.alignment = "Right" -- 87
label20.text = "100%" -- 87
figure:addChild(label20) -- 87
local skillArea = Node() -- 90
skillArea.x = -303 -- 90
skillArea.y = -280 -- 90
skillArea.size = Size(888,592) -- 90
figure:addChild(skillArea) -- 90
local item3 = Skill{} -- 91
skillArea:addChild(item3) -- 91
local item4 = Skill{} -- 92
skillArea:addChild(item4) -- 92
local item5 = Skill{} -- 93
skillArea:addChild(item5) -- 93
local item6 = Skill{} -- 94
skillArea:addChild(item6) -- 94
local item7 = Skill{} -- 95
skillArea:addChild(item7) -- 95
local item8 = Skill{} -- 96
skillArea:addChild(item8) -- 96
skillArea:alignItems(0) -- 97
local bottomControl = AlignNode{vAlign = "Bottom", hAlign = "Center"} -- 100
item2:addChild(bottomControl) -- 100
local mirror = Node() -- 101
mirror.anchor = Vec2(mirror.anchor.x,1) -- 101
mirror.scaleY = -1 -- 101
mirror.size = Size(2721,300) -- 101
bottomControl:addChild(mirror) -- 101
local playable2 = Playable("spine:moyu") -- 102
playable2.x = mirror.width*0.5 + p1.x -- 102
playable2.y = 60 -- 102
playable2.scaleX = 1.5 -- 102
playable2.scaleY = 1.5 -- 102
playable2:play("idle",true) -- 102
mirror:addChild(playable2) -- 102
local playable3 = Playable("spine:dataotie") -- 103
playable3.x = mirror.width*0.5 + 852 -- 103
playable3.y = 60 -- 103
playable3.scaleX = 1.5 -- 103
playable3.scaleY = 1.5 -- 103
playable3:play("idle",true) -- 103
mirror:addChild(playable3) -- 103
do -- 103
	local _with_0 = mirror:grab(1, 1) -- 105
	_with_0:setColor(1, 1, Color(0x00ffffff)) -- 106
	_with_0:setColor(2, 1, Color(0x00ffffff)) -- 107
	_with_0:setColor(1, 2, Color(0x44ffffff)) -- 108
	_with_0:setColor(2, 2, Color(0x44ffffff)) -- 109
end -- 109
local node1 = Node() -- 112
node1.x = 852 -- 112
node1.y = 250 -- 112
bottomControl:addChild(node1) -- 112
local sprite2 = Sprite("shadow.png") -- 113
sprite2.scaleX = 8 -- 113
sprite2.scaleY = 8 -- 113
node1:addChild(sprite2) -- 113
local playable4 = Playable("spine:dataotie") -- 114
playable4.scaleX = 1.5 -- 114
playable4.scaleY = 1.5 -- 114
playable4:play("idle",true) -- 114
node1:addChild(playable4) -- 114
local label21 = Label("SourceHanSansCN-Regular",50) -- 115
label21.y = 1100 -- 115
label21.color3 = Color3(0x0) -- 115
label21.alignment = "Center" -- 115
label21.text = "狂暴的巨型饕餮" -- 115
node1:addChild(label21) -- 115
local sprite3 = Sprite("shadow.png") -- 119
sprite3.x = p1.x -- 119
sprite3.y = 250 -- 119
sprite3.scaleX = 1.5 -- 119
sprite3.scaleY = 1.5 -- 119
bottomControl:addChild(sprite3) -- 119
local playable5 = Playable("spine:moyu") -- 120
playable5.x = p1.x -- 120
playable5.y = 250 -- 120
playable5.scaleX = 1.5 -- 120
playable5.scaleY = 1.5 -- 120
playable5:play("idle",true) -- 120
bottomControl:addChild(playable5) -- 120
local lsdOS = LsdOS{} -- 123
item2:addChild(lsdOS) -- 123
local topControl = AlignNode{vAlign = "Top", hAlign = "Left"} -- 125
item2:addChild(topControl) -- 125
local item9 = BackButton{y = -45 - 33.5, x = 100 + 55} -- 126
topControl:addChild(item9) -- 126
local leftControl = AlignNode{vAlign = "Bottom", hAlign = "Left"} -- 129
item2:addChild(leftControl) -- 129
local item10 = Button{y = 70 + 41.5, x = 100 + 181.5, textBG = "SELECT MEMBER", text = "选择学员"} -- 130
leftControl:addChild(item10) -- 130
local rightControl = AlignNode{vAlign = "Bottom", hAlign = "Right"} -- 133
item2:addChild(rightControl) -- 133
local item11 = Button{y = 70 + 41.5, x = -100 - 181.5, textBG = "START TRAINING", text = "开始训练"} -- 134
rightControl:addChild(item11) -- 134
local trainingBox = AlignNode{vAlign = "Center", hAlign = "Left"} -- 138
item1:addChild(trainingBox) -- 138
local gearBox = AlignNode{vAlign = "Center", hAlign = "Right"} -- 142
item1:addChild(gearBox) -- 142
item1:slot("AlignLayout",function(w, h) -- 145
do -- 145
	local scale = h / H -- 147
	local ratio = w / h -- 148
	local extraScale = ratio / math.max(ratio, 1.9) -- 149
	local _list_0 = { -- 150
		figure, -- 150
		bottomControl -- 150
	} -- 150
	for _index_0 = 1, #_list_0 do -- 150
		local item = _list_0[_index_0] -- 150
		item.scaleX = scale * extraScale -- 151
		item.scaleY = scale * extraScale -- 152
	end -- 152
	local _list_1 = { -- 153
		bg, -- 153
		lsdOS, -- 153
		topControl, -- 153
		leftControl, -- 153
		rightControl, -- 153
		trainingBox, -- 153
		gearBox -- 153
	} -- 153
	for _index_0 = 1, #_list_1 do -- 153
		local item = _list_1[_index_0] -- 153
		item.scaleX = scale -- 154
		item.scaleY = scale -- 155
	end -- 155
end -- 155
end) -- 146
return item1 -- 146
end