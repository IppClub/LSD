-- [yue]: Script/Scene/Train.yue
local Vec2 = Dora.Vec2 -- 1
local once = Dora.once -- 1
local cycle = Dora.cycle -- 1
local Spine = Dora.Spine -- 1
local Class = Dora.Class -- 1
local property = Dora.property -- 1
local Sprite = Dora.Sprite -- 1
local View = Dora.View -- 1
local math = _G.math -- 1
local Opacity = Dora.Opacity -- 1
local sleep = Dora.sleep -- 1
local _module_0 = Dora.Platformer -- 1
local PlatformWorld = _module_0.PlatformWorld -- 1
local Rect = Dora.Rect -- 1
local BodyDef = Dora.BodyDef -- 1
local Body = Dora.Body -- 1
local Data = _module_0.Data -- 1
local loop = Dora.loop -- 1
local Cache = Dora.Cache -- 1
local _module_0 = nil -- 1
local SceneScale <const> = 1.7 -- 3
local W <const> = 3840 / SceneScale -- 4
local HW <const> = W / 2 -- 5
local H <const> = 1080 / SceneScale -- 6
local HH <const> = H / 2 -- 7
local Offset <const> = 100 -- 8
local PathOffset <const> = Vec2(10, 10) -- 9
local MaxPath <const> = 2 -- 10
local layerDefs = { -- 19
	{ -- 19
		look = "front", -- 19
		order = 100, -- 19
		ratio = Vec2(-0.2, 0) -- 19
	}, -- 19
	{ -- 20
		look = "lightambient", -- 20
		order = 99, -- 20
		light = true -- 20
	}, -- 20
	{ -- 21
		look = "handrails", -- 21
		order = 98, -- 21
		ratio = Vec2(-0.05, 0), -- 21
		highSpeed = false -- 21
	}, -- 21
	{ -- 22
		look = "handrailshadow", -- 22
		order = 97, -- 22
		light = true, -- 22
		ratio = Vec2(-0.05, 0), -- 22
		highSpeed = false -- 22
	}, -- 22
	{ -- 23
		look = "seat1", -- 23
		order = -100, -- 23
		highSpeed = true -- 23
	}, -- 23
	{ -- 24
		look = "seat2", -- 24
		order = -100, -- 24
		highSpeed = false -- 24
	}, -- 24
	{ -- 25
		look = "lightwindow1", -- 25
		order = -101, -- 25
		light = true, -- 25
		highSpeed = false -- 25
	}, -- 25
	{ -- 26
		look = "lightwindow", -- 26
		order = -102, -- 26
		light = true, -- 26
		highSpeed = true -- 26
	}, -- 26
	{ -- 27
		look = "lightfloor", -- 27
		order = -103, -- 27
		light = true -- 27
	}, -- 27
	{ -- 28
		look = "floor", -- 28
		order = -104 -- 28
	}, -- 28
	{ -- 29
		look = "carriage", -- 29
		order = -105 -- 29
	}, -- 29
	{ -- 30
		look = "scenerylight", -- 30
		order = -106, -- 30
		light = true, -- 30
		handle = function(self, world) -- 30
			self:play("idle", true) -- 31
			world:slot("SpeedUp", function() -- 32
				return self:schedule(once(function() -- 33
					return cycle(10, function(dt) -- 33
						self.speed = dt * world.speed -- 33
					end) -- 33
				end)) -- 33
			end) -- 32
			world:slot("SpeedDown", function() -- 34
				return self:schedule(once(function() -- 35
					return cycle(10, function(dt) -- 35
						self.speed = (1.0 - dt) * world.speed -- 35
					end) -- 35
				end)) -- 35
			end) -- 34
			return self -- 30
		end -- 30
	}, -- 30
	{ -- 36
		look = "scenerydark", -- 36
		order = -107, -- 36
		handle = function(self, world) -- 36
			self:play("idle", true) -- 37
			world:slot("SpeedUp", function() -- 38
				return self:schedule(once(function() -- 39
					return cycle(10, function(dt) -- 39
						self.speed = dt * world.speed -- 39
					end) -- 39
				end)) -- 39
			end) -- 38
			world:slot("SpeedDown", function() -- 40
				return self:schedule(once(function() -- 41
					return cycle(10, function(dt) -- 41
						self.speed = (1.0 - dt) * world.speed -- 41
					end) -- 41
				end)) -- 41
			end) -- 40
			return self -- 36
		end -- 36
	} -- 36
} -- 18
local lightDefs -- 43
do -- 43
	local _accum_0 = { } -- 43
	local _len_0 = 1 -- 43
	for _index_0 = 1, #layerDefs do -- 43
		local def = layerDefs[_index_0] -- 43
		if def.light then -- 43
			_accum_0[_len_0] = def -- 43
			_len_0 = _len_0 + 1 -- 43
		end -- 43
	end -- 43
	lightDefs = _accum_0 -- 43
end -- 43
local darkDefs -- 44
do -- 44
	local _accum_0 = { } -- 44
	local _len_0 = 1 -- 44
	for _index_0 = 1, #layerDefs do -- 44
		local def = layerDefs[_index_0] -- 44
		if def.light ~= nil and def.light == false then -- 44
			_accum_0[_len_0] = def -- 44
			_len_0 = _len_0 + 1 -- 44
		end -- 44
	end -- 44
	darkDefs = _accum_0 -- 44
end -- 44
local addLayer -- 46
addLayer = function(world, def) -- 46
	local layer -- 47
	do -- 47
		local _with_0 = Spine("train") -- 47
		_with_0.scaleX = 1 / SceneScale -- 48
		_with_0.scaleY = 1 / SceneScale -- 49
		_with_0.look = def.look -- 50
		_with_0.order = def.order -- 51
		layer = _with_0 -- 47
	end -- 47
	if def.ratio then -- 52
		world:setLayerRatio(def.order, def.ratio) -- 53
	end -- 52
	world:addChild(layer) -- 54
	if def.handle then -- 55
		def.handle(layer, world) -- 55
	end -- 55
	return layer -- 56
end -- 46
_module_0 = Class({ -- 59
	width = property(function() -- 59
		return W -- 59
	end), -- 59
	offset = property(function() -- 60
		return Offset -- 60
	end), -- 60
	addShadowTo = function(self, unit) -- 62
		local _with_0 = Sprite("Image/shadow.png") -- 63
		_with_0.order = -1 -- 64
		_with_0:schedule(function() -- 65
			_with_0.y = self.offset - unit.y -- 65
		end) -- 65
		_with_0:addTo(unit) -- 66
		return _with_0 -- 63
	end, -- 62
	zoom = property(function(self) -- 68
		return self._zoom -- 68
	end, function(self, value) -- 69
		self._zoom = value -- 70
		return self:updateZoom() -- 71
	end), -- 68
	updateZoom = function(self) -- 73
		local width, height -- 74
		do -- 74
			local _obj_0 = View.size -- 74
			width, height = _obj_0.width, _obj_0.height -- 74
		end -- 74
		local zoom = self._zoom -- 75
		self.camera.zoom = math.max(height / H / zoom, width / W / zoom) -- 76
	end, -- 73
	isUnderground = property(function(self) -- 78
		return self._isUnderground -- 78
	end, function(self, value) -- 79
		self._isUnderground = value -- 80
		local showLayers = value and darkDefs or lightDefs -- 81
		local hideLayers = value and lightDefs or darkDefs -- 82
		for _index_0 = 1, #hideLayers do -- 83
			local def = hideLayers[_index_0] -- 83
			local layer = self:getLayer(def.order) -- 84
			layer:runAction(Opacity(0.5, 1, 0)) -- 85
			layer:schedule(once(function() -- 86
				sleep(0.5) -- 87
				layer.visible = false -- 88
			end)) -- 86
		end -- 88
		for _index_0 = 1, #showLayers do -- 89
			local def = showLayers[_index_0] -- 89
			local layer = self:getLayer(def.order) -- 90
			layer:runAction(Opacity(0.5, 0, 1)) -- 91
			layer.visible = true -- 92
		end -- 92
	end), -- 78
	__partial = function(_self) -- 94
		local _with_0 = PlatformWorld() -- 95
		local _with_1 = _with_0.camera -- 96
		_with_1.boundary = Rect(0, 0, W, H) -- 97
		_with_1.followRatio = Vec2(0.03, 0.03) -- 98
		return _with_0 -- 95
	end, -- 94
	__init = function(self, highSpeed) -- 100
		if highSpeed == nil then -- 100
			highSpeed = true -- 100
		end -- 100
		for i = -MaxPath, MaxPath do -- 101
			self:setLayerOffset(i, PathOffset * -i) -- 102
		end -- 102
		for _index_0 = 1, #layerDefs do -- 104
			local def = layerDefs[_index_0] -- 104
			if not (def.highSpeed ~= nil) or def.highSpeed == highSpeed then -- 105
				addLayer(self, def) -- 106
			end -- 105
		end -- 106
		local terrainDef -- 108
		do -- 108
			local _with_0 = BodyDef() -- 108
			_with_0.type = "Static" -- 109
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 110
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 111
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 112
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 113
			_with_0.position = Vec2(0, Offset) -- 114
			terrainDef = _with_0 -- 108
		end -- 108
		do -- 116
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 116
			_with_0.group = Data.groupTerrain -- 117
			_with_0:addTo(self) -- 118
		end -- 116
		self._zoom = 1.0 -- 120
		self:gslot("AppChange", function(settingName) -- 121
			if settingName == "Size" then -- 121
				return self:updateZoom() -- 121
			end -- 121
		end) -- 121
		self:updateZoom() -- 122
		self.speed = highSpeed and 2.0 or 1.0 -- 124
		self:emit("SpeedUp") -- 125
		return self:schedule(loop(function() -- 126
			sleep(math.random(5, 30)) -- 127
			self.isUnderground = not self.isUnderground -- 128
		end)) -- 128
	end, -- 100
	loadAsync = function(_self) -- 130
		return Cache:loadAsync("spine:train") -- 130
	end -- 130
}) -- 58
return _module_0 -- 130
