-- Cold-start the legitimately completed packaged journey, with no save edits.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/fresh-ending-resume-current-result.json';local r={status='RUNNING',osInput=false}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(os.getenv('LSD_QA_PARENT_RESULT') or '/private/tmp/lsd-earned-ending-20261007/result.json'),32)
  assert(prior.status=='PASS'and prior.sameJourney and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/fresh%-ending%-current%-%d+%.db$'))
  local db=D.Content.writablePath..'/fresh-ending-resume-current-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);r.database=db;r.source=prior.database
  D.Director.entry:slot('Cleanup',function()if D.DB:existDB('lsd')then D.DB:exec('DETACH DATABASE lsd')end end)
  local function wait(fn,t)local deadline=D.App.runningTime+(t or 30);while not fn()do assert(D.App.runningTime<deadline,'Ending cold resume stalled');D.sleep(.03)end end
  local E=require('Economy.Store');assert(E.open());assert(E.wallet().available==prior.balanceAfter and not E.active());r.balance=E.wallet().available
  local tables={'Game0MissionAttempts','Game0MissionUnlocks','Game0SupplyWallet','Game0StoryNodes','Game0StoryPerformances','Game0EndingViews','Game0Training','Game0Training_wuyun'};local before={}
  for _,name in ipairs(tables)do before[name]=D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true)end
  r.screenshots={}
  local function capture(node,name)
   for _,size in ipairs({D.Size(960,540),D.Size(683,384)})do
    D.App.winSize=size;D.sleep(.2)
    local file=D.Path(D.Content.writablePath,name..'-'..string.format('%d',D.App.bufferSize.width)..'.tga');D.App:saveScreenshot(file);D.sleep(.1)
    r.screenshots[#r.screenshots+1]={name=name,width=D.App.bufferSize.width,height=D.App.bufferSize.height,path=file};save()
   end
  end
  require('Start');local Hub=require('Ending.Hub');wait(function()return Hub.current and Hub.current.mode=='records'and Hub.current.view end,45)
  assert(not D.Platformer.Data.store.world);local view=Hub.current.view;local records=view.records
  assert(require('Training.Summary').matches(prior.final.learner,records.finalModel) and records.evacuation.economy.cost==prior.final.economy.cost)
  assert(records.currentModel and records.auxiliaryVariant==prior.final.auxiliary.variant)
  r.missions=records.missions;r.roster=records.roster;r.recordsResumed=true
  r.recordPages={}
  for page=1,#view.pages do
   assert(view.page==page and view.phase=='reading');D.sleep(.1)
   local bottom=view.body.y-view.body.height
   r.recordPages[#r.recordPages+1]={page=page,title=view.pages[page].title,bodyHeight=view.body.height,bodyBottom=bottom,text=view.body.text};save()
   if view.bodyArea then
    local area=view.bodyArea;r.recordPages[#r.recordPages].observedArea={offsetY=area.offset.y,height=area.contentSize.height,bottom=area.y-area.contentSize.height/2};save();assert(area.offset.y==0 and area.contentSize.height==510 and area.y-area.contentSize.height/2>=180)
    assert(area.viewSize.height>=view.body.height+40 and view.body.text==view.pages[page].body:gsub('🐚','（贝壳）'))
    capture(view.node,'ending-records-'..page..'-top')
    local offset=math.max(0,area.viewSize.height-area.contentSize.height);area:scrollTo(D.Vec2(0,offset));D.sleep(.1)
    assert(math.abs(area.offset.y-offset)<.01 and view.body.y-view.body.height>=19.9,'Last body line unreachable')
    r.recordPages[#r.recordPages].scrollMax=offset;r.recordPages[#r.recordPages].lastLineBottom=view.body.y-view.body.height;save()
    if offset>0 then capture(view.node,'ending-records-'..page..'-bottom')end
   else
    capture(view.node,'ending-records-'..page)
    assert(bottom>=180,'Ending records body overlaps footer/buttons on page '..page)
   end
   if page<#view.pages then view.next:emit('Tapped');wait(function()return view.page==page+1 and view.phase=='reading'end)end
  end
  view.close:emit('Tapped');wait(function()return Hub.current and Hub.current.mode=='title'and Hub.current.phase=='ready'end)
  capture(Hub.current.node,'ending-title')
  Hub.current.explore:emit('Tapped');wait(function()local w=D.Platformer.Data.store.world;return w and w.tag=='RDRoom'and w.academyLoss and w.jadeArrival and w.jadeArrival.phase=='ready'end,45)
  local w=D.Platformer.Data.store.world;assert(w.academyLoss.recorded and w.academyLoss.damageNode and not w.storyFlow)
  assert(not require('Story.Availability').canDeploy('wuyun'));r.damagedAcademyPreserved=true
  for _,name in ipairs(tables)do assert(before[name]==D.json.encode(D.DB:query('SELECT * FROM lsd.'..name..' ORDER BY 1'),false,true),'Resume changed '..name)end
  r.noDuplicateRewards=true;r.balanceAfter=E.wallet().available
 end,debug.traceback)
 r.status=ok and'PASS'or'FAIL';r.error=not ok and err or nil;save();print('LSD_FRESH_ENDING_RESUME_CURRENT_'..r.status)
end)
