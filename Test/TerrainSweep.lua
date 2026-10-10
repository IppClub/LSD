package.path='/Users/Jin/Workspace/Dora/LSD/Script/?.lua;'..package.path
package.preload.Dora=function()return {Vec2=function(x,y)return {x=x,y=y}end,Platformer={Data={groupTerrain=1}}}end
local T=require('Combat.TerrainSweep')
local a,b={x=0,y=0},{x=100,y=0};local part={t=.5}
local function world(hits)return {raycast=function(_,_,_,closest,callback)
 assert(not closest)
 for _,h in ipairs(hits)do assert(callback({group=h.group or 1},{x=h.x,y=0})==false)end
end}end
assert(T.first(world({{x=90},{x=10}}),a,b,part)==nil)
assert(T.first(world({{x=10},{x=90}}),a,b,part)==nil)
assert(T.first(world({{x=90}}),a,b,part)==part)
assert(T.first(world({{x=50}}),a,b,part)==nil)
assert(T.first(world({{x=10,group=2}}),a,b,part)==part)
local hit,blocked=T.first(world({{x=10}}),a,b,nil);assert(not hit and blocked)
assert(T.first(world({}),a,a,part)==part)
print('PASS unordered terrain contacts, before/behind, equal-contact terrain priority, nonterrain ignored, no part, zero distance')
