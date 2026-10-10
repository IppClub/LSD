local G=dofile('Script/Combat/HitGeometry.lua')
local box={id='body',vertices={{x=0,y=0},{x=10,y=0},{x=10,y=10},{x=0,y=10}}}
local h=G.distance({x=15,y=5},{box});assert(h.distance==5 and h.position.x==10 and h.position.y==5)
h=G.distance({x=13,y=14},{box});assert(h.distance==5 and h.position.x==10 and h.position.y==10)
h=G.distance({x=5,y=5},{box});assert(h.distance==0 and h.inside)
assert(G.distance({x=10,y=5},{box}).distance==0)
box.enabled=false;assert(not G.distance({x=5,y=5},{box}));box.enabled=true
local concave={id='limb',vertices={{x=0,y=0},{x=10,y=0},{x=10,y=3},{x=3,y=3},{x=3,y=10},{x=0,y=10}}}
h=G.distance({x=6,y=6},{concave});assert(h.distance==3 and not h.inside,'Concavity treated as solid bounding box')
local remote={id='other',vertices={{x=20,y=0},{x=30,y=0},{x=30,y=10},{x=20,y=10}}}
h=G.distance({x=18,y=5},{box,remote});assert(h.part=='other' and h.distance==2)
-- Large outlines exercise the containment index, including degenerate edges
-- and epsilon-wide horizontal boundaries at several coordinate scales.
local old=dofile('Test/Fixtures/CombatStutterBefore/HitGeometry.lua')
for _,scale in ipairs({1e-5,1,1e6})do
 local vs={};for i=1,64 do local a=i*math.pi/32;vs[i]={x=math.cos(a)*scale,y=math.sin(a)*scale}end
 vs[65]=vs[64]
 local parts={{id='first',vertices=vs},{id='tie',vertices=vs}}
 for _,v in ipairs(vs)do for _,offset in ipairs({-1e-8,0,1e-8})do
  local point={x=v.x,y=v.y+offset}
  assert(G.contains(point,vs)==old.contains(point,vs),'Indexed containment boundary mismatch')
  local before,after=old.distance(point,parts),G.distance(point,parts)
  assert(before.distance==after.distance and before.part==after.part and before.inside==after.inside,'Distance boundary/tie mismatch')
 end end
end
-- Repeated rays and an in-place edited origin must never retain stale inside.
local origin={x=5,y=5};local endpoint={x=40,y=7}
for _,x in ipairs({5,5,18,18,5,-10,18})do
 origin.x=x
 local a,b=old.segment(origin,endpoint,box.vertices),G.segment(origin,endpoint,box.vertices)
 assert((a~=nil)==(b~=nil),'Origin cache presence')
 if a then assert(a.t==b.t and a.startedInside==b.startedInside,'Origin cache invalidation')end
end
print('SPATIAL_GEOMETRY_PASS edges=true corners=true concavity=true disabled=true nearestPart=true')
