-- [xml]: UI/FormationRole.xml
local figureDefs = { -- 3
charF = {x = 572, y = -492.5, scale = 0.44}, -- 4
moling = {x = 235, y = -151.5, scale = 0.37}, -- 5
moyu = {x = -45, y = -408.5, scale = 0.4}, -- 6
liyena = {x = 239, y = 269.5, scale = 0.4}, -- 7
ayan = {x = 552, y = -652.5, scale = 0.48}, -- 8
charM = {x = 246, y = -657.5, scale = 0.48}, -- 9
villywan = {x = 240, y =162, scale = 0.32}, -- 10
yuzijiang = {x = 301, y = 8.5, scale = 0.45}, -- 11
ninilite = {x = 108, y = -60.5, scale = 0.42}, -- 12
wuyun = {x = 306, y = -608.5, scale = 0.48}, -- 13
sunborn = {x = 565, y = 9.5, scale = 0.44}, -- 14
} -- 15
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 17
node1.x = x or 0 -- 17
node1.y = y or 0 -- 17
node1.size = Size(510,1017) -- 17
node1.touchEnabled = true -- 17
local scale = math.min(App.bufferSize.height / 1563, 1.0) -- 18
local bk = Playable("bone:formationRole") -- 19
bk.x = node1.width*0.5 -- 19
bk.y = node1.height*0.5 -- 19
node1:addChild(bk) -- 19
local icon_add_light = bk:getChildByTag("icon_add_light") -- 20
icon_add_light.visible = false -- 20
local icon_add = bk:getChildByTag("icon_add") -- 21
icon_add.visible = false -- 21
local role_bg_light = bk:getChildByTag("role_bg_light") -- 22
role_bg_light.visible = false -- 22
local role_img = bk:getChildByTag("role_img") -- 23
role_img.visible = false -- 23
local role_bg = bk:getChildByTag("role_bg") -- 24
role_bg.visible = true -- 24
local reinforce = bk:getChildByTag("reinforce") -- 25
reinforce.visible = false -- 25
local captain = bk:getChildByTag("captain") -- 26
captain.visible = cap -- 26
local roleNode = bk:getChildByTag("role") -- 27
roleNode.visible = true -- 27
local clip = Node() -- 28
clip.scaleX = 1 / scale -- 28
clip.scaleY = 1 / scale -- 28
clip.size = Size(504 * scale,1011 * scale) -- 28
roleNode:addChild(clip) -- 28
do -- 28
	do -- 30
		local _with_0 = clip:grab(1, 2) -- 30
		_with_0:setColor(1, 3, Color(0x22ffffff)) -- 31
		_with_0:setColor(2, 3, Color(0x22ffffff)) -- 32
	end -- 30
end -- 32
local node2 = Node() -- 34
node2.scaleX = scale -- 34
node2.scaleY = scale -- 34
clip:addChild(node2) -- 34
if editing then -- 35
local playable = Playable('spine:' .. role .. 'Figure') -- 36
playable.x = figureDefs[role].x -- 36
playable.y = figureDefs[role].y -- 36
playable.scaleX = figureDefs[role].scale -- 36
playable.scaleY = figureDefs[role].scale -- 36
playable.speed = 0.5 -- 36
playable:play("idle",true) -- 36
node2:addChild(playable) -- 36
do -- 42
	if editing then -- 44
		local scaleX = playable.scaleX -- 45
		clip:schedule(function() -- 46
			local width, height -- 47
			do -- 47
				local _obj_0 = App.visualSize -- 47
				width, height = _obj_0.width, _obj_0.height -- 47
			end -- 47
			ImGui.SetNextWindowPos(Vec2(width - 10, 10), "FirstUseEver", Vec2(1, 0)) -- 48
			ImGui.SetNextWindowSize(Vec2(240, 160), "FirstUseEver") -- 49
			return ImGui.Begin(role, { -- 50
				"NoResize", -- 50
				"NoSavedSettings" -- 50
			}, function() -- 50
				local x = playable.x -- 51
				local changed -- 52
				changed, x = ImGui.DragFloat("X", x, 1, -2000, 2000, "%.2f") -- 52
				if changed then -- 53
					playable.x = x -- 53
				end -- 53
				local y = playable.y -- 54
				changed, y = ImGui.DragFloat("Y", y, 1, -2000, 2000, "%.2f") -- 55
				if changed then -- 56
					playable.y = y -- 56
				end -- 56
				changed, scaleX = ImGui.DragFloat("Scale", scaleX, 0.01, -2, 2, "%.2f") -- 57
				if changed then -- 58
					playable.scaleX, playable.scaleY = scaleX, scaleX -- 58
				end -- 58
			end) -- 58
		end) -- 46
	end -- 44
end -- 58
else -- 60
local playable1 = Playable('spine:' .. role .. 'Figure') -- 61
playable1.x = figureDefs[role].x -- 61
playable1.y = figureDefs[role].y -- 61
playable1.scaleX = figureDefs[role].scale -- 61
playable1.scaleY = figureDefs[role].scale -- 61
playable1.speed = 0.5 -- 61
playable1:play("idle",true) -- 61
node2:addChild(playable1) -- 61
end -- 67
return node1 -- 67
end