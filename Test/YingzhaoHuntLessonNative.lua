-- Controlled initial placement, actual summon animation and active minions.
-- QA command-path demonstrations, never human input or a natural victory.
local D=require('Dora');local entry,qaResultName=...;local root=D.Path:getPath(D.Path:getScriptPath(entry));local out=root..'/Test/'..(qaResultName or 'yingzhao-hunt-lesson-result.json');local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')};local A=require('Training.YingzhaoActions')
  for _,actor in ipairs({'ninilite','wuyun'})do for _,side in ipairs({-1,1})do
   local loadout={{actor=actor,item='emp',quantity=6}};if actor=='wuyun'then loadout[#loadout+1]={actor=actor,item='blade',quantity=12}end
   local b=require('Training.BigYingzhaoPractice').createAsync(models,loadout,actor);local a=b.demonstrator
   local other=actor=='ninilite'and b.wuyun or b.arena;assert(b:start());other.mode='review'
   local boss=b.enemies[1];local update=boss.guard.update
   boss.guard.update=function(g,now)g.nextAttack=math.huge;update(g,now);g.nextAttack=math.huge end
   a.student.position=D.Vec2(1920+side*900,b.world.offset+155)
   b.mentor.x=1920-side*1200;other.student.x=1920-side*1300
   D.sleep(.5);assert(boss.guard:attack('hunt',a.student));D.sleep(.1)
   local row={actor=actor,side=side,commands={}};r.cases[#r.cases+1]=row
   local deadline=D.App.runningTime+4
   while boss.guard.busy and D.App.runningTime<deadline and a.studentHP>0 do
    if not a:isAttacking()and not require('Combat.Displacement').blocked(a.student)then
     local observation=b.observeYingzhao(a.student);local chosen
     if observation.target=='summon'and observation.targetDistance=='near'then
      local ok,why=b:command(side==1 and'right'or'left');row.commands[#row.commands+1]={action='retreat',accepted=ok,reason=why,observation=observation}
     elseif a:available('laser')then
      for _,part in ipairs({'head','forelegs','arms','hindlegs','torso','flank'})do
       if observation['part_'..part]~='exposed'and A.plan(b,a,part)then chosen=part;break end
      end
      if chosen then
       assert(b:command('aim-part',chosen));local ok,why=b:command('shoot')
       row.commands[#row.commands+1]={action='shoot@'..chosen,accepted=ok,reason=why,observation=observation}
      else
       local ok,why=b:command(side==1 and'right'or'left');row.commands[#row.commands+1]={action='retreat',accepted=ok,reason=why,observation=observation}
      end
     end
    end
    D.sleep(.1)
   end
   local finishDeadline=D.App.runningTime+5
   while a:isAttacking()or b.bossCombat:pendingActor(actor)do assert(D.App.runningTime<finishDeadline);D.sleep(.02)end
   row.hp=a.studentHP;row.summoned=boss.guard.strike.summons and boss.guard.strike.summons.spawned
   assert(row.summoned==2,'Actual summon release missing')
   b:finish('aborted','Actual hunt opportunity QA lesson');while b.phase=='settling'do D.sleep(.02)end
   local resources=b.supplies:evidence();b.bossTrace.resources=resources
   local source={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator=actor,episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
   local data=assert(require('Training.YingzhaoPolicy').inspect({source},actor))
   row.samples=#data.samples;row.actions=data.actions;row.source=source
   local huntShots=0;for _,s in ipairs(data.samples)do if s.state.bossAction=='hunt'and s.action:match('^shoot@')then huntShots=huntShots+1 end end
   row.huntShots=huntShots;save();assert(huntShots>=1,'No completed real shot during summon window')
  end end
  r.notNaturalVictory=true;r.notHumanDemonstration=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
