-- Earned energy journey branch, physical public route, no HP/unlock/model injection.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/fresh-disarm-current-result.json'
local r={status='RUNNING',osInput=false,stages={}};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local prior=D.json.decode(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or root..'/Test/fresh-energy-efficiency-result.json'),32)
  assert(prior.status=='PASS'and prior.sameJourney and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-energy%-efficiency%-%d+%.db$'))
  local db=D.Content.writablePath..'/fresh-disarm-current-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and not D.Content:exist(db)and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  r.database=db;r.source=prior.database
  local E=require('Economy.Store');assert(E.open());r.balanceBefore=E.wallet().available;assert(r.balanceBefore==prior.balance)
  local S=assert(require('Mission.Service').open());assert(not S:summary().unlocks['yingzhao-route-cleared'])
  local function models()return D.json.encode({D.DB:query('SELECT slot,payload FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true)end
  local original=models()
  local function stage(name)r.stage=name;r.stages[#r.stages+1]={name=name,at=D.App.runningTime,balance=E.wallet().available};save()end
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Disarm journey stalled at '..tostring(r.stage));D.sleep(.02)end end
  local function world()return D.Platformer.Data.store.world end
  local function player()return D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world()end)end
  local function hud()local h;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then h=n end end);return assert(h)end
  local function move(x)local p=player();local h=hud();local side=p.unit.x<x and 'Right'or'Left';h.move:emit(side,true);wait(function()return math.abs(p.unit.x-x)<35 end,45);h.move:emit(side,false);D.sleep(.3)end
  local function door(side,target)
   local old=world();move(side=='left'and 120 or side=='right'and old.sceneWidth-120 or old.center.x)
   local p=player();local index;for i=1,p.moveTargets.count do if p.moveTargets:get(i)==target then index=i end end
   assert(index and p.interaction.menu.enabled,'Missing public route '..target);p.interaction:emit('Tapped',index)
   wait(function()return world()~=old and world().tag==target end);D.sleep(.3);stage(target)
  end
  require('Start');wait(function()return world()and world().tag=='PreparationRoom'and player()and not player().busy end);stage('resumed')
  door('left','PassageA');door('center','PassageC');door('left','Station')
  move(world().sceneWidth-1800);world():getChildByTag('boardingTerminal'):emit('Tapped',1)
  wait(function()return world().tag=='TrainA'end);move(world().sceneWidth-170)
  world():getChildByTag('groundDeploymentTerminal'):emit('Tapped',1);wait(function()return world().groundDeployment end)
  local deployment=world().groundDeployment;assert(deployment.team and deployment.view.secondCard)
  if not deployment.formation.wuyun then deployment.view.secondCard.children.first:emit('Tapped');wait(function()return deployment.formation.wuyun end)end
  deployment.view.startButton:emit('Tapped');wait(function()return world().tag=='AbandonedCity'and world().energySquad and world().disarmGate end)
  move(4650);local gate=world().disarmGate;wait(function()return gate.menu.visible and gate.menu.menu.enabled end);stage('public-disarm-site')
  gate.menu:emit('Tapped',2);D.sleep(.2);assert(not gate.supplyPanel and gate.label.text:find('先完成',1,true)and not E.active()and E.wallet().available==r.balanceBefore);r.bossLockedNoCharge=true
  gate.menu:emit('Tapped',1);wait(function()return gate.supplyPanel end);gate.supplyPanel.closeButton:emit('Tapped');wait(function()return not gate.supplyPanel and gate.menu.visible and gate.menu.menu.enabled end);D.sleep(.25)
  assert(not E.active()and E.wallet().available==r.balanceBefore);r.cancelNoCharge=true
  local expeditionSupport=assert(world().groundExpedition.support)
  gate.menu:emit('Tapped',1);wait(function()return gate.supplyPanel end)
  local panel=gate.supplyPanel;assert(panel.quote.total<=E.wallet().available);r.budget=panel.quote.total;panel.saveButton:emit('Tapped')
  wait(function()return world().patrolLevel end);local level=world().patrolLevel;local b=level.battle
  assert(not b.supplies.isVirtual and b.disarmTrace.kind=='disarm-mission')
  assert(b.support==expeditionSupport and b.machine and b.supportView.actor.variant==expeditionSupport.variant)
  local beforeGold,beforeSpent=b.support.gold,b.support.spent;D.sleep(.6);assert(b.support.gold==beforeGold,'Ready clearance drained support')
  r.supportBefore={gold=beforeGold,spent=beforeSpent,machineHP=b.support.machineHP}
  D.App:saveScreenshot(root..'/Test/disarm-support-ready.tga');D.sleep(.2);r.screenshot=root..'/Test/disarm-support-ready.tga'
  if os.getenv('LSD_QA_CAPTURE_CLEARANCE')=='1'then
   local originalSize=D.App.winSize;r.readabilityLayouts={}
   for _,size in ipairs({D.Size(1280,720),D.Size(960,540),D.Size(683,384)})do
    D.App.winSize=size;D.sleep(.3)
    local path=D.Content.writablePath..'/clearance-ready-'..math.floor(D.App.bufferSize.width)..'.tga'
    r.readabilityLayouts[#r.readabilityLayouts+1]={path=path,buffer={width=D.App.bufferSize.width,height=D.App.bufferSize.height},headerHeight=level.headerHeight,labelHeight=level.status.height,labelWidth=level.status.width,textWidth=level.status.textWidth,text=level.status.text}
    assert(level.status.width<=level.status.textWidth+.1,'Clearance status exceeds width')
    assert(level.headerHeight>=level.status.height+49.9,'Clearance status outside header')
    D.App:saveScreenshot(path);D.sleep(.05)
   end
   D.App.winSize=os.getenv('LSD_QA_CLEARANCE_WINDOW')=='small'and D.Size(683,384)or originalSize;D.sleep(.3);save()
  end
  stage('disarm-ready');level.start:emit('Tapped')
  local deadline=D.App.runningTime+150
  while b.phase=='ready'or b.phase=='playing'or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Natural disarm battle stalled')
   if b.phase=='playing'then
    if os.getenv('LSD_QA_CAPTURE_CLEARANCE')=='1'and not r.readability and b.enemies[1].enemyHP<=120 then
     local path=D.Content.writablePath..'/clearance-active.tga'
     r.readability={path=path,headerHeight=level.headerHeight,labelHeight=level.status.height,text=level.status.text,buffer={width=D.App.bufferSize.width,height=D.App.bufferSize.height},camera={x=b.world.camera.position.x,y=b.world.camera.position.y,zoom=b.world.camera.zoom},actors={mentor={x=b.mentor.x,y=b.mentor.y},ninilite={x=b.arena.student.x,y=b.arena.student.y},wuyun={x=b.wuyun.student.x,y=b.wuyun.student.y},enemy={x=b.enemies[1].enemy.x,y=b.enemies[1].enemy.y,hp=b.enemies[1].enemyHP}}}
     if b.cameraFrame then
      r.readability.cameraFrame=D.json.decode(D.json.encode(b.cameraFrame,false,true),32)
      r.readability.enemyScale={x=b.enemies[1].enemy.playable.scaleX,y=b.enemies[1].enemy.playable.scaleY}
      assert(r.readability.enemyScale.x==1 and r.readability.enemyScale.y==1,'Camera resized original enemy model')
     end
     if level.playerMarker then
      local m=level.playerMarker
      assert(m.owner==b.mentor and m.node.visible and m.label.text=='导师','Controlled mentor marker not visible')
      assert(m.projection and D.App.runningTime-m.projection.at<.2,'Controlled mentor marker projection stale')
      assert(math.abs(m.hpBar.scaleX-b.mentorHP/100)<.001,'Original life bar does not match mentor')
      r.readability.playerMarker={x=m.node.x,y=m.node.y,visible=m.node.visible,hpFraction=m.hpBar.scaleX,projection=m.projection}
     end
     r.readability.projections={}
     for name,u in pairs({mentor=b.mentor,ninilite=b.arena.student,wuyun=b.wuyun.student,enemy=b.enemies[1].enemy})do
      local name,u=name,u;local layer=u.parent
      local sample={order=u.order,parentOrder=layer.order,parentPosition={x=layer.x,y=layer.y},layerOffset={x=b.world:getLayerOffset(u.order).x,y=b.world:getLayerOffset(u.order).y}}
      r.readability.projections[name]=sample
      u:convertToWindowSpace(D.Vec2.zero,function(point)sample.center={x=point.x,y=point.y};save()end)
     end
     D.App:saveScreenshot(path);save()
    end
    local target=b:target(b.mentor);local dx=target and target.enemy.x-b.mentor.x or 0
    local moving=target and math.abs(dx)>420
    level.hud.move:emit('Right',moving and dx>0);level.hud.move:emit('Left',moving and dx<0)
    if target and not moving then level.hud.weapon:emit('TapBegan');D.sleep(.04);level.hud.weapon:emit('TapEnded')end
    if target then level.fire:emit('TapBegan');level.wind:emit('TapBegan')end
   end;D.sleep(.1)
  end
  r.battle=b.report;r.outcome=b.phase;r.supportAfter=b.report.auxiliary;assert(b.report.auxiliary and b.report.auxiliary.spent>beforeSpent,'Clearance did not run finite support');save();assert(b.phase=='won',b.reason)
  wait(function()return level.phase=='result'end);assert(level.result.resultLayout=='Settlement'and not E.active())
  if level.playerMarker then assert(level.playerMarker.closed,'Player marker retained after settlement');r.playerMarkerClosed=true end
  assert(E.wallet().available==r.balanceBefore+b.report.economy.net and S:summary().unlocks['yingzhao-route-cleared'])
  assert(models()==original,'Optional clearance changed adopted models')
  local attempt=tonumber(b.supplies.attempt:match('(%d+)$'));local episode=assert(require('Training.CombatStore').load(attempt));assert(episode.disarm.status=='won')
  r.balanceAfter=E.wallet().available;r.episodeSaved=true;r.sameJourneyBranch=true;stage('natural-clearance-won')
  level.result.baseButton:emit('Tapped');wait(function()return world()~=b.world and world().tag=='TrainA'end)
  r.returnedToTrain=true;r.stage='clearance-returned'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save();print('LSD_FRESH_DISARM_CURRENT_'..r.status)
end)
