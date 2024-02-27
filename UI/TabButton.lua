-- [xml]: UI/TabButton.xml
local MovingText = require("UI.MovingText") -- 2
return function(args) -- 1
local _ENV = Dora(args) -- 1
local btn = Node() -- 3
btn.touchEnabled = true -- 3
local active = Sprite("button.clip|btn_big_1") -- 4
active.anchor = Vec2(0,0) -- 4
active.visible = selected -- 4
btn:addChild(active) -- 4
local sprite1 = Sprite("button.clip|btn_big_light") -- 5
sprite1.x = active.width*0.5 -- 5
sprite1.y = active.height*0.5 -- 5
sprite1.scaleX = 2 -- 5
sprite1.scaleY = 2 -- 5
sprite1.order = -1 -- 5
active:addChild(sprite1) -- 5
local glow = Action(Sequence(Opacity(0.5,0,1),Opacity(0.5,1,0))) -- 7
sprite1:slot("Enter",function() -- 12
sprite1:perform(glow) -- 12
sprite1:slot("ActionEnd",function(_action_) if _action_ == glow then sprite1:perform(glow) end end) -- 12
end) -- 12
local inactive = Sprite("button.clip|btn_big_2") -- 15
inactive.anchor = Vec2(0,0) -- 15
inactive.visible = not selected -- 15
btn:addChild(inactive) -- 15
local movingText = MovingText{color3 = 0xffffff, textBG = textBG or ''} -- 16
btn:addChild(movingText) -- 16
local mask = movingText.mask -- 17
local activeStencil = Sprite("button.clip|btn_big_1") -- 18
activeStencil.anchor = Vec2(0,0) -- 18
activeStencil.visible = selected -- 18
mask:addChild(activeStencil) -- 18
local inactiveStencil = Sprite("button.clip|btn_big_2") -- 19
inactiveStencil.anchor = Vec2(0,0) -- 19
inactiveStencil.visible = not selected -- 19
mask:addChild(inactiveStencil) -- 19
local txt = Label("SourceHanSansCN-Regular",50) -- 22
txt.anchor = Vec2(0,txt.anchor.y) -- 22
txt.x = 35 -- 22
txt.y = 41.5 -- 22
txt.color3 = Color3(selected and 0x7ec0f8 or 0xffffff) -- 22
txt.alignment = "Left" -- 22
txt.spacing = 5 -- 22
txt.text = text or '' -- 22
btn:addChild(txt) -- 22
btn:slot("Toggle",function() -- 26
do -- 26
	btn.selected = not btn.selected -- 28
	local selected = btn.selected -- 29
	btn.size = selected and active.size or inactive.size -- 30
	local color3 = Color3(selected and 0x7ec0f8 or 0xffffff) -- 31
	movingText.color3 = color3 -- 32
	txt.color3 = color3 -- 33
	active.visible = selected -- 34
	activeStencil.visible = selected -- 35
	inactive.visible = not selected -- 36
	inactiveStencil.visible = not selected -- 37
end -- 37
end) -- 27
do -- 39
	movingText.color3 = Color3(selected and 0x7ec0f8 or 0xffffff) -- 41
	btn.selected = selected or false -- 42
	local size = selected and active.size or inactive.size -- 43
	btn.size = size -- 44
end -- 44
return btn -- 40
end