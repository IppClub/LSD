local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/energy-supply-tactics-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/energy-supply-tactics-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local models=assert(require('Training.FlowerQStore').loadAsync()).source.baseModels
  local service=assert(require('Mission.Service').open());assert(service:recoverAsync());assert(require('Story.Service').open())
  -- Explicit fixture gates isolate resource accounting from story acceptance.
  assert(D.DB:exec("INSERT OR IGNORE INTO lsd.Game0StoryNodes(id,completedAt) VALUES('ground-contact',0),('energy-plan',0)")>=0)
  local E=require('Economy.Store');assert(E.open())
  local values=require('Economy.Loadout').defaults();assert(require('Economy.Loadout').saveAsync(values))
  for _,id in ipairs({'c0-m03'})do
   local formation={mentor=true,learner='ninilite',wuyun=id=='c0-m03' and true or nil};assert(service:saveFormationAsync(formation))
   local balance=E.wallet().available;local c,attempt
   local support=require('Ground.LifeSupport').new(65,'defence');support.hp={100,100,100}
   local panel=assert(require('Economy.Preparation').openAsync(id,id=='c0-m02' and models.ninilite or models,nil,function(s,a)attempt=a;c=require(id=='c0-m02' and 'Ground.Level' or 'Ground.EnergyLevel').openAsync(s,a,support)end))
   assert(#panel.quote.lines==(id=='c0-m02' and 2 or 4))
   if panel.quote.total>E.wallet().available then
    panel.recoveryButton:emit('Tapped');D.sleep(.1);local recovery=assert(panel.recoveryPanel)
    while E.wallet().available<panel.quote.total do for _,item in ipairs({'kinetic','emp','laser'})do recovery.buttons[item]:emit('Tapped');D.sleep(.12)end end
    recovery.backButton:emit('Tapped');D.sleep(.1);balance=E.wallet().available
   end
   panel.saveButton:emit('Tapped')
   local deadline=D.App.totalTime+30;while not c do assert(D.App.totalTime<deadline);D.sleep(.05)end
   local hud=assert(D.Director.ui3D:getChildByTag(id=='c0-m02'and 'ground-battle-hud'or'energy-battle-hud'))
   local b=c.battle;assert(b.supplies and b.arena.supplies==b.supplies)
   deadline=D.App.totalTime+110
   while b.phase=='playing'or b.phase=='saving'do
    assert(D.App.totalTime<deadline,'Natural battle stalled')
    hud.weapon:emit('TapBegan');hud.weapon:emit('TapEnded')
    b:command('fire');b:command('wind')
    if b.arena.studentHP<55 or b.wuyun.studentHP<55 then b:command('gather')end
    D.sleep(.1)
   end
   assert(b.phase~='save-error',b.saveError)
   while not c.result do assert(D.App.totalTime<deadline);D.sleep(.05)end
   assert(c.result.resultLayout==(b.phase=='won'and 'Settlement'or'MissionFail')and c.result.economy==b.report.economy)
   assert(b.report.economy.income==(b.phase=='won'and 100 or 0)and E.wallet().available==balance+b.report.economy.net)
   if id=='c0-m02'then assert(require('Training.CombatStore').validate(b.combatEpisode));assert(b.combatEpisode.resources.spent==b.report.economy.cost)end
   local after=E.wallet().available;assert(service:finishAsync(attempt,b.phase,b.report,b.combatEpisode));assert(E.wallet().available==after)
   r.cases[#r.cases+1]={fireHits=b.magic.fireHits,windHits=b.magic.windHits,synergyHits=b.magic.synergyHits,mentorHP=b.mentorHP,learnerHP=b.arena.studentHP,wuyunHP=b.wuyun.studentHP,mission=id,outcome=b.phase,seconds=b.report.seconds,net=b.report.economy.net,reason=b.reason,cost=b.report.economy.cost,balance=after,lines=b.report.economy.lines,combatEvidence=b.combatEpisode~=nil};save()
   assert(c.result.baseButton.children.last.text==(b.phase=='won'and '继续调查'or'返回列车'))
   assert(not c.result.againButton.visible and not c.result.againButton.touchEnabled)
   assert(c.result.reportLabel.text:find(b.reason,1,true))
   r.screenshot=D.Content.writablePath..'/energy-settlement-exit.tga';D.App:saveScreenshot(r.screenshot);D.sleep(.2)
   c.result.baseButton:emit('Tapped');local returnDeadline=D.App.runningTime+30
   while D.Platformer.Data.store.world==b.arena.world or D.Platformer.Data.store.world.tag~=(b.phase=='won'and 'AbandonedCity'or'TrainA')do
    assert(D.App.runningTime<returnDeadline,'Settlement return timed out');D.sleep(.05)
   end
   assert(not E.active()and E.wallet().available==after);r.cases[#r.cases].returnRoom=D.Platformer.Data.store.world.tag
  end
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
