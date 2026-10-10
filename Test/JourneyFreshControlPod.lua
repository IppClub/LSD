-- Public entry and actual timed native traversal on a copy of an earned second-patrol victory.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/fresh-control-pod-route-result.json')
local function save()D.Content:save(out,D.json.encode(report))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-second-patrol-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-fresh%-second%-patrol%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-fresh-control-pod-route-qa-'..run..'.db');report.database=db
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Control pod stalled');D.sleep(.03)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.phase=='ready'end,40)
  D.Platformer.Data.store.world.infiltration.menu:emit('Tapped',1)
  wait(function()local w=D.Platformer.Data.store.world;return w and w.controlPod and w.controlPod.phase=='ready'end,40)
  local w=D.Platformer.Data.store.world;local c=w.controlPod;report.entered=true;save()
  assert(c.fox.model.motionVariant=='spine-corrected' and require('Story.FoxCompanion').walkSpeed==240)
  assert(c.floor==1 and #c.actors==3 and c.barrier and not c.state.doorOpen)
  assert(not c:openDoor());assert(not c.store:writeAsync('floor',{from=1,to=7}))
  local count=0;D.Group({'name','unit'}):each(function(e)if e.name=='wuyun' and e.unit.world==w then count=count+1 end end);assert(count==0)
  for floor=2,7 do
   if floor==3 then assert(D.DB:exec("CREATE TRIGGER lsd.fail_pod BEFORE UPDATE ON Game0ControlPod BEGIN SELECT RAISE(ABORT,'QA pod');END")>=0)end
   c.up:emit('TapBegan');wait(function()return c.phase=='ready' or c.phase=='save-error'end,20)
   if floor==3 then
    assert(c.phase=='save-error' and assert(c.store:load()).floor==2)
    assert(D.DB:exec('DROP TRIGGER lsd.fail_pod')>=0);c.retry:emit('Tapped');wait(function()return c.phase=='ready'end)
   end
   assert(c.floor==floor and c.state.floor==floor);assert(c.lastTraversal.maxX-c.lastTraversal.minX>950)
   report.floor=floor;save()
  end
  c.hud.move:emit('Right',true);wait(function()return c.player.unit.x>1390 end,10);D.sleep(1.5);assert(c.player.unit.x<1500,'Sealed door collision failed');c.hud.move:emit('Right',false);D.sleep(.1)
  assert(c.barrier)
  c.doorButton:emit('TapBegan');wait(function()return c.phase=='ready'end,10)
  assert(c.state.doorOpen and not c.barrier and c.lastDoor.seconds>=2.75 and c.lastDoor.soundHandle>0)
  local proof=assert(c.store:load()).report;assert(#proof.floors==6 and proof.door)
  for name,value in pairs(snapshot)do if name~='Game0ControlPod' then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  D.Content:save(D.Path(root,'Test/fresh-control-pod-resume-fixture.txt'),db)
  report.status='PASS';report.proof=proof;report.publicEntry=true;report.sevenFloors=true;report.saveFailureRetry=true;report.doorOpened=true;report.priorTablesPreserved=true
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end;save();print(D.json.encode(report))
end)
