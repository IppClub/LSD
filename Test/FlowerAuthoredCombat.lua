-- Natural full-skill combat on a fresh disposable save. QA drives public demo
-- controls; its observations are not a claim of real-user training or adoption.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-authored-combat-result.json'
local r={status='RUNNING'};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local source=D.Content.writablePath..'/lsd-medical-visit-qa-1791007987.db';local dest=D.Content.writablePath..'/flower-authored-combat-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and not D.Content:exist(dest) and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local P=require('Training.FlowerPractice');local Store=require('Training.FlowerTrialStore')
  local function progress()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0MissionUnlocks')},false,true)end
  local before=progress();local records={}
  local function evaluate(mode)
   local c=P.openAsync(nil,'ninilite',nil,nil,nil,'field');D.sleep(.3)
   if mode=='basic'then c.basicButton:emit('Tapped')else c.trialButton:emit('Tapped')end
   assert(c.mode==mode and c.battle.roots[3].enemy.playable.scaleX==1)
   local started=D.App.totalTime
   while c.battle.phase=='playing' or c.battle.phase=='saving'do
    assert(D.App.totalTime-started<135,'Natural evaluation stalled');r.phase=mode;r.elapsed=D.App.totalTime-started;save();D.sleep(.5)
   end
   assert(c.result and c.result.trialSaved,c.battle.saveError)
   local record=assert(Store.latest('ninilite'));assert(record.status~='aborted' and record.setup.bossScale==1 and record.episode.versions.aim==1)
   records[mode]=record;r[mode]={status=record.status,seconds=record.seconds,evaluation=record.evaluation};assert(progress()==before);save()
  end
  evaluate('basic')
  local c=P.openAsync(nil,'ninilite');local b=c.battle;local a=c.arena
  assert(c.coverage and c.coverage.total==0,'Demo source was not empty')
  D.sleep(.3);c.startButton:emit('Tapped');c.hud.move:emit('Right',true)
  local moving=true;local releaseAt;local started=D.App.totalTime
  while b.phase=='playing' or b.phase=='saving'do
   assert(D.App.totalTime-started<135,'Natural demo stalled')
   if b.phase=='playing'then
    if moving and b.roots[3].enemy.x-a.student.x<=500 then c.hud.move:emit('Right',false);c.wait:emit('TapBegan');moving=false end
    if releaseAt and D.App.runningTime>=releaseAt then c.hud.weapon:emit('TapEnded');releaseAt=nil
    elseif not moving and not releaseAt and a:available('laser') and not c.aim.shot then
     -- QA chooses visible, not-yet-known or still-armored parts, using only
     -- feedback knowledge. No hidden armor values or future impact locations.
     local angle
     for _,part in ipairs({'petal-left','flower-core','petal-right','roots'})do
      local known=b.partCombat.known[part]
      if not known or known.ap>0 then local ray=b.partCombat:aim(a.student,part,true);if ray then angle=ray.angle;break end end
     end
     c.hud.weapon:emit('TapBegan')
     if angle and math.abs(angle)>3 then
      local hold=(45-angle)/180;if hold<=.15 then hold=(angle+135)/180 end
      releaseAt=D.App.runningTime+hold
     else c.hud.weapon:emit('TapEnded')end
    end
    for _,state in pairs(b.effects.states)do if D.App.runningTime<(state.confusedUntil or 0)then c.song:emit('TapBegan');break end end
   end
   r.phase='demo';r.elapsed=D.App.totalTime-started;save();D.sleep(.02)
  end
  assert(c.result and c.result.saved,b.saveError);r.demo={status=b.phase,coverage=c.coverage,evaluation=c.result.report.evaluation};save()
  c.learnButton:emit('Tapped');local deadline=D.App.totalTime+20
  while not c.candidate and not c.learningError do assert(D.App.totalTime<deadline,'Learning stalled');D.sleep(.02)end
  assert(c.candidate,c.learningError);r.model={samples=c.candidate.sampleCount,version=c.candidate.actionSetVersion,rules=c.candidate.rules};assert(progress()==before);save()
  evaluate('candidate')
  r.comparison=assert(require('Training.FlowerComparison').build(records.basic,records.candidate))
  r.progressUnchanged=progress()==before;assert(r.progressUnchanged)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
