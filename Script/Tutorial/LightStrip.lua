-- [ts]: LightStrip.ts
local ____exports = {} -- 1
local ____Dora = require("Dora") -- 2
local Color = ____Dora.Color -- 2
local DrawNode = ____Dora.DrawNode -- 2
local Vec2 = ____Dora.Vec2 -- 2
function ____exports.LightStrip(startPoint, targetNode, color) -- 4
	local node = DrawNode() -- 5
	node.position = startPoint -- 6
	if targetNode.parent then -- 6
		node:addTo(targetNode.parent, targetNode.order) -- 8
	end -- 8
	local target = targetNode -- 10
	targetNode:slot( -- 11
		"Cleanup", -- 11
		function() -- 11
			target = nil -- 12
		end -- 11
	) -- 11
	local stopPoint = target.position -- 14
	local current = 0 -- 15
	local step = 10 -- 16
	local stepTime = 0.02 -- 17
	local targetColor = Color(color) -- 18
	local verts = {Vec2.zero, Vec2.zero, Vec2.zero, Vec2.zero} -- 19
	node:schedule(function(deltaTime) -- 25
		node:clear() -- 26
		if target then -- 26
			stopPoint = target.position -- 28
		end -- 28
		local distance = math.min( -- 30
			1000, -- 30
			stopPoint:distance(startPoint) -- 30
		) -- 30
		local angle = stopPoint:sub(startPoint).angle -- 31
		node.angle = -math.deg(angle) + 90 -- 32
		local i = 0 -- 33
		local ended = true -- 34
		do -- 34
			local dist = 0 -- 35
			while dist < distance do -- 35
				local start = step * i -- 36
				local stop = math.min(start + step, distance) -- 37
				local duration = (i + 1) * stepTime -- 38
				if current < duration then -- 38
					ended = false -- 40
				end -- 40
				local alpha = 1 - current / duration -- 42
				if alpha > 0 then -- 42
					targetColor.opacity = alpha -- 44
					verts[1] = Vec2(-step / 2, start) -- 45
					verts[2] = Vec2(-step / 2, stop) -- 46
					verts[3] = Vec2(step / 2, stop) -- 47
					verts[4] = Vec2(step / 2, start) -- 48
					node:drawPolygon(verts, targetColor) -- 49
				end -- 49
				i = i + 1 -- 51
				dist = dist + step -- 35
			end -- 35
		end -- 35
		if ended then -- 35
			node:clear() -- 54
			node:removeFromParent() -- 55
			return true -- 56
		end -- 56
		current = current + deltaTime -- 58
		return false -- 59
	end) -- 25
end -- 4
return ____exports -- 4