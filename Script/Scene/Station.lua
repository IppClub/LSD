-- [yue]: Script/Scene/Station.yue
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
local Offset <const> = 100 -- 7
local PathOffset <const> = Vec2(50, -25) -- 8
local MaxPath <const> = 2 -- 9
local DefaultZoom <const> = 1.0 -- 10
local layerDefs = { -- 19
	{ -- 19
		look = "frontUp", -- 19
		order = 100, -- 19
		ratio = Vec2(-0.2, 0) -- 19
	}, -- 19
	{ -- 20
		look = "frontDown", -- 20
		order = 99, -- 20
		ratio = Vec2(-0.2, 0) -- 20
	}, -- 20
	{ -- 21
		look = "floor", -- 21
		order = -100 -- 21
	}, -- 21
	{ -- 22
		look = "car", -- 22
		order = -101, -- 22
		ratio = Vec2(0.2, 0) -- 22
	}, -- 22
	{ -- 23
		look = "light", -- 23
		order = -102, -- 23
		ratio = Vec2(0.4, 0) -- 23
	}, -- 23
	{ -- 24
		look = "back1", -- 24
		order = -103, -- 24
		ratio = Vec2(0.4, 0) -- 24
	}, -- 24
	{ -- 25
		look = "back2", -- 25
		order = -104, -- 25
		ratio = Vec2(0.6, 0) -- 25
	} -- 25
} -- 18
local addLayer -- 27
addLayer = function(world, def) -- 27
	local layer -- 28
	do -- 28
		local _with_0 = Spine("station") -- 28
		_with_0.look = def.look -- 29
		_with_0.order = def.order -- 30
		layer = _with_0 -- 28
	end -- 28
	if def.ratio then -- 31
		world:setLayerRatio(def.order, def.ratio) -- 32
	end -- 31
	if def.offset then -- 33
		world:setLayerOffset(def.order, def.offset) -- 34
	end -- 33
	world:addChild(layer) -- 35
	if def.handle then -- 36
		def.handle(layer) -- 36
	end -- 36
	return layer -- 37
end -- 27
_module_0 = Class({ -- 40
	width = property(function() -- 40
		return W -- 40
	end), -- 40
	offset = property(function() -- 41
		return Offset -- 41
	end), -- 41
	addShadowTo = function(self, unit) -- 43
		local _with_0 = Sprite("Image/shadow.png") -- 44
		_with_0.order = -1 -- 45
		_with_0:schedule(function() -- 46
			_with_0.y = self.offset - unit.y -- 46
		end) -- 46
		_with_0:addTo(unit) -- 47
		return _with_0 -- 44
	end, -- 43
	zoom = property(function(self) -- 49
		return self._zoom -- 49
	end, function(self, value) -- 50
		self._zoom = value -- 51
		return self:updateZoom() -- 52
	end), -- 49
	updateZoom = function(self) -- 54
		local scale = View.scale -- 55
		local width, height -- 56
		do -- 56
			local _obj_0 = View.size * Vec2(scale, scale) -- 56
			width, height = _obj_0.width, _obj_0.height -- 56
		end -- 56
		local zoom = self._zoom / DefaultZoom -- 57
		zoom = math.max(width / W / zoom, height / H / zoom) -- 58
		local realWidth = math.min(W / zoom, W) -- 59
		local realHeight = math.min(H / zoom, H) -- 60
		zoom = math.max(W / realWidth, H / realHeight) -- 61
		self.camera.zoom = zoom / scale -- 62
	end, -- 54
	__partial = function(_self) -- 64
		local _with_0 = PlatformWorld() -- 65
		do -- 66
			local _with_1 = _with_0.camera -- 66
			_with_1.boundary = Rect(0, 0, W, H) -- 67
			_with_1.followRatio = Vec2(0.03, 0.03) -- 68
		end -- 66
		_with_0.tag = "Station" -- 69
		return _with_0 -- 65
	end, -- 64
	__init = function(self) -- 71
		for i = -MaxPath, MaxPath do -- 72
			self:setLayerOffset(i, PathOffset * i) -- 73
		end -- 73
		for _index_0 = 1, #layerDefs do -- 75
			local def = layerDefs[_index_0] -- 75
			addLayer(self, def) -- 76
		end -- 76
		local terrainDef -- 78
		do -- 78
			local _with_0 = BodyDef() -- 78
			_with_0.type = "Static" -- 79
			_with_0:attachPolygon(Vec2(HW, 0), W, 10, 0, 1, 1, 0) -- 80
			_with_0:attachPolygon(Vec2(HW, H), W, 10, 0, 1, 1, 0) -- 81
			_with_0:attachPolygon(Vec2(0, HH), 10, H, 0, 1, 1, 0) -- 82
			_with_0:attachPolygon(Vec2(W, HH), 10, H, 0, 1, 1, 0) -- 83
			_with_0.position = Vec2(0, Offset) -- 84
			terrainDef = _with_0 -- 78
		end -- 78
		do -- 86
			local _with_0 = Body(terrainDef, self, Vec2.zero) -- 86
			_with_0.group = Data.groupTerrain -- 87
			_with_0:addTo(self) -- 88
		end -- 86
		self._zoom = 1.0 -- 90
		self:gslot("AppChange", function(settingName) -- 91
			if settingName == "Size" then -- 91
				return self:updateZoom() -- 91
			end -- 91
		end) -- 91
		return self:updateZoom() -- 92
	end, -- 71
	loadAsync = function(_self) -- 94
		return Cache:loadAsync("spine:station") -- 94
	end -- 94
}) -- 39
return _module_0 -- 94
