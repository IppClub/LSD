-- [xml]: UI/ArrowButton.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 1
node1.x = x or 0 -- 1
node1.y = y or 0 -- 1
node1.size = Size(72,72) -- 1
local sprite1 = Sprite("button.clip|formation_pop_icon_1") -- 2
sprite1.x = node1.width*0.5 -- 2
sprite1.y = node1.height*0.5 -- 2
sprite1.scaleX = right and -1 or 1 -- 2
sprite1.visible = false -- 2
node1:addChild(sprite1) -- 2
local sprite2 = Sprite("button.clip|formation_pop_icon_2") -- 3
sprite2.x = node1.width*0.5 -- 3
sprite2.y = node1.height*0.5 -- 3
sprite2.scaleX = right and -1 or 1 -- 3
sprite2.visible = true -- 3
node1:addChild(sprite2) -- 3
return node1 -- 3
end