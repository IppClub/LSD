-- Same native process across legal checkpoint branches. No HP, funds, unlock,
-- learned-model or win injection. Scripted inputs do not prove OS/manual QA.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/full-game-reference-probe-result.json'
local ReferenceProbe=(function()
-- External QA diagnostic, not production code. Do not load into the live soak.
-- Registry indices are verified against bundled Lua 5.5 and tolua headers:
-- LUA_RIDX_LAST=3; TOLUA_REG_INDEX_UBOX=4; TOLUA_REG_INDEX_CALLBACK=5.
local D=require('Dora');local Probe={}
function Probe.capture()
 local result={objects=D.Object.count,luaRefs=D.Object.luaRefCount,callRefs=D.Object.callRefCount,objectTypes={},callbacks={},routineSources={},roots={},scope='Diagnostic metadata only; bounded upvalue traversal does not enumerate every owner. Temporary Lua wrappers created by observation are not retained in this report.'}
 local registry=debug.getregistry();local box=assert(registry[4]);local callbacks=assert(registry[5]);assert(getmetatable(box).__mode=='v'and type(callbacks)=='table','Unexpected runtime registry layout')
 local types={};local objectCount=0
 local function describe(value)
  local mt=getmetatable(value);return type(mt)=='table'and mt.__name or'userdata'
 end
 for _,value in pairs(box)do if type(value)=='userdata'then local name=describe(value);types[name]=(types[name]or 0)+1;objectCount=objectCount+1 end end
 result.objectTypes=types;result.boxObjectCount=objectCount
 local function source(fn)
  local info=debug.getinfo(fn,'Slu');return info and {source=info.source,firstLine=info.linedefined,lastLine=info.lastlinedefined,what=info.what,upvalues=info.nups}or{}
 end
 for id,fn in pairs(callbacks)do
  if type(fn)=='function'or type(fn)=='thread'then
   local item={ref=id,kind=type(fn),userdataUpvalues={}};local seen={}
   local function scan(value,path,depth)
    if type(value)=='userdata'then item.userdataUpvalues[#item.userdataUpvalues+1]={path=path,type=describe(value)}
    elseif type(value)=='table'and depth<2 and not seen[value]then
     seen[value]=true;local count=0
     for key,child in pairs(value)do count=count+1;if count>24 then item.truncated=true;break end
      local label=type(key)=='string'and key:match('^[%a_][%w_]*$')and key or'entry'..count
      scan(child,path..'.'..label,depth+1)
     end
    end
   end
   if type(fn)=='function'then
    item.info=source(fn);local i=1
    while true do local name,value=debug.getupvalue(fn,i);if not name then break end
     if name~='_ENV'and name~='D'and name~='P'and name~='_G'and name~='package'then scan(value,name,0)end;i=i+1
    end
   else
    item.status=coroutine.status(fn);local info=debug.getinfo(fn,1,'Sl');if info then item.info={source=info.source,line=info.currentline}end
   end
   result.callbacks[#result.callbacks+1]=item
  end
 end
 table.sort(result.callbacks,function(a,b)return a.ref<b.ref end);result.callbackTableCount=#result.callbacks
 for i,routine in ipairs(D.Routine)do
  if type(routine)=='thread'then local info=debug.getinfo(routine,1,'Sl');result.routineSources[#result.routineSources+1]={index=i,status=coroutine.status(routine),source=info and info.source,line=info and info.currentline}end
 end
 for name,node in pairs({entry=D.Director.entry,ui=D.Director.ui,ui3D=D.Director.ui3D,postNode=D.Director.postNode})do
  local children={};if node.children then node.children:each(function(child)children[#children+1]={tag=child.tag,type=describe(child)}end)end
  result.roots[name]=children
 end
 return result
end
return Probe

end)()
local diagnosticCycles=2
local requested=0
assert(requested==0 or requested>=1800 and requested<=3600,'Invalid soak duration')
local r={status='RUNNING',osInput=false,fullGameComplete=false,targetSeconds=requested,mode=requested==0 and'smoke'or'long-soak',cycles={},stages={},checkpointBranches=true,injectsCombatState=false}
local clearRootCleanup=os.getenv('LSD_QA_SOAK_PRESERVE_ROOT_CLEANUP')~='1'
r.qaRootCleanupReset=clearRootCleanup;r.cleanupMeasurements={}
r.mode='reference-probe';r.targetCycles=diagnosticCycles;r.referenceSnapshots={}
local started=D.App.totalTime;local realGetenv=os.getenv;local parentResult
local function save()r.elapsed=D.App.totalTime-started;r.heartbeat=D.App.totalTime;D.Content:save(out,D.json.encode(r,false,true))end;save()
local bins={};local count,sum,max,over33=0,0,0,0;local slow={};local scenes={};local weakScenes=setmetatable({},{__mode='v'});local sceneSerial=0;local previousWorld
local sampler=D.Node();sampler:addTo(D.Director.ui)
sampler:schedule(function(dt)
 count=count+1;sum=sum+dt;max=math.max(max,dt);local key=math.min(600000,math.ceil(dt*10000));bins[key]=(bins[key]or 0)+1
 local world=D.Platformer.Data.store.world
 if world~=previousWorld then
  previousWorld=world
  if world then sceneSerial=sceneSerial+1;weakScenes[sceneSerial]=world;local tag=world.tag or'untagged';scenes[tag]=(scenes[tag]or 0)+1 end
 end
 if dt>1/30 then over33=over33+1;if #slow<100 then slow[#slow+1]={dt=dt,at=D.App.totalTime-started,stage=r.stage,scene=world and world.tag}end end
 return false
end)
local function frameSummary()
 local keys={};for k in pairs(bins)do keys[#keys+1]=k end;table.sort(keys)
 local n,p95,p99=0,nil,nil
 for _,k in ipairs(keys)do n=n+bins[k];if not p95 and n>=count*.95 then p95=k/10000 end;if not p99 and n>=count*.99 then p99=k/10000 end end
 return {count=count,mean=count>0 and sum/count or 0,max=max,p95=p95,p99=p99,over33ms=over33,slowFrames=slow}
end
D.thread(function()
 local ok,why=xpcall(function()
  local base=realGetenv('LSD_QA_SOAK_BASE')or'/private/tmp/lsd-wave-warning-full-journey-20261008'
  local trainParent=base..'/fresh-train-current/result.json';local commandParent=base..'/fresh-command-current/result.json'
  for _,path in ipairs({trainParent,commandParent})do
   local prior=D.json.decode(assert(D.Content:load(path)),32);assert(prior.status=='PASS'and prior.sameJourney and D.Content:exist(prior.database),'Missing earned checkpoint')
  end
  r.parentResults={trainParent,commandParent}
  -- Route only the child test's parent-result lookup; gameplay code is unchanged.
  os.getenv=function(name)if name=='LSD_QA_PARENT_RESULT'then return parentResult end;return realGetenv(name)end
  local function clearScene()
   local E=require('Economy.Store');if D.DB:existDB('lsd')then assert(not E.active(),'Cannot reload an active supply attempt')end
   D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear();previousWorld=nil
   D.sleep(.6)
   if D.DB:existDB('lsd')then assert(D.DB:exec('DETACH DATABASE lsd')>=0)end
   -- Only this QA re-executes Start/child entry scripts on a permanent root.
   -- Their shutdown handlers otherwise accumulate although the scene and DB
   -- have already been explicitly disposed. Record the immediate native counts
   -- on both sides; do not count a diagnostic reset as a production leak fix.
   local cleanup={stage=r.stage,cycle=r.currentCycle,at=D.App.totalTime-started,callRefsBefore=D.Object.callRefCount,luaRefsBefore=D.Object.luaRefCount,objectsBefore=D.Object.count,reset=clearRootCleanup}
   if clearRootCleanup then D.Director.entry:slot('Cleanup'):clear()end
   cleanup.callRefsAfter=D.Object.callRefCount;cleanup.luaRefsAfter=D.Object.luaRefCount;cleanup.objectsAfter=D.Object.count
   r.cleanupMeasurements[#r.cleanupMeasurements+1]=cleanup
   -- Start is an entry script. Re-execute it for the next earned checkpoint.
   package.loaded.Start=nil
   collectgarbage('collect');D.sleep(.1)
  end
  local function child(name,resultName,parent,cycle)
   parentResult=parent;r.stage=name;r.phase='checkpoint-resume';save()
   if D.DB:existDB('lsd')then clearScene()end
   local path=root..'/Test/'..name..'.lua';local resultPath=root..'/Test/'..resultName
   local source=assert(D.Content:load(path));D.Content:save(D.Content.writablePath..'/child-'..cycle..'-'..name..'.lua',source)
   D.Content:save(resultPath,D.json.encode({status='RUNNING',soakCycle=cycle},false,true))
   local began=D.App.totalTime
   assert(load(source,'@'..path))(root..'/Test/'..name)
   local deadline=began+900;local lastHeartbeat=0;local result
   repeat
    assert(D.App.totalTime<deadline,'Child stage stalled: '..name)
    D.sleep(.1)
    if D.App.totalTime-lastHeartbeat>=1 then
     lastHeartbeat=D.App.totalTime;local raw=D.Content:load(resultPath);local decoded,data=pcall(D.json.decode,raw or'',32)
     if decoded then result=data;r.childPhase=data.stage or data.phase;r.phase='playing-branch'end
     save()
    end
   until result and (result.status=='PASS'or result.status=='FAIL')
   local archived=D.Content.writablePath..'/cycle-'..cycle..'-'..resultName;assert(D.Content:save(archived,D.json.encode(result,false,true)))
   assert(result.status=='PASS','Child failed: '..name..': '..tostring(result.error))
   assert(result.sameJourney,'Child did not preserve a legal journey')
   local E=require('Economy.Store');assert(not E.active(),'Unclosed supply attempt')
   r.stages[#r.stages+1]={cycle=cycle,test=name,seconds=D.App.totalTime-began,result=archived,database=result.database,source=result.source,balance=result.balance or result.balanceAfter}
   save();return archived,result
  end
  local cycle=0
  repeat
   cycle=cycle+1;r.currentCycle=cycle;local cycleStart=D.App.totalTime
   child('FreshGroundCurrentNative','fresh-ground-current-result.json',trainParent,cycle)
   local factoryResult=child('FreshFactoryCurrentNative','fresh-factory-current-result.json',commandParent,cycle)
   local chapterResult=child('FreshChapterThreeCurrentNative','fresh-chapter-three-current-result.json',factoryResult,cycle)
   child('FreshEndingCurrentNative','fresh-ending-current-result.json',chapterResult,cycle)
   clearScene();previousWorld=nil;collectgarbage('collect');D.sleep(.3);collectgarbage('collect')
   local retained=0;for _ in pairs(weakScenes)do retained=retained+1 end
   r.cycles[#r.cycles+1]={index=cycle,seconds=D.App.totalTime-cycleStart,elapsed=D.App.totalTime-started,objects=D.Object.count,luaRefs=D.Object.luaRefCount,callRefs=D.Object.callRefCount,luaKB=collectgarbage('count'),retainedSceneWorlds=retained}
   r.referenceSnapshots[#r.referenceSnapshots+1]={cycle=cycle,at=D.App.totalTime-started,probe=ReferenceProbe.capture()}
   r.completedCycles=cycle;r.frames=frameSummary();r.sceneEntries=scenes;save()
  until cycle>=diagnosticCycles
  assert(requested==0 or D.App.totalTime-started>=1800,'Long soak did not reach 30 minutes')
  r.status='PASS';r.phase='complete';r.sameNativeProcess=true;r.memoryTrendNeedsReview=true;r.fullGameComplete=false
 end,debug.traceback)
 os.getenv=realGetenv;sampler:removeFromParent();r.frames=frameSummary();r.sceneEntries=scenes
 if not ok then r.status='FAIL';r.error=why end;save()
end)
