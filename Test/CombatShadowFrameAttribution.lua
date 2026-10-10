local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/combat-shadow-frame-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/combat-stutter-profile-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local Store=require('Training.FlowerQStore');local saved=assert(Store.loadAsync())
  package.loaded['Combat.PartAim']=assert(load(D.Content:load(root..'/Test/Fixtures/CombatShadowIntegrated/PartAim.lua')))()
  local timings={};local frames={};local rows={}
  local function row()
   local f=D.App.frame;local v=rows[f]
   if not v then v={frame=f,dt=D.App.deltaTime,costs={},calls={},luaKB=collectgarbage('count')};rows[f]=v end
   return v
  end
  for _,entry in ipairs({{'Combat.AimOcclusion','build'},{'Combat.SpineRegions','sample'},{'Combat.PartAim','solve'},{'Training.FlowerFeatures','capture'},{'Training.FlowerDecisionTrace','options'},{'Factory.Battle','update'},{'Factory.PartCombat','contact'}})do
   local m=require(entry[1]);local fn=m[entry[2]];local name=table.concat(entry,'.');local total={calls=0,seconds=0,max=0};timings[name]=total
   m[entry[2]]=function(...)
    local v=row();local start=D.App.runningTime;local a,b,c=fn(...);local dt=D.App.runningTime-start
    v.costs[name]=(v.costs[name]or 0)+dt;v.calls[name]=(v.calls[name]or 0)+1
    total.calls=total.calls+1;total.seconds=total.seconds+dt;total.max=math.max(total.max,dt)
    return a,b,c
   end
  end
  local run=require('Training.FlowerQSession').runAsync({mode='evaluate',profile='field',models=saved.source.baseModels,initial=saved.models,onStart=function(b)
   local warm=D.App.totalTime+2;local n=D.Node();n:addTo(b.arena.world);n:schedule(function(dt)if b.phase=='playing' and D.App.totalTime>warm then frames[#frames+1]=dt;local v=row();v.sampledElapsed=D.App.elapsedTime;v.playing=true end;return false end)
  end})
  local rebuilt,why=require('Training.FlowerTraceReview').rebuild(run.trace,run.episode,run.status);assert(rebuilt,why);r.traceRebuilt=true
  r.telemetry=require('Training.FlowerQTelemetry').build(run)
  assert(require('Training.FlowerIdentity').equal(run.models,saved.models),'Evaluation changed candidate');r.candidateUnchanged=true
  local ranked={};for _,v in pairs(rows)do if v.playing then ranked[#ranked+1]=v end end
  table.sort(ranked,function(a,b)return a.dt>b.dt end);r.slowFrames={}
  for i=1,math.min(12,#ranked)do local v=ranked[i];r.slowFrames[i]={previous=rows[v.frame-1],current=v,following=rows[v.frame+1]}end
  table.sort(frames);local sum,slow=0,0;for _,dt in ipairs(frames)do sum=sum+dt;if dt>1/30 then slow=slow+1 end end
  r.performance={frames=#frames,mean=sum/#frames,p95=frames[math.ceil(#frames*.95)],p99=frames[math.ceil(#frames*.99)],max=frames[#frames],over33ms=slow,timings=timings};r.naturalStatus=run.status

 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
