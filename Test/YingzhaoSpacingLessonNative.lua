-- Real movement -> full combo evasion -> actual shot. Controlled Boss trigger.
local D=require('Dora');local entry,qaResultName=...;local root=D.Path:getPath(D.Path:getScriptPath(entry));local out=root..'/Test/'..(qaResultName or 'yingzhao-spacing-lesson-result.json')
local r={status='RUNNING',cases={},notNaturalVictory=true,notHumanDemonstration=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}
  local function wait(fn)local deadline=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<deadline,'Spacing lesson timeout');D.sleep(.02)end end
  for _,actor in ipairs({'ninilite','wuyun'})do for _,side in ipairs({-1,1})do
   local b=require('Training.BigYingzhaoPractice').createAsync(models,{{actor=actor,item='emp',quantity=5}},actor)
   local a=b.demonstrator;local other=actor=='ninilite'and b.wuyun or b.arena;local boss=b.enemies[1];local g=boss.guard;local update=g.update
   g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   assert(b:start());other.mode='review';boss.enemy.position=D.Vec2(1920,b.world.offset+255);boss.enemy.faceRight=side>0
   a.student.position=D.Vec2(1920+side*500,b.world.offset+155);other.student.x=1920-side*1400;b.mentor.x=1920-side*1200
   D.sleep(.4);wait(function()return a.student.onSurface and boss.enemy.onSurface end)
   local row={actor=actor,side=side,hpBefore=a.studentHP,startDistance=math.abs(a.student.x-boss.enemy.x)};r.cases[#r.cases+1]=row
   local command=side>0 and 'right'or'left';local deadline=D.App.runningTime+5
   while math.abs(a.student.x-boss.enemy.x)<650 do assert(D.App.runningTime<deadline);assert(b:command(command));D.sleep(.05)end
   row.attackDistance=math.abs(a.student.x-boss.enemy.x);assert(b:command('stop'));assert(g:attack('massive',a.student));local strike=g.strike
   D.sleep(.1);deadline=D.App.runningTime+6
   while g.busy do assert(D.App.runningTime<deadline);assert(b:command(command));D.sleep(.1)end
   assert(strike.completed and not strike.cancelled and #strike.impacts==3 and strike.completed-strike.started>=2.85)
   row.strike=strike;row.damage=row.hpBefore-a.studentHP;assert(row.damage==0,'Spacing did not avoid full combo')
   assert(b:command('stop'));wait(function()return a:available('laser')and not a:isAttacking()end)
   local part
   wait(function()for _,id in ipairs({'head','forelegs','arms','torso','hindlegs','flank'})do if require('Training.YingzhaoActions').plan(b,a,id)then part=id;return true end end end)
   row.shotPart=part;local ap=b.bossCombat.armor.target.damage.parts[part].ap
   assert(b:command('aim-part',part));assert(b:command('shoot'))
   wait(function()return not a:isAttacking()and not b.bossCombat:pendingActor(actor)end)
   row.armorDamage=ap-b.bossCombat.armor.target.damage.parts[part].ap;assert(row.armorDamage==35,'Recovery shot missed actual armor')
   assert(b.supplies:observation(actor).ammo.emp==4);assert(a.studentHP==row.hpBefore)
   b:finish('aborted','Controlled continuous spacing lesson');wait(function()return b.phase=='aborted'end)
   local resources=b.supplies:evidence();b.bossTrace.resources=resources
   row.source={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator=actor,episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
   local data=assert(require('Training.YingzhaoPolicy').inspect({row.source},actor));row.samples=#data.samples;row.actions=data.actions
   local before,during,shot=0,0,0
   for _,s in ipairs(data.samples)do
    if s.action=='bmove'and s.state.bossAction=='idle'then before=before+1 end
    if s.action=='bmove'and s.state.bossAction=='massive'then during=during+1 end
    if s.action=='shoot@'..part then shot=shot+1 end
   end
   row.phases={prepare=before,evade=during,shoot=shot};assert(before>0 and during>0 and shot==1,'Continuous phases missing from training evidence');save()
  end end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
