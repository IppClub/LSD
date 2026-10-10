-- One Start, one earned save, original deployment/result-return between cycles.
-- No QA root cleanup, DB reload, combat-state injection, or root handler reset.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/production-return-soak-result.json'
local duration=tonumber(os.getenv('LSD_QA_PRODUCTION_SOAK_SECONDS')or'1800')
assert(duration==0 or duration>=1800 and duration<=3600)
local r={status='RUNNING',osInput=false,fullGameComplete=false,targetSeconds=duration,startExecutions=0,dbAttachments=0,qaSceneReset=false,qaRootCleanupReset=false,cycles={},stages={},scope='One-process original Train/deployment/clearance/result-return loop, scripted HUD inputs; not three-chapter or actual OS acceptance'}
local started=D.App.totalTime
local function save()r.elapsed=D.App.totalTime-started;D.Content:save(out,D.json.encode(r,false,true))end;save()
local bins,slow,weak={},{},setmetatable({},{__mode='v'})
local previousWorld,serial,frameCount,sum,max=nil,0,0,0,0
local observer=D.Node();observer:addTo(D.Director.ui)
observer:schedule(function(dt)
 frameCount=frameCount+1;sum=sum+dt;max=math.max(max,dt);local bin=math.ceil(dt*10000);bins[bin]=(bins[bin]or 0)+1
 local world=D.Platformer.Data.store.world
 if world~=previousWorld then previousWorld=world;if world then serial=serial+1;weak[serial]=world end end
 if dt>1/30 and #slow<100 then slow[#slow+1]={dt=dt,at=D.App.totalTime-started,stage=r.stage,scene=world and world.tag}end
 return false
end)
local function frames()
 local keys={};for k in pairs(bins)do keys[#keys+1]=k end;table.sort(keys)
 local count,p95,p99=0
 for _,k in ipairs(keys)do count=count+bins[k];if not p95 and count>=frameCount*.95 then p95=k/10000 end;if not p99 and count>=frameCount*.99 then p99=k/10000 end end
 return {count=frameCount,mean=sum/math.max(1,frameCount),max=max,p95=p95,p99=p99,slowFrames=slow}
end
D.thread(function()
 local ok,why=xpcall(function()
  local parent=os.getenv('LSD_QA_PARENT_RESULT')or'/private/tmp/lsd-report-snapshot-full-journey-20261009/fresh-energy-efficiency/result.json'
  local prior=D.json.decode(assert(D.Content:load(parent)),32);assert(prior.status=='PASS'and prior.sameJourney)
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-energy%-efficiency%-%d+%.db$'))
  local db=D.Path(D.Content.writablePath,'production-return-soak-'..os.time()..'.db')
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  r.dbAttachments=1;r.source=prior.database;r.database=db;r.parentResult=parent
  local E=require('Economy.Store');assert(E.open());r.balanceBefore=E.wallet().available
  local function models()return D.json.encode({D.DB:query('SELECT slot,payload FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true)end
  local original=models()
  local function world()return D.Platformer.Data.store.world end
  local function player()return D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world()end)end
  local function stage(name)r.stage=name;r.stages[#r.stages+1]={name=name,at=D.App.totalTime-started,balance=E.wallet().available};save()end
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Production loop stalled: '..tostring(r.stage));D.sleep(.02)end end
  local function hud()local h;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then h=n end end);return assert(h)end
  local function move(x)local p=assert(player());local h=hud();local side=p.unit.x<x and'Right'or'Left';h.move:emit(side,true);wait(function()return math.abs(p.unit.x-x)<35 end,45);h.move:emit(side,false);D.sleep(.3)end
  local function door(side,target)
   local old=world();move(side=='left'and 120 or side=='right'and old.sceneWidth-120 or old.center.x)
   local p=player();local index;for i=1,p.moveTargets.count do if p.moveTargets:get(i)==target then index=i end end
   assert(index and p.interaction.menu.enabled);p.interaction:emit('Tapped',index);wait(function()return world()~=old and world().tag==target and player()end);stage(target)
  end
  require('Start');r.startExecutions=1;wait(function()return world()and world().tag=='PreparationRoom'and player()and not player().busy end)
  door('left','PassageA');door('center','PassageC');door('left','Station')
  move(world().sceneWidth-1800);world():getChildByTag('boardingTerminal'):emit('Tapped',1);wait(function()return world().tag=='TrainA'and player()end)
  local function play(cycle)
   stage('cycle-'..cycle..'-train-deployment');move(world().sceneWidth-170)
   world():getChildByTag('groundDeploymentTerminal'):emit('Tapped',1);wait(function()return world().groundDeployment end)
   local deploy=world().groundDeployment
   if not deploy.formation.wuyun then deploy.view.secondCard.children.first:emit('Tapped');wait(function()return deploy.formation.wuyun end)end
   deploy.view.startButton:emit('Tapped');wait(function()return world().tag=='AbandonedCity'and world().disarmGate and player()end)
   move(4650);local gate=world().disarmGate;wait(function()return gate.menu.visible and gate.menu.menu.enabled end)
   gate.menu:emit('Tapped',1);wait(function()return gate.supplyPanel end)
   local panel=gate.supplyPanel;assert(panel.quote.total<=E.wallet().available,'Loop lacks earned budget')
   panel.saveButton:emit('Tapped');wait(function()return world().patrolLevel end)
   local c=world().patrolLevel;local b=c.battle;assert(not b.supplies.isVirtual)
   local before=E.wallet().available;stage('cycle-'..cycle..'-clearance');c.start:emit('Tapped')
   local deadline=D.App.runningTime+150
   while b.phase=='ready'or b.phase=='playing'or b.phase=='settling'do
    assert(D.App.runningTime<deadline,'Clearance stalled')
    if b.phase=='playing'then
     local target=b:target(b.mentor);local dx=target and target.enemy.x-b.mentor.x or 0;local moving=target and math.abs(dx)>420
     c.hud.move:emit('Right',moving and dx>0);c.hud.move:emit('Left',moving and dx<0)
     if target and not moving then c.hud.weapon:emit('TapBegan');D.sleep(.04);c.hud.weapon:emit('TapEnded')end
     if target then c.fire:emit('TapBegan');c.wind:emit('TapBegan')end
    end;D.sleep(.1)
   end
   wait(function()return c.phase=='result'end);assert(b.phase=='won',b.reason);assert(not E.active()and models()==original)
   assert(c.result.resultLayout=='Settlement'and E.wallet().available==before+b.report.economy.reserved+b.report.economy.net)
   local row={index=cycle,report=b.report,balance=E.wallet().available,attempt=b.supplies.attempt}
   c.result.baseButton:emit('Tapped');wait(function()return world()~=b.world and world().tag=='TrainA'and player()end)
   row.originalReturn=true;return row
  end
  repeat
   local row=play(#r.cycles+1);D.sleep(.6);collectgarbage('collect');D.sleep(.1);collectgarbage('collect')
   local retained=0;for _ in pairs(weak)do retained=retained+1 end
   row.retainedSceneWorlds=retained;row.objects=D.Object.count;row.luaRefs=D.Object.luaRefCount;row.callRefs=D.Object.callRefCount;row.luaKB=collectgarbage('count')
   r.cycles[#r.cycles+1]=row;r.frames=frames();save()
  until #r.cycles>=2 and (duration==0 or D.App.totalTime-started>=duration)
  assert(r.startExecutions==1 and r.dbAttachments==1 and not E.active()and models()==original)
  r.balanceAfter=E.wallet().available;r.status='PASS_ORIGINAL_RETURN_LOOP';r.longDurationObserved=duration>=1800;r.productionMemoryAccepted=false
 end,debug.traceback)
 observer:removeFromParent();r.frames=frames()
 if not ok then r.status='FAIL';r.error=why else r.status='PASS';r.stage='complete'end;save()
end)
