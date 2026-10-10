package.path='/Users/Jin/Workspace/Dora/LSD/Script/?.lua;'..package.path
local M=require('Combat.MovingHit');local G=require('Combat.HitGeometry')
local function box(x,y,w,h)return {{x=x,y=y},{x=x+w,y=y},{x=x+w,y=y+h},{x=x,y=y+h}}end
local function close(a,b)assert(math.abs(a-b)<1e-6,tostring(a)..' ~= '..tostring(b))end
local from,to={x=0,y=0},{x=10,y=0}
local old,new=box(4,2,2,2),box(4,-4,2,2)
assert(not G.segment(from,to,new))
local h=assert(M.segment(from,to,old,new));close(h.t,.4);close(h.position.x,4)
h=assert(M.segment({x=5,y=0},{x=5,y=0},old,new));close(h.t,1/3)
assert(not M.segment({x=20,y=0},{x=20,y=0},old,new))
-- Expanding edge and collinear sliding endpoint.
h=assert(M.segment({x=0,y=0},{x=0,y=0},box(2,-1,1,2),box(-2,-1,5,2)));close(h.t,.5)
h=assert(M.segment(from,to,box(4,0,2,2),box(4,0,2,2)));close(h.t,.4)
local n=0
for y=-2,12 do for x=-10,20 do
 local a,b={x=x,y=y},{x=x+40,y=y+.3};local shape=box(0,0,10,10)
 local g=G.segment(a,b,shape);local m=M.segment(a,b,shape,shape)
 assert((g~=nil)==(m~=nil));if g then close(g.t,m.t)end;n=n+1
end end
local p={id='a',vertices=old};local q={id='a',vertices=new}
assert(M.nearest(from,to,{p},{q}).part=='a')
print('PASS moving crossing, stationary projectile, miss, deformation, collinear, '..n..' static parity queries')
math.randomseed(91827)
for case=1,300 do
 local old=box(math.random(-20,20),math.random(-20,20),math.random(1,10),math.random(1,10))
 local new=box(math.random(-20,20),math.random(-20,20),math.random(1,10),math.random(1,10))
 local a,b={x=math.random(-20,20),y=math.random(-20,20)},{x=math.random(-20,20),y=math.random(-20,20)}
 local hit=M.segment(a,b,old,new);local first
 for tick=0,500 do
  local t=tick/500;local shape={}
  for i,v in ipairs(old)do shape[i]={x=v.x+(new[i].x-v.x)*t,y=v.y+(new[i].y-v.y)*t}end
  if G.contains({x=a.x+(b.x-a.x)*t,y=a.y+(b.y-a.y)*t},shape)then first=t;break end
 end
 if first then assert(hit and hit.t<=first+1e-7 and first-hit.t<=.002001,'Dense reference mismatch '..case)end
 if hit then
  local shape={};for i,v in ipairs(old)do shape[i]={x=v.x+(new[i].x-v.x)*hit.t,y=v.y+(new[i].y-v.y)*hit.t}end
  assert(G.contains(hit.position,shape),'Contact outside interpolated hull '..case)
 end
end
print('PASS 300 deterministic deforming trajectories against dense containment reference')

-- Disconnected pieces share armor IDs but must retain independent trajectories.
local a={id='roots',geometryId='a',vertices=box(4,2,2,2)}
local b={id='roots',geometryId='b',vertices=box(30,2,2,2)}
local c={id='roots',geometryId='a',vertices=box(4,-4,2,2)}
local d={id='roots',geometryId='b',vertices=box(30,2,2,2)}
local hit=assert(M.nearest(from,to,{a,b},{c,d}));close(hit.t,.4);assert(hit.part=='roots')
assert(not M.nearest(from,to,{a,b},{a,b}))
print('PASS compound armor identity preserves per-piece motion')
