-- [xml]: UI/View/Story.xml
local SolidRect = require("UI.View.Shape.SolidRect") -- 2
local AlignNode = require("UI.Control.Basic.AlignNode") -- 3
local ScrollArea = require("UI.Control.Basic.ScrollArea") -- 4
local FullScreenMask = require("UI.FullScreenMask") -- 6
local ReviewSentence = require("UI.ReviewSentence") -- 7
local ReviewButton = require("UI.ReviewButton") -- 9
local H <const> = 1563 -- 11
return function(args) -- 1
local _ENV = Dora(args) -- 1
local ui = AlignNode{isRoot = true, inUI = true} -- 12
local item1 = FullScreenMask{} -- 13
ui:addChild(item1) -- 13
local figure = AlignNode{vAlign = "Bottom", hAlign = "Center"} -- 14
ui:addChild(figure) -- 14
ui.figure = figure -- 14
local talkArea = AlignNode{vAlign = "Bottom", hAlign = "Left"} -- 15
ui:addChild(talkArea) -- 15
local talkBack = SolidRect{color = 0x66000000, order = -1, height = 370, width = 3258} -- 16
talkArea:addChild(talkBack) -- 16
local sprite1 = Sprite("button.clip|prompt_chat_2") -- 17
sprite1.x = 50 -- 17
sprite1.y = 340 -- 17
talkArea:addChild(sprite1) -- 17
local rightLabel = Sprite("button.clip|prompt_chat_2") -- 18
rightLabel.x = 3208 -- 18
rightLabel.y = 340 -- 18
talkArea:addChild(rightLabel) -- 18
local talkLine = Line() -- 19
talkLine.color3 = Color3(0xffffff) -- 19
talkArea:addChild(talkLine) -- 19
talkLine:set({Vec2(92,340),Vec2(3166,340)},Color(0xffffffff)) -- 19
local name = Label("SourceHanSansCN-Regular",55) -- 23
name.anchor = Vec2(0,name.anchor.y) -- 23
name.x = 97 -- 23
name.y = 185 -- 23
name.color3 = Color3(0xffffff) -- 23
name.alignment = "Left" -- 23
talkArea:addChild(name) -- 23
ui.name = name -- 23
local confirm = Node() -- 27
confirm.touchEnabled = true -- 27
talkArea:addChild(confirm) -- 27
ui.confirm = confirm -- 27
local textArea = ScrollArea{y = 165, x = 1620, scrollBar = false, paddingX = 0} -- 28
talkArea:addChild(textArea) -- 28
ui.textArea = textArea -- 28
local view = textArea.view -- 29
local text = Label("SourceHanSansCN-Regular",50) -- 30
text.color3 = Color3(0xffffff) -- 30
text.alignment = "Left" -- 30
text.textWidth = 2368 -- 30
view:addChild(text) -- 30
ui.text = text -- 30
local rightCenter = AlignNode{vAlign = "Center", hAlign = "Right"} -- 37
ui:addChild(rightCenter) -- 37
ui.rightCenter = rightCenter -- 37
local answerList = Menu() -- 38
answerList.x = -413.5 -- 38
answerList.size = Size(907,114) -- 38
rightCenter:addChild(answerList) -- 38
ui.answerList = answerList -- 38
local rightBottom = AlignNode{vAlign = "Bottom", hAlign = "Right"} -- 41
ui:addChild(rightBottom) -- 41
local reviewButton = ReviewButton{y = 260, x = -163} -- 42
rightBottom:addChild(reviewButton) -- 42
ui.reviewButton = reviewButton -- 42
local move = Action(Sequence(Move(1,Vec2(-163,94),Vec2(-163,114),Ease.InExpo),Move(1,Vec2(-163,114),Vec2(-163,94),Ease.OutExpo))) -- 44
local continueIcon = Sprite("button.clip|prompt_chat_continue") -- 49
continueIcon.x = -163 -- 49
continueIcon.y = 94 -- 49
rightBottom:addChild(continueIcon) -- 49
ui.continueIcon = continueIcon -- 49
continueIcon:slot("Enter",function() -- 50
continueIcon:perform(move) -- 50
continueIcon:slot("ActionEnd",function(_action_) if _action_ == move then continueIcon:perform(move) end end) -- 50
end) -- 50
local rightTop = AlignNode{vAlign = "Top", hAlign = "Right"} -- 53
ui:addChild(rightTop) -- 53
local reviewMask = FullScreenMask{} -- 59
ui:addChild(reviewMask) -- 59
ui.reviewMask = reviewMask -- 59
local topCenter = AlignNode{vAlign = "Top", hAlign = "Center"} -- 60
ui:addChild(topCenter) -- 60
ui.topCenter = topCenter -- 60
local label1 = Label("SourceHanSansCN-Regular",70) -- 61
label1.anchor = Vec2(label1.anchor.x,1) -- 61
label1.y = -83 -- 61
label1.color3 = Color3(0xffffff) -- 61
label1.alignment = "Center" -- 61
label1.text = "对话回顾" -- 61
topCenter:addChild(label1) -- 61
local leftLabel1 = Sprite("button.clip|prompt_chat_2") -- 65
leftLabel1.x = -1579 -- 65
leftLabel1.y = -208 -- 65
topCenter:addChild(leftLabel1) -- 65
local rightLabel1 = Sprite("button.clip|prompt_chat_2") -- 66
rightLabel1.x = 1579 -- 66
rightLabel1.y = -208 -- 66
topCenter:addChild(rightLabel1) -- 66
local talkLine2 = Line() -- 67
talkLine2.y = -208 -- 67
talkLine2.color3 = Color3(0xffffff) -- 67
topCenter:addChild(talkLine2) -- 67
talkLine2:set({Vec2(-1579,0),Vec2(1579,0)},Color(0xffffffff)) -- 67
local reviewBack = Node() -- 71
reviewBack.touchEnabled = true -- 71
topCenter:addChild(reviewBack) -- 71
ui.reviewBack = reviewBack -- 71
local reviewArea = ScrollArea{scrollBar = false, paddingX = 0} -- 72
topCenter:addChild(reviewArea) -- 72
ui.reviewArea = reviewArea -- 72
local view = reviewArea.view -- 73
ui:slot("AlignLayout",function(w, h) -- 77
do -- 77
	local scale = h / H -- 80
	local reviewW = w / scale - 160 * 2 -- 81
	local reviewH = h / scale - 208 - 370 -- 82
	reviewArea.y = -208 - reviewH / 2 -- 83
	reviewArea.view:removeAllChildren() -- 84
	local _list_0 = ui._reviews -- 85
	for _index_0 = 1, #_list_0 do -- 85
		local _des_0 = _list_0[_index_0] -- 85
		local name, text = _des_0.name, _des_0.text -- 85
		reviewArea.view:addChild(ReviewSentence({ -- 86
			width = reviewW, -- 86
			name = name, -- 86
			text = text -- 86
		})) -- 86
	end -- 86
	reviewArea.view:addChild(ReviewSentence({ -- 87
		width = reviewW, -- 87
		name = "", -- 87
		text = "\n" -- 87
	})) -- 87
	reviewArea:adjustSizeWithAlign("Auto", 0, Size(reviewW, reviewH)) -- 88
	local offset = (w / 2) / scale - 150 -- 89
	leftLabel1.x = -offset -- 90
	rightLabel1.x = offset -- 91
	offset = (w / 2) / scale - 192 -- 92
	talkLine2:removeFromParent() -- 93
	do -- 94
		local _with_0 = Line({ -- 94
			Vec2(-offset, -208), -- 94
			Vec2(offset, -208) -- 94
		}, Color(0xffffffff)) -- 94
		_with_0:addTo(topCenter) -- 95
		talkLine2 = _with_0 -- 94
	end -- 94
	local _list_1 = { -- 96
		talkArea, -- 96
		rightBottom, -- 96
		rightTop, -- 96
		rightCenter, -- 96
		figure, -- 96
		topCenter -- 96
	} -- 96
	for _index_0 = 1, #_list_1 do -- 96
		local item = _list_1[_index_0] -- 96
		item.scaleX = scale -- 97
		item.scaleY = scale -- 98
	end -- 98
	talkBack:removeFromParent() -- 99
	local realWidth = w / scale -- 100
	do -- 101
		local _with_0 = SolidRect({ -- 101
			width = realWidth, -- 101
			height = 370, -- 101
			color = 0x66000000 -- 101
		}) -- 101
		_with_0.order = -1 -- 102
		_with_0:addTo(talkArea) -- 103
		talkBack = _with_0 -- 101
	end -- 101
	talkLine:removeFromParent() -- 104
	do -- 105
		local _with_0 = Line({ -- 105
			Vec2(92, 340), -- 105
			Vec2(realWidth - 92, 340) -- 105
		}, Color(0xffffffff)) -- 105
		_with_0:addTo(talkArea) -- 106
		talkLine = _with_0 -- 105
	end -- 105
	rightLabel.x = realWidth - 50 -- 107
	text.textWidth = realWidth - 890 -- 108
	textArea.x = 436 + (realWidth - 890) / 2 -- 109
	textArea:adjustSizeWithAlign("Auto", 0, Size(realWidth - 890, math.min(300, text.height))) -- 110
end -- 110
end) -- 78
return ui -- 78
end