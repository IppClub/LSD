-- [xml]: UI/ReviewSentence.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node = Node() -- 2
node.size = Size(width,100) -- 2
local nameLabel = Label("SourceHanSansCN-Regular",50) -- 3
nameLabel.anchor = Vec2(0,1) -- 3
nameLabel.x = 0 -- 3
nameLabel.y = node.height -- 3
nameLabel.color3 = Color3(0xffffff) -- 3
nameLabel.alignment = "Left" -- 3
nameLabel.textWidth = 200 -- 3
nameLabel.text = name -- 3
node:addChild(nameLabel) -- 3
local textLabel = Label("SourceHanSansCN-Regular",40) -- 7
textLabel.anchor = Vec2(0,1) -- 7
textLabel.x = 250 -- 7
textLabel.y = node.height -- 7
textLabel.color3 = Color3(0xffffff) -- 7
textLabel.alignment = "Left" -- 7
textLabel.textWidth = width - 250 -- 7
textLabel.text = text -- 7
node:addChild(textLabel) -- 7
do -- 10
	local height = math.max(nameLabel.height, textLabel.height) -- 12
	node.height = height + 60 -- 13
	nameLabel.y = height - 30 -- 14
	textLabel.y = height - 30 -- 15
end -- 15
return node -- 11
end