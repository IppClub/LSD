local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/ground-supply-result.json';local r={status='RUNNING',cases={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/flower-spatial-q-result.json'),32);assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-spatial%-q%-%d+%.db$'))
  local dest=D.Content.writablePath..'/ground-supply-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local models=assert(require('Training.FlowerQStore').loadAsync()).source.baseModels
  local service=assert(require('Mission.Service').open());assert(service:recoverAsync());assert(require('Story.Service').open())
  -- Explicit fixture gates isolate resource accounting from story acceptance.
  assert(D.DB:exec("INSERT OR IGNORE INTO lsd.Game0StoryNodes(id,completedAt) VALUES('ground-contact',0),('energy-plan',0)")>=0)
  local E=require('Economy.Store');assert(E.open())
  local values=require('Economy.Loadout').defaults();values['mentor:kinetic']=2;values['ninilite:emp']=2;values['wuyun:emp']=1;values['wuyun:blade']=2;assert(require('Economy.Loadout').saveAsync(values))
  for _,id in ipairs({'c0-m02','c0-m03'})do
   local formation={mentor=true,learner='ninilite',wuyun=id=='c0-m03' and true or nil};assert(service:saveFormationAsync(formation))
   local balance=E.wallet().available;local c,attempt
   local support=require('Ground.LifeSupport').new(65,'defence');support.hp={100,100,100}
   local panel=assert(require('Economy.Preparation').openAsync(id,id=='c0-m02' and models.ninilite or models,nil,function(s,a)attempt=a;c=require(id=='c0-m02' and 'Ground.Level' or 'Ground.EnergyLevel').openAsync(s,a,support)end))
   assert(#panel.quote.lines==(id=='c0-m02' and 2 or 4));panel.saveButton:emit('Tapped')
   local deadline=D.App.totalTime+30;while not c do assert(D.App.totalTime<deadline);D.sleep(.05)end
   local b=c.battle;assert(b.supplies and b.arena.supplies==b.supplies)
   while b.supplies.ledger.stock['mentor:kinetic'].remaining>0 or b.supplies.ledger.stock['ninilite:emp'].used==0 or id=='c0-m03' and b.supplies.ledger.stock['wuyun:emp'].used+b.supplies.ledger.stock['wuyun:blade'].used==0 do
    assert(b.phase=='playing' and D.App.totalTime<deadline,'Consumption not observed');b:command('shoot');D.sleep(.1)
   end
   local accepted,why=b:command('shoot');assert(not accepted and why=='NO_SUPPLIES','Empty command accepted')
   b:finish('aborted','Resource accounting QA');while not c.result do assert(D.App.totalTime<deadline,b.saveError);D.sleep(.05)end
   assert(c.result.resultLayout=='MissionFail' and c.result.economy==b.report.economy)
   assert(b.report.economy.income==0 and E.wallet().available==balance-b.report.economy.cost)
   if id=='c0-m02'then assert(require('Training.CombatStore').validate(b.combatEpisode));assert(b.combatEpisode.resources.spent==b.report.economy.cost)end
   local after=E.wallet().available;assert(service:finishAsync(attempt,'aborted',b.report,b.combatEpisode));assert(E.wallet().available==after)
   r.cases[#r.cases+1]={mission=id,cost=b.report.economy.cost,balance=after,lines=b.report.economy.lines,combatEvidence=b.combatEpisode~=nil};save()
  end
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
