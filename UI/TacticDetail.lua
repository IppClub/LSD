-- [xml]: UI/TacticDetail.xml
local ScrollArea = require("UI.Control.Basic.ScrollArea") -- 2
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 4
node1.size = Size(704,1154) -- 4
local sprite1 = Sprite("ai.clip|pop_ai_bg") -- 5
sprite1.x = node1.width*0.5 -- 5
sprite1.y = node1.height*0.5 -- 5
node1:addChild(sprite1) -- 5
local sprite2 = Sprite("ai.clip|pop_ai_close") -- 6
sprite2.x = node1.width*0.5 + 295 -- 6
sprite2.y = node1.height*0.5 + 515 -- 6
node1:addChild(sprite2) -- 6
local label1 = Label("SourceHanSansCN-Regular",40) -- 7
label1.anchor = Vec2(label1.anchor.x,1) -- 7
label1.x = node1.width*0.5 -- 7
label1.y = node1.height*0.5 + 535 -- 7
label1.color3 = Color3(0xffffff) -- 7
label1.alignment = "Center" -- 7
label1.spacing = 5 -- 7
label1.text = "近战武器" -- 7
node1:addChild(label1) -- 7
local infoArea = ScrollArea{y = node1.height*0.5 - 25, x = node1.width*0.5, scrollBar = false, paddingX = 0} -- 11
node1:addChild(infoArea) -- 11
local view = infoArea.view -- 12
local label2 = Label("SourceHanSansCN-Regular",35) -- 13
label2.color3 = Color3(0xffffff) -- 13
label2.alignment = "Left" -- 13
label2.textWidth = 630 -- 13
label2.text = "策略说明\n策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明\n\n策略说明\n策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明\n\n策略说明\n策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明\n\n策略说明\n策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明" -- 13
view:addChild(label2) -- 13
do -- 16
	infoArea:adjustSizeWithAlign("Auto", 0, Size(630, 1000)) -- 18
end -- 18
return node1 -- 17
end