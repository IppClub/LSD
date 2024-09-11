-- [yue]: Script/System/PlayOP.yue
local View = Dora.View -- 1
local Director = Dora.Director -- 1
local Color = Dora.Color -- 1
local Cache = Dora.Cache -- 1
local tostring = _G.tostring -- 1
local Playable = Dora.Playable -- 1
local once = Dora.once -- 1
local Audio = Dora.Audio -- 1
local sleep = Dora.sleep -- 1
local wait = Dora.wait -- 1
local _module_0 = nil -- 1
local PVInfo -- 3
PVInfo = { -- 4
	{ -- 4
		3003, -- 4
		1688, -- 4
		3.1666667461395 -- 4
	}, -- 4
	{ -- 5
		3000, -- 5
		1686, -- 5
		4.0 -- 5
	}, -- 5
	{ -- 6
		3013, -- 6
		1699, -- 6
		4.2666668891907 -- 6
	}, -- 6
	{ -- 7
		2988, -- 7
		1700, -- 7
		5.0000004768372 -- 7
	}, -- 7
	{ -- 8
		3017, -- 8
		1704, -- 8
		5.3333334922791 -- 8
	}, -- 8
	{ -- 9
		3021, -- 9
		1704, -- 9
		5.0000004768372 -- 9
	}, -- 9
	{ -- 10
		3018, -- 10
		1703, -- 10
		2.8333334922791 -- 10
	}, -- 10
	{ -- 11
		3018, -- 11
		1706, -- 11
		3.0000002384186, -- 11
		0.1 -- 11
	}, -- 11
	{ -- 12
		3020, -- 12
		1707, -- 12
		3.0000002384186 -- 12
	}, -- 12
	{ -- 13
		1162, -- 13
		656, -- 13
		4.1666669845581 -- 13
	}, -- 13
	{ -- 14
		2999, -- 14
		1687, -- 14
		4.6666669845581 -- 14
	}, -- 14
	{ -- 15
		2928, -- 15
		1650, -- 15
		4.0 -- 15
	}, -- 15
	{ -- 16
		2926, -- 16
		1650, -- 16
		1.5000001192093 -- 16
	}, -- 16
	{ -- 17
		2927, -- 17
		1651, -- 17
		1.5000001192093 -- 17
	}, -- 17
	{ -- 18
		2926, -- 18
		1651, -- 18
		2.566666841507 -- 18
	}, -- 18
	{ -- 19
		2927, -- 19
		1650, -- 19
		1.6666667461395 -- 19
	}, -- 19
	{ -- 20
		2903, -- 20
		1629, -- 20
		1.5000001192093 -- 20
	}, -- 20
	{ -- 21
		3006, -- 21
		1689, -- 21
		5.0000004768372 -- 21
	}, -- 21
	{ -- 22
		2907, -- 22
		1632, -- 22
		0.66666668653488 -- 22
	}, -- 22
	{ -- 23
		2999, -- 23
		1686, -- 23
		2.0 -- 23
	}, -- 23
	{ -- 24
		2907, -- 24
		1631, -- 24
		1.0666667222977 -- 24
	}, -- 24
	{ -- 25
		2907, -- 25
		1631, -- 25
		3, -- 25
		1.0 -- 25
	}, -- 25
	{ -- 26
		2907, -- 26
		1631, -- 26
		5.3333334922791 -- 26
	}, -- 26
	{ -- 27
		2998, -- 27
		1685, -- 27
		1.1666667461395 -- 27
	}, -- 27
	{ -- 28
		3353, -- 28
		1882, -- 28
		4.0 -- 28
	}, -- 28
	{ -- 29
		2918, -- 29
		1646, -- 29
		6.6666669845581 -- 29
	} -- 29
} -- 3
local scaleView -- 32
scaleView = function(self, index) -- 32
	local width, height, time, target -- 33
	do -- 33
		local _obj_0 = PVInfo[index] -- 33
		width, height, time, target = _obj_0[1], _obj_0[2], _obj_0[3], _obj_0[4] -- 33
		if target == nil then -- 33
			target = time -- 33
		end -- 33
	end -- 33
	local w, h -- 34
	do -- 34
		local _obj_0 = View.size -- 34
		w, h = _obj_0.width, _obj_0.height -- 34
	end -- 34
	local scale -- 35
	if (w / h) > (width / height) then -- 35
		scale = h / height -- 36
	else -- 38
		scale = w / width -- 38
	end -- 35
	self.scaleX = scale -- 39
	self.scaleY = scale -- 40
	self.speed = time / target -- 41
end -- 32
local playOP -- 43
playOP = function() -- 43
	Director.clearColor = Color(0x0) -- 44
	local start = 1 -- 45
	Cache:loadAsync("spine:PV1/PV1_" .. tostring(start)) -- 46
	for i = start, #PVInfo do -- 47
		if (9 == i or 19 == i) then -- 48
			goto _continue_0 -- 48
		end -- 48
		local playEnded = false -- 49
		local nextViewLoaded = false -- 50
		local playable = Playable("spine:PV1/PV1_" .. tostring(i)) -- 51
		playable:play("animation", i == 1) -- 52
		playable:gslot("AppChange", function(settingName) -- 53
			if settingName == "Size" then -- 53
				return scaleView(playable, i) -- 53
			end -- 53
		end) -- 53
		scaleView(playable, i) -- 54
		if i + 1 <= #PVInfo then -- 55
			playable:schedule(once(function() -- 56
				Cache:loadAsync("spine:PV1/PV1_" .. tostring(i + 1)) -- 57
				nextViewLoaded = true -- 58
			end)) -- 56
		else -- 60
			nextViewLoaded = true -- 60
		end -- 55
		playable:addTo(Director.entry) -- 61
		Cache:unload("PV1/PV1_" .. tostring(i) .. ".atlas") -- 62
		Cache:unload("spine:PV1/PV1_" .. tostring(i)) -- 63
		if i == 1 then -- 64
			Audio:playStream("Music/L·S·Depart.mp3", true) -- 65
			sleep(3) -- 66
			local Story = require("UI.Story") -- 67
			local story -- 68
			do -- 68
				local _with_0 = Story("Tutorial/Dialog/startUp.yarn") -- 68
				_with_0:slot("Ended", function() -- 69
					playEnded = true -- 69
				end) -- 69
				_with_0:showAsync() -- 70
				_with_0:addTo(Director.ui3D) -- 71
				story = _with_0 -- 68
			end -- 68
			wait(function() -- 72
				return playEnded -- 72
			end) -- 72
			Audio:playStream("Music/L·S·DepartII.mp3", false, 1) -- 73
			sleep(2) -- 74
		else -- 76
			playable:slot("end", function() -- 76
				playEnded = true -- 76
			end) -- 76
			playable:slot("AnimationEnd", function() -- 77
				playEnded = true -- 77
			end) -- 77
		end -- 64
		wait(function() -- 78
			return playEnded and nextViewLoaded -- 78
		end) -- 78
		if i + 1 <= #PVInfo then -- 79
			playable:removeFromParent() -- 80
			Cache:removeUnused("Texture") -- 81
		end -- 79
		::_continue_0:: -- 48
	end -- 81
end -- 43
_module_0 = playOP -- 83
return _module_0 -- 83
