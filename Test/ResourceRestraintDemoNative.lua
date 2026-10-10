-- Real attack actions through the demo interface; no manufactured impacts or HP.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-restraint-demo-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-restraint-demo-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local saved=assert(require('Training.FlowerQStore').loadAsync());local E=require('Economy.Store');assert(E.open());local wallet=E.wallet()
  local c=require('Training.FlowerPractice').openAsync(nil,'ninilite',nil,saved.source.baseModels,nil,nil,nil,{{actor='ninilite',item='emp',quantity=16},{actor='mentor',item='kinetic',quantity=30},{actor='wuyun',item='blade',quantity=30}})
  D.sleep(.2);c.startButton:emit('Tapped');local b=c.battle;local deadline=D.App.totalTime+75
  r.shots={}
  r.restraintRequests=0
  for i=1,22 do
   assert(b.phase=='playing'and D.App.totalTime<deadline,'Round ended before demonstration')
   local known=b.partCombat.known.roots
   if known and known.ap<=0 then
    local action=i%2==0 and 'idle'or'bmove'
    while not c:request(action)do assert(b.phase=='playing'and D.App.totalTime<deadline);D.sleep(.03)end
    r.restraintRequests=r.restraintRequests+1;D.sleep(.4)
   else
    while not c.arena:available('laser')or c.aim.shot do assert(b.phase=='playing'and D.App.totalTime<deadline,'Aim unavailable');D.sleep(.03)end
    -- Recheck shared observed armor after waiting for action recovery.
    known=b.partCombat.known.roots
    if not known or known.ap>0 then
     c.hud.weapon:emit('TapBegan');D.sleep(({.03,.35,.43,.47})[(i-1)%4+1]);c.hud.weapon:emit('TapEnded');D.sleep(.1)
     while c.arena:isAttacking()do assert(D.App.totalTime<deadline);D.sleep(.03)end
    end
   end
  end
  D.sleep(.5)
  c:finish();while b.phase=='saving'do assert(D.App.totalTime<deadline);D.sleep(.03)end
  assert(c.result and c.result.saved,b.saveError)
  local episode=c.result.episode;assert(require('Training.CombatStore').validate(episode))
  local P=require('Training.ResourcePolicy');local data=assert(P.collect({episode},'ninilite'));r.coverage=data.coverage;save()
  assert(data.coverage.knownUnarmoredShots==0,'Wasteful aimed EMP retained')
  local restraint=0
  for _,step in ipairs(episode.steps)do
   local a=step.action;local o=step.observation
   if a.actor=='ninilite'and a.origin=='demo'and step.sealed and not step.truncated and (a.name=='idle'or a.name=='bmove')and o.part_roots=='exposed'and o.resources.ammo.emp>0 then
    restraint=restraint+1
    for _,event in pairs(episode.resources.events)do assert(not(event.owner=='ninilite'and event.step==step.id),'Restraint spent EMP')end
   end
  end
  assert(restraint>=6,'Missing informed restraint samples');r.informedRestraint=restraint
  local model=assert(P.buildAsync({episode},'ninilite'))
  assert(require('Training.ResourcePolicyStore').saveAsync(model,{episode}))
  local rebuilt=assert(require('Training.ResourcePolicyStore').loadAsync('ninilite'))
  assert(E.wallet().available==wallet.available and E.wallet().revision==wallet.revision)
  r.samples=model.sampleCount;r.rules=model.rules;r.cost=b.supplies.ledger.spent
  D.Content:save(root..'/Docs/evidence/2026-10-06/resource-restraint-demo-episode.json',D.json.encode(episode,false,true))

 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
