-- [xml]: UI/RewardItem.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.size = Size(241,231) -- 2
local sprite1 = Sprite("gearBox.clip|prop_bg_1") -- 3
sprite1.x = node1.width*0.5 -- 3
sprite1.y = node1.height*0.5 + 30 -- 3
node1:addChild(sprite1) -- 3
local label1 = Label("SourceHanSansCN-Regular",30) -- 4
label1.x = node1.width*0.5 -- 4
label1.y = 30 -- 4
label1.color3 = Color3(0xffffff) -- 4
label1.opacity = 0.5 -- 4
label1.alignment = "Center" -- 4
label1.text = 'x' .. tostring(num or 1) -- 4
node1:addChild(label1) -- 4
return node1 -- 4
end