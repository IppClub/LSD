-- [xml]: UI/MissionFail.xml
local SolidRect = require("UI.View.Shape.SolidRect") -- 2
local AlignNode = require("UI.Control.Basic.AlignNode") -- 3
local MovingText = require("UI.MovingText") -- 4
local FullScreenMask = require("UI.FullScreenMask") -- 5
local H <const> = 1563 -- 7
return function(args) -- 1
local _ENV = Dora(args) -- 1
local item1 = AlignNode{isRoot = true, inUI = true} -- 8
local item2 = FullScreenMask{} -- 9
item1:addChild(item2) -- 9
local left = AlignNode{vAlign = "Center", hAlign = "Left"} -- 10
item1:addChild(left) -- 10
local rc = SolidRect{color = 0xb2000000, height = 592, width = 3258, y = -296} -- 11
left:addChild(rc) -- 11
local logo = Grid("ar.clip|lsdar_settlement_logo", 1, 1) -- 12
logo.x = 438.5 -- 12
logo.y = -268.5 -- 12
logo.order = 1 -- 12
left:addChild(logo) -- 12
do -- 12
	logo:moveUV(1, 2, Vec2(0, -537)) -- 14
	logo:moveUV(2, 2, Vec2(0, -537)) -- 15
end -- 15
local label1 = Label("SourceHanSansCN-Regular",300) -- 18
label1.anchor = Vec2(0,label1.anchor.y) -- 18
label1.x = 129.5 -- 18
label1.y = 268.5 -- 18
label1.color3 = Color3(0xffffff) -- 18
label1.order = 1 -- 18
label1.alignment = "Left" -- 18
label1.spacing = 10 -- 18
label1.text = "行动失败" -- 18
left:addChild(label1) -- 18
local label2 = Label("SourceHanSansCN-Regular",55) -- 22
label2.anchor = Vec2(0,label2.anchor.y) -- 22
label2.x = 787.5 -- 22
label2.y = 225 -- 22
label2.color3 = Color3(0xffffff) -- 22
label2.opacity = 0.7 -- 22
label2.order = 1 -- 22
label2.alignment = "Center" -- 22
label2.text = "2-3地底的喧嚣" -- 22
left:addChild(label2) -- 22
local center = AlignNode{vAlign = "Center", hAlign = "Center"} -- 27
item1:addChild(center) -- 27
local sprite1 = Sprite("ar.clip|lsdar_settlement_icon_1") -- 28
sprite1.x = -540 -- 28
center:addChild(sprite1) -- 28
local sprite2 = Sprite("ar.clip|lsdar_settlement_icon_2") -- 29
center:addChild(sprite2) -- 29
local sprite3 = Sprite("ar.clip|lsdar_settlement_icon_3") -- 30
sprite3.x = 540 -- 30
center:addChild(sprite3) -- 30
local sprite4 = Sprite("ar.clip|lsdar_settlement_divider") -- 31
sprite4.x = -540 -- 31
sprite4.y = -170 -- 31
center:addChild(sprite4) -- 31
local sprite5 = Sprite("ar.clip|lsdar_settlement_divider") -- 32
sprite5.y = -170 -- 32
center:addChild(sprite5) -- 32
local sprite6 = Sprite("ar.clip|lsdar_settlement_divider") -- 33
sprite6.x = 540 -- 33
sprite6.y = -170 -- 33
center:addChild(sprite6) -- 33
local sprite7 = Sprite("ar.clip|lsdar_settlement_ribbon_1") -- 34
sprite7.anchor = Vec2(sprite7.anchor.x,1) -- 34
sprite7.y = -335 -- 34
center:addChild(sprite7) -- 34
local label3 = Label("SourceHanSansCN-Regular",45) -- 35
label3.anchor = Vec2(label3.anchor.x,1) -- 35
label3.x = -540 -- 35
label3.y = -115 -- 35
label3.color3 = Color3(0xffffff) -- 35
label3.order = 1 -- 35
label3.alignment = "Center" -- 35
label3.text = "学员培养" -- 35
center:addChild(label3) -- 35
local label4 = Label("SourceHanSansCN-Regular",45) -- 39
label4.anchor = Vec2(label4.anchor.x,1) -- 39
label4.y = -115 -- 39
label4.color3 = Color3(0xffffff) -- 39
label4.order = 1 -- 39
label4.alignment = "Center" -- 39
label4.text = "装备强化" -- 39
center:addChild(label4) -- 39
local label5 = Label("SourceHanSansCN-Regular",45) -- 43
label5.anchor = Vec2(label5.anchor.x,1) -- 43
label5.x = 540 -- 43
label5.y = -115 -- 43
label5.color3 = Color3(0xffffff) -- 43
label5.order = 1 -- 43
label5.alignment = "Center" -- 43
label5.text = "更多战术" -- 43
center:addChild(label5) -- 43
local label6 = Label("SourceHanSansCN-Regular",35) -- 47
label6.anchor = Vec2(label6.anchor.x,1) -- 47
label6.x = -540 -- 47
label6.y = -190 -- 47
label6.color3 = Color3(0xffffff) -- 47
label6.opacity = 0.5 -- 47
label6.order = 1 -- 47
label6.alignment = "Center" -- 47
label6.text = "提升学员对策" -- 47
center:addChild(label6) -- 47
local label7 = Label("SourceHanSansCN-Regular",35) -- 51
label7.anchor = Vec2(label7.anchor.x,1) -- 51
label7.y = -190 -- 51
label7.color3 = Color3(0xffffff) -- 51
label7.opacity = 0.5 -- 51
label7.order = 1 -- 51
label7.alignment = "Center" -- 51
label7.text = "配备更好的装备" -- 51
center:addChild(label7) -- 51
local label8 = Label("SourceHanSansCN-Regular",35) -- 55
label8.anchor = Vec2(label8.anchor.x,1) -- 55
label8.x = 540 -- 55
label8.y = -190 -- 55
label8.color3 = Color3(0xffffff) -- 55
label8.opacity = 0.5 -- 55
label8.order = 1 -- 55
label8.alignment = "Center" -- 55
label8.text = "组建更适合的编队" -- 55
center:addChild(label8) -- 55
local label9 = Label("SourceHanSansCN-Regular",35) -- 59
label9.anchor = Vec2(label9.anchor.x,1) -- 59
label9.y = -357 -- 59
label9.color3 = Color3(0xffffff) -- 59
label9.opacity = 0.3 -- 59
label9.order = 1 -- 59
label9.alignment = "Center" -- 59
label9.text = "点击空白处退出" -- 59
center:addChild(label9) -- 59
local right = AlignNode{vAlign = "Center", hAlign = "Right"} -- 64
item1:addChild(right) -- 64
local node1 = Node() -- 65
node1.y = 296 -- 65
node1.opacity = 0.1 -- 65
node1.scaleX = 1.5 -- 65
node1.scaleY = 1.5 -- 65
right:addChild(node1) -- 65
local item3 = MovingText{offsetY = 0, color3 = 0xffffff, fontSize = 100, y = -75, textBG = "MISSION FAILED     MISSION FAILED", x = -2000} -- 66
node1:addChild(item3) -- 66
local mask = item3.mask -- 67
local item4 = SolidRect{height = 75, width = 2000} -- 68
mask:addChild(item4) -- 68
item1:slot("AlignLayout",function(w, h) -- 73
do -- 73
	local scale = h / H -- 76
	rc:removeFromParent() -- 77
	rc = SolidRect({ -- 78
		y = -296, -- 78
		width = w / scale, -- 78
		height = 592, -- 78
		color = 0xb2000000 -- 78
	}) -- 78
	left:addChild(rc) -- 79
	local _list_0 = { -- 80
		left, -- 80
		center, -- 80
		right -- 80
	} -- 80
	for _index_0 = 1, #_list_0 do -- 80
		local item = _list_0[_index_0] -- 80
		item.scaleX = scale -- 81
		item.scaleY = scale -- 82
	end -- 82
end -- 82
end) -- 74
return item1 -- 74
end