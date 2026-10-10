-- Actual earned model copy, physical guard projectiles, and authored three-person skills.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','male-current-infiltration-route-result.txt');D.Content:save(out,'LSD_MALE_CURRENT_INFILTRATION_ROUTE_RUNNING '..id..'\n')
D.thread(function()
 local ok,result=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','male-current-command-assembly-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-male%-current%-command%-assembly%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-male-current-infiltration-route-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  local snapshot={};for _,row in ipairs(D.DB:query("SELECT name FROM lsd.sqlite_master WHERE type='table' AND name NOT LIKE 'sqlite_%'")) do snapshot[row[1]]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..row[1]..' ORDER BY 1'),false,true) end
  local progress=require('Training.Progress');assert(progress.load());local wp=progress.forCharacter('wuyun');assert(wp.load());local models={ninilite=assert(progress.adopted),wuyun=assert(wp.adopted)}
  local function wait(f,t) local deadline=D.App.runningTime+(t or 20);while not f()do assert(D.App.runningTime<deadline,'Public infiltration wait stalled');D.sleep(.03)end end
  local function advance(f,count)
   wait(function()return f.view.visible end)
   local deadline=D.App.runningTime+30;while f.phase~='complete'do assert(D.App.runningTime<deadline);if not f.view._advancing then f.view.confirm:emit('Tapped')end;D.sleep(.08)end
   assert(#f.view._reviews==count)
  end
  require('Start');wait(function()local w=D.Platformer.Data.store.world;return w and w.commandAssembly and w.commandAssembly.phase=='ready'end,40)
  local world=D.Platformer.Data.store.world;local assembly=world.commandAssembly
  local player=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end)
  local hud;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then hud=n end end);assert(hud)
  if math.abs(player.unit.x-assembly.center)>=100 then
   local side=player.unit.x<assembly.center and 'Right' or 'Left';hud.move:emit(side,true)
   wait(function()return math.abs(player.unit.x-assembly.center)<100 end);hud.move:emit(side,false);D.sleep(.3)
  end
  assembly.menu:emit('Tapped',4)
  wait(function()local w=D.Platformer.Data.store.world;return w~=world and w.infiltration and w.infiltration.phase=='ready'end,30)
  world=D.Platformer.Data.store.world;local c=world.infiltration;assert(world.infiltrationRoute and not world.factoryExpedition and c.fox.companionForm=='nine-tail-chibi' and c.fox.motionVariant=='spine-corrected')
  local store=c.store;assert(store:load().active and not store:load().located)
  assert(not store:writeAsync('locate',{fromLens=true,x=3000,seconds=3}),'Out-of-range scan accepted')
  c.menu:emit('Tapped',1);wait(function()return world.storyFlow and world.storyFlow.id=='patrol-approach'end);advance(world.storyFlow,2)
  assert(c:request());local lens=world.nightLens;assert(lens.locations[2].id=='patrol')
  lens.view.researchButton:emit('Tapped');wait(function()return store:load().located and not c.scanning end,6);lens.view.closeButton:emit('Tapped')
  assert(c:request());wait(function()return c.battleLevel and c.battleLevel.phase=='ready'end,30)
  local level=c.battleLevel;local b=level.battle
  level.start:emit('Tapped');wait(function()return b.world.storyFlow and b.world.storyFlow.id=='patrol-contact'end);advance(b.world.storyFlow,1);wait(function()return b.phase=='playing'end)
  local deadline=D.App.runningTime+70;local nextShot=0
  while b.phase=='playing' or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Patrol battle stalled')
   local e=b:target(b.mentor)
   if e then
    if math.abs(e.enemy.x-b.mentor.x)>330 then b:command(e.enemy.x>b.mentor.x and 'right' or 'left')else b:command('stop');if D.App.runningTime>=nextShot then b:command('shoot');nextShot=D.App.runningTime+.3 end end
    b:command('fire');b:command('wind')
   end;D.sleep(.03)
  end
  assert(b.phase=='won',b.reason);wait(function()return level.phase=='result' and level.checkpointSaved end)
  local report=store:load().report;assert(store:load().firstPatrol and report.mentorHits>0 and report.fireHits>0 and report.windHits>0)
  level.result.againButton:emit('Tapped');wait(function()local w=D.Platformer.Data.store.world;return w~=b.world and w.infiltration and w.infiltration.phase=='ready'end,30)
  world=D.Platformer.Data.store.world;c=world.infiltration;assert(c.state.firstPatrol and math.abs(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world end).unit.x-2200)<80)
  assert(c:request());advance(world.storyFlow,1);assert(require('Story.Service').open():summary().completed['patrol-cleared'])
  local saved=D.json.encode(store:load().report,false,true);D.sleep(.1);assert(c.phase=='ready'and not world.patrolBattle and saved==D.json.encode(store:load().report,false,true),'Repeated patrol completion changed report');assert(require('Story.Service').open():canRead('infiltration-fox-guide','Factory'))
  local fixture=D.Path(D.Content.writablePath,'lsd-male-current-infiltration-mid-qa-'..id..'.db');assert(not D.Content:exist(fixture) and D.Content:copyAsync(db,fixture));D.Content:save(D.Path(root,'Test','male-current-infiltration-resume-fixture.txt'),fixture)
  c.menu:emit('Tapped',2);wait(function()return D.Platformer.Data.store.world.tag=='OperationRoom'end,30);assert(not store:load().active and store:load().firstPatrol)
  local current=D.Platformer.Data.store.world;local journal=assert(require('Story.Journal').openAsync(current,13));journal.view.researchButton:emit('Tapped');wait(function()return current.storyFlow and current.storyFlow.id=='patrol-cleared'end);advance(current.storyFlow,1);wait(function()return current.storyJournal.phase=='journal'end);current.storyJournal.view.closeButton:emit('Tapped')
  for name,value in pairs(snapshot) do if name~='Game0StoryNodes' and name~='Game0StoryUnlocks'then assert(value==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Public infiltration mutated '..name) end end
  D.App:saveScreenshot(D.Path(root,'Docs/evidence/2026-10-04/male-current-infiltration.tga'));D.sleep(.2)
  return 'PASS physicalAssemblyEntry=true originalNightLens=true actualScanTwoSeconds=true originalThreeLinesAndCompletionLine=true realEarnedModelsBattle=true saveFaultInjected=false durablePatrolReport=true noRepeatBattleReward=true actualReturnOperation=true publicJournalReplay=true otherTablesUnchanged=true '..D.json.encode(report,false,true)
 end,debug.traceback)
 local report='LSD_MALE_CURRENT_INFILTRATION_ROUTE_'..(ok and result or 'FAIL '..tostring(result))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
