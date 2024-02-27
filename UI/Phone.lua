-- [xml]: UI/Phone.xml
local SolidRect = require("UI.View.Shape.SolidRect") -- 2
local AlignNode = require("UI.Control.Basic.AlignNode") -- 3
local PhoneTabButton = require("UI.PhoneTabButton") -- 4
local MovingText = require("UI.MovingText") -- 5
local PhoneMessageTab = require("UI.PhoneMessageTab") -- 6
local PhoneMissionTab = require("UI.PhoneMissionTab") -- 7
local PhoneSetting = require("UI.PhoneSetting") -- 8
local H <const> = 1563 -- 10
-- local curTab = 1 -- 11
return function(args) -- 1
local _ENV = Dora(args) -- 1
local phone = AlignNode{isRoot = true, inUI = true} -- 13
local screenArea = AlignNode{vAlign = "Center", hAlign = "Center"} -- 15
phone:addChild(screenArea) -- 15
local sprite1 = Sprite("phone.clip|phone_bg") -- 18
screenArea:addChild(sprite1) -- 18
local content = Node() -- 19
content.x = 415 -- 19
content.y = 600 -- 19
screenArea:addChild(content) -- 19
local item1 = PhoneMessageTab{date = 3.4, msg = "快到研发室来！", username = "妮妮莉特", time = "17:28", avatar = "phone.clip|phone_icon_set_3"} -- 20
content:addChild(item1) -- 20
local item2 = PhoneMessageTab{y = -145, date = 3.4, msg = "地下城疑似怪物入侵", time = "16:16", avatar = "phone.clip|phone_icon_set_3"} -- 21
content:addChild(item2) -- 21
local top = Node() -- 25
top.y = 650 -- 25
screenArea:addChild(top) -- 25
local sprite2 = Sprite("phone.clip|phone_signal_4") -- 26
sprite2.x = -375 -- 26
sprite2.y = -0 -- 26
top:addChild(sprite2) -- 26
local topname1 = Node() -- 27
topname1.visible = true -- 27
top:addChild(topname1) -- 27
phone.topname1 = topname1 -- 27
local sprite3 = Sprite("phone.clip|phone_icon_com_1") -- 28
sprite3.x = -120 -- 28
sprite3.y = -0 -- 28
topname1:addChild(sprite3) -- 28
local label1 = Label("SourceHanSansCN-Regular",65) -- 29
label1.y = -0 -- 29
label1.color3 = Color3(0xffffff) -- 29
label1.alignment = "Center" -- 29
label1.text = "通讯" -- 29
topname1:addChild(label1) -- 29
local topname2 = Node() -- 35
topname2.visible = false -- 35
top:addChild(topname2) -- 35
phone.topname2 = topname2 -- 35
local sprite4 = Sprite("phone.clip|phone_icon_mission_1") -- 36
sprite4.x = -120 -- 36
sprite4.y = -0 -- 36
topname2:addChild(sprite4) -- 36
local label2 = Label("SourceHanSansCN-Regular",65) -- 37
label2.y = -0 -- 37
label2.color3 = Color3(0xffffff) -- 37
label2.alignment = "Center" -- 37
label2.text = "任务" -- 37
topname2:addChild(label2) -- 37
local topname3 = Node() -- 43
topname3.visible = false -- 43
top:addChild(topname3) -- 43
phone.topname3 = topname3 -- 43
local sprite5 = Sprite("phone.clip|phone_icon_collect_1") -- 44
sprite5.x = -120 -- 44
sprite5.y = -0 -- 44
topname3:addChild(sprite5) -- 44
local label3 = Label("SourceHanSansCN-Regular",65) -- 45
label3.y = -0 -- 45
label3.color3 = Color3(0xffffff) -- 45
label3.alignment = "Center" -- 45
label3.text = "服务" -- 45
topname3:addChild(label3) -- 45
local topname4 = Node() -- 51
topname4.visible = false -- 51
top:addChild(topname4) -- 51
phone.topname4 = topname4 -- 51
local sprite6 = Sprite("phone.clip|phone_icon_set_1") -- 52
sprite6.x = -120 -- 52
sprite6.y = -0 -- 52
topname4:addChild(sprite6) -- 52
local label4 = Label("SourceHanSansCN-Regular",65) -- 53
label4.y = -0 -- 53
label4.color3 = Color3(0xffffff) -- 53
label4.alignment = "Center" -- 53
label4.text = "设置" -- 53
topname4:addChild(label4) -- 53
local sprite7 = Sprite("phone.clip|phone_electric_5") -- 60
sprite7.x = 355 -- 60
sprite7.y = -0 -- 60
top:addChild(sprite7) -- 60
local node1 = Node() -- 61
node1.opacity = 0.3 -- 61
top:addChild(node1) -- 61
local item3 = MovingText{offsetY = 0, color3 = 0xffffff, fontSize = 150, y = -25, textBG = "COMMUNITY", x = -200} -- 62
node1:addChild(item3) -- 62
local mask = item3.mask -- 63
local item4 = SolidRect{height = 85, width = 600} -- 64
mask:addChild(item4) -- 64
local node2 = Node() -- 72
node2.y = -599 -- 72
screenArea:addChild(node2) -- 72
local tab1 = PhoneTabButton{x = -211, index = 1, tabIcon = "phone.clip|phone_icon_com_"} -- 73
node2:addChild(tab1) -- 73
tab1:slot("Tapped",function() -- 74
do -- 74
	topname1.visible = true -- 77
	topname2.visible = false -- 78
	topname3.visible = false -- 79
	topname4.visible = false -- 80
	content:removeFromParent() -- 81
	do -- 82
		local _with_0 = Node() -- 82
		_with_0.x = 415 -- 83
		_with_0.y = 600 -- 84
		content = _with_0 -- 82
	end -- 82
	content:addChild(PhoneMissionTab({ -- 85
		name = '地底的喧嚣' -- 85
	})) -- 85
	screenArea:addChild(content) -- 87
end -- 87
end) -- 75
local tab2 = PhoneTabButton{x = -3, index = 2, tabIcon = "phone.clip|phone_icon_mission_"} -- 91
node2:addChild(tab2) -- 91
tab2:slot("Tapped",function() -- 92
do -- 92
	topname1.visible = false -- 95
	topname2.visible = true -- 96
	topname3.visible = false -- 97
	topname4.visible = false -- 98
	content:removeFromParent() -- 99
	do -- 100
		local _with_0 = Node() -- 100
		_with_0.x = 415 -- 101
		_with_0.y = 600 -- 102
		content = _with_0 -- 100
	end -- 100
	content:addChild(PhoneMessageTab({ -- 103
		avatar = "phone.clip|phone_icon_set_3", -- 103
		username = "妮妮莉特", -- 103
		msg = "快到研发室来！", -- 103
		date = "3.4", -- 103
		time = "17:28" -- 103
	})) -- 103
	screenArea:addChild(content) -- 104
end -- 104
end) -- 93
local tab3 = PhoneTabButton{x = 206, index = 3, tabIcon = "phone.clip|phone_icon_collect_"} -- 108
node2:addChild(tab3) -- 108
local tab4 = PhoneTabButton{x = 414, index = 4, tabIcon = "phone.clip|phone_icon_set_"} -- 109
node2:addChild(tab4) -- 109
tab4:slot("Tapped",function() -- 110
do -- 110
	topname1.visible = false -- 113
	topname2.visible = false -- 114
	topname3.visible = false -- 115
	topname4.visible = true -- 116
	content:removeFromParent() -- 117
	do -- 118
		local _with_0 = Node() -- 118
		_with_0.x = 415 -- 119
		_with_0.y = 600 -- 120
		content = _with_0 -- 118
	end -- 118
	content:addChild(PhoneSetting()) -- 121
	screenArea:addChild(content) -- 122
end -- 122
end) -- 111
phone:slot("AlignLayout",function(_w,  h) -- 132
do -- 132
	local scale = h / H -- 134
	local _list_0 = { -- 135
		screenArea -- 135
	} -- 135
	for _index_0 = 1, #_list_0 do -- 135
		local item = _list_0[_index_0] -- 135
		item.scaleX = scale -- 136
		item.scaleY = scale -- 137
	end -- 137
end -- 137
end) -- 133
return phone -- 133
end