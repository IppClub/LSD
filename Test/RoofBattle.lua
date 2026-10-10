-- Native combat integration fixture; uses the earned dialogue save and adopted learner.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/roof-battle-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/roof-dialogue-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-roof%-dialogue%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-roof-battle-qa-'..run..'.db');report.database=db;report.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+(t or 20);while not f()do assert(D.App.runningTime<deadline,'Roof combat stalled');D.sleep(.02)end end
  require('Start');wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.roof and D.Platformer.Data.store.world.roof.phase=='ready'end,40)
  local c=D.Platformer.Data.store.world.roof;local p=require('Training.Progress');assert(p.load()and p.adopted)
  assert(c:act());wait(function()return c.world.patrolLevel end);local level=c.world.patrolLevel;local b=level.battle;wait(function()return b.mentor.onSurface and b.arena.student.onSurface and b.enemy.enemy.onSurface end)
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_roof_duel BEFORE UPDATE ON Game0RoofDuel WHEN NEW.completed=1 BEGIN SELECT RAISE(FAIL,'qa injected save failure'); END")>=0)
  level.start:emit('Tapped');wait(function()return b.phase=='playing'end);D.sleep(6)
  local deadline=D.App.runningTime+80;local captured=false
  while b.phase=='playing'or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Battle did not settle')
   if b.phase=='playing'then
    local delta=b.enemy.enemy.x-b.mentor.x
    if math.abs(delta)>215 then level.hud.move:emit(delta>0 and 'Right'or 'Left',true)else level.hud.move:emit('Right',false);level.hud.move:emit('Left',false);D.emit('Skill.Began');D.emit('Skill.Ended');level.fire:emit('TapBegan')end
    if b.opponent.busy and b.opponent.strike.kind=='wind'and not captured then captured=true;D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-wuyun-wind.tga'))end
   end;D.sleep(.04)
  end
  report.combat=b.report;assert(b.phase=='won',b.report.reason)
  assert(b.mentorHits>0 and b.arena.metrics.modelActions>0 and b.magic.fireHits>0 and b.opponent.dead)
  local kinds={};for _,s in ipairs(b.opponent.strikes)do
   assert(s.releaseAt and s.completed and s.completed>s.releaseAt and s.impactOffset>=(s.kind=='shot'and .48 or .38),'Truncated attack')
   assert(s.completed-s.started>=s.duration-.04,'Incomplete native action');kinds[s.kind]=true
  end
  assert(kinds.shot and kinds.wind,'Missing opponent move variety')
  assert(b.opponent.loseEnded-b.opponent.loseStarted>=b.opponent.loseDuration-.04,'Truncated defeat')
  wait(function()return level.phase=='save-error'end)
  local store=assert(require('Story.RoofDuelStore').open());assert(not store:load().completed)
  assert(D.DB:exec('DROP TRIGGER lsd.fail_roof_duel')>=0);level.result.againButton:emit('Tapped');wait(function()return level.phase=='result'end)
  assert(store:load().completed);local saved=D.json.encode(store:load().report,false,true);assert(store:writeAsync(b.report));assert(saved==D.json.encode(store:load().report,false,true))
  level.result.againButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world~=b.world and D.Platformer.Data.store.world.roof end)
  assert(D.Platformer.Data.store.world.roof.duelComplete)
  report.saveRetry=true;report.resume=true
  for name,value in pairs(snapshot)do if name~='Game0RoofDuel'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-wuyun-combat-won.tga'))
  D.Content:save(D.Path(root,'Test/roof-battle-resume-fixture.txt'),db)
  report.status='PASS';report.adoptedLearner=true;report.fullAttacks=true;report.priorTablesPreserved=true
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
