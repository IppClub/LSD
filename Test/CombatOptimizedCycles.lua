-- Frame-only timing: no wrapped geometry calls, slow-ray capture or per-frame IO.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/combat-optimized-cycles-result.json';local r={status='RUNNING',profiles={}}
local weak=setmetatable({},{__mode='v'});r.cycles=6;r.memory={}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/combat-training-performance-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local saved=assert(require('Training.FlowerQStore').loadAsync())
  for cycle,profile in ipairs({'near','field','near','field','near','field'})do
   local frames={}
   local run=require('Training.FlowerQSession').runAsync({mode='evaluate',profile=profile,models=saved.source.baseModels,initial=saved.models,onStart=function(b)
    weak[cycle]=b;local warm=D.App.totalTime+2;local n=D.Node();n:addTo(b.arena.world)
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
   run=nil;frames=nil;rebuilt=nil;telemetry=nil
   D.sleep(.5);collectgarbage('collect');D.sleep(.2);collectgarbage('collect')
   local retained,old=0,0
   for index,b in pairs(weak)do if b then retained=retained+1;if index<cycle then old=old+1 end end end
   r.memory[cycle]={objects=D.Object.count,luaRefs=D.Object.luaRefCount,callRefs=D.Object.callRefCount,luaKB=collectgarbage('count'),retainedBattles=retained,retainedOlderBattles=old}
   if old>0 then
    local target=weak[1];local seen={};local found={};local visited=0
    local function scan(value,path,depth)
     if value==target then found[#found+1]=path;return end
     if seen[value] or depth>5 or visited>150000 then return end
     local kind=type(value);if kind~='table' and kind~='function'then return end
     seen[value]=true;visited=visited+1
     if kind=='function'then
      local info=debug.getinfo(value,'S');local source=info and (info.short_src..':'..info.linedefined)or '?'
      for i=1,100 do local name,v=debug.getupvalue(value,i);if not name then break end
       if name~='_ENV'then scan(v,path..' -> '..source..' up:'..name,depth+1)end
      end
     else
      local mt=getmetatable(value);local mode=type(mt)=='table'and rawget(mt,'__mode')or ''
      if not mode:find('v')then for k,v in pairs(value)do scan(v,path..'['..tostring(k)..']',depth+1)end end
     end
    end
    scan(debug.getregistry(),'registry',0);r.retainerPaths=found;r.retainerVisited=visited
   end
   save();assert(old==0,'Prior closed battles retained across cycles')
  end
  local final=assert(require('Training.FlowerQStore').loadAsync())
  assert(require('Training.FlowerIdentity').equal(final.models,saved.models),'Repeated evaluation changed stored candidate')
  r.storedCandidateUnchanged=true;r.resourceTrendNeedsReview=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
