package.path='/Users/Jin/Workspace/Dora/LSD/Script/?.lua;'..package.path
local A=require('Combat.PartAim')
local function box(id,x,y)return {id=id,vertices={{x=x,y=y},{x=x+20,y=y},{x=x+20,y=y+20},{x=x,y=y+20}}}end
local origin={x=0,y=0};local head=box('head',100,40)
local r=assert(A.solve(origin,true,'head',{head},function()return false end));assert(r.angle<0 and r.angle>=-45)
assert(not A.solve(origin,false,'head',{head},function()return false end))
assert(not A.solve(origin,true,'head',{head},function()return true end))
assert(not A.solve(origin,true,'head',{head,box('front',40,10)},function()return false end))
assert(not A.solve(origin,true,'head',{box('head',10,100)},function()return false end))
local left=assert(A.solve(origin,false,'head',{box('head',-120,40)},function()return false end));assert(left.angle<0)
assert(not A.solve(origin,true,'missing',{head},function()return false end))
assert(not A.solve({x=105,y=45},true,'head',{head},function()return false end))
assert(not A.solve(origin,true,'head',{box('head',2500,0)},function()return false end))
assert(require('Combat.FirearmRules').travel==require('Combat.FirearmRules').speed*require('Combat.FirearmRules').lifeTime)
print('PASS left/right constrained aim, terrain and part occlusion, reach, unknown part, inside-muzzle rejection')

-- Interior preference remains a constrained ray, including fallback when the
-- center is terrain-blocked; ordinary five-argument ordering stays unchanged.
local centered=assert(A.solve(origin,true,'head',{head},function()return false end,true))
assert(centered.point.x==110 and centered.point.y==50)
local mirrored=assert(A.solve(origin,false,'head',{box('head',-120,40)},function()return false end,true))
assert(mirrored.point.x==-110 and mirrored.point.y==50 and mirrored.angle==centered.angle)
local fallback=assert(A.solve(origin,true,'head',{head},function(from,to)return math.abs(to.y/to.x-50/110)<1e-8 end,true))
assert(fallback.point.x~=110 or fallback.point.y~=50)
assert(not A.solve(origin,true,'head',{head},function()return true end,true))
assert(not A.solve(origin,true,'head',{head,box('front',40,10)},function()return false end,true))
print('PASS optional interior aim, mirrored geometry, terrain fallback and body occlusion')
