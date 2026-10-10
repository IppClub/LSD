local script,fixture=...
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(script))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','pursuit-battle-result.txt');D.Content:save(out,'LSD_PURSUIT_RUNNING '..id..'\n')
D.thread(function()
 local ok,res=xpcall(function()
  local source=fixture or assert(D.Content:load(D.Path(root,'Test','ruins-resume-fixture.txt')));assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-ruins%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-pursuit-qa-'..id..'.db');assert(not D.DB:existDB('lsd') and not D.Content:exist(db) and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function() if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  require('Data.Config'):loadAsync();local story=assert(require('Story.Service').open());assert(story:summary().completed['ayan-recovery'])
  local wp=require('Training.Progress').forCharacter('wuyun');assert(require('Training.Progress').load() and wp.load());local models=D.json.encode({require('Training.Progress').adopted,wp.adopted},false,true)
  local function wait(f,t,describe) local untilTime=D.App.runningTime+(t or 15);while not f() do assert(D.App.runningTime<untilTime,'Pursuit wait stalled'..(describe and (' '..describe()) or ''));D.sleep(.04) end end
  local world=require('Academy.Navigation').returnToRoomAsync('AbandonedCity',{spawn=8800,energySquad=true,ruinsSearch=true})
  wait(function() return world.ruinsExpedition and world.ruinsExpedition.phase=='exploring' and world.ruinsExpedition.returnRoute.menu.enabled end,30)
  world.ruinsExpedition.returnRoute:emit('Tapped',1)
  wait(function() return world.storyFlow and world.storyFlow.id=='ruins-ambush' and world.storyFlow.view.visible end)
  local f=world.storyFlow
  while f.phase=='dialogue' or f.phase=='saving' do if not f.view._advancing then f.view.confirm:emit('Tapped') end;D.sleep(.08) end
  assert(f.phase=='complete' and #f.view._reviews==5)
  wait(function() return D.Platformer.Data.store.world.pursuitLevel end,30)
  local c=D.Platformer.Data.store.world.pursuitLevel;local b=c.battle
  for _,enemy in ipairs(b.enemies)do assert(require('Ruins.Pursuit').attackSpecs[enemy.asset],'Enemy lacks skill configuration: '..enemy.asset)end
  wait(function() return b.mentor.onSurface end)
  local hud=assert(D.Director.ui3D:getChildByTag('pursuit-hud'))
  hud.weapon:emit('TapBegan');D.sleep(.04);assert(b.mentorAim.held and not b.mentor:isDoing('groundMentorShot'),'Press fired before release');hud.weapon:emit('TapEnded');wait(function() return b.mentorHits>0 and not b.mentor:isDoing('groundMentorShot') end)
  c.toolButtons.flare:emit('TapBegan');wait(function() return b.toolAnimations.flare==1 and b.flareHits>0 end)
  c.toolButtons.smoke:emit('TapBegan');wait(function() return b.toolAnimations.smoke==1 end)
  hud.move:emit('Right',true)
  wait(function() return b.phase~='playing' and b.phase~='saving' end,40,function()return D.json.encode({phase=b.phase,hp=b.mentorHP,x=b.mentor.x,down=b.stamina.down,knockdowns=b.stamina.knockdowns,escorts=b.escortsSafe,checkpoints=b.checkpoints,tool=b.toolAnimations})end)
  assert(b.phase=='won',b.reason..' HP='..b.mentorHP..' x='..b.mentor.x)
  wait(function() return c.result end)
  for _,e in ipairs(b.escorts) do assert(e.walked>1000 and e.unit.x<=require('Ruins.Pursuit').safeX,'Escort did not walk to safety') end
  assert(story:summary().mission.unlocks['ruins-diversion-complete'])
  assert(require('Training.Progress').load() and wp.load() and D.json.encode({require('Training.Progress').adopted,wp.adopted},false,true)==models)
  if not fixture then D.Content:save(D.Path(root,'Test','pursuit-resume-fixture.txt'),db)end
  return 'PASS actualReturnRoute=true originalFiveRows=true originalHUDTools=true originalShanAssets=true physicalFlareHit=true actualShotHit=true fullToolAnimations=true actualFourEscortWalks=true actualEscapeRoute=true modelsPreserved=true report='..D.json.encode(b.report,false,true)
 end,debug.traceback)
 local report='LSD_PURSUIT_'..(ok and res or 'FAIL '..tostring(res))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
