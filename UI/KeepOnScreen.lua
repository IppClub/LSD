-- Clamp horizontal screen bounds without changing world-space interaction ranges.
local D=require('Dora')
return function(node,targets)
 local tick=D.Node();tick:addTo(node)
 local correction=0;local authoredX,lastApplied;local serial=0;local pendingAt=-10
 -- Reuse the measurement table and callbacks across rounds instead of
 -- rebuilding the table and receive closure every ~3 frames.
 local points={};local remaining=0
 local function receive(batch,key,p)
  if batch~=serial or points[key] then return end
  points[key]=p;remaining=remaining-1
  if remaining~=0 then return end
  pendingAt=-10
  local slope=(points.axis.x-points.origin.x)/100/node.scaleX
  if math.abs(slope)<.001 then return end
  local left,right=math.huge,-math.huge
  for i=1,#targets*2 do left=math.min(left,points[i].x);right=math.max(right,points[i].x)end
  local width=D.App.visualSize.width;local margin=16
  -- Compare the authored position, so the adjustment also releases when the camera moves.
  left=left-correction*slope;right=right-correction*slope
  local shift=0
  if right-left>width-2*margin then shift=margin-left
  elseif left<margin then shift=margin-left elseif right>width-margin then shift=width-margin-right end
  local nextCorrection=shift/slope
  node.x=authoredX+nextCorrection;lastApplied=node.x;correction=node.x-authoredX
 end
 local function adapter(key)
  -- Projection callbacks run at render time and may outlive this batch when
  -- a target is hidden. Capture the generation for each request.
  local batch=serial
  return function(p)receive(batch,key,p)end
 end
 local AXIS=D.Vec2(100,0)
 tick:schedule(function()
  if not node.visible or node.opacity<.05 or not node.parent then return false end
  if D.App.frame-pendingAt<3 then return false end
  if not authoredX then authoredX=node.x elseif lastApplied and math.abs(node.x-lastApplied)>.01 then authoredX=authoredX+node.x-lastApplied end
  serial=serial+1;pendingAt=D.App.frame
  points['origin']=nil;points['axis']=nil
  for i=1,#targets*2 do points[i]=nil end
  remaining=#targets*2+2
  node:convertToWindowSpace(D.Vec2.zero,adapter('origin'))
  node:convertToWindowSpace(AXIS,adapter('axis'))
  for i,target in ipairs(targets)do
   target:convertToWindowSpace(D.Vec2.zero,adapter(i*2-1))
   target:convertToWindowSpace(D.Vec2(target.width,target.height),adapter(i*2))
  end
  return false
 end)
end
