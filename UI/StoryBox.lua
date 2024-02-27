-- [xml]: UI/StoryBox.xml
local MovingText = require("UI.MovingText") -- 2
return function(args) -- 1
local _ENV = Dora(args) -- 1
local box = Node() -- 3
box.size = Size(1071,103) -- 3
local bk = Grid("button.clip|role_story_4", 1, 3) -- 4
bk.x = box.width*0.5 + 15 -- 4
bk.visible = content ~= nil -- 4
box:addChild(bk) -- 4
local tab = Sprite("button.clip|role_story_2") -- 5
tab.anchor = Vec2(0,0) -- 5
tab.y = 20 -- 5
tab.color3 = Color3(content and 0x7ec0f8 or 0xffffff) -- 5
box:addChild(tab) -- 5
local item1 = MovingText{color3 = 0xffffff, passColor = content ~= nil, textBG = "STORY"} -- 6
tab:addChild(item1) -- 6
local mask = item1.mask -- 7
local sprite1 = Sprite("button.clip|btn_big_1") -- 8
sprite1.anchor = Vec2(0,0) -- 8
mask:addChild(sprite1) -- 8
if not content then -- 12
local sprite2 = Sprite("button.clip|role_story_lock") -- 13
sprite2.anchor = Vec2(0,sprite2.anchor.y) -- 13
sprite2.x = 35 -- 13
sprite2.y = 61.5 -- 13
box:addChild(sprite2) -- 13
end -- 14
local tt = Label("SourceHanSansCN-Regular",50) -- 15
tt.anchor = Vec2(0,tt.anchor.y) -- 15
tt.x = content and 35 or 35 + 52 -- 15
tt.y = 61.5 -- 15
tt.color3 = Color3(0xffffff) -- 15
tt.alignment = "Left" -- 15
tt.text = title or '' -- 15
box:addChild(tt) -- 15
if requirement then -- 19
local label1 = Label("SourceHanSansCN-Regular",40) -- 20
label1.anchor = Vec2(0,label1.anchor.y) -- 20
label1.x = 363 -- 20
label1.y = 61.5 -- 20
label1.color3 = Color3(0xffffff) -- 20
label1.alignment = "Left" -- 20
label1.text = requirement -- 20
box:addChild(label1) -- 20
end -- 24
local txt = Label("SourceHanSansCN-Regular",40) -- 25
txt.anchor = Vec2(0,1) -- 25
txt.x = 75 -- 25
txt.color3 = Color3(0xffffff) -- 25
txt.visible = content ~= nil -- 25
txt.alignment = "Left" -- 25
txt.textWidth = 950 -- 25
txt.text = content or '' -- 25
box:addChild(txt) -- 25
do -- 28
	if content then -- 30
		local padding = 20 -- 31
		local height = txt.height -- 32
		local offset = 30 + height + 83 / 3 -- 33
		txt.y = offset - 30 + padding -- 34
		tt.y = offset + 41.5 + padding -- 35
		box.height = 83 + offset + padding -- 36
		tab.y = offset + padding -- 37
		do -- 38
			local _with_0 = bk -- 38
			local yOffset = height + 30 -- 39
			_with_0.y = 83 / 2 + padding -- 40
			local x, y -- 41
			do -- 41
				local _obj_0 = _with_0:getPos(1, 1) -- 41
				x, y = _obj_0.x, _obj_0.y -- 41
			end -- 41
			_with_0:setPos(1, 1, Vec2(x, y + yOffset)) -- 42
			do -- 43
				local _obj_0 = _with_0:getPos(2, 1) -- 43
				x, y = _obj_0.x, _obj_0.y -- 43
			end -- 43
			_with_0:setPos(2, 1, Vec2(x, y + yOffset)) -- 44
		end -- 38
	end -- 30
end -- 44
return box -- 29
end