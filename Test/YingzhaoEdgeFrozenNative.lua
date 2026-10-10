-- Frozen learned models in explicit boundary fixtures, with a real punch.
-- Only the initial geometry/attack cue is controlled; no movement commands.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-edge-frozen-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local learned=D.json.decode(D.Content:load(root..'/Test/yingzhao-mixed-natural-result.json'),32);assert(learned.status=='PASS')
  local function idle(id)return {schemaVersion=1,featureSchemaVersion=2,actionSetVersion=1,characterId=id,sampleCount=1,trainingAccuracy=1,actions={'idle'},rules={{conditions={},action='idle'}}}end
  local models={ninilite=idle('ninilite'),wuyun=idle('wuyun')}
  local function wait(fn)local deadline=D.App.runningTime+10;while not fn()do assert(D.App.runningTime<deadline,'Frozen edge timeout');D.sleep(.02)end end
  for _,actor in ipairs({'ninilite','wuyun'})do
   for _,side in ipairs({'left','right'})do
    local model=actor=='ninilite'and learned.model or learned.companion
    local _,loadout=require('Economy.Loadout').quote(require('Economy.Loadout').defaults(),{mentor=true,learner=true,wuyun=true})
    local supplies=assert(require('Economy.CombatSession').virtual('edge-frozen-'..actor..'-'..side,loadout))
    local b=require('Enemy.BigYingzhaoBattle').createAsync(models,supplies,{virtual=true})
    local a=actor=='ninilite'and b.arena or b.wuyun;local other=actor=='ninilite'and b.wuyun or b.arena;other.mode='review'
    local boss=b.enemies[1];boss.guard.nextAttack=math.huge
    local x=side=='left'and b.minX or b.maxX;local direction=side=='left'and 1 or -1
    a.student.position=D.Vec2(x,b.world.offset+155);boss.enemy.position=D.Vec2(x,b.world.offset+255)
    b.mentor.x=1920;other.student.x=2020;D.sleep(.4)
    require('Training.YingzhaoTrial').attach(b,model);assert(b:start());other.mode='review';boss.guard.nextAttack=math.huge
    assert(boss.guard:attack('punch',a.student))
    wait(function()return not boss.guard.busy end);boss.guard.nextAttack=math.huge;D.sleep(1)
    local first
    for _,d in ipairs(b.yingzhaoDecisionsByActor[actor])do if d.accepted then first=d;break end end
    assert(first and first.observation.targetBossSide=='overlap'and first.observation.arenaEdge==side)
    assert(first.action==(side=='left'and'fmove'or'bmove'))
    local row={actor=actor,side=side,first=first.action,travel=(a.student.x-x)*direction,damage=100-a.studentHP,decisions=b.yingzhaoDecisionsByActor[actor]};r.cases[#r.cases+1]=row;save()
    assert(a.studentHP>0 and row.travel>100,'Frozen model failed to leave the overlapping edge')
    assert(#a.recorder.samples==0 and require('Training.FlowerIdentity').equal(model,b.yingzhaoCandidates[actor]))
    b:finish('aborted','Frozen edge fixture');wait(function()return b.phase=='aborted'end)
   end
  end
  r.notNaturalVictory=true;r.noMovementCommands=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
