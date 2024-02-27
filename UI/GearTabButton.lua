-- [xml]: UI/GearTabButton.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.x = x or 0 -- 2
node1.y = y or 0 -- 2
node1.size = Size(211,90) -- 2
local sprite1 = Sprite("button.clip|btn_small_1") -- 3
sprite1.x = node1.width*0.5 -- 3
sprite1.y = node1.height*0.5 -- 3
sprite1.visible = not selected -- 3
node1:addChild(sprite1) -- 3
local label1 = Label("SourceHanSansCN-Regular",40) -- 4
label1.x = sprite1.width*0.5 -- 4
label1.y = sprite1.height*0.5 -- 4
label1.color3 = Color3(0xffffff) -- 4
label1.alignment = "Center" -- 4
label1.spacing = 5 -- 4
label1.text = text -- 4
sprite1:addChild(label1) -- 4
local sprite2 = Sprite("button.clip|btn_small_3") -- 8
sprite2.x = node1.width*0.5 -- 8
sprite2.y = node1.height*0.5 -- 8
sprite2.visible = selected -- 8
node1:addChild(sprite2) -- 8
local label2 = Label("SourceHanSansCN-Regular",40) -- 9
label2.x = sprite2.width*0.5 -- 9
label2.y = sprite2.height*0.5 -- 9
label2.color3 = Color3(0x0) -- 9
label2.alignment = "Center" -- 9
label2.spacing = 5 -- 9
label2.text = text -- 9
sprite2:addChild(label2) -- 9
return node1 -- 9
end