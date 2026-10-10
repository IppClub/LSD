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
local settlement = AlignNode{isRoot = true, inUI = true} -- 13
if missionMode and resultStatus ~= "Complete" then settlement:cleanup(); return require("UI.MissionFail")(args) end -- 14
local bk = AlignNode{vAlign = "Bottom", hAlign = "Left"} -- 15
settlement:addChild(bk) -- 15
local mask = SolidRect{color = 0x66000000, height = 1563, width = 3258} -- 16
bk:addChild(mask) -- 16
local left = AlignNode{vAlign = "Center", hAlign = "Left"} -- 18
settlement:addChild(left) -- 18
local rc = SolidRect{color = 0xb2000000, height = 1129, width = 3258, y = -618.5} -- 19
left:addChild(rc) -- 19
local node1 = Node() -- 20
node1.y = -54 -- 20
node1.order = 1 -- 20
left:addChild(node1) -- 20
local logo = Sprite("ar.clip|lsdar_settlement_logo") -- 21
logo.x = 438.5 -- 21
node1:addChild(logo) -- 21
local sprite1 = Sprite("ar.clip|lsdar_settlement_ribbon") -- 22
sprite1.anchor = Vec2(0,sprite1.anchor.y) -- 22
sprite1.y = -492 -- 22
node1:addChild(sprite1) -- 22
local resultHeading = Label("SourceHanSansCN-Regular",missionMode and 140 or 300) -- 23
resultHeading.anchor = Vec2(0,resultHeading.anchor.y) -- 23
resultHeading.x = 129.5 -- 23
resultHeading.y = 537 -- 23
resultHeading.color3 = Color3(0xffffff) -- 23
resultHeading.alignment = "Left" -- 23
resultHeading.spacing = 10 -- 23
resultHeading.text = resultTitle or '行动结束' -- 23
node1:addChild(resultHeading) -- 23
if missionMode then local k=math.min(1,940/math.max(1,resultHeading.width)); resultHeading.scaleX=k; resultHeading.scaleY=k; settlement.resultHeading=resultHeading end -- 27
local label1 = Label("SourceHanSansCN-Regular",55) -- 28
label1.anchor = Vec2(0,label1.anchor.y) -- 28
label1.x = 129.5 -- 28
label1.y = 657 -- 28
label1.color3 = Color3(0xffffff) -- 28
label1.opacity = 0.7 -- 28
label1.alignment = "Left" -- 28
label1.text = missionTitle or '2-3地底的喧嚣' -- 28
node1:addChild(label1) -- 28
local label2 = Label("SourceHanSansCN-Regular",40) -- 32
label2.anchor = Vec2(0,label2.anchor.y) -- 32
label2.x = 129.5 -- 32
label2.y = -492 -- 32
label2.color3 = Color3(0xffffff) -- 32
label2.alignment = "Left" -- 32
label2.text = missionMode and '确认收支后选择下一步' or '10秒后自动退出战斗结算界面' -- 32
node1:addChild(label2) -- 32
local assessment = Node() -- 36
assessment.visible = true -- 36
node1:addChild(assessment) -- 36
local lb = Label("SourceHanSansCN-Regular",40) -- 37
lb.anchor = Vec2(0,0) -- 37
lb.x = 129.5 -- 37
lb.y = 100 -- 37
lb.color3 = Color3(0xffffff) -- 37
lb.opacity = 0.5 -- 37
lb.alignment = "Left" -- 37
lb.text = missionMode and '行动收支' or '获得物资' -- 37
assessment:addChild(lb) -- 37
local label3 = Label("SourceHanSansCN-Regular",30) -- 41
label3.anchor = Vec2(0,0) -- 41
label3.x = lb.x + lb.width + 30 -- 41
label3.y = 100 -- 41
label3.color3 = Color3(0xffffff) -- 41
label3.opacity = 0.5 -- 41
label3.alignment = "Left" -- 41
label3.text = "REWARD" -- 41
assessment:addChild(label3) -- 41
local lb1 = Label("SourceHanSansCN-Regular",40) -- 45
lb1.anchor = Vec2(0,0) -- 45
lb1.x = 1125 -- 45
lb1.y = 476 -- 45
lb1.color3 = Color3(0xffffff) -- 45
lb1.opacity = 0.5 -- 45
lb1.alignment = "Left" -- 45
lb1.text = "出战成员" -- 45
assessment:addChild(lb1) -- 45
local label4 = Label("SourceHanSansCN-Regular",30) -- 49
label4.anchor = Vec2(0,0) -- 49
label4.x = lb1.x + lb1.width + 30 -- 49
label4.y = 476 -- 49
label4.color3 = Color3(0xffffff) -- 49
label4.opacity = 0.5 -- 49
label4.alignment = "Left" -- 49
label4.text = "TEAM MEMBER" -- 49
assessment:addChild(label4) -- 49
local item1 = MissionTab{title = missionTitle or '地底的喧嚣', status = "Complete", mode = missionCategory or 'Main', y = 407, x = 582} -- 53
assessment:addChild(item1) -- 53
if not missionMode then -- 54
local item2 = MissionTab{title = "饕餮骚动中", status = "(15/30)", mode = "Side", y = 315, x = 582} -- 55
assessment:addChild(item2) -- 55
local item3 = MissionTab{title = "黑暗中的残影", status = "Failed", mode = "Map", y = 223, x = 582} -- 56
assessment:addChild(item3) -- 56
end -- 57
local rewardArea = ScrollArea{scrollBar = missionMode == true, paddingX = 0, width = 964, y = -166, height = 500, x = 582} -- 58
assessment:addChild(rewardArea) -- 58
do -- 59
local view = rewardArea.view -- 60
if not missionMode then -- 61
local item4 = RewardItem{} -- 61
view:addChild(item4) -- 61
end -- 61
if not missionMode then -- 62
local item5 = RewardItem{} -- 62
view:addChild(item5) -- 62
end -- 62
if not missionMode then -- 63
local item6 = RewardItem{} -- 63
view:addChild(item6) -- 63
end -- 63
if not missionMode then -- 64
local item7 = RewardItem{} -- 64
view:addChild(item7) -- 64
end -- 64
if not missionMode then -- 65
local item8 = RewardItem{} -- 65
view:addChild(item8) -- 65
end -- 65
if not missionMode then -- 66
local item9 = RewardItem{} -- 66
view:addChild(item9) -- 66
end -- 66
if not missionMode then -- 67
local item10 = RewardItem{} -- 67
view:addChild(item10) -- 67
end -- 67
if not missionMode then -- 68
local item11 = RewardItem{} -- 68
view:addChild(item11) -- 68
end -- 68
if not missionMode then -- 69
local item12 = RewardItem{} -- 69
view:addChild(item12) -- 69
end -- 69
if not missionMode then -- 70
local item13 = RewardItem{} -- 70
view:addChild(item13) -- 70
end -- 70
end -- 72
rewardArea:adjustSizeWithAlign("Auto", 0, Size(964, 500)) -- 73
local memberArea = ScrollArea{scrollBar = false, height = 843, width = 964, y = 24, paddingY = 0} -- 75
assessment:addChild(memberArea) -- 75
do -- 76
local view = memberArea.view -- 77
if not missionMode then -- 78
local item14 = MemberView{} -- 78
view:addChild(item14) -- 78
end -- 78
if not missionMode then -- 79
local item15 = MemberView{} -- 79
view:addChild(item15) -- 79
end -- 79
if not missionMode then -- 80
local item16 = MemberView{} -- 80
view:addChild(item16) -- 80
end -- 80
if not missionMode then -- 81
local item17 = MemberView{} -- 81
view:addChild(item17) -- 81
end -- 81
if not missionMode then -- 82
local item18 = MemberView{} -- 82
view:addChild(item18) -- 82
end -- 82
end -- 84
memberArea:adjustSizeWithAlign("Horizontal", 0, Size(964, 843)) -- 85
local tacticReview = Node() -- 89
tacticReview.visible = false -- 89
tacticReview.order = 1 -- 89
left:addChild(tacticReview) -- 89
local sprite2 = Sprite("ar.clip|lsdar_settlement_role_bg") -- 90
sprite2.x = 342 -- 90
sprite2.y = 5 -- 90
tacticReview:addChild(sprite2) -- 90
local tacticArea = ScrollArea{scrollBar = false, height = 739, width = 476, x = 942, y = 10, paddingY = 0} -- 91
tacticReview:addChild(tacticArea) -- 91
do -- 92
local view = tacticArea.view -- 93
local item19 = TacticReview{score = "S"} -- 94
view:addChild(item19) -- 94
local item20 = TacticReview{score = "A"} -- 95
view:addChild(item20) -- 95
local item21 = TacticReview{score = "B"} -- 96
view:addChild(item21) -- 96
local item22 = TacticReview{score = "C"} -- 97
view:addChild(item22) -- 97
local item23 = TacticReview{score = "C"} -- 98
view:addChild(item23) -- 98
end -- 100
tacticArea:adjustSizeWithAlign("Horizontal", 0, Size(476, 739)) -- 101
local right = AlignNode{vAlign = "Center", hAlign = "Right"} -- 105
settlement:addChild(right) -- 105
local node2 = Node() -- 106
node2.y = 510.5 -- 106
node2.opacity = 0.1 -- 106
node2.scaleX = 1.5 -- 106
node2.scaleY = 1.5 -- 106
right:addChild(node2) -- 106
local item24 = MovingText{offsetY = 0, color3 = 0xffffff, fontSize = 100, textBG = "MISSION COMPLETE     MISSION COMPLETE", y = -75, x = -2000} -- 107
node2:addChild(item24) -- 107
local mask = item24.mask -- 108
local item25 = SolidRect{height = 75, width = 2000} -- 109
mask:addChild(item25) -- 109
local againButton = PropButton{text = againText or '再次行动', y = -546, x = -646} -- 113
right:addChild(againButton) -- 113
settlement.againButton = againButton -- 113
local baseButton = PropButton{text = baseText or '返回基地', y = -546, x = -273} -- 114
right:addChild(baseButton) -- 114
settlement.baseButton = baseButton -- 114
if missionMode then require("UI.ResultDetails").success(settlement, rewardArea, memberArea, args) end -- 116
settlement:slot("AlignLayout",function(w, h) -- 117
do -- 117
	local scale = h / H -- 120
	rc:removeFromParent() -- 121
	rc = SolidRect({ -- 122
		y = -618.5, -- 122
		width = w / scale, -- 122
		height = 1129, -- 122
		color = 0xb2000000 -- 122
	}) -- 122
	left:addChild(rc) -- 123
	mask:removeFromParent() -- 124
	mask = SolidRect({ -- 125
		width = w, -- 125
		height = h, -- 125
		color = 0x66000000 -- 125
	}) -- 125
	bk:addChild(mask) -- 126
	local _list_0 = { -- 127
		left, -- 127
		right -- 127
	} -- 127
	for _index_0 = 1, #_list_0 do -- 127
		local item = _list_0[_index_0] -- 127
		item.scaleX = scale -- 128
		item.scaleY = scale -- 129
	end -- 127
	local memberWidth = w / scale - 1115 -- 130
	do -- 131
		local _with_0 = memberArea -- 131
		_with_0.x = 1115 + memberWidth / 2 -- 132
		if missionMode then -- 133
			settlement:layoutResultDetails(memberWidth) -- 134
		else -- 136
			_with_0:adjustSizeWithAlign("Horizontal", 0, Size(memberWidth, 843)) -- 136
		end -- 133
	end -- 131
	local tacticWidth = w / scale - 704 -- 137
	local _with_0 = tacticArea -- 138
	_with_0.x = 704 + tacticWidth / 2 -- 139
	_with_0:adjustSizeWithAlign("Horizontal", 0, Size(tacticWidth, 739)) -- 140
end -- 117
end) -- 118
return settlement -- 118
end