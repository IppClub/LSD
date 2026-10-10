local _,mode=...;assert(mode=='prepare' or mode=='read')
local D=require('Dora');local root=D.Path:getPath(D.Path:getScriptPath(...));local out=root..'/Test/flower-q-current-cold-'..mode..'-result.json';local r={status='RUNNING',mode=mode}
local function save()D.Content:save(out,D.json.encode(r,false,true))end;save()
D.thread(function()
 local ok,err=xpcall(function()
  local source=D.json.decode(D.Content:load(root..'/Test/'..(mode=='prepare' and 'flower-q-current-deployment-result.json' or 'flower-q-current-cold-prepare-result.json')),32);assert(source.status=='PASS')
  local pattern=mode=='prepare' and '^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-current%-deployment%-%d+%.db$' or '^/private/tmp/lsd%-shan%-%d+/save/flower%-q%-current%-cold%-prepare%-%d+%.db$'
  assert(source.database:match(pattern))
  local dest=D.Content.writablePath..'/flower-q-current-cold-'..mode..'-'..os.time()..'.db';assert(not D.DB:existDB('lsd')and D.Content:copyAsync(source.database,dest));assert(D.DB:exec("ATTACH DATABASE '"..dest.."' AS lsd")>=0);require('Data.Config'):loadAsync();r.database=dest
  local S=require('Training.FlowerQAdoptionStore');local Store=require('Training.FlowerQStore');local A=require('Training.FlowerQAssessment');local equal=require('Training.FlowerIdentity').equal
  local candidate=assert(Store.loadAsync());assert(candidate.id==source.candidate and candidate.models.ninilite.featureSchemaVersion==7)
  local models=candidate.source.baseModels;r.candidate=candidate.id
  if mode=='prepare'then
   assert(S.currentId()==source.previousAdoption)
   local old,why=S.loadAsync(models);assert(not old and why=='ENCOUNTER_CHANGED');r.rollbackSurvivedRestart=true
   local rows=D.DB:query('SELECT payload FROM lsd.Game0FlowerQAdoptions WHERE id=?',{source.adoption});local archived=D.json.decode(assert(rows[1])[1],32)
   local verified,why=A.readArchiveAsync(archived.bundle);assert(verified,why);assert(equal(verified.models,candidate.models));r.newArchiveSurvivedRestart=true
   local reports=D.DB:query('SELECT status,report FROM lsd.Game0MissionAttempts ORDER BY id DESC LIMIT 1');assert(reports[1][1]=='won')
   local report=D.json.decode(reports[1][2],32)
   for _,id in ipairs({'ninilite','wuyun'})do assert(report.learners[id].qAdoptionId==source.adoption and report.learners[id].controller=='flower-qlearning')end
   r.winningReportSurvivedRestart=true
   local panel=require('Training.FlowerQAdoptionPanel').openAsync(models,function()end)
   for i=1,3 do panel.next:emit('Tapped')end;assert(panel.adopt.visible)
   panel.adopt:emit('Tapped');panel.confirmAdopt:emit('Tapped')
   local deadline=D.App.totalTime+180;while panel.busy do assert(D.App.totalTime<deadline);D.sleep(.05)end
   assert(not panel.error and panel.alreadyAdopted,panel.error or panel.message)
   local adopted,why=S.loadAsync(models);assert(adopted,why);assert(equal(adopted.models,candidate.models))
   r.adoption=adopted.id;r.previousAdoption=adopted.parent;panel.back:emit('Tapped');r.publicReadoption=true
  else
   assert(S.currentId()==source.adoption)
   local adopted,why=S.loadAsync(models);assert(adopted,why)
   assert(adopted.id==source.adoption and adopted.bundle.candidate==candidate.id and require('Factory.Rules').qCurrent(adopted.bundle))
   assert(equal(adopted.models,candidate.models));r.adoption=adopted.id;r.currentModelsRestored=true
   assert(S.rollbackAsync(adopted.id));assert(S.currentId()==source.previousAdoption);r.rollbackRetainsParent=true
  end
 end,debug.traceback)
 r.status=ok and 'PASS' or 'FAIL';r.error=not ok and err or nil;save()
end)
