local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
D.thread(function()
 local r={status='RUNNING',cases={},scope='Native ambush warning interruption and normal-HP backstep; controlled battle, no formal settlement',osInput=false,formalMissionAccepted=false}
 local function save()D.Content:save(root..'/Test/ambush-warning-cancel-result.json',D.json.encode(r))end;save()
 local ok,err=xpcall(function()
  local B=require('Ruins.Pursuit')
  local function wait(f)local untilAt=D.App.runningTime+8;while not f()do assert(D.App.runningTime<untilAt,'Timeout');D.sleep(.01)end end
  for _,kind in ipairs({'cancel','finish','stun','defeat'})do
   local b=B.createAsync({finishAsync=function()return true end},{mission='c0-m06'})
   for _,actor in ipairs(b.enemies)do actor.nextAttack=math.huge end
   wait(function()return b.mentor.onSurface end)
   local e=b.enemies[1];assert(b:enemyStrike(e,B.attackSpecs.dashanxiao[4]));local strike=e.strikes[#e.strikes]
   assert(#strike.stages==0 and not e.untargetable and e.unit.group==2)
   D.sleep(.2)
   if kind=='cancel'then assert(e.attackSequence:cancel('QA_WARNING_CANCEL'))
   elseif kind=='finish'then b:finish('aborted','QA_WARNING')
   elseif kind=='stun'then e.stunUntil=D.App.runningTime+3
   else e.hp=0 end
   wait(function()return not e.busy end);e.nextAttack=math.huge;D.sleep(2.5)
   assert(strike.cancelled and #strike.stages==0 and #strike.impacts==0 and strike.hits==0)
   assert(strike.portal.closed and not strike.warning.parent and not b.ambushActive and not e.untargetable and e.unit.group==2)
   assert(b.mentorHP==100)
   r.cases[#r.cases+1]={kind=kind,cancelled=strike.cancelled,stages=#strike.stages,hits=strike.hits};save()
   if b.phase=='playing'then b:finish('aborted','QA_CLEANUP')end
   b.world:removeFromParent();D.sleep(.1)
  end
  r.cleanup={}
  for _,skill in ipairs({2,4})do
   local b=B.createAsync({finishAsync=function()return true end},{mission='c0-m06'})
   for _,actor in ipairs(b.enemies)do actor.nextAttack=math.huge end
   wait(function()return b.mentor.onSurface end);local e=b.enemies[1]
   assert(b:enemyStrike(e,B.attackSpecs.dashanxiao[skill]));local strike=e.strikes[#e.strikes];D.sleep(.1)
   b:finish('aborted','QA_IMMEDIATE_CLEANUP');b.world:removeFromParent();D.sleep(1)
   assert(not e.busy and strike.cancelled and #strike.impacts==0)
   r.cleanup[#r.cleanup+1]={skill=strike.kind,cancelled=strike.cancelled};save()
  end
  r.backsteps={}
  for _,direction in ipairs({'left','right'})do
   local b=B.createAsync({finishAsync=function()return true end},{mission='c0-m06'})
   for i,actor in ipairs(b.enemies)do actor.nextAttack=math.huge;if i>1 then actor.unit.position=D.Vec2(11000,b.world.offset+155)end end
   local e=b.enemies[1];e.unit.position=D.Vec2(7520,b.world.offset+155)
   b.mentor.position=D.Vec2(direction=='left' and 7100 or 7940,b.world.offset+155)
   wait(function()return b.mentor.onSurface end)
   assert(b:enemyStrike(e,B.attackSpecs.dashanxiao[4]));local strike=e.strikes[#e.strikes]
   assert(b:command(direction));D.sleep(.1);assert(math.abs(b.mentor.velocityX)==135,'Backstep not half speed')
   wait(function()return not e.busy end);e.nextAttack=math.huge
   assert(b.mentorHP==100 and strike.hits==0 and #strike.impacts==1 and #strike.stages==2)
   assert(strike.stages[1].duration>=.99 and strike.stages[2].duration>=.99)
   assert(strike.completed-strike.animationStarted>=1.99 and strike.animationStarted-strike.warningStarted>=.99)
   r.backsteps[#r.backsteps+1]={direction=direction,hp=b.mentorHP,hits=strike.hits,impact=strike.impacts[1],warningLead=strike.animationStarted-strike.warningStarted,clips=strike.stages};save()
   b:command('idle');b:finish('aborted','QA_CLEANUP');b.world:removeFromParent();D.sleep(.1)
  end
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
