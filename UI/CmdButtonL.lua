-- [xml]: UI/CmdButtonL.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.x = x or 0 -- 2
node1.y = y or 0 -- 2
node1.size = Size(375,117) -- 2
local sprite1 = Sprite("button.clip|lsdar_btn_bg_1") -- 3
sprite1.x = node1.width*0.5 -- 3
sprite1.y = node1.height*0.5 -- 3
sprite1.visible = not selected -- 3
node1:addChild(sprite1) -- 3
local sprite2 = Sprite("button.clip|lsdar_btn_bg_2") -- 4
sprite2.x = node1.width*0.5 -- 4
sprite2.y = node1.height*0.5 -- 4
sprite2.visible = selected -- 4
node1:addChild(sprite2) -- 4
local sprite3 = Sprite("button.clip|lsdar_btn_teem_1") -- 5
sprite3.x = 55 -- 5
sprite3.y = node1.height*0.5 -- 5
sprite3.opacity = selected and 1.0 or 0.5 -- 5
node1:addChild(sprite3) -- 5
local label1 = Label("SourceHanSansCN-Regular",55) -- 6
label1.anchor = Vec2(0,label1.anchor.y) -- 6
label1.x = 110 -- 6
label1.y = node1.height*0.5 -- 6
label1.color3 = Color3(0xffffff) -- 6
label1.opacity = selected and 1.0 or 0.5 -- 6
label1.alignment = "Left" -- 6
label1.spacing = 5 -- 6
label1.text = text or '' -- 6
node1:addChild(label1) -- 6
return node1 -- 6
end