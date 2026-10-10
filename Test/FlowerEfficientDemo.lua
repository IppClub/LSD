-- Natural full-skill combat on a fresh disposable save. QA drives public demo
-- controls; its observations are not a claim of real-user training or adoption.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-efficient-demo-result.json'
local r={status='RUNNING'};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-authored-combat-result.json'),32));assert(prior.status=='PASS');local source=prior.database;assert(D.Path:getFilename(source):match('^flower%-authored%-combat%-%d+%.db$'));local dest=D.Content.writablePath..'/flower-efficient-demo-'..os.time()..'.db'
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
  for _,record in ipairs(assert(Store.history('ninilite')))do if record.controller=='basic'then records.basic=record;break end end
  assert(records.basic and records.basic.setup.bossScale==1)
  r.basic={status=records.basic.status,seconds=records.basic.seconds,evaluation=records.basic.evaluation};r.baselineFromMatchingArchive=true
  local oldHistory=assert(require('Training.FlowerPracticeStore').history('ninilite'))

  local c=P.openAsync(nil,'ninilite');local b=c.battle;local a=c.arena
  assert(c.coverage and c.coverage.total>0,'Prior demonstration not preserved')
  D.sleep(.3);c.startButton:emit('Tapped');c.hud.move:emit('Right',true)
  local moving=true;local moveKey='Right';local destination=b.roots[3].enemy.x-500;local releaseAt;local started=D.App.totalTime;local lastFlank=started;local onRight=false
  while b.phase=='playing' or b.phase=='saving'do
   assert(D.App.totalTime-started<135,'Natural demo stalled')
   if b.phase=='playing'then
    if moving and ((moveKey=='Right' and a.student.x>=destination-10) or (moveKey=='Left' and a.student.x<=destination+10))then c.hud.move:emit(moveKey,false);c.wait:emit('TapBegan');moving=false end
    if releaseAt and D.App.runningTime>=releaseAt then c.hud.weapon:emit('TapEnded');releaseAt=nil
    elseif not moving and not releaseAt and a:available('laser') and not c.aim.shot then
     -- QA chooses visible, not-yet-known or still-armored parts, using only
     -- feedback knowledge. No hidden armor values or future impact locations.
     local angle
     for _,part in ipairs({'petal-left','flower-core','petal-right','roots'})do
      local known=b.partCombat.known[part]
      if not known or known.ap>0 then local ray=b.partCombat:aim(a.student,part,true);if ray then angle=ray.angle;break end end
     end
     if angle then
      c.hud.weapon:emit('TapBegan')
      if math.abs(angle)>3 then local hold=(45-angle)/180;if hold<=.15 then hold=(angle+135)/180 end;releaseAt=D.App.runningTime+hold
      else c.hud.weapon:emit('TapEnded')end
     else
      c.wait:emit('TapBegan')
      local potential=false;for _,part in ipairs({'petal-left','flower-core','petal-right','roots'})do local known=b.partCombat.known[part];if not known or known.ap>0 then potential=true end end
      if potential and D.App.totalTime-lastFlank>10 then
       onRight=not onRight;destination=b.roots[3].enemy.x+(onRight and 450 or -500);moveKey=destination>a.student.x and 'Right' or 'Left'
       c.hud.move:emit(moveKey,true);moving=true;lastFlank=D.App.totalTime
      end
     end
    end
    for _,state in pairs(b.effects.states)do if D.App.runningTime<(state.confusedUntil or 0)then c.song:emit('TapBegan');break end end
   end
   r.phase='demo';r.elapsed=D.App.totalTime-started;save();D.sleep(.02)
  end
  assert(c.result and c.result.saved,b.saveError);r.demo={status=b.phase,coverage=c.coverage,evaluation=c.result.report.evaluation};save()
  local beforeCandidate=c.candidate
  local latestHistory=assert(require('Training.FlowerPracticeStore').history('ninilite'));assert(#latestHistory==#oldHistory+1)
  for i,old in ipairs(oldHistory)do assert(require('Training.FlowerIdentity').equal(old,latestHistory[i]))end
  local newest=latestHistory[#latestHistory];local only=assert(require('Training.FlowerPolicy').collect({newest},'ninilite'))
  r.latestCoverage=only.coverage;r.historyPreserved=true
  c.learnLatestButton:emit('Tapped');local deadline=D.App.totalTime+20
  while c.candidate==beforeCandidate and not c.learningError do assert(D.App.totalTime<deadline,'Learning stalled');D.sleep(.02)end
  assert(c.candidate~=beforeCandidate and not c.learningError,c.learningError);assert(#c.candidate.sourceEpisodes==1 and c.candidate.sourceEpisodes[1]==newest.episode and c.candidate.sampleCount==#only.samples);r.latestOnly=true;r.model={samples=c.candidate.sampleCount,version=c.candidate.actionSetVersion,rules=c.candidate.rules};assert(progress()==before);save()
  evaluate('candidate')
  r.comparison=assert(require('Training.FlowerComparison').build(records.basic,records.candidate))
  r.progressUnchanged=progress()==before;assert(r.progressUnchanged)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
