local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/disarm-demonstration-result.json';local r={status='RUNNING',cases={}}
D.Content:save(out,D.json.encode(r,false,true))
D.thread(function()
 local ok,err=xpcall(function()
  local prior=D.json.decode(D.Content:load(root..'/Test/disarm-performance-result.json'),32)
  assert(prior.status=='PASS'and prior.database:match('^/private/tmp/lsd%-combat%-qa%-.+/save/lsd%-disarm%-practice%-qa%-%d+%.db$'))
  local db=D.Content.writablePath..'/disarm-demo-'..os.time()..'.db';r.database=db
  assert(not D.DB:existDB('lsd')and D.Content:copyAsync(prior.database,db));assert(D.DB:exec("ATTACH DATABASE '"..db.."' AS lsd")>=0);require('Data.Config'):loadAsync()
  local function wait(fn)local endAt=D.App.runningTime+15;while not fn()do assert(D.App.runningTime<endAt,'Demonstration timeout');D.sleep(.02)end end
  local function saved()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts')},false,true)end
  local before=saved()
  for _,id in ipairs({'ninilite','wuyun'})do
   require('Training.Level')(nil,id);wait(function()local ui=D.Director.ui3D:getChildByTag('training-controls');return ui and ui.arena.character.id==id end)
   D.Director.ui3D:getChildByTag('training-controls'):getChildByTag('training-menu'):getChildByTag('缴械示范'):emit('Tapped')
   wait(function()return D.Director.ui3D:getChildByTag('disarm-supply-loadout')end)
   local budget=D.Director.ui3D:getChildByTag('disarm-supply-loadout');assert(budget.noteLabel.text:find('亲自控制',1,true));budget.saveButton:emit('Tapped')
   wait(function()return D.Platformer.Data.store.world and D.Platformer.Data.store.world.patrolLevel end)
   local c=D.Platformer.Data.store.world.patrolLevel;local b=c.battle;local a=assert(b.demonstrator);assert(a.character.id==id)
   c.start:emit('Tapped');wait(function()return b.phase=='playing'and a.student.onSurface end);assert(a.mode=='demo')
   local x=a.student.x;c.hud.move:emit('Right',true);D.sleep(.35);c.hud.move:emit('Right',false);assert(a.student.x>x+20,'Unified joystick did not move learner')
   c.hud.weapon:emit('TapBegan');D.sleep(.05);c.hud.weapon:emit('TapEnded')
   wait(function()for _,s in ipairs(b.disarmTrace.executions)do if s.actor==id and s.action=='laser'and s.source=='demo'and s.outcome=='completed'then return true end end end)
   for i=1,2 do c.hud.move:emit('Left',true);D.sleep(.25);c.hud.move:emit('Left',false);D.sleep(.2);c.hud.move:emit('Right',true);D.sleep(.25);c.hud.move:emit('Right',false);D.sleep(.2)end
   if id=='wuyun'then assert(c.melee);c.melee:emit('TapBegan');wait(function()for _,s in ipairs(b.disarmTrace.executions)do if s.actor==id and s.action=='melee'and s.source=='demo'and s.outcome=='completed'then return true end end end)end
   D.sleep(.2);r.screenshots=r.screenshots or{};r.screenshots[id]=D.Content.writablePath..'/disarm-demo-'..id..'.tga';D.App:saveScreenshot(r.screenshots[id]);D.sleep(.2)
   assert(a.metrics.modelActions==0,'Adopted model controlled manual learner');assert(b.mentorHits==0,'Manual shot fired mentor weapon')
   c.withdraw:emit('Tapped');wait(function()return c.phase=='result'and b.disarmTrace.sourceSaveState=='saved'end)
   local archived=assert(require('Training.DisarmStore').loadLatestAsync());assert(archived.source.trace.demonstrator==id);assert(b.disarmTrace.executionReview,b.disarmTrace.executionReviewError)
   local demo,other=0,0
   for _,s in ipairs(archived.source.trace.executions)do if s.actor==id then assert(s.source=='demo');demo=demo+1 elseif s.source=='model'or s.source=='baseline'then other=other+1 end end
   assert(demo>=3 and other>0);r.cases[#r.cases+1]={character=id,demo=demo,other=other,cost=b.disarmTrace.virtualResult.cost}
   c.result.againButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('disarm-supply-loadout')end);D.Director.ui3D:getChildByTag('disarm-supply-loadout').closeButton:emit('Tapped');wait(function()return D.Director.ui3D:getChildByTag('training-controls')end)
   local controls=D.Director.ui3D:getChildByTag('training-controls');controls:getChildByTag('training-menu'):getChildByTag('学习缴械'):emit('Tapped');wait(function()return controls.arena.mode~='building'end)
   assert(controls.arena.message:find('已保存',1,true),controls.arena.message)
   local candidate,why=require('Training.DisarmPolicyStore').loadLatestAsync(id);assert(candidate,why);assert(candidate.model.sampleCount>=6 and candidate.model.algorithm=='disarm-c45')
   r.cases[#r.cases].candidate=candidate.id;r.cases[#r.cases].samples=candidate.model.sampleCount;r.cases[#r.cases].accuracy=candidate.model.trainingAccuracy
   assert(saved()==before)
  end
  r.progressUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS'or'FAIL';r.error=not ok and err or nil;D.Content:save(out,D.json.encode(r,false,true))
end)
