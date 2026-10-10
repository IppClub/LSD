local G=dofile('/Users/Jin/Workspace/Dora/LSD/Script/Combat/HitGeometry.lua')
local function box(id,x,y,w,h)return {id=id,vertices={{x=x,y=y},{x=x+w,y=y},{x=x+w,y=y+h},{x=x,y=y+h}}}end
local a,b={x=-100,y=5},{x=100,y=5}
local front,back=box('front',0,0,10,10),box('back',20,0,10,10)
local h=assert(G.nearest(a,b,{back,front}));assert(h.part=='front' and math.abs(h.position.x)<1e-6 and h.normal.x==-1)
assert(G.nearest(b,a,{front,back}).part=='back')
assert(not G.nearest({x=-100,y=11},{x=100,y=11},{front,back}))
local vertical=assert(G.nearest({x=5,y=100},{x=5,y=-100},{front}));assert(vertical.position.y==10 and vertical.normal.y==1)
local inside=assert(G.nearest({x=5,y=5},b,{front}));assert(inside.t==0 and inside.startedInside)
local grazing=assert(G.nearest({x=-10,y=10},{x=20,y=10},{front}));assert(grazing.position.x==0)
local tied=box('cover',0,0,10,10);tied.priority=1
assert(G.nearest(a,b,{front,tied}).part=='cover');assert(G.nearest(a,b,{tied,front}).part=='cover')
tied.enabled=false;assert(G.nearest(a,b,{tied,front}).part=='front')
-- Mirrored, translated and non-uniformly scaled world geometry is supplied by host.
local moved=box('head',40,20,20,5)
assert(G.nearest({x=100,y=22},{x=-100,y=22},{moved}).position.x==60)
assert(not G.segment(a,a,front.vertices))
print('PASS first contact independent of order, reversed path, miss, vertical, inside, grazing, overlap priority, transformed region')

-- Reuse the very same pose and mutable point through different muzzles.
local origin={x=-10,y=5};local endpoint={x=20,y=5}
assert(G.segment(origin,endpoint,front.vertices).position.x==0)
origin.x=20;endpoint.x=-10
assert(G.segment(origin,endpoint,front.vertices).position.x==10)
origin.x=5;origin.y=20;endpoint.x=5;endpoint.y=-10
assert(G.segment(origin,endpoint,front.vertices).position.y==10)
origin.x=-10;origin.y=5;endpoint.x=20;endpoint.y=5
assert(G.segment(origin,endpoint,front.vertices).position.x==0)
print('PASS changed and restored mutable muzzle coordinates on one pose')
