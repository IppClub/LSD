-- Relative sweep of authored actor body rectangles during an active rush.
local R={}
function R.hit(previous,current,halfWidth,halfHeight,faceRight)
 local direction=faceRight and 1 or -1
 if previous.x*direction < -halfWidth then return false end
 local enter,leave=0,1
 for _,axis in ipairs({'x','y'})do
  local limit=axis=='x' and halfWidth or halfHeight
  local p=previous[axis];local delta=current[axis]-p
  if math.abs(delta)<1e-8 then if math.abs(p)>limit then return false end
  else
   local a,b=(-limit-p)/delta,(limit-p)/delta;if a>b then a,b=b,a end
   enter=math.max(enter,a);leave=math.min(leave,b);if enter>leave then return false end
  end
 end
 return true,enter
end
return R
