-- [yue]: Script/Scene/Factory.yue
local Vec2 = Dora.Vec2 -- 1
local Spine = Dora.Spine -- 1
local Class = Dora.Class -- 1
local property = Dora.property -- 1
local Sprite = Dora.Sprite -- 1
local View = Dora.View -- 1
local math = _G.math -- 1
local _module_0 = Dora.Platformer -- 1
local PlatformWorld = _module_0.PlatformWorld -- 1
local Rect = Dora.Rect -- 1
local BodyDef = Dora.BodyDef -- 1
local Body = Dora.Body -- 1
local Data = _module_0.Data -- 1
local Cache = Dora.Cache -- 1
local _module_0 = nil -- 1
local W <const> = 11520 -- 3
local HW <const> = W / 2 -- 4
local H <const> = 1080 -- 5
local HH <const> = H / 2 -- 6
local Offset <const> = 130 -- 7
local PathOffset <const> = Vec2(50, -25) -- 8
local MaxPath <const> = 2 -- 9
local DefaultZoom <const> = 1.0 -- 10
local layerDefs = { -- 19
	{ -- 19
		look = "shadow", -- 19
		order = 100, -- 19
		ratio = Vec2(-0.2, 0) -- 19
	}, -- 19
	{ -- 20
		look = "front", -- 20
		order = 99, -- 20
		ratio = Vec2(-0.2, 0) -- 20
	}, -- 20
	{ -- 21
		look = "road", -- 21
		order = -100 -- 21
	}, -- 21
	{ -- 22
		look = "back1", -- 22
		order = -101, -- 22
		ratio = Vec2(0.8, 0) -- 22
	}, -- 22
	{ -- 23
		look = "back1.5", -- 23
		order = -102, -- 23
		ratio = Vec2(0.77, 0) -- 23
	}, -- 23
	{ -- 24
		look = "back2", -- 24
		order = -103, -- 24
		ratio = Vec2(0.72, 0), -- 24
		offset = Vec2(50, 0) -- 24
	}, -- 24
	{ -- 25
		look = "back4", -- 25
		order = -104, -- 25
		ratio = Vec2(0.78, 0) -- 25
	}, -- 25
	{ -- 26
		look = "back4.5", -- 26
		order = -105, -- 26
		ratio = Vec2(0.8, 0) -- 26
	}, -- 26
	{ -- 27
		look = "back3", -- 27
		order = -106, -- 27
		ratio = Vec2(0.76, 0) -- 27
	}, -- 27
	{ -- 28
		look = "back5", -- 28
		order = -107, -- 28
		ratio = Vec2(0.79, 0) -- 28
	}, -- 28
	{ -- 29
		look = "back5.5", -- 29
		order = -108, -- 29
		ratio = Vec2(0.8, 0) -- 29
	}, -- 29
	{ -- 30
		look = "back6", -- 30
		order = -109, -- 30
		ratio = Vec2(0.82, 0), -- 30
		offset = Vec2(-150, 0) -- 30
	}, -- 30
	{ -- 31
		look = "back7", -- 31
		order = -110, -- 31
		ratio = Vec2(0.84, 0) -- 31
	}, -- 31
	{ -- 32
		look = "back8", -- 32
		order = -111, -- 32
		ratio = Vec2(0.86, 0) -- 32
	}, -- 32
	{ -- 33
		look = "fog", -- 33
		order = -112, -- 33
		ratio = Vec2(0.88, 0) -- 33
	}, -- 33
	{ -- 34
		look = "back9", -- 34
		order = -113, -- 34
		ratio = Vec2(0.9, 0) -- 34
	} -- 34
} -- 18
local addLayer -- 36
addLayer = function(world, def) -- 36
	local layer -- 37
	do -- 37
		local _with_0 = Spine("factory") -- 37
		_with_0.look = def.look -- 38
		_with_0.order = def.order -- 39
		layer = _with_0 -- 37
	end -- 37
	if def.ratio then -- 40
		world:setLayerRatio(def.order, def.ratio) -- 41
	end -- 40
	if def.offset then -- 42
		world:setLayerOffset(def.order, def.offset) -- 43
	end -- 42
	world:addChild(layer) -- 44
	if def.handle then -- 45
		def.handle(layer) -- 45
	end -- 45
	return layer -- 46
end -- 36
_module_0 = Class({ -- 49
	width = property(function() -- 49
		return W -- 49
	end), -- 49
	offset = property(function() -- 50
		return Offset -- 50
	end), -- 50
	addShadowTo = function(self, unit) -- 52
		local _with_0 = Sprite("Image/shadow.png") -- 53
		_with_0.order = -1 -- 54
		_with_0:schedule(function() -- 55
			_with_0.y = self.offset - unit.y -- 55
		end) -- 55
		_with_0:addTo(unit) -- 56
		return _with_0 -- 53
	end, -- 52
	zoom = property(function(self) -- 58
		return self._zoom -- 58
	end, function(self, value) -- 59
		self._zoom = value -- 60
		return self:updateZoom() -- 61
	end), -- 58
	updateZoom = function(self) -- 63
		local scale = View.scale -- 64
		local width, height -- 65
		do -- 65
			local _obj_0 = View.size * Vec2(scale, scale) -- 65
			width, height = _obj_0.width, _obj_0.height -- 65
		end -- 65
		local zoom = self._zoom / DefaultZoom -- 66
		zoom = math.max(width / W / zoom, height / H / zoom) -- 67
		local realWidth = math.min(W / zoom, W) -- 68
		local realHeight = math.min(H / zoom, H) -- 69
		zoom = math.max(W / realWidth, H / realHeight) -- 70
		self.camera.zoom = zoom / scale -- 71
	end, -- 63
	__partial = function(_) -- 73
		local _with_0 = PlatformWorld() -- 74
		do -- 75
			local _with_1 = _with_0.camera -- 75
			_with_1.boundary = Rect(0, 0, W, H) -- 76
			_with_1.followRatio = Vec2(0.03, 0.03) -- 77
		end -- 75
		_with_0.tag = "Factory" -- 78
		return _with_0 -- 74
	end, -- 73
	__init = function(self) -- 80
		for i = -MaxPath, MaxPath do -- 81
			self:setLayerOffset(i, PathOffset * i) -- 82
		end -- 82
		for _index_0 = 1, #layerDefs do -- 84
			local def = layerDefs[_index_0] -- 84
			addLayer(self, def) -- 85
		end -- 85
		local terrainDef -- 87
		do -- 87
			local _with_0 = BodyDef() -- 87
			_with_0.type = "Static" -- 88
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 89
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 90
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 91
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 92
			_with_0.position = Vec2(0, Offset) -- 93
			terrainDef = _with_0 -- 87
		end -- 87
		do -- 95
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 95
			_with_0.group = Data.groupTerrain -- 96
			_with_0:addTo(self) -- 97
		end -- 95
		self._zoom = 1.0 -- 99
		self:gslot("AppSizeChanged", function() -- 100
			return self:updateZoom() -- 100
		end) -- 100
		return self:updateZoom() -- 101
	end, -- 80
	loadAsync = function(_) -- 103
		return Cache:loadAsync("spine:factory") -- 103
	end -- 103
}) -- 48
return _module_0 -- 103
