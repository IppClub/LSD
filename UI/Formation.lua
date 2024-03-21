-- [xml]: UI/Formation.xml
local AlignNode = require("UI.Control.Basic.AlignNode") -- 2
local FormationRole = require("UI.FormationRole") -- 3
local GearBox = require("UI.GearBox") -- 4
local LsdOS = require("UI.LsdOS") -- 5
local Button = require("UI.Button") -- 6
local BackButton = require("UI.BackButton") -- 7
local FormationSlot = require("UI.FormationSlot") -- 8
local RoleSelect = require("UI.RoleSelect") -- 9
local ScrollArea = require("UI.Control.Basic.ScrollArea") -- 10
local RoleTab = require("UI.RoleTab") -- 11
local H <const> = 1563 -- 14
return function(args) -- 1
local _ENV = Dora(args) -- 1
local formation = AlignNode{isRoot = true, inUI = true} -- 15
local item1 = AlignNode{alignHeight = "h", alignWidth = "3258 * math.min(h / 1563, w / 3258)", vAlign = "Center", hAlign = "Center"} -- 16
formation:addChild(item1) -- 16
local bg = AlignNode{vAlign = "Center", hAlign = "Center"} -- 18
item1:addChild(bg) -- 18
local playable1 = Playable("bone:lsdOSBack") -- 19
bg:addChild(playable1) -- 19
local logo = playable1:getChildByTag("logo") -- 20
logo.visible = false -- 20
local formation_head_line = playable1:getChildByTag("formation_head_line") -- 21
local title = Label("SourceHanSansCN-Regular",50) -- 22
title.anchor = Vec2(title.anchor.x,0) -- 22
title.x = 1333 -- 22
title.y = -8 -- 22
title.color3 = Color3(0xffffff) -- 22
title.alignment = "Center" -- 22
title.spacing = 20 -- 22
title.text = "2-3地底的喧嚣" -- 22
formation_head_line:addChild(title) -- 22
local figure = AlignNode{vAlign = "Center", hAlign = "Center"} -- 30
item1:addChild(figure) -- 30
local menu = Menu() -- 31
menu.y = 100 -- 31
menu.visible = true -- 31
menu.size = Size(2721,1074) -- 31
figure:addChild(menu) -- 31
formation.menu = menu -- 31
local p1 = FormationRole{cap = true, editing = false, role = "charM"} -- 32
menu:addChild(p1) -- 32
local p2 = FormationRole{editing = false, role = "moling"} -- 33
menu:addChild(p2) -- 33
p2:slot("Tapped",function() -- 34
formation.menu.visible = false -- 36
formation.shadow.visible = false -- 37
formation.selection.visible = true -- 38
end) -- 38
local p3 = FormationRole{editing = false, role = "moyu"} -- 42
menu:addChild(p3) -- 42
local p4 = FormationRole{editing = false, role = "villywan"} -- 43
menu:addChild(p4) -- 43
local p5 = FormationRole{editing = false, role = "liyena"} -- 44
menu:addChild(p5) -- 44
menu:alignItems(28.5) -- 45
local selection = Node() -- 47
selection.visible = false -- 47
figure:addChild(selection) -- 47
formation.selection = selection -- 47
local teamMenu = Menu() -- 48
teamMenu.y = 446 -- 48
teamMenu.size = Size(2721,382) -- 48
selection:addChild(teamMenu) -- 48
local item2 = FormationSlot{} -- 49
teamMenu:addChild(item2) -- 49
local item3 = FormationSlot{} -- 50
teamMenu:addChild(item3) -- 50
item3:slot("Tapped",function() -- 51
formation.menu.visible = true -- 53
formation.shadow.visible = true -- 54
formation.selection.visible = false -- 55
end) -- 55
local item4 = FormationSlot{} -- 59
teamMenu:addChild(item4) -- 59
local item5 = FormationSlot{} -- 60
teamMenu:addChild(item5) -- 60
local item6 = FormationSlot{} -- 61
teamMenu:addChild(item6) -- 61
teamMenu:alignItems(28.5) -- 62
local charMenu = ScrollArea{scrollBar = false, paddingX = 0, y = -263.25} -- 64
selection:addChild(charMenu) -- 64
local view = charMenu.view -- 65
local item7 = RoleSelect{vacant = true} -- 66
view:addChild(item7) -- 66
local item8 = RoleSelect{} -- 67
view:addChild(item8) -- 67
local item9 = RoleSelect{locked = true} -- 68
view:addChild(item9) -- 68
local item10 = RoleSelect{selected = true} -- 69
view:addChild(item10) -- 69
local item11 = RoleSelect{} -- 70
view:addChild(item11) -- 70
local item12 = RoleSelect{} -- 71
view:addChild(item12) -- 71
local item13 = RoleSelect{} -- 72
view:addChild(item13) -- 72
local item14 = RoleSelect{} -- 73
view:addChild(item14) -- 73
local item15 = RoleTab{y = 240, x = -1375} -- 76
selection:addChild(item15) -- 76
local bottomControl = AlignNode{vAlign = "Bottom", hAlign = "Center"} -- 79
item1:addChild(bottomControl) -- 79
local shadow = Node() -- 80
shadow.visible = true -- 80
bottomControl:addChild(shadow) -- 80
formation.shadow = shadow -- 80
local mirror = Node() -- 81
mirror.anchor = Vec2(mirror.anchor.x,1) -- 81
mirror.scaleY = -1 -- 81
mirror.size = Size(2721,300) -- 81
shadow:addChild(mirror) -- 81
local sprite1 = Sprite("box2.png") -- 82
sprite1.x = p1.x - 150 -- 82
sprite1.y = 100 -- 82
mirror:addChild(sprite1) -- 82
local sprite2 = Sprite("box1.png") -- 83
sprite2.x = p1.x - 150 -- 83
sprite2.y = 170 -- 83
mirror:addChild(sprite2) -- 83
local sprite3 = Sprite("box2.png") -- 84
sprite3.x = p1.x + 150 -- 84
sprite3.y = 100 -- 84
sprite3.scaleX = -1 -- 84
mirror:addChild(sprite3) -- 84
local sprite4 = Sprite("box1.png") -- 85
sprite4.x = p1.x + 150 -- 85
sprite4.y = 170 -- 85
sprite4.scaleX = -1 -- 85
mirror:addChild(sprite4) -- 85
local sprite5 = Sprite("box2.png") -- 86
sprite5.x = p2.x - 150 -- 86
sprite5.y = 100 -- 86
mirror:addChild(sprite5) -- 86
local sprite6 = Sprite("box1.png") -- 87
sprite6.x = p2.x - 150 -- 87
sprite6.y = 170 -- 87
mirror:addChild(sprite6) -- 87
local sprite7 = Sprite("box2.png") -- 88
sprite7.x = p2.x + 150 -- 88
sprite7.y = 100 -- 88
sprite7.scaleX = -1 -- 88
mirror:addChild(sprite7) -- 88
local sprite8 = Sprite("box1.png") -- 89
sprite8.x = p2.x + 150 -- 89
sprite8.y = 170 -- 89
sprite8.scaleX = -1 -- 89
mirror:addChild(sprite8) -- 89
local sprite9 = Sprite("box2.png") -- 90
sprite9.x = p3.x - 150 -- 90
sprite9.y = 100 -- 90
mirror:addChild(sprite9) -- 90
local sprite10 = Sprite("box1.png") -- 91
sprite10.x = p3.x - 150 -- 91
sprite10.y = 170 -- 91
mirror:addChild(sprite10) -- 91
local sprite11 = Sprite("box2.png") -- 92
sprite11.x = p3.x + 150 -- 92
sprite11.y = 100 -- 92
sprite11.scaleX = -1 -- 92
mirror:addChild(sprite11) -- 92
local sprite12 = Sprite("box1.png") -- 93
sprite12.x = p3.x + 150 -- 93
sprite12.y = 170 -- 93
sprite12.scaleX = -1 -- 93
mirror:addChild(sprite12) -- 93
local sprite13 = Sprite("box2.png") -- 94
sprite13.x = p4.x - 150 -- 94
sprite13.y = 100 -- 94
mirror:addChild(sprite13) -- 94
local sprite14 = Sprite("box1.png") -- 95
sprite14.x = p4.x - 150 -- 95
sprite14.y = 170 -- 95
mirror:addChild(sprite14) -- 95
local sprite15 = Sprite("box2.png") -- 96
sprite15.x = p4.x + 150 -- 96
sprite15.y = 100 -- 96
sprite15.scaleX = -1 -- 96
mirror:addChild(sprite15) -- 96
local sprite16 = Sprite("box1.png") -- 97
sprite16.x = p4.x + 150 -- 97
sprite16.y = 170 -- 97
sprite16.scaleX = -1 -- 97
mirror:addChild(sprite16) -- 97
local sprite17 = Sprite("box2.png") -- 98
sprite17.x = p5.x - 150 -- 98
sprite17.y = 100 -- 98
mirror:addChild(sprite17) -- 98
local sprite18 = Sprite("box1.png") -- 99
sprite18.x = p5.x - 150 -- 99
sprite18.y = 170 -- 99
mirror:addChild(sprite18) -- 99
local sprite19 = Sprite("box2.png") -- 100
sprite19.x = p5.x + 150 -- 100
sprite19.y = 100 -- 100
sprite19.scaleX = -1 -- 100
mirror:addChild(sprite19) -- 100
local sprite20 = Sprite("box1.png") -- 101
sprite20.x = p5.x + 150 -- 101
sprite20.y = 170 -- 101
sprite20.scaleX = -1 -- 101
mirror:addChild(sprite20) -- 101
local playable2 = Playable("spine:charM") -- 102
playable2.x = p1.x -- 102
playable2.y = 60 -- 102
playable2.scaleX = 1.5 -- 102
playable2.scaleY = 1.5 -- 102
playable2:play("idle",true) -- 102
mirror:addChild(playable2) -- 102
local playable3 = Playable("spine:moling") -- 103
playable3.x = p2.x -- 103
playable3.y = 60 -- 103
playable3.scaleX = 1.5 -- 103
playable3.scaleY = 1.5 -- 103
playable3:play("idle",true) -- 103
mirror:addChild(playable3) -- 103
local playable4 = Playable("spine:moyu") -- 104
playable4.x = p3.x -- 104
playable4.y = 60 -- 104
playable4.scaleX = 1.5 -- 104
playable4.scaleY = 1.5 -- 104
playable4:play("idle",true) -- 104
mirror:addChild(playable4) -- 104
local playable5 = Playable("spine:villywan") -- 105
playable5.x = p4.x -- 105
playable5.y = 60 -- 105
playable5.scaleX = 1.5 -- 105
playable5.scaleY = 1.5 -- 105
playable5:play("idle",true) -- 105
mirror:addChild(playable5) -- 105
local playable6 = Playable("spine:liyena") -- 106
playable6.x = p5.x -- 106
playable6.y = 60 -- 106
playable6.scaleX = 1.5 -- 106
playable6.scaleY = 1.5 -- 106
playable6.fliped = true -- 106
playable6:play("idle",true) -- 106
mirror:addChild(playable6) -- 106
do -- 106
	local _with_0 = mirror:grab(1, 1) -- 108
	_with_0:setColor(1, 1, Color(0x00ffffff)) -- 109
	_with_0:setColor(2, 1, Color(0x00ffffff)) -- 110
	_with_0:setColor(1, 2, Color(0x44ffffff)) -- 111
	_with_0:setColor(2, 2, Color(0x44ffffff)) -- 112
end -- 112
local node1 = Node() -- 115
node1.y = 250 -- 115
node1.width = 2721 -- 115
shadow:addChild(node1) -- 115
local sprite21 = Sprite("shadow.png") -- 116
sprite21.x = p1.x - 150 -- 116
sprite21.y = 50 -- 116
sprite21.scaleX = 1.5 -- 116
sprite21.scaleY = 1.5 -- 116
node1:addChild(sprite21) -- 116
local sprite22 = Sprite("box2.png") -- 117
sprite22.x = p1.x - 150 -- 117
sprite22.y = 90 -- 117
node1:addChild(sprite22) -- 117
local sprite23 = Sprite("box1.png") -- 118
sprite23.x = p1.x - 150 -- 118
sprite23.y = 160 -- 118
node1:addChild(sprite23) -- 118
local sprite24 = Sprite("shadow.png") -- 119
sprite24.x = p1.x + 150 -- 119
sprite24.y = 50 -- 119
sprite24.scaleX = 1.5 -- 119
sprite24.scaleY = 1.5 -- 119
node1:addChild(sprite24) -- 119
local sprite25 = Sprite("box2.png") -- 120
sprite25.x = p1.x + 150 -- 120
sprite25.y = 90 -- 120
sprite25.scaleX = -1 -- 120
node1:addChild(sprite25) -- 120
local sprite26 = Sprite("box1.png") -- 121
sprite26.x = p1.x + 150 -- 121
sprite26.y = 160 -- 121
sprite26.scaleX = -1 -- 121
node1:addChild(sprite26) -- 121
local sprite27 = Sprite("shadow.png") -- 122
sprite27.x = p2.x - 150 -- 122
sprite27.y = 50 -- 122
sprite27.scaleX = 1.5 -- 122
sprite27.scaleY = 1.5 -- 122
node1:addChild(sprite27) -- 122
local sprite28 = Sprite("box2.png") -- 123
sprite28.x = p2.x - 150 -- 123
sprite28.y = 90 -- 123
node1:addChild(sprite28) -- 123
local sprite29 = Sprite("box1.png") -- 124
sprite29.x = p2.x - 150 -- 124
sprite29.y = 160 -- 124
node1:addChild(sprite29) -- 124
local sprite30 = Sprite("shadow.png") -- 125
sprite30.x = p2.x + 150 -- 125
sprite30.y = 50 -- 125
sprite30.scaleX = 1.5 -- 125
sprite30.scaleY = 1.5 -- 125
node1:addChild(sprite30) -- 125
local sprite31 = Sprite("box2.png") -- 126
sprite31.x = p2.x + 150 -- 126
sprite31.y = 90 -- 126
sprite31.scaleX = -1 -- 126
node1:addChild(sprite31) -- 126
local sprite32 = Sprite("box1.png") -- 127
sprite32.x = p2.x + 150 -- 127
sprite32.y = 160 -- 127
sprite32.scaleX = -1 -- 127
node1:addChild(sprite32) -- 127
local sprite33 = Sprite("shadow.png") -- 128
sprite33.x = p3.x - 150 -- 128
sprite33.y = 50 -- 128
sprite33.scaleX = 1.5 -- 128
sprite33.scaleY = 1.5 -- 128
node1:addChild(sprite33) -- 128
local sprite34 = Sprite("box2.png") -- 129
sprite34.x = p3.x - 150 -- 129
sprite34.y = 90 -- 129
node1:addChild(sprite34) -- 129
local sprite35 = Sprite("box1.png") -- 130
sprite35.x = p3.x - 150 -- 130
sprite35.y = 160 -- 130
node1:addChild(sprite35) -- 130
local sprite36 = Sprite("shadow.png") -- 131
sprite36.x = p3.x + 150 -- 131
sprite36.y = 50 -- 131
sprite36.scaleX = 1.5 -- 131
sprite36.scaleY = 1.5 -- 131
node1:addChild(sprite36) -- 131
local sprite37 = Sprite("box2.png") -- 132
sprite37.x = p3.x + 150 -- 132
sprite37.y = 90 -- 132
sprite37.scaleX = -1 -- 132
node1:addChild(sprite37) -- 132
local sprite38 = Sprite("box1.png") -- 133
sprite38.x = p3.x + 150 -- 133
sprite38.y = 160 -- 133
sprite38.scaleX = -1 -- 133
node1:addChild(sprite38) -- 133
local sprite39 = Sprite("shadow.png") -- 134
sprite39.x = p4.x - 150 -- 134
sprite39.y = 50 -- 134
sprite39.scaleX = 1.5 -- 134
sprite39.scaleY = 1.5 -- 134
node1:addChild(sprite39) -- 134
local sprite40 = Sprite("box2.png") -- 135
sprite40.x = p4.x - 150 -- 135
sprite40.y = 90 -- 135
node1:addChild(sprite40) -- 135
local sprite41 = Sprite("box1.png") -- 136
sprite41.x = p4.x - 150 -- 136
sprite41.y = 160 -- 136
node1:addChild(sprite41) -- 136
local sprite42 = Sprite("shadow.png") -- 137
sprite42.x = p4.x + 150 -- 137
sprite42.y = 50 -- 137
sprite42.scaleX = 1.5 -- 137
sprite42.scaleY = 1.5 -- 137
node1:addChild(sprite42) -- 137
local sprite43 = Sprite("box2.png") -- 138
sprite43.x = p4.x + 150 -- 138
sprite43.y = 90 -- 138
sprite43.scaleX = -1 -- 138
node1:addChild(sprite43) -- 138
local sprite44 = Sprite("box1.png") -- 139
sprite44.x = p4.x + 150 -- 139
sprite44.y = 160 -- 139
sprite44.scaleX = -1 -- 139
node1:addChild(sprite44) -- 139
local sprite45 = Sprite("shadow.png") -- 140
sprite45.x = p5.x - 150 -- 140
sprite45.y = 50 -- 140
sprite45.scaleX = 1.5 -- 140
sprite45.scaleY = 1.5 -- 140
node1:addChild(sprite45) -- 140
local sprite46 = Sprite("box2.png") -- 141
sprite46.x = p5.x - 150 -- 141
sprite46.y = 90 -- 141
node1:addChild(sprite46) -- 141
local sprite47 = Sprite("box1.png") -- 142
sprite47.x = p5.x - 150 -- 142
sprite47.y = 160 -- 142
node1:addChild(sprite47) -- 142
local sprite48 = Sprite("shadow.png") -- 143
sprite48.x = p5.x + 150 -- 143
sprite48.y = 50 -- 143
sprite48.scaleX = 1.5 -- 143
sprite48.scaleY = 1.5 -- 143
node1:addChild(sprite48) -- 143
local sprite49 = Sprite("box2.png") -- 144
sprite49.x = p5.x + 150 -- 144
sprite49.y = 90 -- 144
sprite49.scaleX = -1 -- 144
node1:addChild(sprite49) -- 144
local sprite50 = Sprite("box1.png") -- 145
sprite50.x = p5.x + 150 -- 145
sprite50.y = 160 -- 145
sprite50.scaleX = -1 -- 145
node1:addChild(sprite50) -- 145
local sprite51 = Sprite("shadow.png") -- 146
sprite51.x = p1.x -- 146
sprite51.scaleX = 1.5 -- 146
sprite51.scaleY = 1.5 -- 146
node1:addChild(sprite51) -- 146
local sprite52 = Sprite("shadow.png") -- 147
sprite52.x = p2.x -- 147
sprite52.scaleX = 1.5 -- 147
sprite52.scaleY = 1.5 -- 147
node1:addChild(sprite52) -- 147
local sprite53 = Sprite("shadow.png") -- 148
sprite53.x = p3.x -- 148
sprite53.scaleX = 1.5 -- 148
sprite53.scaleY = 1.5 -- 148
node1:addChild(sprite53) -- 148
local sprite54 = Sprite("shadow.png") -- 149
sprite54.x = p4.x -- 149
sprite54.scaleX = 1.5 -- 149
sprite54.scaleY = 1.5 -- 149
node1:addChild(sprite54) -- 149
local sprite55 = Sprite("shadow.png") -- 150
sprite55.x = p5.x -- 150
sprite55.scaleX = 1.5 -- 150
sprite55.scaleY = 1.5 -- 150
node1:addChild(sprite55) -- 150
local playable7 = Playable("spine:charM") -- 151
playable7.x = p1.x -- 151
playable7.scaleX = 1.5 -- 151
playable7.scaleY = 1.5 -- 151
playable7:play("idle",true) -- 151
node1:addChild(playable7) -- 151
local playable8 = Playable("spine:moling") -- 152
playable8.x = p2.x -- 152
playable8.scaleX = 1.5 -- 152
playable8.scaleY = 1.5 -- 152
playable8:play("idle",true) -- 152
node1:addChild(playable8) -- 152
local playable9 = Playable("spine:moyu") -- 153
playable9.x = p3.x -- 153
playable9.scaleX = 1.5 -- 153
playable9.scaleY = 1.5 -- 153
playable9:play("idle",true) -- 153
node1:addChild(playable9) -- 153
local playable10 = Playable("spine:villywan") -- 154
playable10.x = p4.x -- 154
playable10.scaleX = 1.5 -- 154
playable10.scaleY = 1.5 -- 154
playable10:play("idle",true) -- 154
node1:addChild(playable10) -- 154
local playable11 = Playable("spine:liyena") -- 155
playable11.x = p5.x -- 155
playable11.scaleX = 1.5 -- 155
playable11.scaleY = 1.5 -- 155
playable11.fliped = true -- 155
playable11:play("idle",true) -- 155
node1:addChild(playable11) -- 155
local lsdOS = LsdOS{} -- 160
item1:addChild(lsdOS) -- 160
local topControl = AlignNode{vAlign = "Top", hAlign = "Left"} -- 162
item1:addChild(topControl) -- 162
local item16 = BackButton{y = -78.5, x = 155} -- 163
topControl:addChild(item16) -- 163
local leftControl = AlignNode{vAlign = "Bottom", hAlign = "Left"} -- 166
item1:addChild(leftControl) -- 166
local item17 = Button{y = 111.5, x = 281.5, textBG = "FORMATION", text = "已有编队"} -- 167
leftControl:addChild(item17) -- 167
local rightControl = AlignNode{vAlign = "Bottom", hAlign = "Right"} -- 170
item1:addChild(rightControl) -- 170
local item18 = Button{y = 111.5, x = -281.5, textBG = "START BATTLE", text = "开始作战"} -- 171
rightControl:addChild(item18) -- 171
local leftBox = AlignNode{vAlign = "Center", hAlign = "Left"} -- 175
formation:addChild(leftBox) -- 175
local rightBox = AlignNode{vAlign = "Center", hAlign = "Right"} -- 180
formation:addChild(rightBox) -- 180
local item19 = GearBox{right = true} -- 181
rightBox:addChild(item19) -- 181
formation:slot("AlignLayout",function(w, h) -- 183
do -- 183
	local scale = h / H -- 185
	local ratio = w / h -- 186
	local extraScale = ratio / math.max(ratio, 1.9) -- 187
	local _list_0 = { -- 188
		figure, -- 188
		bottomControl -- 188
	} -- 188
	for _index_0 = 1, #_list_0 do -- 188
		local item = _list_0[_index_0] -- 188
		item.scaleX = scale * extraScale -- 189
		item.scaleY = scale * extraScale -- 190
	end -- 190
	local _list_1 = { -- 191
		bg, -- 191
		lsdOS, -- 191
		topControl, -- 191
		leftControl, -- 191
		rightControl, -- 191
		leftBox, -- 191
		rightBox -- 191
	} -- 191
	for _index_0 = 1, #_list_1 do -- 191
		local item = _list_1[_index_0] -- 191
		item.scaleX = scale -- 192
		item.scaleY = scale -- 193
	end -- 193
	charMenu:adjustSizeWithAlign("Auto", 27, Size(2715, 1036.5)) -- 194
end -- 194
end) -- 184
return formation -- 184
end