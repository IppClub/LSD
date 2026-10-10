-- [xml]: UI/TrainingButton.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.size = Size(201,201) -- 2
local sprite1 = Sprite("gearBox.clip|prop_bg_1") -- 3
sprite1.x = node1.width*0.5 -- 3
sprite1.y = node1.height*0.5 -- 3
sprite1.visible = not selected -- 3
node1:addChild(sprite1) -- 3
local sprite2 = Sprite("gearBox.clip|prop_bg_4") -- 4
sprite2.x = node1.width*0.5 -- 4
sprite2.y = node1.height*0.5 -- 4
sprite2.visible = selected -- 4
node1:addChild(sprite2) -- 4
local light = Sprite("gearBox.clip|prop_bg_3") -- 5
light.x = node1.width*0.5 -- 5
light.y = node1.height*0.5 -- 5
light.visible = selected -- 5
node1:addChild(light) -- 5
local glow = Action(Sequence(Opacity(0.5,0,1),Opacity(0.5,1,0))) -- 7
node1:slot("Enter",function() -- 12
if node1.running then light:perform(glow, true) end -- 12
end) -- 12
return node1 -- 12
end