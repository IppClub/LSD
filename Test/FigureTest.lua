-- [yue]: Test/FigureTest.yue
local Path = dora.Path -- 1
local Content = dora.Content -- 1
local Director = dora.Director -- 1
local Spine = dora.Spine -- 1
local Node = dora.Node -- 1
local App = dora.App -- 1
local _module_0 = dora.ImGui -- 1
local SetNextWindowBgAlpha = _module_0.SetNextWindowBgAlpha -- 1
local SetNextWindowPos = _module_0.SetNextWindowPos -- 1
local Vec2 = dora.Vec2 -- 1
local SetNextWindowSize = _module_0.SetNextWindowSize -- 1
local Begin = _module_0.Begin -- 1
local Text = _module_0.Text -- 1
local Separator = _module_0.Separator -- 1
local Combo = _module_0.Combo -- 1

do -- 2
	local scriptPath = Path:getScriptPath(...) -- 2
	if scriptPath then -- 2
		scriptPath = Path:getPath(scriptPath) -- 3
		local _list_0 = { -- 5
			scriptPath, -- 5
			Path(scriptPath, "Script"), -- 6
			Path(scriptPath, "Spine"), -- 7
			Path(scriptPath, "Image"), -- 8
			Path(scriptPath, "Font") -- 9
		} -- 4
		for _index_0 = 1, #_list_0 do -- 10
			local path = _list_0[_index_0] -- 4
			Content:insertSearchPath(1, path) -- 11
		end -- 11
	else -- 12
		return -- 12
	end -- 2
end -- 2
local RoleStats = require("UI.RoleStats") -- 14
local roleStats -- 16
do -- 16
	local _with_0 = RoleStats() -- 16
	_with_0:alignLayout() -- 17
	roleStats = _with_0 -- 16
end -- 16
Director.ui3D:addChild(roleStats) -- 18
local figures = { -- 21
	"molingFigure", -- 21
	"ayanFigure", -- 22
	"charFFigure", -- 23
	"charFigure", -- 24
	"charMFigure", -- 25
	"liyenaFigure", -- 26
	"moyuFigure", -- 27
	"niniliteFigure", -- 28
	"sunbornFigure", -- 29
	"villywanFigure", -- 30
	"wuyunFigure", -- 31
	"yuzijiangFigure" -- 32
} -- 20
local currentFigure = 1 -- 34
local spine -- 36
do -- 36
	local _with_0 = Spine(figures[currentFigure]) -- 36
	_with_0.look = "full" -- 37
	_with_0:play("idle", true) -- 38
	_with_0.scaleX = 0.21 -- 39
	_with_0.scaleY = 0.21 -- 40
	spine = _with_0 -- 36
end -- 36
roleStats.figure:addChild(spine) -- 41
return Director.entry:addChild((function() -- 43
	local _with_0 = Node() -- 43
	local windowFlags = { -- 45
		"NoDecoration", -- 45
		"AlwaysAutoResize", -- 46
		"NoSavedSettings", -- 47
		"NoFocusOnAppearing", -- 48
		"NoNav", -- 49
		"NoMove" -- 50
	} -- 44
	_with_0:schedule(function() -- 51
		local width, height -- 52
		do -- 52
			local _obj_0 = App.visualSize -- 52
			width, height = _obj_0.width, _obj_0.height -- 52
		end -- 52
		SetNextWindowBgAlpha(0.35) -- 53
		SetNextWindowPos(Vec2(width - 10, 10), "Always", Vec2(1, 0)) -- 54
		SetNextWindowSize(Vec2(100, 0), "FirstUseEver") -- 55
		return Begin("FigureTest", windowFlags, function() -- 56
			Text("Figure") -- 57
			Separator() -- 58
			local changed -- 59
			changed, currentFigure = Combo("Change", currentFigure, figures) -- 59
			if changed then -- 60
				spine:removeFromParent() -- 61
				do -- 62
					local _with_1 = Spine(figures[currentFigure]) -- 62
					_with_1.look = "full" -- 63
					_with_1:play("idle", true) -- 64
					_with_1.scaleX = 0.21 -- 65
					_with_1.scaleY = 0.21 -- 66
					spine = _with_1 -- 62
				end -- 62
				return roleStats.figure:addChild(spine) -- 67
			end -- 60
		end) -- 67
	end) -- 51
	return _with_0 -- 43
end)()) -- 67
