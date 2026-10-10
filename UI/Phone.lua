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
if storyMode then phone:cleanup(); return require("UI.StoryJournal")(args) end -- 14
local screenArea = AlignNode{vAlign = "Center", hAlign = "Center"} -- 16
phone:addChild(screenArea) -- 16
local sprite1 = Sprite("phone.clip|phone_bg") -- 19
screenArea:addChild(sprite1) -- 19
local content = Node() -- 20
content.x = 415 -- 20
content.y = 600 -- 20
screenArea:addChild(content) -- 20
local item1 = PhoneMessageTab{date = 3.4, msg = "快到研发室来！", username = "妮妮莉特", time = "17:28", avatar = "phone.clip|phone_icon_set_3"} -- 21
content:addChild(item1) -- 21
local item2 = PhoneMessageTab{y = -145, date = 3.4, msg = "地下城疑似怪物入侵", time = "16:16", avatar = "phone.clip|phone_icon_set_3"} -- 22
content:addChild(item2) -- 22
local top = Node() -- 26
top.y = 650 -- 26
screenArea:addChild(top) -- 26
local sprite2 = Sprite("phone.clip|phone_signal_4") -- 27
sprite2.x = -375 -- 27
sprite2.y = -0 -- 27
top:addChild(sprite2) -- 27
local topname1 = Node() -- 28
topname1.visible = true -- 28
top:addChild(topname1) -- 28
phone.topname1 = topname1 -- 28
local sprite3 = Sprite("phone.clip|phone_icon_com_1") -- 29
sprite3.x = -120 -- 29
sprite3.y = -0 -- 29
topname1:addChild(sprite3) -- 29
local label1 = Label("SourceHanSansCN-Regular",65) -- 30
label1.y = -0 -- 30
label1.color3 = Color3(0xffffff) -- 30
label1.alignment = "Center" -- 30
label1.text = "通讯" -- 30
topname1:addChild(label1) -- 30
local topname2 = Node() -- 36
topname2.visible = false -- 36
top:addChild(topname2) -- 36
phone.topname2 = topname2 -- 36
local sprite4 = Sprite("phone.clip|phone_icon_mission_1") -- 37
sprite4.x = -120 -- 37
sprite4.y = -0 -- 37
topname2:addChild(sprite4) -- 37
local label2 = Label("SourceHanSansCN-Regular",65) -- 38
label2.y = -0 -- 38
label2.color3 = Color3(0xffffff) -- 38
label2.alignment = "Center" -- 38
label2.text = "任务" -- 38
topname2:addChild(label2) -- 38
local topname3 = Node() -- 44
topname3.visible = false -- 44
top:addChild(topname3) -- 44
phone.topname3 = topname3 -- 44
local sprite5 = Sprite("phone.clip|phone_icon_collect_1") -- 45
sprite5.x = -120 -- 45
sprite5.y = -0 -- 45
topname3:addChild(sprite5) -- 45
local label3 = Label("SourceHanSansCN-Regular",65) -- 46
label3.y = -0 -- 46
label3.color3 = Color3(0xffffff) -- 46
label3.alignment = "Center" -- 46
label3.text = "服务" -- 46
topname3:addChild(label3) -- 46
local topname4 = Node() -- 52
topname4.visible = false -- 52
top:addChild(topname4) -- 52
phone.topname4 = topname4 -- 52
local sprite6 = Sprite("phone.clip|phone_icon_set_1") -- 53
sprite6.x = -120 -- 53
sprite6.y = -0 -- 53
topname4:addChild(sprite6) -- 53
local label4 = Label("SourceHanSansCN-Regular",65) -- 54
label4.y = -0 -- 54
label4.color3 = Color3(0xffffff) -- 54
label4.alignment = "Center" -- 54
label4.text = "设置" -- 54
topname4:addChild(label4) -- 54
local sprite7 = Sprite("phone.clip|phone_electric_5") -- 61
sprite7.x = 355 -- 61
sprite7.y = -0 -- 61
top:addChild(sprite7) -- 61
local node1 = Node() -- 62
node1.opacity = 0.3 -- 62
top:addChild(node1) -- 62
local item3 = MovingText{offsetY = 0, color3 = 0xffffff, fontSize = 150, y = -25, textBG = "COMMUNITY", x = -200} -- 63
node1:addChild(item3) -- 63
local mask = item3.mask -- 64
local item4 = SolidRect{height = 85, width = 600} -- 65
mask:addChild(item4) -- 65
local node2 = Node() -- 73
node2.y = -599 -- 73
screenArea:addChild(node2) -- 73
local tab1 = PhoneTabButton{x = -211, index = 1, tabIcon = "phone.clip|phone_icon_com_"} -- 74
node2:addChild(tab1) -- 74
tab1:slot("Tapped",function() -- 75
do -- 75
	topname1.visible = true -- 78
	topname2.visible = false -- 79
	topname3.visible = false -- 80
	topname4.visible = false -- 81
	content:removeFromParent() -- 82
	do -- 83
		local _with_0 = Node() -- 83
		_with_0.x = 415 -- 84
		_with_0.y = 600 -- 85
		content = _with_0 -- 83
	end -- 83
	content:addChild(PhoneMissionTab({ -- 86
		name = '地底的喧嚣' -- 86
	})) -- 86
	screenArea:addChild(content) -- 88
end -- 75
end) -- 76
local tab2 = PhoneTabButton{x = -3, index = 2, tabIcon = "phone.clip|phone_icon_mission_"} -- 92
node2:addChild(tab2) -- 92
tab2:slot("Tapped",function() -- 93
do -- 93
	topname1.visible = false -- 96
	topname2.visible = true -- 97
	topname3.visible = false -- 98
	topname4.visible = false -- 99
	content:removeFromParent() -- 100
	do -- 101
		local _with_0 = Node() -- 101
		_with_0.x = 415 -- 102
		_with_0.y = 600 -- 103
		content = _with_0 -- 101
	end -- 101
	content:addChild(PhoneMessageTab({ -- 104
		avatar = "phone.clip|phone_icon_set_3", -- 104
		username = "妮妮莉特", -- 104
		msg = "快到研发室来！", -- 104
		date = "3.4", -- 104
		time = "17:28" -- 104
	})) -- 104
	screenArea:addChild(content) -- 105
end -- 93
end) -- 94
local tab3 = PhoneTabButton{x = 206, index = 3, tabIcon = "phone.clip|phone_icon_collect_"} -- 109
node2:addChild(tab3) -- 109
local tab4 = PhoneTabButton{x = 414, index = 4, tabIcon = "phone.clip|phone_icon_set_"} -- 110
node2:addChild(tab4) -- 110
tab4:slot("Tapped",function() -- 111
do -- 111
	topname1.visible = false -- 114
	topname2.visible = false -- 115
	topname3.visible = false -- 116
	topname4.visible = true -- 117
	content:removeFromParent() -- 118
	do -- 119
		local _with_0 = Node() -- 119
		_with_0.x = 415 -- 120
		_with_0.y = 600 -- 121
		content = _with_0 -- 119
	end -- 119
	content:addChild(PhoneSetting()) -- 122
	screenArea:addChild(content) -- 123
end -- 111
end) -- 112
phone:slot("AlignLayout",function(_w,  h) -- 133
do -- 133
	local scale = h / H -- 135
	local _list_0 = { -- 136
		screenArea -- 136
	} -- 136
	for _index_0 = 1, #_list_0 do -- 136
		local item = _list_0[_index_0] -- 136
		item.scaleX = scale -- 137
		item.scaleY = scale -- 138
	end -- 136
end -- 133
end) -- 134
return phone -- 134
end