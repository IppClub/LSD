-- Continuous point contact for linearly interpolated polygon vertices.
-- Bone arcs within a frame and discontinuous pose changes need separate handling.
local G=require('Combat.HitGeometry')
local M={};local eps=1e-8
local function cross(x,y,u,v)return x*v-y*u end
local function roots(a,b,c)
 if math.abs(a)<eps then
  if math.abs(b)<eps then return {} end
  return {-c/b}
 end
 local d=b*b-4*a*c;if d<0 then return {}end
 local q=-.5*(b+(b>=0 and 1 or -1)*math.sqrt(d))
 if math.abs(q)<eps then return {-b/(2*a)}end
 return {q/a,c/q}
end
function M.segment(from,to,old,new)
 local dx,dy=to.x-from.x,to.y-from.y
 if G.contains(from,old)then
  local len=math.sqrt(dx*dx+dy*dy)
  return {t=0,position={x=from.x,y=from.y},normal={x=len>eps and -dx/len or 0,y=len>eps and -dy/len or 1},startedInside=true}
 end
 local best
 for i,a in ipairs(old)do
  local j=i%#old+1;local b=old[j];local na,nb=new[i],new[j]
  local avx,avy=na.x-a.x,na.y-a.y
  local ex,ey=b.x-a.x,b.y-a.y;local evx,evy=(nb.x-b.x)-avx,(nb.y-b.y)-avy
  local rx,ry=from.x-a.x,from.y-a.y;local vx,vy=dx-avx,dy-avy
  local qa=cross(vx,vy,evx,evy);local qb=cross(rx,ry,evx,evy)+cross(vx,vy,ex,ey);local qc=cross(rx,ry,ex,ey)
  local candidates=roots(qa,qb,qc)
  if math.abs(qa)<eps and math.abs(qb)<eps and math.abs(qc)<eps then
   -- Collinear motion enters through an endpoint, including a collapsing edge.
   for _,v in ipairs({{rx,ry,vx,vy},{rx-ex,ry-ey,vx-evx,vy-evy}})do
    local speed=v[3]*v[3]+v[4]*v[4]
    if speed>eps then candidates[#candidates+1]=-(v[1]*v[3]+v[2]*v[4])/speed end
   end
  end
  for _,t in ipairs(candidates)do
   if t>=-eps and t<=1+eps and (not best or t<best.t)then
    t=math.max(0,math.min(1,t))
    local tx,ty=rx+vx*t,ry+vy*t;local edgeX,edgeY=ex+evx*t,ey+evy*t
    local length2=edgeX*edgeX+edgeY*edgeY
    local u=length2>eps and (tx*edgeX+ty*edgeY)/length2 or 0
    if u>=-eps and u<=1+eps and (tx-u*edgeX)^2+(ty-u*edgeY)^2<=1e-10 then
     local length=math.sqrt(length2);local nx,ny=0,1
     if length>eps then nx,ny=-edgeY/length,edgeX/length end
     if nx*(vx-u*evx)+ny*(vy-u*evy)>0 then nx,ny=-nx,-ny end
     best={t=t,position={x=from.x+dx*t,y=from.y+dy*t},normal={x=nx,y=ny},startedInside=false}
    end
   end
  end
 end
 return best
end
function M.nearest(from,to,previous,current)
 local byId={};for _,p in ipairs(previous)do byId[p.geometryId or p.id]=p end
 local best;local minX,maxX=math.min(from.x,to.x),math.max(from.x,to.x);local minY,maxY=math.min(from.y,to.y),math.max(from.y,to.y)
 for _,part in ipairs(current)do
  local old=byId[part.geometryId or part.id]
  if part.enabled~=false and old and old.enabled~=false and #old.vertices==#part.vertices then
   local a,b=old.bounds,part.bounds
   local overlap=not a or not b or (maxX>=math.min(a.minX,b.minX)-eps and minX<=math.max(a.maxX,b.maxX)+eps and maxY>=math.min(a.minY,b.minY)-eps and minY<=math.max(a.maxY,b.maxY)+eps)
   if overlap then
    local h=M.segment(from,to,old.vertices,part.vertices)
    if h then
     h.part=part.id;h.priority=part.priority or 0
     if not best or h.t<best.t-eps or (math.abs(h.t-best.t)<=eps and (h.priority>best.priority or (h.priority==best.priority and h.part<best.part)))then best=h end
    end
   end
  end
 end
 return best
end
return M
