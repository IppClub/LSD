-- Natural terminal trials. No forced damage, frozen enemies or fabricated wins.
local script,source=...;local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(script))
local out=root..'/Test/flower-comparison-result.json';D.Content:save(out,'{"status":"RUNNING"}')
D.thread(function()
 local r={status='RUNNING'};local function save()D.Content:save(out,D.json.encode(r))end
 local ok,err=xpcall(function()
  assert(D.Path:getPath(source)==D.Content.writablePath and D.Path:getFilename(source):match('^flower%-learning%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-comparison-'..os.time()..'.db'
  assert(not D.DB:existDB('lsd') and not D.Content:exist(dest) and D.Content:copyAsync(source,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0)
  require('Data.Config'):loadAsync()
  local P=require('Training.FlowerPractice');local C=require('Training.FlowerComparison');local Store=require('Training.FlowerTrialStore')
  local function progress()return D.json.encode({D.DB:query('SELECT * FROM lsd.Game0Training'),D.DB:query('SELECT * FROM lsd.Game0Training_wuyun'),D.DB:query('SELECT * FROM lsd.Game0MissionAttempts'),D.DB:query('SELECT * FROM lsd.Game0MissionUnlocks'),D.DB:query('SELECT * FROM lsd.Game0FlowerCandidates'),D.DB:query('SELECT * FROM lsd.Game0FlowerPractice')},false,true)end
  local original=progress();local records={}
  for _,mode in ipairs({'basic','candidate'})do
   local c=P.openAsync(nil,'ninilite');D.sleep(.3)
   if mode=='basic'then c.basicButton:emit('Tapped')else c.trialButton:emit('Tapped')end
   assert(c.mode==mode and c.battle.phase=='playing')
   local start=D.App.totalTime
   while c.battle.phase=='playing' or c.battle.phase=='saving'do
    assert(D.App.totalTime-start<135,'Natural trial timeout')
    r.mode=mode;r.elapsed=D.App.totalTime-start;r.phase=c.battle.phase;r.hp=c.arena.studentHP;save();D.sleep(.5)
   end
   assert(c.result and c.result.trialSaved,'Trial failed to persist: '..tostring(c.battle.saveError))
   records[mode]=assert(Store.latest('ninilite'));assert(records[mode].controller==mode and records[mode].status~='aborted')
   assert(progress()==original,'Trial changed progression, model or demonstrations')
  end
  local comparison=assert(C.build(records.basic,records.candidate));r.comparison=comparison
  assert(comparison.adoptionEligible==false and comparison.scope=='single-pair-observation')
  local reloaded=P.openAsync(nil,'ninilite');assert(reloaded.comparison and reloaded.comparison.basicEpisode==records.basic.episode.episode and reloaded.comparison.candidateEpisode==records.candidate.episode.episode)
  local function clone(v)return D.json.decode(D.json.encode(v),32)end
  local aborted=clone(records.basic);aborted.status='aborted';local no,why=C.build(aborted,records.candidate);assert(not no and why=='ABORTED_TRIAL')
  local mismatch=clone(records.candidate);mismatch.setup.models.wuyun.trainingAccuracy=.123;local no,why=C.build(records.basic,mismatch);assert(not no and why=='SETUP_MISMATCH')
  assert(not C.latest('ninilite',{},assert(P.models())),'Stale candidate comparison selected')
  D.App.winSize=D.Size(683,384);D.sleep(.2);D.App:saveScreenshot(root..'/Docs/evidence/2026-10-05/flower-comparison.tga');D.sleep(.2)
  r.naturalTerminal=true;r.reloaded=true;r.abortedRejected=true;r.configurationMismatchRejected=true;r.progressUnchanged=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
