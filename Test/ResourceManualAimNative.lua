-- Real attack actions through the demo interface; no manufactured impacts or HP.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-manual-aim-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-manual-aim-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local saved=assert(require('Training.FlowerQStore').loadAsync());local E=require('Economy.Store');assert(E.open());local wallet=E.wallet()
  local c=require('Training.FlowerPractice').openAsync(nil,'ninilite',nil,saved.source.baseModels,nil,nil,nil,{{actor='ninilite',item='emp',quantity=16},{actor='mentor',item='kinetic',quantity=30},{actor='wuyun',item='blade',quantity=30}})
  D.sleep(.2);c.startButton:emit('Tapped');local b=c.battle;local deadline=D.App.totalTime+75
  r.shots={}
  for i=1,12 do
   while not c.arena:available('laser')or c.aim.shot do assert(b.phase=='playing'and D.App.totalTime<deadline,'Aim unavailable');D.sleep(.03)end
   local count=#b.partCombat.journal.steps
   c.hud.weapon:emit('TapBegan');assert(c.aim.held and c.aim.line.visible)
   D.sleep(({.03,.35,.43,.47})[(i-1)%4+1])
   c.hud.weapon:emit('TapEnded')
   D.sleep(.1)
   while c.arena:isAttacking()do assert(D.App.totalTime<deadline);D.sleep(.03)end
   for j=count+1,#b.partCombat.journal.steps do
    local step=b.partCombat.journal.steps[j];local action=step.action
    if action.actor=='ninilite'and action.name=='shoot'then r.shots[#r.shots+1]={step=step.id,angle=action.aimAngle,source=action.aimSource,part=action.intendedPart,status=action.aimStatus,emitted=action.emitted,hits=step.hits}end
   end
   save()
  end
  for i=1,8 do
   while not c:request(i%2==0 and 'idle'or'bmove')do assert(b.phase=='playing'and D.App.totalTime<deadline);D.sleep(.03)end;D.sleep(.35)
  end
  c:finish();while b.phase=='saving'do assert(D.App.totalTime<deadline);D.sleep(.03)end
  assert(c.result and c.result.saved,b.saveError)
  local episode=c.result.episode;assert(require('Training.CombatStore').validate(episode))
  local P=require('Training.ResourcePolicy');local data=assert(P.collect({episode},'ninilite'));r.coverage=data.coverage;save()
  assert(data.coverage.aimed>0,'No boss-part aim samples captured')
  local model=assert(P.buildAsync({episode},'ninilite'));assert(model.actionSetVersion==5)
  assert(require('Training.ResourcePolicyStore').saveAsync(model,{episode}))
  local rebuilt=assert(require('Training.ResourcePolicyStore').loadAsync('ninilite'));assert(rebuilt.actionSetVersion==5)
  assert(E.wallet().available==wallet.available and E.wallet().revision==wallet.revision)
  r.samples=model.sampleCount;r.rules=model.rules;r.cost=b.supplies.ledger.spent
  D.Content:save(root..'/Docs/evidence/2026-10-06/resource-manual-aim-episode.json',D.json.encode(episode,false,true))

 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
