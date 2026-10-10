local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-coaching-result.json';local r={status='RUNNING',actors={}}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-demonstration-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/disarm%-demo%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-coaching-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn)local limit=D.App.runningTime+20;while not fn()do assert(D.App.runningTime<limit);D.sleep(.05)end end
  local function snapshot()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0DisarmCandidates'),D.DB:query('SELECT * FROM lsd.Game0DisarmObservations')},false,true)end
  local before=snapshot();local Coaching=require('Training.DisarmCoaching')
  for _,actor in ipairs({'ninilite','wuyun'})do
   require('Training.Level')(nil,actor);wait(function()local controls=D.Director.ui3D:getChildByTag('training-controls');return controls and controls.arena and controls.arena.character.id==actor end)
   local controls=D.Director.ui3D:getChildByTag('training-controls');controls:getChildByTag('training-menu'):getChildByTag('缴械补练'):emit('Tapped')
   local view=assert(D.Director.ui3D:getChildByTag('disarm-coaching'));assert(not controls.visible and not view.retryButton.visible)
   local report=assert(view.coaching);local candidate=assert(require('Training.DisarmPolicyStore').loadLatestAsync(actor));assert(report.samples==candidate.model.sampleCount and report.actor==actor)
   local total=0;for _,count in pairs(report.actions)do total=total+count end;assert(total==report.samples)
   assert(view.label.text:find('不会自动采用',1,true));collectgarbage('collect');assert(view.coaching)
   r.actors[actor]=report;D.sleep(.2);r.screenshot=D.Content.writablePath..'/coaching-'..actor..'.tga';D.App:saveScreenshot(r.screenshot);D.sleep(.2)
   if view.area.viewSize.height>view.area.height then view.area:scrollToPosY(-10000,0);D.sleep(.1);r.scrolled=true end
   view.backButton:emit('Tapped');assert(controls.visible and not D.Director.ui3D:getChildByTag('disarm-coaching'))
  end
  local empty=assert(Coaching.review({},'ninilite'));assert(empty.samples==0 and Coaching.text(empty):find('至少6',1,true));assert(not Coaching.review({},'fox'))
  local Store=require('Training.DisarmStore');local records={};for _,id in ipairs(assert(Store.listAsync()))do local row=assert(Store.loadAsync(id));if row.source.trace.demonstrator=='wuyun'then records[#records+1]=row end end
  assert(Coaching.review(records,'ninilite').samples==0,'Other actor leaked into coaching')
  assert(snapshot()==before);r.unchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;save()
end)
