-- A real mentor bullet creates the Boss hit window; no HP/animation injection.
local D=require('Dora');local entry,qaResultName=...;local root=D.Path:getPath(D.Path:getScriptPath(entry));local out=root..'/Test/'..(qaResultName or 'yingzhao-hit-lesson-result.json');local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')};local A=require('Training.YingzhaoActions')
  local function wait(fn)local deadline=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<deadline,'Hit opportunity timeout');D.sleep(.02)end end
  for _,actor in ipairs({'ninilite','wuyun'})do for _,side in ipairs({-1,1})do
   local loadout={{actor=actor,item='emp',quantity=6},{actor='mentor',item='kinetic',quantity=4}};if actor=='wuyun'then loadout[#loadout+1]={actor=actor,item='blade',quantity=12}end
   local supplies=assert(require('Economy.CombatSession').virtual('big-yingzhao-demo:'..os.time()..':'..D.App.runningTime,loadout))
   local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true})
   local mentorCommand=b.command
   require('Training.YingzhaoDemonstration').attach(b,actor)
   -- Explicit QA mentor input keeps the public learner demonstration router intact.
   b.mentorAim.fire=function()return mentorCommand(b,'shoot')end
   local a=b.demonstrator
   local other=actor=='ninilite'and b.wuyun or b.arena;assert(b:start());other.mode='review'
   local boss=b.enemies[1];local update=boss.guard.update
   boss.guard.update=function(g,now)g.nextAttack=math.huge;update(g,now);g.nextAttack=math.huge end
   a.student.position=D.Vec2(1920+side*900,b.world.offset+155)
   b.mentor.x=1920-side*900;other.student.x=1920-side*1300;D.sleep(.5)
   local row={actor=actor,side=side,windows={}};r.cases[#r.cases+1]=row
   for cycle=1,2 do
    wait(function()return not boss.guard.reacting and D.App.runningTime>=(boss.guard.nextReaction or 0)and b.mentorAim.canStart()end)
    local hp=boss.enemyHP;assert(require('Training.YingzhaoMentor').shoot(b))
    wait(function()return boss.guard.reacting~=nil end)
    local observation=b.observeYingzhao(a.student);assert(observation.bossAction=='hit'and boss.enemyHP<hp)
    local chosen
    for _,part in ipairs({'head','forelegs','arms','hindlegs','torso','flank'})do
     if observation['part_'..part]~='exposed'and A.plan(b,a,part)then chosen=part;break end
    end
    assert(chosen,'No reachable armor during actual hit reaction')
    assert(b:command('aim-part',chosen));assert(b:command('shoot'))
    wait(function()return not a:isAttacking()and not b.bossCombat:pendingActor(actor)end)
    row.windows[#row.windows+1]={mentorDamage=hp-boss.enemyHP,part=chosen,observation=observation}
   end
   b:finish('aborted','Actual hit reaction opportunity QA lesson');while b.phase=='settling'do D.sleep(.02)end
   local resources=b.supplies:evidence();b.bossTrace.resources=resources
   local source={schemaVersion=1,closed=true,trainable=false,kind='big-yingzhao-demonstration',demonstrator=actor,episode=resources.attempt,versions={resources=1,bigYingzhao=1},resources=resources,boss=b.bossTrace}
   local data=assert(require('Training.YingzhaoPolicy').inspect({source},actor));row.samples=#data.samples;row.source=source;row.actions=data.actions
   assert(#data.samples==2);for _,s in ipairs(data.samples)do assert(s.state.bossAction=='hit'and s.action:match('^shoot@'))end
   assert(b.supplies:observation(actor).ammo.emp==4 and b.supplies:observation('mentor').ammo.kinetic==2)
   save()
  end end
  r.notNaturalVictory=true;r.notHumanDemonstration=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
