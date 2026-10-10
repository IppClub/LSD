local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/combat-frame-profile-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/combat-stutter-profile-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.FlowerQStore');local saved=assert(Store.loadAsync())
  local timings={};local frames={};local poses={}
  for _,entry in ipairs({{'Combat.SpineRegions','sample'},{'Combat.HitGeometry','distance'},{'Combat.PartAim','solve'},{'Training.FlowerFeatures','capture'},{'Training.FlowerDecisionTrace','options'},{'Factory.Battle','update'},{'Factory.PartCombat','contact'},{'Factory.PartCombat','aimBlocked'},{'Combat.HitGeometry','nearest'},{'Combat.HitGeometry','contains'}})do
   local m=require(entry[1]);local f=m[entry[2]];local t={calls=0,seconds=0,max=0};timings[table.concat(entry,'.')]=t
   m[entry[2]]=function(...)local start=D.App.elapsedTime;local a,b,c=f(...);local dt=D.App.elapsedTime-start;t.calls=t.calls+1;t.seconds=t.seconds+dt;t.max=math.max(t.max,dt);return a,b,c end
  end
  local run=require('Training.FlowerQSession').runAsync({mode='evaluate',profile='near',models=saved.source.baseModels,initial=saved.models,onStart=function(b)
   local warm=D.App.totalTime+2;local n=D.Node();n:addTo(b.arena.world);n:schedule(function(dt)if b.phase=='playing' and D.App.totalTime>warm then frames[#frames+1]=dt end;return false end)
  end})
  local rebuilt,why=require('Training.FlowerTraceReview').rebuild(run.trace,run.episode,run.status);assert(rebuilt,why);r.traceRebuilt=true
  r.telemetry=require('Training.FlowerQTelemetry').build(run)
  assert(require('Training.FlowerIdentity').equal(run.models,saved.models),'Evaluation changed candidate');r.candidateUnchanged=true
  table.sort(frames);local sum,slow=0,0;for _,dt in ipairs(frames)do sum=sum+dt;if dt>1/30 then slow=slow+1 end end
  r.performance={frames=#frames,mean=sum/#frames,p95=frames[math.ceil(#frames*.95)],p99=frames[math.ceil(#frames*.99)],max=frames[#frames],over33ms=slow,timings=timings};r.naturalStatus=run.status

 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
