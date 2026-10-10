-- Continue the earned factory journey through real doors and formal defense.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/fresh-chapter-three-current-result.json';local r={status='RUNNING',osInput=false,stages={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local previous=D.json.decode(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or '/private/tmp/lsd-earned-factory-low-wallet-20261007/result.json'),32)
  assert(previous.status=='PASS'and previous.sameJourney and previous.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-factory%-current%-%d+%.db$'))
  local db=D.Content.writablePath..'/fresh-chapter-three-current-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(previous.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db;r.source=previous.database
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
  require('Start');wait(function()return world()and world().tag=='OperationRoom'and world().reconnection end,45);stage('factory-resumed')
  local w=world();move(w.reconnection.marker.x);wait(function()return w.reconnection.menu.menu.enabled end);w.reconnection.menu:emit('Tapped',1);flow(w,'return-online',16)
  door('left','PassageC');door('center','PassageD');door('right','RDRoom')
  w=world();move(w.reconnection.marker.x);wait(function()return w.reconnection.menu.menu.enabled end);w.reconnection.menu:emit('Tapped',1);flow(w,'network-warning',6)
  door('left','PassageD');door('center','PassageC');door('center','PassageA')
  w=world();local gate=assert(w.defenseGate);move(gate.marker and gate.marker.x or 1150);local panel,why=gate:request();assert(panel,why);assert(panel.quote.total<=E.wallet().available);panel.saveButton:emit('Tapped')
  wait(function()return gate.level end,45);local level=gate.level;local b=level.battle;assert(b.supplies and not b.supplies.isVirtual);stage('defense-ready');D.sleep(.8);level.start:emit('Tapped')
  local deadline=D.App.runningTime+270
  while b.phase=='ready'or b.phase=='playing'or b.phase=='settling'do
   assert(D.App.runningTime<deadline,'Defense battle stalled')
   if b.phase=='playing'then
    local target=b:target(b.mentor);local delta=target and target.enemy.x-b.mentor.x or b.objective.x+180-b.mentor.x
    local retreat=target and target.enemyPhase=='attack'and math.abs(delta)<330;local moving=retreat or math.abs(delta)>(target and 380 or 70);local direction=retreat and -delta or delta
    level.hud.move:emit('Left',moving and direction<0);level.hud.move:emit('Right',moving and direction>0)
    if not moving and target then D.emit('Skill.Began');D.emit('Skill.Ended');level.fire:emit('TapBegan')end
    if b.mentorHP<=65 then level.medicine:emit('TapBegan')end
   end;D.sleep(.04)
  end
  r.battle=b.report;save();assert(b.phase=='won',b.reason);wait(function()return level.phase=='result'end)
  local P=require('Training.Progress');assert(P.load());assert(require('Academy.DefenseProof').validate(b.report,P.adopted))
  assert(not E.active()and E.wallet().available==r.balanceBefore-b.report.economy.cost+b.report.economy.income);stage('defense-won')
  level.result.againButton:emit('Tapped');wait(function()return world()~=b.world and world().tag=='PassageA'and world().academyLoss end,40)
  w=world();local loss=w.academyLoss;move(loss.marker.x);loss.menu:emit('Tapped',1);flow(w,'academy-loss',8)
  wait(function()return world()~=w and world().academyLoss and world().academyLoss.recorded end,40)
  local facts=assert(require('Story.Service').open()):summary();assert(facts.completed['academy-loss']and facts.mission.unlocks['academy-defense-complete'])
  r.roster=assert(require('Story.AcademyLossRecords').saved());r.balanceAfter=E.wallet().available;r.balance=r.balanceAfter;assert(models()==unchanged,'Chapter changed adopted training model');r.sameJourney=true;r.damagedAcademy=true;r.stage='academy-loss-complete'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save();print('LSD_FRESH_CHAPTER_THREE_CURRENT_'..r.status)
end)
