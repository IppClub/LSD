-- [xml]: UI/GearButton.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.size = Size(201,201) -- 2
local sprite1 = Sprite("gearBox.clip|prop_bg_1") -- 3
sprite1.x = node1.width*0.5 -- 3
sprite1.y = node1.height*0.5 -- 3
sprite1.visible = not equiped and not locked -- 3
node1:addChild(sprite1) -- 3
local sprite2 = Sprite("gearBox.clip|prop_bg_2") -- 4
sprite2.x = node1.width*0.5 -- 4
sprite2.y = node1.height*0.5 -- 4
sprite2.visible = locked -- 4
node1:addChild(sprite2) -- 4
local sprite3 = Sprite("gearBox.clip|prop_bg_4") -- 5
sprite3.x = node1.width*0.5 -- 5
sprite3.y = node1.height*0.5 -- 5
sprite3.visible = equiped and not locked -- 5
node1:addChild(sprite3) -- 5
local sprite4 = Sprite("gearBox.clip|prop_bg_3") -- 6
sprite4.x = node1.width*0.5 -- 6
sprite4.y = node1.height*0.5 -- 6
sprite4.visible = false -- 6
node1:addChild(sprite4) -- 6
local sprite5 = Sprite("gearBox.clip|prop_equipperd_1") -- 7
sprite5.x = node1.width*0.5 - 1 -- 7
sprite5.y = node1.height*0.5 -- 7
sprite5.visible = locked -- 7
node1:addChild(sprite5) -- 7
local clipNode1 = ClipNode() -- 8
clipNode1.x = node1.width*0.5 - 1 -- 8
clipNode1.y = node1.height*0.5 -- 8
clipNode1.visible = equiped and not locked -- 8
node1:addChild(clipNode1) -- 8
local sprite6 = Sprite("gearBox.clip|prop_equipperd_2") -- 10
clipNode1.stencil = sprite6 -- 10
local node2 = Node() -- 12
clipNode1:addChild(node2) -- 12
local sprite7 = Sprite("gearBox.clip|prop_equipperd_2") -- 13
sprite7.x = 170 -- 13
sprite7.scaleX = 1.01 -- 13
node2:addChild(sprite7) -- 13
local sprite8 = Sprite("gearBox.clip|prop_equipperd_2") -- 14
sprite8.scaleX = 1.01 -- 14
node2:addChild(sprite8) -- 14
local move = Action(Move(3,Vec2(0,0),Vec2(-170,0))) -- 16
node2:slot("Enter",function() -- 18
node2:perform(move) -- 18
node2:slot("ActionEnd",function(_action_) if _action_ == move then node2:perform(move) end end) -- 18
end) -- 18
return node1 -- 18
end