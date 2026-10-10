-- Actual earned model copy, physical guard projectiles, and authored three-person skills.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','patrol-outcomes-result.txt');D.Content:save(out,'LSD_PATROL_OUTCOMES_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','command-assembly-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-command%-assembly%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-patrol-outcomes-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local snapshot={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")) do snapshot[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true) end
  local progress=require('Training.Progress');assert(progress.load());local wp=progress.forCharacter('wuyun');assert(wp.load());local models={ninilite=assert(progress.adopted),wuyun=assert(wp.adopted)}
  local factory=require('Factory.PatrolBattle')
  local b=factory.createAsync(models)
  assert(b:finish('aborted','QA actual ready withdrawal'))
  local deadline=D.App.runningTime+12
  while b.phase=='settling' do assert(D.App.runningTime<deadline);D.sleep(.01) end
  assert(b.phase=='aborted' and b.settled and b.mentorHP==100)
  for _,e in ipairs(b.enemies) do assert(#e.guard.strikes==0 and e.enemyHP==240) end
  b=factory.createAsync(models);assert(b:start())
  deadline=D.App.runningTime+95
  while b.phase=='playing' or b.phase=='settling' do
   assert(D.App.runningTime<deadline,'Physical failure did not settle')
   D.sleep(.01)
  end
  assert(b.phase=='failed' and b.settled and b.reason:find('协同',1,true),'Passive patrol incorrectly completed authored collaboration')
  local hits=0;for _,e in ipairs(b.enemies) do for _,s in ipairs(e.guard.strikes) do hits=hits+s.hits end end
  assert(hits>0 and b.mentorHP<100,'No physical patrol damage evidence')
  for name,value in pairs(snapshot) do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Prototype battle mutated '..name) end
  return 'PASS readyAbort=true noPrematureShots=true passiveMissingSkillFailure=true physicalDamage=true settled=true allDatabaseTablesUnchanged=true hits='..hits
 end,debug.traceback)
 local report='LSD_PATROL_OUTCOMES_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
