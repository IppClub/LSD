local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-candidate-trial-result.json';local r={status='RUNNING',cases={}}
D.Content:save(out,D.json.encode(r,false,true))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-demonstration-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-demo%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-candidate-trial-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn)local stop=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<stop,'Candidate trial timeout');D.sleep(.02)end end
  local function saved()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0DisarmCandidates')},false,true)end
  local before=saved()
  for _,id in ipairs({'ninilite','wuyun'})do
   local candidate=assert(require('Training.DisarmPolicyStore').loadLatestAsync(id))
   require('Training.Level')(nil,id);wait(function()local v=D.Director.ui3D:getChildByTag('training-controls');return v and v.arena.character.id==id end)
   D.Director.ui3D:getChildByTag('training-controls'):getChildByTag('training-menu'):getChildByTag('缴械试战'):emit('Tapped')
   wait(function()return D.Director.ui3D:getChildByTag('disarm-supply-loadout')end)
   local budget=D.Director.ui3D:getChildByTag('disarm-supply-loadout');assert(budget.noteLabel.text:find('缴械候选',1,true));budget.saveButton:emit('Tapped')
   wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.patrolLevel end)
   local c=D.Platformer.Data.store.world.patrolLevel;local b=c.battle
   assert(b.trialCandidate.id==candidate.id and b.candidateArena.character.id==id and not b.demonstrator)
   c.start:emit('Tapped');wait(function()return b.phase=='playing'end)
   local deadline=D.App.runningTime+100;local screenshot
   while b.phase=='playing'or b.phase=='settling'do
    assert(D.App.runningTime<deadline,'Trial did not finish')
    if b.phase=='playing'then
     local enemy=b:target(b.mentor)
     if enemy then
      local dx=enemy.enemy.x-b.mentor.x
      if math.abs(dx)>420 then c.hud.move:emit(dx>0 and 'Right'or'Left',true)
      else c.hud.move:emit('Right',false);c.hud.move:emit('Left',false);c.hud.weapon:emit('TapBegan');D.sleep(.04);c.hud.weapon:emit('TapEnded')end
      c.fire:emit('TapBegan');c.wind:emit('TapBegan')
     end
     if not screenshot and D.App.runningTime-b.started>3 then screenshot=D.Content.writablePath..'/candidate-'..id..'.tga';D.App:saveScreenshot(screenshot)end
    end
    D.sleep(.1)
   end
   wait(function()return c.phase=='result'end)
   assert(b.phase=='won',b.reason);assert(b.disarmTrace.sourceSaveState=='saved')
   local archived=assert(require('Training.DisarmStore').loadLatestAsync());local t=archived.source.trace
   assert(t.candidate.id==candidate.id and #t.candidateDecisions>3 and not t.demonstrator)
   local executed=0;for _,step in ipairs(t.executions)do if step.actor==id then assert(step.source=='candidate');executed=executed+1 end end;assert(executed>0)
   assert(#assert(require('Training.DisarmPolicy').inspect({archived},id)).samples==0,'Candidate behavior became a demonstration')
   assert(require('Training.FlowerIdentity').equal(t.candidate.model,candidate.model));assert(saved()==before)
   r.cases[#r.cases+1]={character=id,candidate=candidate.id,status=b.phase,decisions=#t.candidateDecisions,executions=executed,cost=t.virtualResult.cost,seconds=b.report.seconds,screenshot=screenshot}
   c.result.againButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('disarm-supply-loadout')end);D.Director.ui3D:getChildByTag('disarm-supply-loadout').saveButton:emit('Tapped')
   wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.patrolLevel and D.Platformer.Data.store.world.patrolLevel~=c end)
   local retry=D.Platformer.Data.store.world.patrolLevel;assert(retry.battle.trialCandidate.id==candidate.id);retry.withdraw:emit('Tapped');wait(function()return retry.phase=='result'end)
   retry.result.baseButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
  end
  assert(saved()==before);r.savedModelsUnchanged=true;r.retryFrozen=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
