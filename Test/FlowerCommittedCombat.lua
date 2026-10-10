-- Paired full-skill trials on a disposable copy of the existing 52-sample
-- candidate. No retraining, fabricated hits, enemy disabling, or adoption.
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-committed-combat-result.json'
local r={status='RUNNING'};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-efficient-demo-result.json'),32));assert(prior.status=='PASS');local source=prior.database;assert(D.Path:getFilename(source):match('^flower%-efficient%-demo%-%d+%.db$'));local dest=D.Content.writablePath..'/flower-committed-combat-'..os.time()..'.db'
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
  local previous=assert(Store.history('ninilite'))
  local history=assert(require('Training.FlowerPracticeStore').history('ninilite'))
  evaluate('basic');evaluate('candidate')
  assert(records.basic.setup.aimPolicy==require('Factory.PartCombat').aimPolicy)
  assert(records.candidate.setup.aimPolicy==records.basic.setup.aimPolicy)
  local shots={};for _,step in ipairs(records.candidate.episode.steps)do
   if step.action.aimSource=='part-policy-v1'then shots[#shots+1]={action=step.action,hits=step.hits}end
  end
  r.targetedShots=shots
  r.historyPreserved=require('Training.FlowerIdentity').equal(history,assert(require('Training.FlowerPracticeStore').history('ninilite')));assert(r.historyPreserved)
  local oldBasic;for _,record in ipairs(previous)do if record.controller=='basic'then oldBasic=record;break end end
  assert(oldBasic and not require('Training.FlowerComparison').build(oldBasic,records.candidate),'Old aim-policy baseline accepted')
  r.legacyComparisonRejected=true
  r.comparison=assert(require('Training.FlowerComparison').build(records.basic,records.candidate))
  r.progressUnchanged=progress()==before;assert(r.progressUnchanged)
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
