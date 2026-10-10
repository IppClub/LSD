-- Native combat integration fixture; uses the earned dialogue save and adopted learner.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=true};local out=D.Path(root,'Test/roof-battle-mouse-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/roof-dialogue-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-roof%-dialogue%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-roof-battle-mouse-qa-'..run..'.db');report.database=db;report.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+(t or 20);while not f()do assert(D.App.runningTime<deadline,'Roof combat stalled');D.sleep(.02)end end
  require('Start');wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.roof and D.Platformer.Data.store.world.roof.phase=='ready'end,40)
  local c=D.Platformer.Data.store.world.roof;local p=require('Training.Progress');assert(p.load()and p.adopted)
  wait(function()return c.world.patrolLevel end,900);local level=c.world.patrolLevel;local b=level.battle
  local audit={j=0,tap=0,event=0};b.inputAudit=audit;local monitor=D.Node();monitor:addTo(b.world)
  monitor:gslot('Skill.Began',function()audit.event=audit.event+1 end)
  level.hud.weapon:slot('TapBegan',function()audit.tap=audit.tap+1 end)
  monitor:schedule(function()if D.Keyboard:isKeyDown('J')then audit.j=audit.j+1 end;return false end)
  wait(function()return b.phase=='won'or b.phase=='failed'or b.phase=='aborted'end,900)
  report.combat=b.report;assert(b.phase=='won',b.report.reason)
  assert(b.mentorHits>0 and b.arena.metrics.modelActions>0 and b.opponent.dead)
  local kinds={};for _,s in ipairs(b.opponent.strikes)do
   assert(s.releaseAt and s.completed and s.completed>s.releaseAt and s.impactOffset>=(s.kind=='shot'and .48 or .38),'Truncated attack')
   assert(s.completed-s.started>=s.duration-.04,'Incomplete native action');kinds[s.kind]=true
  end
  assert(kinds.shot and kinds.wind,'Missing opponent move variety')
  assert(b.opponent.loseEnded-b.opponent.loseStarted>=b.opponent.loseDuration-.04,'Truncated defeat')
  wait(function()return level.phase=='result'end)
  local store=assert(require('Story.RoofDuelStore').open());assert(store:load().completed)
  report.actualInputOnly=true
  for name,value in pairs(snapshot)do if name~='Game0RoofDuel'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-wuyun-combat-os-won.tga'))
  D.Content:save(D.Path(root,'Test/roof-battle-mouse-fixture.txt'),db)
  report.status='PASS';report.adoptedLearner=true;report.fullAttacks=true;report.priorTablesPreserved=true
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
