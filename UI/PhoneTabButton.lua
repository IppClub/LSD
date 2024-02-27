-- [xml]: UI/PhoneTabButton.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.x = x or 0 -- 2
node1.y = y or 0 -- 2
node1.size = Size(204,93) -- 2
node1.touchEnabled = true -- 2
local inactive = Node() -- 3
inactive.visible = true -- 3
node1:addChild(inactive) -- 3
node1.inactive = inactive -- 3
local sprite1 = Sprite('phone.clip|phone_btn_1') -- 4
inactive:addChild(sprite1) -- 4
local sprite2 = Sprite(tabIcon ..  '2') -- 5
inactive:addChild(sprite2) -- 5
local active = Node() -- 7
active.visible = false -- 7
node1:addChild(active) -- 7
node1.active = active -- 7
local sprite3 = Sprite('phone.clip|phone_btn_2') -- 8
active:addChild(sprite3) -- 8
local sprite4 = Sprite(tabIcon ..  '3') -- 9
active:addChild(sprite4) -- 9
node1:slot("Tapped",function() -- 11
do -- 11
	inactive.visible = not inactive.visible -- 13
	active.visible = not active.visible -- 14
	print(index) -- 15
end -- 15
end) -- 12
return node1 -- 12
end