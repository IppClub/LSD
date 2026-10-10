local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/defense-supply-result.json';local r={status='RUNNING',stages={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/defense-supply-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local model=assert(require('Training.FlowerQStore').loadAsync()).source.baseModels.ninilite
  local service=assert(require('Mission.Service').open());assert(service:recoverAsync());assert(require('Story.Service').open())
  -- Explicit story fixture, not a full chapter progression claim.
  assert(D.DB:exec("INSERT OR IGNORE INTO lsd.Game0StoryNodes(id,completedAt) VALUES('network-warning',0)")>=0)
  assert(service:saveFormationAsync({mentor=true,learner='ninilite'}))
  local E=require('Economy.Store');assert(E.open());local balance=E.wallet().available
  assert(require('Economy.Loadout').saveAsync(require('Economy.Loadout').defaults()))
  local level,attempt
  local panel=assert(require('Economy.Preparation').openAsync('c0-m07',model,nil,function(s,a)
   attempt=a;level=require('Academy.DefenseLevel').openAsync({ninilite=a.model},nil,{attempt=a,onSettledAsync=function(status,report)return s:finishAsync(a,status,report)end})
  end))
  assert(#panel.quote.lines==2 and panel.quote.total==229);panel.saveButton:emit('Tapped')
  local deadline=D.App.runningTime+280;while not level do assert(D.App.runningTime<deadline);D.sleep(.05)end
  local b=level.battle;local session=assert(b.supplies);assert(b.arena.supplies==session)
  D.sleep(.8);level.start:emit('Tapped')
  while b.phase=='ready'or b.phase=='playing'or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Defense supply battle stalled')
   if b.phase=='playing'then
    assert(b.supplies==session and b.arena.supplies==session)
    if not r.stages[b.stage]then
     local stock=session.ledger.stock;r.stages[b.stage]={spent=session.ledger.spent,mentor=stock['mentor:kinetic'].remaining,learner=stock['ninilite:emp'].remaining}
     if b.stage>1 then assert(session.ledger.spent>=r.stages[b.stage-1].spent and stock['mentor:kinetic'].remaining<=r.stages[b.stage-1].mentor)end
     save()
    end
    local target=b:target(b.mentor);local delta=target and target.enemy.x-b.mentor.x or b.objective.x+180-b.mentor.x
    local retreat=target and target.enemyPhase=='attack'and math.abs(delta)<330
    local moving=retreat or math.abs(delta)>(target and 380 or 70)
    local moveDelta=retreat and -delta or delta
    level.hud.move:emit('Left',moving and moveDelta<0);level.hud.move:emit('Right',moving and moveDelta>0)
    if not moving and target then D.emit('Skill.Began');D.emit('Skill.Ended');level.fire:emit('TapBegan')end
    if b.mentorHP<=65 then level.medicine:emit('TapBegan')end

   end
   D.sleep(.04)
  end
  r.phase=b.phase;r.reason=b.reason;r.combat=b.report;save();assert(b.phase=='won',b.reason)
  while not level.result do assert(D.App.runningTime<deadline);D.sleep(.05)end
  assert(level.result.resultLayout=='Settlement' and level.result.economy==b.report.economy)
  assert(require('Academy.DefenseProof').validate(b.report,model))
  local bill=assert(b.report.economy);assert(bill.cost==session.ledger.spent and bill.income==100 and E.wallet().available==balance+bill.net)
  local after=E.wallet().available;assert(service:finishAsync(attempt,'won',b.report));assert(E.wallet().available==after)
  r.cost=bill.cost;r.net=bill.net;r.seconds=b.report.seconds;r.sharedAcrossThreeStages=true
  D.App:saveScreenshot(root..'/Docs/evidence/2026-10-06/defense-supply-result.tga');D.sleep(.2)
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
