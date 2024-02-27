-- [xml]: UI/View/HUDMove.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local menu = Menu() -- 1
menu.x = x or 0 -- 1
menu.y = y or 0 -- 1
menu.visible = visible -- 1
local sprite1 = Sprite("skill.clip|lsdar_move_bg_1") -- 2
menu:addChild(sprite1) -- 2
local leftBack = Sprite("skill.clip|lsdar_move_bg_3") -- 3
leftBack.x = -125 -- 3
leftBack.visible = false -- 3
menu:addChild(leftBack) -- 3
local rightBack = Sprite("skill.clip|lsdar_move_bg_3") -- 4
rightBack.x = 125 -- 4
rightBack.scaleX = -1 -- 4
rightBack.visible = false -- 4
menu:addChild(rightBack) -- 4
local sprite2 = Sprite("skill.clip|lsdar_move_rocker_1") -- 5
menu:addChild(sprite2) -- 5
local centerLight = Sprite("skill.clip|lsdar_move_rocker_2") -- 6
centerLight.visible = false -- 6
menu:addChild(centerLight) -- 6
local sprite3 = Sprite("skill.clip|lsdar_move_left_1") -- 7
sprite3.x = -153 -- 7
menu:addChild(sprite3) -- 7
local leftArrow = Sprite("skill.clip|lsdar_move_left_2") -- 8
leftArrow.x = -153 -- 8
leftArrow.visible = false -- 8
menu:addChild(leftArrow) -- 8
local sprite4 = Sprite("skill.clip|lsdar_move_left_1") -- 9
sprite4.x = 153 -- 9
sprite4.scaleX = -1 -- 9
menu:addChild(sprite4) -- 9
local rightArrow = Sprite("skill.clip|lsdar_move_left_2") -- 10
rightArrow.x = 153 -- 10
rightArrow.scaleX = -1 -- 10
rightArrow.visible = false -- 10
menu:addChild(rightArrow) -- 10
local node1 = Node() -- 11
node1.x = -125 -- 11
node1.size = Size(250,250) -- 11
node1.touchEnabled = true -- 11
menu:addChild(node1) -- 11
node1:slot("TapBegan",function() -- 12
leftBack.visible = true -- 14
leftArrow.visible = true -- 15
centerLight.visible = true -- 16
menu:emit("Left", true) -- 17
end) -- 17
node1:slot("TapEnded",function() -- 20
leftBack.visible = false -- 22
leftArrow.visible = false -- 23
centerLight.visible = leftBack.visible or rightBack.visible -- 24
menu:emit("Left", false) -- 25
end) -- 25
local node2 = Node() -- 29
node2.x = 125 -- 29
node2.size = Size(250,250) -- 29
node2.touchEnabled = true -- 29
menu:addChild(node2) -- 29
node2:slot("TapBegan",function() -- 30
rightBack.visible = true -- 32
rightArrow.visible = true -- 33
centerLight.visible = true -- 34
menu:emit("Right", true) -- 35
end) -- 35
node2:slot("TapEnded",function() -- 38
rightBack.visible = false -- 40
rightArrow.visible = false -- 41
centerLight.visible = leftBack.visible or rightBack.visible -- 42
menu:emit("Right", false) -- 43
end) -- 43
return menu -- 43
end