-- Real training labels; frozen battle and controlled review data isolate glyph layout.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/training-text-cache-result.json'
local r={status='RUNNING',osInput=false,controlledFixture=true,cases={}};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local meta,newindex
 local ok,why=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load('/private/tmp/lsd-report-snapshot-full-journey-20261009/fresh-wuyun-current/result.json')),32)
  assert(prior.status=='PASS'and prior.sameJourney)
  local db=D.Path(D.Content.writablePath,'training-text-cache.db');assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.source=prior.database;r.database=db
  local tracked=setmetatable({},{__mode='k'})
  local function frames(n)local left=n;local node=D.Node();node:addTo(D.Director.ui);node:schedule(function()left=left-1;return left<=0 end);while left>0 do D.sleep(.01)end;node:removeFromParent()end
  local function wait(fn)local stop=D.App.runningTime+30;while not fn()do assert(D.App.runningTime<stop,'Training cache fixture timeout');D.sleep(.02)end end
  for _,variant in ipairs({'before','after'})do
   local open=variant=='before'and assert(load(assert(D.Content:load('/private/tmp/lsd-training-level-before-text-cache-20261009.lua')),'@training-before'))()or require('Training.Level')
   open(nil,'wuyun');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
   local ui=D.Director.ui3D:getChildByTag('training-controls');local a=ui.arena;a.update=function()return false end
   local title=assert(ui:getChildByTag('training-status'));local report=assert(ui:getChildByTag('training-comparison'));local tc,rc={writes=0},{writes=0};tracked[title]=tc;tracked[report]=rc
   if not meta then meta=getmetatable(title);newindex=assert(meta.__newindex);meta.__newindex=function(o,k,v)local count=tracked[o];if count and k=='text'then count.writes=count.writes+1 end;return newindex(o,k,v)end end
   frames(5);tc.writes=0;frames(120);local row={variant=variant,steadyFrames=120,demoWrites=tc.writes};r.cases[#r.cases+1]=row;save();assert(tc.writes==(variant=='before'and 120 or 0))
   tc.writes=0;a.message='文字变化应即时显示';frames(5);row.changedDemoWrites=tc.writes;assert(title.text:find(a.message,1,true)and tc.writes==(variant=='before'and 5 or 1))
   a.mode='review';a.evaluation={summary={candidate={wins=2,health=70,seconds=10},baseline={wins=1,health=60,seconds=12}}};frames(5);tc.writes=0;rc.writes=0;frames(120);row.reviewTitleWrites=tc.writes;row.reviewReportWrites=rc.writes
   assert(tc.writes==(variant=='before'and 120 or 0)and rc.writes==(variant=='before'and 120 or 0))
   rc.writes=0;a.evaluation.summary.candidate.wins=3;frames(5);row.changedReportWrites=rc.writes;assert(report.text:find('胜利 3/3',1,true)and rc.writes==(variant=='before'and 5 or 1))
   a.mode='trial';a.trialIndex=2;a.lastDecision='bmove';frames(5);assert(title.text:find('2/3',1,true)and title.text:find('后退',1,true));row.trialText=title.text
   local modelsBefore=D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun')},false,true)
   local menu=ui:getChildByTag('training-menu');menu:getChildByTag('training-category-部位战术'):emit('Tapped');menu:getChildByTag('training-category-基础训练'):emit('Tapped');frames(5)
   assert(modelsBefore==D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun')},false,true));row.modelsUnchanged=true;tracked[title]=nil;tracked[report]=nil
   D.Director.entry:removeAllChildren();D.Director.ui3D:removeAllChildren();D.Entity:clear();D.Platformer.Data.store:clear();frames(5)
  end
 end,debug.traceback)
 if meta and newindex then meta.__newindex=newindex end
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
