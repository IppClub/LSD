local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/final-betrayal-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/last-promise-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-last%-promise%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-final-betrayal-qa-'..run..'.db');result.database=db;result.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshots={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshots[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Final betrayal timeout');D.sleep(.02)end end
  require('Data.Config'):loadAsync();local service=assert(require('Story.Service').open());local Stage=require('Final.Betrayal')
  local row=assert(D.DB:query("SELECT id,mission,attempt FROM lsd.Game0MissionUnlocks WHERE id='last-promise-complete'")[1]);assert(D.DB:exec("DELETE FROM lsd.Game0MissionUnlocks WHERE id='last-promise-complete'")>=0)
  local denied,why=Stage.openAsync();assert(not denied and why=='STORY_LOCKED');assert(D.DB:exec('INSERT INTO lsd.Game0MissionUnlocks VALUES(?,?,?)',row)>=0)
  assert(not service:canRead('final-betrayal','RDRoom'));assert(not service:completeAsync('final-betrayal','PassageA',false,{}))
  local function advance(c)
   local f=assert(c:request());wait(function()return f.view.visible end,20)
   local deadline=D.App.runningTime+60;local clock
   while f.phase=='dialogue'or f.phase=='saving'do
    assert(D.App.runningTime<deadline)
    if c.frozenClock then clock=clock or c.clock;assert(c.clock==clock,'Communication clock advanced')end
    if f.view.visible and not f.view._advancing then
     local id=f.view._dialog.character;assert(f.view.figure.children.first.tag=='story-portrait:spine:'..id)
     f.view.confirm:emit('Tapped')
    end
    D.sleep(.12)
   end
   return f
  end
  -- Closing during a native attack must cancel only the unsaved presentation.
  local c=assert(Stage.openAsync());local f=assert(c:request())
  local attackDeadline=D.App.runningTime+60
  while not(c.actionReport and c.actionReport.attackStarted)do
   assert(D.App.runningTime<attackDeadline,'Cancel test did not reach attack')
   if f.view.visible and not f.view._advancing then f.view.confirm:emit('Tapped')end;D.sleep(.06)
  end
  c.back:emit('Tapped');wait(function()return D.Platformer.Data.store.world~=c.world end,20)
  assert(not service:summary().completed['final-betrayal']);result.cancelDuringAttackSafe=true
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_final_story BEFORE INSERT ON Game0StoryPerformances WHEN NEW.node='final-betrayal' BEGIN SELECT RAISE(FAIL,'qa final story'); END")>=0)
  c=assert(Stage.openAsync());c.onImpact=function()D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/final-betrayal-impact.tga'))end
  f=advance(c);assert(f.phase=='save-error'and #f.view._reviews==15 and not service:summary().completed['final-betrayal'])
  c.back:emit('Tapped');D.sleep(.1);assert(D.Platformer.Data.store.world==c.world,'Unsaved completion allowed exit')
  assert(D.DB:exec('DROP TRIGGER lsd.fail_final_story')>=0);f.retryButton:emit('Tapped');wait(function()return f.phase=='complete'end,10)
  assert(require('Final.BetrayalProof').validate(c.report));result.proof=c.report
  for _,corrupt in ipairs({function(p)p.rows=14 end,function(p)p.clockAfter=p.clockBefore+1 end,function(p)p.action.impactAt=p.action.attackStarted end,function(p)p.action.attackEnded=p.action.attackStarted end,function(p)p.action.fallStarted=p.action.hitStarted end,function(p)p.action.held=false end})do
   local p=D.json.decode(D.json.encode(c.report),32);corrupt(p);assert(not require('Final.BetrayalProof').validate(p))
  end
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/final-betrayal-held.tga'));D.sleep(.2)
  local before=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0StoryPerformances ORDER BY node'),false,true)
  c=assert(Stage.openAsync(true));f=advance(c);assert(f.phase=='complete'and #f.view._reviews==15)
  assert(before==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0StoryPerformances ORDER BY node'),false,true))
  require('Start');wait(function()local h=require('Ending.Hub').current;return h and h.mode=='records'and h.view end,30)
  assert(not D.Platformer.Data.store.world,'Completed story should resume in records')
  assert(service:summary().completed['final-betrayal']and service:summary().unlocks['final-story-complete'])
  for name,value in pairs(snapshots)do if name~='Game0StoryNodes'and name~='Game0StoryUnlocks'and name~='Game0StoryPerformances'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  result.priorTablesPreserved=true;result.replayUnchanged=true;result.sameProcessResume=true;result.saveRetry=true;result.status='PASS'
  D.Content:save(D.Path(root,'Test/final-betrayal-resume-fixture.txt'),db)
  -- Ready for a separate, explicitly scoped OS replay check.
  Stage.openAsync(true)
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=why end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
