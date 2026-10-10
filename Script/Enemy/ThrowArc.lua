-- Lock a target at release; gravity supplies the arc, without homing afterward.
local A={gravity=800}
function A.solve(from,to)
 local dx,dy=to.x-from.x,to.y-from.y
 local time=math.min(1.1,.55+math.abs(dx)/1600)
 return {vx=dx/time,vy=dy/time+.5*A.gravity*time,time=time,gravity=A.gravity}
end
return A
