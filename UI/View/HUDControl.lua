-- [xml]: UI/View/HUDControl.xml
local AlignNode = require("UI.Control.Basic.AlignNode") -- 2
local Skill = require("UI.Skill") -- 3
local CmdButtonL = require("UI.CmdButtonL") -- 4
local CmdButtonS = require("UI.CmdButtonS") -- 5
local HeadBox = require("UI.HeadBox") -- 6
local MessageBox = require("UI.MessageBox") -- 7
local HUDMove = require("UI.HUDMove") -- 8
local H <const> = 1563 -- 10
return function(args) -- 1
local _ENV = Dora(args) -- 1
local item1 = AlignNode{isRoot = true, inUI = true} -- 11
local topControl = AlignNode{vAlign = "Top", hAlign = "Center"} -- 12
item1:addChild(topControl) -- 12
local sprite1 = Sprite("ar.clip|lsdar_bossblood_1") -- 13
sprite1.y = -102.5 -- 13
sprite1.visible = false -- 13
topControl:addChild(sprite1) -- 13
local sprite2 = Sprite("ar.clip|lsdar_bossblood_2") -- 14
sprite2.y = -112.5 -- 14
sprite2.visible = false -- 14
topControl:addChild(sprite2) -- 14
local sprite3 = Sprite("ar.clip|lsdar_bossblood_3") -- 15
sprite3.y = -85 -- 15
topControl:addChild(sprite3) -- 15
local ltControl = AlignNode{vAlign = "Top", hAlign = "Left"} -- 17
item1:addChild(ltControl) -- 17
local node1 = Node() -- 18
node1.angleY = -20 -- 18
node1.visible = false -- 18
ltControl:addChild(node1) -- 18
local sprite4 = Sprite("ar.clip|lsd_ar_display") -- 19
sprite4.anchor = Vec2(0,1) -- 19
sprite4.x = 5 -- 19
sprite4.y = -150 -- 19
sprite4.scaleX = 0.7 -- 19
sprite4.scaleY = 0.7 -- 19
node1:addChild(sprite4) -- 19
local leftControl = AlignNode{vAlign = "Center", hAlign = "Left"} -- 22
item1:addChild(leftControl) -- 22
local node2 = Node() -- 23
node2.angleY = -20 -- 23
node2.visible = false -- 23
leftControl:addChild(node2) -- 23
local item2 = CmdButtonL{y = 462, x = 202.5, selected = true, text = "团队指令"} -- 24
node2:addChild(item2) -- 24
local item3 = CmdButtonS{y = 338, x = 303, action = "follow", text = "跟随"} -- 25
node2:addChild(item3) -- 25
local item4 = CmdButtonS{y = 338 - 105, x = 303, action = "cover", selected = true, text = "掩护"} -- 26
node2:addChild(item4) -- 26
local item5 = CmdButtonS{y = 338 - 105 * 2, x = 303, action = "assemble", text = "集结"} -- 27
node2:addChild(item5) -- 27
local item6 = CmdButtonS{y = 338 - 105 * 3, x = 303, action = "fight", text = "进攻"} -- 28
node2:addChild(item6) -- 28
local item7 = CmdButtonS{y = 338 - 105 * 4, x = 303, action = "retreat", text = "撤退"} -- 29
node2:addChild(item7) -- 29
local lbControl = AlignNode{vAlign = "Bottom", hAlign = "Left"} -- 32
item1:addChild(lbControl) -- 32
local node3 = Node() -- 33
node3.angleY = -20 -- 33
lbControl:addChild(node3) -- 33
local item8 = MessageBox{y = 530, x = 414} -- 34
node3:addChild(item8) -- 34
local item9 = HUDMove{visible = false, y = 230, x = 414} -- 35
node3:addChild(item9) -- 35
local rightControl = AlignNode{vAlign = "Center", hAlign = "Right"} -- 38
item1:addChild(rightControl) -- 38
local node4 = Node() -- 39
node4.angleY = 20 -- 39
node4.visible = false -- 39
rightControl:addChild(node4) -- 39
local item10 = HeadBox{y = 580, x = -223} -- 40
node4:addChild(item10) -- 40
local item11 = HeadBox{selected = true, y = 580 - 170, x = -223} -- 41
node4:addChild(item11) -- 41
local item12 = HeadBox{y = 580 - 170 * 2, x = -223} -- 42
node4:addChild(item12) -- 42
local item13 = HeadBox{y = 580 - 170 * 3, x = -223} -- 43
node4:addChild(item13) -- 43
local node5 = Node() -- 44
node5.x = -518 -- 44
node5.y = 612 -- 44
node4:addChild(node5) -- 44
local item14 = CmdButtonS{text = "共享视野"} -- 45
node5:addChild(item14) -- 45
local item15 = CmdButtonS{y = -105, action = "follow", text = "跟随"} -- 46
node5:addChild(item15) -- 46
local item16 = CmdButtonS{y = -105 * 2, action = "cover", selected = true, text = "掩护"} -- 47
node5:addChild(item16) -- 47
local item17 = CmdButtonS{y = -105 * 3, action = "assemble", text = "集结"} -- 48
node5:addChild(item17) -- 48
local item18 = CmdButtonS{y = -105 * 4, action = "fight", text = "进攻"} -- 49
node5:addChild(item18) -- 49
local item19 = CmdButtonS{y = -105 * 5, action = "retreat", text = "撤退"} -- 50
node5:addChild(item19) -- 50
local rbControl = AlignNode{vAlign = "Bottom", hAlign = "Right"} -- 54
item1:addChild(rbControl) -- 54
local node6 = Node() -- 55
node6.angleY = 20 -- 55
node6.visible = true -- 55
rbControl:addChild(node6) -- 55
local skillArea = Node() -- 56
skillArea.x = -580 -- 56
skillArea.y = 365 -- 56
skillArea.size = Size(888,592) -- 56
node6:addChild(skillArea) -- 56
local item20 = Skill{placeHolder = true, visible = false} -- 57
skillArea:addChild(item20) -- 57
local item21 = Skill{placeHolder = true, visible = false} -- 58
skillArea:addChild(item21) -- 58
local item22 = Skill{placeHolder = true, visible = false} -- 59
skillArea:addChild(item22) -- 59
local item23 = Skill{placeHolder = true, visible = false} -- 60
skillArea:addChild(item23) -- 60
local item24 = Skill{placeHolder = true, visible = false} -- 61
skillArea:addChild(item24) -- 61
local weapon = Skill{visible = false} -- 62
skillArea:addChild(weapon) -- 62
item1.weapon = weapon -- 62
weapon:slot("TapBegan",function() -- 63
emit("Skill.Began") -- 64
end) -- 64
weapon:slot("TapEnded",function() -- 66
emit("Skill.Ended") -- 67
end) -- 67
skillArea:alignItems(0) -- 70
item1:slot("AlignLayout",function(_w, h) -- 74
do -- 74
	local scale = h / H -- 76
	local _list_0 = { -- 77
		topControl, -- 77
		ltControl, -- 77
		leftControl, -- 77
		lbControl, -- 77
		rightControl, -- 77
		rbControl -- 77
	} -- 77
	for _index_0 = 1, #_list_0 do -- 77
		local item = _list_0[_index_0] -- 77
		item.scaleX = scale -- 78
		item.scaleY = scale -- 79
	end -- 79
end -- 79
end) -- 75
return item1 -- 75
end