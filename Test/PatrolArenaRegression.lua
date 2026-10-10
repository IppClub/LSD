-- Actual earned model copy, physical guard projectiles, and authored three-person skills.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','patrol-arena-regression-result.txt');D.Content:save(out,'LSD_PATROL_ARENA_REGRESSION_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','command-assembly-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-command%-assembly%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-patrol-arena-regression-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local snapshot={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")) do snapshot[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true) end
  local progress=require('Training.Progress');assert(progress.load());local wp=progress.forCharacter('wuyun');assert(wp.load());local models={ninilite=assert(progress.adopted),wuyun=assert(wp.adopted)}
  local rounds={}
  for _,id in ipairs({'ninilite','wuyun'}) do
   local arena=require('Training.Arena').createAsync({scene='VRTraining',characterId=id,actionPrefix='patrolRegression'..id..'_'})
   assert(arena.enemyCombat and not arena.externalCombat,'Default training lost original enemy combat')
   assert(arena:beginTrial(id=='wuyun' and 420 or 500,models[id]))
   local deadline=D.App.runningTime+45
   while arena.mode=='trial' do assert(D.App.runningTime<deadline,'Original training trial stalled');D.sleep(.03) end
   assert(arena.result and arena.result.won and arena.metrics.modelActions>0 and arena.metrics.hits>0,'Original learner battle regressed')
   rounds[#rounds+1]={character=id,hits=arena.metrics.hits,modelActions=arena.metrics.modelActions,fallback=arena.metrics.fallback}
  end
  for name,value in pairs(snapshot) do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Prototype battle mutated '..name) end
  return 'PASS originalVRTraining=true originalEnemyCombat=true bothAdoptedLearners=true actualProjectileHits=true allDatabaseTablesUnchanged=true '..D.json.encode(rounds,false,true)
 end,debug.traceback)
 local report='LSD_PATROL_ARENA_REGRESSION_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
