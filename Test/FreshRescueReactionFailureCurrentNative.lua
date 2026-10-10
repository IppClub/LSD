-- Earned third-chapter save -> original rescue entrance -> real enemy reaction regression.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/fresh-rescue-reaction-failure-current-result.json';local r={status='RUNNING',osInput=false,stages={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local previous=D.json.decode(D.Content:load(root..'/Test/fresh-chapter-three-current-result.json'),32)
  assert(previous.status=='PASS'and previous.sameJourney and previous.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-chapter%-three%-current%-%d+%.db$'))
  local db=D.Content.writablePath..'/fresh-rescue-reaction-failure-current-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(previous.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db;r.source=previous.database
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local E=require('Economy.Store');assert(E.open());r.balanceBefore=E.wallet().available;assert(r.balanceBefore==previous.balanceAfter)
  local function models()return D.json.encode({D.DB:query('SELECT slot,payload FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT slot,payload FROM lsd.Game0Training_wuyun ORDER BY slot')},false,true)end
  local unchanged=models()
  local function stage(name)r.stage=name;r.stages[#r.stages+1]={name=name,time=D.App.runningTime,balance=E.wallet().available};save()end
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Third chapter stalled at '..tostring(r.stage));D.sleep(.02)end end
  local function world()return D.Platformer.Data.store.world end
  local function player()return assert(D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==world()end))end
  local function hud()local v;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then v=n end end);return assert(v)end
  local function move(x)
   local p=player();local h=hud();if math.abs(p.unit.x-x)>25 then local side=p.unit.x<x and 'Right'or'Left';h.move:emit(side,true);wait(function()return math.abs(p.unit.x-x)<25 end,45);h.move:emit(side,false)end;D.sleep(.3)
  end
  local function door(side,target)
   local old=world();move(side=='left'and 120 or side=='right'and old.sceneWidth-120 or old.center.x)
   local p=player();local index;for i=1,p.moveTargets.count do if p.moveTargets:get(i)==target then index=i end end
   assert(index and p.interaction.menu.enabled,'Door '..target..' unavailable');p.interaction:emit('Tapped',index)
   wait(function()return world()~=old and world().tag==target end,20);D.sleep(.3);stage(target)
  end
  local function flow(w,id,count)
   wait(function()return w.storyFlow and w.storyFlow.id==id and w.storyFlow.view.visible end)
   local f=w.storyFlow;local deadline=D.App.runningTime+100;while f.phase~='complete'do assert(D.App.runningTime<deadline,'Dialogue '..id..' '..f.phase);if f.view.visible and not f.view._advancing then f.view.confirm:emit('Tapped')end;D.sleep(.07)end
   assert(#f.view._reviews==count);stage(id)
  end
  require('Start');wait(function()return world()and world().tag=='PassageA'and world().academyLoss end,45);stage('damaged-academy-resumed')
  door('center','PassageC');door('center','PassageD');door('right','RDRoom')
  local w=world();wait(function()return w.jadeArrival and w.jadeArrival.phase=='ready'end,30)
  move(w.jadeArrival.marker.x);w.jadeArrival.menu:emit('Tapped',1);flow(w,'jade-arrival',12)
  wait(function()return w.rescueGate end);local gate=w.rescueGate;move(gate.marker.x)
  local panel,why=gate:request();assert(panel,why)
  -- Deliberately poor, publicly configurable supplies; never alter HP/model.
  while panel.values['mentor:kinetic']>1 do panel.buttons[1][-1]:emit('Tapped')end
  while panel.values['ninilite:emp']>0 do panel.buttons[2][-1]:emit('Tapped')end
  assert(panel.quote and panel.quote.total==4)
  panel.saveButton:emit('Tapped');wait(function()return gate.level end,45)
  local level=gate.level;local b=level.battle;assert(b.supplies and not b.supplies.isVirtual)
  stage('under-equipped-rescue-ready');D.sleep(.8);level.start:emit('Tapped')
  local deadline=D.App.runningTime+260;local observed=false
  while b.phase=='ready'or b.phase=='playing'or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Under-equipped rescue did not end')
   for _,t in ipairs(b.twins)do
    if t.actor:isReacting()then observed=true end
    if t.actor:blocksMovement() and t.actor.reaction and D.App.totalTime-t.actor.reaction.started>.05 then assert(math.abs(t.unit.velocityX)<.001,'Failed rescue kept walking during reaction')end
   end
   D.sleep(.04)
  end
  r.battle=b.report;r.observed=observed;r.phase=b.phase;save()
  assert(b.phase=='failed'and observed,'Natural failed rescue/reaction not observed')
  wait(function()return level.phase=='result'end,45)
  assert(level.result.resultLayout=='MissionFail'and not E.active(),'Failure used wrong settlement or kept reservation')
  local fatal=false
  for _,t in ipairs(b.twins)do
   assert(not t.actor:isReacting(),'Failure settlement cut a reaction short')
   for _,event in ipairs(t.actor.events)do if event.kind=='complete'then assert(event.elapsed>=event.duration-.0001,'Clipped failure reaction')end end
   if t.actor.hp==0 then
    fatal=true;assert(t.actor.state=='down'and t.unit.velocityX==0,'Fatal escort stood up or moved')
    local startedFalls=0;local fatalAt
    for _,event in ipairs(t.actor.events)do
     if event.kind=='damage'and event.hp==0 then fatalAt=event.at end
     if fatalAt and event.kind=='start'then assert(event.clip~='standUp','Fatal escort started rising');if event.clip=='fall'then startedFalls=startedFalls+1 end end
    end
    assert(startedFalls<=1,'Fatal fall restarted')
   end
  end
  assert(fatal,'Failure was not a naturally lethal twin attack')
  r.battle=b.report;r.naturalFatal=true;r.balanceAfter=E.wallet().available
  assert(b.report.economy.income==0 and b.report.economy.net<0 and r.balanceAfter==r.balanceBefore+b.report.economy.net)
  assert(models()==unchanged,'Failure changed trained models')
  local facts=assert(require('Story.Service').open()):summary();assert(not facts.mission.unlocks['twins-rescued'],'Failure unlocked rescue story')
  stage('natural-failure-settled');local old=b.world;level.result.baseButton:emit('Tapped')
  wait(function()return world()~=old and world().tag=='RDRoom'and world().rescueGate end,45)
  gate=world().rescueGate;move(gate.marker.x)
  local retry,error=gate:request();assert(retry,error)
  retry.defaultsButton:emit('Tapped');assert(retry.quote.total<=E.wallet().available)
  retry.closeButton:emit('Tapped');assert(E.wallet().available==r.balanceAfter and not E.active(),'Cancelled retry charged resources')
  r.sameJourneyBranch=true;r.retryAvailable=true;r.stage='failure-returned-retry-available'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save();print('LSD_FRESH_RESCUE_REACTION_FAILURE_CURRENT_'..r.status)
end)
