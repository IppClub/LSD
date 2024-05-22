-- [yue]: Script/Scene/VRTraining.yue
local Vec2 = Dora.Vec2 -- 1
local math = _G.math -- 1
local Content = Dora.Content -- 1
local table = _G.table -- 1
local Spine = Dora.Spine -- 1
local Class = Dora.Class -- 1
local property = Dora.property -- 1
local View = Dora.View -- 1
local _module_0 = Dora.Platformer -- 1
local PlatformWorld = _module_0.PlatformWorld -- 1
local Rect = Dora.Rect -- 1
local Sequence = Dora.Sequence -- 1
local Opacity = Dora.Opacity -- 1
local utf8 = _G.utf8 -- 1
local Label = Dora.Label -- 1
local Color3 = Dora.Color3 -- 1
local loop = Dora.loop -- 1
local Node = Dora.Node -- 1
local once = Dora.once -- 1
local sleep = Dora.sleep -- 1
local Show = Dora.Show -- 1
local Ease = Dora.Ease -- 1
local Hide = Dora.Hide -- 1
local BodyDef = Dora.BodyDef -- 1
local Body = Dora.Body -- 1
local Data = _module_0.Data -- 1
local Cache = Dora.Cache -- 1
local _module_0 = nil -- 1
local Struct = require("Utils").Struct -- 2
local u8 = require("utf-8") -- 3
local W <const> = 3840 -- 5
local HW <const> = W / 2 -- 6
local H <const> = 1080 -- 7
local HH <const> = H / 2 -- 8
local Offset <const> = 140 -- 9
local PathOffset <const> = Vec2(50, 30) -- 10
local MaxPath <const> = 2 -- 11
local DefaultZoom <const> = 1.0 -- 12
local FrameScale <const> = 1 -- 14
local FrameLook <const> = "frame1" -- 15
local FrameHeight <const> = 630 -- 16
local FrameWidth <const> = 1308 -- 17
local FrameCol <const> = 21 -- 18
local FrameSize <const> = FrameWidth / FrameCol -- 19
local FrameRow <const> = math.floor(FrameHeight / FrameSize) -- 20
local FrameLen <const> = FrameCol * FrameRow -- 21
local CodeFile <const> = "Data/wenyan-lang.xlsx" -- 23
local codes = Content:loadExcel(CodeFile, { -- 25
	"codes" -- 25
}).codes -- 25
do -- 26
	Struct.Wenyan(codes[1]) -- 27
	table.remove(codes, 1) -- 28
	for _index_0 = 1, #codes do -- 29
		local code = codes[_index_0] -- 29
		Struct:load("Wenyan", code) -- 30
	end -- 30
end -- 30
local layerDefs = { -- 39
	{ -- 39
		look = "floor", -- 39
		order = -100 -- 39
	}, -- 39
	{ -- 40
		look = "stats", -- 40
		order = -101, -- 40
		handle = function(self) -- 40
			self.z = 600 -- 41
			self:play("stat", true) -- 42
			return self -- 40
		end -- 40
	}, -- 40
	{ -- 43
		look = "back", -- 43
		order = -102 -- 43
	} -- 43
} -- 38
local addLayer -- 45
addLayer = function(world, def) -- 45
	local layer -- 46
	do -- 46
		local _with_0 = Spine("VRTraining") -- 46
		_with_0.look = def.look -- 47
		_with_0.order = def.order -- 48
		layer = _with_0 -- 46
	end -- 46
	if def.ratio then -- 49
		world:setLayerRatio(def.order, def.ratio) -- 50
	end -- 49
	if def.offset then -- 51
		world:setLayerOffset(def.order, def.offset) -- 52
	end -- 51
	world:addChild(layer) -- 53
	if def.handle then -- 54
		def.handle(layer) -- 54
	end -- 54
	return layer -- 55
end -- 45
_module_0 = Class({ -- 58
	width = property(function() -- 58
		return W -- 58
	end), -- 58
	offset = property(function() -- 59
		return Offset -- 59
	end), -- 59
	addShadowTo = function(_self) end, -- 61
	zoom = property(function(self) -- 63
		return self._zoom -- 63
	end, function(self, value) -- 64
		self._zoom = value -- 65
		return self:updateZoom() -- 66
	end), -- 63
	updateZoom = function(self) -- 68
		local width, height -- 69
		do -- 69
			local _obj_0 = View.size -- 69
			width, height = _obj_0.width, _obj_0.height -- 69
		end -- 69
		local zoom = self._zoom / DefaultZoom -- 70
		zoom = math.max(width / W / zoom, height / H / zoom) -- 71
		local realWidth = math.min(W / zoom, W) -- 72
		local realHeight = math.min(H / zoom, H) -- 73
		zoom = math.max(W / realWidth, H / realHeight) -- 74
		self.camera.zoom = zoom -- 75
	end, -- 68
	__partial = function(_self) -- 77
		local _with_0 = PlatformWorld() -- 78
		do -- 79
			local _with_1 = _with_0.camera -- 79
			_with_1.boundary = Rect(0, 0, W, H) -- 80
			_with_1.followRatio = Vec2(0.03, 0.03) -- 81
		end -- 79
		_with_0.tag = "VRTraining" -- 82
		return _with_0 -- 78
	end, -- 77
	__init = function(self) -- 84
		for i = -MaxPath, MaxPath do -- 85
			self:setLayerOffset(i, PathOffset * -i) -- 86
		end -- 86
		for _index_0 = 1, #layerDefs do -- 88
			local def = layerDefs[_index_0] -- 88
			addLayer(self, def) -- 89
		end -- 89
		local code = codes[math.random(1, #codes)] -- 91
		local codeStr = code.code -- 92
		local len = u8.len(codeStr) -- 93
		local start = 1 -- 94
		local i = 0 -- 95
		local lefts = { } -- 96
		local rights = { } -- 97
		local blink = Sequence(Opacity(0.1, 0.2, 1), Opacity(1, 1, 0.2)) -- 98
		while true do -- 102
			i = i + 1 -- 103
			local fontSize = math.floor(FrameSize * FrameScale) - 6 -- 104
			if start >= len then -- 105
				break -- 105
			end -- 105
			local codePanel -- 106
			do -- 106
				local _with_0 = Spine("VRTraining") -- 106
				_with_0.scaleX = FrameScale -- 107
				_with_0.scaleY = FrameScale -- 108
				_with_0.look = FrameLook -- 109
				if i % 2 ~= 0 then -- 110
					_with_0.x = math.random(0, (W / 2) - math.floor(FrameWidth * FrameScale) - 600) -- 111
				else -- 113
					_with_0.x = math.random((W / 2) + 600, W - math.floor(FrameWidth * FrameScale)) -- 113
				end -- 110
				_with_0.y = math.random(350, H - math.floor(FrameHeight * FrameScale) - 100) -- 114
				_with_0.z = math.random(100, 500) -- 115
				_with_0.order = -3 -- 116
				_with_0.visible = false -- 117
				_with_0.opacity = 0 -- 118
				codePanel = _with_0 -- 106
			end -- 106
			if i % 2 ~= 0 then -- 119
				table.insert(lefts, codePanel) -- 120
			else -- 122
				table.insert(rights, codePanel) -- 122
			end -- 119
			self:addChild(codePanel) -- 123
			local str = u8.sub(codeStr, start, start + FrameLen - 1) -- 124
			local row = 1 -- 125
			local col = 1 -- 126
			local chars -- 127
			do -- 127
				local _accum_0 = { } -- 127
				local _len_0 = 1 -- 127
				for _, c in utf8.codes(str) do -- 127
					local ch = utf8.char(c) -- 128
					local label -- 129
					do -- 129
						local _with_0 = Label("DroidSansFallback", fontSize) -- 129
						_with_0.color3 = Color3(0x4aa0e8) -- 130
						_with_0.text = ch -- 131
						_with_0.x = (FrameWidth - (FrameSize / 2) - FrameSize * (col - 1)) * FrameScale -- 132
						_with_0.y = (FrameHeight - (FrameSize / 2) - FrameSize * (row - 1)) * FrameScale -- 133
						_with_0.opacity = 0.2 -- 134
						label = _with_0 -- 129
					end -- 129
					codePanel:addChild(label) -- 135
					row = row + 1 -- 136
					if row > FrameRow then -- 137
						row = 1 -- 138
						col = col + 1 -- 139
					end -- 137
					_accum_0[_len_0] = label -- 140
					_len_0 = _len_0 + 1 -- 140
				end -- 140
				chars = _accum_0 -- 127
			end -- 140
			codePanel:schedule(loop(function() -- 141
				codePanel:addChild((function() -- 142
					local _with_0 = Node() -- 142
					_with_0:schedule(once(function() -- 143
						for _index_0 = 1, #chars do -- 144
							local char = chars[_index_0] -- 144
							char:perform(blink) -- 145
							sleep(0.01) -- 146
						end -- 146
						return _with_0:removeFromParent() -- 147
					end)) -- 143
					return _with_0 -- 142
				end)()) -- 142
				return sleep(2) -- 148
			end)) -- 141
			start = start + FrameLen -- 149
		end -- 149
		local index = 1 -- 150
		local count = math.max(#lefts, #rights) -- 151
		self:schedule(loop(function() -- 152
			local left = lefts[index] -- 153
			local right = rights[index] -- 154
			if left then -- 158
				left:perform(Sequence(Show(), Opacity(5, 0, 1, Ease.InQuad))) -- 155
			end -- 158
			if right then -- 162
				right:perform(Sequence(Show(), Opacity(5, 0, 1, Ease.InQuad))) -- 159
			end -- 162
			if count == 1 then -- 163
				return true -- 163
			end -- 163
			sleep(10) -- 164
			if left then -- 168
				left:perform(Sequence(Opacity(5, 1, 0, Ease.OutQuad), Hide())) -- 165
			end -- 168
			if right then -- 172
				right:perform(Sequence(Opacity(5, 1, 0, Ease.OutQuad), Hide())) -- 169
			end -- 172
			index = index + 1 -- 173
			if index > count then -- 174
				index = 1 -- 174
			end -- 174
		end)) -- 152
		local terrainDef -- 175
		do -- 175
			local _with_0 = BodyDef() -- 175
			_with_0.type = "Static" -- 176
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 177
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 178
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 179
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 180
			_with_0.position = Vec2(0, Offset) -- 181
			terrainDef = _with_0 -- 175
		end -- 175
		do -- 183
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 183
			_with_0.group = Data.groupTerrain -- 184
			_with_0:addTo(self) -- 185
		end -- 183
		self._zoom = 1.0 -- 187
		self:gslot("AppSizeChanged", function() -- 188
			return self:updateZoom() -- 188
		end) -- 188
		return self:updateZoom() -- 189
	end, -- 84
	loadAsync = function(_self) -- 191
		return Cache:loadAsync("spine:VRTraining") -- 191
	end -- 191
}) -- 57
return _module_0 -- 191
