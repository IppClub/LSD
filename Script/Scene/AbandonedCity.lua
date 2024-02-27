-- [yue]: Script/Scene/AbandonedCity.yue
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
local Offset <const> = 230 -- 7
local PathOffset <const> = Vec2(50, -25) -- 8
local MaxPath <const> = 2 -- 9
local DefaultZoom <const> = 1.0 -- 10
local layerDefs = { -- 19
	{ -- 19
		look = "front", -- 19
		order = 100, -- 19
		ratio = Vec2(-0.2, 0) -- 19
	}, -- 19
	{ -- 20
		look = "road", -- 20
		order = -100 -- 20
	}, -- 20
	{ -- 21
		look = "back1", -- 21
		order = -101, -- 21
		ratio = Vec2(0.7, 0) -- 21
	}, -- 21
	{ -- 22
		look = "back2", -- 22
		order = -102, -- 22
		ratio = Vec2(0.76, 0), -- 22
		handle = function(self) -- 22
			self:play("idle", true) -- 23
			return self -- 22
		end -- 22
	}, -- 22
	{ -- 24
		look = "back3", -- 24
		order = -103, -- 24
		ratio = Vec2(0.73, 0) -- 24
	}, -- 24
	{ -- 25
		look = "back4", -- 25
		order = -104, -- 25
		ratio = Vec2(0.76, 0) -- 25
	}, -- 25
	{ -- 26
		look = "back5", -- 26
		order = -105, -- 26
		ratio = Vec2(0.80, 0) -- 26
	}, -- 26
	{ -- 27
		look = "back6c1", -- 27
		order = -106, -- 27
		ratio = Vec2(0.8, 0), -- 27
		handle = function(self) -- 27
			self:play("cloud1", true) -- 28
			return self -- 27
		end -- 27
	}, -- 27
	{ -- 29
		look = "back6c2", -- 29
		order = -107, -- 29
		ratio = Vec2(0.82, 0), -- 29
		handle = function(self) -- 29
			self:play("cloud2", true) -- 30
			return self -- 29
		end -- 29
	}, -- 29
	{ -- 31
		look = "back7", -- 31
		order = -108, -- 31
		ratio = Vec2(0.84, 0) -- 31
	}, -- 31
	{ -- 32
		look = "back8c", -- 32
		order = -109, -- 32
		ratio = Vec2(0.86, 0), -- 32
		handle = function(self) -- 32
			self:play("cloud3", true) -- 33
			return self -- 32
		end -- 32
	}, -- 32
	{ -- 34
		look = "bk", -- 34
		order = -110, -- 34
		ratio = Vec2(1, 0) -- 34
	} -- 34
} -- 18
local addLayer -- 36
addLayer = function(world, def) -- 36
	local layer -- 37
	do -- 37
		local _with_0 = Spine("abandonedCity") -- 37
		_with_0.look = def.look -- 38
		_with_0.order = def.order -- 39
		layer = _with_0 -- 37
	end -- 37
	if def.ratio then -- 40
		world:setLayerRatio(def.order, def.ratio) -- 41
	end -- 40
	world:addChild(layer) -- 42
	if def.handle then -- 43
		def.handle(layer) -- 43
	end -- 43
	return layer -- 44
end -- 36
_module_0 = Class({ -- 47
	width = property(function() -- 47
		return W -- 47
	end), -- 47
	offset = property(function() -- 48
		return Offset -- 48
	end), -- 48
	addShadowTo = function(self, unit) -- 50
		local _with_0 = Sprite("Image/shadow.png") -- 51
		_with_0.order = -1 -- 52
		_with_0:schedule(function() -- 53
			_with_0.y = self.offset - unit.y -- 53
		end) -- 53
		_with_0:addTo(unit) -- 54
		return _with_0 -- 51
	end, -- 50
	zoom = property(function(self) -- 56
		return self._zoom -- 56
	end, function(self, value) -- 57
		self._zoom = value -- 58
		return self:updateZoom() -- 59
	end), -- 56
	updateZoom = function(self) -- 61
		local scale = View.scale -- 62
		local width, height -- 63
		do -- 63
			local _obj_0 = View.size * Vec2(scale, scale) -- 63
			width, height = _obj_0.width, _obj_0.height -- 63
		end -- 63
		local zoom = self._zoom / DefaultZoom -- 64
		zoom = math.max(width / W / zoom, height / H / zoom) -- 65
		local realWidth = math.min(W / zoom, W) -- 66
		local realHeight = math.min(H / zoom, H) -- 67
		zoom = math.max(W / realWidth, H / realHeight) -- 68
		self.camera.zoom = zoom / scale -- 69
	end, -- 61
	__partial = function(_) -- 71
		local _with_0 = PlatformWorld() -- 72
		do -- 73
			local _with_1 = _with_0.camera -- 73
			_with_1.boundary = Rect(0, 0, W, H) -- 74
			_with_1.followRatio = Vec2(0.03, 0.03) -- 75
		end -- 73
		_with_0.tag = "AbandonedCity" -- 76
		return _with_0 -- 72
	end, -- 71
	__init = function(self) -- 78
		for i = -MaxPath, MaxPath do -- 79
			self:setLayerOffset(i, PathOffset * i) -- 80
		end -- 80
		for _index_0 = 1, #layerDefs do -- 82
			local def = layerDefs[_index_0] -- 82
			addLayer(self, def) -- 83
		end -- 83
		local terrainDef -- 85
		do -- 85
			local _with_0 = BodyDef() -- 85
			_with_0.type = "Static" -- 86
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 87
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 88
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 89
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 90
			_with_0.position = Vec2(0, Offset) -- 91
			terrainDef = _with_0 -- 85
		end -- 85
		do -- 93
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 93
			_with_0.group = Data.groupTerrain -- 94
			_with_0:addTo(self) -- 95
		end -- 93
		self._zoom = 1.0 -- 97
		self:gslot("AppSizeChanged", function() -- 98
			return self:updateZoom() -- 98
		end) -- 98
		return self:updateZoom() -- 99
	end, -- 78
	loadAsync = function(_) -- 101
		return Cache:loadAsync("spine:abandonedCity") -- 101
	end -- 101
}) -- 46
return _module_0 -- 101
