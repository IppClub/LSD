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
if not text then -- 5
local playable1 = Playable('spine:Spine/' .. (icon or 'kineticgun')) -- 6
playable1.x = node1.width*0.5 - 60 -- 6
playable1.y = node1.height*0.5 - 40 -- 6
playable1.scaleX = 0.5 -- 6
playable1.scaleY = 0.5 -- 6
playable1.look = "PT" -- 6
node1:addChild(playable1) -- 6
else -- 7
local label1 = Label("SourceHanSansCN-Regular",50) -- 8
label1.x = node1.width*0.5 -- 8
label1.y = node1.height*0.5 -- 8
label1.text = text -- 8
node1:addChild(label1) -- 8
node1.textLabel = label1
end -- 9
node1:slot("TapBegan",function() -- 10
normal.visible = false -- 12
highlight.visible = true -- 13
end) -- 13
node1:slot("TapEnded",function() -- 16
normal.visible = true -- 18
highlight.visible = false -- 19
end) -- 19
end -- 22
return node1 -- 22
end