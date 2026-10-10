-- Frame-only timing: no wrapped geometry calls, slow-ray capture or per-frame IO.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/combat-training-performance-result.json';local r={status='RUNNING',profiles={}}
local profileOnly=select(2,...);assert(profileOnly==nil or profileOnly=='near' or profileOnly=='field')
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/combat-training-performance-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local saved=assert(require('Training.FlowerQStore').loadAsync())
  for _,profile in ipairs(profileOnly and {profileOnly} or {'near','field'})do
   local frames={}
   local run=require('Training.FlowerQSession').runAsync({mode='evaluate',profile=profile,models=saved.source.baseModels,initial=saved.models,onStart=function(b)
    local warm=D.App.totalTime+2;local n=D.Node();n:addTo(b.arena.world)
    n:schedule(function(dt)if b.phase=='playing' and D.App.totalTime>warm then frames[#frames+1]=dt end;return false end)
   end})
   local rebuilt,why=require('Training.FlowerTraceReview').rebuild(run.trace,run.episode,run.status);assert(rebuilt,why)
   local telemetry=require('Training.FlowerQTelemetry').build(run)
   assert(require('Training.FlowerIdentity').equal(run.models,saved.models),'Evaluation changed candidate')
   local skipped=0;for _,id in ipairs({'ninilite','wuyun'})do
    skipped=skipped+(run.decisions[id].skipped or 0)
    assert(run.decisions[id].accepted==#run.trace.actors[id].steps,'Skipped polling lost an accepted action')
   end
   assert(skipped>0,'No unavailable polling exercised')
   table.sort(frames);assert(#frames>60)
   local sum,slow=0,0;for _,dt in ipairs(frames)do sum=sum+dt;if dt>1/30 then slow=slow+1 end end
   r.profiles[#r.profiles+1]={profile=profile,naturalStatus=run.status,telemetry=telemetry,skipped=skipped,traceRebuilt=true,candidateUnchanged=true,
    performance={frames=#frames,mean=sum/#frames,p95=frames[math.ceil(#frames*.95)],p99=frames[math.ceil(#frames*.99)],max=frames[#frames],over33ms=slow}}
   save();D.sleep(.5)
  end
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
