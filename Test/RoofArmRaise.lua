-- Candidate arm lift for 2-17, verified in the real rooftop after an earned win.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/roof-arm-raise-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/roof-battle-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-roof%-battle%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-roof-arm-qa-'..run..'.db');report.source=source;report.database=db
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  D.Cache:unload('spine:Spine/Roof/wuyun.json|Spine/wuyun.atlas')
  local function wait(f,t)local deadline=D.App.runningTime+(t or 20);while not f()do assert(D.App.runningTime<deadline,'Arm animation stalled');D.sleep(.01)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.roof and w.roof.phase=='ready'end,40)
  local c=D.Platformer.Data.store.world.roof;assert(c.duelComplete)
  c.hud.move:emit('Right',true);wait(function()return c.player.model.x>2490 end);c.hud.move:emit('Right',false);D.sleep(.7);c.phase='arm-preview';c.held={};c.wuyun:play('idle',true);D.sleep(.3)
  local raised=false;local eventAt;local m=c.wuyun;local base=m:getKey('roofMark/roofMark');local last=base;local maxStep=0;local samples=0;local phase='raise'
  local observer=D.Node();observer.scheduler=D.Director.postScheduler;observer:addTo(c.world);observer:schedule(function()local p=m:getKey('roofMark/roofMark');local step=(p-last).length;if step>maxStep then maxStep=step;report.maxStepPhase=phase end;last=p;samples=samples+1;return false end)
  m:slot('roofArmRaised',function()raised=true;eventAt=D.App.runningTime;m.speed=0 end)
  local start=D.App.runningTime;m.recovery=.2;local duration=m:play('roofRaise',false);assert(duration>.79 and duration<.81)
  wait(function()return raised end,3);D.sleep(.1);local high=m:getKey('roofMark/roofMark');assert(high.y-base.y>60,'Arm did not visibly rise')
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-wuyun-raised.tga'))
  D.sleep(.6);assert((m:getKey('roofMark/roofMark')-high).length<.05,'Held arm drifted')
  local lowered=false;m:slot('roofArmLowered',function()lowered=true end);phase='lower';m.speed=1;m.recovery=0;m:play('roofLower',false);wait(function()return lowered end,2);D.sleep(.02);phase='recovery';m.recovery=.2;m:play('idle',true);D.sleep(.4)
  report.maxAnchorStep=maxStep
  assert(maxStep<12,'Arm recovery jumped');observer:removeFromParent();c.phase='ready'
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  report.status='PASS';report.duration=duration;report.nativeRaisedAt=eventAt-start;report.armRise=high.y-base.y;report.maxAnchorStep=maxStep;report.samples=samples;report.recovery=.2;report.allTablesPreserved=true
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
