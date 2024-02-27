-- [xml]: UI/TacticAction.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.anchor = Vec2(0,node1.anchor.y) -- 2
node1.x = x or 0 -- 2
node1.y = y or 0 -- 2
node1.size = Size(426,92) -- 2
local sprite1 = Sprite("ai.clip|ai_big_tab_1") -- 3
sprite1.x = node1.width*0.5 -- 3
sprite1.y = node1.height*0.5 -- 3
node1:addChild(sprite1) -- 3
local label1 = Label("SourceHanSansCN-Regular",45) -- 4
label1.x = node1.width*0.5 - 20 -- 4
label1.y = node1.height*0.5 - 5 -- 4
label1.color3 = Color3(0xffffff) -- 4
label1.alignment = "Center" -- 4
label1.text = text -- 4
node1:addChild(label1) -- 4
return node1 -- 4
end