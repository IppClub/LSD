-- [xml]: UI/MemberView.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.size = Size(408,843) -- 2
local sprite1 = Sprite("ar.clip|lsdar_settlement_role_bg") -- 3
sprite1.x = node1.width*0.5 -- 3
sprite1.y = node1.height*0.5 + 40 -- 3
node1:addChild(sprite1) -- 3
local sprite2 = Sprite("ar.clip|lsdar_settlement_role_evaluate_5") -- 4
sprite2.x = node1.width*0.5 -- 4
sprite2.y = 37.5 -- 4
node1:addChild(sprite2) -- 4
return node1 -- 4
end