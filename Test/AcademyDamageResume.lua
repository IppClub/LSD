local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local result={status='RUNNING',runId=tostring(os.time()),osInput=false};local out=D.Path(root,'Test/academy-damage-resume-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,why=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/male-current-academy-loss-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-male%-current%-academy%-loss%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-academy-damage-resume-qa-'..result.runId..'.db');result.database=db;result.source=source
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  require('Start');local deadline=D.App.runningTime+40
  while not(D.Platformer.Data.store.world and D.Platformer.Data.store.world.academyLoss)do assert(D.App.runningTime<deadline);D.sleep(.03)end
  D.sleep(1);local w=D.Platformer.Data.store.world;assert(w.tag=='PassageA'and w.academyLoss.recorded and w.academyLoss.damageNode and not w.storyFlow and not w.defenseGate)
  assert(w.academyLoss.damageNode.children.count==12 and w.academyLoss.smoke.children.count==3)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/academy-damage-resumed.tga'))
  result.roster=assert(require('Story.AcademyLossRecords').saved());assert(#result.roster==11)
  assert(require('Story.Availability').canDeploy('ninilite'));assert(not require('Story.Availability').canDeploy('liyena'))
  for name,value in pairs(snapshot)do assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end
  result.allTablesPreserved=true;result.noReplay=true;result.status='PASS'
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=why end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
