-- [xml]: UI/InputButton.xml
local MovingText = require("UI.MovingText") -- 2
return function(args) -- 1
local _ENV = Dora(args) -- 1
local btn = Node() -- 3
btn.x = x or 0 -- 3
btn.y = y or 0 -- 3
btn.size = Size(309,83) -- 3
btn.touchEnabled = true -- 3
local active = Sprite("button.clip|prompt_chat_btn") -- 4
active.anchor = Vec2(0,0) -- 4
btn:addChild(active) -- 4
local item1 = MovingText{textBG = textBG or ''} -- 5
btn:addChild(item1) -- 5
local mask = item1.mask -- 6
local sprite1 = Sprite("button.clip|prompt_chat_btn") -- 7
sprite1.anchor = Vec2(0,0) -- 7
mask:addChild(sprite1) -- 7
local txt = Label("SourceHanSansCN-Regular",50) -- 10
txt.anchor = Vec2(0,txt.anchor.y) -- 10
txt.x = 35 -- 10
txt.y = 41.5 -- 10
txt.color3 = Color3(0xffffff) -- 10
txt.alignment = "Left" -- 10
txt.text = text or '' -- 10
btn:addChild(txt) -- 10
local scaleAction = Action(Sequence(Scale(0.08,1,0.8),Scale(0.3,0.8,1,Ease.OutBack))) -- 15
local tapBegan = Action(Tint(0,0x7ec0f8,0x7ec0f8)) -- 19
local tapEnded = Action(Tint(0.8,0x7ec0f8,0xffffff)) -- 20
btn:slot("Tapped",function() -- 22
btn:perform(scaleAction) -- 22
end) -- 22
btn:slot("TapBegan",function() -- 23
txt:perform(tapBegan) -- 23
end) -- 23
btn:slot("TapEnded",function() -- 24
txt:perform(tapEnded) -- 24
end) -- 24
return btn -- 24
end