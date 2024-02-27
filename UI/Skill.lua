-- [xml]: UI/Skill.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 1
node1.visible = visible -- 1
node1.size = Size(296,296) -- 1
node1.touchEnabled = true -- 1
if not placeHolder then -- 2
local normal = Sprite("skill.clip|lsdar_skill_bg_1") -- 3
normal.x = node1.width*0.5 -- 3
normal.y = node1.height*0.5 -- 3
node1:addChild(normal) -- 3
local highlight = Sprite("skill.clip|lsdar_skill_bg_2") -- 4
highlight.x = node1.width*0.5 -- 4
highlight.y = node1.height*0.5 -- 4
highlight.visible = false -- 4
node1:addChild(highlight) -- 4
local playable1 = Playable("spine:Spine/kineticgun") -- 5
playable1.x = node1.width*0.5 - 60 -- 5
playable1.y = node1.height*0.5 - 40 -- 5
playable1.scaleX = 0.5 -- 5
playable1.scaleY = 0.5 -- 5
playable1.look = "PT" -- 5
node1:addChild(playable1) -- 5
node1:slot("TapBegan",function() -- 6
normal.visible = false -- 8
highlight.visible = true -- 9
end) -- 9
node1:slot("TapEnded",function() -- 12
normal.visible = true -- 14
highlight.visible = false -- 15
end) -- 15
end -- 18
return node1 -- 18
end