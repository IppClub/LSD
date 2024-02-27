-- [xml]: UI/TacticReview.xml
local FixedLabel = require("UI.Control.Basic.FixedLabel") -- 2
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 4
node1.size = Size(476,739) -- 4
local sprite1 = Sprite("ar.clip|lsdar_settlement_ai_1") -- 5
sprite1.anchor = Vec2(sprite1.anchor.x,1) -- 5
sprite1.x = node1.width*0.5 -- 5
sprite1.y = node1.height -- 5
node1:addChild(sprite1) -- 5
local sprite2 = Sprite("ar.clip|lsdar_settlement_ai_2") -- 6
sprite2.anchor = Vec2(sprite2.anchor.x,1) -- 6
sprite2.x = node1.width*0.5 -- 6
sprite2.y = node1.height -- 6
node1:addChild(sprite2) -- 6
local label1 = Label("SourceHanSansCN-Regular",40) -- 7
label1.x = sprite2.width*0.5 -- 7
label1.y = sprite2.height*0.5 -- 7
label1.color3 = Color3(0xffffff) -- 7
label1.alignment = "Center" -- 7
label1.spacing = 5 -- 7
label1.text = title or '' -- 7
sprite2:addChild(label1) -- 7
local sprite3 = Sprite("ar.clip|lsdar_settlement_ai_record") -- 12
sprite3.anchor = Vec2(sprite3.anchor.x,0) -- 12
sprite3.x = node1.width*0.5 -- 12
sprite3.y = 0 -- 12
node1:addChild(sprite3) -- 12
local item1 = FixedLabel{y = node1.height*0.5, x = node1.width*0.5, textAlign = "Left", color3 = 0xffffff, text = "策略说明\n策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明\n\n策略说明\n策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明\n\n策略说明\n策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明\n\n策略说明\n策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明策略说明", fontSize = 35, fontName = "SourceHanSansCN-Regular", height = 500, width = 350} -- 13
node1:addChild(item1) -- 13
return node1 -- 13
end