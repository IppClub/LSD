-- Actual earned model copy, physical guard projectiles, and authored three-person skills.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','researcher-battle-result.txt');D.Content:save(out,'LSD_RESEARCHER_BATTLE_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','command-assembly-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-command%-assembly%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-researcher-battle-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local snapshot={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")) do snapshot[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true) end
  local progress=require('Training.Progress');assert(progress.load());local wp=progress.forCharacter('wuyun');assert(wp.load());local models={ninilite=assert(progress.adopted),wuyun=assert(wp.adopted)}
  local b=require('Factory.ResearcherBattle').createAsync(models);assert(b.phase=='ready' and #b.enemies==1)
  D.sleep(1);assert(b.mentorHP==100 and b.arena.studentHP==100 and b.wuyun.studentHP==100,'Guards attacked before start')
  assert(not b:command('shoot'));assert(b:start());local deadline=D.App.runningTime+70;local nextShot=0
  while b.phase=='playing' or b.phase=='settling' do
   assert(D.App.runningTime<deadline,'Patrol battle stalled')
   local e=b:target(b.mentor)
   if e then
    if math.abs(e.enemy.x-b.mentor.x)>330 then b:command(e.enemy.x>b.mentor.x and 'right' or 'left') else b:command('stop');if D.App.runningTime>=nextShot then b:command('shoot');nextShot=D.App.runningTime+.3 end end
    b:command('fire');b:command('wind')
   end
   D.sleep(.03)
  end
  assert(b.phase=='won',b.reason or b.phase)
  assert(b.mentorHits+b.magic.fireHits+b.magic.windHits>0,'No commanded physical hit')
  for _,a in ipairs(b.learners) do assert(a.metrics.modelActions>0 and a.metrics.hits>0 and a.trialModel==models[a.character.id],'Adopted learner not used') end
  local r=b.enemies[1].guard
  assert(r.dead and r.capturedAt and not r.escaped,'Researcher not captured')
  assert(#r.hits>0 and r.damageTaken>=180,'No actual damage/reactions')
  for _,hit in ipairs(r.hits)do assert(hit.ended and hit.ended-hit.started>=.6,'Researcher reaction was cut short')end
  assert(r.unit.playable.current=='restrained','Captured actor lost restrained loop')
  for name,value in pairs(snapshot) do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Prototype battle mutated '..name) end
  return 'PASS singleResearcher=true actualEarnedModels=true physicalHits=true fullHitAnimationEnds=true restrainedLoop=true databaseUnchanged=true osInput=false '..D.json.encode(b.report,false,true)
 end,debug.traceback)
 local report='LSD_RESEARCHER_BATTLE_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
