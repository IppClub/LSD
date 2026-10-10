local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/combat-stutter-profile-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/combat-stutter-profile-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.FlowerQStore');local saved=assert(Store.loadAsync())
  local timings={};local frames={};local poses={}
  for _,entry in ipairs({{'Combat.SpineRegions','sample'},{'Combat.HitGeometry','distance'},{'Combat.PartAim','solve'},{'Training.FlowerFeatures','capture'},{'Training.FlowerDecisionTrace','options'},{'Factory.Battle','update'},{'Factory.PartCombat','contact'}})do
   local m=require(entry[1]);local f=m[entry[2]];local t={calls=0,seconds=0,max=0};timings[table.concat(entry,'.')]=t
   m[entry[2]]=function(...)local start=D.App.elapsedTime;local a,b,c=f(...);local dt=D.App.elapsedTime-start;t.calls=t.calls+1;t.seconds=t.seconds+dt;t.max=math.max(t.max,dt);return a,b,c end
  end
  local slowAims={};local Aim=require('Combat.PartAim');local solve=Aim.solve
  Aim.solve=function(origin,facing,part,regions,blocked)
   local calls={};local start=D.App.elapsedTime
   local value,reason=solve(origin,facing,part,regions,function(from,to)
    local result=blocked(from,to)
    calls[#calls+1]={from={x=from.x,y=from.y},to={x=to.x,y=to.y},blocked=not not result}
    return result
   end)
   local elapsed=D.App.elapsedTime-start
   if #slowAims<12 or elapsed>slowAims[#slowAims].seconds then
    slowAims[#slowAims+1]={seconds=elapsed,origin={x=origin.x,y=origin.y},facing=facing,part=part,regions=regions,terrain=calls,result=value,reason=reason}
    table.sort(slowAims,function(a,b)return a.seconds>b.seconds end)
    if #slowAims>12 then slowAims[13]=nil end
   end
   return value,reason
  end
  local run=require('Training.FlowerQSession').runAsync({mode='evaluate',profile='near',models=saved.source.baseModels,initial=saved.models,onProgress=function(b)if #poses<12 then b.partCombat:sample();poses[#poses+1]={regions=b.partCombat.target.regions,origin={x=b.arena.student.x+65,y=b.arena.student.y-20},facing=true}end end,onStart=function(b)
   local warm=D.App.totalTime+2;local n=D.Node();n:addTo(b.arena.world);n:schedule(function(dt)if b.phase=='playing' and D.App.totalTime>warm then frames[#frames+1]=dt end;return false end)
  end})
  D.Content:save(root..'/Test/combat-slow-aims.json',D.json.encode(slowAims,false,true))
  local rebuilt,why=require('Training.FlowerTraceReview').rebuild(run.trace,run.episode,run.status);assert(rebuilt,why);r.traceRebuilt=true
  r.telemetry=require('Training.FlowerQTelemetry').build(run)
  assert(require('Training.FlowerIdentity').equal(run.models,saved.models),'Evaluation changed candidate');r.candidateUnchanged=true
  table.sort(frames);local sum,slow=0,0;for _,dt in ipairs(frames)do sum=sum+dt;if dt>1/30 then slow=slow+1 end end
  r.performance={frames=#frames,mean=sum/#frames,p95=frames[math.ceil(#frames*.95)],p99=frames[math.ceil(#frames*.99)],max=frames[#frames],over33ms=slow,timings=timings};r.naturalStatus=run.status;D.Content:save(root..'/Test/combat-stutter-poses.json',D.json.encode(poses,false,true))

 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
