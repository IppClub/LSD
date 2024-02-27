-- [yue]: Script/Scene/FrozenCity.yue
local Vec2 = dora.Vec2 -- 1
local Spine = dora.Spine -- 1
local Class = dora.Class -- 1
local property = dora.property -- 1
local Sprite = dora.Sprite -- 1
local View = dora.View -- 1
local math = _G.math -- 1
local _module_0 = dora.Platformer -- 1
local PlatformWorld = _module_0.PlatformWorld -- 1
local Rect = dora.Rect -- 1
local BodyDef = dora.BodyDef -- 1
local Body = dora.Body -- 1
local Data = _module_0.Data -- 1
local Cache = dora.Cache -- 1
local _module_0 = nil -- 1
local W <const> = 11520 -- 3
local HW <const> = W / 2 -- 4
local H <const> = 1080 -- 5
local HH <const> = H / 2 -- 6
local Offset <const> = 100 -- 7
local PathOffset <const> = Vec2(50, 30) -- 8
local MaxPath <const> = 2 -- 9
local DefaultZoom <const> = 1.0 -- 10
local layerDefs = { -- 19
	{ -- 19
		look = "snow", -- 19
		order = 100, -- 19
		ratio = Vec2(1, 0), -- 19
		handle = function(self) -- 19
			self:play("idle", true) -- 20
			return self -- 19
		end -- 19
	}, -- 19
	{ -- 21
		look = "front", -- 21
		order = 99, -- 21
		ratio = Vec2(-0.2, 0) -- 21
	}, -- 21
	{ -- 22
		look = "road", -- 22
		order = -100 -- 22
	}, -- 22
	{ -- 23
		look = "fog", -- 23
		order = -101, -- 23
		ratio = Vec2(0.8, 0), -- 23
		handle = function(self) -- 23
			self:play("idle", true) -- 24
			return self -- 23
		end -- 23
	}, -- 23
	{ -- 25
		look = "back0", -- 25
		order = -102, -- 25
		ratio = Vec2(0.72, 0), -- 25
		handle = function(self) -- 25
			self:play("idle", true) -- 26
			return self -- 25
		end -- 25
	}, -- 25
	{ -- 27
		look = "back1", -- 27
		order = -103, -- 27
		ratio = Vec2(0.74, 0) -- 27
	}, -- 27
	{ -- 28
		look = "back2", -- 28
		order = -104, -- 28
		ratio = Vec2(0.76, 0) -- 28
	}, -- 28
	{ -- 29
		look = "back3", -- 29
		order = -105, -- 29
		ratio = Vec2(0.78, 0) -- 29
	}, -- 29
	{ -- 30
		look = "back4", -- 30
		order = -106, -- 30
		ratio = Vec2(0.8, 0) -- 30
	}, -- 30
	{ -- 31
		look = "back5", -- 31
		order = -107, -- 31
		ratio = Vec2(0.82, 0) -- 31
	}, -- 31
	{ -- 32
		look = "back6", -- 32
		order = -108, -- 32
		ratio = Vec2(0.84, 0) -- 32
	}, -- 32
	{ -- 33
		look = "back7", -- 33
		order = -109, -- 33
		ratio = Vec2(0.86, 0) -- 33
	}, -- 33
	{ -- 34
		look = "back8", -- 34
		order = -110, -- 34
		ratio = Vec2(0.9, 0) -- 34
	}, -- 34
	{ -- 35
		look = "back9", -- 35
		order = -111, -- 35
		ratio = Vec2(0.92, 0) -- 35
	}, -- 35
	{ -- 36
		look = "cloud", -- 36
		order = -112, -- 36
		ratio = Vec2(0.9, 0), -- 36
		handle = function(self) -- 36
			self:play("idle", true) -- 37
			return self -- 36
		end -- 36
	}, -- 36
	{ -- 38
		look = "sky", -- 38
		order = -113, -- 38
		ratio = Vec2(1, 0) -- 38
	} -- 38
} -- 18
local addLayer -- 40
addLayer = function(world, def) -- 40
	local layer -- 41
	do -- 41
		local _with_0 = Spine("frozenCity") -- 41
		_with_0.look = def.look -- 42
		_with_0.order = def.order -- 43
		layer = _with_0 -- 41
	end -- 41
	if def.ratio then -- 44
		world:setLayerRatio(def.order, def.ratio) -- 45
	end -- 44
	if def.offset then -- 46
		world:setLayerOffset(def.order, def.offset) -- 47
	end -- 46
	world:addChild(layer) -- 48
	if def.handle then -- 49
		def.handle(layer) -- 49
	end -- 49
	return layer -- 50
end -- 40
_module_0 = Class({ -- 53
	width = property(function() -- 53
		return W -- 53
	end), -- 53
	offset = property(function() -- 54
		return Offset -- 54
	end), -- 54
	addShadowTo = function(self, unit) -- 56
		local _with_0 = Sprite("Image/shadow.png") -- 57
		_with_0.order = -1 -- 58
		_with_0:schedule(function() -- 59
			_with_0.y = self.offset - unit.y -- 59
		end) -- 59
		_with_0:addTo(unit) -- 60
		return _with_0 -- 57
	end, -- 56
	zoom = property(function(self) -- 62
		return self._zoom -- 62
	end, function(self, value) -- 63
		self._zoom = value -- 64
		return self:updateZoom() -- 65
	end), -- 62
	updateZoom = function(self) -- 67
		local scale = View.scale -- 68
		local width, height -- 69
		do -- 69
			local _obj_0 = View.size * Vec2(scale, scale) -- 69
			width, height = _obj_0.width, _obj_0.height -- 69
		end -- 69
		local zoom = self._zoom / DefaultZoom -- 70
		zoom = math.max(width / W / zoom, height / H / zoom) -- 71
		local realWidth = math.min(W / zoom, W) -- 72
		local realHeight = math.min(H / zoom, H) -- 73
		zoom = math.max(W / realWidth, H / realHeight) -- 74
		self.camera.zoom = zoom / scale -- 75
	end, -- 67
	__partial = function(_) -- 77
		local _with_0 = PlatformWorld() -- 78
		do -- 79
			local _with_1 = _with_0.camera -- 79
			_with_1.boundary = Rect(0, 0, W, H) -- 80
			_with_1.followRatio = Vec2(0.03, 0.03) -- 81
		end -- 79
		_with_0.tag = "FrozenCity" -- 82
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
		local terrainDef -- 91
		do -- 91
			local _with_0 = BodyDef() -- 91
			_with_0.type = "Static" -- 92
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 93
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 94
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 95
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 96
			_with_0.position = Vec2(0, Offset) -- 97
			terrainDef = _with_0 -- 91
		end -- 91
		do -- 99
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 99
			_with_0.group = Data.groupTerrain -- 100
			_with_0:addTo(self) -- 101
		end -- 99
		self._zoom = 1.0 -- 103
		self:gslot("AppSizeChanged", function() -- 104
			return self:updateZoom() -- 104
		end) -- 104
		return self:updateZoom() -- 105
	end, -- 84
	loadAsync = function(_) -- 107
		return Cache:loadAsync("spine:frozenCity") -- 107
	end -- 107
}) -- 52
return _module_0 -- 107
