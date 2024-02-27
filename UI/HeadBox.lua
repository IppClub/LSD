-- [xml]: UI/HeadBox.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.x = x or 0 -- 2
node1.y = y or 0 -- 2
node1.size = Size(208,154) -- 2
local node2 = Node() -- 3
node2.x = node1.width*0.5 -- 3
node2.y = node1.height*0.5 -- 3
node2.visible = not selected -- 3
node1:addChild(node2) -- 3
local sprite1 = Sprite("ar.clip|lsdar_role_1") -- 4
node2:addChild(sprite1) -- 4
local node3 = Node() -- 6
node3.x = node1.width -- 6
node3.y = node1.height*0.5 -- 6
node3.visible = selected -- 6
node1:addChild(node3) -- 6
local sprite2 = Sprite("ar.clip|lsdar_role_2") -- 7
sprite2.anchor = Vec2(1,sprite2.anchor.y) -- 7
node3:addChild(sprite2) -- 7
return node1 -- 7
end