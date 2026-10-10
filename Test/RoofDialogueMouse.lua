local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=true};local out=D.Path(root,'Test/roof-dialogue-mouse-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/roof-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-roof%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-roof-dialogue-mouse-qa-'..run..'.db');report.database=db;report.source=source
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+(t or 20);while not f()do assert(D.App.runningTime<deadline,'Roof dialogue stalled');D.sleep(.02)end end
  require('Start');wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.roof and D.Platformer.Data.store.world.roof.phase=='ready'end,40)
  local c=D.Platformer.Data.store.world.roof;assert(c.stage==2 and not c.confrontationComplete)
  local service=assert(require('Story.Service').open());local rejected,why=service:completeAsync('roof-confrontation','FactoryRoof',false,{})
  assert(not rejected and why=='ROOF_DIALOGUE_REQUIRED');local rejected,why=c:act();assert(not rejected and why=='OUT_OF_RANGE')
  wait(function()return c.world.storyFlow and c.world.storyFlow.view.visible end,900)
  local flow=c.world.storyFlow;local view=flow.view;assert(flow.id=='roof-confrontation')
  local captured=false;local observer=D.Node();observer:addTo(c.world);observer:schedule(function()if c.beacon.active and c.beacon.elapsed>1.5 and not captured then captured=true;D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/roof-beacon-os.tga'))end;return captured end)
  wait(function()return flow.phase=='complete'end,900)
  assert(#view._reviews==11)
  assert(c.confrontationComplete and c.beacon.active and c.phase=='ready')
  local proof=assert(D.DB:query("SELECT report FROM lsd.Game0StoryPerformances WHERE node='roof-confrontation'"))[1][1]
  assert(require('Story.RoofDialogueProof').validate(D.json.decode(proof)))
  for name,value in pairs(snapshot)do if name~='Game0StoryNodes'and name~='Game0StoryUnlocks'and name~='Game0StoryPerformances'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  report.status='PASS';report.rows=11;report.proof=D.json.decode(proof);report.actualInputOnly=true;report.priorTablesPreserved=true
  D.Content:save(D.Path(root,'Test/roof-dialogue-mouse-fixture.txt'),db)
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
