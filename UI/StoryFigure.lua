-- [xml]: UI/StoryFigure.xml
return function(args) -- 1
local _ENV = Dora(args) -- 1
local node1 = Node() -- 2
local offsets = { -- 4
charF = {x = 330, y = -350, scale = 0.49}, -- 5
charM = {x = 0, y = -560, scale = 0.54}, -- 6
ninilite = {x = -102, y = 40, scale = 0.46}, -- 7
ayan = {x = 187, y = -370, scale = 0.47}, -- 8
villywan = {x = 19, y = 257, scale = 0.33}, -- 9
moling = {x = 0, y = 77, scale = 0.41}, -- 10
moyu = {x = -163, y = -246, scale = 0.43}, -- 11
liyena = {x = 0, y = 405, scale = 0.43}, -- 12
sunborn = {x = 307, y = 244, scale = 0.48}, -- 13
wuyun = {x = 0, y = -480, scale = 0.54}, -- 14
vika = {x = -2733, y = -1553, scale = 1.27}, -- 15
vivi = {x = -2137, y = -2316, scale = 1.3}, -- 16
yuzijiang = {x = 40, y = 261, scale = 0.45}, -- 17
} -- 18
local file, look -- 19
if char == "vivi" then -- 20
file = "spine:vikaFigure" -- 21
look = "vivi" -- 22
elseif char == "vika" then -- 23
file = "spine:vikaFigure" -- 24
look = "vika" -- 25
else -- 26
file = "spine:" .. char .. "Figure" -- 27
look = "" -- 28
end -- 29
local offsetX, offsetY, scale = 0, 0, 1.0 -- 30
if offsets[char] then -- 31
offsetX = offsets[char].x -- 32
offsetY = offsets[char].y -- 33
scale = offsets[char].scale -- 34
end -- 35
local spine = Playable(file) -- 37
spine.x = offsetX -- 37
spine.y = offsetY -- 37
spine.scaleX = scale -- 37
spine.scaleY = scale -- 37
spine.look = look -- 37
spine:play("idle",true) -- 37
node1:addChild(spine) -- 37
do -- 44
	if editing then -- 46
		spine:schedule(function() -- 47
			local width, height -- 48
			do -- 48
				local _obj_0 = App.visualSize -- 48
				width, height = _obj_0.width, _obj_0.height -- 48
			end -- 48
			ImGui.SetNextWindowPos(Vec2(width - 10, 10), "FirstUseEver", Vec2(1, 0)) -- 49
			ImGui.SetNextWindowSize(Vec2(240, 160), "FirstUseEver") -- 50
			return ImGui.Begin(char, { -- 51
				"NoResize", -- 51
				"NoSavedSettings" -- 51
			}, function() -- 51
				local x, y, scale -- 52
				do -- 52
					local _obj_0 = spine -- 52
					x, y, scale = _obj_0.x, _obj_0.y, _obj_0.scaleX -- 52
				end -- 52
				do -- 53
					local changed -- 53
					changed, x = ImGui.DragFloat("X", x, 1, -3000, 3000, "%.2f") -- 53
					if changed then -- 53
						spine.x = x -- 53
					end -- 53
				end -- 53
				do -- 54
					local changed -- 54
					changed, y = ImGui.DragFloat("Y", y, 1, -3000, 3000, "%.2f") -- 54
					if changed then -- 54
						spine.y = y -- 54
					end -- 54
				end -- 54
				local changed -- 55
				changed, scale = ImGui.DragFloat("Scale", scale, 0.01, -2, 2, "%.2f") -- 55
				if changed then -- 55
					spine.scaleX = scale -- 56
					spine.scaleY = scale -- 56
				end -- 55
			end) -- 56
		end) -- 47
	end -- 46
end -- 56
return node1 -- 45
end