-- Real attack actions through the demo interface; no manufactured impacts or HP.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/resource-attack-demo-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/resource-attack-demo-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local saved=assert(require('Training.FlowerQStore').loadAsync());local E=require('Economy.Store');assert(E.open());local wallet=E.wallet()
  for _,case in ipairs({{actor='ninilite',action='laser',item='emp',label='shoot',cost=19},{actor='wuyun',action='melee',item='blade',label='melee',cost=5}})do
   local c=require('Training.FlowerPractice').openAsync(nil,case.actor,nil,saved.source.baseModels,nil,nil,nil,{{actor=case.actor,item=case.item,quantity=4}})
   D.sleep(.2);c.startButton:emit('Tapped');assert(c.battle.phase=='playing')
   local deadline=D.App.totalTime+45
   local attempts=0
   while c.battle.supplies:observation(case.actor).ammo[case.item]>0 do
    attempts=attempts+1;assert(attempts<=12,'Too many interrupted attempts')
    while not c:request(case.action)do assert(c.battle.phase=='playing' and D.App.totalTime<deadline,'Attack not available');D.sleep(.05)end
    D.sleep(.1)
    while c.arena:isAttacking()do assert(D.App.totalTime<deadline,'Attack stalled');D.sleep(.05)end
   end
   local before=c.battle.supplies:observation(case.actor);assert(before.ammo[case.item]==0 and before.spent==case.cost,D.json.encode(before))
   local count=#c.battle.partCombat.journal.steps;assert(not c:request(case.action))
   assert(#c.battle.partCombat.journal.steps==count and c.battle.supplies:observation(case.actor).spent==before.spent,'Empty attack recorded or charged')
   for i=1,8 do
    local action=i%2==0 and 'idle' or 'bmove'
    while not c:request(action)do assert(c.battle.phase=='playing' and D.App.totalTime<deadline);D.sleep(.05)end
    D.sleep(.35)
   end
   D.sleep(.4);c:finish();while c.battle.phase=='saving'do assert(D.App.totalTime<deadline);D.sleep(.02)end
   assert(c.result and c.result.saved,c.battle.saveError)
   local P=require('Training.ResourcePolicy');local episodes=assert(require('Training.ResourceDemoStore').history(case.actor));local data=assert(P.collect(episodes,case.actor));local counts=data.coverage.resources[case.item=='emp' and 'empAmmo' or 'bladeAmmo']
   assert(data.coverage.actions[case.label]>=1 and counts.ready>=1 and counts.low>=1 and counts.empty>=6)
   local model=assert(P.buildAsync(episodes,case.actor));assert(require('Training.ResourcePolicyStore').saveAsync(model,episodes))
   local consumed=0;for _,event in pairs(c.result.episode.resources.events)do if event.owner==case.actor then consumed=consumed+event.count end end;assert(consumed==4)
   assert(E.wallet().available==wallet.available and E.wallet().revision==wallet.revision)
   r.cases[#r.cases+1]={actor=case.actor,attempts=attempts,consumed=consumed,cost=before.spent,samples=#data.samples,coverage=data.coverage};save()
   D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/resource-attack-demo-'..case.actor..'.tga');D.sleep(.2)
  end
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
