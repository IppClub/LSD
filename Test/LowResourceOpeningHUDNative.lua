-- Earned formal save, public entry/loadout/HUD and withdrawal; scripted input.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/low-resource-opening-hud-result.json'
local r={status='RUNNING',osInput=false,formalComponent=true,naturalVictory=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT')))),32)
  assert(prior.status=='PASS'and prior.sameJourneyBranch and prior.episodeSaved and prior.returnedToTrain)
  assert(prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-big%-yingzhao%-current%-%d+%.db$'))
  local db=D.Content.writablePath..'/low-resource-opening-hud-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  r.database=db;r.source=prior.database;require('Data.Config'):loadAsync()
  local E=require('Economy.Store');assert(E.open());r.balanceBefore=E.wallet().available;assert(r.balanceBefore==prior.balanceAfter)
  local service=assert(require('Mission.Service').open());assert(service:summary().unlocks['yingzhao-route-cleared'])
  local function models()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training ORDER BY slot'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun ORDER BY slot')})end
  local original=models()
  local function wait(fn,t)local stop=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<stop,'Formal gather save stalled');D.sleep(.02)end end
  require('Academy.Navigation').returnToRoomAsync('AbandonedCity',{spawn=4650,energySquad=true})
  local gate=assert(D.Platformer.Data.store.world.disarmGate);wait(function()return gate.menu.visible and gate.menu.menu.enabled end)
  gate.menu:emit('Tapped',2);wait(function()return gate.supplyPanel end)
  local panel=gate.supplyPanel;panel.defaultsButton:emit('Tapped')
  assert(r.balanceBefore==169 and panel.quote.total==293)
  panel.saveButton:emit('Tapped');wait(function()return not panel.saving end)
  assert(not E.active() and E.wallet().available==r.balanceBefore,'Insufficient budget changed wallet/started mission')
  r.insufficientRejected=true;r.recoverySteps={}
  panel.recoveryButton:emit('Tapped');local v=assert(panel.recoveryPanel)
  while E.wallet().available<panel.quote.total do
   local state=v.state;local before=E.wallet().available;assert(state.eligible)
   local item=require('Economy.Recovery').tasks[state.stage+1].item
   v.buttons[item]:emit('Tapped')
   wait(function()return not v.busy and (v.state.stage~=state.stage or v.state.round~=state.round)end)
   r.recoverySteps[#r.recoverySteps+1]={round=state.round,stage=state.stage,item=item,before=before,after=E.wallet().available}
   save()
  end
  r.recoveryIncome=E.wallet().available-r.balanceBefore;assert(r.recoveryIncome==124)
  v.backButton:emit('Tapped');assert(panel.visible)
  assert(panel.quote.total<=E.wallet().available)
  r.budget=panel.quote.total;panel.saveButton:emit('Tapped')
  wait(function()return D.Platformer.Data.store.world.patrolLevel end)
  local level=D.Platformer.Data.store.world.patrolLevel;local b=level.battle
  assert(b.bossCombat and not b.supplies.isVirtual)
  level.start:emit('Tapped');wait(function()return b.phase=='playing'end)
  level.gather:emit('TapBegan');level.gather:emit('TapEnded')
  level.hud.move:emit('Left',true);D.sleep(2);level.hud.move:emit('Left',false)
  local untilAt=D.App.runningTime+35;local recovered=false;local size=D.App.winSize;r.screenshots={};local sizes={{960,540,'1920'},{683,384,'1366'}}
  while b.phase=='playing'and D.App.runningTime<untilAt do
   if not recovered and b.support.gold>0 and (b.mentorHP<100 or b.arena.studentHP<100 or b.wuyun.studentHP<100)then
    level.gather:emit('TapBegan');D.sleep(.7);level.gather:emit('TapEnded');recovered=true
   end
   local warning=require('Ground.BigYingzhaoLevel').supportWarningText(b)
   if #r.screenshots<2 and warning:find('Boss收招停顿',1,true)then
    local target=sizes[#r.screenshots+1];D.App.winSize=D.Size(target[1],target[2]);D.sleep(.12)
    warning=require('Ground.BigYingzhaoLevel').supportWarningText(b)
    if warning:find('Boss收招停顿',1,true)then
     local label=assert(level.supportWarning)
     assert(label.visible and label.text==warning,'Live HUD warning mismatch')
     assert(label.y-label.height>=level.controls.height-level.headerHeight,'Live warning escaped header')
     local path=root..'/Test/low-resource-opening-hud-'..target[3]..'.tga'
     D.App:saveScreenshot(path);D.sleep(.1)
     r.screenshots[#r.screenshots+1]={path=path,text=warning,width=D.App.bufferSize.width,height=D.App.bufferSize.height,labelHeight=label.height,bossHP=b.bossCombat.boss.enemyHP}
     save()
    end
   end
   if #r.screenshots==2 then break end
   D.sleep(.05)
  end
  D.App.winSize=size;assert(#r.screenshots==2,'No natural completed-opening full HUD captures')
  if b.phase=='settling'then wait(function()return b.phase~='settling'end,30)end
  if b.phase=='playing'then level.withdraw:emit('Tapped')end
  wait(function()return level.phase=='result'end,45)
  assert(level.result.resultLayout=='MissionFail'and b.report and not E.active())
  local attempt=tonumber(b.supplies.attempt:match('(%d+)$'))
  local episode=assert(require('Training.CombatStore').load(attempt))
  assert(episode.boss.gatherVersion==1 and #episode.boss.gathers>0)
  r.loadedGathers=episode.boss.gathers;r.runtimeGathers=b.bossTrace.gathers;save()
  local maxDelta=0
  local function equal(a,c)
   if type(a)~=type(c)then return false end
   if type(a)=='number'then local delta=math.abs(a-c);maxDelta=math.max(maxDelta,delta);return delta<=1e-8 end
   if type(a)~='table'then return a==c end
   for k,v in pairs(a)do if not equal(v,c[k])then return false end end
   for k in pairs(c)do if a[k]==nil then return false end end
   return true
  end
  assert(equal(episode.boss.gathers,b.bossTrace.gathers),'Saved gather fields differ')
  r.jsonMaxNumericDelta=maxDelta;r.jsonTolerance=1e-8
  for _,g in ipairs(episode.boss.gathers)do assert(g.started and g.deadline and g.initialPlan and g.latestPlan and g.ended and g.reason)end
  r.gathers=episode.boss.gathers;r.battle=b.report;r.episode=episode;r.outcome=b.report.status
  r.balanceAfter=E.wallet().available;assert(r.balanceAfter==r.balanceBefore+r.recoveryIncome+b.report.economy.net and b.report.economy.income==0)
  level.result.baseButton:emit('Tapped');wait(function()return D.Platformer.Data.store.world~=b.world end)
  assert(models()==original);r.modelsUnchanged=true;r.returned=true;r.recoveryIssued=recovered
  r.scope='Legal low-resource public recovery and natural completed-opening full HUD at two sizes; formal paid component encounter from earned failed checkpoint; public HUD scripted gather/recovery, saved exact gather trace, withdrawal/failure and original result return; no HP/position injection, not natural victory or OS/full journey acceptance'
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
