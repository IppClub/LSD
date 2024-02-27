-- [xml]: UI/RoleSelect.xml
local MovingText = require("UI.MovingText") -- 2
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 3
node1.size = Size(421,321) -- 3
if vacant then -- 4
local sprite1 = Sprite("viewBox.clip|formation_role_alternative_img") -- 5
sprite1.x = node1.width*0.5 -- 5
sprite1.y = node1.height*0.5 -- 5
node1:addChild(sprite1) -- 5
local sprite2 = Sprite("viewBox.clip|formation_role_alternative_1") -- 6
sprite2.x = node1.width*0.5 -- 6
sprite2.y = node1.height*0.5 -- 6
node1:addChild(sprite2) -- 6
local sprite3 = Sprite("viewBox.clip|formation_role_alternative_1_tab") -- 7
sprite3.x = node1.width*0.5 -- 7
sprite3.y = node1.height*0.5 -- 7
node1:addChild(sprite3) -- 7
local item1 = MovingText{textBG = "VACANT POSITION", color3 = 0xffffff, offsetY = 40} -- 8
sprite3:addChild(item1) -- 8
local mask = item1.mask -- 9
local sprite4 = Sprite("viewBox.clip|formation_role_alternative_1_tab") -- 10
sprite4.anchor = Vec2(0,0) -- 10
mask:addChild(sprite4) -- 10
local label1 = Label("SourceHanSansCN-Regular",50) -- 14
label1.x = node1.width*0.5 -- 14
label1.y = node1.height*0.5 -- 14
label1.color3 = Color3(0xffffff) -- 14
label1.alignment = "Center" -- 14
label1.spacing = 20 -- 14
label1.text = "空置" -- 14
node1:addChild(label1) -- 14
else -- 18
local sprite5 = Sprite("viewBox.clip|formation_role_alternative_1") -- 19
sprite5.x = node1.width*0.5 -- 19
sprite5.y = node1.height*0.5 -- 19
sprite5.visible = not locked -- 19
node1:addChild(sprite5) -- 19
local sprite6 = Sprite("viewBox.clip|formation_role_alternative_2") -- 20
sprite6.x = node1.width*0.5 -- 20
sprite6.y = node1.height*0.5 -- 20
sprite6.visible = locked -- 20
node1:addChild(sprite6) -- 20
local sprite7 = Sprite("viewBox.clip|formation_role_alternative_3") -- 21
sprite7.x = node1.width*0.5 -- 21
sprite7.y = node1.height*0.5 -- 21
sprite7.visible = selected and not locked -- 21
node1:addChild(sprite7) -- 21
local sprite8 = Sprite("viewBox.clip|formation_role_small_bg_2") -- 22
sprite8.x = node1.width*0.5 -- 22
sprite8.y = node1.height*0.5 -- 22
sprite8.scaleX = 0.8255 -- 22
sprite8.scaleY = 0.9847 -- 22
sprite8.visible = selected -- 22
node1:addChild(sprite8) -- 22
local sprite9 = Sprite("viewBox.clip|formation_role_alternative_2_tab") -- 23
sprite9.anchor = Vec2(sprite9.anchor.x,0) -- 23
sprite9.x = node1.width*0.5 -- 23
sprite9.y = 0 -- 23
sprite9.visible = locked -- 23
node1:addChild(sprite9) -- 23
local label2 = Label("SourceHanSansCN-Regular",50) -- 24
label2.x = sprite9.width*0.5 -- 24
label2.y = sprite9.height*0.5 -- 24
label2.color3 = Color3(0xffffff) -- 24
label2.alignment = "Center" -- 24
label2.spacing = 10 -- 24
label2.text = "队伍中" -- 24
sprite9:addChild(label2) -- 24
end -- 29
return node1 -- 29
end