-- [xml]: UI/View/Interaction.xml
local MovingText = require("UI.MovingText") -- 2
local InputButton = require("UI.InputButton") -- 3
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 4
node1.x = fliped and -80 or 80 -- 4
node1.z = -200 -- 4
node1.scaleX = 0.5 -- 4
node1.scaleY = 0.5 -- 4
local node2 = Node() -- 5
node2.size = Size(228,67) -- 5
node1:addChild(node2) -- 5
if fliped then -- 6
local sprite1 = Sprite("button.clip|prompt_chat_name") -- 7
sprite1.x = node2.width*0.5 -- 7
sprite1.y = node2.height*0.5 -- 7
sprite1.scaleX = -1 -- 7
node2:addChild(sprite1) -- 7
local sprite2 = Sprite("button.clip|prompt_chat_name1") -- 8
sprite2.anchor = Vec2(0,0) -- 8
sprite2.x = 0 -- 8
sprite2.y = 0 -- 8
sprite2.scaleX = -1 -- 8
node2:addChild(sprite2) -- 8
local clip = MovingText{offsetY = 25, textBG = "TARGET"} -- 9
node2:addChild(clip) -- 9
local mask = clip.mask -- 10
local sprite3 = Sprite("button.clip|prompt_chat_name") -- 11
sprite3.anchor = Vec2(1,0) -- 11
sprite3.scaleX = -1 -- 11
mask:addChild(sprite3) -- 11
clip.alphaThreshold = 0.5 -- 14
else -- 15
local sprite4 = Sprite("button.clip|prompt_chat_name") -- 16
sprite4.x = node2.width*0.5 -- 16
sprite4.y = node2.height*0.5 -- 16
node2:addChild(sprite4) -- 16
local sprite5 = Sprite("button.clip|prompt_chat_name1") -- 17
sprite5.anchor = Vec2(0,0) -- 17
sprite5.x = node2.width -- 17
sprite5.y = 0 -- 17
node2:addChild(sprite5) -- 17
local clip = MovingText{offsetY = 25, textBG = "TARGET"} -- 18
node2:addChild(clip) -- 18
local mask = clip.mask -- 19
local sprite6 = Sprite("button.clip|prompt_chat_name") -- 20
sprite6.anchor = Vec2(0,0) -- 20
mask:addChild(sprite6) -- 20
clip.alphaThreshold = 0.5 -- 23
end -- 24
local label1 = Label("SourceHanSansCN-Regular",45) -- 25
label1.anchor = Vec2(0,label1.anchor.y) -- 25
label1.x = 20 -- 25
label1.y = node2.height*0.5 -- 25
label1.color3 = Color3(0xffffff) -- 25
label1.alignment = "Left" -- 25
label1.text = text or '' -- 25
node2:addChild(label1) -- 25
local menu = Menu() -- 30
menu.anchor = Vec2(menu.anchor.x,1) -- 30
menu.x = fliped and -160 or 160 -- 30
menu.y = -40 -- 30
menu.size = Size(319,93) -- 30
node1:addChild(menu) -- 30
node1.menu = menu -- 30
return node1 -- 30
end