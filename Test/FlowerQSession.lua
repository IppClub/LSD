local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-session-result.json'
local r={status='RUNNING'};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-team-native-result.json'),32));assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-team%-native%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-session-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local models=assert(require('Training.FlowerPractice').models());local initial=assert(D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-05/flower-q-first-models.json'),32))
  local equal=require('Training.FlowerIdentity').equal;local S=require('Training.FlowerQSession');local R=require('Training.FlowerTraceReview')
  local tables={'Game0FlowerCandidates','Game0FlowerCandidateEvidence','Game0FlowerTrials','Game0FlowerTeamTrials','Game0Training','Game0Training_wuyun','Game0MissionAttempts','Game0FlowerAdoptionState'}
  local function state()local rows={};for _,name in ipairs(tables)do rows[name]=D.DB:query('SELECT * FROM lsd.'..name)end;return D.json.encode(rows,false,true)end
  local before=state();local runs={}
  for _,mode in ipairs({'basic','explore','evaluate'})do
   r.phase=mode;save()
   local result=S.runAsync({mode=mode,models=models,initial=mode~='basic' and initial or nil,profile='near',seed=mode=='explore' and 41821 or nil,onProgress=function(b)r.elapsed=D.App.runningTime-b.started;r.hp={b.mentorHP,b.arena.studentHP,b.wuyun.studentHP};save()end})
   D.Content:save(root..'/Docs/evidence/2026-10-05/flower-q-'..mode..'-session.json',D.json.encode(result,false,true))
   assert(result.status=='won' or result.status=='failed');assert(R.rebuild(result.trace,result.episode,result.status))
   if mode=='explore'then
    assert(result.models,result.learningError)
    for _,id in ipairs({'ninilite','wuyun'})do assert(result.decisions[id].explored>0 and result.models[id].updates>initial[id].updates)end
    initial=result.models
   elseif mode=='evaluate'then
    assert(equal(initial,result.models))
    for _,id in ipairs({'ninilite','wuyun'})do assert(result.decisions[id].explored==0 and result.decisions[id].accepted>0)end
   end
   assert(state()==before,'Session changed adopted or recorded C4.5/mission state')
   r[mode]={status=result.status,seconds=result.report.seconds,decisions=result.decisions,evaluation=result.report.evaluation}
   runs[mode]=result;D.Content:save(root..'/Docs/evidence/2026-10-05/flower-q-'..mode..'-session.json',D.json.encode(result,false,true));save()
  end
  assert(equal(runs.basic.setup,runs.evaluate.setup));r.matchedSetup=true
  -- Early explicit cancellation is not a terminal training reward or model update.
  local cancelled=S.runAsync({mode='explore',models=models,initial=initial,profile='near',seed=99,cancelled=function()return true end})
  assert(cancelled.status=='aborted' and not cancelled.models and not cancelled.trace.trainable);r.cancelExcluded=true
  assert(state()==before);r.noProgressMutation=true
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
