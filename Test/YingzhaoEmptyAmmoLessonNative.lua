-- Consume the final real virtual round, then demonstrate another legal action.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-empty-ammo-lesson-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')};local A=require('Training.YingzhaoActions')
  local function wait(fn)local stop=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<stop,'Empty ammo lesson timeout');D.sleep(.02)end end
  for _,side in ipairs({-1,1})do for _,response in ipairs({'approach','wind'})do
   local b=require('Training.BigYingzhaoPractice').createAsync(models,{{actor='wuyun',item='emp',quantity=1},{actor='wuyun',item='blade',quantity=5}},'wuyun')
   local a=b.wuyun;local boss=b.enemies[1];local g=boss.guard;local update=g.update
   g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end
   b.arena.mode='review';assert(b:start());boss.enemy.x=1900;a.student.x=1900+side*(response=='approach'and 850 or 500);b.arena.student.x=1900-side*1000;b.mentor.x=1900-side*900
   D.sleep(.4);wait(function()return a.student.onSurface end)
   local row={side=side,response=response};r.cases[#r.cases+1]=row;save()
   local shot
   for _,part in ipairs({'head','flank','torso','forelegs','hindlegs','arms'})do local label='shoot@'..part;if A.available(b,a,label,2)then shot=label;break end end
   assert(shot,'No reachable part for final round');assert(A.request(b,a,shot,'demo',2));wait(function()return not a:isAttacking()and not b.bossCombat:pendingActor('wuyun')end)
   row.empty=b.observeYingzhao(a.student);assert(row.empty.empAmmo=='empty'and row.empty.bladeAmmo=='ready')
   local accepted,why=A.request(b,a,shot,'demo',2);assert(not accepted and why=='OUT_OF_SUPPLIES');row.rejected=why
   if response=='approach'then
    assert(A.request(b,a,'fmove','demo',2));wait(function()return math.abs(a.student.x-boss.enemy.x)<=170 end)
    assert(A.request(b,a,'idle','demo',2));D.sleep(.2);assert(A.request(b,a,'melee','demo',2));wait(function()return not a:isAttacking()end)
    local hit=false;for _,h in ipairs(b.bossTrace.hits)do if h.source=='wuyun'and h.weapon=='blade'and h.healthDamage+h.armorDamage>0 then hit=true end end;assert(hit,'Melee did not contact Boss')
   else
    assert(g:attack('punch',a.student));D.sleep(.1);assert(A.request(b,a,side<0 and'wind@right'or'wind@left','demo',2));wait(function()return #b.magic.logs>0 and b.magic.logs[1].endedAt and not g.busy end)
    assert(b.magic.windHits>0 and g.strike.cancelled=='HIT','Empty-ammo wind did not counter')
   end
   b:command('stop');b:finish('aborted','Empty ammunition alternative demonstration');wait(function()return b.phase=='aborted'end)
   local e=b.supplies:evidence();b.bossTrace.resources=e
   row.source=D.json.decode(D.json.encode({schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator='wuyun',episode=e.attempt,versions={resources=1,bigYingzhao=1},resources=e,boss=b.bossTrace},false,true),32)
   local valid,reason=require('Enemy.BigYingzhaoEvidence').validateVirtual(row.source);assert(valid,reason)
   local data=assert(require('Training.YingzhaoPolicy').inspect({row.source},'wuyun',8,2));row.samples=#data.samples;row.actions=data.actions;row.emptyLabels={}
   for _,s in ipairs(data.samples)do if s.state.empAmmo=='empty'then row.emptyLabels[#row.emptyLabels+1]=s.action end end
   assert(#row.emptyLabels>0);save()
  end end
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
