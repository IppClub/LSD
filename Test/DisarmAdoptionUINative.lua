local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-adoption-ui-result.json';local r={status='RUNNING'}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-adoption-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-adoption%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-adoption-ui-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local S=require('Training.DisarmAdoptionStore');local equal=require('Training.FlowerIdentity').equal
  assert(S.rollbackAsync('wuyun',S.state('wuyun')));assert(S.state('wuyun').current==0)
  local function wait(fn)local untilAt=D.App.runningTime+30;while not fn()do assert(D.App.runningTime<untilAt,'Adoption UI timeout');D.sleep(.02)end end
  local function snapshot()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0DisarmCandidates'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')},false,true)end
  local before=snapshot();require('Training.Level')(nil,'wuyun');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  local controls=D.Director.ui3D:getChildByTag('training-controls')
  local function open()
   controls:getChildByTag('training-menu'):getChildByTag('缴械成果'):emit('Tapped')
   wait(function()local v=D.Director.ui3D:getChildByTag('disarm-adoption');return v and not v.state.busy end)
   local v=D.Director.ui3D:getChildByTag('disarm-adoption');assert(not controls.visible);collectgarbage('collect');assert(v.state.view==v);return v.state
  end
  local p=open();assert(p.bundle and p.adopt.visible and p.view.label.text:find('基础模型',1,true));local initial=S.state('wuyun')
  p.adopt:emit('Tapped');assert(p.confirm.visible and not p.back.visible);assert(p.view.label.text:find('确认将',1,true)<100);p.cancel:emit('Tapped');assert(equal(initial,S.state('wuyun')));r.cancelPreservesSelection=true
  p.next:emit('Tapped');wait(function()return not p.busy end);assert(p.bundle);p.previous:emit('Tapped');wait(function()return not p.busy end);r.recordsNavigable=true
  assert(D.DB:exec("CREATE TRIGGER lsd.ui_write_failure BEFORE INSERT ON Game0DisarmAdoptions BEGIN SELECT RAISE(ABORT,'UI failure'); END")>=0)
  p.adopt:emit('Tapped');p.confirm:emit('Tapped');assert(p.busy);p.confirm:emit('Tapped');p.back:emit('Tapped')
  wait(function()return not p.busy end);assert(equal(initial,S.state('wuyun'))and p.view.label.text:find('保存失败',1,true));assert(not controls.visible)
  assert(D.DB:exec('DROP TRIGGER lsd.ui_write_failure')>=0);r.failedWriteRetryable=true
  p.adopt:emit('Tapped');p.confirm:emit('Tapped');wait(function()return not p.busy end)
  local current=S.state('wuyun');assert(current.current>0 and p.already and not p.adopt.visible and p.rollback.visible)
  assert(S.loadAsync('wuyun',require('Training.FlowerPractice').models(),'mission'));r.adoption=current.current;r.reviewScreenshot=D.Content.writablePath..'/disarm-adoption-review.tga';D.App:saveScreenshot(r.reviewScreenshot);D.sleep(.2)
  p.view.area:scrollToPosY(-10000,0);D.sleep(.2);r.detailScreenshot=D.Content.writablePath..'/disarm-adoption-details.tga';D.App:saveScreenshot(r.detailScreenshot);D.sleep(.2)
  p.back:emit('Tapped');assert(controls.visible and not controls.arena.closed);r.sameTrainingReturned=true
  controls:getChildByTag('training-menu'):getChildByTag('缴械演练'):emit('Tapped')
  wait(function()return D.Director.ui3D:getChildByTag('disarm-supply-loadout')end);D.Director.ui3D:getChildByTag('disarm-supply-loadout').saveButton:emit('Tapped')
  wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.patrolLevel end)
  local c=D.Platformer.Data.store.world.patrolLevel;local b=c.battle
  assert(b.disarmTrace.adoptions.wuyun.id==current.current and not b.disarmTrace.adoptions.ninilite and not b.trialCandidate and not b.demonstrator)
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  local deadline=D.App.runningTime+100
  while b.phase=='playing'or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Adopted practice timeout')
   if b.phase=='playing'then
    local enemy=b:target(b.mentor)
    if enemy then local dx=enemy.enemy.x-b.mentor.x
     if math.abs(dx)>420 then c.hud.move:emit(dx>0 and 'Right'or'Left',true)
     else c.hud.move:emit('Right',false);c.hud.move:emit('Left',false);c.hud.weapon:emit('TapBegan');D.sleep(.04);c.hud.weapon:emit('TapEnded')end
     c.fire:emit('TapBegan');c.wind:emit('TapBegan')
    end
   end
   D.sleep(.1)
  end
  wait(function()return c.phase=='result'end);assert(b.phase=='won',b.reason)
  local archived=assert(require('Training.DisarmStore').loadLatestAsync());local t=archived.source.trace
  assert(t.adoptions.wuyun.id==current.current and #t.adoptionDecisions>0 and not t.candidate and not t.demonstrator)
  local count=0;for _,step in ipairs(t.executions)do if step.actor=='wuyun'then assert(step.source=='adopted-disarm');count=count+1 end end;assert(count>0)
  assert(#assert(require('Training.DisarmPolicy').inspect({archived},'wuyun')).samples==0)
  assert(require('Training.DisarmCredit').rebuild(t));r.deployment={executions=count,decisions=#t.adoptionDecisions,status=b.phase,cost=t.virtualResult.cost}
  c.result.baseButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end);controls=D.Director.ui3D:getChildByTag('training-controls')
  p=open();p.rollback:emit('Tapped');p.cancel:emit('Tapped');assert(S.state('wuyun').current==current.current)
  p.rollback:emit('Tapped');p.confirm:emit('Tapped');wait(function()return not p.busy end);assert(S.state('wuyun').current==0);p.back:emit('Tapped')
  controls:getChildByTag('training-menu'):getChildByTag('缴械演练'):emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('disarm-supply-loadout')end);D.Director.ui3D:getChildByTag('disarm-supply-loadout').saveButton:emit('Tapped')
  wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.patrolLevel and D.Platformer.Data.store.world.patrolLevel~=c end)
  local retry=D.Platformer.Data.store.world.patrolLevel;assert(next(retry.battle.disarmTrace.adoptions)==nil);retry.withdraw:emit('Tapped');wait(function()return retry.phase=='result'end)
  retry.result.baseButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end);controls=D.Director.ui3D:getChildByTag('training-controls')
  p=open();p.next:emit('Tapped');wait(function()return not p.busy end);p.next:emit('Tapped');wait(function()return not p.busy end)
  assert(not p.bundle and not p.adopt.visible and p.view.label.text:find('规则已变化',1,true));p.back:emit('Tapped');r.historicalReadOnly=true
  controls:getChildByTag('training-switch'):emit('Tapped');wait(function()local v=D.Director.ui3D:getChildByTag('training-controls');return v and v.arena.character.id=='ninilite'end);controls=D.Director.ui3D:getChildByTag('training-controls')
  p=open();assert(#p.ids==0 and not p.adopt.visible and not p.rollback.visible and p.view.label.text:find('尚无',1,true));p.back:emit('Tapped');r.otherLearnerEmpty=true
  assert(snapshot()==before);r.rollbackAffectsNextPractice=true;r.originalTrainingUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
