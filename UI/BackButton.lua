-- [xml]: UI/BackButton.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 1
node1.x = x or 0 -- 1
node1.y = y or 0 -- 1
node1.size = Size(110,67) -- 1
node1.touchEnabled = true -- 1
local sprite1 = Sprite("button.clip|btn_return_2") -- 2
sprite1.x = node1.width*0.5 -- 2
sprite1.y = node1.height*0.5 -- 2
node1:addChild(sprite1) -- 2
return node1 -- 2
end