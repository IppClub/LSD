-- Player-facing hold/release events; disposable QA save and real native bullets.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/flower-aim-native-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={shots={}};local ok,err=xpcall(function()
  local source=D.Content.writablePath..'/lsd-medical-visit-qa-1791007987.db';local dest=D.Content.writablePath..'/flower-aim-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local c=require('Training.FlowerPractice').openAsync(nil,'ninilite');local b=c.battle;local a=c.arena;local combat=b.partCombat
  local function wait(fn,seconds)local endAt=D.App.totalTime+(seconds or 6);while not fn()do assert(D.App.totalTime<endAt,'Aim timeout');D.sleep(.01)end end
  D.sleep(.5);c.startButton:emit('Tapped')
  -- Pose fixture only: no arbitrary HP changes or simulated hit records.
  for _,e in ipairs(b.roots)do e.enemyCombat:close()end
  for i=1,2 do b.roots[i].enemy.x=6000 end
  local command=b.command;b.command=function(self,action)if action=='shoot'then return false end;return command(self,action)end
  a.student.x=1200;b.wuyun.student.x=900;b.mentor.x=950;a.student.faceRight=true
  local function demos()local n=0;for _,s in ipairs(combat.journal.steps)do if s.action.actor=='ninilite' and s.action.name=='shoot'then n=n+1 end end;return n end
  local function fire(hold)
   wait(function()return a:available('laser') and not c.aim.shot end)
   local before=demos();c.hud.weapon:emit('TapBegan');assert(c.aim.held and c.aim.line.visible)
   D.sleep(hold);assert(demos()==before,'Holding fired before release')
   local angle=hold<=.15 and 0 or c.aim.angle
   c.hud.weapon:emit('TapEnded');assert(not c.aim.held and not c.aim.line.visible)
   wait(function()return demos()>before end)
   local step;for _,s in ipairs(combat.journal.steps)do if s.action.actor=='ninilite' and s.action.name=='shoot'then step=s end end
   wait(function()return step.sealed and (step.action.emitted or 0)>0 end)
   local action=step.action
   assert(action.aimSource=='manual-sweep-v1' and math.abs(action.aimAngle-angle)<.01 and action.aimAt>=step.started)
   local actual=-math.deg(math.atan(action.velocity.y,math.abs(action.velocity.x)))
   assert(math.abs(actual-angle)<.02,'Actual bullet did not follow chosen angle')
   r.shots[#r.shots+1]={angle=angle,velocityAngle=actual,intendedPart=action.intendedPart,aimStatus=action.aimStatus,hits=step.hits}
   return step
  end
  fire(.03);fire(.35);fire(.43);fire(.47);fire(.03);fire(.35)
  wait(function()return a:available('laser') and not c.aim.shot end)
  local before=demos();c.hud.weapon:emit('TapBegan');D.sleep(.2);c.aim:cancel();c.hud.weapon:emit('TapEnded');D.sleep(.2)
  assert(demos()==before and not c.aim.line.visible);r.cancel=true
  c.finishButton:emit('Tapped');wait(function()return c.result end)
  local episode=c.result.episode;assert(require('Training.CombatStore').validate(episode))
  local saved=assert(require('Training.FlowerPracticeStore').latest('ninilite'));assert(saved.episode.episode==episode.episode)
  local shot;for _,s in ipairs(episode.steps)do if s.action.aimSource then shot=s;break end end
  assert(shot);local invalid=D.json.decode(D.json.encode(episode),32);invalid.steps[shot.id].action.aimAngle=90;assert(not require('Training.CombatStore').validate(invalid))
  invalid=D.json.decode(D.json.encode(episode),32);invalid.steps[shot.id].action.aimStatus='boss';invalid.steps[shot.id].action.intendedPart='invented';assert(not require('Training.CombatStore').validate(invalid))
  r.persisted=true;r.invalidRejected=true
  local P=require('Training.FlowerPolicy');local model,why=P.buildAsync({episode},'ninilite');assert(model,why)
  assert(model.actionSetVersion==5 and P.validate(model))
  local oldVersion=D.json.decode(D.json.encode(model),32);oldVersion.actionSetVersion=4;assert(not P.validate(oldVersion),'Target actions accepted as legacy version')
  local targeted=false;for _,rule in ipairs(model.rules)do if select(2,P.decodeAction(rule.action))then targeted=true end end;assert(targeted,'C4.5 discarded target intention')
  local evidence=assert(require('Training.FlowerEvidence').make(model,{episode}));assert(require('Training.FlowerEvidence').verifyAsync(evidence))
  r.model={samples=model.sampleCount,version=model.actionSetVersion,rules=model.rules};r.rebuilt=true
  local nextC=require('Training.FlowerPractice').openAsync(nil,'ninilite');local nextB=nextC.battle;local nextA=nextC.arena
  nextC.candidate=model
  for _,e in ipairs(nextB.roots)do e.enemyCombat:close()end;for i=1,2 do nextB.roots[i].enemy.x=6000 end
  nextA.student.x=1200;nextB.wuyun.student.x=900;nextB.mentor.x=950;nextA.student.faceRight=false;nextB.roots[3].enemy.faceRight=false
  local nextCommand=nextB.command;nextB.command=function(self,action)if action=='shoot'then return false end;return nextCommand(self,action)end
  D.sleep(.3);assert(nextC:start(true))
  local targetStep
  wait(function()
   for _,step in ipairs(nextB.partCombat.journal.steps)do if step.action.actor=='ninilite' and step.action.aimSource=='part-policy-v1' and (step.action.emitted or 0)>0 and step.sealed then targetStep=step;return true end end
  end,12)
  assert(targetStep.action.intendedPart~='unknown' and #targetStep.hits>0,'Learned aim did not produce a native contact')
  r.executed={intendedPart=targetStep.action.intendedPart,angle=targetStep.action.aimAngle,hits=targetStep.hits}
  -- Isolated execution fixtures: a committed shot must survive target motion
  -- and new cover, while collision still blocks it. No outcomes are fabricated.
  nextC.nextDecision=math.huge
  for _,learner in ipairs(nextB.learners)do learner.nextDecision=math.huge end
  local pc=nextB.partCombat;local boss=nextB.roots[3].enemy
  local function ready()
   wait(function()return nextA:available('laser') and next(pc.shots)==nil end)
   nextA.student:stop();nextA.student.x=1200;nextA.student.faceRight=true
   D.sleep(.1)
  end
  local function policy()
   for _,part in ipairs({'petal-left','flower-core','roots','flower-head','petal-right'})do
    local ray=pc:aim(nextA.student,part,true,true)
    if ray then local p=D.json.decode(D.json.encode(model),32);p.rules={{conditions={},action='shoot@'..part}};return p,ray end
   end
   error('No reachable part for commitment fixture')
  end
  local function selectShot(p)
   assert(require('Training.FlowerController').step(nextB,nextA,p))
   local step=pc.journal.steps[pc.aimSteps.ninilite]
   assert(step and step.action.aimCommit==1 and not step.action.emitted)
   assert(not nextA.flowerTargetAim and not nextA.flowerTargetPart)
   return step
  end
  local function verifyEmission(step)
   wait(function()return step.sealed and (step.action.emitted or 0)>0 end)
   local action=step.action
   assert(action.emitted==1 and not action.shotRejected and #step.hits==0)
   assert(math.abs(-math.deg(math.atan(action.velocity.y,math.abs(action.velocity.x)))-action.aimAngle)<.02)
   return {angle=action.aimAngle,emitted=action.emitted,hits=#step.hits,committedAt=action.aimCommittedAt}
  end
  ready();local p,ray=policy();local step=selectShot(p)
  local position=boss.position;boss.position=position+D.Vec2(0,3000)
  r.committedMovingMiss=verifyEmission(step);boss.position=position;boss.velocityY=0
  ready();p,ray=policy();step=selectShot(p)
  local def=D.BodyDef();def.type='Static';def:attachPolygon(10,1600,1,0,0)
  local wall=D.Body(def,nextA.world,D.Vec2(ray.origin.x+60,nextA.student.y));wall.group=D.Platformer.Data.groupTerrain;wall:addTo(nextA.world)
  r.committedTerrain=verifyEmission(step)
  ready();local count=#pc.journal.steps
  require('Training.FlowerController').step(nextB,nextA,p)
  for i=count+1,#pc.journal.steps do assert(pc.journal.steps[i].action.name~='shoot','Initially blocked aim was accepted')end
  r.initialCoverRejected=true;wall:removeFromParent()
  nextC:finish();wait(function()return nextC.result end)
  assert(require('Training.CombatStore').validate(nextC.result.episode));assert(nextC.trialRecord and nextC.trialRecord.policy.actionSetVersion==5)
  assert(nextC.trialRecord.setup.aimPolicy==pc.aimPolicy)
  local forged=D.json.decode(D.json.encode(nextC.result.episode),32)
  forged.steps[step.id].action.aimCommittedAt=forged.steps[step.id].started+1
  local valid,reason=require('Training.CombatStore').validate(forged)
  assert(not valid and reason=='INVALID_AIM_COMMIT');r.invalidCommitRejected=true
  r.trialPersisted=true

 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
