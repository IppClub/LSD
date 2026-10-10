local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local report={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/fresh-roof-aftermath-result.json');D.Content:save(out,D.json.encode(report))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/fresh-roof-battle-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-fresh%-roof%-battle%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-fresh-roof-aftermath-qa-'..run..'.db');report.database=db;report.source=source
  assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+(t or 20);while not f()do assert(D.App.runningTime<deadline,'Roof dialogue stalled');D.sleep(.02)end end
  require('Start');wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.roof and D.Platformer.Data.store.world.roof.phase=='ready'end,40)
  local c=D.Platformer.Data.store.world.roof;assert(c.stage==2 and c.duelComplete and not c.aftermathComplete)
  local service=assert(require('Story.Service').open());local rejected,why=service:completeAsync('roof-aftermath','FactoryRoof',false,{})
  assert(not rejected and why=='ROOF_AFTERMATH_REQUIRED')
  c.hud.move:emit('Right',true);wait(function()return c.player.model.x>=2490 end,8);c.hud.move:emit('Right',false);D.sleep(.7)
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/fresh-roof-aftermath-approach.tga'))
  assert(c:act());wait(function()return c.world.storyFlow and c.world.storyFlow.view.visible end)
  local flow=c.world.storyFlow;local view=flow.view;assert(flow.id=='roof-aftermath')
  assert(D.DB:exec("CREATE TRIGGER lsd.fail_roof_dialogue BEFORE INSERT ON Game0StoryNodes WHEN NEW.id='roof-aftermath' BEGIN SELECT RAISE(FAIL,'qa injected save failure'); END")>=0)
  local captured=false;local observer=D.Node();observer:addTo(c.world);observer:schedule(function()if c.vortex.active and c.vortex.elapsed>1.4 and not captured then captured=true;D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/fresh-roof-vortex-native.tga'))end;return captured end)
  local departureImage=false;local capture=D.Node();capture:addTo(c.world);capture:schedule(function()if c.wuyun.y>1400 and c.wuyun.visible and not departureImage then departureImage=true;D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/fresh-roof-vortex-entry.tga'))end;return departureImage end)
  local deadline=D.App.runningTime+90
  while flow.phase=='dialogue'do assert(D.App.runningTime<deadline,'Dialogue did not advance');if not view._advancing then view.confirm:emit('Tapped')end;D.sleep(.05)end
  wait(function()return flow.phase=='save-error'end);assert(#view._reviews==5 and not service:summary().completed['roof-aftermath'])
  assert(#D.DB:query("SELECT * FROM lsd.Game0StoryPerformances WHERE node='roof-aftermath'")==0)
  assert(D.DB:exec('DROP TRIGGER lsd.fail_roof_dialogue')>=0);flow.retryButton:emit('Tapped');wait(function()return flow.phase=='complete'end)
  assert(c.aftermathComplete and c.vortex.active and not c.wuyun.visible and c.phase=='ready')
  local proof=assert(D.DB:query("SELECT report FROM lsd.Game0StoryPerformances WHERE node='roof-aftermath'"))[1][1]
  assert(require('Story.RoofAftermathProof').validate(D.json.decode(proof)))
  local again,why=service:completeAsync('roof-aftermath','FactoryRoof',true);assert(again,why)
  local replay=assert(require('Story.Flow').openAsync('roof-aftermath',c.world,nil,true));deadline=D.App.runningTime+90
  while replay.phase=='dialogue'or replay.phase=='saving'do assert(D.App.runningTime<deadline,'Replay stalled');if replay.phase=='dialogue'and not replay.view._advancing then replay.view.confirm:emit('Tapped')end;D.sleep(.05)end
  assert(replay.phase=='complete'and #replay.view._reviews==5 and D.DB:query("SELECT report FROM lsd.Game0StoryPerformances WHERE node='roof-aftermath'")[1][1]==proof)
  for name,value in pairs(snapshot)do if name~='Game0StoryNodes'and name~='Game0StoryUnlocks'and name~='Game0StoryPerformances'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  local world=assert(require('Factory.Roof').openAsync());c=world.roof;assert(c.stage==2 and c.aftermathComplete and c.vortex.active and not c.wuyun.visible and not world.storyFlow)
  report.status='PASS';report.rows=5;report.proof=D.json.decode(proof);report.saveRetry=true;report.replay=true;report.resume=true;report.priorTablesPreserved=true
  D.Content:save(D.Path(root,'Test/fresh-roof-aftermath-resume-fixture.txt'),db)
 end,debug.traceback)
 if not ok then report.status='FAIL';report.error=err end;D.Content:save(out,D.json.encode(report));print(D.json.encode(report))
end)
