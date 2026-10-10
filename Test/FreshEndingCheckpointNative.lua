-- Resume the actual saved victory after the settlement UI failed; do not replay or charge battles.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/fresh-ending-checkpoint-result.json';local r={status='RUNNING',osInput=false,stages={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local previous=D.json.decode(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or '/private/tmp/lsd-earned-chapter-three-20261007/result.json'),32)
  assert(previous.status=='FAIL' and previous.stage=='final-ready' and previous.final and previous.final.economy.status=='won' and previous.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-ending%-current%-%d+%.db$'))
  local db=D.Content.writablePath..'/fresh-ending-current-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(previous.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db;r.source=previous.database
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local E=require('Economy.Store');assert(E.open());r.balanceBefore=E.wallet().available;assert(r.balanceBefore==previous.final.economy.balanceAfter and not E.active())
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
  local finalRows=assert(D.DB:query("SELECT report FROM lsd.Game0MissionAttempts WHERE mission='c0-m09' AND status='won' ORDER BY id LIMIT 1"));r.final=D.json.decode(finalRows[1][1],32)
  local rescueRows=assert(D.DB:query("SELECT report FROM lsd.Game0MissionAttempts WHERE mission='c0-m08' AND status='won' ORDER BY id LIMIT 1"));r.rescue=D.json.decode(rescueRows[1][1],32)
  local attemptsBefore=D.json.encode(D.DB:query('SELECT id,status,report FROM lsd.Game0MissionAttempts ORDER BY id'),false,true)
  require('Start');wait(function()return world()and world().tag=='RDRoom'and world().finalGate and player()and not player().busy end,45);stage('saved-victory-resumed')
  local w=world();local gate=w.finalGate;move(gate.marker.x)
  gate.menu:emit('Tapped',2);wait(function()return gate.view end)
  local record=gate.view;assert(record.resultLayout=='Settlement')
  local supportText=assert(require('Factory.Support').resultText(r.final));assert(record.reportLabel.text:find(supportText,1,true),'Stored life-field report missing')
  r.savedRecordViewed=true;record.againButton:emit('Tapped');wait(function()return gate.phase=='ready'end)
  assert(D.json.encode(D.DB:query('SELECT id,status,report FROM lsd.Game0MissionAttempts ORDER BY id'),false,true)==attemptsBefore and E.wallet().available==r.balanceBefore and not E.active())
  r.noBattleReplayOrDuplicateCharges=true
  local terminal,why=gate:request(1);assert(terminal,why);terminal.call:emit('Tapped');flow(terminal.world,'final-betrayal',15)
  assert(require('Final.BetrayalProof').validate(terminal.report));r.terminal=terminal.report
  terminal.ending:emit('Tapped');wait(function()return terminal.endingView end,30);local view=terminal.endingView
  while view.phase~='closed'do local page=view.page;view.next:emit('Tapped');wait(function()return view.page~=page or view.phase=='closed'end,10)end
  wait(function()local h=require('Ending.Hub').current;return h and h.mode=='title'end,30)
  local watched=assert(require('Ending.Store').open():load());assert(watched.ending and watched.credits)
  r.endingViews=watched;r.balanceAfter=E.wallet().available;r.balance=r.balanceAfter;assert(models()==unchanged,'Chapter changed adopted training model');r.sameJourney=true;r.stage='ending-and-credits-complete'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save();print('LSD_FRESH_ENDING_CHECKPOINT_'..r.status)
end)
