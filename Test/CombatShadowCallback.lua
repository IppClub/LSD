local root='/Users/Jin/Workspace/Dora/LSD';package.path=root..'/Script/?.lua;'..package.path
local S=require('Combat.AimOcclusion');local original=S.build
local builds,rejects=0,0
S.build=function(...)builds=builds+1;local proof=original(...);if not proof then return nil end;return function(p)local value=proof(p);if value then rejects=rejects+1 end;return value end end
local old=dofile(root..'/Test/Fixtures/CombatShadowBefore/PartAim.lua');local new=dofile(root..'/Test/Fixtures/CombatShadowIntegrated/PartAim.lua')
local function circle(x,y,id)
 local v={};for i=1,40 do local a=i*math.pi/20;v[i]={x=x+math.cos(a),y=y+math.sin(a)}end
 return {id=id,vertices=v}
end
local function run(aim)
 local wall={id='wall',vertices={{x=5,y=-3},{x=5.2,y=-3},{x=5.2,y=3},{x=5,y=3}}}
 local parts={circle(10,0,'target'),circle(10,8,'target'),circle(10,0,'target'),wall}
 local calls={}
 local result,why=aim.solve({x=0,y=0},true,'target',parts,function(from,to)
  calls[#calls+1]={x=to.x,y=to.y};wall.enabled=false
  return to.y>2
 end)
 return {result=result,why=why,calls=calls}
end
local a,b=run(old),run(new)
assert(builds>0 and rejects>0,'fixture must exercise a proof before callback mutation')
assert(a.result and b.result and a.why==b.why and a.result.angle==b.result.angle and #a.calls==#b.calls)
for i,p in ipairs(a.calls)do assert(p.x==b.calls[i].x and p.y==b.calls[i].y)end
print('PASS active shadow invalidated after callback disables blocker; '..builds..' build, '..rejects..' rejections, '..#a.calls..' exact callback contacts')
