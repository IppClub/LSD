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
	targetNode:slot( -- 14
		"StopStrip", -- 14
		function() -- 14
			target = nil -- 15
		end -- 14
	) -- 14
	local stopPoint = target.position -- 17
	local current = 0 -- 18
	local step = 10 -- 19
	local stepTime = 0.02 -- 20
	local targetColor = Color(color) -- 21
	local startOpacity = targetColor.opacity -- 22
	local verts = {Vec2.zero, Vec2.zero, Vec2.zero, Vec2.zero} -- 23
	node:schedule(function(deltaTime) -- 29
		node:clear() -- 30
		if target then -- 30
			stopPoint = target.position -- 32
		end -- 32
		local distance = math.min( -- 34
			1000, -- 34
			stopPoint:distance(startPoint) -- 34
		) -- 34
		local angle = stopPoint:sub(startPoint).angle -- 35
		node.angle = -angle + 90 -- 36
		local i = 0 -- 37
		local ended = true -- 38
		do -- 38
			local dist = 0 -- 39
			while dist < distance do -- 39
				local start = step * i -- 40
				local stop = math.min(start + step, distance) -- 41
				local duration = (i + 1) * stepTime -- 42
				if current < duration then -- 42
					ended = false -- 44
				end -- 44
				local alpha = 1 - current / duration -- 46
				if alpha > 0 then -- 46
					targetColor.opacity = alpha * startOpacity -- 48
					verts[1] = Vec2(-step / 2, start) -- 49
					verts[2] = Vec2(-step / 2, stop) -- 50
					verts[3] = Vec2(step / 2, stop) -- 51
					verts[4] = Vec2(step / 2, start) -- 52
					node:drawPolygon(verts, targetColor) -- 53
				end -- 53
				i = i + 1 -- 55
				dist = dist + step -- 39
			end -- 39
		end -- 39
		if ended then -- 39
			node:clear() -- 58
			node:removeFromParent() -- 59
			return true -- 60
		end -- 60
		current = current + deltaTime -- 62
		return false -- 63
	end) -- 29
end -- 4
return ____exports -- 4