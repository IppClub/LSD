-- [xml]: UI/StoryFigure.xml
local offsets = { -- 3
charF = {x = 330, y = -350, scale = 0.49}, -- 4
charM = {x = 0, y = -560, scale = 0.54}, -- 5
ninilite = {x = 0, y = 40, scale = 0.46} -- 6
} -- 7
return function(args) -- 1
local _ENV = Dora(args) -- 1
local spine = Playable('spine:' .. char .. 'Figure') -- 9
spine.x = offsets[char].x -- 9
spine.y = offsets[char].y -- 9
spine.scaleX = offsets[char].scale -- 9
spine.scaleY = offsets[char].scale -- 9
spine:play("idle",true) -- 9
do -- 15
	if editing then -- 17
		spine:schedule(function() -- 18
			local width, height -- 19
			do -- 19
				local _obj_0 = App.visualSize -- 19
				width, height = _obj_0.width, _obj_0.height -- 19
			end -- 19
			ImGui.SetNextWindowPos(Vec2(width - 10, 10), "FirstUseEver", Vec2(1, 0)) -- 20
			ImGui.SetNextWindowSize(Vec2(240, 160), "FirstUseEver") -- 21
			return ImGui.Begin(char, { -- 22
				"NoResize", -- 22
				"NoSavedSettings" -- 22
			}, function() -- 22
				local x, y, scale -- 23
				do -- 23
					local _obj_0 = spine -- 23
					x, y, scale = _obj_0.x, _obj_0.y, _obj_0.scaleX -- 23
				end -- 23
				do -- 24
					local changed -- 24
					changed, x = ImGui.DragFloat("X", x, 1, -2000, 2000, "%.2f") -- 24
					if changed then -- 24
						spine.x = x -- 24
					end -- 24
				end -- 24
				do -- 25
					local changed -- 25
					changed, y = ImGui.DragFloat("Y", y, 1, -2000, 2000, "%.2f") -- 25
					if changed then -- 25
						spine.y = y -- 25
					end -- 25
				end -- 25
				local changed -- 26
				changed, scale = ImGui.DragFloat("Scale", scale, 0.01, -2, 2, "%.2f") -- 26
				if changed then -- 26
					spine.scaleX = scale -- 27
					spine.scaleY = scale -- 27
				end -- 26
			end) -- 27
		end) -- 18
	end -- 17
end -- 27
return spine -- 16
end