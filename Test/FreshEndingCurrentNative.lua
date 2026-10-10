-- Continue the earned factory journey through real doors and formal defense.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/fresh-ending-current-result.json';local r={status='RUNNING',osInput=false,stages={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local previous=D.json.decode(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or '/private/tmp/lsd-earned-chapter-three-20261007/result.json'),32)
  assert(previous.status=='PASS'and previous.sameJourney and previous.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-chapter%-three%-current%-%d+%.db$'))
  local db=D.Content.writablePath..'/fresh-ending-current-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(previous.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db;r.source=previous.database
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
  local panel,why=gate:request();assert(panel,why);assert(panel.quote.total<=E.wallet().available);panel.saveButton:emit('Tapped');wait(function()return gate.level end,45)
  local function fight(level,kind)
   local b=level.battle;assert(b.supplies and not b.supplies.isVirtual);local before=E.wallet().available+panel.quote.total
   stage(kind..'-ready');D.sleep(.8);level.start:emit('Tapped');local frames={};local sampleStart=D.App.totalTime;local monitor=D.Node();monitor:addTo(b.world);monitor:schedule(function(dt)if b.phase=='playing' and D.App.totalTime-sampleStart>2 then frames[#frames+1]=dt end;return false end);local deadline=D.App.runningTime+280
   while b.phase=='ready'or b.phase=='playing'or b.phase=='settling'do
    assert(D.App.runningTime<deadline,kind..' battle stalled')
    if b.phase=='playing'then
     local target=b:target(b.mentor);local lead=kind=='rescue'and b.twins[1].unit.x+180 or b.objective.x+170
     local delta=target and target.enemy.x-b.mentor.x or lead-b.mentor.x
     local retreat=target and target.enemyPhase=='attack'and math.abs(delta)<240
     local moving=retreat or math.abs(delta)>(target and 300 or 50);local direction=retreat and -delta or delta
     level.hud.move:emit('Left',moving and direction<0);level.hud.move:emit('Right',moving and direction>0)
     if not moving and target then D.emit('Skill.Began');D.emit('Skill.Ended');level.fire:emit('TapBegan')end
     if b.mentorHP<=65 then level.medicine:emit('TapBegan')end
    end;D.sleep(.04)
   end
   monitor:removeFromParent();assert(#frames>0,'No gameplay timing samples');table.sort(frames);local sum,slow=0,0;for _,dt in ipairs(frames)do sum=sum+dt;if dt>1/30 then slow=slow+1 end end;r.performance=r.performance or {};r.performance[kind]={frames=#frames,mean=sum/#frames,p95=frames[math.ceil(#frames*.95)],p99=frames[math.ceil(#frames*.99)],max=frames[#frames],over33ms=slow,excludesInitialSeconds=2,screenshots=false}
   r[kind]=b.report;save();assert(b.phase=='won',b.reason);wait(function()return level.phase=='result'end)
   assert(level.result.resultLayout=='Settlement'and not E.active())
   assert(E.wallet().available==before+b.report.economy.net,'Wallet mismatch')
   stage(kind..'-won');local old=b.world;level.result.againButton:emit('Tapped')
   wait(function()return world()~=old and world().tag=='RDRoom'and world().jadeArrival and world().jadeArrival.phase=='ready'end,45)
  end
  fight(gate.level,'rescue');w=world();move(w.jadeArrival.marker.x);w.jadeArrival.menu:emit('Tapped',1);flow(w,'jade-distance',8)
  wait(function()return w.finalGate end);gate=w.finalGate;move(gate.marker.x)
  local preparation,why=gate:request();assert(preparation,why);assert(preparation.view and preparation.phase=='briefing')
  preparation.view.startButton:emit('Tapped');wait(function()return gate.supplyPanel end,30)
  panel=gate.supplyPanel;assert(panel.quote.total<=E.wallet().available);panel.saveButton:emit('Tapped');wait(function()return gate.level end,45)
  fight(gate.level,'final');w=world();gate=assert(w.finalGate);move(gate.marker.x)
  local terminal,why=gate:request(1);assert(terminal,why);terminal.call:emit('Tapped');flow(terminal.world,'final-betrayal',15)
  assert(require('Final.BetrayalProof').validate(terminal.report));r.terminal=terminal.report
  terminal.ending:emit('Tapped');wait(function()return terminal.endingView end,30);local view=terminal.endingView
  while view.phase~='closed'do local page=view.page;view.next:emit('Tapped');wait(function()return view.page~=page or view.phase=='closed'end,10)end
  wait(function()local h=require('Ending.Hub').current;return h and h.mode=='title'end,30)
  local watched=assert(require('Ending.Store').open():load());assert(watched.ending and watched.credits)
  r.endingViews=watched;r.balanceAfter=E.wallet().available;r.balance=r.balanceAfter;assert(models()==unchanged,'Chapter changed adopted training model');r.sameJourney=true;r.stage='ending-and-credits-complete'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save();print('LSD_FRESH_ENDING_CURRENT_'..r.status)
end)
