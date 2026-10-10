package.path='/Users/Jin/Workspace/Dora/LSD/Script/?.lua;'..package.path
local A=require('Enemy.ThrowArc')
for _,dx in ipairs({-900,-400,0,400,900})do for _,dy in ipairs({-200,0,200})do
 local s=A.solve({x=100,y=300},{x=100+dx,y=300+dy})
 assert(s.time>=.55 and s.time<=1.1)
 assert(math.abs(s.vx*s.time-dx)<1e-6)
 assert(math.abs(s.vy*s.time-.5*s.gravity*s.time*s.time-dy)<1e-6)
 local t=s.time/2;assert(s.vy*t-.5*s.gravity*t*t>dy/2)
end end
print('PASS left/right/vertical targets, elevation changes, bounded flight time and above-chord arc')
