-- [yue]: Script/Scene/LoopTowerA.yue
local Vec2 = dora.Vec2 -- 1
local Spine = dora.Spine -- 1
local Class = dora.Class -- 1
local property = dora.property -- 1
local Sprite = dora.Sprite -- 1
local _module_0 = dora.Platformer -- 1
local Data = _module_0.Data -- 1
local View = dora.View -- 1
local math = _G.math -- 1
local PlatformWorld = _module_0.PlatformWorld -- 1
local Rect = dora.Rect -- 1
local ClipNode = dora.ClipNode -- 1
local BodyDef = dora.BodyDef -- 1
local Body = dora.Body -- 1
local Node = dora.Node -- 1
local Director = dora.Director -- 1
local Cache = dora.Cache -- 1
local _module_0 = nil -- 1
local SceneScale <const> = 1.7 -- 3
local W <const> = (11700 + 4000) / SceneScale -- 4
local H <const> = (2616 + 2000) / SceneScale -- 5
local HH <const> = H / 2 -- 6
local Offset <const> = 150 -- 7
local PathOffset <const> = Vec2(10, 10) -- 8
local MaxPath <const> = 2 -- 9
local DefaultZoom <const> = 0.45 -- 10
local layerDefs = { -- 19
	{ -- 19
		look = "front", -- 19
		order = 100 -- 19
	}, -- 19
	{ -- 20
		look = "backitem", -- 20
		order = -100 -- 20
	}, -- 20
	{ -- 21
		look = "floor", -- 21
		order = -101 -- 21
	}, -- 21
	{ -- 22
		look = "window", -- 22
		order = -102 -- 22
	}, -- 22
	{ -- 23
		look = "windowmask", -- 23
		order = -103 -- 23
	}, -- 23
	{ -- 24
		look = "windowoutside", -- 24
		order = -104, -- 24
		ratio = Vec2(-0.1, 0) -- 24
	}, -- 24
	{ -- 25
		look = "back", -- 25
		order = -105 -- 25
	}, -- 25
	{ -- 26
		look = "door", -- 26
		order = -106 -- 26
	}, -- 26
	{ -- 27
		look = "doorinside", -- 27
		order = -107 -- 27
	} -- 27
} -- 18
local lightDefs -- 29
do -- 29
	local _accum_0 = { } -- 29
	local _len_0 = 1 -- 29
	for _index_0 = 1, #layerDefs do -- 29
		local def = layerDefs[_index_0] -- 29
		if def.light then -- 29
			_accum_0[_len_0] = def -- 29
			_len_0 = _len_0 + 1 -- 29
		end -- 29
	end -- 29
	lightDefs = _accum_0 -- 29
end -- 29
local darkDefs -- 30
do -- 30
	local _accum_0 = { } -- 30
	local _len_0 = 1 -- 30
	for _index_0 = 1, #layerDefs do -- 30
		local def = layerDefs[_index_0] -- 30
		if def.light ~= nil and def.light == false then -- 30
			_accum_0[_len_0] = def -- 30
			_len_0 = _len_0 + 1 -- 30
		end -- 30
	end -- 30
	darkDefs = _accum_0 -- 30
end -- 30
local addLayer -- 32
addLayer = function(world, def) -- 32
	local layer -- 33
	do -- 33
		local _with_0 = Spine("loopTowerA") -- 33
		_with_0.scaleX = 1 / SceneScale -- 34
		_with_0.scaleY = 1 / SceneScale -- 35
		_with_0.look = def.look -- 36
		_with_0.order = def.order -- 37
		layer = _with_0 -- 33
	end -- 33
	if def.ratio then -- 38
		world:setLayerRatio(def.order, def.ratio) -- 39
	end -- 38
	world:addChild(layer) -- 40
	if def.handle then -- 41
		def.handle(layer, world) -- 41
	end -- 41
	return layer -- 42
end -- 32
_module_0 = Class({ -- 45
	width = property(function() -- 45
		return W -- 45
	end), -- 45
	offset = property(function() -- 46
		return Offset -- 46
	end), -- 46
	addShadowTo = function(self, unit) -- 48
		local _with_0 = Sprite("Image/shadow.png") -- 49
		_with_0.order = -1 -- 50
		_with_0:schedule(function() -- 51
			local position = unit.position -- 52
			local target = position -- 53
			if self:raycast(position, Vec2(position.x, position.y - 1000), false, function(body, point) -- 54
				if body.group == Data.groupTerrain then -- 55
					target = point -- 56
					return true -- 57
				else -- 59
					return false -- 59
				end -- 55
			end) then -- 54
				_with_0.y = target.y - unit.y -- 60
			end -- 54
		end) -- 51
		_with_0:addTo(unit) -- 61
		return _with_0 -- 49
	end, -- 48
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
		local zoom = self._zoom * DefaultZoom -- 70
		self.camera.zoom = math.max(height / H / zoom, width / W / zoom) -- 71
	end, -- 68
	__partial = function(_) -- 73
		local _with_0 = PlatformWorld() -- 74
		do -- 75
			local _with_1 = _with_0.camera -- 75
			_with_1.boundary = Rect(0, 0, W, H) -- 76
			_with_1.followRatio = Vec2(0.03, 0.03) -- 77
			_with_1.followOffset = Vec2(0, 200) -- 78
		end -- 75
		_with_0.tag = "LoopTowerA" -- 79
		return _with_0 -- 74
	end, -- 73
	openRightDoor = function(self) -- 81
		return self._layers.door:play("openR") -- 81
	end, -- 81
	__init = function(self) -- 83
		for i = -MaxPath, MaxPath do -- 84
			self:setLayerOffset(i, PathOffset * -i) -- 85
		end -- 85
		do -- 87
			local _tbl_0 = { } -- 87
			for _index_0 = 1, #layerDefs do -- 87
				local def = layerDefs[_index_0] -- 87
				_tbl_0[def.look] = addLayer(self, def) -- 87
			end -- 87
			self._layers = _tbl_0 -- 87
		end -- 87
		do -- 89
			local mask = self._layers.windowmask -- 89
			mask:removeFromParent(false) -- 90
			local clip = ClipNode(mask) -- 91
			clip.order = mask.order -- 92
			clip:addTo(self) -- 93
			local _with_0 = self._layers.windowoutside -- 94
			_with_0.transformTarget = _with_0.parent -- 95
			_with_0:moveToParent(clip) -- 96
		end -- 89
		local RightDoorSensor <const> = 0 -- 98
		local terrainDef -- 99
		do -- 99
			local _with_0 = BodyDef() -- 99
			_with_0.type = "Static" -- 100
			_with_0:attachPolygon(Vec2(959 / SceneScale, 0), 1918 / SceneScale, 10, 0, 1, 1, 0) -- 101
			_with_0:attachPolygon(Vec2(5838 / SceneScale, 398 / SceneScale), 7880 / SceneScale, 10, -5.8, 1, 1, 0) -- 102
			_with_0:attachPolygon(Vec2(10618.5 / SceneScale, 796 / SceneScale), 1721 / SceneScale, 10, 0, 1, 1, 0) -- 103
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 104
			_with_0:attachPolygon(Vec2(11479 / SceneScale, HH), 10, H, 0, 1, 1, 0) -- 105
			_with_0:attachPolygonSensor(RightDoorSensor, Vec2(6230, 675), 300, 400) -- 106
			_with_0.position = Vec2(0, Offset) -- 107
			terrainDef = _with_0 -- 99
		end -- 99
		do -- 109
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 109
			_with_0.group = Data.groupTerrain -- 110
			_with_0:addTo(self) -- 111
			_with_0:slot("BodyEnter", function(body, sensorTag) -- 112
				if sensorTag == RightDoorSensor then -- 113
					if not body.entity then -- 114
						return -- 114
					end -- 114
					if not body.entity.player then -- 115
						return -- 115
					end -- 115
					body.entity.enterExit = true -- 116
				end -- 113
			end) -- 112
			_with_0:slot("BodyLeave", function(body, sensorTag) -- 117
				if sensorTag == RightDoorSensor then -- 118
					if not body.entity then -- 119
						return -- 119
					end -- 119
					if not body.entity.player then -- 120
						return -- 120
					end -- 120
					body.entity.enterExit = false -- 121
				end -- 118
			end) -- 117
		end -- 109
		self._zoom = 1.0 -- 123
		self:gslot("AppSizeChanged", function() -- 124
			return self:updateZoom() -- 124
		end) -- 124
		self:updateZoom() -- 125
		local world = self -- 127
		world.scaleX = 1.33 -- 128
		world.scaleY = 1.33 -- 129
		return world:slot("Enter", function() -- 130
			local node = Node() -- 131
			node:addTo(world.parent) -- 132
			node:schedule(function() -- 133
				local position, zoom -- 134
				do -- 134
					local _obj_0 = Director.currentCamera -- 134
					position, zoom = _obj_0.position, _obj_0.zoom -- 134
				end -- 134
				local size = View.size * Vec2(1.0 / zoom, 1.0 / zoom) -- 135
				node.scaleX = 1.33 -- 136
				node.scaleY = 1.33 -- 137
				local h = size.height -- 138
				node.position = position -- 139
				world.position = Vec2(0.5, 0.5) * size - position -- 140
				world.y = world.y + (h * 0.1) -- 141
				node.size = size -- 142
			end) -- 133
			local zoom = Director.currentCamera.zoom -- 143
			node.size = View.size * Vec2(1.0 / zoom, 1.0 / zoom) -- 144
			local h = node.size.height -- 145
			do -- 146
				local _with_0 = node:grab(20, 1) -- 146
				for x = 1, 21 do -- 147
					for y = 1, 2 do -- 148
						local pos = _with_0:getPos(x, y) -- 149
						_with_0:setPos(x, y, pos, math.sin(math.abs(x - 11) * math.pi / 200) * math.abs(x - 11) * h * 0.25) -- 150
					end -- 150
				end -- 150
			end -- 146
			node:gslot("AppSizeChanged", function() -- 151
				zoom = Director.currentCamera.zoom -- 152
				node.size = View.size * Vec2(1.0 / zoom, 1.0 / zoom) -- 153
				h = node.size.height -- 154
				node:grab(false) -- 155
				local _with_0 = node:grab(20, 1) -- 156
				for x = 1, 21 do -- 157
					for y = 1, 2 do -- 158
						local pos = _with_0:getPos(x, y) -- 159
						_with_0:setPos(x, y, pos, math.sin(math.abs(x - 11) * math.pi / 200) * math.abs(x - 11) * h * 0.25) -- 160
					end -- 160
				end -- 160
				return _with_0 -- 156
			end) -- 151
			world:moveToParent(node) -- 161
			return node -- 131
		end) -- 161
	end, -- 83
	loadAsync = function(_) -- 164
		return Cache:loadAsync("spine:loopTowerA") -- 164
	end -- 164
}) -- 44
return _module_0 -- 164
