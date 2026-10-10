local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
D.thread(function()
 local r={status='RUNNING',stage='SETUP',osInput=true,diagnosticObserver=true,setupScripted=true,combatScripted=false,defaultAppBootstrap=false,fullGameComplete=false,events={},samples={}}
 local function save()D.Content:save(root..'/Test/os-current-pursuit-result.json',D.json.encode(r,false,true))end;save()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load('/private/tmp/lsd-ambush-warning-ruins-route-20261008/result.json'),32);assert(prior.status=='PASS' and prior.stage=='valley-arrival')
  local db=D.Path(D.Content.writablePath,'os-current-pursuit-'..os.time()..'.db');assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.source=prior.database;r.database=db;save()
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  require('Data.Config'):loadAsync();local S=assert(require('Mission.Service').open());assert(S:recoverAsync());local E=require('Economy.Store');assert(E.open()and not E.active());r.balanceBefore=E.wallet().available
  local models=D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true)
  local node=D.Node();node.keyboardEnabled=true;node:addTo(D.Director.ui)
  for _,kind in ipairs({'KeyDown','KeyUp'})do node:slot(kind,function(key)r.events[#r.events+1]={kind=kind,key=key,at=D.App.runningTime,stage=r.stage};save()end)end
  local c;local p=assert(require('Economy.Preparation').openAsync('c0-m06',nil,nil,function(service,attempt)c=require('Ruins.PursuitLevel').openAsync(service,attempt)end))
  for i,key in ipairs({'mentor:kinetic','mentor:smoke','mentor:flare'})do local target=({4,6,2})[i];while p.values[key]~=target do p.buttons[i][p.values[key]<target and 1 or -1]:emit('Tapped')end end
  assert(p.quote.total==62);r.stage='READY_FOR_OS_BUDGET_CONFIRM';save()
  local function wait(fn,t)local untilAt=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<untilAt,'OS pursuit wait at '..r.stage);D.sleep(.05)end end
  wait(function()return c end,300);r.stage='ACTUAL_OS_COMBAT';save();local b=c.battle;local last=0
  r.aimEvents={}
  for _,name in ipairs({'Skill.Began','Skill.Ended'})do node:gslot(name,function(cancelled)
   if b.phase~='playing' or not b.mentor.parent or not b.mentor.playable then return end
   local aim=b.mentorAim;r.aimEvents[#r.aimEvents+1]={name=name,at=D.App.runningTime-b.started,cancelled=cancelled,held=aim.held,shot=aim.shot,canStart=aim.canStart(),onSurface=b.mentor.onSurface,staminaDown=b.stamina.down,clip=b.mentor.playable.current};save()
  end)end
  while b.phase=='playing' or b.phase=='saving'do
   local aim=b.mentorAim
   local enemies={};for _,e in ipairs(b.enemies)do enemies[#enemies+1]={asset=e.asset,x=e.unit.x,hp=e.hp,busy=e.busy,untargetable=e.untargetable}end
   local sample={at=D.App.runningTime-b.started,x=b.mentor.x,hp=b.mentorHP,vx=b.mentor.velocityX,clip=b.mentor.playable.current,phase=b.phase,ammo=b.supplies.ledger.stock['mentor:kinetic'].remaining,escorts=b.escortsSafe,shotHits=b.mentorHits,flareHits=b.flareHits,toolUses={smoke=b.toolUses.smoke,flare=b.toolUses.flare},keyD=D.Keyboard:isKeyPressed('D'),keyJ=D.Keyboard:isKeyPressed('J'),keyE=D.Keyboard:isKeyPressed('E'),keyL=D.Keyboard:isKeyPressed('L'),aimHeld=aim and aim.held,aimShot=aim and aim.shot,aimCanStart=aim and aim.canStart(),onSurface=b.mentor.onSurface,faceRight=b.mentor.faceRight,stamina=b.stamina.value,staminaDown=b.stamina.down,shotAction=b.mentor:isDoing('groundMentorShot'),toolAction=b.mentor:isDoing('pursuitTool'),enemies=enemies}
   r.samples[#r.samples+1]=sample;r.current=sample
   if D.App.runningTime-last>1 then last=D.App.runningTime;save()end;D.sleep(.1)
  end
  wait(function()return c.result end);r.outcome=b.phase;r.report=b.report;r.resultLayout=c.result.resultLayout;r.balanceAfter=E.wallet().available;r.stage='READY_FOR_OS_RESULT_RETURN'
  assert(b.phase=='won' or b.phase=='failed' or b.phase=='aborted');assert(not E.active()and r.balanceAfter==r.balanceBefore+b.report.economy.net)
  assert(c.result.resultLayout==(b.phase=='won'and'Settlement'or'MissionFail'));save()
  local target=b.phase=='won'and'OuterHeaven'or'AbandonedCity';wait(function()local w=D.Platformer.Data.store.world;return w and w~=b.world and w.tag==target end,300)
  r.returnScene=D.Platformer.Data.store.world.tag
  assert(models==D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true));r.modelsUnchanged=true
  local down,up;for _,e in ipairs(r.events)do if e.stage=='ACTUAL_OS_COMBAT'and e.key=='J'then if e.kind=='KeyDown'then down=true elseif down and e.kind=='KeyUp'then up=true end end end
  assert(down and up and b.report.economy.lines[1].used>0,'Missing real combat J down/up and paid firing');r.actualPaidKeyFire=true;r.stage='RETURNED';node:removeFromParent()
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and tostring(err)or nil;save()
end)
