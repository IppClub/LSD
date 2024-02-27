-- [xml]: UI/PropButton.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
node1.x = x or 0 -- 2
node1.y = y or 0 -- 2
node1.size = Size(296,75) -- 2
node1.touchEnabled = true -- 2
local sprite1 = Sprite("button.clip|btn_middle_3") -- 3
sprite1.x = node1.width*0.5 -- 3
sprite1.y = node1.height*0.5 -- 3
node1:addChild(sprite1) -- 3
local label1 = Label("SourceHanSansCN-Regular",40) -- 4
label1.x = node1.width*0.5 -- 4
label1.y = node1.height*0.5 -- 4
label1.color3 = Color3(0xffffff) -- 4
label1.alignment = "Center" -- 4
label1.spacing = 5 -- 4
label1.text = text or '' -- 4
node1:addChild(label1) -- 4
local scaleAction = Action(Sequence(Scale(0.08,1,0.8),Scale(0.3,0.8,1,Ease.OutBack))) -- 9
node1:slot("Tapped",function() -- 14
node1:perform(scaleAction) -- 14
end) -- 14
return node1 -- 14
end