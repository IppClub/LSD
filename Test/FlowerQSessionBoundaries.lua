local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-session-boundaries-result.json'
local r={status='RUNNING'};local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local prior=assert(D.json.decode(D.Content:load(root..'/Test/flower-team-native-result.json'),32));assert(prior.status=='PASS')
  assert(prior.database:match('^/private/tmp/lsd%-shan%-%d+/save/flower%-team%-native%-%d+%.db$'))
  local dest=D.Content.writablePath..'/flower-q-session-boundaries-'..os.time()..'.db';assert(D.Content:copyAsync(prior.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local models=assert(require('Training.FlowerPractice').models());local initial=assert(D.json.decode(D.Content:load(root..'/Docs/evidence/2026-10-05/flower-q-first-models.json'),32))
  local equal=require('Training.FlowerIdentity').equal;local S=require('Training.FlowerQSession');local R=require('Training.FlowerTraceReview')
  local tables={'Game0FlowerCandidates','Game0FlowerCandidateEvidence','Game0FlowerTrials','Game0FlowerTeamTrials','Game0Training','Game0Training_wuyun','Game0MissionAttempts','Game0FlowerAdoptionState'}
  local function state()local rows={};for _,name in ipairs(tables)do rows[name]=D.DB:query('SELECT * FROM lsd.'..name)end;return D.json.encode(rows,false,true)end
  local before=state()
  local options={mode='evaluate',models=models,initial=initial,profile='near',cancelled=function()return true end}
  options.onStart=function()
   options.mode='explore';options.initial.ninilite.algorithm='changed-by-caller';options.models.ninilite.sampleCount=999
  end
  local frozenInitial=D.json.decode(D.json.encode(initial,false,true),32)
  local result=S.runAsync(options)
  assert(result.status=='aborted' and result.mode=='evaluate' and equal(result.models,frozenInitial) and not result.trace.trainable)
  assert(result.baseModels.ninilite.sampleCount~=999 and state()==before);r.frozenInputs=true;r.cancelExcluded=true
  assert(not pcall(S.runAsync,{mode='explore',models=result.baseModels,profile='near'}))
  assert(not pcall(S.runAsync,{mode='evaluate',models=result.baseModels,epsilon=.3,initial=frozenInitial}))
  r.explicitExplorationOnly=true

 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
