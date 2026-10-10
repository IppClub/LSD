-- [xml]: UI/ReviewSentence.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node = Node() -- 2
node.size = Size(width,100) -- 2
local nameLabel = Label("SourceHanSansCN-Regular",55) -- 3
nameLabel.anchor = Vec2(0,1) -- 3
nameLabel.x = 0 -- 3
nameLabel.y = node.height -- 3
nameLabel.color3 = Color3(0xffffff) -- 3
nameLabel.alignment = "Left" -- 3
nameLabel.textWidth = Label.AutomaticWidth -- 3
nameLabel.text = name -- 3
node:addChild(nameLabel) -- 3
local textLabel = Label("SourceHanSansCN-Regular",50) -- 7
textLabel.anchor = Vec2(0,1) -- 7
textLabel.x = 0 -- 7
textLabel.y = node.height -- 7
textLabel.color3 = Color3(0xffffff) -- 7
textLabel.alignment = "Left" -- 7
textLabel.textWidth = width -- 7
textLabel.text = text -- 7
node:addChild(textLabel) -- 7
do -- 10
	local column = math.min(math.max(250, nameLabel.width + 30), width * 0.35) -- 12
	local nameScale = math.min(1, (column - 30) / math.max(1, nameLabel.width)) -- 13
	nameLabel.scaleX = nameScale -- 14
	nameLabel.scaleY = nameScale -- 14
	textLabel.x = column -- 15
	textLabel.textWidth = width - column -- 16
	local height = math.max(nameLabel.height * nameScale, textLabel.height) -- 17
	node.height = height + 60 -- 18
	nameLabel.y = height - 30 -- 19
	textLabel.y = height - 30 -- 20
end -- 10
return node -- 11
end