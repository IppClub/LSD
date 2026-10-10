-- Actual earned model copy, physical guard projectiles, and authored three-person skills.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','researcher-mouse-result.txt');D.Content:save(out,'LSD_RESEARCHER_MOUSE_PREPARING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','command-assembly-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-command%-assembly%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-researcher-mouse-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local snapshot={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")) do snapshot[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true) end
  local progress=require('Training.Progress');assert(progress.load());local wp=progress.forCharacter('wuyun');assert(wp.load());local models={ninilite=assert(progress.adopted),wuyun=assert(wp.adopted)}
  local c=require('Factory.ResearcherLevel').openAsync(models)
  c.mouseQA={runId=id,before=snapshot,database=db};D.sleep(1)
  assert(c.battle.phase=='ready' and c.start.visible and c.hud.move)
  local watcher=D.Node();watcher:addTo(c.battle.world)
  watcher:schedule(function()
   if not c.battle.settled then return false end
   local unchanged=true
   for name,value in pairs(snapshot)do if value~=D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true)then unchanged=false end end
   local r={status=c.battle.phase,report=c.battle.report,databaseUnchanged=unchanged,runId=id,osInputTest=true}
   D.Content:save(D.Path(root,'Test/researcher-mouse-final.json'),D.json.encode(r));return true
  end)
  return 'READY originalHUD=true adoptedEarnedModels=true singleResearcher=true actualMouseStartRequired=true'
 end,debug.traceback)
 local report='LSD_RESEARCHER_MOUSE_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
