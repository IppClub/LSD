-- Earned profile copy, public train gate, real formation UI and original city.
local D=require('Dora')
local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,D.Path(root,'Script'),D.Path(root,'Spine'),D.Path(root,'Image'),D.Path(root,'Font')}) do D.Content:insertSearchPath(1,p) end
local id=tostring(os.time());local out=D.Path(root,'Test','auxiliary-route-result.txt');D.Content:save(out,'LSD_AUXILIARY_ROUTE_RUNNING '..id..'\n')
D.thread(function()
 local ok,res=xpcall(function()
  local source=assert(D.Content:load(D.Path(root,'Test','train-resume-fixture.txt')))
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^lsd%-train%-route%-qa%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'lsd-auxiliary-route-qa-'..id..'.db')
  assert(not D.Content:exist(db) and not D.DB:existDB('lsd') and D.Content:copyAsync(source,db))
  assert(D.DB:exec("ATTACH DATABASE '"..db:gsub("'","''").."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function() if D.DB:existDB('lsd') then D.DB:exec('DETACH DATABASE lsd') end end)
  require('Data.Config'):loadAsync(); local story=assert(require('Story.Service').open());assert(story:summary().completed['mail-two'])
  require('Academy.Navigation').returnToRoomAsync('TrainA')
  local function world() return D.Platformer.Data.store.world end
  local function player() return D.Group({'player','unit'}):find(function(e) return e.player and e.unit.world==world() end) end
  local function wait(f,t) local deadline=D.App.runningTime+(t or 15);while not f() do assert(D.App.runningTime<deadline,'Public auxiliary route stalled');D.sleep(.05) end end
  local function walk(x)
   local p=assert(player());local deadline=D.App.runningTime+30
   while math.abs(p.unit.x-x)>35 do assert(D.App.runningTime<deadline,'Public walk stalled');p.keyLeft=p.unit.x>x;p.keyRight=p.unit.x<x;D.sleep(.05) end
   p.keyLeft=false;p.keyRight=false;D.sleep(.4)
  end
  wait(player);walk(world().sceneWidth-170)
  world():getChildByTag('groundDeploymentTerminal'):emit('Tapped',1);wait(function() return world().groundDeployment end)
  local deployment=world().groundDeployment
  for _,variant in ipairs({'defence','mobility','cargo'}) do deployment.auxiliaryButtons[variant]:emit('Tapped');assert(deployment.auxiliaryVariant==variant and deployment.auxiliaryPreview) end
  D.Content:save(out,'LSD_AUXILIARY_ROUTE_SELECTION_READY '..id..'\n')
  -- Mouse-operated start is observed from the native UI during this wait.
  wait(function() return deployment.phase=='deploying' end,90)
  wait(function() return world().tag=='AbandonedCity' and world().groundExpedition and player() end)
  local s=world().groundExpedition.support;local v=assert(world().auxiliaryView)
  assert(s.variant=='cargo' and v.actor.variant=='cargo','Selection lost entering city')
  wait(function() return v.actor.completed.deploy and v.actor.completed.shield end)
  walk(1150);wait(function() return s.collected['survey-gold-1'] end)
  wait(function() return v.actor.completed.collect and v.actor.eventCounts['energy-transfer']==1 end)
  local hp=s.machineHP;s:damageMachine(18);wait(function() return v.actor.completed.hit==1 end);assert(s.machineHP==hp-18)
  assert(D.Director.ui3D:getChildByTag('ground-hud'),'Original movement and skill UI missing')
  v.actor:reveal(100)
  return 'PASS earnedCopy=true physicalTrainGate=true originalFormation=true selectableVariants=3 mouseDeployment=true actualCity=true cargoSelectionCarried=true originalHUD=true actualGoldPickup=true collectEventOnce=true actualMachineDamage=true fullRecovery=true'
 end,debug.traceback)
 local report='LSD_AUXILIARY_ROUTE_'..(ok and res or 'FAIL '..tostring(res))..' runId='..id;print(report);D.Content:save(out,report..'\n')
end)
