-- [xml]: UI/View/MessageBox.xml
local ScrollArea = require("UI.Control.Basic.ScrollArea") -- 2
local Message = require("UI.Message") -- 3
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 4
node1.x = x or 0 -- 4
node1.y = y or 0 -- 4
node1.size = Size(700,204) -- 4
local sprite1 = Sprite("button.clip|prompt") -- 5
sprite1.x = node1.width*0.5 -- 5
sprite1.y = node1.height*0.5 -- 5
node1:addChild(sprite1) -- 5
local area = ScrollArea{scrollBar = false, paddingX = 0, y = node1.height*0.5, x = node1.width*0.5} -- 6
node1:addChild(area) -- 6
node1.area = area -- 6
local view = area.view -- 7
node1.view = view -- 7
return node1 -- 7
end