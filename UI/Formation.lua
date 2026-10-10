-- [xml]: UI/Formation.xml
local AlignNode = require("UI.Control.Basic.AlignNode") -- 2
local SolidRect = require("UI.View.Shape.SolidRect") -- 3
local FormationRole = require("UI.FormationRole") -- 4
local GearBox = require("UI.GearBox") -- 5
local LsdOS = require("UI.LsdOS") -- 6
local Button = require("UI.Button") -- 7
local BackButton = require("UI.BackButton") -- 8
local FormationSlot = require("UI.FormationSlot") -- 9
local RoleSelect = require("UI.RoleSelect") -- 10
local ScrollArea = require("UI.Control.Basic.ScrollArea") -- 11
local RoleTab = require("UI.RoleTab") -- 12
local H <const> = 1563 -- 15
return function(args) -- 1
local _ENV = Dora(args) -- 1
local formation = AlignNode{isRoot = true, inUI = true} -- 16
local item1 = AlignNode{alignHeight = "h", alignWidth = "3258 * math.min(h / 1563, w / 3258)", vAlign = "Center", hAlign = "Center"} -- 17
formation:addChild(item1) -- 17
local bg = AlignNode{vAlign = "Center", hAlign = "Center"} -- 19
item1:addChild(bg) -- 19
local playable1 = Playable("bone:lsdOSBack") -- 20
bg:addChild(playable1) -- 20
local logo = playable1:getChildByTag("logo") -- 21
logo.visible = false -- 21
local formation_head_line = playable1:getChildByTag("formation_head_line") -- 22
local title = Label("SourceHanSansCN-Regular",50) -- 23
title.anchor = Vec2(title.anchor.x,0) -- 23
title.x = 1333 -- 23
title.y = -8 -- 23
title.color3 = Color3(0xffffff) -- 23
title.alignment = "Center" -- 23
title.spacing = 20 -- 23
title.text = missionTitle or '2-3地底的喧嚣' -- 23
formation_head_line:addChild(title) -- 23
if missionMode then -- 30
local figure = AlignNode{vAlign = "Center", hAlign = "Center"} -- 31
item1:addChild(figure) -- 31
formation.figure = figure -- 31
local squad = Menu() -- 32
squad.y = 100 -- 32
squad.size = Size(secondLearner and 1700 or 1150,1074) -- 32
figure:addChild(squad) -- 32
local mentorCard = FormationRole{cap = true, editing = false, role = mentorRole or 'charM'} -- 33
squad:addChild(mentorCard) -- 33
formation.mentorCard = mentorCard -- 33
if learnerIncluded then -- 34
local learnerCard = FormationRole{editing = false, role = "ninilite"} -- 35
squad:addChild(learnerCard) -- 35
formation.learnerCard = learnerCard -- 35
else -- 36
local learnerCard = Node() -- 37
learnerCard.size = Size(510,1017) -- 37
learnerCard.touchEnabled = true -- 37
squad:addChild(learnerCard) -- 37
formation.learnerCard = learnerCard -- 37
local item2 = FormationSlot{y = 508.5, x = 255} -- 38
learnerCard:addChild(item2) -- 38
end -- 40
if secondLearner then -- 41
if secondIncluded then -- 42
local secondCard = FormationRole{editing = false, role = "wuyun"} -- 43
squad:addChild(secondCard) -- 43
formation.secondCard = secondCard -- 43
else -- 44
local secondCard = Node() -- 45
secondCard.size = Size(510,1017) -- 45
secondCard.touchEnabled = true -- 45
squad:addChild(secondCard) -- 45
formation.secondCard = secondCard -- 45
local item3 = FormationSlot{y = 508.5, x = 255} -- 45
secondCard:addChild(item3) -- 45
end -- 46
end -- 47
squad:alignItemsHorizontally(28.5) -- 48
local item4 = SolidRect{color = 0xb2000000, width = 2600, y = secondLearner and -675 or -635, height = secondLearner and 230 or 190, x = -1300} -- 50
figure:addChild(item4) -- 50
local status = Label("SourceHanSansCN-Regular",40) -- 51
status.y = secondLearner and -550 or -535 -- 51
status.alignment = "Center" -- 51
status.textWidth = 2600 -- 51
status.text = squadStatus or '' -- 51
figure:addChild(status) -- 51
formation.status = status -- 51
local bottomControl = AlignNode{vAlign = "Bottom", hAlign = "Center"} -- 53
item1:addChild(bottomControl) -- 53
formation.bottomControl = bottomControl -- 53
else -- 54
local figure = AlignNode{vAlign = "Center", hAlign = "Center"} -- 56
item1:addChild(figure) -- 56
formation.figure = figure -- 56
local menu = Menu() -- 57
menu.y = 100 -- 57
menu.visible = true -- 57
menu.size = Size(2721,1074) -- 57
figure:addChild(menu) -- 57
formation.menu = menu -- 57
local p1 = FormationRole{cap = true, editing = false, role = "charM"} -- 58
menu:addChild(p1) -- 58
local p2 = FormationRole{editing = false, role = "moling"} -- 59
menu:addChild(p2) -- 59
p2:slot("Tapped",function() -- 60
formation.menu.visible = false -- 62
formation.shadow.visible = false -- 63
formation.selection.visible = true -- 64
end) -- 64
local p3 = FormationRole{editing = false, role = "moyu"} -- 68
menu:addChild(p3) -- 68
local p4 = FormationRole{editing = false, role = "villywan"} -- 69
menu:addChild(p4) -- 69
local p5 = FormationRole{editing = false, role = "liyena"} -- 70
menu:addChild(p5) -- 70
menu:alignItems(28.5) -- 71
local selection = Node() -- 73
selection.visible = false -- 73
figure:addChild(selection) -- 73
formation.selection = selection -- 73
local teamMenu = Menu() -- 74
teamMenu.y = 446 -- 74
teamMenu.size = Size(2721,382) -- 74
selection:addChild(teamMenu) -- 74
local item5 = FormationSlot{} -- 75
teamMenu:addChild(item5) -- 75
local item6 = FormationSlot{} -- 76
teamMenu:addChild(item6) -- 76
item6:slot("Tapped",function() -- 77
formation.menu.visible = true -- 79
formation.shadow.visible = true -- 80
formation.selection.visible = false -- 81
end) -- 81
local item7 = FormationSlot{} -- 85
teamMenu:addChild(item7) -- 85
local item8 = FormationSlot{} -- 86
teamMenu:addChild(item8) -- 86
local item9 = FormationSlot{} -- 87
teamMenu:addChild(item9) -- 87
teamMenu:alignItems(28.5) -- 88
local charMenu = ScrollArea{scrollBar = false, paddingX = 0, y = -263.25} -- 90
selection:addChild(charMenu) -- 90
formation.charMenu = charMenu -- 90
local view = charMenu.view -- 91
local item10 = RoleSelect{vacant = true} -- 92
view:addChild(item10) -- 92
local item11 = RoleSelect{} -- 93
view:addChild(item11) -- 93
local item12 = RoleSelect{locked = true} -- 94
view:addChild(item12) -- 94
local item13 = RoleSelect{selected = true} -- 95
view:addChild(item13) -- 95
local item14 = RoleSelect{} -- 96
view:addChild(item14) -- 96
local item15 = RoleSelect{} -- 97
view:addChild(item15) -- 97
local item16 = RoleSelect{} -- 98
view:addChild(item16) -- 98
local item17 = RoleSelect{} -- 99
view:addChild(item17) -- 99
local item18 = RoleTab{y = 240, x = -1375} -- 102
selection:addChild(item18) -- 102
local bottomControl = AlignNode{vAlign = "Bottom", hAlign = "Center"} -- 105
item1:addChild(bottomControl) -- 105
formation.bottomControl = bottomControl -- 105
local shadow = Node() -- 106
shadow.visible = true -- 106
bottomControl:addChild(shadow) -- 106
formation.shadow = shadow -- 106
local mirror = Node() -- 107
mirror.anchor = Vec2(mirror.anchor.x,1) -- 107
mirror.scaleY = -1 -- 107
mirror.size = Size(2721,300) -- 107
shadow:addChild(mirror) -- 107
local sprite1 = Sprite("box2.png") -- 108
sprite1.x = p1.x - 150 -- 108
sprite1.y = 100 -- 108
mirror:addChild(sprite1) -- 108
local sprite2 = Sprite("box1.png") -- 109
sprite2.x = p1.x - 150 -- 109
sprite2.y = 170 -- 109
mirror:addChild(sprite2) -- 109
local sprite3 = Sprite("box2.png") -- 110
sprite3.x = p1.x + 150 -- 110
sprite3.y = 100 -- 110
sprite3.scaleX = -1 -- 110
mirror:addChild(sprite3) -- 110
local sprite4 = Sprite("box1.png") -- 111
sprite4.x = p1.x + 150 -- 111
sprite4.y = 170 -- 111
sprite4.scaleX = -1 -- 111
mirror:addChild(sprite4) -- 111
local sprite5 = Sprite("box2.png") -- 112
sprite5.x = p2.x - 150 -- 112
sprite5.y = 100 -- 112
mirror:addChild(sprite5) -- 112
local sprite6 = Sprite("box1.png") -- 113
sprite6.x = p2.x - 150 -- 113
sprite6.y = 170 -- 113
mirror:addChild(sprite6) -- 113
local sprite7 = Sprite("box2.png") -- 114
sprite7.x = p2.x + 150 -- 114
sprite7.y = 100 -- 114
sprite7.scaleX = -1 -- 114
mirror:addChild(sprite7) -- 114
local sprite8 = Sprite("box1.png") -- 115
sprite8.x = p2.x + 150 -- 115
sprite8.y = 170 -- 115
sprite8.scaleX = -1 -- 115
mirror:addChild(sprite8) -- 115
local sprite9 = Sprite("box2.png") -- 116
sprite9.x = p3.x - 150 -- 116
sprite9.y = 100 -- 116
mirror:addChild(sprite9) -- 116
local sprite10 = Sprite("box1.png") -- 117
sprite10.x = p3.x - 150 -- 117
sprite10.y = 170 -- 117
mirror:addChild(sprite10) -- 117
local sprite11 = Sprite("box2.png") -- 118
sprite11.x = p3.x + 150 -- 118
sprite11.y = 100 -- 118
sprite11.scaleX = -1 -- 118
mirror:addChild(sprite11) -- 118
local sprite12 = Sprite("box1.png") -- 119
sprite12.x = p3.x + 150 -- 119
sprite12.y = 170 -- 119
sprite12.scaleX = -1 -- 119
mirror:addChild(sprite12) -- 119
local sprite13 = Sprite("box2.png") -- 120
sprite13.x = p4.x - 150 -- 120
sprite13.y = 100 -- 120
mirror:addChild(sprite13) -- 120
local sprite14 = Sprite("box1.png") -- 121
sprite14.x = p4.x - 150 -- 121
sprite14.y = 170 -- 121
mirror:addChild(sprite14) -- 121
local sprite15 = Sprite("box2.png") -- 122
sprite15.x = p4.x + 150 -- 122
sprite15.y = 100 -- 122
sprite15.scaleX = -1 -- 122
mirror:addChild(sprite15) -- 122
local sprite16 = Sprite("box1.png") -- 123
sprite16.x = p4.x + 150 -- 123
sprite16.y = 170 -- 123
sprite16.scaleX = -1 -- 123
mirror:addChild(sprite16) -- 123
local sprite17 = Sprite("box2.png") -- 124
sprite17.x = p5.x - 150 -- 124
sprite17.y = 100 -- 124
mirror:addChild(sprite17) -- 124
local sprite18 = Sprite("box1.png") -- 125
sprite18.x = p5.x - 150 -- 125
sprite18.y = 170 -- 125
mirror:addChild(sprite18) -- 125
local sprite19 = Sprite("box2.png") -- 126
sprite19.x = p5.x + 150 -- 126
sprite19.y = 100 -- 126
sprite19.scaleX = -1 -- 126
mirror:addChild(sprite19) -- 126
local sprite20 = Sprite("box1.png") -- 127
sprite20.x = p5.x + 150 -- 127
sprite20.y = 170 -- 127
sprite20.scaleX = -1 -- 127
mirror:addChild(sprite20) -- 127
local playable2 = Playable("spine:charM") -- 128
playable2.x = p1.x -- 128
playable2.y = 60 -- 128
playable2.scaleX = 1.5 -- 128
playable2.scaleY = 1.5 -- 128
playable2:play("idle",true) -- 128
mirror:addChild(playable2) -- 128
local playable3 = Playable("spine:moling") -- 129
playable3.x = p2.x -- 129
playable3.y = 60 -- 129
playable3.scaleX = 1.5 -- 129
playable3.scaleY = 1.5 -- 129
playable3:play("idle",true) -- 129
mirror:addChild(playable3) -- 129
local playable4 = Playable("spine:moyu") -- 130
playable4.x = p3.x -- 130
playable4.y = 60 -- 130
playable4.scaleX = 1.5 -- 130
playable4.scaleY = 1.5 -- 130
playable4:play("idle",true) -- 130
mirror:addChild(playable4) -- 130
local playable5 = Playable("spine:villywan") -- 131
playable5.x = p4.x -- 131
playable5.y = 60 -- 131
playable5.scaleX = 1.5 -- 131
playable5.scaleY = 1.5 -- 131
playable5:play("idle",true) -- 131
mirror:addChild(playable5) -- 131
local playable6 = Playable("spine:liyena") -- 132
playable6.x = p5.x -- 132
playable6.y = 60 -- 132
playable6.scaleX = 1.5 -- 132
playable6.scaleY = 1.5 -- 132
playable6.fliped = true -- 132
playable6:play("idle",true) -- 132
mirror:addChild(playable6) -- 132
do -- 132
	local _with_0 = mirror:grab(1, 1) -- 134
	_with_0:setColor(1, 1, Color(0x00ffffff)) -- 135
	_with_0:setColor(2, 1, Color(0x00ffffff)) -- 136
	_with_0:setColor(1, 2, Color(0x44ffffff)) -- 137
	_with_0:setColor(2, 2, Color(0x44ffffff)) -- 138
end -- 132
local node1 = Node() -- 141
node1.y = 250 -- 141
node1.width = 2721 -- 141
shadow:addChild(node1) -- 141
local sprite21 = Sprite("shadow.png") -- 142
sprite21.x = p1.x - 150 -- 142
sprite21.y = 50 -- 142
sprite21.scaleX = 1.5 -- 142
sprite21.scaleY = 1.5 -- 142
node1:addChild(sprite21) -- 142
local sprite22 = Sprite("box2.png") -- 143
sprite22.x = p1.x - 150 -- 143
sprite22.y = 90 -- 143
node1:addChild(sprite22) -- 143
local sprite23 = Sprite("box1.png") -- 144
sprite23.x = p1.x - 150 -- 144
sprite23.y = 160 -- 144
node1:addChild(sprite23) -- 144
local sprite24 = Sprite("shadow.png") -- 145
sprite24.x = p1.x + 150 -- 145
sprite24.y = 50 -- 145
sprite24.scaleX = 1.5 -- 145
sprite24.scaleY = 1.5 -- 145
node1:addChild(sprite24) -- 145
local sprite25 = Sprite("box2.png") -- 146
sprite25.x = p1.x + 150 -- 146
sprite25.y = 90 -- 146
sprite25.scaleX = -1 -- 146
node1:addChild(sprite25) -- 146
local sprite26 = Sprite("box1.png") -- 147
sprite26.x = p1.x + 150 -- 147
sprite26.y = 160 -- 147
sprite26.scaleX = -1 -- 147
node1:addChild(sprite26) -- 147
local sprite27 = Sprite("shadow.png") -- 148
sprite27.x = p2.x - 150 -- 148
sprite27.y = 50 -- 148
sprite27.scaleX = 1.5 -- 148
sprite27.scaleY = 1.5 -- 148
node1:addChild(sprite27) -- 148
local sprite28 = Sprite("box2.png") -- 149
sprite28.x = p2.x - 150 -- 149
sprite28.y = 90 -- 149
node1:addChild(sprite28) -- 149
local sprite29 = Sprite("box1.png") -- 150
sprite29.x = p2.x - 150 -- 150
sprite29.y = 160 -- 150
node1:addChild(sprite29) -- 150
local sprite30 = Sprite("shadow.png") -- 151
sprite30.x = p2.x + 150 -- 151
sprite30.y = 50 -- 151
sprite30.scaleX = 1.5 -- 151
sprite30.scaleY = 1.5 -- 151
node1:addChild(sprite30) -- 151
local sprite31 = Sprite("box2.png") -- 152
sprite31.x = p2.x + 150 -- 152
sprite31.y = 90 -- 152
sprite31.scaleX = -1 -- 152
node1:addChild(sprite31) -- 152
local sprite32 = Sprite("box1.png") -- 153
sprite32.x = p2.x + 150 -- 153
sprite32.y = 160 -- 153
sprite32.scaleX = -1 -- 153
node1:addChild(sprite32) -- 153
local sprite33 = Sprite("shadow.png") -- 154
sprite33.x = p3.x - 150 -- 154
sprite33.y = 50 -- 154
sprite33.scaleX = 1.5 -- 154
sprite33.scaleY = 1.5 -- 154
node1:addChild(sprite33) -- 154
local sprite34 = Sprite("box2.png") -- 155
sprite34.x = p3.x - 150 -- 155
sprite34.y = 90 -- 155
node1:addChild(sprite34) -- 155
local sprite35 = Sprite("box1.png") -- 156
sprite35.x = p3.x - 150 -- 156
sprite35.y = 160 -- 156
node1:addChild(sprite35) -- 156
local sprite36 = Sprite("shadow.png") -- 157
sprite36.x = p3.x + 150 -- 157
sprite36.y = 50 -- 157
sprite36.scaleX = 1.5 -- 157
sprite36.scaleY = 1.5 -- 157
node1:addChild(sprite36) -- 157
local sprite37 = Sprite("box2.png") -- 158
sprite37.x = p3.x + 150 -- 158
sprite37.y = 90 -- 158
sprite37.scaleX = -1 -- 158
node1:addChild(sprite37) -- 158
local sprite38 = Sprite("box1.png") -- 159
sprite38.x = p3.x + 150 -- 159
sprite38.y = 160 -- 159
sprite38.scaleX = -1 -- 159
node1:addChild(sprite38) -- 159
local sprite39 = Sprite("shadow.png") -- 160
sprite39.x = p4.x - 150 -- 160
sprite39.y = 50 -- 160
sprite39.scaleX = 1.5 -- 160
sprite39.scaleY = 1.5 -- 160
node1:addChild(sprite39) -- 160
local sprite40 = Sprite("box2.png") -- 161
sprite40.x = p4.x - 150 -- 161
sprite40.y = 90 -- 161
node1:addChild(sprite40) -- 161
local sprite41 = Sprite("box1.png") -- 162
sprite41.x = p4.x - 150 -- 162
sprite41.y = 160 -- 162
node1:addChild(sprite41) -- 162
local sprite42 = Sprite("shadow.png") -- 163
sprite42.x = p4.x + 150 -- 163
sprite42.y = 50 -- 163
sprite42.scaleX = 1.5 -- 163
sprite42.scaleY = 1.5 -- 163
node1:addChild(sprite42) -- 163
local sprite43 = Sprite("box2.png") -- 164
sprite43.x = p4.x + 150 -- 164
sprite43.y = 90 -- 164
sprite43.scaleX = -1 -- 164
node1:addChild(sprite43) -- 164
local sprite44 = Sprite("box1.png") -- 165
sprite44.x = p4.x + 150 -- 165
sprite44.y = 160 -- 165
sprite44.scaleX = -1 -- 165
node1:addChild(sprite44) -- 165
local sprite45 = Sprite("shadow.png") -- 166
sprite45.x = p5.x - 150 -- 166
sprite45.y = 50 -- 166
sprite45.scaleX = 1.5 -- 166
sprite45.scaleY = 1.5 -- 166
node1:addChild(sprite45) -- 166
local sprite46 = Sprite("box2.png") -- 167
sprite46.x = p5.x - 150 -- 167
sprite46.y = 90 -- 167
node1:addChild(sprite46) -- 167
local sprite47 = Sprite("box1.png") -- 168
sprite47.x = p5.x - 150 -- 168
sprite47.y = 160 -- 168
node1:addChild(sprite47) -- 168
local sprite48 = Sprite("shadow.png") -- 169
sprite48.x = p5.x + 150 -- 169
sprite48.y = 50 -- 169
sprite48.scaleX = 1.5 -- 169
sprite48.scaleY = 1.5 -- 169
node1:addChild(sprite48) -- 169
local sprite49 = Sprite("box2.png") -- 170
sprite49.x = p5.x + 150 -- 170
sprite49.y = 90 -- 170
sprite49.scaleX = -1 -- 170
node1:addChild(sprite49) -- 170
local sprite50 = Sprite("box1.png") -- 171
sprite50.x = p5.x + 150 -- 171
sprite50.y = 160 -- 171
sprite50.scaleX = -1 -- 171
node1:addChild(sprite50) -- 171
local sprite51 = Sprite("shadow.png") -- 172
sprite51.x = p1.x -- 172
sprite51.scaleX = 1.5 -- 172
sprite51.scaleY = 1.5 -- 172
node1:addChild(sprite51) -- 172
local sprite52 = Sprite("shadow.png") -- 173
sprite52.x = p2.x -- 173
sprite52.scaleX = 1.5 -- 173
sprite52.scaleY = 1.5 -- 173
node1:addChild(sprite52) -- 173
local sprite53 = Sprite("shadow.png") -- 174
sprite53.x = p3.x -- 174
sprite53.scaleX = 1.5 -- 174
sprite53.scaleY = 1.5 -- 174
node1:addChild(sprite53) -- 174
local sprite54 = Sprite("shadow.png") -- 175
sprite54.x = p4.x -- 175
sprite54.scaleX = 1.5 -- 175
sprite54.scaleY = 1.5 -- 175
node1:addChild(sprite54) -- 175
local sprite55 = Sprite("shadow.png") -- 176
sprite55.x = p5.x -- 176
sprite55.scaleX = 1.5 -- 176
sprite55.scaleY = 1.5 -- 176
node1:addChild(sprite55) -- 176
local playable7 = Playable("spine:charM") -- 177
playable7.x = p1.x -- 177
playable7.scaleX = 1.5 -- 177
playable7.scaleY = 1.5 -- 177
playable7:play("idle",true) -- 177
node1:addChild(playable7) -- 177
local playable8 = Playable("spine:moling") -- 178
playable8.x = p2.x -- 178
playable8.scaleX = 1.5 -- 178
playable8.scaleY = 1.5 -- 178
playable8:play("idle",true) -- 178
node1:addChild(playable8) -- 178
local playable9 = Playable("spine:moyu") -- 179
playable9.x = p3.x -- 179
playable9.scaleX = 1.5 -- 179
playable9.scaleY = 1.5 -- 179
playable9:play("idle",true) -- 179
node1:addChild(playable9) -- 179
local playable10 = Playable("spine:villywan") -- 180
playable10.x = p4.x -- 180
playable10.scaleX = 1.5 -- 180
playable10.scaleY = 1.5 -- 180
playable10:play("idle",true) -- 180
node1:addChild(playable10) -- 180
local playable11 = Playable("spine:liyena") -- 181
playable11.x = p5.x -- 181
playable11.scaleX = 1.5 -- 181
playable11.scaleY = 1.5 -- 181
playable11.fliped = true -- 181
playable11:play("idle",true) -- 181
node1:addChild(playable11) -- 181
end -- 185
local lsdOS = LsdOS{} -- 187
item1:addChild(lsdOS) -- 187
local topControl = AlignNode{vAlign = "Top", hAlign = "Left"} -- 189
item1:addChild(topControl) -- 189
local backButton = BackButton{y = -78.5, x = 155} -- 190
topControl:addChild(backButton) -- 190
formation.backButton = backButton -- 190
local leftControl = AlignNode{vAlign = "Bottom", hAlign = "Left"} -- 193
item1:addChild(leftControl) -- 193
local rosterButton = Button{y = 111.5, x = 281.5, textBG = missionMode and '' or 'FORMATION', text = missionMode and '调整学员' or '已有编队'} -- 194
leftControl:addChild(rosterButton) -- 194
formation.rosterButton = rosterButton -- 194
local rightControl = AlignNode{vAlign = "Bottom", hAlign = "Right"} -- 197
item1:addChild(rightControl) -- 197
local startButton = Button{y = 111.5, x = -281.5, textBG = missionMode and '' or 'START BATTLE', text = "开始作战"} -- 198
rightControl:addChild(startButton) -- 198
formation.startButton = startButton -- 198
local leftBox = AlignNode{vAlign = "Center", hAlign = "Left"} -- 202
formation:addChild(leftBox) -- 202
local rightBox = AlignNode{hAlign = "Right", vAlign = "Center", visible = not missionMode} -- 207
formation:addChild(rightBox) -- 207
local item19 = GearBox{right = true} -- 208
rightBox:addChild(item19) -- 208
rightBox.visible = not missionMode -- 210
formation:slot("AlignLayout",function(w, h) -- 211
do -- 211
	local scale = h / H -- 213
	local ratio = w / h -- 214
	local extraScale = ratio / math.max(ratio, 1.9) -- 215
	local _list_0 = { -- 216
		formation.figure, -- 216
		formation.bottomControl -- 216
	} -- 216
	for _index_0 = 1, #_list_0 do -- 216
		local item = _list_0[_index_0] -- 216
		item.scaleX = scale * extraScale -- 217
		item.scaleY = scale * extraScale -- 218
	end -- 216
	local _list_1 = { -- 219
		bg, -- 219
		lsdOS, -- 219
		topControl, -- 219
		leftControl, -- 219
		rightControl, -- 219
		leftBox, -- 219
		rightBox -- 219
	} -- 219
	for _index_0 = 1, #_list_1 do -- 219
		local item = _list_1[_index_0] -- 219
		item.scaleX = scale -- 220
		item.scaleY = scale -- 221
	end -- 219
	if formation.charMenu then -- 222
		formation.charMenu:adjustSizeWithAlign("Auto", 27, Size(2715, 1036.5)) -- 222
	end -- 222
end -- 211
end) -- 212
return formation -- 212
end