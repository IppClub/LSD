-- Same native process across legal checkpoint branches. No HP, funds, unlock,
-- learned-model or win injection. Scripted inputs do not prove OS/manual QA.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/full-game-soak-result.json'
local requested=tonumber(os.getenv('LSD_QA_FULL_GAME_SOAK_SECONDS')or'1800')
assert(requested==0 or requested>=1800 and requested<=3600,'Invalid soak duration')
local r={status='RUNNING',osInput=false,fullGameComplete=false,targetSeconds=requested,mode=requested==0 and'smoke'or'long-soak',cycles={},stages={},checkpointBranches=true,injectsCombatState=false}
local clearRootCleanup=os.getenv('LSD_QA_SOAK_PRESERVE_ROOT_CLEANUP')~='1'
r.qaRootCleanupReset=clearRootCleanup;r.cleanupMeasurements={}
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
   r.completedCycles=cycle;r.frames=frameSummary();r.sceneEntries=scenes;save()
  until requested==0 or D.App.totalTime-started>=requested
  assert(requested==0 or D.App.totalTime-started>=1800,'Long soak did not reach 30 minutes')
  r.status='PASS';r.phase='complete';r.sameNativeProcess=true;r.memoryTrendNeedsReview=true;r.fullGameComplete=false
 end,debug.traceback)
 os.getenv=realGetenv;sampler:removeFromParent();r.frames=frameSummary();r.sceneEntries=scenes
 if not ok then r.status='FAIL';r.error=why end;save()
end)
