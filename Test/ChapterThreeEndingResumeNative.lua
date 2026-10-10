-- Cold-start the legitimately completed packaged journey, with no save edits.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/chapter-three-ending-resume-result.json';local r={status='RUNNING',osInput=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/chapter-three-ending-result.json'),32)
  assert(prior.status=='PASS'and prior.sameJourney and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/chapter%-three%-ending%-%d+%.db$'))
  local db=D.Content.writablePath..'/chapter-three-ending-resume-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db;r.source=prior.database
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Ending cold resume stalled');D.sleep(.03)end end
  local E=require('Economy.Store');assert(E.open());assert(E.wallet().available==prior.balanceAfter and not E.active());r.balance=E.wallet().available
  local tables={'Game0MissionAttempts','Game0MissionUnlocks','Game0SupplyWallet','Game0StoryNodes','Game0StoryPerformances','Game0EndingViews'};local before={}
  for _,name in ipairs(tables)do before[name]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true)end
  require('Start');local Hub=require('Ending.Hub');wait(function()return Hub.current and Hub.current.mode=='records'and Hub.current.view end,45)
  assert(not D.Platformer.Data.store.world);local view=Hub.current.view;local records=view.records
  assert(require('Training.Summary').matches(prior.final.learner,records.finalModel) and records.evacuation.economy.cost==prior.final.economy.cost)
  assert(records.currentModel and records.auxiliaryVariant==prior.final.auxiliary.variant)
  r.missions=records.missions;r.roster=records.roster;r.recordsResumed=true
  view.close:emit('Tapped');wait(function()return Hub.current and Hub.current.mode=='title'and Hub.current.phase=='ready'end)
  Hub.current.explore:emit('Tapped');wait(function()local w=D.Platformer.Data.store.world;return w and w.tag=='RDRoom'and w.academyLoss and w.jadeArrival and w.jadeArrival.phase=='ready'end,45)
  local w=D.Platformer.Data.store.world;assert(w.academyLoss.recorded and w.academyLoss.damageNode and not w.storyFlow)
  assert(not require('Story.Availability').canDeploy('wuyun'));r.damagedAcademyPreserved=true
  for _,name in ipairs(tables)do assert(before[name]==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Resume changed '..name)end
  r.noDuplicateRewards=true;r.balanceAfter=E.wallet().available
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save();print('LSD_CHAPTER_THREE_ENDING_RESUME_'..r.status)
end)
