-- Short formal component regression with actual adopted models and charged supplies.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/yingzhao-emp-formal-report-result.json'
local r={status='RUNNING',osInput=false,naturalVictory=false,formalComponentEncounter=true}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT'))),32)
  assert(prior.operationVariant=='visible-remote-interior-no-chase-public-route-v11'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/yingzhao%-adopted%-boss%-natural%-%d+%.db$'))
  local db=D.Content.writablePath..'/yingzhao-emp-formal-report-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local E=require('Economy.Store');assert(E.open());local initial=E.wallet().available
  local S=require('Training.YingzhaoAdoptionStore');local I=require('Training.FlowerIdentity')
  local states={ninilite=S.state('ninilite'),wuyun=S.state('wuyun')}
  local function basic()return {D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot')}end
  local modelsBefore=basic()
  local function wait(fn,t)local stop=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<stop,'Formal report route timeout');D.sleep(.02)end end
  require('Academy.Navigation').returnToRoomAsync('AbandonedCity',{spawn=4650,energySquad=true})
  local gate=assert(D.Platformer.Data.store.world.disarmGate);wait(function()return gate.menu.visible and gate.menu.menu.enabled end)
  gate.menu:emit('Tapped',2);wait(function()return gate.supplyPanel end)
  local panel=gate.supplyPanel
  for _,entry in ipairs({{1,'mentor:kinetic',20},{2,'ninilite:emp',12},{3,'wuyun:emp',2},{4,'wuyun:blade',12}})do
   while panel.values[entry[2]]>entry[3]do local delta=panel.values[entry[2]]-entry[3]>=5 and -5 or -1;panel.buttons[entry[1]][delta]:emit('Tapped')end
  end
  assert(panel.quote.total<=initial);r.reservedBudget=panel.quote.total;panel.saveButton:emit('Tapped')
  wait(function()local w=D.Platformer.Data.store.world;return w and w.patrolLevel end)
  local c=D.Platformer.Data.store.world.patrolLevel;local b=c.battle
  for actor,id in pairs(prior.adoptions)do assert(b.yingzhaoDeployments[actor].id==id)end
  c.start:emit('Tapped');wait(function()return b.phase=='playing'end);D.sleep(6)
  c.withdraw:emit('Tapped');wait(function()return c.phase=='result'or c.phase=='save-error'end,45);assert(c.phase=='result',c.error)
  assert(c.result.resultLayout=='MissionFail');c.result.reportButton:emit('Tapped');wait(function()return c.result.reportPanel end)
  assert(c.result.reportLabel.text:find('队伍贡献（耗材',1,true),'Formal report did not use contribution feedback')
  r.reportText=c.result.reportLabel.text;r.battle=b.report;r.cost=b.report.economy.cost;r.balanceAfter=E.wallet().available
  assert(r.balanceAfter==initial-r.cost and b.report.economy.income==0 and not E.active())
  local attempt=tonumber(b.supplies.attempt:match('(%d+)$'));r.attempt=attempt
  r.episode=assert(require('Training.CombatStore').load(attempt));assert(require('Enemy.BigYingzhaoEvidence').validate(r.episode))
  assert(r.episode.boss.status=='aborted');r.contributions=require('Training.YingzhaoContributions').summarize(r.episode.boss)
  assert(r.contributions.totalCost==r.cost)
  c.result.reportPanel.backButton:emit('Tapped');assert(c.result.visible and not c.result.reportPanel)
  c.result.baseButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world~=b.world end)
  assert(I.equal(modelsBefore,basic())and I.equal(states.ninilite,S.state('ninilite'))and I.equal(states.wuyun,S.state('wuyun')))
  r.formalLedgerAndReport=true;r.normalReturn=true;r.adoptionsAndBasicModelsUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
