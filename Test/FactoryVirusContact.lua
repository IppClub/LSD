-- Public factory HUD aiming, with isolated save and stationary combat fixtures.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
for _,p in ipairs({root,root..'/Script',root..'/Spine',root..'/Image',root..'/Font'})do D.Content:insertSearchPath(1,p)end
local out=root..'/Test/factory-virus-contact-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={};local ok,err=xpcall(function()
  local source=D.Content.writablePath..'/lsd-ruins-route-qa-1791013294.db'
  local dest=D.Content.writablePath..'/factory-aim-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  local function model(id,action)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=6,trainingAccuracy=1,actions={action},rules={{conditions={},action=action}}}end
  D.App.winSize=D.Size(683,384)
  local c=require('Factory.Level').openAsync({finishAsync=function()return true end},{mission='c0-m05',models={ninilite=model('ninilite','laser'),wuyun=model('wuyun','melee')}})
  local b=c.battle;local combat=b.partCombat
  local function wait(f,t)local deadline=D.App.runningTime+(t or 6);while not f()do assert(D.App.runningTime<deadline,'Factory virus timeout '..D.json.encode({events=#combat.events,mentor={x=b.mentor.x,y=b.mentor.y},ni={x=b.arena.student.x,y=b.arena.student.y},wu={x=b.wuyun.student.x,y=b.wuyun.student.y},boss={x=b.roots[3].enemy.x,y=b.roots[3].enemy.y},steps=combat.journal.steps}));D.sleep(.01)end end
  D.sleep(.1);c.start:emit('Tapped')
  for _,a in ipairs(b.learners)do a.nextDecision=math.huge end
  for _,e in ipairs(b.roots)do e.enemyCombat:close()end
  for i=1,2 do b.roots[i].enemyHP=0;b.roots[i].enemy.x=7500 end

  b.mentor.x=5350;b.arena.student.x=3000;b.wuyun.student.x=6200;D.sleep(.2)
  local function virus(unit)
   local target;for _,t in ipairs(b.targets())do if t.unit==unit then target=t end end
   assert(b.effects:apply(target,'virus',5,{kind='QA-redirected-enemy'}))
  end
  virus(b.mentor)
  assert(b:command('shoot'));wait(function()return #combat.events==1 end)
  local first=combat.events[1]
  assert(first.weapon=='kinetic' and first.healthDamage==1.5 and first.apBefore>0 and first.apAfter==first.apBefore,'Virus bypassed Boss armor')
  assert((b.friendlyHits or 0)==0)
  r.kinetic=first
  wait(function()return not b.mentor:isDoing('groundMentorShot')end)
  b.effects:clear();b.mentor.x=3000;b.arena.student.x=5350;D.sleep(.2)
  virus(b.arena.student)
  assert(b.arena.student:start(b.arena.physical.laser));wait(function()return #combat.events==2 end)
  local second=combat.events[2]
  assert(second.weapon=='emp' and second.healthDamage==0 and second.armorDamage==35,'Virus changed EMP damage split')
  assert((b.arena.metrics.friendlyHits or 0)==0);r.emp=second
  wait(function()return not b.arena:isAttacking()end)
  c.withdraw:emit('Tapped');wait(function()return b.phase=='aborted'end)
  local episode=b.combatEpisode;assert(require('Training.CombatStore').validate(episode))
  local hits=0
  for _,step in ipairs(episode.steps)do
   assert(step.action.redirected==true)
   for _,hit in ipairs(step.hits)do hits=hits+1;assert(hit.relation=='hostile' and hit.source==step.action.actor)end
  end
  assert(hits==2);r.recorded=hits
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r))
end)
