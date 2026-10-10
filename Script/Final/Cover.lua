-- Side-scrolling cover checks the impact segment against the panel's height.
local Cover={}
function Cover.intersection(x,base,sourceX,sourceY,targetX,targetY)
 if math.abs(targetX-x)>120 or (sourceX-x)*(targetX-x)>=0 then return false end
 local u=(x-sourceX)/(targetX-sourceX);local y=sourceY+(targetY-sourceY)*u
 return y>=base and y<=base+260,y
end
return Cover
