-- Observe actual desktop input only; preparation copies an earned completion.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/ending-os-scroll-result.json';local r={status='RUNNING',osInput=true,scriptedPreparation=true,scriptedControls=false,events={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,why=xpcall(function()
  local prior=D.json.decode(assert(D.Content:load(assert(os.getenv('LSD_QA_PARENT_RESULT')))),32);assert(prior.status=='PASS'and prior.sameJourney)
  local db=D.Path(D.Content.writablePath,'ending-os-scroll-'..os.time()..'.db');assert(D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db;r.source=prior.database
  local function wait(fn,stage,t)
   r.stage=stage;save();local endAt=D.App.runningTime+(t or 150)
   while not fn()do assert(D.App.runningTime<endAt,'OS ending input timed out at '..stage);D.sleep(.03)end
  end
  D.App.winSize=D.Size(960,540);require('Start');local Hub=require('Ending.Hub')
  wait(function()return Hub.current and Hub.current.mode=='records'and Hub.current.view end,'loading',45)
  local view=Hub.current.view;local area=assert(view.bodyArea);local maximum=area.viewSize.height-area.contentSize.height;assert(maximum>0 and view.page==1)
  r.scrollMaximum=maximum;r.recordText=view.body.text;r.balance=prior.balanceAfter
  local function record(name)
   local file=D.Path(D.Content.writablePath,name..'.tga');D.App:saveScreenshot(file);D.sleep(.15)
   r.events[#r.events+1]={name=name,at=D.App.runningTime,page=view.page,offset=area.offset.y,path=file};save()
  end
  record('before-os-scroll')
  wait(function()return area.offset.y>=maximum-1 end,'await-wheel-bottom');D.sleep(.7)
  assert(math.abs(area.offset.y-maximum)<1 and view.page==1);assert(view.body.y-view.body.height>=19);record('os-wheel-bottom');r.wheelReachedLastLine=true
  wait(function()return view.page==2 end,'await-next');assert(math.abs(area.offset.y)<.01);record('os-next-page');r.nextResetScroll=true
  wait(function()return view.page==1 end,'await-previous');assert(math.abs(area.offset.y)<.01);record('os-previous-page');r.previousResetScroll=true
  wait(function()return area.offset.y>=maximum-1 end,'await-drag-bottom');D.sleep(.7);assert(math.abs(area.offset.y-maximum)<1);record('os-drag-bottom');r.dragReachedLastLine=true
  wait(function()return Hub.current and Hub.current.mode=='title'and Hub.current.phase=='ready'end,'await-return');r.returnedTitle=true
  local file=D.Path(D.Content.writablePath,'os-ending-title.tga');D.App:saveScreenshot(file);D.sleep(.15);r.titleScreenshot=file;save()
  wait(function()local w=D.Platformer.Data.store.world;return w and w.tag=='RDRoom'and w.academyLoss and w.jadeArrival and w.jadeArrival.phase=='ready'end,'await-explore',150)
  assert(not require('Story.Availability').canDeploy('wuyun'));assert(D.Platformer.Data.store.world.academyLoss.recorded);r.damagedAcademyPreserved=true
  local E=require('Economy.Store');assert(E.open());r.balanceAfter=E.wallet().available;assert(r.balanceAfter==r.balance and not E.active());r.stage='os-scroll-return-explore-complete'
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and why or nil;save()
end)
