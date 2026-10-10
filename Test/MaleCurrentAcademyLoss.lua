local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')})do D.Content:insertSearchPath(1,p)end
local run=tostring(os.time());local result={status='RUNNING',runId=run,osInput=false};local out=D.Path(root,'Test/male-current-academy-loss-result.json');D.Content:save(out,D.json.encode(result))
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test/male-current-academy-defense-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-male%-current%-academy%-defense%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-male-current-academy-loss-qa-'..run..'.db');result.source=source;result.database=db
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local snapshot={};for _,r in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'"))do snapshot[r[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..r[1]..' ORDER BY 1'),false,true)end
  local function wait(f,t)local deadline=D.App.runningTime+t;while not f()do assert(D.App.runningTime<deadline,'Academy loss timeout');D.sleep(.03)end end
  require('Data.Config'):loadAsync();local service=assert(require('Story.Service').open());local nav=require('Academy.Navigation')
  assert(not service:canRead('academy-loss','RDRoom'));assert(not service:completeAsync('academy-loss','PassageA',false,{}))
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.tag=='PassageA'and w.academyLoss end,40)
  local w=D.Platformer.Data.store.world;local c=assert(w.academyLoss);assert(not c.recorded and not c.damageNode)
  local player=assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end))
  local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end)
  hud.move:emit('Left',true);wait(function()return player.unit.x<c.marker.x-240 end,12);hud.move:emit('Left',false);D.sleep(.3)
  assert(not c:request(),'Remote request accepted')
  hud.move:emit('Right',true);wait(function()return player.unit.x>c.marker.x-60 end,12);hud.move:emit('Right',false);D.sleep(.3)
  c.menu:emit('Tapped',1);wait(function()return w.storyFlow~=nil end,15);local f=w.storyFlow
  local function advance(flow)
   wait(function()return flow.view.visible end,20);local deadline=D.App.runningTime+60
   while flow.phase=='dialogue'or flow.phase=='saving'do assert(D.App.runningTime<deadline,'Dialogue stalled');if flow.view.visible and not flow.view._advancing then flow.view.confirm:emit('Tapped')end;D.sleep(.08)end
  end
  advance(f);assert(f.phase=='complete'and #f.view._reviews==8,'Missing eight-row completion');result.saveFaultInjected=false
  wait(function()local n=D.Platformer.Data.store.world;return n~=w and n.academyLoss and n.academyLoss.recorded end,20)
  w=D.Platformer.Data.store.world;c=w.academyLoss;assert(c.damageNode and not w.defenseGate and not w.reconnection and not w.storyFlow)
  local roster=assert(require('Story.AcademyLossRecords').saved());result.roster=roster;result.proof=D.json.decode(D.DB:query("SELECT report FROM lsd.Game0StoryPerformances WHERE node='academy-loss'")[1][1],32)
  assert(require('Story.AcademyLossProof').validate(result.proof))
  assert(not require('Story.Availability').canDeploy('liyena')and not require('Story.Availability').canDeploy('wuyun')and require('Story.Availability').canDeploy('ninilite'))
  local before=D.json.encode(D.DB:query('SELECT * FROM lsd.Game0StoryPerformances ORDER BY node'),false,true)
  local replay=assert(require('Story.Flow').openAsync('academy-loss',w,nil,true));advance(replay);assert(replay.phase=='complete'and #replay.view._reviews==8)
  assert(before==D.json.encode(D.DB:query('SELECT * FROM lsd.Game0StoryPerformances ORDER BY node'),false,true));result.replayUnchanged=true
  c:showRecord();D.sleep(.5);c.record.nextButton:emit('Tapped');D.sleep(.2);assert(c.record.pageLabel.text=='记录 2 / 3');c.record.nextButton:emit('Tapped');D.sleep(.2);assert(c.record.pageLabel.text=='记录 3 / 3');c.record.previousButton:emit('Tapped');c.record.previousButton:emit('Tapped');D.sleep(.3);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/male-current-academy-loss-record.tga'));D.sleep(.3);c.record.closeButton:emit('Tapped')
  local companion=assert(require('Academy.Companion').openAsync('ninilite',w,'talk'));wait(function()return companion.view.visible end,20);local deadline=D.App.runningTime+30;while companion.phase=='dialogue'do assert(D.App.runningTime<deadline);if not companion.view._advancing then companion.view.confirm:emit('Tapped')end;D.sleep(.08)end;assert(#companion.view._reviews==3);result.currentCompanionTalk=true
  w=nav.returnToRoomAsync('RestRoom');assert(w.academyLoss and w.academyLoss.damageNode and not w.medicalVisit and not w.recoveryVisit)
  w=nav.returnToRoomAsync('RDRoom');assert(w.academyLoss and w.academyLoss.damageNode and not w.reconnection and not w.storyFlow)
  package.loaded['Start']=nil;require('Start');wait(function()local n=D.Platformer.Data.store.world;return n~=w and n.tag=='PassageA'and n.academyLoss and n.academyLoss.recorded end,30)
  w=D.Platformer.Data.store.world;assert(not w.storyFlow);result.startRestored=true
  D.sleep(1);D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/male-current-academy-loss-scene.tga'));D.sleep(.3)
  for name,value in pairs(snapshot)do if name~='Game0StoryNodes'and name~='Game0StoryUnlocks'and name~='Game0StoryPerformances'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Changed '..name)end end
  result.priorTablesPreserved=true;result.status='PASS';D.Content:save(D.Path(root,'Test/male-current-academy-loss-resume-fixture.txt'),db)
 end,debug.traceback)
 if not ok then result.status='FAIL';result.error=err end;D.Content:save(out,D.json.encode(result));print(D.json.encode(result))
end)
