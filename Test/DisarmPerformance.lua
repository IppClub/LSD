local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-performance-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS' and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'));local source=prior.database;local dest=D.Content.writablePath..'/lsd-disarm-practice-qa-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local function saved()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0MissionUnlocks')},false,true)end
  local before=saved();local function wait(fn,seconds)local untilAt=D.App.runningTime+(seconds or 12);while not fn()do assert(D.App.runningTime<untilAt,'Yingzhao practice timeout');D.sleep(.02)end end
  require('Training.Level')(nil,'ninilite');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  local basic=D.Director.ui3D:getChildByTag('training-controls');basic:getChildByTag('training-menu'):getChildByTag('缴械演练'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('disarm-supply-loadout')end)
  local budget=D.Director.ui3D:getChildByTag('disarm-supply-loadout');assert(budget.noteLabel.text:find('抢枪',1,true));assert(not budget.recoveryButton.visible)
  budget.closeButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  D.Director.ui3D:getChildByTag('training-controls'):getChildByTag('training-menu'):getChildByTag('缴械演练'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('disarm-supply-loadout')end)
  budget=D.Director.ui3D:getChildByTag('disarm-supply-loadout');budget.buttons[1][-1]:emit('Tapped');assert(budget.values['mentor:kinetic']==39);budget.saveButton:emit('Tapped')
  wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.patrolLevel end)
  local c=D.Platformer.Data.store.world.patrolLevel;local b=c.battle
  b.mentor:slot('Combat.WeaponState',function(event)if event.state=='returned'then assert(not b.mentor.data.weaponDisarmed,'Return event preceded state restoration')end end)
  assert(b.supplies.ledger.stock['mentor:kinetic'].remaining==39);r.budgetEntry=true;r.budgetCancel=true
  assert(b.world.tag=='VRTraining' and #b.enemies==1 and b.phase=='ready');D.sleep(.7)
  for _,e in ipairs(b.enemies)do assert(#e.guard.strikes==0 and e.enemy.playable.current=='idle')end
  local watch=D.Node();watch:addTo(b.world);local observed=false;local frames={}
  watch:schedule(function(dt)
   if b.phase=="playing" and D.App.runningTime-b.started>2 then frames[#frames+1]=dt end
   local lease=b.enemies[1].guard.lease
   if lease and lease.active and not observed and c.status.text:find('武器被夺',1,true)then
    observed=true;r.disarmObserved=true;r.disarmHint=c.status.text
    if lease.owner==b.mentor then local ok,why=b:command('shoot');assert(not ok and why=='WEAPON_DISARMED');r.disarmInputRejected=true end
   end
   return false
  end)
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  local endAt=D.App.runningTime+100;local photographed=false
  while b.phase=='playing' or b.phase=='settling' do
   assert(D.App.runningTime<endAt,'Encounter did not settle')
   if b.phase=='playing' then
    local target=b:target(b.mentor)
    if target then
     local delta=target.enemy.x-b.mentor.x
     if math.abs(delta)>420 then c.hud.move:emit(delta>0 and 'Right' or 'Left',true)
     else
      c.hud.move:emit('Right',false);c.hud.move:emit('Left',false)
      if b.mentor.faceRight~=(delta>=0)then c.hud.move:emit(delta>=0 and 'Right' or 'Left',true);D.sleep(.02);c.hud.move:emit('Right',false);c.hud.move:emit('Left',false)end
      c.hud.weapon:emit('TapBegan');D.sleep(.04);c.hud.weapon:emit('TapEnded')
     end
     c.fire:emit('TapBegan');c.wind:emit('TapBegan')
    end
   end
   D.sleep(.1)
  end
  watch:removeFromParent();assert(observed,'Public encounter never showed disarm');r.report=b.report;local trace=assert(b.report.disarmTrace);assert(trace.schemaVersion==2 and trace.trainable==false and #trace.actions>0 and #trace.weaponEvents>=2)
  local taken,returned=false,false;for _,event in ipairs(trace.weaponEvents)do if event.state=='taken'then taken=true elseif event.state=='returned'then returned=true end end
  assert(taken and returned,'Missing weapon transition');assert(D.json.decode(D.json.encode(trace)).schemaVersion==2);r.traceRecorded=true;wait(function()return trace.resourcesFinalizedAt end);assert(require('Training.ResourceEvidence').validate(trace.resources));assert(trace.virtualResult and #trace.consumption>0);assert(trace.resourceReview and not trace.resourceReviewError);assert(trace.resourceReview.total==trace.virtualResult.cost and trace.resourceReview.trainable==false);r.virtualCost=trace.virtualResult.cost;wait(function()return trace.sourceSaveState~='saving'end);assert(trace.sourceSaveState=='saved',trace.sourceSaveError);assert(trace.executionReview,trace.executionReviewError);assert(not trace.executionReview.trainable and trace.executionReview.cost+trace.executionReview.unassignedCost+trace.executionReview.stolenCost+trace.executionReview.deployment==trace.virtualResult.cost);local archived=assert(require('Training.DisarmStore').loadLatestAsync());assert(archived.id==trace.sourceId and archived.review.total==trace.virtualResult.cost);r.archivedSource=archived.id;assert(#trace.actions<100,'Repeated input polling polluted accepted actions')
  if r.disarmInputRejected then local rejected=false;for _,item in ipairs(trace.rejected)do if item.reason=='WEAPON_DISARMED'then rejected=true;assert(not item.accepted)end end;assert(rejected,'Disarmed shot missing rejection reason')end
  assert(b.phase=='won',b.reason);assert(b.mentorHits>0 and b.arena.metrics.modelActions>0 and b.wuyun.metrics.modelActions>0)
  local attacks=0;for _,e in ipairs(b.enemies)do assert(e.guard.dead);attacks=attacks+#e.guard.strikes end;assert(attacks>0);r.attacks=attacks
  assert(not b.mentor.data.weaponDisarmed);for _,a in ipairs(b.learners)do assert(not a.student.data.weaponDisarmed)end
  wait(function()return c.phase=='result'end);assert(c.result.economyMode=='virtual' and c.result.economyLabel.text:find('不扣真实物资',1,true));assert(c.result.economy.cost==b.supplies.ledger.spent);assert(saved()==before,'Practice changed saved progress')
  c.result.againButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('disarm-supply-loadout')end);budget=D.Director.ui3D:getChildByTag('disarm-supply-loadout');assert(budget.values['mentor:kinetic']==39);budget.saveButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.patrolLevel and D.Platformer.Data.store.world.patrolLevel~=c end)
  local again=D.Platformer.Data.store.world.patrolLevel;assert(again.battle.phase=='ready');again.withdraw:emit('Tapped');wait(function()return again.phase=='result'end)
  again.result.baseButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  assert(saved()==before);for _,row in ipairs(b.disarmTrace.executions)do assert(row.source=='model' or row.source=='baseline','Non-learner source entered learner execution');assert(row.outcome~='running')end;r.publicEntry=true;r.virtualScene=true;r.restart=true;r.returned=true;r.progressUnchanged=true
  table.sort(frames);assert(#frames>60);local slow=0;for _,dt in ipairs(frames)do if dt>1/30 then slow=slow+1 end end
  r.performance={frames=#frames,max=frames[#frames],p99=frames[math.ceil(#frames*.99)],over33ms=slow}
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
