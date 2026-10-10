-- Real journey battle profiling; fault injection affects result preparation only.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/optimization-performance-result.json';local r={status='RUNNING',osInput=false,scope='current-source-factory-battle',timings={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
local function profile(module,key)
 local m=require(module);local original=assert(m[key]);local t={calls=0,seconds=0,max=0};r.timings[module..'.'..key]=t
 m[key]=function(...)
  local at=D.App.elapsedTime;local result=table.pack(original(...));local dt=D.App.elapsedTime-at
  t.calls=t.calls+1;t.seconds=t.seconds+dt;t.max=math.max(t.max,dt);return table.unpack(result,1,result.n)
 end
end
for _,v in ipairs({{'Factory.Battle','update'},{'Combat.SpineRegions','sample'},{'Combat.PartAim','solve'},{'Factory.PartCombat','contact'}})do profile(v[1],v[2])end
local E=require('Training.FlowerEvaluation');local build=E.build;local attempts=0
E.build=function(...)attempts=attempts+1;if attempts==1 then error('QA_TRANSIENT_RESULT_PREPARATION')end;return build(...)end
local frames={};local start;local sampling=true
-- A scene switch replaces Director.entry; keep the sampler on the engine thread.
D.thread(function()
 while sampling do
  local world=D.Platformer.Data.store.world;local b=world and world.factoryBattle and world.factoryBattle.battle
  if b and b.phase=='playing' then start=start or D.App.runningTime;if D.App.runningTime-start>2 then frames[#frames+1]=D.App.deltaTime end end
  D.sleep(0)
 end
end)
local journeyPath=root..'/Test/FreshMaterialsCurrentNative.lua'
assert(load(D.Content:load(journeyPath),'@'..journeyPath))(root..'/Test/FreshMaterialsCurrentNative')
D.thread(function()
 local ok,err=xpcall(function()
  local deadline=D.App.runningTime+220;local journey
  repeat D.sleep(.2);assert(D.App.runningTime<deadline,'Profile journey stalled');journey=D.json.decode(D.Content:load(root..'/Test/fresh-materials-current-result.json'),32)until journey.status~='RUNNING'
  assert(journey.status=='PASS',journey.error);assert(attempts==2,'Preparation retry did not recompute exactly once')
  r.journey=journey;r.database=journey.database;r.preparationFailureRecovered=true;r.evaluationAttempts=attempts
  assert(#frames>100,'Insufficient real battle frames');table.sort(frames);local sum,over33,over50=0,0,0
  for _,dt in ipairs(frames)do sum=sum+dt;if dt>1/30 then over33=over33+1 end;if dt>.05 then over50=over50+1 end end
  r.performance={frames=#frames,seconds=sum,mean=sum/#frames,p95=frames[math.ceil(#frames*.95)],p99=frames[math.ceil(#frames*.99)],max=frames[#frames],over33ms=over33,over50ms=over50,warmupSeconds=2}
  r.performance.accepted=r.performance.p95<=1/30 and over50/#frames<.01
  sampling=false
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
