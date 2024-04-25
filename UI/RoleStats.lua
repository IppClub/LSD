-- [xml]: UI/RoleStats.xml
local AlignNode = require("UI.Control.Basic.AlignNode") -- 2
local ScrollArea = require("UI.Control.Basic.ScrollArea") -- 3
local CDE = require("UI.CDE") -- 4
local TabButton = require("UI.TabButton") -- 5
local LsdOS = require("UI.LsdOS") -- 6
local Button = require("UI.Button") -- 7
local BackButton = require("UI.BackButton") -- 8
local StoryBox = require("UI.StoryBox") -- 9
local TacticFileS = require("UI.TacticFileS") -- 10
local TacticFileL = require("UI.TacticFileL") -- 11
local TacticAction = require("UI.TacticAction") -- 12
local TacticDetail = require("UI.TacticDetail") -- 13
local H <const> = 1563 -- 15
return function(args) -- 1
local _ENV = Dora(args) -- 1
local ui = AlignNode{isRoot = true, inUI = true} -- 16
local item1 = AlignNode{alignHeight = "h", alignWidth = "3000 * math.min(h / 1563, w / 3000)", vAlign = "Center", hAlign = "Center"} -- 17
ui:addChild(item1) -- 17
local item2 = AlignNode{vAlign = "Center", hAlign = "Center"} -- 19
item1:addChild(item2) -- 19
local bg = Playable("bone:lsdOSBack") -- 20
item2:addChild(bg) -- 20
local formation_head_line = bg:getChildByTag("formation_head_line") -- 21
formation_head_line.visible = false -- 21
local lsdOS = LsdOS{} -- 25
item1:addChild(lsdOS) -- 25
local item3 = AlignNode{alignHeight = "h", alignWidth = "w / 2", vAlign = "Center", hAlign = "Left"} -- 27
item1:addChild(item3) -- 27
local figure = AlignNode{vAlign = "Center", hAlign = "Center"} -- 28
item3:addChild(figure) -- 28
ui.figure = figure -- 28
local leftControl = AlignNode{vAlign = "Bottom", hAlign = "Left"} -- 31
item1:addChild(leftControl) -- 31
local menu = Menu() -- 32
menu.anchor = Vec2(0,0) -- 32
menu.x = 70 -- 32
menu.y = 40 -- 32
menu.order = 1 -- 32
menu.size = Size(971,143) -- 32
leftControl:addChild(menu) -- 32
local btn1 = TabButton{textBG = "OVERVIEW", selected = true, text = "总览"} -- 33
menu:addChild(btn1) -- 33
btn1:slot("Tapped",function() -- 34
do -- 34
	btn1:emit("Toggle") -- 36
	menu.selected:emit("Toggle") -- 37
	menu.selected = btn1 -- 38
	menu:alignItems(30) -- 39
	ui.infoArea.visible = true -- 40
	ui.storyArea.visible = false -- 41
end -- 41
end) -- 35
local btn2 = TabButton{textBG = "INTELLIGENCE", text = "对策"} -- 45
menu:addChild(btn2) -- 45
btn2:slot("Tapped",function() -- 46
do -- 46
	btn2:emit("Toggle") -- 48
	menu.selected:emit("Toggle") -- 49
	menu.selected = btn2 -- 50
	menu:alignItems(30) -- 51
end -- 51
end) -- 47
local btn3 = TabButton{textBG = "STORY", text = "故事"} -- 55
menu:addChild(btn3) -- 55
btn3:slot("Tapped",function() -- 56
do -- 56
	btn3:emit("Toggle") -- 58
	menu.selected:emit("Toggle") -- 59
	menu.selected = btn3 -- 60
	menu:alignItems(30) -- 61
	ui.infoArea.visible = false -- 62
	ui.storyArea.visible = true -- 63
end -- 63
end) -- 57
do -- 66
	menu.selected = btn1 -- 68
	menu:alignItems(30) -- 69
end -- 69
local item4 = AlignNode{alignHeight = "h", alignWidth = "w / 2", vAlign = "Center", hAlign = "Right"} -- 74
item1:addChild(item4) -- 74
local scrollArea = AlignNode{vAlign = "Center", hAlign = "Center"} -- 75
item4:addChild(scrollArea) -- 75
local aiArea = ScrollArea{visible = false, clipping = false, scrollBar = false, paddingX = 0, x = 50} -- 76
scrollArea:addChild(aiArea) -- 76
ui.aiArea = aiArea -- 76
local view = aiArea.view -- 77
local node1 = Node() -- 78
node1.size = Size(1042,270) -- 78
view:addChild(node1) -- 78
local item5 = TacticFileS{} -- 79
view:addChild(item5) -- 79
local item6 = TacticFileS{} -- 80
view:addChild(item6) -- 80
local item7 = TacticFileS{} -- 81
view:addChild(item7) -- 81
local item8 = TacticFileS{} -- 82
view:addChild(item8) -- 82
local item9 = TacticFileS{} -- 83
view:addChild(item9) -- 83
local item10 = TacticFileS{} -- 84
view:addChild(item10) -- 84
local node2 = Node() -- 87
node2.x = 90 -- 87
node2.y = 100 -- 87
scrollArea:addChild(node2) -- 87
local item11 = TacticFileL{y = -150, x = -500} -- 88
node2:addChild(item11) -- 88
local sprite1 = Sprite("ai.clip|ai_img") -- 89
sprite1.anchor = Vec2(1,sprite1.anchor.y) -- 89
sprite1.x = 262.5 -- 89
sprite1.y = -520 -- 89
sprite1.opacity = 0.3 -- 89
sprite1.scaleX = 0.6 -- 89
sprite1.scaleY = 0.6 -- 89
node2:addChild(sprite1) -- 89
local sprite2 = Sprite("ai.clip|ai_img") -- 90
sprite2.anchor = Vec2(1,sprite2.anchor.y) -- 90
sprite2.x = 302.5 -- 90
sprite2.y = -520 -- 90
sprite2.opacity = 0.3 -- 90
sprite2.scaleX = -0.6 -- 90
sprite2.scaleY = 0.6 -- 90
node2:addChild(sprite2) -- 90
local sprite3 = Sprite("ai.clip|ai_big_circuit") -- 91
sprite3.x = -115 -- 91
node2:addChild(sprite3) -- 91
local item12 = TacticAction{y = 430, x = 84.5, text = "枪械"} -- 92
node2:addChild(item12) -- 92
local item13 = TacticAction{y = 260, x = 84.5, text = "近战武器"} -- 93
node2:addChild(item13) -- 93
local item14 = TacticAction{y = 90, x = 84.5, text = "近战武器"} -- 94
node2:addChild(item14) -- 94
local item15 = TacticAction{y = -80, x = 84.5, text = "闪避"} -- 95
node2:addChild(item15) -- 95
local item16 = TacticAction{y = -250, x = 84.5, text = "格挡"} -- 96
node2:addChild(item16) -- 96
local item17 = TacticAction{y = -420, x = 84.5, text = "防御"} -- 97
node2:addChild(item17) -- 97
do -- 99
local infoArea = ScrollArea{visible = false, clipping = false, scrollBar = false, paddingX = 0} -- 100
scrollArea:addChild(infoArea) -- 100
ui.infoArea = infoArea -- 100
local view = infoArea.view -- 101
local node3 = Node() -- 102
node3.size = Size(1042,108) -- 102
view:addChild(node3) -- 102
local name = Label("SourceHanSansCN-Regular",70) -- 103
name.color3 = Color3(0x0) -- 103
name.spacing = 5 -- 103
name.text = "默翎" -- 103
view:addChild(name) -- 103
local node4 = Node() -- 104
node4.size = Size(37,name.height) -- 104
view:addChild(node4) -- 104
local label1 = Label("FangZhengHeiTiJianTi",60) -- 105
label1.anchor = Vec2(0,label1.anchor.y) -- 105
label1.x = 37 -- 105
label1.y = 26 -- 105
label1.color3 = Color3(0x0) -- 105
label1.opacity = 0.5 -- 105
label1.alignment = "Left" -- 105
label1.spacing = 5 -- 105
label1.text = "LIAN" -- 105
node4:addChild(label1) -- 105
local node5 = Node() -- 110
node5.size = Size(1042,10) -- 110
view:addChild(node5) -- 110
local node6 = Node() -- 111
node6.size = Size(1042,210) -- 111
view:addChild(node6) -- 111
local sprite4 = Sprite("CDE.clip|role_divider") -- 112
sprite4.x = 520.8 -- 112
sprite4.y = 205.81 -- 112
node6:addChild(sprite4) -- 112
local sprite5 = Sprite("CDE.clip|role_icon_hp_1") -- 113
sprite5.x = 34.17 -- 113
sprite5.y = 129.93 -- 113
node6:addChild(sprite5) -- 113
local sprite6 = Sprite("CDE.clip|role_icon_sp_1") -- 114
sprite6.x = 38.49 -- 114
sprite6.y = 31.43 -- 114
node6:addChild(sprite6) -- 114
local sprite7 = Sprite("CDE.clip|role_icon_atk_1") -- 115
sprite7.x = 660.45 -- 115
sprite7.y = 125.64 -- 115
node6:addChild(sprite7) -- 115
local sprite8 = Sprite("CDE.clip|role_icon_atks_1") -- 116
sprite8.x = 656.88 -- 116
sprite8.y = 34.34 -- 116
node6:addChild(sprite8) -- 116
local label2 = Label("SourceHanSansCN-Regular",55) -- 117
label2.anchor = Vec2(0,label2.anchor.y) -- 117
label2.x = 118 -- 117
label2.y = 130 -- 117
label2.color3 = Color3(0x0) -- 117
label2.opacity = 0.5 -- 117
label2.renderOrder = 8 -- 117
label2.alignment = "Left" -- 117
label2.spacing = 10 -- 117
label2.text = "生命" -- 117
node6:addChild(label2) -- 117
local label3 = Label("SourceHanSansCN-Regular",50) -- 121
label3.anchor = Vec2(1,label3.anchor.y) -- 121
label3.x = 408 -- 121
label3.y = 130 -- 121
label3.color3 = Color3(0x0) -- 121
label3.renderOrder = 7 -- 121
label3.alignment = "Right" -- 121
label3.text = "100" -- 121
node6:addChild(label3) -- 121
local label4 = Label("SourceHanSansCN-Regular",55) -- 125
label4.anchor = Vec2(0,label4.anchor.y) -- 125
label4.x = 732 -- 125
label4.y = 130 -- 125
label4.color3 = Color3(0x0) -- 125
label4.opacity = 0.5 -- 125
label4.renderOrder = 8 -- 125
label4.alignment = "Left" -- 125
label4.spacing = 10 -- 125
label4.text = "力量" -- 125
node6:addChild(label4) -- 125
local lb = Label("SourceHanSansCN-Regular",50) -- 129
lb.anchor = Vec2(1,lb.anchor.y) -- 129
lb.x = 1020 -- 129
lb.y = 130 -- 129
lb.color3 = Color3(0x0) -- 129
lb.renderOrder = 7 -- 129
lb.alignment = "Right" -- 129
lb.text = "100" -- 129
node6:addChild(lb) -- 129
local label5 = Label("SourceHanSansCN-Regular",55) -- 133
label5.anchor = Vec2(0,label5.anchor.y) -- 133
label5.x = 118 -- 133
label5.y = 32 -- 133
label5.color3 = Color3(0x0) -- 133
label5.opacity = 0.5 -- 133
label5.renderOrder = 8 -- 133
label5.alignment = "Left" -- 133
label5.spacing = 10 -- 133
label5.text = "体能" -- 133
node6:addChild(label5) -- 133
local label6 = Label("SourceHanSansCN-Regular",50) -- 137
label6.anchor = Vec2(1,label6.anchor.y) -- 137
label6.x = 408 -- 137
label6.y = 32 -- 137
label6.color3 = Color3(0x0) -- 137
label6.renderOrder = 7 -- 137
label6.alignment = "Right" -- 137
label6.text = "100" -- 137
node6:addChild(label6) -- 137
local label7 = Label("SourceHanSansCN-Regular",55) -- 141
label7.anchor = Vec2(0,label7.anchor.y) -- 141
label7.x = 732 -- 141
label7.y = 32 -- 141
label7.color3 = Color3(0x0) -- 141
label7.opacity = 0.5 -- 141
label7.renderOrder = 8 -- 141
label7.alignment = "Left" -- 141
label7.spacing = 10 -- 141
label7.text = "灵活" -- 141
node6:addChild(label7) -- 141
local label8 = Label("SourceHanSansCN-Regular",50) -- 145
label8.anchor = Vec2(1,label8.anchor.y) -- 145
label8.x = 1020 -- 145
label8.y = 32 -- 145
label8.color3 = Color3(0x0) -- 145
label8.renderOrder = 7 -- 145
label8.alignment = "Right" -- 145
label8.text = "100" -- 145
node6:addChild(label8) -- 145
local node7 = Node() -- 150
node7.size = Size(1042,132) -- 150
view:addChild(node7) -- 150
local left <const> = 70 -- 152
local right <const> = 110 -- 153
local lb = Label("SourceHanSansCN-Regular",35) -- 155
lb.anchor = Vec2(0,lb.anchor.y) -- 155
lb.x = 10 -- 155
lb.y = 82.5 -- 155
lb.color3 = Color3(0x0) -- 155
lb.alignment = "Left" -- 155
lb.text = "移动速度" -- 155
node7:addChild(lb) -- 155
local lb1 = Label("SourceHanSansCN-Regular",35) -- 159
lb1.x = lb.x + lb.width + left -- 159
lb1.y = 82.5 -- 159
lb1.color3 = Color3(0x538eff) -- 159
lb1.alignment = "Center" -- 159
lb1.text = "100" -- 159
node7:addChild(lb1) -- 159
local lb2 = Label("SourceHanSansCN-Regular",35) -- 163
lb2.anchor = Vec2(0,lb2.anchor.y) -- 163
lb2.x = lb1.x + right -- 163
lb2.y = 82.5 -- 163
lb2.color3 = Color3(0x0) -- 163
lb2.alignment = "Left" -- 163
lb2.text = "近战命中率" -- 163
node7:addChild(lb2) -- 163
local lb3 = Label("SourceHanSansCN-Regular",35) -- 167
lb3.x = lb2.x + lb2.width + left -- 167
lb3.y = 82.5 -- 167
lb3.color3 = Color3(0x538eff) -- 167
lb3.alignment = "Center" -- 167
lb3.text = "100%" -- 167
node7:addChild(lb3) -- 167
local lb4 = Label("SourceHanSansCN-Regular",35) -- 171
lb4.anchor = Vec2(0,lb4.anchor.y) -- 171
lb4.x = lb3.x + right -- 171
lb4.y = 82.5 -- 171
lb4.color3 = Color3(0x0) -- 171
lb4.alignment = "Left" -- 171
lb4.text = "技能命中率" -- 171
node7:addChild(lb4) -- 171
local lb5 = Label("SourceHanSansCN-Regular",35) -- 175
lb5.x = lb4.x + lb4.width + left -- 175
lb5.y = 82.5 -- 175
lb5.color3 = Color3(0x538eff) -- 175
lb5.alignment = "Center" -- 175
lb5.text = "100%" -- 175
node7:addChild(lb5) -- 175
local lb = Label("SourceHanSansCN-Regular",35) -- 180
lb.anchor = Vec2(0,lb.anchor.y) -- 180
lb.x = 10 -- 180
lb.y = 17.5 -- 180
lb.color3 = Color3(0x0) -- 180
lb.alignment = "Left" -- 180
lb.text = "跳跃能力" -- 180
node7:addChild(lb) -- 180
local lb1 = Label("SourceHanSansCN-Regular",35) -- 184
lb1.x = lb.x + lb.width + left -- 184
lb1.y = 17.5 -- 184
lb1.color3 = Color3(0x538eff) -- 184
lb1.alignment = "Center" -- 184
lb1.text = "100" -- 184
node7:addChild(lb1) -- 184
local lb2 = Label("SourceHanSansCN-Regular",35) -- 188
lb2.anchor = Vec2(0,lb2.anchor.y) -- 188
lb2.x = lb1.x + right -- 188
lb2.y = 17.5 -- 188
lb2.color3 = Color3(0x0) -- 188
lb2.alignment = "Left" -- 188
lb2.text = "射击命中率" -- 188
node7:addChild(lb2) -- 188
local lb3 = Label("SourceHanSansCN-Regular",35) -- 192
lb3.x = lb2.x + lb2.width + left -- 192
lb3.y = 17.5 -- 192
lb3.color3 = Color3(0x538eff) -- 192
lb3.alignment = "Center" -- 192
lb3.text = "100%" -- 192
node7:addChild(lb3) -- 192
local node8 = Node() -- 197
node8.size = Size(1042,116) -- 197
view:addChild(node8) -- 197
local lb = Label("SourceHanSansCN-Regular",50) -- 198
lb.anchor = Vec2(0,lb.anchor.y) -- 198
lb.x = 138 -- 198
lb.y = 25 -- 198
lb.color3 = Color3(0x0) -- 198
lb.renderOrder = 6 -- 198
lb.alignment = "Left" -- 198
lb.spacing = 5 -- 198
lb.text = "无形之毒" -- 198
node8:addChild(lb) -- 198
local label9 = Label("FangZhengHeiTiJianTi",30) -- 202
label9.anchor = Vec2(0,label9.anchor.y) -- 202
label9.x = lb.x + lb.width + 10 -- 202
label9.y = 10 -- 202
label9.color3 = Color3(0x0) -- 202
label9.opacity = 0.5 -- 202
label9.renderOrder = 5 -- 202
label9.alignment = "Left" -- 202
label9.spacing = 2 -- 202
label9.text = "Invisible Poison" -- 202
node8:addChild(label9) -- 202
local node9 = Node() -- 207
node9.size = Size(1042,24) -- 207
view:addChild(node9) -- 207
local lb = Label("SourceHanSansCN-Regular",40) -- 208
lb.color3 = Color3(0x0) -- 208
lb.alignment = "Left" -- 208
lb.textWidth = 1020 -- 208
lb.text = "技能说明技能说明技能说明技能说明技能说明技能说明技能说明技能说明技能说明技能说明技能说明技能说明技能说明技能说明" -- 208
view:addChild(lb) -- 208
local node10 = Node() -- 212
node10.size = Size(1042,116) -- 212
view:addChild(node10) -- 212
local lb = Label("SourceHanSansCN-Regular",50) -- 213
lb.anchor = Vec2(0,lb.anchor.y) -- 213
lb.x = 10 -- 213
lb.y = 25 -- 213
lb.color3 = Color3(0x0) -- 213
lb.renderOrder = 6 -- 213
lb.alignment = "Left" -- 213
lb.spacing = 5 -- 213
lb.text = "人物缺点" -- 213
node10:addChild(lb) -- 213
local label10 = Label("FangZhengHeiTiJianTi",30) -- 217
label10.anchor = Vec2(0,label10.anchor.y) -- 217
label10.x = lb.x + lb.width + 10 -- 217
label10.y = 10 -- 217
label10.color3 = Color3(0x0) -- 217
label10.opacity = 0.5 -- 217
label10.renderOrder = 5 -- 217
label10.alignment = "Left" -- 217
label10.spacing = 2 -- 217
label10.text = "Character Defects" -- 217
node10:addChild(label10) -- 217
local node11 = Node() -- 222
node11.size = Size(1042,10) -- 222
view:addChild(node11) -- 222
for i = 1, 20 do -- 223
local item18 = CDE{} -- 224
view:addChild(item18) -- 224
end -- 225
end -- 228
do -- 229
local storyArea = ScrollArea{visible = false, clipping = false, scrollBar = false, paddingX = 0} -- 230
scrollArea:addChild(storyArea) -- 230
ui.storyArea = storyArea -- 230
local view = storyArea.view -- 231
local node12 = Node() -- 232
node12.size = Size(1071,108) -- 232
view:addChild(node12) -- 232
local item19 = StoryBox{content = "人物故事人物故事人物故事人物故事人物故事人物故事人物故事人物故事人物故事人物故事人物故事人物故事人物故事人物故事人物故事", title = "故事一"} -- 233
view:addChild(item19) -- 233
local item20 = StoryBox{requirement = "解锁条件", textBG = "STORY", title = "故事二"} -- 234
view:addChild(item20) -- 234
local item21 = StoryBox{requirement = "解锁条件解锁条件解锁条件解锁条件", textBG = "STORY", title = "故事三"} -- 235
view:addChild(item21) -- 235
end -- 238
local pop = Sprite("CDE.clip|pop_small_bg") -- 241
pop.anchor = Vec2(1,0) -- 241
pop.visible = false -- 241
pop.renderGroup = true -- 241
pop.renderOrder = 0 -- 241
item1:addChild(pop) -- 241
local label11 = Label("SourceHanSansCN-Regular",50) -- 242
label11.anchor = Vec2(0,0) -- 242
label11.x = 25 -- 242
label11.y = 500 -- 242
label11.color3 = Color3(0xffffff) -- 242
label11.renderOrder = 1 -- 242
label11.alignment = "Left" -- 242
label11.spacing = 5 -- 242
label11.text = "人物缺点" -- 242
pop:addChild(label11) -- 242
local sprite9 = Sprite("CDE.clip|pop_small_tab_bg") -- 246
sprite9.anchor = Vec2(0,0) -- 246
sprite9.x = 13 -- 246
sprite9.y = 404 -- 246
sprite9.renderOrder = 0 -- 246
pop:addChild(sprite9) -- 246
local label12 = Label("SourceHanSansCN-Regular",40) -- 247
label12.anchor = Vec2(0,label12.anchor.y) -- 247
label12.x = 25 -- 247
label12.y = 437 -- 247
label12.color3 = Color3(0xffffff) -- 247
label12.renderOrder = 2 -- 247
label12.alignment = "Left" -- 247
label12.spacing = 1 -- 247
label12.text = "减益效果" -- 247
pop:addChild(label12) -- 247
local debuffDesc = Label("SourceHanSansCN-Regular",35) -- 251
debuffDesc.anchor = Vec2(0,1) -- 251
debuffDesc.x = 25 -- 251
debuffDesc.y = 398 -- 251
debuffDesc.color3 = Color3(0xffffff) -- 251
debuffDesc.renderOrder = 3 -- 251
debuffDesc.alignment = "Left" -- 251
debuffDesc.textWidth = 466 -- 251
debuffDesc.text = "进⼊战场前60秒各项属性提升5%，过60秒后各项属性降低10%" -- 251
pop:addChild(debuffDesc) -- 251
local tab2 = Sprite("CDE.clip|pop_small_tab_bg") -- 255
tab2.anchor = Vec2(0,1) -- 255
tab2.x = 13 -- 255
tab2.y = debuffDesc.y - debuffDesc.height - 6 -- 255
tab2.renderOrder = 0 -- 255
pop:addChild(tab2) -- 255
local label13 = Label("SourceHanSansCN-Regular",40) -- 256
label13.anchor = Vec2(0,1) -- 256
label13.x = 25 -- 256
label13.y = tab2.y - 12 -- 256
label13.color3 = Color3(0xffffff) -- 256
label13.renderOrder = 2 -- 256
label13.alignment = "Left" -- 256
label13.spacing = 1 -- 256
label13.text = "成长条件" -- 256
pop:addChild(label13) -- 256
local growDesc = Label("SourceHanSansCN-Regular",35) -- 260
growDesc.anchor = Vec2(0,1) -- 260
growDesc.x = 25 -- 260
growDesc.y = tab2.y - tab2.height - 6 -- 260
growDesc.color3 = Color3(0xffffff) -- 260
growDesc.renderOrder = 3 -- 260
growDesc.alignment = "Left" -- 260
growDesc.textWidth = 466 -- 260
growDesc.text = "1、满足条件A\n2、满足条件B" -- 260
pop:addChild(growDesc) -- 260
do -- 264
	local _exp_0 = App.platform -- 266
	if "Windows" == _exp_0 or "macOS" == _exp_0 or "Linux" == _exp_0 then -- 267
		local pos -- 268
		local viewCDE -- 269
		viewCDE = function(self) -- 269
			if self.tag ~= "CDE" then -- 270
				return -- 270
			end -- 270
			local localPos = self:convertToNodeSpace(pos) -- 271
			if Rect(Vec2.zero, self.size):containsPoint(localPos) then -- 272
				pop.position = pop.parent:convertToNodeSpace(pos) -- 273
				pop.visible = true -- 274
				return true -- 275
			else -- 277
				pop.visible = false -- 277
			end -- 272
		end -- 269
		pop:schedule(function() -- 278
			if not ui.infoArea.visible then -- 279
				return -- 279
			end -- 279
			local width, height -- 280
			do -- 280
				local _obj_0 = View.size -- 280
				width, height = _obj_0.width, _obj_0.height -- 280
			end -- 280
			pos = nvg.TouchPos() * (width / App.visualSize.width) -- 281
			pos = Vec2(pos.x, height - pos.y) -- 282
			ui.infoArea.view:eachChild(viewCDE) -- 283
			return false -- 284
		end) -- 278
	else -- 286
		if ui.infoArea.visible then -- 286
			ui.infoArea.view:eachChild(function(self) -- 287
				if self.tag ~= "CDE" then -- 288
					return -- 288
				end -- 288
				self.touchEnabled = true -- 289
				self:slot("TapBegan", function() -- 290
					pop.position = pop.parent:convertToNodeSpace(self:convertToWorldSpace(Vec2(0.5, 0.5) * self.size)) -- 291
					return pop:perform(Spawn(Show(), Opacity(0, 0, 1))) -- 292
				end) -- 290
				return self:slot("TapEnded", function() -- 293
					return pop:perform(Sequence(Opacity(0.3, pop.opacity, 0), Hide())) -- 297
				end) -- 297
			end) -- 287
		end -- 286
	end -- 297
end -- 297
local topControl = AlignNode{vAlign = "Top", hAlign = "Left"} -- 300
item1:addChild(topControl) -- 300
local item22 = BackButton{y = -45 - 33.5, x = 100 + 55} -- 301
topControl:addChild(item22) -- 301
local sprite10 = Sprite("button.clip|btn_explain") -- 302
sprite10.anchor = Vec2(0,sprite10.anchor.y) -- 302
sprite10.x = 100 + 110 + 30 -- 302
sprite10.y = -45 - 33.5 -- 302
topControl:addChild(sprite10) -- 302
local rightControl = AlignNode{vAlign = "Bottom", hAlign = "Right"} -- 305
item1:addChild(rightControl) -- 305
local item23 = Button{y = 70 + 41.5, x = -100 - 181.5, textBG = "CONFIRM", text = "确定"} -- 306
rightControl:addChild(item23) -- 306
local centerControl = AlignNode{vAlign = "Center", hAlign = "Center"} -- 308
item1:addChild(centerControl) -- 308
local item24 = TacticDetail{} -- 309
centerControl:addChild(item24) -- 309
ui:slot("AlignLayout",function(w, h) -- 312
do -- 312
	local ratio = w / h -- 314
	ratio = math.min(ratio / 1.5, 1.0) -- 315
	local scale = h / H -- 316
	local _list_0 = { -- 317
		figure, -- 317
		scrollArea -- 317
	} -- 317
	for _index_0 = 1, #_list_0 do -- 317
		local item = _list_0[_index_0] -- 317
		item.scaleX = scale * ratio -- 318
		item.scaleY = scale * ratio -- 319
	end -- 319
	local _list_1 = { -- 320
		bg, -- 320
		leftControl, -- 320
		topControl, -- 320
		rightControl, -- 320
		centerControl, -- 320
		pop, -- 320
		lsdOS -- 320
	} -- 320
	for _index_0 = 1, #_list_1 do -- 320
		local item = _list_1[_index_0] -- 320
		item.scaleX = scale -- 321
		item.scaleY = scale -- 322
	end -- 322
	aiArea:adjustSizeWithAlign("Auto", 0, Size(1168, H)) -- 323
	ui.infoArea:adjustSizeWithAlign("Auto", 0, Size(1042, H)) -- 324
	ui.storyArea:adjustSizeWithAlign("Auto", 0, Size(1071, H)) -- 325
end -- 325
end) -- 313
return ui -- 313
end