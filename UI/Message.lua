-- [xml]: UI/Message.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local item = Node() -- 2
item.width = 700 -- 2
local label = Sprite('button.clip|' ..  (special and 'prompt_laberl_1' or 'prompt_laberl_2')) -- 3
label.anchor = Vec2(0,1) -- 3
label.x = 12 -- 3
item:addChild(label) -- 3
local label1 = Label("SourceHanSansCN-Regular",30) -- 4
label1.x = label.width*0.5 -- 4
label1.y = label.height*0.5 -- 4
label1.color3 = Color3(0x0) -- 4
label1.alignment = "Center" -- 4
label1.text = title or '' -- 4
label:addChild(label1) -- 4
local txt = Label("SourceHanSansCN-Regular",30) -- 9
txt.anchor = Vec2(0,1) -- 9
txt.x = 126 -- 9
txt.color3 = Color3(0xffffff) -- 9
txt.alignment = "Left" -- 9
txt.textWidth = 700 - 126 - 12 -- 9
txt.lineGap = 0 -- 9
txt.text = text or '' -- 9
item:addChild(txt) -- 9
do -- 12
	local height = txt.height -- 14
	local padding = 14 -- 15
	height = height + (8 + padding) -- 16
	item.height = height -- 17
	label.y = height - padding / 2 -- 18
	txt.y = height - 6 - padding / 2 -- 19
end -- 19
return item -- 13
end