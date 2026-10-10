local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/auxiliary-selection-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/train-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-train%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-auxiliary-selection-qa-'..run..'.db');result.source=source;result.database=db
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  require('Data.Config'):loadAsync();assert(require('Story.Service').open():summary().completed['mail-two'])
  local store=assert(require('Ground.AuxiliarySelection').open());assert(not store:load().recorded,'Old profile acquired invented choice')
  local snapshots={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshots[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Auxiliary selection timeout');D.sleep(.03)end end
  local nav=require('Academy.Navigation');local w=nav.returnToRoomAsync('TrainA');local deployment=require('Ground.Deployment')
  local c=assert(deployment.openAsync(w));assert(c.auxiliaryVariant=='defence'and not c.auxiliaryRecorded)
  c.auxiliaryButtons.mobility:emit('Tapped');c.view.backButton:emit('Tapped');assert(not store:load().recorded);result.cancelWithoutHistory=true
  c=assert(deployment.openAsync(w));c.auxiliaryButtons.cargo:emit('Tapped')
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_auxiliary BEFORE INSERT ON Game0AuxiliarySelection BEGIN SELECT RAISE(FAIL,'QA auxiliary save'); END")>=0)
  c.view.startButton:emit('Tapped');wait(function()return c.phase=='briefing'and c.error=='WRITE_FAILED'end,10)
  assert(D.Platformer.Data.store.world==w and not store:load().recorded and c.auxiliaryVariant=='cargo')
  assert(D.DB:exec('DROP TRIGGER lsd.fail_auxiliary')>=0);result.saveFailureStayedInBriefing=true
  result.variants={}
  for _,id in ipairs({'cargo','defence','mobility'})do
   c.auxiliaryButtons[id]:emit('Tapped');c.view.startButton:emit('Tapped')
   wait(function()local n=D.Platformer.Data.store.world;return n~=w and n.tag=='AbandonedCity'and n.auxiliaryView and n.groundExpedition end,25)
   local city=D.Platformer.Data.store.world;local actor=city.auxiliaryView.actor
   assert(city.auxiliaryVariant==id and city.groundExpedition.support.variant==id and actor.variant==id)
   wait(function()return actor.completed.deploy and actor.completed.shield end,15)
   local saved=assert(require('Ground.AuxiliarySelection').open():load());assert(saved.recorded and saved.variant==id and saved.destination=='AbandonedCity')
   result.variants[id]={deploy=actor.completed.deploy,shield=actor.completed.shield}
   w=nav.returnToRoomAsync('TrainA');c=assert(deployment.openAsync(w));assert(c.auxiliaryVariant==id and c.auxiliaryRecorded)
   local other=id=='cargo'and 'mobility'or 'cargo';c.auxiliaryButtons[other]:emit('Tapped');c.view.backButton:emit('Tapped');assert(store:load().variant==id)
   c=assert(deployment.openAsync(w));assert(c.auxiliaryVariant==id)
  end
  assert(not store:saveAsync('missing','AbandonedCity'));assert(not store:saveAsync('cargo','missing'));assert(store:load().variant=='mobility')
  c.view.backButton:emit('Tapped')
  assert(D.DB:exec('UPDATE lsd.Game0AuxiliarySelection SET schemaVersion=9 WHERE id=1')>=0)
  local bad,err=store:load();assert(not bad and err=='INCOMPATIBLE_AUXILIARY_SAVE');assert(not store:saveAsync('cargo','AbandonedCity'));assert(D.DB:query('SELECT schemaVersion FROM lsd.Game0AuxiliarySelection')[1][1]==9)
  assert(D.DB:exec('UPDATE lsd.Game0AuxiliarySelection SET schemaVersion=1 WHERE id=1')>=0)
  for name,value in pairs(snapshots)do if name~='Game0AuxiliarySelection'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  c=assert(deployment.openAsync(w));assert(c.auxiliaryVariant=='mobility');D.sleep(.3);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/auxiliary-selection-restored.tga'));D.sleep(.2)
  result.priorTablesPreserved=true;result.cancelPreservedSelection=true;result.invalidRejected=true;result.status='PASS';D.Content:save(D.Path(root,'Test/auxiliary-selection-resume-fixture.txt'),db)
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=why end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
