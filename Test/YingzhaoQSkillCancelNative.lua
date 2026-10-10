-- Actual kick interrupts and explicitly injected end conditions, not natural outcomes.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-q-skill-cancel-result.json';local r={status='RUNNING',cases={},notNaturalVictory=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  assert(not D.DB:existDB('lsd'));local db=D.Content.writablePath..'/yingzhao-q-cancel-'..os.time()..'.db';assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db
  local Q=require('Training.YingzhaoQ');local A=require('Training.YingzhaoActions');local Store=require('Training.YingzhaoQStore')
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local function wait(fn)local deadline=D.App.runningTime+12;while not fn()do assert(D.App.runningTime<deadline,'Q cancel timeout');D.sleep(.02)end end
  for _,actor in ipairs({'ninilite','wuyun'})do for _,mode in ipairs({'before-release','after-release','failed-before-release','aborted-before-release'})do
   local skill=actor=='ninilite'and'fire'or'wind';local label=skill..'@right'
   local supplies=assert(require('Economy.CombatSession').virtual('q-cancel:'..D.App.runningTime,{{actor=actor,item='emp',quantity=2}}))
   local b=require('Enemy.BigYingzhaoBattle').createAsync({ninilite=idle('ninilite'),wuyun=idle('wuyun')},supplies,{virtual=true})
   local a=actor=='ninilite'and b.arena or b.wuyun;local other=actor=='ninilite'and b.wuyun or b.arena;other.mode='review'
   local function pause(g)local update=g.update;g.update=function(self,now)self.nextAttack=math.huge;update(self,now);self.nextAttack=math.huge end end
   local boss=b.enemies[1];pause(boss.guard);boss.enemy.x=2500;b.arena.student.x=1800;b.wuyun.student.x=2100;b.mentor.x=mode=='before-release'and 3300 or 2250;b.mentor.faceRight=true
   local child
   if mode=='before-release'or mode=='after-release'then
    local Small=require('Enemy.SmallYingzhao');child={enemy=Small.create(b.world,a.student.x-150),enemyHP=70};child.guard=Small.new(b,child);pause(child.guard);b.enemies[#b.enemies+1]=child
   end
   D.sleep(.4)
   local session;local calls=0;local start
   session=Q.attach(b,actor,{epsilon=1,random=function()
    calls=calls+1;if calls%2==1 then return 0 end
    local wanted=label
    local list={};local chosen
    for _,action in ipairs(session.q.actions)do if A.available(b,a,action,2)then list[#list+1]=action end end
    for i,action in ipairs(list)do if action==wanted then chosen=i;break elseif action=='idle'then chosen=i end end
    return (assert(chosen)-.5)/#list
   end})
   if mode=='before-release'then
    -- Delay the first controller decision, not the animation or enemy clock.
    -- Starting with an idle decision could seal at either .3/.6s and miss the kick window.
    local update=a.update;a.update=function(self,...)if b.phase=='playing'and D.App.runningTime-start<.5 then return end;return update(self,...)end
   end
   start=D.App.runningTime;assert(b:start());if child then assert(child.guard:attack('kick',a.student))end
   wait(function()return #b.magic.logs>0 end);local log=b.magic.logs[1]
   if mode=='failed-before-release'or mode=='aborted-before-release'then
    D.sleep(.1);assert(b:finish(mode=='failed-before-release'and'failed'or'aborted','Injected early outcome fixture'));wait(function()return session.closed end)
   else
    wait(function()for _,t in ipairs(session.transitions)do if t.action==label then return true end end end)
    assert(b:finish('aborted','Actual kick interruption fixture'));wait(function()return session.closed end)
   end
   r.latest={actor=actor,mode=mode,log=log,hp=a.studentHP,kick=child and child.guard.strike};save()
   assert(log.status=='cancelled'and not log.completedAt,'Interrupted skill marked complete')
   if mode=='after-release'then assert(log.releaseAt and(log.hits or 0)>0)else assert(not log.releaseAt and(log.hits or 0)==0)end
   local t;for _,transition in ipairs(session.transitions)do if transition.action==label then assert(not t);t=transition end end
   local row={actor=actor,mode=mode,log=log,hp=a.studentHP,transitions=session.transitions};r.cases[#r.cases+1]=row;save()
   if mode=='aborted-before-release'then
    assert(not t and session.q.updates==0 and session.discarded==1,'Abort fabricated a terminal Q loss')
    assert(not Q.validate(session.model),'Empty candidate accepted')
   else
    assert(t and t.ended>=log.endedAt)
    if child then assert(a.studentHP==88 and not t.done,'Actual kick missing or wrongly terminal')
    else assert(t.done and not t.nextState and not t.nextActions and math.abs(t.reward+103)<1e-6)end
    local source=D.json.decode(D.json.encode({schemaVersion=2,kind='yingzhao-q-candidate',episode=session.combat.episode,model=session.model,transitions=session.transitions,combat=session.combat},false,true),32)
    row.source=source;save();local valid,why=Store.validate(source);assert(valid,why)
    local accepted,why,id=Store.saveAsync(source);assert(accepted,why);row.id=id
    assert(require('Training.FlowerIdentity').equal(assert(Store.loadAsync(id)).source,source))
   end
   local hits=#b.bossTrace.hits;local updates=session.q.updates;a.student.playable:emit('attack');D.sleep(.2)
   assert(#b.bossTrace.hits==hits and session.q.updates==updates,'Late release/reward after cancellation');save()
  end end
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
