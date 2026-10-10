-- Public route from an earned stealth checkpoint; no fabricated victory or user save writes.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local id=tostring(os.time());local out=D.Path(root,'Test/researcher-route-result.txt');D.Content:save(out,'RUNNING '..id)
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/infiltration-path-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-infiltration%-path%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-researcher-route-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(fn,t)local untilTime=D.App.runningTime+(t or 25);while not fn()do assert(D.App.runningTime<untilTime,'Researcher route stalled');D.sleep(.02)end end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.phase=='ready'end,40)
  local w=D.Platformer.Data.store.world;local route=w.infiltration
  assert(route.pathCompleted and route.researcher and not route.capture.caught)
  assert(not route.captureStore:writeAsync({status='won'}),'Accepted empty victory')
  route.menu:emit('Tapped',1)
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel and w.patrolLevel.phase=='ready'end,40)
  local level=D.Platformer.Data.store.world.patrolLevel;local b=level.battle
  level.start:emit('Tapped')
  wait(function()return b.world.storyFlow and b.world.storyFlow.id=='researcher-contact' and b.world.storyFlow.view.visible end)
  local f=b.world.storyFlow;while f.phase~='complete'do if not f.view._advancing then f.view.confirm:emit('Tapped')end;D.sleep(.08)end
  assert(#f.view._reviews==2,'Original contact rows missing')
  wait(function()return b.phase=='playing'end)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_researcher BEFORE UPDATE OF caught ON Game0Researcher WHEN NEW.caught=1 BEGIN SELECT RAISE(ABORT,'QA researcher');END")>=0)
  local deadline=D.App.runningTime+60
  while b.phase=='playing' or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Capture stalled')
   local target=b:target(b.mentor)
   if target then
    if math.abs(target.enemy.x-b.mentor.x)>330 then b:command(target.enemy.x>b.mentor.x and 'right' or 'left')else b:command('stop');b:command('shoot')end
    b:command('fire');b:command('wind')
   end
   D.sleep(.03)
  end
  assert(b.phase=='won',b.reason);wait(function()return level.phase=='save-error'end)
  local store=assert(require('Story.ResearcherStore').open());assert(not store:load().caught,'Failed write advanced capture')
  D.DB:exec('DROP TRIGGER lsd.fail_researcher');level.result.againButton:emit('Tapped');wait(function()return level.phase=='result'end)
  assert(store:load().caught and level.checkpointSaved)
  local saved=D.json.encode(store:load().report,false,true);assert(store:writeAsync(b.report));assert(saved==D.json.encode(store:load().report,false,true),'Replay replaced first report')
  level.result.againButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.infiltration and w.infiltration.capture and w.infiltration.capture.caught end,40)
  w=D.Platformer.Data.store.world;route=w.infiltration
  assert(route.researcher.current=='restrained' and not route.battleLevel and not route.path)
  local p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end);assert(math.abs(p.unit.x-4100)<50)
  assert(assert(require('Story.Service').open()):summary().objective:find('已被控制'))
  assert(assert(require('Story.Service').open()):canRead('researcher-interrogation','Factory'));assert(not route.battleLevel,'Repeated capture battle')
  for name,value in pairs(snapshot)do if name~='Game0StoryNodes' and name~='Game0StoryUnlocks'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  D.Content:save(D.Path(root,'Test/researcher-resume-fixture.txt'),db)
  assert(D.DB:exec('UPDATE lsd.Game0Researcher SET schemaVersion=99 WHERE id=1')>=0)
  local bad,err=require('Story.ResearcherStore').open();assert(not bad and err=='INCOMPATIBLE_RESEARCHER_SAVE')
  local options,resumeError=require('Story.InfiltrationStore').resumeOptions(assert(require('Story.Service').open()):summary());assert(not options and resumeError=='INCOMPATIBLE_RESEARCHER_SAVE')
  D.DB:exec('UPDATE lsd.Game0Researcher SET schemaVersion=1 WHERE id=1')
  return 'PASS earnedPath=true publicInteraction=true originalContactRows2=true realCombat=true saveFailureRetry=true idempotentCapture=true factoryReturn4100=true restrainedActor=true noRepeatedBattle=true priorTablesPreserved=true futureVersionRefused=true sameProcessOnly=true osInput=false'
 end,debug.traceback)
 local text='LSD_RESEARCHER_ROUTE_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;D.Content:save(out,text);print(text)
end)
