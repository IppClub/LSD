-- Wu public melee demonstration, native C4.5 and eight natural trials.
-- Review/adoption stays conditional on real results, on a named QA copy only.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-wuyun-current-result.json'
local r={status='RUNNING'};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-adoption-current-result.json'),32));assert(prior.status=='PASS');local source=prior.database;assert(D.Path:getFilename(source):match('^flower%-adoption%-current%-%d+%.db$'));local dest=D.Content.writablePath..'/flower-wuyun-current-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and not D.Content:exist(dest) and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local P=require('Training.FlowerPractice');local Store=require('Training.FlowerTrialStore')
  local function progress()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0MissionUnlocks')},false,true)end
  local before=progress();local records={}
  local function evaluate(mode,scenario)
   local c=P.openAsync(nil,'wuyun',nil,nil,nil,scenario);D.sleep(.3)
   if mode=='basic'then c.basicButton:emit('Tapped')else c.trialButton:emit('Tapped')end
   assert(c.mode==mode and c.battle.roots[3].enemy.playable.scaleX==1)
   local started=D.App.totalTime
   while c.battle.phase=='playing' or c.battle.phase=='saving'do
    assert(D.App.totalTime-started<135,'Natural evaluation stalled');r.phase=scenario..'-'..mode;r.elapsed=D.App.totalTime-started;save();D.sleep(.5)
   end
   assert(c.result and c.result.trialSaved,c.battle.saveError)
   local record=assert(Store.latest('wuyun'));assert(record.status~='aborted' and record.setup.bossScale==1 and record.episode.versions.aim==1)
   records[scenario]=records[scenario] or {};records[scenario][mode]=record;r[scenario]=r[scenario] or {};r[scenario][mode]={status=record.status,seconds=record.seconds,evaluation=record.evaluation};assert(progress()==before);save()
  end
  -- Teach through the same movement/melee/wait/song controls as the player.
  -- Nearest visible enemy and distance guide QA input; no fabricated labels,
  -- hidden armor, fixed poses, disabled skills, or edited HP are used.
  local demo=P.openAsync(nil,'wuyun');D.sleep(.3);demo.startButton:emit('Tapped')
  local b=demo.battle;local a=demo.arena;local held
  local function move(side)
   if held==side then return end
   if held then demo.hud.move:emit(held,false)end
   held=side;if held then demo.hud.move:emit(held,true)end
  end
  local started=D.App.totalTime
  while b.phase=='playing' or b.phase=='saving'do
   assert(D.App.totalTime-started<135,'Wu demonstration stalled')
   if b.phase=='playing'then
    local target=b:target(a.student)
    if target then
     local dx=target.enemy.x-a.student.x
     if math.abs(dx)>180 and not a:isAttacking() then move(dx>0 and 'Right' or 'Left')
     else move(nil);if a:available('melee')then demo.melee:emit('TapBegan')elseif not a:isAttacking()then demo.wait:emit('TapBegan')end end
    else move(nil)end
    for _,state in pairs(b.effects.states)do if D.App.runningTime<(state.confusedUntil or 0)then demo.song:emit('TapBegan');break end end
   end
   r.phase='wuyun-demo';r.elapsed=D.App.totalTime-started;save();D.sleep(.04)
  end
  move(nil);assert(demo.result and demo.result.saved,b.saveError)
  local history=assert(require('Training.FlowerPracticeStore').history('wuyun'))
  local latest=history[#history];local samples=assert(require('Training.FlowerPolicy').collect({latest},'wuyun'))
  r.demo={status=b.phase,coverage=samples.coverage,evaluation=demo.result.report.evaluation}
  demo.learnLatestButton:emit('Tapped');local deadline=D.App.totalTime+20
  while not demo.candidate and not demo.learningError do assert(D.App.totalTime<deadline);D.sleep(.02)end
  assert(demo.candidate,demo.learningError);r.wuSamples=demo.candidate.sampleCount;r.model=demo.candidate
  assert(#demo.candidate.sourceEpisodes==1 and demo.candidate.sourceEpisodes[1]==latest.episode);assert(progress()==before);save()
  local history=assert(require('Training.FlowerPracticeStore').history('wuyun'))
  for _,profile in ipairs({'near','far','reproduction','field'})do evaluate('basic',profile);evaluate('candidate',profile)end
  r.comparisons={}
  for profile,pair in pairs(records)do r.comparisons[profile]=assert(require('Training.FlowerComparison').build(pair.basic,pair.candidate))end
  r.historyPreserved=require('Training.FlowerIdentity').equal(history,assert(require('Training.FlowerPracticeStore').history('wuyun')));assert(r.historyPreserved)
  local c=P.openAsync(nil,'wuyun');D.sleep(.3);c.adoptionButton:emit('Tapped')
  local panel=assert(c.adoptionView);r.ready=panel.ready;r.review=panel.review
  assert(panel.bundle and panel.review.required==4)
  assert(not panel.adopt.visible)
  panel.adopt:emit('Tapped');assert(not require('Training.FlowerAdoptionStore').inspect('wuyun'),'Adopted without reviewing pages')
  for i=1,4 do panel.next:emit('Tapped')end
  if panel.ready then
   assert(panel.adopt.visible);panel.adopt:emit('Tapped')
   local deadline=D.App.totalTime+30;while panel.busy do assert(D.App.totalTime<deadline,'Adoption stalled');D.sleep(.02)end
   assert(panel.saved,panel.error);local saved=assert(require('Training.FlowerAdoptionStore').load('wuyun'));assert(saved.bundle.source.policy.sampleCount==r.wuSamples)
   r.adoptedId=saved.id
   panel.back:emit('Tapped');c.adoptionButton:emit('Tapped');panel=assert(c.adoptionView);assert(panel.deployed and panel.current.id==saved.id)
   r.reopened=true
   D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-wuyun-current.tga');D.sleep(.2)
   panel.rollback:emit('Tapped');panel.confirmRollback:emit('Tapped');while panel.busy do assert(D.App.totalTime<deadline);D.sleep(.02)end
   assert(not panel.current and panel.message=='已恢复基础成果。');r.restoredBasic=true
  else
   assert(not panel.adopt.visible);r.blockedCorrectly=true
  end
  panel.back:emit('Tapped')
  r.progressUnchanged=progress()==before;assert(r.progressUnchanged)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
