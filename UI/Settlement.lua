-- [xml]: UI/Settlement.xml
local SolidRect = require("UI.View.Shape.SolidRect") -- 2
local AlignNode = require("UI.Control.Basic.AlignNode") -- 3
local ScrollArea = require("UI.Control.Basic.ScrollArea") -- 4
local MovingText = require("UI.MovingText") -- 5
local MissionTab = require("UI.MissionTab") -- 6
local RewardItem = require("UI.RewardItem") -- 7
local MemberView = require("UI.MemberView") -- 8
local PropButton = require("UI.PropButton") -- 9
local TacticReview = require("UI.TacticReview") -- 10
local H <const> = 1563 -- 12
return function(args) -- 1
local _ENV = Dora(args) -- 1
local item1 = AlignNode{isRoot = true, inUI = true} -- 13
local bk = AlignNode{vAlign = "Bottom", hAlign = "Left"} -- 14
item1:addChild(bk) -- 14
local mask = SolidRect{color = 0x66000000, height = 1563, width = 3258} -- 15
bk:addChild(mask) -- 15
local left = AlignNode{vAlign = "Center", hAlign = "Left"} -- 17
item1:addChild(left) -- 17
local rc = SolidRect{color = 0xb2000000, height = 1129, width = 3258, y = -618.5} -- 18
left:addChild(rc) -- 18
local node1 = Node() -- 19
node1.y = -54 -- 19
node1.order = 1 -- 19
left:addChild(node1) -- 19
local logo = Sprite("ar.clip|lsdar_settlement_logo") -- 20
logo.x = 438.5 -- 20
node1:addChild(logo) -- 20
local sprite1 = Sprite("ar.clip|lsdar_settlement_ribbon") -- 21
sprite1.anchor = Vec2(0,sprite1.anchor.y) -- 21
sprite1.y = -492 -- 21
node1:addChild(sprite1) -- 21
local label1 = Label("SourceHanSansCN-Regular",300) -- 22
label1.anchor = Vec2(0,label1.anchor.y) -- 22
label1.x = 129.5 -- 22
label1.y = 537 -- 22
label1.color3 = Color3(0xffffff) -- 22
label1.alignment = "Left" -- 22
label1.spacing = 10 -- 22
label1.text = "行动结束" -- 22
node1:addChild(label1) -- 22
local label2 = Label("SourceHanSansCN-Regular",55) -- 26
label2.anchor = Vec2(0,label2.anchor.y) -- 26
label2.x = 129.5 -- 26
label2.y = 657 -- 26
label2.color3 = Color3(0xffffff) -- 26
label2.opacity = 0.7 -- 26
label2.alignment = "Left" -- 26
label2.text = "2-3地底的喧嚣" -- 26
node1:addChild(label2) -- 26
local label3 = Label("SourceHanSansCN-Regular",40) -- 30
label3.anchor = Vec2(0,label3.anchor.y) -- 30
label3.x = 129.5 -- 30
label3.y = -492 -- 30
label3.color3 = Color3(0xffffff) -- 30
label3.alignment = "Left" -- 30
label3.text = "10秒后自动退出战斗结算界面" -- 30
node1:addChild(label3) -- 30
local assessment = Node() -- 34
assessment.visible = true -- 34
node1:addChild(assessment) -- 34
local lb = Label("SourceHanSansCN-Regular",40) -- 35
lb.anchor = Vec2(0,0) -- 35
lb.x = 129.5 -- 35
lb.y = 100 -- 35
lb.color3 = Color3(0xffffff) -- 35
lb.opacity = 0.5 -- 35
lb.alignment = "Left" -- 35
lb.text = "获得物资" -- 35
assessment:addChild(lb) -- 35
local label4 = Label("SourceHanSansCN-Regular",30) -- 39
label4.anchor = Vec2(0,0) -- 39
label4.x = lb.x + lb.width + 30 -- 39
label4.y = 100 -- 39
label4.color3 = Color3(0xffffff) -- 39
label4.opacity = 0.5 -- 39
label4.alignment = "Left" -- 39
label4.text = "REWARD" -- 39
assessment:addChild(label4) -- 39
local lb1 = Label("SourceHanSansCN-Regular",40) -- 43
lb1.anchor = Vec2(0,0) -- 43
lb1.x = 1125 -- 43
lb1.y = 476 -- 43
lb1.color3 = Color3(0xffffff) -- 43
lb1.opacity = 0.5 -- 43
lb1.alignment = "Left" -- 43
lb1.text = "出战成员" -- 43
assessment:addChild(lb1) -- 43
local label5 = Label("SourceHanSansCN-Regular",30) -- 47
label5.anchor = Vec2(0,0) -- 47
label5.x = lb1.x + lb1.width + 30 -- 47
label5.y = 476 -- 47
label5.color3 = Color3(0xffffff) -- 47
label5.opacity = 0.5 -- 47
label5.alignment = "Left" -- 47
label5.text = "TEAM MEMBER" -- 47
assessment:addChild(label5) -- 47
local item2 = MissionTab{title = "地底的喧嚣", status = "Complete", mode = "Main", y = 407, x = 582} -- 51
assessment:addChild(item2) -- 51
local item3 = MissionTab{title = "饕餮骚动中", status = "(15/30)", mode = "Side", y = 315, x = 582} -- 52
assessment:addChild(item3) -- 52
local item4 = MissionTab{title = "黑暗中的残影", status = "Failed", mode = "Map", y = 223, x = 582} -- 53
assessment:addChild(item4) -- 53
local rewardArea = ScrollArea{scrollBar = false, paddingX = 0, width = 964, y = -166, height = 500, x = 582} -- 54
assessment:addChild(rewardArea) -- 54
do -- 55
local view = rewardArea.view -- 56
local item5 = RewardItem{} -- 57
view:addChild(item5) -- 57
local item6 = RewardItem{} -- 58
view:addChild(item6) -- 58
local item7 = RewardItem{} -- 59
view:addChild(item7) -- 59
local item8 = RewardItem{} -- 60
view:addChild(item8) -- 60
local item9 = RewardItem{} -- 61
view:addChild(item9) -- 61
local item10 = RewardItem{} -- 62
view:addChild(item10) -- 62
local item11 = RewardItem{} -- 63
view:addChild(item11) -- 63
local item12 = RewardItem{} -- 64
view:addChild(item12) -- 64
local item13 = RewardItem{} -- 65
view:addChild(item13) -- 65
local item14 = RewardItem{} -- 66
view:addChild(item14) -- 66
end -- 68
rewardArea:adjustSizeWithAlign("Auto", 0, Size(964, 500)) -- 69
local memberArea = ScrollArea{scrollBar = false, height = 843, width = 964, y = 24, paddingY = 0} -- 71
assessment:addChild(memberArea) -- 71
do -- 72
local view = memberArea.view -- 73
local item15 = MemberView{} -- 74
view:addChild(item15) -- 74
local item16 = MemberView{} -- 75
view:addChild(item16) -- 75
local item17 = MemberView{} -- 76
view:addChild(item17) -- 76
local item18 = MemberView{} -- 77
view:addChild(item18) -- 77
local item19 = MemberView{} -- 78
view:addChild(item19) -- 78
end -- 80
memberArea:adjustSizeWithAlign("Horizontal", 0, Size(964, 843)) -- 81
local tacticReview = Node() -- 85
tacticReview.visible = false -- 85
tacticReview.order = 1 -- 85
left:addChild(tacticReview) -- 85
local sprite2 = Sprite("ar.clip|lsdar_settlement_role_bg") -- 86
sprite2.x = 342 -- 86
sprite2.y = 5 -- 86
tacticReview:addChild(sprite2) -- 86
local tacticArea = ScrollArea{scrollBar = false, height = 739, width = 476, x = 942, y = 10, paddingY = 0} -- 87
tacticReview:addChild(tacticArea) -- 87
do -- 88
local view = tacticArea.view -- 89
local item20 = TacticReview{score = "S"} -- 90
view:addChild(item20) -- 90
local item21 = TacticReview{score = "A"} -- 91
view:addChild(item21) -- 91
local item22 = TacticReview{score = "B"} -- 92
view:addChild(item22) -- 92
local item23 = TacticReview{score = "C"} -- 93
view:addChild(item23) -- 93
local item24 = TacticReview{score = "C"} -- 94
view:addChild(item24) -- 94
end -- 96
tacticArea:adjustSizeWithAlign("Horizontal", 0, Size(476, 739)) -- 97
local right = AlignNode{vAlign = "Center", hAlign = "Right"} -- 101
item1:addChild(right) -- 101
local node2 = Node() -- 102
node2.y = 510.5 -- 102
node2.opacity = 0.1 -- 102
node2.scaleX = 1.5 -- 102
node2.scaleY = 1.5 -- 102
right:addChild(node2) -- 102
local item25 = MovingText{offsetY = 0, color3 = 0xffffff, fontSize = 100, textBG = "MISSION COMPLETE     MISSION COMPLETE", y = -75, x = -2000} -- 103
node2:addChild(item25) -- 103
local mask = item25.mask -- 104
local item26 = SolidRect{height = 75, width = 2000} -- 105
mask:addChild(item26) -- 105
local item27 = PropButton{text = "再次行动", y = -546, x = -646} -- 109
right:addChild(item27) -- 109
local item28 = PropButton{text = "返回基地", y = -546, x = -273} -- 110
right:addChild(item28) -- 110
item1:slot("AlignLayout",function(w, h) -- 112
do -- 112
	local scale = h / H -- 115
	rc:removeFromParent() -- 116
	rc = SolidRect({ -- 117
		y = -618.5, -- 117
		width = w / scale, -- 117
		height = 1129, -- 117
		color = 0xb2000000 -- 117
	}) -- 117
	left:addChild(rc) -- 118
	mask:removeFromParent() -- 119
	mask = SolidRect({ -- 120
		width = w, -- 120
		height = h, -- 120
		color = 0x66000000 -- 120
	}) -- 120
	bk:addChild(mask) -- 121
	local _list_0 = { -- 122
		left, -- 122
		right -- 122
	} -- 122
	for _index_0 = 1, #_list_0 do -- 122
		local item = _list_0[_index_0] -- 122
		item.scaleX = scale -- 123
		item.scaleY = scale -- 124
	end -- 124
	local memberWidth = w / scale - 1115 -- 125
	do -- 126
		local _with_0 = memberArea -- 126
		_with_0.x = 1115 + memberWidth / 2 -- 127
		_with_0:adjustSizeWithAlign("Horizontal", 0, Size(memberWidth, 843)) -- 128
	end -- 126
	local tacticWidth = w / scale - 704 -- 129
	local _with_0 = tacticArea -- 130
	_with_0.x = 704 + tacticWidth / 2 -- 131
	_with_0:adjustSizeWithAlign("Horizontal", 0, Size(tacticWidth, 739)) -- 132
end -- 132
end) -- 113
return item1 -- 113
end