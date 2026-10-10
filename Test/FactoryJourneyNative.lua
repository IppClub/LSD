-- One earned assembly save, continuous public traversal; no injected progression/HP.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...))
local out=root..'/Test/factory-journey-result.json';local r={status='RUNNING',osInput=false,stages={},battles={},recoveryIncome=0}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local source=assert(D.Content:load(root..'/Test/command-assembly-resume-fixture.txt'));assert(source:match('^/Users/Jin/Workspace/Dora/lsd%-command%-assembly%-qa%-%d+%.db$'))
  local db=D.Content.writablePath..'/factory-journey-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(source,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0)
  r.database=db;r.source=source;require('Data.Config'):loadAsync();local E=require('Economy.Store');assert(E.open());r.balanceBefore=E.wallet().available
  local function stage(name)r.stage=name;r.stages[#r.stages+1]={name=name,time=D.App.runningTime,balance=E.wallet().available};save()end
  local function wait(fn,t,label)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,(label or 'Journey stalled')..' stage='..tostring(r.stage));D.sleep(.02)end end
  local function world()return D.Platformer.Data.store.world end
  local function flow(w,id,count)
   wait(function()return w.storyFlow and w.storyFlow.id==id and w.storyFlow.view.visible end,30,id)
   local f=w.storyFlow;local deadline=D.App.runningTime+120
   while f.phase~='complete'do assert(D.App.runningTime<deadline,'Dialogue '..id..' '..f.phase);if f.view.visible and not f.view._advancing then f.view.confirm:emit('Tapped')end;D.sleep(.07)end
   assert(#f.view._reviews==count,id..' missing authored rows');stage(id);return f
  end
  local function hud(w)
   local found;D.Director.ui3D.children:each(function(n)if n.move and n.skillArea then found=n end end);return assert(found,'Scene HUD absent')
  end
  local function move(control,unit,x,t,margin)
   margin=margin or 16;local side=unit.x<x and 'Right'or'Left'
   if math.abs(unit.x-x)>margin then control.move:emit(side,true);wait(function()return math.abs(unit.x-x)<=margin end,t or 12,'Movement at '..unit.x..' target '..x);control.move:emit(side,false)end
   D.sleep(.12)
  end
  local function prepare(owner,mission)
   wait(function()return owner.supplyPanel end);local panel=owner.supplyPanel
   if panel.quote.total>E.wallet().available then
    panel.saveButton:emit('Tapped');wait(function()return not panel.saving end);assert(not E.active(),'Insufficient budget started a task');r.insufficientBudgetBlocked=true
    panel.recoveryButton:emit('Tapped');local v=assert(panel.recoveryPanel);local before=E.wallet().available
    while E.wallet().available<panel.quote.total do
     local state=v.state;assert(state.eligible,'Recovery ceiling cannot fund task')
     local expected=require('Economy.Recovery').tasks[state.stage+1].item
     v.buttons[expected]:emit('Tapped');wait(function()return not v.busy and (v.state.stage~=state.stage or v.state.round~=state.round)end)
    end
    r.recoveryIncome=r.recoveryIncome+E.wallet().available-before;r.recoveryUsed=true;v.backButton:emit('Tapped');assert(panel.visible)
   end
   panel.saveButton:emit('Tapped');wait(function()return owner.battleLevel end,40)
   local level=owner.battleLevel;local b=level.battle;assert(b.supplies and not b.supplies.isVirtual)
   local id=tonumber(b.supplies.attempt:match('(%d+)$'));assert(D.DB:query('SELECT mission FROM lsd.Game0MissionAttempts WHERE id=?',{id})[1][1]==mission)
   return level,b
  end
  local function fight(level,b,mission,beforeDialogue)
   local before=b.supplies.ledger.balanceBefore;level.start:emit('Tapped')
   if beforeDialogue then flow(b.world,beforeDialogue.id,beforeDialogue.count)end
   wait(function()return b.phase=='playing'end);local deadline=D.App.runningTime+125;local nextShot=0
   while b.phase=='playing'or b.phase=='settling'do
    assert(D.App.runningTime<deadline,'Battle '..mission..' stalled')
    if b.phase=='playing'then
     local target=b.target and b:target(b.mentor)or b.enemy
     if target then local delta=target.enemy.x-b.mentor.x
      if math.abs(delta)>300 then b:command(delta>0 and 'right'or'left')else b:command('stop');if D.App.runningTime>=nextShot then b:command('shoot');nextShot=D.App.runningTime+.3 end end
      b:command('fire');if b.wuyun then b:command('wind')end
     end
    end;D.sleep(.03)
   end
   assert(b.phase=='won',mission..' '..tostring(b.reason));wait(function()return level.phase=='result'end)
   assert(level.checkpointSaved and not E.active());local result=assert(b.report.economy);assert(E.wallet().available==before-result.cost+result.income)
   r.battles[#r.battles+1]={mission=mission,report=b.report};stage(mission)
   level.result.againButton:emit('Tapped');wait(function()local w=world();local route=w.infiltration or w.roof;return w~=b.world and route and route.phase=='ready'end,40)
  end
  stage('assembly');require('Start');wait(function()return world()and world().commandAssembly and world().commandAssembly.phase=='ready'end,40)
  local w=world();local assembly=w.commandAssembly;local p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end);move(hud(w),p.unit,assembly.center,15,80)
  wait(function()return assembly.menu.visible end);assembly.menu:emit('Tapped',4);wait(function()return world()~=w and world().infiltration and world().infiltration.phase=='ready'end,40)
  w=world();local c=w.infiltration;c.menu:emit('Tapped',1);flow(w,'patrol-approach',2)
  assert(c:request());local lens=assert(w.nightLens);lens.view.researchButton:emit('Tapped');wait(function()return c.store:load().located and not c.scanning end,10);lens.view.closeButton:emit('Tapped');stage('patrol-located')
  assert(c:request());local level,b=prepare(c,'c0-patrol');fight(level,b,'c0-patrol',{id='patrol-contact',count=1})
  w=world();c=w.infiltration;assert(c:request());flow(w,'patrol-cleared',1);assert(c:request());flow(w,'infiltration-fox-guide',1)
  wait(function()return c.path and c.path.phase=='walking'end);local path=c.path;p=D.Group({'player','unit'}):find(function(e)return e.player and e.unit.world==w end);local control=hud(w)
  for i,cover in ipairs(path.covers)do
   if i==1 then wait(function()return path.guards[1].sign==1 and path.guards[1].unit.x>2700 end,20)
   else wait(function()return path.guards[i-1].sign==-1 and path.guards[i-1].unit.x<path.covers[i-1].x-35 and path.guards[i].sign==1 and path.guards[i].unit.x>cover.x+35 end,20)end
   local alerts=path.alerts;move(control,p.unit,cover.x,10);assert(path.alerts==alerts,'Unsafe stealth crossing '..i)
   path.action:emit('TapBegan');assert(path.hidden and p.busy);D.sleep(.55)
   if i<3 then wait(function()return path.guards[i].sign==-1 and path.guards[i].unit.x<cover.x-35 and path.guards[i+1].sign==1 and path.guards[i+1].unit.x>path.covers[i+1].x+35 end,20)
   else wait(function()return path.guards[i].sign==-1 and path.guards[i].unit.x<cover.x-35 end,20)end
   path.action:emit('TapBegan');assert(not path.hidden and not p.busy)
  end
  move(control,p.unit,4100,10);wait(function()return path.phase=='complete'and c.pathCompleted end);stage('stealth-complete')
  assert(c:request());flow(w,'infiltration-researcher-scout',2);assert(c:request());level,b=prepare(c,'c0-researcher');fight(level,b,'c0-researcher',{id='researcher-contact',count=2})
  w=world();c=w.infiltration;assert(c.capture.caught);assert(c:request());flow(w,'researcher-interrogation',12);wait(function()return c.phase=='ready'end)
  assert(c:request());level,b=prepare(c,'c0-patrol-second');assert(not b.wuyun and not b.supplies.ledger.stock['wuyun:emp']);fight(level,b,'c0-patrol-second')
  w=world();c=w.infiltration;assert(c.second.completed);assert(c:request());wait(function()return world().controlPod and world().controlPod.phase=='ready'end,40)
  local pod=world().controlPod;assert(pod.floor==1)
  for floor=2,7 do pod.up:emit('TapBegan');wait(function()return pod.phase=='ready'end,25);assert(pod.floor==floor);stage('control-floor-'..floor)end
  pod.hud.move:emit('Right',true);wait(function()return pod.player.unit.x>1390 end,10);pod.hud.move:emit('Right',false)
  pod.doorButton:emit('TapBegan');wait(function()return pod.phase=='ready'and pod.state.doorOpen end,15)
  move(pod.hud,pod.player.unit,2190,12,20);wait(function()return pod.fox.animation=='idle'end,10);assert(pod:openDoor());flow(pod.world,'control-pod-researchers',29)
  move(pod.hud,pod.player.unit,3300,12,15);assert(pod:openDoor());wait(function()return world().roof and world().roof.phase=='ready'end,40)
  local roof=world().roof;assert(roof.stage==0);move(roof.hud,roof.player.model,360,3,10);assert(roof:act());wait(function()return roof.phase=='ready'and roof.stage==1 end,30)
  move(roof.hud,roof.player.model,1245,6,10);assert(roof:act());wait(function()return roof.phase=='ready'and roof.stage==2 end,45);stage('roof-climbed')
  move(roof.hud,roof.player.model,2490,10,15);D.sleep(.7);assert(roof:act());flow(roof.world,'roof-confrontation',11)
  assert(roof:act());level,b=prepare(roof,'c0-roof');wait(function()return b.mentor.onSurface and b.arena.student.onSurface end);fight(level,b,'c0-roof')
  roof=world().roof;assert(roof.duelComplete);move(roof.hud,roof.player.model,2490,10,15);D.sleep(.7);assert(roof:act());flow(roof.world,'roof-aftermath',5)
  assert(roof.aftermathComplete and not roof.wuyun.visible);roof.back:emit('Tapped');wait(function()return world().controlPod and world().controlPod.phase=='ready'end,40)
  pod=world().controlPod;assert(pod.aftermathComplete);pod.leave:emit('Tapped');wait(function()return world().infiltration and world().infiltration.phase=='ready'end,40)
  w=world();assert(w.infiltration.wuyunGone);w.infiltration.menu:emit('Tapped',2);wait(function()return world().tag=='OperationRoom'end,40)
  assert(not E.active());r.balanceAfter=E.wallet().available;local cost,income=0,0
  for _,battle in ipairs(r.battles)do cost=cost+battle.report.economy.cost;income=income+battle.report.economy.income end
  assert(#r.battles==4 and r.balanceAfter==r.balanceBefore+r.recoveryIncome+income-cost);r.totalCost=cost;r.totalIncome=income;r.returned=true;r.sameSave=true;stage('factory-complete')
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save();print('LSD_FACTORY_JOURNEY_'..r.status)
end)
