-- [xml]: UI/View/Interaction.xml
local MovingText = require("UI.MovingText") -- 2
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 3
node1.x = fliped and -80 or 80 -- 3
node1.z = -200 -- 3
node1.scaleX = 0.5 -- 3
node1.scaleY = 0.5 -- 3
local node2 = Node() -- 4
node2.size = Size(228,67) -- 4
node1:addChild(node2) -- 4
if fliped then -- 5
local sprite1 = Sprite("button.clip|prompt_chat_name") -- 6
sprite1.x = node2.width*0.5 -- 6
sprite1.y = node2.height*0.5 -- 6
sprite1.scaleX = -1 -- 6
node2:addChild(sprite1) -- 6
local sprite2 = Sprite("button.clip|prompt_chat_name1") -- 7
sprite2.anchor = Vec2(0,0) -- 7
sprite2.x = 0 -- 7
sprite2.y = 0 -- 7
sprite2.scaleX = -1 -- 7
node2:addChild(sprite2) -- 7
local clip = MovingText{offsetY = 25, textBG = ''} -- 8
node2:addChild(clip) -- 8
local mask = clip.mask -- 9
local sprite3 = Sprite("button.clip|prompt_chat_name") -- 10
sprite3.anchor = Vec2(1,0) -- 10
sprite3.scaleX = -1 -- 10
mask:addChild(sprite3) -- 10
clip.alphaThreshold = 0.5 -- 13
else -- 14
local sprite4 = Sprite("button.clip|prompt_chat_name") -- 15
sprite4.x = node2.width*0.5 -- 15
sprite4.y = node2.height*0.5 -- 15
node2:addChild(sprite4) -- 15
local sprite5 = Sprite("button.clip|prompt_chat_name1") -- 16
sprite5.anchor = Vec2(0,0) -- 16
sprite5.x = node2.width -- 16
sprite5.y = 0 -- 16
node2:addChild(sprite5) -- 16
local clip = MovingText{offsetY = 25, textBG = ''} -- 17
node2:addChild(clip) -- 17
local mask = clip.mask -- 18
local sprite6 = Sprite("button.clip|prompt_chat_name") -- 19
sprite6.anchor = Vec2(0,0) -- 19
mask:addChild(sprite6) -- 19
clip.alphaThreshold = 0.5 -- 22
end -- 23
local label1 = Label("SourceHanSansCN-Regular",45) -- 24
label1.anchor = Vec2(0,label1.anchor.y) -- 24
label1.x = 20 -- 24
label1.y = node2.height*0.5 -- 24
label1.color3 = Color3(0xffffff) -- 24
label1.alignment = "Left" -- 24
label1.text = text or '' -- 24
node2:addChild(label1) -- 24
local menu = Menu() -- 29
menu.anchor = Vec2(menu.anchor.x,1) -- 29
menu.x = fliped and -160 or 160 -- 29
menu.y = -40 -- 29
menu.size = Size(319,93) -- 29
node1:addChild(menu) -- 29
node1.menu = menu -- 29
return node1 -- 29
end