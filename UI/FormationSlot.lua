-- [xml]: UI/FormationSlot.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.size = Size(510,325) -- 2
node1.touchEnabled = true -- 2
local sprite1 = Sprite("viewBox.clip|formation_role_small_bg_1") -- 3
sprite1.x = node1.width*0.5 -- 3
sprite1.y = node1.height*0.5 -- 3
node1:addChild(sprite1) -- 3
local sprite2 = Sprite("viewBox.clip|formation_role_small_img") -- 4
sprite2.x = node1.width*0.5 -- 4
sprite2.y = node1.height*0.5 -- 4
node1:addChild(sprite2) -- 4
local sprite3 = Sprite("viewBox.clip|formation_role_small_bg_2") -- 5
sprite3.x = node1.width*0.5 -- 5
sprite3.y = node1.height*0.5 -- 5
sprite3.visible = false -- 5
node1:addChild(sprite3) -- 5
local sprite4 = Sprite("viewBox.clip|formation_icon_add_1") -- 6
sprite4.x = node1.width*0.5 -- 6
sprite4.y = node1.height*0.5 -- 6
node1:addChild(sprite4) -- 6
return node1 -- 6
end