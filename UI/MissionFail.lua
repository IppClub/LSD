-- [xml]: UI/MissionFail.xml
local SolidRect = require("UI.View.Shape.SolidRect") -- 2
local AlignNode = require("UI.Control.Basic.AlignNode") -- 3
local MovingText = require("UI.MovingText") -- 4
local FullScreenMask = require("UI.FullScreenMask") -- 5
local PropButton = require("UI.PropButton") -- 6
local H <const> = 1563 -- 8
return function(args) -- 1
local _ENV = Dora(args) -- 1
local failure = AlignNode{isRoot = true, inUI = true} -- 9
local item1 = FullScreenMask{} -- 10
failure:addChild(item1) -- 10
local left = AlignNode{vAlign = "Center", hAlign = "Left"} -- 11
failure:addChild(left) -- 11
local rc = SolidRect{color = 0xb2000000, height = 592, width = 3258, y = -296} -- 12
left:addChild(rc) -- 12
local logo = Grid("ar.clip|lsdar_settlement_logo", 1, 1) -- 13
logo.x = 438.5 -- 13
logo.y = -268.5 -- 13
logo.order = 1 -- 13
left:addChild(logo) -- 13
do -- 13
	logo:moveUV(1, 2, Vec2(0, -537)) -- 15
	logo:moveUV(2, 2, Vec2(0, -537)) -- 16
end -- 13
local label1 = Label("SourceHanSansCN-Regular",missionMode and 140 or 300) -- 19
label1.anchor = Vec2(0,label1.anchor.y) -- 19
label1.x = 129.5 -- 19
label1.y = 268.5 -- 19
label1.color3 = Color3(0xffffff) -- 19
label1.order = 1 -- 19
label1.alignment = "Left" -- 19
label1.spacing = 10 -- 19
label1.text = resultTitle or '行动失败' -- 19
left:addChild(label1) -- 19
local label2 = Label("SourceHanSansCN-Regular",55) -- 23
label2.anchor = Vec2(0,label2.anchor.y) -- 23
label2.x = missionMode and 129.5 or 787.5 -- 23
label2.y = missionMode and 420 or 225 -- 23
label2.color3 = Color3(0xffffff) -- 23
label2.opacity = 0.7 -- 23
label2.order = 1 -- 23
label2.alignment = "Center" -- 23
label2.text = missionTitle or '2-3地底的喧嚣' -- 23
left:addChild(label2) -- 23
local center = AlignNode{vAlign = "Center", hAlign = "Center"} -- 28
failure:addChild(center) -- 28
local sprite1 = Sprite("ar.clip|lsdar_settlement_icon_1") -- 29
sprite1.x = -540 -- 29
center:addChild(sprite1) -- 29
local sprite2 = Sprite("ar.clip|lsdar_settlement_icon_2") -- 30
center:addChild(sprite2) -- 30
local sprite3 = Sprite("ar.clip|lsdar_settlement_icon_3") -- 31
sprite3.x = 540 -- 31
center:addChild(sprite3) -- 31
local sprite4 = Sprite("ar.clip|lsdar_settlement_divider") -- 32
sprite4.x = -540 -- 32
sprite4.y = -170 -- 32
center:addChild(sprite4) -- 32
local sprite5 = Sprite("ar.clip|lsdar_settlement_divider") -- 33
sprite5.y = -170 -- 33
center:addChild(sprite5) -- 33
local sprite6 = Sprite("ar.clip|lsdar_settlement_divider") -- 34
sprite6.x = 540 -- 34
sprite6.y = -170 -- 34
center:addChild(sprite6) -- 34
local sprite7 = Sprite("ar.clip|lsdar_settlement_ribbon_1") -- 35
sprite7.anchor = Vec2(sprite7.anchor.x,1) -- 35
sprite7.y = -335 -- 35
center:addChild(sprite7) -- 35
local label3 = Label("SourceHanSansCN-Regular",45) -- 36
label3.anchor = Vec2(label3.anchor.x,1) -- 36
label3.x = -540 -- 36
label3.y = -115 -- 36
label3.color3 = Color3(0xffffff) -- 36
label3.order = 1 -- 36
label3.alignment = "Center" -- 36
label3.text = "学员培养" -- 36
center:addChild(label3) -- 36
local label4 = Label("SourceHanSansCN-Regular",45) -- 40
label4.anchor = Vec2(label4.anchor.x,1) -- 40
label4.y = -115 -- 40
label4.color3 = Color3(0xffffff) -- 40
label4.order = 1 -- 40
label4.alignment = "Center" -- 40
label4.text = "装备强化" -- 40
center:addChild(label4) -- 40
local label5 = Label("SourceHanSansCN-Regular",45) -- 44
label5.anchor = Vec2(label5.anchor.x,1) -- 44
label5.x = 540 -- 44
label5.y = -115 -- 44
label5.color3 = Color3(0xffffff) -- 44
label5.order = 1 -- 44
label5.alignment = "Center" -- 44
label5.text = "更多战术" -- 44
center:addChild(label5) -- 44
local label6 = Label("SourceHanSansCN-Regular",35) -- 48
label6.anchor = Vec2(label6.anchor.x,1) -- 48
label6.x = -540 -- 48
label6.y = -190 -- 48
label6.color3 = Color3(0xffffff) -- 48
label6.opacity = 0.5 -- 48
label6.order = 1 -- 48
label6.alignment = "Center" -- 48
label6.text = "提升学员对策" -- 48
center:addChild(label6) -- 48
local label7 = Label("SourceHanSansCN-Regular",35) -- 52
label7.anchor = Vec2(label7.anchor.x,1) -- 52
label7.y = -190 -- 52
label7.color3 = Color3(0xffffff) -- 52
label7.opacity = 0.5 -- 52
label7.order = 1 -- 52
label7.alignment = "Center" -- 52
label7.text = missionMode and '检查破甲搭配与消耗' or '配备更好的装备' -- 52
center:addChild(label7) -- 52
local label8 = Label("SourceHanSansCN-Regular",35) -- 56
label8.anchor = Vec2(label8.anchor.x,1) -- 56
label8.x = 540 -- 56
label8.y = -190 -- 56
label8.color3 = Color3(0xffffff) -- 56
label8.opacity = 0.5 -- 56
label8.order = 1 -- 56
label8.alignment = "Center" -- 56
label8.text = "组建更适合的编队" -- 56
center:addChild(label8) -- 56
local label9 = Label("SourceHanSansCN-Regular",35) -- 60
label9.anchor = Vec2(label9.anchor.x,1) -- 60
label9.y = -357 -- 60
label9.color3 = Color3(0xffffff) -- 60
label9.opacity = 0.3 -- 60
label9.order = 1 -- 60
label9.alignment = "Center" -- 60
label9.text = missionMode and '确认损耗后重新配置或返回' or '点击空白处退出' -- 60
center:addChild(label9) -- 60
local right = AlignNode{vAlign = "Center", hAlign = "Right"} -- 65
failure:addChild(right) -- 65
local node1 = Node() -- 66
node1.y = 296 -- 66
node1.opacity = 0.1 -- 66
node1.scaleX = 1.5 -- 66
node1.scaleY = 1.5 -- 66
right:addChild(node1) -- 66
local item2 = MovingText{offsetY = 0, color3 = 0xffffff, fontSize = 100, y = -75, textBG = "MISSION FAILED     MISSION FAILED", x = -2000} -- 67
node1:addChild(item2) -- 67
local mask = item2.mask -- 68
local item3 = SolidRect{height = 75, width = 2000} -- 69
mask:addChild(item3) -- 69
if missionMode then require("UI.ResultDetails").failure(failure, center, args) end -- 74
failure:slot("AlignLayout",function(w, h) -- 75
do -- 75
	local scale = h / H -- 78
	rc:removeFromParent() -- 79
	rc = SolidRect({ -- 80
		y = -296, -- 80
		width = w / scale, -- 80
		height = 592, -- 80
		color = 0xb2000000 -- 80
	}) -- 80
	left:addChild(rc) -- 81
	local _list_0 = { -- 82
		left, -- 82
		center, -- 82
		right -- 82
	} -- 82
	for _index_0 = 1, #_list_0 do -- 82
		local item = _list_0[_index_0] -- 82
		item.scaleX = scale -- 83
		item.scaleY = scale -- 84
	end -- 82
end -- 75
end) -- 76
return failure -- 76
end