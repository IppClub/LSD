-- Continuous native game loop; keep this engine session alive until terminal status.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local report={status='RUNNING',runId=os.time(),osInput=false,targetSeconds=720,completedCycles=0,phase='loading'}
package.loaded['_lsd_training_memory_diagnostic_state']=report
local out=D.Path(root,'Test/training-memory-diagnostic-result.json');local started=D.App.runningTime
local function census()
 local rows={};local modules={}
 for name in pairs(package.loaded)do modules[#modules+1]=tostring(name)end;table.sort(modules)
 -- Only count direct registry tables; never traverse weak native bindings or keep their values.
 if debug and debug.getregistry then
  for key,value in pairs(debug.getregistry())do
   if type(value)=='table' then
    local entries,maxInteger=0,0
    for k in pairs(value)do entries=entries+1;if type(k)=='number' and k%1==0 and k>maxInteger then maxInteger=k end end
    local mt=getmetatable(value)
    rows[#rows+1]={key=tostring(key),entries=entries,maxInteger=maxInteger,weak=type(mt)=='table'and rawget(mt,'__mode')or nil}
   end
  end
 end
 table.sort(rows,function(a,b)return a.key<b.key end)
 return {modules=modules,registryTables=rows}
end
local function save()report.elapsed=D.App.runningTime-started;report.heartbeat=D.App.runningTime;D.Content:save(out,D.json.encode(report))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-cooperation-resume-fixture.txt')));assert(D.Path:getFilename(source):match('^lsd%-fresh%-cooperation%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-training-memory-diagnostic-qa-'..report.runId..'.db');report.database=db
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  require('Data.Config'):loadAsync()
  local function wait(f,seconds)
   local limit=D.App.runningTime+(seconds or 40);local nextSave=0
   while not f()do assert(D.App.runningTime<limit,'Soak stalled: '..report.phase);report.heartbeat=D.App.runningTime
    if D.App.runningTime>nextSave then save();nextSave=D.App.runningTime+5 end;D.sleep(.04)
   end
  end
  local weak=setmetatable({},{__mode='v'});local count=0
  require('Academy.Navigation').returnToTrainingAsync()
  repeat
   count=count+1;report.currentCycle=count;report.phase='enter';save()
   local world=D.Platformer.Data.store.world;assert(world.tag=='TrainingRoom')
   local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end)
   local p;wait(function()p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end);return p and not p.busy end)
   hud.move:emit('Left',true);wait(function()return p.unit.x<950 end);hud.move:emit('Left',false);D.sleep(.15)
   assert(world:getChildByTag('trainingTerminal'),'Training room terminal was not created'):emit('Tapped',1);wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
   local ui=D.Director.ui3D:getChildByTag('training-controls');local a=ui.arena;weak[count]=a
   local h=D.Director.ui3D:getChildByTag('trainingHUD');local menu=ui:getChildByTag('training-menu')
   report.phase='demonstrate';save()
   for _,distance in ipairs({'近处对练','中距对练','远处对练'})do
    menu:getChildByTag(distance):emit('Tapped');wait(function()return a:available('laser')end)
    local hits=a.metrics.hits;h.weapon:emit('TapBegan');h.weapon:emit('TapEnded')
    wait(function()return a.metrics.hits>hits and not a:isAttacking()end)
    h.skillArea:getChildByTag('training-wait'):emit('TapBegan');D.sleep(.08)
   end
   assert(#a.recorder.samples==6,'Expected six actual successful demonstrations')
   report.phase='build';menu:getChildByTag('结束示范'):emit('Tapped');wait(function()return a.mode=='review'end);assert(a.candidate)
   report.phase='evaluate';menu:getChildByTag('三场试战'):emit('Tapped');wait(function()return a.evaluation and not a.evaluating end,300)
   assert(#a.evaluation.candidate==3 and #a.evaluation.baseline==3)
   local evaluated=a.candidate;report.phase='adopt';menu:getChildByTag('采用'):emit('Tapped');wait(function()return a.mode=='review'end)
   assert(a.adopted==evaluated and a.message=='训练成果已保存，可退出后继续。')
   assert(require('Training.Progress').load());assert(require('Training.Progress').adopted.sampleCount==6)
   local result={index=count,seconds=D.App.runningTime-started,candidate=a.evaluation.summary.candidate.wins,baseline=a.evaluation.summary.baseline.wins}
   report.phase='return';menu:getChildByTag('返回训练室'):emit('Tapped');wait(function()local w=D.Platformer.Data.store.world;return a.closed and w.tag=='TrainingRoom' and w:getChildByTag('trainingTerminal')end)
   a=nil;ui=nil;h=nil;menu=nil;world=nil;hud=nil;p=nil;evaluated=nil
   D.sleep(.25);collectgarbage('collect');D.sleep(.1);collectgarbage('collect')
   local retained=0;for _,value in pairs(weak)do if value then retained=retained+1 end end
   result.objects=D.Object.count;result.luaRefs=D.Object.luaRefCount;result.callRefs=D.Object.callRefCount;result.luaKB=collectgarbage('count');result.retainedArenas=retained
   assert(retained<=1,'Old training arenas retained across cycles')
   result.census=census()
   local cyclePath=D.Path(root,'Test/training-memory-diagnostic-'..report.runId..'-cycle-'..count..'.json')
   D.Content:save(cyclePath,D.json.encode(result))
   result.census=nil;report.lastCycle=result;report.completedCycles=count;save()
  until count>=12 and D.App.runningTime-started>=report.targetSeconds
  report.phase='complete';report.status='PASS';report.resourceTrendNeedsReview=true
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=why end;save();print(D.json.encode(report))
end)
