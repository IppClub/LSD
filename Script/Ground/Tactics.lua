-- Coordinate rules for the authored cover / wind-fire encounter.
local T={columns={5570,5770,6120},coverRadius=90,windRange=700}
function T.covered(x,source)
 for _,pillar in ipairs(T.columns) do
  if math.abs(x-pillar)<=T.coverRadius and (pillar-x)*(source-x)>0 and math.abs(source-x)>math.abs(pillar-x) then return true,pillar end
 end
 return false
end
function T.inWind(x,y,originX,originY,direction)
 local forward=(x-originX)*direction
 return forward>=0 and forward<=T.windRange and math.abs(y-originY)<=110+forward*0.2
end
function T.aligned(vx,direction) return vx*direction>0 end
function T.rewardMultiplier(report)
 return type(report)=="table" and (report.synergyHits or 0)>0 and (report.coverBlocks or 0)>0 and 2 or 1
end
return T
