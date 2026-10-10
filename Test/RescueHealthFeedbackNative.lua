-- Continue the earned factory journey through real doors and formal defense.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/rescue-health-feedback-result.json';local r={status='RUNNING',osInput=false,stages={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local previous=D.json.decode(D.Content:load(root..'/Test/chapter-three-journey-result.json'),32)
  assert(previous.status=='PASS'and previous.sameJourney and previous.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/chapter%-three%-journey%-%d+%.db$'))
  local db=D.Content.writablePath..'/rescue-health-feedback-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(previous.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db;r.source=previous.database
  local E=require('Economy.Store');assert(E.open());r.balanceBefore=E.wallet().available;assert(r.balanceBefore==previous.balanceAfter)
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
   stage(kind..'-ready');D.sleep(.8);level.start:emit('Tapped');local deadline=D.App.runningTime+280
   while b.phase=='ready'or b.phase=='playing'or b.phase=='settling'do
    assert(D.App.runningTime<deadline,kind..' battle stalled')
    if b.phase=='playing'then
     assert(b.healthHud.parent==D.Director.ui3D and b.healthHud.visible,'Health HUD not visible')
     for _,t in ipairs(b.twins)do
      assert(t.health.node.parent and not t.health.ap and t.health.hp.scaleX>=0 and t.health.hp.scaleX<=1)
      if t.hitAt and t.label.text:find('  -',1,true)and math.abs(t.health.hp.scaleX-t.actor.hp/100)<.001 then
       if not r.hitFeedback then
        r.hitFeedback={role=t.actor.asset,hp=t.actor.hp,bar=t.health.hp.scaleX,label=t.label.text,hitAt=t.hitAt}
        D.App:saveScreenshot(root..'/Test/rescue-health-feedback-hit.tga');save()
       end
      elseif r.hitFeedback and t.actor.asset==r.hitFeedback.role and not t.label.text:find('  -',1,true)and D.App.runningTime-t.hitAt>=.45 then
       r.hitRecovered=true
      end
     end
     if b.ward.active and math.abs(b.wardHealth.hp.scaleX-b.ward.remaining/b.ward.capacity)<.001 then r.wardObserved=true end
     local target=b:target(b.mentor);local lead=kind=='rescue'and b.twins[1].unit.x+180 or b.objective.x+170
     local delta=target and target.enemy.x-b.mentor.x or lead-b.mentor.x
     local retreat=target and target.enemyPhase=='attack'and math.abs(delta)<240
     local moving=retreat or math.abs(delta)>(target and 300 or 50);local direction=retreat and -delta or delta
     level.hud.move:emit('Left',moving and direction<0);level.hud.move:emit('Right',moving and direction>0)
     if not moving and target then D.emit('Skill.Began');D.emit('Skill.Ended');level.fire:emit('TapBegan')end
     if b.mentorHP<=65 then level.medicine:emit('TapBegan')end
    end;D.sleep(.04)
   end
   r[kind]=b.report;save();assert(b.phase=='won',b.reason);wait(function()return level.phase=='result'end)
   assert(level.result.resultLayout=='Settlement'and not E.active())
   assert(E.wallet().available==before+b.report.economy.net,'Wallet mismatch')
   stage(kind..'-won');local old=b.world;level.result.againButton:emit('Tapped')
   wait(function()return world()~=old and world().tag=='RDRoom'and world().jadeArrival and world().jadeArrival.phase=='ready'end,45)
  end
  fight(gate.level,'rescue')
  assert(r.hitFeedback and r.hitRecovered,'Actual unshielded hit feedback was not observed')
  assert(r.wardObserved,'Finite ward display was not observed')
  r.balanceAfter=E.wallet().available;r.stage='rescue-health-complete'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save();print('LSD_RESCUE_HEALTH_FEEDBACK_'..r.status)
end)
